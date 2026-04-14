import type { TokenConfig } from "../config";
import { isTransientError, metaEq, viewFn } from "./client";
import { logError, logInfo, logWarn } from "./logger";
import { getTokenInfo, preloadTokenInfo } from "./tokens";

// Pool data cache in localStorage. Reduces cold-start RPC pressure on IPs
// that are rate-limited (dev laptops with past bot traffic, shared NAT, etc).
// TTL is intentionally short so reserves/supply stay reasonably fresh.
const POOL_CACHE_KEY = "darbitex.poolsCache";
const POOL_CACHE_TTL_MS = 60_000;

// Build-time snapshot served from the Walrus bundle itself — zero RPC cost
// for cold boots. Populated by `scripts/generate-pool-snapshot.ts` and
// shipped as `/pools-snapshot.json`. Used only when there's no warm cache.
// Staleness floor is the deploy age; reserves diverge from live chain until
// the next 60s cache tick triggers a fresh load or a swap forces `fresh`.
const SNAPSHOT_URL = "/pools-snapshot.json";

export type ThalaPoolEntry = {
  addr: string;
  assets: string[];
};

type PoolSnapshotFile = {
  generated_at: string;
  package: string;
  pool_count: number;
  pools: Pool[];
  thala_adapter?: string;
  thala_pools?: ThalaPoolEntry[];
};

// Thala pool registry populated from the snapshot on first read. Separate
// from the Darbitex Pool cache because Thala pools are only consulted by
// the aggregator's external-venue fan-out, not by Darbitex routing.
let thalaPoolRegistry: ThalaPoolEntry[] | null = null;

export function getThalaPools(): ThalaPoolEntry[] {
  return thalaPoolRegistry ?? [];
}

async function readSnapshot(): Promise<Pool[] | null> {
  if (typeof fetch === "undefined") return null;
  try {
    const res = await fetch(SNAPSHOT_URL, { cache: "no-cache" });
    if (!res.ok) return null;
    const json = (await res.json()) as PoolSnapshotFile;
    if (!json || !Array.isArray(json.pools)) return null;
    // Seed the Thala registry from the snapshot while we have it open.
    if (Array.isArray(json.thala_pools)) {
      thalaPoolRegistry = json.thala_pools;
    }
    return json.pools;
  } catch {
    return null;
  }
}

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

// Subscribe/notify hooks so mounted pages can receive fresh pool data
// when either (a) a manual refresh button is clicked, or (b) the boot-time
// background count check detects a new on-chain pool. Each page's useEffect
// registers a setPools callback; refreshPools() pushes new state to all.
type PoolSubscriber = (pools: Pool[]) => void;
const poolSubscribers = new Set<PoolSubscriber>();

export function subscribePools(cb: PoolSubscriber): () => void {
  poolSubscribers.add(cb);
  return () => {
    poolSubscribers.delete(cb);
  };
}

function notifyPoolSubscribers(pools: Pool[]): void {
  for (const cb of poolSubscribers) {
    try {
      cb(pools);
    } catch (e) {
      logWarn("pools", "subscriber threw during notify", e);
    }
  }
}

export function invalidatePoolCache(): void {
  if (typeof localStorage !== "undefined") {
    try {
      localStorage.removeItem(POOL_CACHE_KEY);
    } catch {
      // ignore
    }
  }
}

// Nuke caches, force fresh chain load, broadcast new state to every
// subscribed page. Used by the manual refresh button and the background
// count-mismatch check.
export async function refreshPools(): Promise<Pool[]> {
  invalidatePoolCache();
  const fresh = await loadPools({ fresh: true });
  notifyPoolSubscribers(fresh);
  return fresh;
}

// Background sanity check: fire a single get_all_pools (1 RPC call) and
// compare the on-chain pool count against what we cached from the snapshot.
// If the chain has more (or fewer) pools, triggers a full refresh. Designed
// to run once ~5s after page load, opt-in, silent on failure.
export async function backgroundPoolCountCheck(): Promise<boolean> {
  try {
    const res = await viewFn<[string[]]>("pool_factory::get_all_pools");
    const chainCount = (res[0] ?? []).length;
    const cached = readCache();
    const cachedCount = cached?.length ?? 0;
    if (chainCount !== cachedCount) {
      logInfo(
        "pools",
        `background check: chain=${chainCount} cached=${cachedCount}, refreshing`,
      );
      await refreshPools();
      return true;
    }
    return false;
  } catch {
    return false;
  }
}

