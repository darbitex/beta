import { THALA_PACKAGE } from "../config";
import { metaEq, viewFn } from "./client";
import { logError, logInfo, logWarn } from "./logger";

// ThalaSwap V2 frontend integration. No on-chain satellite — Thala's own
// `preview_swap_exact_in_*` functions are public fn (not #[view]-annotated
// explicitly, but Aptos view API accepts them because they're pure). We
// call them directly with packageOverride=THALA_PACKAGE.

export type ThalaPoolKind = "weighted" | "stable" | "metastable";

export type ThalaPool = {
  addr: string;
  metas: string[]; // pool_assets_metadata, ordered as on-chain
  kind: ThalaPoolKind;
};

const CACHE_KEY = "darbitex.thalaPools";
const CACHE_TTL_MS = 5 * 60_000;

type CacheEntry = { ts: number; pools: ThalaPool[] };

function readCache(): ThalaPool[] | null {
  if (typeof localStorage === "undefined") return null;
  try {
    const raw = localStorage.getItem(CACHE_KEY);
    if (!raw) return null;
    const parsed = JSON.parse(raw) as CacheEntry;
    if (!parsed || typeof parsed.ts !== "number") return null;
    if (Date.now() - parsed.ts > CACHE_TTL_MS) return null;
    return parsed.pools;
  } catch {
    return null;
  }
}

function writeCache(pools: ThalaPool[]): void {
  if (typeof localStorage === "undefined") return;
  try {
    localStorage.setItem(CACHE_KEY, JSON.stringify({ ts: Date.now(), pools } as CacheEntry));
  } catch {
    // ignore quota error
  }
}

function extractInner(x: unknown): string {
  if (x && typeof x === "object" && "inner" in (x as Record<string, unknown>)) {
    return String((x as { inner: unknown }).inner);
  }
  return String(x);
}

async function loadPoolMetadata(poolAddr: string): Promise<ThalaPool | null> {
  try {
    const [metasRes, isWeightedRes, isStableRes] = await Promise.all([
      viewFn<[unknown[]]>("pool::pool_assets_metadata", [], [poolAddr], THALA_PACKAGE),
      viewFn<[boolean]>("pool::pool_is_weighted", [], [poolAddr], THALA_PACKAGE),
      viewFn<[boolean]>("pool::pool_is_stable", [], [poolAddr], THALA_PACKAGE),
    ]);
    const metas = (metasRes[0] ?? []).map((m) => extractInner(m).toLowerCase());
    const kind: ThalaPoolKind = isWeightedRes[0]
      ? "weighted"
      : isStableRes[0]
        ? "stable"
        : "metastable";
    return { addr: poolAddr, metas, kind };
  } catch (e) {
    logWarn("thala", `loadPoolMetadata skip ${poolAddr}`, e);
    return null;
  }
}

export async function loadThalaPools(): Promise<ThalaPool[]> {
  const cached = readCache();
  if (cached) {
    logInfo("thala", `pool cache hit (${cached.length} pools)`);
    return cached;
  }
  try {
    const res = await viewFn<[unknown[]]>("pool::pools", [], [], THALA_PACKAGE);
    const addrs = (res[0] ?? []).map((x) => extractInner(x));
    const results = await Promise.all(addrs.map(loadPoolMetadata));
    const pools = results.filter((x): x is ThalaPool => x !== null);
    writeCache(pools);
    logInfo("thala", `loaded ${pools.length} pools (${addrs.length} attempted)`);
    return pools;
  } catch (e) {
    logError("thala", "loadThalaPools failed", e);
    return [];
  }
}

export function findThalaPool(
  pools: ThalaPool[],
  metaIn: string,
  metaOut: string,
): ThalaPool | undefined {
  return pools.find(
    (p) =>
      p.metas.some((m) => metaEq(m, metaIn)) &&
      p.metas.some((m) => metaEq(m, metaOut)),
  );
}

// Quote via the per-kind preview function. Option<address> is passed as
// `{ vec: [] }` (Aptos SDK convention for None).
export async function quoteThala(
  pool: ThalaPool,
  metaIn: string,
  metaOut: string,
  amountInRaw: bigint,
): Promise<bigint> {
  const fn = `pool::preview_swap_exact_in_${pool.kind}`;
  try {
    const res = await viewFn<[Record<string, unknown>]>(
      fn,
      [],
      [pool.addr, metaIn, amountInRaw.toString(), metaOut, { vec: [] }],
      THALA_PACKAGE,
    );
    const preview = res[0] as { amount_out?: string | number } | undefined;
    return BigInt(String(preview?.amount_out ?? "0"));
  } catch (e) {
    logError("quoteThala", `${pool.kind} pool=${pool.addr.slice(0, 14)}...`, e);
    return 0n;
  }
}

// Expose the module name for the entry tx builder. The entry function is
// named `swap_exact_in_<kind>_entry` and has signature:
//   (signer, Object<Pool>, Object<Metadata> in, u64 amount_in,
//    Object<Metadata> out, u64 min_out)
export function thalaSwapEntryFn(kind: ThalaPoolKind): string {
  return `swap_exact_in_${kind}_entry`;
}
