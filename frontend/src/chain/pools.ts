import type { TokenConfig } from "../config";
import { metaEq, viewFn } from "./client";
import { logError, logInfo, logWarn } from "./logger";
import { getTokenInfo } from "./tokens";

// Pool data cache in localStorage. Reduces cold-start RPC pressure on IPs
// that are rate-limited (dev laptops with past bot traffic, shared NAT, etc).
// TTL is intentionally short so reserves/supply stay reasonably fresh.
const POOL_CACHE_KEY = "darbitex.poolsCache";
const POOL_CACHE_TTL_MS = 60_000;

type PoolCacheEntry = {
  ts: number;
  pools: Pool[];
};

function readCache(): Pool[] | null {
  if (typeof localStorage === "undefined") return null;
  try {
    const raw = localStorage.getItem(POOL_CACHE_KEY);
    if (!raw) return null;
    const parsed = JSON.parse(raw) as PoolCacheEntry;
    if (!parsed || typeof parsed.ts !== "number") return null;
    if (Date.now() - parsed.ts > POOL_CACHE_TTL_MS) return null;
    return parsed.pools;
  } catch {
    return null;
  }
}

function writeCache(pools: Pool[]): void {
  if (typeof localStorage === "undefined") return;
  try {
    localStorage.setItem(
      POOL_CACHE_KEY,
      JSON.stringify({ ts: Date.now(), pools } as PoolCacheEntry),
    );
  } catch {
    // quota exceeded — drop
  }
}

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

// Load pools sequentially with explicit retries on transient errors. A
// localStorage cache short-circuits the load entirely when fresh, which
// dramatically reduces cold-start RPC pressure on rate-limited IPs.
// Any view failure is logged with full context so the user can export
// logs via Ctrl+Shift+L and we can diagnose offline.
export async function loadPools(): Promise<Pool[]> {
  const cached = readCache();
  if (cached && cached.length > 0) {
    logInfo("pools", `pool cache hit (${cached.length} pools)`);
    return cached;
  }

  let addrs: string[] = [];
  try {
    const addrRes = await viewFn<[string[]]>("pool_factory::get_all_pools");
    addrs = addrRes[0] ?? [];
  } catch (e) {
    logError("pools", "get_all_pools failed", e);
    // On failure, return stale cache if any — better than nothing.
    if (cached && cached.length > 0) {
      logWarn("pools", `returning stale cache (${cached.length} pools) after get_all_pools failure`);
      return cached;
    }
    return [];
  }

  const pools: Pool[] = [];
  let anyDropped = false;
  for (const addr of addrs) {
    const loaded = await loadSinglePool(addr);
    if (loaded) {
      pools.push(loaded);
    } else {
      anyDropped = true;
      logWarn("pools", `pool dropped from universe: ${addr}`);
    }
  }
  // Only cache a COMPLETE load. A partial result should never be persisted,
  // otherwise we'd serve a tainted cache back to the user on the next visit
  // and they'd see a stale universe where some pools are permanently missing.
  if (pools.length === addrs.length && pools.length > 0) {
    writeCache(pools);
  } else if (anyDropped) {
    // If we have a previous stale cache that's MORE complete than the
    // current partial load, prefer the stale one.
    const stale = readCache();
    if (stale && stale.length > pools.length) {
      logWarn("pools", `partial load (${pools.length}/${addrs.length}), returning stale cache (${stale.length})`);
      return stale;
    }
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
