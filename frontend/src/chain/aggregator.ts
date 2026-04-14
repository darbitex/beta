import {
  AGGREGATOR_PACKAGE,
  HYPERION_ACTIVE_TIER,
  THALA_ADAPTER_PACKAGE,
  type TokenConfig,
} from "../config";
import { metaEq, viewFn } from "./client";
import { logError } from "./logger";
import { getThalaPools, type Route } from "./pools";

// Which venue a quote came from.
// LiquidSwap V0 was removed 2026-04-14 as a user-swap venue: it was the only
// Coin-based (non-FA) venue and required a Coin<->FA bridge via the
// darbitex_liquidswap adapter, plus it needed generic type arguments from
// the frontend — both added fragility and RPC cost (2 parallel calls per
// quote, one per curve) without enough TVL advantage to justify under our
// rate-limit budget. The adapter package `0x85d1e404...` stays deployed
// for the arb path; only the user-swap wiring is dropped.
//
// Thala was re-added 2026-04-14 via the darbitex_thala adapter
// (`0x583d93de...`, 3/5 multisig). The adapter exposes a primitive-only
// `quote` view and `swap_entry`, so the SDK-vs-REST encoding issues that
// forced the first Thala removal are avoided entirely — the adapter
// marshals Option<address>, SwapPreview struct getters, and pool-type
// dispatch on the Move side.
export type Venue = "darbitex" | "hyperion" | "cellana" | "thala";

export type Quote = {
  venue: Venue;
  // Hint to reconstruct the execute call
  darbitexRoute?: Route;  // 1-hop or 2-hop
  hyperionPool?: string;
  cellanaIsStable?: boolean;
  thalaPool?: string;
  amountOutRaw: bigint;
  // Per-hop outputs, for 2-hop quotes. Used to derive tight per-hop
  // min_out floors at execute time.
  darbitexHopOuts?: bigint[];
};

export type AggregatorResult = {
  darbitex: Quote | null;
  hyperion: Quote | null;
  cellana: Quote | null;
  thala: Quote | null;
  best: Quote | null; // max amountOut across all venues
};

function agg<T extends unknown[] = unknown[]>(
  fn: string,
  typeArgs: string[],
  args: unknown[],
): Promise<T> {
  return viewFn<T extends unknown[] ? T : never>(
    `aggregator::${fn}`,
    typeArgs,
    args,
    AGGREGATOR_PACKAGE,
  );
}

async function quoteDarbitexSingleHop(
  poolAddr: string,
  amountInRaw: bigint,
  aToB: boolean,
): Promise<bigint> {
  const res = await agg<[string | number]>("quote_darbitex", [], [
    poolAddr,
    amountInRaw.toString(),
    aToB,
  ]);
  return BigInt(String(res[0] ?? "0"));
}

async function quoteDarbitexRoute(
  route: Route,
  amountInRaw: bigint,
): Promise<Quote | null> {
  try {
    const hopOuts: bigint[] = [];
    let current = amountInRaw;
    for (let i = 0; i < route.pools.length; i++) {
      current = await quoteDarbitexSingleHop(route.pools[i].addr, current, route.aToBs[i]);
      hopOuts.push(current);
      if (current === 0n) return null;
    }
    return {
      venue: "darbitex",
      darbitexRoute: route,
      darbitexHopOuts: hopOuts,
      amountOutRaw: current,
    };
  } catch (e) {
    logError(
      "quoteDarbitexRoute",
      `failed hops=${route.pools.length} amount=${amountInRaw}`,
      e,
    );
    return null;
  }
}

async function hyperionPoolExists(
  metaA: string,
  metaB: string,
  tier: number,
): Promise<boolean> {
  try {
    const res = await agg<[boolean]>("hyperion_pool_exists", [], [metaA, metaB, tier]);
    return Boolean(res[0]);
  } catch {
    return false;
  }
}

async function hyperionGetPool(
  metaA: string,
  metaB: string,
  tier: number,
): Promise<string | null> {
  try {
    const res = await agg<[string]>("hyperion_get_pool", [], [metaA, metaB, tier]);
    return String(res[0]);
  } catch {
    return null;
  }
}

async function quoteHyperionSinglePool(
  pool: string,
  tokenIn: string,
  amountInRaw: bigint,
): Promise<bigint> {
  try {
    const res = await agg<[string | number]>("quote_hyperion", [], [
      pool,
      tokenIn,
      amountInRaw.toString(),
    ]);
    return BigInt(String(res[0] ?? "0"));
  } catch {
    return 0n;
  }
}

