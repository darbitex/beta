import {
  AGGREGATOR_PACKAGE,
  HYPERION_FEE_TIERS,
  LIQUIDSWAP_ADAPTER_PACKAGE,
  type TokenConfig,
} from "../config";
import { viewFn } from "./client";
import { logError } from "./logger";
import type { Route } from "./pools";
import { findThalaPool, quoteThala, type ThalaPool, type ThalaPoolKind } from "./thala";

// Which venue a quote came from.
export type Venue = "darbitex" | "hyperion" | "liquidswap" | "cellana" | "thala";

export type Quote = {
  venue: Venue;
  // Hint to reconstruct the execute call
  darbitexRoute?: Route;  // 1-hop or 2-hop
  hyperionPool?: string;
  liquidswapTypes?: [string, string]; // [inCoin, outCoin]
  liquidswapCurve?: "stable" | "uncorrelated";
  cellanaIsStable?: boolean;
  thalaPool?: string;
  thalaKind?: ThalaPoolKind;
  amountOutRaw: bigint;
  // Per-hop outputs, for 2-hop quotes. Used to derive tight per-hop
  // min_out floors at execute time.
  darbitexHopOuts?: bigint[];
};

export type AggregatorResult = {
  darbitex: Quote | null;
  hyperion: Quote | null;
  liquidswap: Quote | null;
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

async function hyperionReserves(pool: string): Promise<[bigint, bigint] | null> {
  try {
    const res = await agg<[string, string]>("hyperion_reserves", [], [pool]);
    return [BigInt(String(res[0])), BigInt(String(res[1]))];
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

// Enumerate Hyperion fee tiers for a pair, skip dust pools by reserve floor,
// quote each viable pool, return the winning (pool, amountOut) or null.
// Reserve floor is approximate — mostly filters truly-empty pools. Final
// guard is the max amountOut pick.
async function bestHyperionQuote(
  metaIn: string,
  metaOut: string,
  amountInRaw: bigint,
): Promise<Quote | null> {
  // Hyperion sorts the pair by address bytes internally; pass canonical order
  // (lex-sort) for pool lookups, but use metaIn for quote direction.
  const [metaA, metaB] = metaIn.toLowerCase() < metaOut.toLowerCase()
    ? [metaIn, metaOut]
    : [metaOut, metaIn];

  const tierChecks = await Promise.all(
    HYPERION_FEE_TIERS.map(async (tier) => {
      const exists = await hyperionPoolExists(metaA, metaB, tier);
      if (!exists) return null;
      const pool = await hyperionGetPool(metaA, metaB, tier);
      if (!pool) return null;
      const reserves = await hyperionReserves(pool);
      if (!reserves) return null;
      // Dust floor: both reserves must be at least 10^3 raw units.
      // CLMM reserves are aggregate, not per-tick, so this is heuristic.
      if (reserves[0] < 1000n || reserves[1] < 1000n) return null;
      return { tier, pool };
    }),
  );

  const viablePools = tierChecks.filter((x): x is { tier: number; pool: string } => x !== null);
  if (viablePools.length === 0) return null;

  const quotes = await Promise.all(
    viablePools.map(async ({ pool }) => ({
      pool,
      out: await quoteHyperionSinglePool(pool, metaIn, amountInRaw),
    })),
  );

  let best: { pool: string; out: bigint } | null = null;
  for (const q of quotes) {
    if (q.out === 0n) continue;
    if (!best || q.out > best.out) best = q;
  }
  if (!best) return null;

  return { venue: "hyperion", hyperionPool: best.pool, amountOutRaw: best.out };
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

// Cellana supports both stable and volatile curves per pair. Query both in
// parallel, pick whichever has the higher net output. Either or both can
// return 0 (no pool or insufficient liquidity) — handled silently.
async function bestCellanaQuote(
  metaIn: string,
  metaOut: string,
  amountInRaw: bigint,
): Promise<Quote | null> {
  const [volatile, stable] = await Promise.all([
    quoteCellanaCurve(metaIn, metaOut, amountInRaw, false),
    quoteCellanaCurve(metaIn, metaOut, amountInRaw, true),
  ]);
  if (volatile === 0n && stable === 0n) return null;
  const useStable = stable > volatile;
  return {
    venue: "cellana",
    cellanaIsStable: useStable,
    amountOutRaw: useStable ? stable : volatile,
  };
}

// Direct call into liquidswap_adapter package (bypasses aggregator wrapper
// because the aggregator package is frozen at 0.2.0 and doesn't know about
// the Uncorrelated curve surface added in liquidswap_adapter 0.2.0).
async function quoteLiquidswapCurve(
  inCoinType: string,
  outCoinType: string,
  amountInRaw: bigint,
  fn: "quote_stable" | "quote_uncorrelated",
): Promise<bigint> {
  try {
    const res = await viewFn<[string | number]>(
      `darbitex_liquidswap::${fn}`,
      [inCoinType, outCoinType],
      [amountInRaw.toString()],
      LIQUIDSWAP_ADAPTER_PACKAGE,
    );
    return BigInt(String(res[0] ?? "0"));
  } catch {
    return 0n;
  }
}

// Query both curves in parallel, pick the winner.
async function bestLiquidswapQuote(
  inCoinType: string,
  outCoinType: string,
  amountInRaw: bigint,
): Promise<Quote | null> {
  const [stable, uncorrelated] = await Promise.all([
    quoteLiquidswapCurve(inCoinType, outCoinType, amountInRaw, "quote_stable"),
    quoteLiquidswapCurve(inCoinType, outCoinType, amountInRaw, "quote_uncorrelated"),
  ]);
  if (stable === 0n && uncorrelated === 0n) return null;
  const useStable = stable >= uncorrelated;
  return {
    venue: "liquidswap",
    liquidswapCurve: useStable ? "stable" : "uncorrelated",
    liquidswapTypes: [inCoinType, outCoinType],
    amountOutRaw: useStable ? stable : uncorrelated,
  };
}

async function thalaQuoteFor(
  pools: ThalaPool[],
  metaIn: string,
  metaOut: string,
  amountInRaw: bigint,
): Promise<Quote | null> {
  const pool = findThalaPool(pools, metaIn, metaOut);
  if (!pool) return null;
  const out = await quoteThala(pool, metaIn, metaOut, amountInRaw);
  if (out === 0n) return null;
  return {
    venue: "thala",
    thalaPool: pool.addr,
    thalaKind: pool.kind,
    amountOutRaw: out,
  };
}

export async function aggregateQuotes(params: {
  tokenIn: TokenConfig;
  tokenOut: TokenConfig;
  amountInRaw: bigint;
  darbitexRoute: Route | null;
  thalaPools: ThalaPool[];
}): Promise<AggregatorResult> {
  const { tokenIn, tokenOut, amountInRaw, darbitexRoute, thalaPools } = params;

  const [darbitex, hyperion, liquidswap, cellana, thala] = await Promise.all([
    darbitexRoute
      ? quoteDarbitexRoute(darbitexRoute, amountInRaw)
      : Promise.resolve(null),
    bestHyperionQuote(tokenIn.meta, tokenOut.meta, amountInRaw),
    tokenIn.coinType && tokenOut.coinType
      ? bestLiquidswapQuote(tokenIn.coinType, tokenOut.coinType, amountInRaw)
      : Promise.resolve(null),
    bestCellanaQuote(tokenIn.meta, tokenOut.meta, amountInRaw),
    thalaPools.length > 0
      ? thalaQuoteFor(thalaPools, tokenIn.meta, tokenOut.meta, amountInRaw)
      : Promise.resolve(null),
  ]);

  let best: Quote | null = null;
  for (const q of [darbitex, hyperion, liquidswap, cellana, thala]) {
    if (!q) continue;
    if (!best || q.amountOutRaw > best.amountOutRaw) best = q;
  }

  return { darbitex, hyperion, liquidswap, cellana, thala, best };
}
