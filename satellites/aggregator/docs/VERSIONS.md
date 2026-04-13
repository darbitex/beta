# DarbitexAggregator Versions

## 0.1.0 — initial publish (2026-04-13)

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
