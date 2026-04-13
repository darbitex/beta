# DarbitexAggregator Versions

## 0.2.0 — DEPLOYED 2026-04-13

**Upgrade tx:** `0x36038f41b3a5c0e6a58095a9a61393999b9553da5038f878a4d7fe3e5e05a761`
**Propose tx:** `0xd359dd87fedb9eb8362cc8e46e9f9e9ec476721a0eb35131ae8da0d297b64774`

**On-chain smoke tests:**
- `quote_cellana(APT-wrap, lzUSDC-wrap, 1e6, volatile)` → 8219 raw lzUSDC (pool `0x234f0be5...`, matches memory)
- `cellana_pool_address(APT-wrap, lzUSDC-wrap, volatile)` → `0x234f0be5...`
- `quote_cellana(nUSDC, Cellana-lzUSDC-wrap, 10000, stable)` → 9996 raw (stable curve)
- `swap_cellana` entry nUSDC → Cellana-lzUSDC-wrap 10k raw → +9996 lzUSDC balance, tx `0x...348`

**Multisig raised 1/5 → 3/5** post-deploy via proposal seq #2, exec tx `0x7f733ff288d5532156b9db12269849940273bdcc0a69e896d5a6f02a5c704d2d`. Future upgrades need 3 approvals.



Add Cellana venue (Tier-1 per `darbitex_aptos_targets.md`). Two new #[view] functions and one new entry function. Backward-compatible upgrade on the existing multisig publisher.

- `#[view] quote_cellana(meta_in, meta_out, amount_in, is_stable) -> u64` — wraps `cellana::router::get_amount_out`, returns net amount_out (fee dropped from the tuple)
- `#[view] cellana_pool_address(meta_a, meta_b, is_stable) -> address` — wraps `cellana::liquidity_pool::liquidity_pool` and returns the object address (not the Object<T> wrapper)
- `public entry swap_cellana(caller, meta_in, meta_out, is_stable, amount_in, min_out, deadline)` — withdraws FA from caller, routes via `cellana::router::swap` composable, deposits output back, deadline-guarded
- New dep: `cellana` (local bytecode package downloaded from mainnet `0x4bf51972...` via `aptos move download --bytecode`, decompiled to `.mv.move` sources, `FeesAccounting` acquires annotation stripped from `liquidity_pool::mint_lp` to fix an unnecessary-acquires compile error in the decompiled bytecode)

## 0.1.0 — DEPLOYED 2026-04-13

**Package address:** `0x838a981b43c5bf6fb1139a60ccd7851a4031cd31c775f71f963163c49ab62b47`
**Publish tx:** `0xf003a8503b2c0a0f22717beeb2fad91873e487b6fc46e7af8b8f30aa4c507ca6`
**Publisher multisig:** same as package address, 1/5 threshold, same 5 owners as beta publisher
**Multisig create tx:** `0x42f4abf4cfd901b93feaeda1ed210aa2b8163e2d260dc52f8a8fd1dfbe84c532`

**On-chain smoke tests:**
- `swap_darbitex` 0.001 APT → 809 USDC raw — tx `0xc6a45ae69eb8a1716ab48f07af4cb9560818f98316f3da7a71ace4c3a52a6e15`
- `swap_hyperion` 0.001 APT → 820 USDC raw — tx `0x6d47010516fb282131e824364ecc7e1ebe7292e6284b47fde73efc7c788d7e6f`
- Views `quote_darbitex`, `quote_hyperion`, `hyperion_pool_exists`, `hyperion_get_pool`, `hyperion_reserves` all return expected values.
- `quote_liquidswap_stable<X, Y>` and `swap_liquidswap_stable<X, Y>` NOT YET TESTED — require a supported live Stable pool and wallet balance in the right CoinType pair. Code is audit-clean but marked "untested live" until a USDC↔USDt flow is wired end to end.

- New satellite package separated from arb adapters by design
- Module `darbitex_aggregator::aggregator`:
  - `#[view] quote_darbitex(pool_addr, amount_in, a_to_b) -> u64`
  - `#[view] quote_hyperion(pool, token_in, amount_in) -> u64`
  - `#[view] quote_liquidswap_stable<X, Y>(amount_in) -> u64`
  - `#[view] hyperion_pool_exists(meta_a, meta_b, fee_tier) -> bool`
  - `#[view] hyperion_get_pool(meta_a, meta_b, fee_tier) -> address` *(pool address, not Object wrapper — cleaner frontend consumption)*
  - `#[view] hyperion_reserves(pool) -> (u64, u64)`
  - `public entry swap_darbitex(caller, pool, metadata_in, amount_in, min_out, deadline)`
  - `public entry swap_hyperion(caller, pool, metadata_in, a_to_b, amount_in, min_out, deadline)`
  - `public entry swap_liquidswap_stable<X, Y>(caller, metadata_in, amount_in, min_out, deadline)`

Hyperion pool discovery views are added because `hyperion_adapter::adapter::{pool_exists, get_pool, reserves}` are plain `public fun`, not `#[view]`-annotated. The aggregator exposes `#[view]` wrappers so the frontend can cheap-query them without simulating transactions.
- No flash-loan / Aave integration — user-swap scope only. Arbitrage stays in the original `hyperion_adapter` and `liquidswap_adapter` packages.
- Frontend enumerates Hyperion fee tiers (0-5) and picks best net output; LiquidSwap called per hardcoded Tier 1 pair type.
- Deployed from a fresh 1-of-5 publisher multisig (owners mirror beta publisher `0x8c8f40ef...`).
