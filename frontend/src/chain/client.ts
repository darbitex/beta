import { Aptos, AptosConfig, type InputViewFunctionData, type MoveValue } from "@aptos-labs/ts-sdk";
import { NETWORK, PACKAGE, RPC_LIST } from "../config";

// One Aptos client per RPC in the pool. Round-robin rotation per call spreads
// load across endpoints and preserves the per-IP budget model (each user still
// hits all endpoints from their own IP, no shared quota).
const aptosClients: Aptos[] = RPC_LIST.map(
  (rpc) => new Aptos(new AptosConfig({ network: NETWORK, fullnode: rpc })),
);

// Per-provider cooldown state. When a provider returns a transient error
// (429, 503, HTML-instead-of-JSON, network timeout), it's marked cooling and
// skipped in the rotation until the timestamp passes. Self-healing.
const COOLDOWN_MS = 10_000;
const cooldownUntil: number[] = new Array(aptosClients.length).fill(0);

let rpcCursor = 0;

// Legacy single-client export, points to the first RPC. Prefer rotatedView()
// for new read-only code; balance/aggregator helpers already use it.
export const aptos = aptosClients[0];

// Heuristic: is this error "transient" — safe to retry on another provider?
// Rate limits, gateway errors, JSON parse failures (typical of HTML error
// pages returned under 429) all indicate a provider-side problem rather than
// a legitimate Move abort. Move aborts are deterministic across providers,
// so retrying them just wastes latency — we throw those immediately.
function isTransientError(err: unknown): boolean {
  const msg = String((err as Error)?.message ?? err).toLowerCase();
  return (
    msg.includes("429") ||
    msg.includes("503") ||
    msg.includes("502") ||
    msg.includes("504") ||
    msg.includes("rate limit") ||
    msg.includes("too many") ||
    msg.includes("service unavailable") ||
    msg.includes("bad gateway") ||
    msg.includes("unexpected token") ||
    msg.includes("json") ||
    msg.includes("fetch failed") ||
    msg.includes("network") ||
    msg.includes("timeout") ||
    msg.includes("aborted")
  );
}

// Same try-order + cooldown pattern as rotatedView, but for the shared
// client pick loop. Factored out so rotatedView and rotatedGetResource
// share the same rotation state and failover semantics.
function buildTryOrder(): number[] {
  const now = Date.now();
  const available: number[] = [];
  const cooling: number[] = [];
  for (let i = 0; i < aptosClients.length; i++) {
    const idx = (rpcCursor + i) % aptosClients.length;
    if (cooldownUntil[idx] <= now) available.push(idx);
    else cooling.push(idx);
  }
  rpcCursor = (rpcCursor + 1) % aptosClients.length;
  return [...available, ...cooling];
}

// Rotated account-resource read. Used for things like FA metadata lookups
// that the aptos SDK exposes via getAccountResource rather than view.
export async function rotatedGetResource<T>(
  accountAddress: string,
  resourceType: string,
): Promise<T> {
  const tryOrder = buildTryOrder();
  let lastErr: unknown = null;
  for (const idx of tryOrder) {
    try {
      return (await aptosClients[idx].getAccountResource({
        accountAddress,
        resourceType: resourceType as `${string}::${string}::${string}`,
      })) as T;
    } catch (e) {
      if (isTransientError(e)) {
        cooldownUntil[idx] = Date.now() + COOLDOWN_MS;
        lastErr = e;
        continue;
      }
      throw e;
    }
  }
  throw lastErr ?? new Error("All RPC providers failed");
}

// Rotated view: build a try-order that puts non-cooling clients first,
// cooling clients last (so they're still tried as a fallback if everyone
// else has failed too). On transient error, mark cooldown and continue.
// On non-transient error, throw immediately.
export async function rotatedView<T extends MoveValue[] = MoveValue[]>(
  payload: InputViewFunctionData,
): Promise<T> {
  const tryOrder = buildTryOrder();
  let lastErr: unknown = null;
  for (const idx of tryOrder) {
    try {
      const res = await aptosClients[idx].view({ payload });
      return res as T;
    } catch (e) {
      if (isTransientError(e)) {
        cooldownUntil[idx] = Date.now() + COOLDOWN_MS;
        lastErr = e;
        continue;
      }
      // Deterministic error (Move abort, bad args) — same on every provider.
      throw e;
    }
  }
  throw lastErr ?? new Error("All RPC providers failed");
}

export async function viewFn<T extends MoveValue[] = MoveValue[]>(
  fn: string,
  typeArguments: string[] = [],
  functionArguments: unknown[] = [],
  packageOverride?: string,
): Promise<T> {
  const pkg = packageOverride ?? PACKAGE;
  const payload: InputViewFunctionData = {
    function: `${pkg}::${fn}` as `${string}::${string}::${string}`,
    typeArguments,
    functionArguments: functionArguments as InputViewFunctionData["functionArguments"],
  };
  return rotatedView<T>(payload);
}

export function toRaw(amount: number, decimals: number): bigint {
  return BigInt(Math.floor(amount * 10 ** decimals));
}

export function fromRaw(raw: bigint | string | number, decimals: number): number {
  return Number(raw) / 10 ** decimals;
}

export function normMeta(m: string): string {
  return m.replace(/^0x0+/, "0x").toLowerCase();
}

export function metaEq(a: string, b: string): boolean {
  return normMeta(a) === normMeta(b);
}

export function metaCmp(a: string, b: string): -1 | 0 | 1 {
  const norm = (s: string) => s.replace(/^0x/i, "").padStart(64, "0").toLowerCase();
  const na = norm(a);
  const nb = norm(b);
  return na < nb ? -1 : na > nb ? 1 : 0;
}
