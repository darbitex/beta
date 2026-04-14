import { Aptos, AptosConfig, type InputViewFunctionData, type MoveValue } from "@aptos-labs/ts-sdk";
import { NETWORK, PACKAGE, RPC_LIST } from "../config";

// Power-user escape hatch: if localStorage has a `darbitex.rpcOverride` key
// (JSON array of URLs), those endpoints are prepended to the pool. Intended
// for devs whose IP is heavily rate-limited on Aptos Labs public — they can
// set their own QuickNode/Alchemy URL in the browser console and it will
// never leak into the public bundle or be seen by other users.
//
//   localStorage.setItem('darbitex.rpcOverride', JSON.stringify([
//     "https://my-quicknode-url.aptos-mainnet.quiknode.pro/KEY/v1",
//   ]));
//
// Then reload. The override clients are tried first in rotation.
function readRpcOverride(): string[] {
  if (typeof localStorage === "undefined") return [];
  try {
    const raw = localStorage.getItem("darbitex.rpcOverride");
    if (!raw) return [];
    const parsed = JSON.parse(raw);
    if (Array.isArray(parsed)) {
      return parsed.filter((x): x is string => typeof x === "string" && x.startsWith("http"));
    }
  } catch {
    // ignore malformed override
  }
  return [];
}

const effectiveRpcList: string[] = [...readRpcOverride(), ...RPC_LIST];

// One Aptos client per RPC in the pool. Round-robin rotation per call spreads
// load across endpoints and preserves the per-IP budget model (each user still
// hits all endpoints from their own IP, no shared quota).
const aptosClients: Aptos[] = effectiveRpcList.map(
  (rpc) => new Aptos(new AptosConfig({ network: NETWORK, fullnode: rpc })),
);

// Per-provider cooldown state with exponential backoff. First 429/503 gives
// a short cooldown; repeated failures double it up to the max. On any success
// from an endpoint, its failure count resets. Self-healing + adaptive.
const BASE_COOLDOWN_MS = 3_000;
const MAX_COOLDOWN_MS = 60_000;
const cooldownUntil: number[] = new Array(aptosClients.length).fill(0);
const failureStreak: number[] = new Array(aptosClients.length).fill(0);

function markCooling(idx: number): void {
  failureStreak[idx] += 1;
  const step = Math.min(failureStreak[idx] - 1, 5);
  const cool = Math.min(BASE_COOLDOWN_MS * Math.pow(2, step), MAX_COOLDOWN_MS);
  cooldownUntil[idx] = Date.now() + cool;
}

function markSuccess(idx: number): void {
  failureStreak[idx] = 0;
}

// Global in-flight semaphore. Public Aptos endpoints rate-limit per-IP hard.
// MAX_IN_FLIGHT = 2 is the conservative setting for heavily rate-limited IPs
// (dev laptops with past bot traffic, shared NAT). Lowered from 3 on
// 2026-04-14 after observing that even the reduced burst with Hyperion
// single-tier + LiquidSwap removal still occasionally tripped 429 on boot.
// Cost: boot burst stretches slightly (3-4s instead of 2-3s) but quote
// latency stays within user-perceptible budget because of the 2s debounce.
const MAX_IN_FLIGHT = 2;
let inFlight = 0;
const waiters: Array<() => void> = [];

async function acquireSlot(): Promise<void> {
  if (inFlight < MAX_IN_FLIGHT) {
    inFlight += 1;
    return;
  }
  await new Promise<void>((resolve) => waiters.push(resolve));
  inFlight += 1;
}

function releaseSlot(): void {
  inFlight -= 1;
  const next = waiters.shift();
  if (next) next();
}

let rpcCursor = 0;

// Legacy single-client export, points to the first RPC. Prefer rotatedView()
// for new read-only code; balance/aggregator helpers already use it.
export const aptos = aptosClients[0];