// Per-pair cache of the Hyperion pool address on the active tier. Pool
// lookups (pool_exists + get_pool) are 2 RPC calls, and the pool address
// is stable unless the pool is destroyed/recreated — 5 min TTL is safe.
// Negative cache (pair has no Hyperion pool on this tier) also stored.
const hyperionPairCache = new Map<string, { pool: string | null; ts: number }>();
const HYPERION_CACHE_TTL_MS = 5 * 60 * 1000;

function hyperionPairKey(metaA: string, metaB: string): string {
  const [a, b] = metaA.toLowerCase() < metaB.toLowerCase()
    ? [metaA.toLowerCase(), metaB.toLowerCase()]
    : [metaB.toLowerCase(), metaA.toLowerCase()];
  return `${a}:${b}`;
}

async function resolveHyperionPool(
  metaIn: string,
  metaOut: string,
): Promise<string | null> {
  const key = hyperionPairKey(metaIn, metaOut);
  const hit = hyperionPairCache.get(key);
  if (hit && Date.now() - hit.ts < HYPERION_CACHE_TTL_MS) return hit.pool;
  // Hyperion sorts the pair by address bytes internally; pass canonical
  // order for pool lookups.
  const [metaA, metaB] = metaIn.toLowerCase() < metaOut.toLowerCase()
    ? [metaIn, metaOut]
    : [metaOut, metaIn];
  const exists = await hyperionPoolExists(metaA, metaB, HYPERION_ACTIVE_TIER);
  const pool = exists ? await hyperionGetPool(metaA, metaB, HYPERION_ACTIVE_TIER) : null;
  hyperionPairCache.set(key, { pool, ts: Date.now() });
  return pool;
}

// Single-tier Hyperion quote. Cold path: 3 calls (exists, get_pool, quote).
// Warm path (within cache TTL): 1 call (quote). No tier enumeration — per
// mainnet scan 2026-04-14 only tier 1 holds liquidity, so enumerating the
// other five was burning ~15 RPC calls per quote for no benefit.
async function bestHyperionQuote(
  metaIn: string,
  metaOut: string,
  amountInRaw: bigint,
): Promise<Quote | null> {
  const pool = await resolveHyperionPool(metaIn, metaOut);
  if (!pool) return null;
  const out = await quoteHyperionSinglePool(pool, metaIn, amountInRaw);
  if (out === 0n) return null;
  return { venue: "hyperion", hyperionPool: pool, amountOutRaw: out };
}

async function quoteCellanaCurve(
  metaIn: string,
  metaOut: string,
  amountInRaw: bigint,
  isStable: boolean,
): Promise<bigint> {
  try {
    const res = await agg<[string | number]>("quote_cellana", [], [
      metaIn,
      metaOut,
      amountInRaw.toString(),
      isStable,
    ]);
    return BigInt(String(res[0] ?? "0"));
  } catch {
    return 0n;
  }
}

// Per-pair cache of which Cellana curve (stable vs volatile) is active.
// Cold start queries both curves in parallel — first quote doubles as the
// curve-probe, so cold cost is 2 calls (unchanged from pre-cache baseline).
// Warm quotes on the same pair only hit the active curve = 1 call. Negative
// cache (neither curve has a pool) is also stored so we don't re-probe
// unroutable pairs. 5 min TTL like Hyperion — curve activation changes rarely.
type CellanaActive = boolean | null; // true=stable, false=volatile, null=none
const cellanaCurveCache = new Map<string, { active: CellanaActive; ts: number }>();
const CELLANA_CACHE_TTL_MS = 5 * 60 * 1000;

function cellanaPairKey(metaIn: string, metaOut: string): string {
  const [a, b] = metaIn.toLowerCase() < metaOut.toLowerCase()
    ? [metaIn.toLowerCase(), metaOut.toLowerCase()]
    : [metaOut.toLowerCase(), metaIn.toLowerCase()];
  return `${a}:${b}`;
}

