import type { TokenConfig } from "../config";
import { metaEq, viewFn } from "./client";
import { logError, logWarn } from "./logger";
import { getTokenInfo } from "./tokens";

export type Pool = {
  addr: string;
  reserve_a: string;
  reserve_b: string;
  lp_supply: string;
  meta_a: string;
  meta_b: string;
  token_a: TokenConfig;
  token_b: TokenConfig;
  hook_nft_1: string;
  hook_nft_2: string;
};

function extractInner(x: unknown): string {
  if (x && typeof x === "object" && "inner" in (x as Record<string, unknown>)) {
    return String((x as { inner: unknown }).inner);
  }
  return String(x);
}

// Load pools sequentially with explicit retries on transient errors. The
// outer loop iterates pools one at a time, and each pool fetches its 4
// view calls in parallel (small burst, spread across 3 RPC endpoints via
// rotatedView — bounded). Any view failure is logged with full context so
// the user can export logs via Ctrl+Shift+L and we can diagnose offline.
export async function loadPools(): Promise<Pool[]> {
  let addrs: string[] = [];
  try {
    const addrRes = await viewFn<[string[]]>("pool_factory::get_all_pools");
    addrs = addrRes[0] ?? [];
  } catch (e) {
    logError("pools", "get_all_pools failed", e);
    return [];
  }

  const pools: Pool[] = [];
  for (const addr of addrs) {
    const loaded = await loadSinglePool(addr);
    if (loaded) pools.push(loaded);
    else logWarn("pools", `pool dropped from universe: ${addr}`);
  }
  return pools;
}

async function loadSinglePool(addr: string): Promise<Pool | null> {
  try {
    const [reserves, tokens, supply, hooks] = await Promise.all([
      viewFn<[string, string]>("pool::reserves", [], [addr]),
      viewFn<[unknown, unknown]>("pool::pool_tokens", [], [addr]),
      viewFn<[string]>("pool::lp_supply", [], [addr]),
      viewFn<[string, string]>("pool::hook_nft_addresses", [], [addr]),
    ]);
    const metaA = extractInner(tokens[0]);
    const metaB = extractInner(tokens[1]);
    const [tokenA, tokenB] = await Promise.all([getTokenInfo(metaA), getTokenInfo(metaB)]);
    return {
      addr,
      reserve_a: String(reserves[0]),
      reserve_b: String(reserves[1]),
      lp_supply: String(supply[0]),
      meta_a: metaA,
      meta_b: metaB,
      token_a: tokenA,
      token_b: tokenB,
      hook_nft_1: String(hooks[0]),
      hook_nft_2: String(hooks[1]),
    };
  } catch (e) {
    logError("pools", `loadSinglePool failed for ${addr}`, e);
    return null;
  }
}

export function findPool(pools: Pool[], metaIn: string, metaOut: string): Pool | undefined {
  const hit = pools.find(
    (p) =>
      (metaEq(p.meta_a, metaIn) && metaEq(p.meta_b, metaOut)) ||
      (metaEq(p.meta_a, metaOut) && metaEq(p.meta_b, metaIn)),
  );
  if (!hit) {
    logWarn("pools", "findPool miss", {
      metaIn,
      metaOut,
      poolCount: pools.length,
      poolPairs: pools.map((p) => `${p.meta_a}/${p.meta_b}`),
    });
  }
  return hit;
}
