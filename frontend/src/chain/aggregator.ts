import { AGGREGATOR_PACKAGE, HYPERION_FEE_TIERS, type TokenConfig } from "../config";
import { viewFn } from "./client";

// Which venue a quote came from.
export type Venue = "darbitex" | "hyperion" | "liquidswap_stable";

export type Quote = {
  venue: Venue;
  // Hint to reconstruct the execute call
  darbitexPool?: string;
  hyperionPool?: string;
  liquidswapTypes?: [string, string]; // [inCoin, outCoin]
  amountOutRaw: bigint;
};

export type AggregatorResult = {
  darbitex: Quote | null;
  hyperion: Quote | null;
  liquidswapStable: Quote | null;
  best: Quote | null; // max amountOut across the three
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

async function quoteDarbitex(
  poolAddr: string,
  amountInRaw: bigint,
  aToB: boolean,
): Promise<Quote | null> {
  try {
    const res = await agg<[string | number]>("quote_darbitex", [], [
      poolAddr,
      amountInRaw.toString(),
      aToB,
    ]);
    const out = BigInt(String(res[0] ?? "0"));
    if (out === 0n) return null;
    return { venue: "darbitex", darbitexPool: poolAddr, amountOutRaw: out };
  } catch {
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

async function quoteLiquidswapStable(
  inCoinType: string,
  outCoinType: string,
  amountInRaw: bigint,
): Promise<Quote | null> {
  try {
    const res = await agg<[string | number]>(
      "quote_liquidswap_stable",
      [inCoinType, outCoinType],
      [amountInRaw.toString()],
    );
    const out = BigInt(String(res[0] ?? "0"));
    if (out === 0n) return null;
    return {
      venue: "liquidswap_stable",
      liquidswapTypes: [inCoinType, outCoinType],
      amountOutRaw: out,
    };
  } catch {
    return null;
  }
}

export async function aggregateQuotes(params: {
  tokenIn: TokenConfig;
  tokenOut: TokenConfig;
  amountInRaw: bigint;
  darbitexPool: string | null;
  darbitexAToB: boolean;
}): Promise<AggregatorResult> {
  const { tokenIn, tokenOut, amountInRaw, darbitexPool, darbitexAToB } = params;

  const [darbitex, hyperion, liquidswapStable] = await Promise.all([
    darbitexPool
      ? quoteDarbitex(darbitexPool, amountInRaw, darbitexAToB)
      : Promise.resolve(null),
    bestHyperionQuote(tokenIn.meta, tokenOut.meta, amountInRaw),
    tokenIn.coinType && tokenOut.coinType
      ? quoteLiquidswapStable(tokenIn.coinType, tokenOut.coinType, amountInRaw)
      : Promise.resolve(null),
  ]);

  let best: Quote | null = null;
  for (const q of [darbitex, hyperion, liquidswapStable]) {
    if (!q) continue;
    if (!best || q.amountOutRaw > best.amountOutRaw) best = q;
  }

  return { darbitex, hyperion, liquidswapStable, best };
}