// Load pools with a 3-tier cache:
//   1. localStorage (warm, <60s)     — zero network
//   2. /pools-snapshot.json (cold)   — zero RPC, served from Walrus bundle
//   3. on-chain RPC                  — fallback, worst-case cost
//
// Post-swap paths pass `{ fresh: true }` to skip tiers 1 and 2 and go
// straight to chain, because reserves need to reflect the just-executed
// swap. Normal navigation and cold boots stay RPC-free in the common case.
//
// Any view failure is logged with full context so the user can export
// logs via Ctrl+Shift+L and we can diagnose offline.
export async function loadPools(opts: { fresh?: boolean } = {}): Promise<Pool[]> {
  const cached = opts.fresh ? null : readCache();
  if (cached && cached.length > 0) {
    logInfo("pools", `pool cache hit (${cached.length} pools)`);
    return cached;
  }

  if (!opts.fresh) {
    const snap = await readSnapshot();
    if (snap && snap.length > 0) {
      logInfo("pools", `pool snapshot hit (${snap.length} pools, 0 RPC cost)`);
      // Seed token cache so future getTokenInfo lookups (balance, decimals,
      // symbol display) don't fall through to RPC.
      for (const p of snap) {
        preloadTokenInfo(p.token_a);
        preloadTokenInfo(p.token_b);
      }
      writeCache(snap);
      return snap;
    }
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
    let loaded: Pool | null = null;
    try {
      loaded = await loadSinglePool(addr);
    } catch (e) {
      // Transient RPC failure exhausted all providers. Don't drop the pool —
      // serve stale cache if we have one, otherwise bail with what we have.
      logWarn("pools", `transient failure loading ${addr}, aborting cold load`);
      const stale = readCache();
      if (stale && stale.length > 0) {
        logWarn("pools", `returning stale cache (${stale.length} pools) after transient failure`);
        return stale;
      }
      return pools;
    }
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
    if (isTransientError(e)) {
      logWarn("pools", `transient RPC failure for ${addr}`);
      throw e;
    }
    logError("pools", `loadSinglePool failed for ${addr}`, e);
    return null;
  }
}

export function findPool(pools: Pool[], metaIn: string, metaOut: string): Pool | undefined {
  return pools.find(
    (p) =>
      (metaEq(p.meta_a, metaIn) && metaEq(p.meta_b, metaOut)) ||
      (metaEq(p.meta_a, metaOut) && metaEq(p.meta_b, metaIn)),
  );
}

// A Darbitex route: one or two pools forming a path from metaIn to metaOut.
// aToBs[i] is the direction for pools[i] — whether the swap on that pool
// sends token_a out as token_b (true) or token_b out as token_a (false).
export type Route = {
  pools: Pool[];
  aToBs: boolean[];
  intermediateMeta?: string; // only for 2-hop
};

// Find a direct 1-hop or an intermediate 2-hop path from metaIn to metaOut
// through the loaded Darbitex pool universe. 2-hop walks the pool graph
// once — O(pools^2), fine for small pool counts. 3-hop is skipped for now.
export function findRoute(
  pools: Pool[],
  metaIn: string,
  metaOut: string,
): Route | null {
  // 1-hop: direct pool
  const direct = findPool(pools, metaIn, metaOut);
  if (direct) {
    return {
      pools: [direct],
      aToBs: [metaEq(direct.meta_a, metaIn)],
    };
  }

  // 2-hop: find pool P1 with metaIn on one side, and pool P2 with the
  // other side of P1 matching one side of P2, and metaOut on the other.
  for (const p1 of pools) {
    let intermediate: string | null = null;
    if (metaEq(p1.meta_a, metaIn)) intermediate = p1.meta_b;
    else if (metaEq(p1.meta_b, metaIn)) intermediate = p1.meta_a;
    if (!intermediate) continue;

    for (const p2 of pools) {
      if (p2 === p1) continue;
      const hasIntermediate = metaEq(p2.meta_a, intermediate) || metaEq(p2.meta_b, intermediate);
      if (!hasIntermediate) continue;
      const hasOut = metaEq(p2.meta_a, metaOut) || metaEq(p2.meta_b, metaOut);
      if (!hasOut) continue;
      return {
        pools: [p1, p2],
        aToBs: [metaEq(p1.meta_a, metaIn), metaEq(p2.meta_a, intermediate)],
        intermediateMeta: intermediate,
      };
    }
  }

  logWarn("pools", "findRoute miss (no 1-hop or 2-hop)", {
    metaIn,
    metaOut,
    poolCount: pools.length,
    poolPairs: pools.map((p) => `${p.meta_a}/${p.meta_b}`),
  });
  return null;
}
