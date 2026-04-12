import type { TokenConfig } from "../config";
import { metaEq, viewFn } from "./client";
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

export async function loadPools(): Promise<Pool[]> {
  const addrRes = await viewFn<[string[]]>("pool_factory::get_all_pools");
  const addrs = addrRes[0] ?? [];
  const pools: Pool[] = [];
  for (const addr of addrs) {
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
      pools.push({
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
      });
    } catch (e) {
      console.error("pool load failed", addr, e);
    }
  }
  return pools;
}

export function findPool(pools: Pool[], metaIn: string, metaOut: string): Pool | undefined {
  return pools.find(
    (p) =>
      (metaEq(p.meta_a, metaIn) && metaEq(p.meta_b, metaOut)) ||
      (metaEq(p.meta_a, metaOut) && metaEq(p.meta_b, metaIn)),
  );
}