// Heuristic: is this error "transient" — safe to retry on another provider?
// Rate limits, gateway errors, JSON parse failures (typical of HTML error
// pages returned under 429), and browser fetch network errors all indicate
// a provider-side or transport problem rather than a legitimate Move abort.
// Move aborts are deterministic across providers, so retrying them just
// wastes latency — we throw those immediately.
export function isTransientError(err: unknown): boolean {
  const asErr = err as { name?: string; message?: string };
  const msg = String(asErr?.message ?? err).toLowerCase();
  // Browser fetch API throws TypeError("Failed to fetch") for any network,
  // DNS, or CORS failure. Any TypeError whose message mentions fetch is a
  // transport issue that a different endpoint may not have.
  if (asErr?.name === "TypeError" && msg.includes("fetch")) return true;
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
    // Browser fetch variants across engines.
    msg.includes("failed to fetch") ||
    msg.includes("fetch failed") ||
    msg.includes("networkerror") ||
    msg.includes("load failed") ||
    msg.includes("network") ||
    msg.includes("timeout") ||
    msg.includes("aborted")
  );
}

// Build the try-order for one call: available endpoints (cooldown expired)
// first, rotated for load-spreading. Cooling endpoints are skipped entirely
// if their cooldown has more than 1s left — we don't hammer them. Endpoints
// within 1s of recovery are appended as last-resort so we can recover fast
// once the window reopens.
function buildTryOrder(): number[] {
  const now = Date.now();
  const available: number[] = [];
  const nearlyReady: number[] = [];
  for (let i = 0; i < aptosClients.length; i++) {
    const idx = (rpcCursor + i) % aptosClients.length;
    const remaining = cooldownUntil[idx] - now;
    if (remaining <= 0) available.push(idx);
    else if (remaining <= 1000) nearlyReady.push(idx);
  }
  rpcCursor = (rpcCursor + 1) % aptosClients.length;
  return [...available, ...nearlyReady];
}

// Circuit-breaker error: no endpoints are currently viable. Aggregator quote
// paths check this and skip the venue for this cycle rather than retrying.
export class RpcExhaustedError extends Error {
  constructor() {
    super("All RPC endpoints cooling — skipping this request cycle");
    this.name = "RpcExhaustedError";
  }
}

// Rotated account-resource read. Used for things like FA metadata lookups
// that the aptos SDK exposes via getAccountResource rather than view.
export async function rotatedGetResource<T>(
  accountAddress: string,
  resourceType: string,
): Promise<T> {
  await acquireSlot();
  try {
    const tryOrder = buildTryOrder();
    if (tryOrder.length === 0) throw new RpcExhaustedError();
    let lastErr: unknown = null;
    for (const idx of tryOrder) {
      try {
        const res = (await aptosClients[idx].getAccountResource({
          accountAddress,
          resourceType: resourceType as `${string}::${string}::${string}`,
        })) as T;
        markSuccess(idx);
        return res;
      } catch (e) {
        if (isTransientError(e)) {
          markCooling(idx);
          lastErr = e;
          continue;
        }
        throw e;
      }
    }
    throw lastErr ?? new RpcExhaustedError();
  } finally {
    releaseSlot();
  }
}

// Rotated view: acquires a global in-flight slot (semaphore caps concurrency
// at MAX_IN_FLIGHT), then picks the next available endpoint. On transient
// error, marks the endpoint cooling with exponential backoff and tries the
// next. Fast-fails with RpcExhaustedError if no endpoint is viable.
export async function rotatedView<T extends MoveValue[] = MoveValue[]>(
  payload: InputViewFunctionData,
): Promise<T> {
  await acquireSlot();
  try {
    const tryOrder = buildTryOrder();
    if (tryOrder.length === 0) throw new RpcExhaustedError();
    let lastErr: unknown = null;
    for (const idx of tryOrder) {
      try {
        const res = await aptosClients[idx].view({ payload });
        markSuccess(idx);
        return res as T;
      } catch (e) {
        if (isTransientError(e)) {
          markCooling(idx);
          lastErr = e;
          continue;
        }
        // Deterministic error (Move abort, bad args) — same on every provider.
        throw e;
      }
    }
    throw lastErr ?? new RpcExhaustedError();
  } finally {
    releaseSlot();
  }
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
