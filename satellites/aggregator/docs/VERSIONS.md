# DarbitexAggregator Versions

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
