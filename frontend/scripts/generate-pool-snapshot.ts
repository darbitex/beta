// Build-time pool snapshot generator. Queries mainnet for the current
// Darbitex beta pool universe and writes `public/pools-snapshot.json`.
// The snapshot becomes part of the Walrus deploy bundle, served from the
// site itself at `/pools-snapshot.json` — zero RPC cost for cold boots.
//
// Trade-off: reserves in the snapshot are stale by at most (time since
// deploy + local cache TTL). Quotes themselves still hit live chain for
// actual pricing; the snapshot only seeds token list, pool identity, and
// display-only TVL. Post-swap refresh explicitly bypasses the snapshot
// via `loadPools({ fresh: true })`.
//
// Run: `npx tsx scripts/generate-pool-snapshot.ts`
// Or via `npm run snapshot` (hooked into pre-build).

import { writeFileSync, mkdirSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const PACKAGE =
  "0x2656e373ace5ccbc191aedaa65f12a50b9d4ea2b8e6f2d0166741994449c7ec2";
const RPC = "https://api.mainnet.aptoslabs.com/v1";

async function view<T = unknown>(
  fn: string,
  args: unknown[] = [],
  typeArgs: string[] = [],
): Promise<T> {
  const res = await fetch(`${RPC}/view`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      function: `${PACKAGE}::${fn}`,
      type_arguments: typeArgs,
      arguments: args,
    }),
  });
  if (!res.ok) {
    const body = await res.text();
    throw new Error(`view ${fn} failed: ${res.status} ${body.slice(0, 100)}`);
  }
  return (await res.json()) as T;
}

async function getResource<T = unknown>(
  addr: string,
  type: string,
): Promise<T | null> {
  const res = await fetch(
    `${RPC}/accounts/${addr}/resource/${encodeURIComponent(type)}`,
  );
  if (res.status === 404) return null;
  if (!res.ok) throw new Error(`resource ${addr} failed: ${res.status}`);
  const j = (await res.json()) as { data: T };
  return j.data;
}

type MetadataResource = {
  name?: string;
  symbol?: string;
  decimals?: number | string;
};

type TokenInfo = {
  meta: string;
  symbol: string;
  decimals: number;
};

type PoolSnapshot = {
  addr: string;
  reserve_a: string;
  reserve_b: string;
  lp_supply: string;
  meta_a: string;
  meta_b: string;
  token_a: TokenInfo;
  token_b: TokenInfo;
  hook_nft_1: string;
  hook_nft_2: string;
};

function extractInner(x: unknown): string {
  if (x && typeof x === "object" && "inner" in (x as Record<string, unknown>)) {
    return String((x as { inner: unknown }).inner);
  }
  return String(x);
}

function normMeta(m: string): string {
  return m.replace(/^0x0+/, "0x").toLowerCase();
}

async function main(): Promise<void> {
  const started = Date.now();
  console.log(`[snapshot] fetching Darbitex beta pool universe from ${RPC}`);

  // 1. Enumerate pool addresses
  const addrsRes = await view<[string[]]>("pool_factory::get_all_pools");
  const addrs = addrsRes[0] ?? [];
  console.log(`[snapshot] ${addrs.length} pools`);

  // 2. Per-pool data (sequential to be polite on build-machine RPC budget)
  const pools: PoolSnapshot[] = [];
  const tokenCache = new Map<string, TokenInfo>();

  async function resolveToken(meta: string): Promise<TokenInfo> {
    const key = normMeta(meta);
    const cached = tokenCache.get(key);
    if (cached) return cached;
    const data = await getResource<MetadataResource>(
      meta,
      "0x1::fungible_asset::Metadata",
    );
    const info: TokenInfo = {
      meta,
      symbol: data?.symbol || `${meta.slice(0, 6)}...`,
      decimals:
        Number.parseInt(String(data?.decimals ?? "0"), 10) || 0,
    };
    tokenCache.set(key, info);
    return info;
  }

  for (const addr of addrs) {
    try {
      const [reservesRes, tokensRes, supplyRes, hooksRes] = await Promise.all([
        view<[string, string]>("pool::reserves", [addr]),
        view<[unknown, unknown]>("pool::pool_tokens", [addr]),
        view<[string]>("pool::lp_supply", [addr]),
        view<[string, string]>("pool::hook_nft_addresses", [addr]),
      ]);
      const meta_a = extractInner(tokensRes[0]);
      const meta_b = extractInner(tokensRes[1]);
      const [token_a, token_b] = await Promise.all([
        resolveToken(meta_a),
        resolveToken(meta_b),
      ]);
      pools.push({
        addr,
        reserve_a: String(reservesRes[0]),
        reserve_b: String(reservesRes[1]),
        lp_supply: String(supplyRes[0]),
        meta_a,
        meta_b,
        token_a,
        token_b,
        hook_nft_1: String(hooksRes[0]),
        hook_nft_2: String(hooksRes[1]),
      });
      console.log(
        `[snapshot]   ${addr.slice(0, 10)}... ${token_a.symbol}/${token_b.symbol} reserves=${reservesRes[0]}/${reservesRes[1]}`,
      );
    } catch (e) {
      console.error(`[snapshot]   skip ${addr.slice(0, 10)}...: ${String(e)}`);
    }
  }

  const elapsed = ((Date.now() - started) / 1000).toFixed(1);
  const snapshot = {
    generated_at: new Date().toISOString(),
    package: PACKAGE,
    pool_count: pools.length,
    pools,
  };

  const thisFile = fileURLToPath(import.meta.url);
  const outPath = resolve(dirname(thisFile), "..", "public", "pools-snapshot.json");
  mkdirSync(dirname(outPath), { recursive: true });
  writeFileSync(outPath, JSON.stringify(snapshot, null, 2));
  console.log(
    `[snapshot] wrote ${pools.length} pools (${tokenCache.size} unique tokens) to ${outPath} in ${elapsed}s`,
  );
}

main().catch((e) => {
  console.error("[snapshot] FAILED:", e);
  process.exit(1);
});
