# Darbitex Beta Frontend Audit Report

**Date:** 2026-04-12
**Scope:** All 23 source files in `frontend/src/`
**Contract:** `0x2656e373ace5ccbc191aedaa65f12a50b9d4ea2b8e6f2d0166741994449c7ec2`

---

## 1. Entry Function Call Audit

Every entry function call in the frontend verified against exact on-chain contract signatures.

| Frontend Call | Contract Signature (excl signer) | Frontend Args | Status |
|---|---|---|---|
| `router::swap_with_deadline` | `(pool_addr: address, metadata_in: Object<Metadata>, amount_in: u64, min_out: u64, deadline: u64)` | `[pool.addr, meta, rawIn, minOut, deadline]` | PASS |
| `pool_factory::create_canonical_pool` | `(metadata_a: Object<Metadata>, metadata_b: Object<Metadata>, amount_a: u64, amount_b: u64)` | `[meta_a, meta_b, rawA, rawB]` | PASS |
| `pool::add_liquidity_entry` | `(pool_addr: address, amount_a: u64, amount_b: u64, min_shares_out: u64)` | `[pool.addr, rawA, rawB, "0"]` | PASS |
| `pool::remove_liquidity_entry` | `(position: Object<LpPosition>, min_amount_a: u64, min_amount_b: u64)` | `[posAddr, "0", "0"]` | PASS |
| `pool::claim_lp_fees_entry` | `(position: Object<LpPosition>)` | `[posAddr]` | PASS |
| `pool::claim_hook_fees_entry` | `(nft: Object<HookNFT>)` | `[nftAddr]` | PASS |
| `pool_factory::buy_hook` | `(pool_addr: address)` | `[poolAddr]` | PASS |

## 2. View Function Call Audit

| Frontend Call | Contract Returns | Frontend Type | Status |
|---|---|---|---|
| `pool_factory::get_all_pools()` | `vector<address>` | `[string[]]` | PASS |
| `pool::reserves(addr)` | `(u64, u64)` | `[string, string]` | PASS |
| `pool::pool_tokens(addr)` | `(Object<Metadata>, Object<Metadata>)` | `[unknown, unknown]` + extractInner | PASS |
| `pool::lp_supply(addr)` | `u64` | `[string]` | PASS |
| `pool::hook_nft_addresses(addr)` | `(address, address)` | `[string, string]` | PASS |
| `pool::get_amount_out(addr, amt, a2b)` | `u64` | `[string \| number]` | PASS |
| `pool_factory::is_hook_listed(addr)` | `bool` | `[boolean]` | PASS |
| `pool::hook_fee_buckets(addr)` | `(u64, u64, u64, u64)` | `[string, string, string, string]` | PASS |
| `pool_factory::hook_listing_price(addr)` | `u64` | `[string]` | PASS |
| `pool::position_info(addr)` | `(address, u64, u128, u128)` | `[string, string, string, string]` | PASS |
| `pool::pending_lp_fees(addr)` | `(u64, u64)` | `[string, string]` | PASS |
| `pool_factory::admin_address()` | `address` | `[string]` | PASS |
| `pool_factory::treasury_address()` | `address` | `[string]` | PASS |
| `pool_factory::revenue_address()` | `address` | `[string]` | PASS |
| `pool_factory::factory_address()` | `address` | `[string]` | PASS |
| `pool_factory::current_hook_price()` | `u64` | `[string]` | PASS |
| `pool::total_stats(addr)` | `(u64, u128, u128)` | `[string, string, string]` | PASS |
| `pool_factory::canonical_pool_address(a, b)` | `address` | `[string]` | PASS |

## 3. Bugs Found and Fixed

### BUG-1: Portfolio indexer query (CRITICAL, FIXED)

**File:** `src/pages/Portfolio.tsx`

**Problem:** Used `object_type` field in GraphQL query against Aptos indexer `current_objects` table. This field does not exist — the query silently returned zero results, making LP positions invisible.

**Verification:** Introspected `current_objects` schema via GraphQL — confirmed only fields: `object_address`, `owner_address`, `state_key_hash`, `allow_ungated_transfer`, `last_transaction_version`, `last_guid_creation_num`, `is_deleted`. No `object_type`.

**Fix:** Query ALL objects owned by user (no type filter), then try `pool::position_info()` on each via view function call. Non-LpPosition objects throw and are silently skipped. Verified against mainnet: 3 out of 6 multisig-owned objects correctly identified as LpPositions.

**Commit:** `7aea476`

### BUG-2: Missing SPA fallback for Walrus (HIGH, FIXED)