async function bestCellanaQuote(
  metaIn: string,
  metaOut: string,
  amountInRaw: bigint,
): Promise<Quote | null> {
  const key = cellanaPairKey(metaIn, metaOut);
  const hit = cellanaCurveCache.get(key);
  // Warm path: cached active curve → 1 call
  if (hit && Date.now() - hit.ts < CELLANA_CACHE_TTL_MS) {
    if (hit.active === null) return null;
    const out = await quoteCellanaCurve(metaIn, metaOut, amountInRaw, hit.active);
    if (out === 0n) return null;
    return { venue: "cellana", cellanaIsStable: hit.active, amountOutRaw: out };
  }
  // Cold path: probe both curves. The probe IS the quote for this refresh,
  // no extra call.
  const [volatile, stable] = await Promise.all([
    quoteCellanaCurve(metaIn, metaOut, amountInRaw, false),
    quoteCellanaCurve(metaIn, metaOut, amountInRaw, true),
  ]);
  let active: CellanaActive;
  let amountOut: bigint;
  if (volatile === 0n && stable === 0n) {
    cellanaCurveCache.set(key, { active: null, ts: Date.now() });
    return null;
  }
  if (stable > volatile) {
    active = true;
    amountOut = stable;
  } else {
    active = false;
    amountOut = volatile;
  }
  cellanaCurveCache.set(key, { active, ts: Date.now() });
  return { venue: "cellana", cellanaIsStable: active, amountOutRaw: amountOut };
}

// Find the seeded Thala pool (from snapshot) whose asset set matches the
// user's selected pair. Returns the pool address or null. Zero RPC cost —
// the pool list + assets are already loaded into the `getThalaPools()`
// registry by the snapshot bootstrap.
function findThalaPoolForPair(metaIn: string, metaOut: string): string | null {
  const pools = getThalaPools();
  for (const p of pools) {
    if (p.assets.length < 2) continue;
    const hasIn = p.assets.some((m) => metaEq(m, metaIn));
    const hasOut = p.assets.some((m) => metaEq(m, metaOut));
    if (hasIn && hasOut) return p.addr;
  }
  return null;
}

async function bestThalaQuote(
  metaIn: string,
  metaOut: string,
  amountInRaw: bigint,
): Promise<Quote | null> {
  const pool = findThalaPoolForPair(metaIn, metaOut);
  if (!pool) return null;
  try {
    const res = await viewFn<[string | number]>(
      "adapter::quote",
      [],
      [pool, metaIn, metaOut, amountInRaw.toString()],
      THALA_ADAPTER_PACKAGE,
    );
    const out = BigInt(String(res[0] ?? "0"));
    if (out === 0n) return null;
    return { venue: "thala", thalaPool: pool, amountOutRaw: out };
  } catch (e) {
    logError("bestThalaQuote", `pool=${pool.slice(0, 10)}...`, e);
    return null;
  }
}

// `includeExternal` gates the external-venue fan-out. In Swap mode the user
// only uses Darbitex, so firing Hyperion + Cellana quotes is pure RPC waste
// — we skip them entirely and spend just 1 RPC call per quote refresh.
// In Aggregator mode the user explicitly opts in to multi-venue routing, so
// we pay the cost. This is the main "per-function scaling" knob: RPC cost
// for a Swap-mode user stays flat regardless of how many venues we add to
// the aggregator over time.
export async function aggregateQuotes(params: {
  tokenIn: TokenConfig;
  tokenOut: TokenConfig;
  amountInRaw: bigint;
  darbitexRoute: Route | null;
  includeExternal: boolean;
}): Promise<AggregatorResult> {
  const { tokenIn, tokenOut, amountInRaw, darbitexRoute, includeExternal } = params;

  const [darbitex, hyperion, cellana, thala] = await Promise.all([
    darbitexRoute
      ? quoteDarbitexRoute(darbitexRoute, amountInRaw)
      : Promise.resolve(null),
    includeExternal
      ? bestHyperionQuote(tokenIn.meta, tokenOut.meta, amountInRaw)
      : Promise.resolve(null),
    includeExternal
      ? bestCellanaQuote(tokenIn.meta, tokenOut.meta, amountInRaw)
      : Promise.resolve(null),
    includeExternal
      ? bestThalaQuote(tokenIn.meta, tokenOut.meta, amountInRaw)
      : Promise.resolve(null),
  ]);

  let best: Quote | null = null;
  for (const q of [darbitex, hyperion, cellana, thala]) {
    if (!q) continue;
    if (!best || q.amountOutRaw > best.amountOutRaw) best = q;
  }

  return { darbitex, hyperion, cellana, thala, best };
}