**File:** `public/ws-resources.json` (was missing)

**Problem:** Without `ws-resources.json` containing `"routes": { "/*": "/index.html" }`, direct navigation or page refresh on `/pools`, `/hooks`, `/portfolio`, etc. would 404 on Walrus portal.

**Fix:** Created `public/ws-resources.json` with SPA route fallback and cache headers, matching V1 Alpha's proven configuration.

**Commit:** `76f52d8`

### BUG-3: Swap rate division by zero (MEDIUM, FIXED)

**File:** `src/pages/Swap.tsx` line 148

**Problem:** Rate display `(quote.amountOut / amountNum).toFixed(6)` could show `Infinity` if `amountNum` was 0 due to race condition between quote state and amount input.

**Fix:** Guarded with `amountNum > 0 ? ... : "—"`.

**Commit:** `76f52d8`

## 4. UI/UX Audit

### Social Login
- Google, Apple via Aptos Connect: **PASS** (identical to V1 Alpha)
- Petra, Petra Web, OKX Wallet, Nightly: **PASS**
- `aptosConnect.dappName`: `"Darbitex Beta"` — correct

### Wallet ConnectButton
- Connect/disconnect flow: **PASS**
- Truncated address display: **PASS**
- Wallet menu z-index (30) below modal (50), above nav (9): **PASS**
- Click-outside-to-close: NOT implemented (same as V1) — acceptable

### Responsive Design
- Mobile-first 480px max-width container: **PASS**
- Sticky header (z-index 10) + nav (z-index 9): **PASS**
- Single breakpoint `@media (min-width: 640px)`: **PASS** (same as V1)
- Touch-friendly button sizes (min 36x36px): **PASS**

### Cold-Start Script (Walrus)
- 5x auto-retry with 700ms delay: **PASS**
- `sessionStorage` counter reset on React mount: **PASS**
- Fallback message on persistent failure: **PASS**
- `__dbx_mounted` callback wired in `main.tsx`: **PASS**

### Branding
- Accent color `#ff8800` consistent across CSS, favicon, manifest, index.html: **PASS**
- Site name "Darbitex Beta" in manifest, ws-resources, Layout: **PASS**

### Token Config
- APT: `0x...0a`, 8 decimals: **PASS**
- USDC: `0xbae207...46f3b`, 6 decimals: **PASS**
- USDt: `0x357b0b...9dc2b`, 6 decimals: **PASS**
- Symbol `USDt` matches official on-chain FA metadata name

### CSS Coverage
- All CSS classes referenced in components are defined in `styles.css`: **PASS**
- `.badge-pause` removed (Beta has no pause concept): N/A
- `.badge-sold` added for Hooks page sold state: **PASS**

### Error Handling
- All entry TX calls wrapped in try/catch with toast feedback: **PASS**
- All view function calls wrapped in try/catch: **PASS**
- No React error boundary (same as V1): ACCEPTED

### Edge Cases
- Empty pool list renders "No pools yet" state: **PASS**
- Disconnected wallet renders connect prompt: **PASS**
- Same-token swap blocked ("Select different tokens"): **PASS**
- Zero amount blocked ("Enter amount"): **PASS**
- Pool duplicate check before creation: **PASS**
- `sqrt(rawA * rawB) > 1000` check before creation: **PASS**

## 5. Architectural Changes from V1 Alpha

| Feature | V1 Alpha | Beta | Rationale |
|---|---|---|---|
| Swap routing | `pool::swap_entry` or `hook_wrapper::swap_entry` | `router::swap_with_deadline` | Unified with deadline protection |
| LP model | Fungible `lp_coin::balance` | NFT `LpPosition` objects via indexer | Per-position fee tracking |
| Hook system | Auction-based (`start_auction`) | Fixed-price escrow (`buy_hook`) | Eliminates auction attack surface |
| Pause | `pool::pause/unpause` | None | Immutable pools by design |
| Modules | 6 (pool, pool_factory, hook_wrapper, router, bridge, lp_coin) | 3 (pool, pool_factory, router) | Simplified core |
| Pages | 5 (Swap, Pools, Portfolio, Protocol, About) | 6 (+Hooks marketplace) | Hook NFT trading UI |
| Remove liquidity | From Pools page | From Portfolio page | Follows NFT ownership model |

## 6. Summary

- **18 view function calls:** ALL PASS
- **7 entry function calls:** ALL PASS
- **3 bugs found:** ALL FIXED before deploy
- **Social login:** Identical to V1
- **UX/responsive:** Identical patterns to V1
- **No outstanding issues**
