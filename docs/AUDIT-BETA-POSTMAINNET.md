# Darbitex Beta — Post-Mainnet Audit Cycle

**Package under review:** `0x2656e373ace5ccbc191aedaa65f12a50b9d4ea2b8e6f2d0166741994449c7ec2`
**Upgrade policy:** `compatible` (fixable in place via 3/5 multisig)
**Scope:** `pool.move`, `pool_factory.move`, `router.move`, `tests.move` as live on mainnet
**Cycle status:** 🟡 **COLLECTING** — more auditors in progress, no fixes applied yet

This document mirrors the pre-mainnet `AUDIT-BETA-REPORT.md` convention:
one section per auditor, each committed under that auditor's own git
author name. Findings are recorded verbatim as received. Triage,
disposition, and fix commits will happen only after all post-mainnet
auditors have returned — the pre-mainnet rounds showed that "action on
first finding" creates churn; batching per cycle is cleaner.

---

## Round 1 (post-mainnet) — Claude Opus 4.6 (fresh web session, extended thinking)

**Auditor:** Claude Opus 4.6 (Anthropic), fresh claude.ai web session with extended thinking enabled
**Date:** 2026-04-13
**Context:** First post-mainnet audit. Clean context, no prior session state. Same auditor category as the pre-mainnet R2/R3 "fresh Claude" rounds (git author `claude`), not to be confused with the in-session Claude that authored the code.
**Verdict:** 🟡 YELLOW — 3 MEDIUM / 4 LOW / 6 INFORMATIONAL

### Executive summary (verbatim)

DarbitexBeta is a constant-product AMM (x·y=k) on Aptos with LP-position
NFTs, a per-position fee accumulator, dual HookNFT fee streams, flash
loans, TWAP oracle, and a multi-hop router. The codebase shows evidence
of multiple prior audit rounds with fixes already applied (HIGH-1 reserve
accounting, buffer donation, u256 overflow, slippage floors, etc.).

**Overall assessment: The protocol is well-engineered for a Beta launch.**
The core invariant accounting is sound, reentrancy is properly guarded,
and the hot-potato flash loan pattern is correctly implemented. However,
I've identified several issues that range from medium to informational
severity that should be addressed or acknowledged before mainnet.

| Severity | Count |
|---|---|
| CRITICAL | 0 |
| HIGH | 0 |
| MEDIUM | 3 |
| LOW | 4 |
| INFORMATIONAL | 6 |

### MEDIUM findings

#### M-1 — Fee Accounting Insolvency Risk on Dust Swaps

**Location:** `pool.move:554–567`, `accrue_fee()`

When `amount_in` is very small (e.g., 1–99 units), `total_fee = amount_in * 1 / 10000` floors to **0**, but `extra_fee` floors up to **1** (line 556). In `accrue_fee`, the LP portion is `total_fee - extra_fee`, which saturates to 0 — fine. But `reserve_fee = extra_fee + lp_fee = 1 + 0 = 1`, meaning `reserve_a += amount_in - 1` while the hook buckets record 1 unit of claimable fee.

The problem: for `amount_in = 1`, `reserve_a += 0` but the hook accumulators promise 1 unit. Over many dust swaps, the hook fee buckets grow while no corresponding tokens back them. When the hook owner calls `claim_hook_fees`, the withdrawal may exceed the pool store balance, causing an abort (or, if the pool has enough surplus from rounding in other swaps, silently draining that surplus).

**Impact:** Slow insolvency of hook fee buckets via repeated dust swaps. An attacker could intentionally spray 1-unit swaps to inflate hook fees beyond store backing.

**Recommendation:** Guard the minimum swap amount (e.g., `assert!(amount_in >= BPS_DENOM, E_ZERO_AMOUNT)`) or cap `extra_fee` to never exceed `total_fee` — which would make hook fees 0 on dust swaps, consistent with LP fees.

#### M-2 — TWAP Oracle Is Trivially Manipulable (No Cumulative Price Ratio)

**Location:** `pool.move:234–242`

The TWAP accumulates raw reserves (`reserve_a * dt`, `reserve_b * dt`) rather than the *price ratio* (`reserve_a / reserve_b * dt`). This means the TWAP tracks aggregate liquidity depth over time, not price. If the intended use is as a price oracle (as the doc comment and Uniswap V2 comparison suggest), the current implementation does not serve that purpose.

Additionally, any on-chain consumer reading `twap_cumulative` values can be manipulated by a single large swap in the same block (no commit-reveal or multi-block averaging is enforced at the pool level).

**Impact:** Any protocol integrating the TWAP as a price feed will get incorrect data. If no one integrates it yet, the risk is deferred but the design should be documented as "not a price oracle."

**Recommendation:** Either (a) accumulate `(reserve_a * SCALE / reserve_b) * dt` (and vice versa) as Uniswap V2 does, or (b) clearly document the TWAP fields as "liquidity-depth accumulators, not price oracles" and rename them to avoid confusion.

#### M-3 — `remove_liquidity` Missing Reentrancy Lock

**Location:** `pool.move:734–810`

`claim_lp_fees` and `claim_hook_fees` both set `pool.locked = true` during execution (documented as defense-in-depth per audit round-2 MEDIUM-2). However, `remove_liquidity` — which also performs FA withdrawals from the pool store and claims accumulated fees in the same operation — does **not** set the reentrancy lock. While Aptos FA operations don't currently have reentrant callbacks, the defense-in-depth rationale applied to the claim functions should equally apply here for consistency.

**Impact:** If a future Aptos framework update introduces FA dispatch hooks (as the existing comments acknowledge is possible), `remove_liquidity` would be the unprotected entry point.

**Recommendation:** Add `assert!(!pool.locked, E_LOCKED); pool.locked = true;` at the start of `remove_liquidity` and `pool.locked = false;` before the return, matching the pattern in `claim_lp_fees`.

### LOW findings

#### L-1 — `add_liquidity` Division-by-Zero if `reserve_a` or `reserve_b` Reaches 0

**Location:** `pool.move:646–648, 659–661`

The optimal-amount computation divides by `pool.reserve_a` and `pool.reserve_b`. If either reserve were ever drained to 0 (e.g., via a bug in a future code path, or an extreme rounding edge case), `add_liquidity` would abort with an arithmetic error rather than a descriptive error code. Currently, the `MINIMUM_LIQUIDITY` lock and the `amount_out < reserve_out` check in `swap` prevent reserves from hitting 0 under normal operation, so this is defensive only.

**Recommendation:** Add an explicit `assert!(pool.reserve_a > 0 && pool.reserve_b > 0, E_INSUFFICIENT_LIQUIDITY)` at the top of `add_liquidity` for clarity.

#### L-2 — `pool_addresses` Vector in Factory Grows Unboundedly

**Location:** `pool_factory.move:65, 246`

Every pool creation appends to `pool_addresses: vector<address>`. On Aptos, global storage is charged per byte. Over thousands of pools, this vector becomes expensive to read (the `get_all_pools` view loads the entire vector). There is no mechanism to prune or cap it.

**Recommendation:** For mainnet longevity, consider switching to a `Table<u64, address>` (index → address) with a separate counter, or document a pool count ceiling, or accept the cost as a design tradeoff for enumeration convenience.

#### L-3 — `flash_borrow` Allows Borrowing Up to `reserve - 1`, Potentially Leaving Pool Illiquid

**Location:** `pool.move:967`

The check is `amount < reserve_in`, meaning a borrower can take `reserve - 1` of one side. During the locked borrow window, the pool is already protected. But the fee computation (`amount * 1 / 10000`) on very large borrows relative to reserves may floor to a small fee that doesn't adequately compensate for the risk of borrowing nearly all liquidity.

**Recommendation:** Consider a minimum reserve floor (e.g., `amount < reserve_in - MINIMUM_LIQUIDITY`) to mirror the LP withdrawal protection.

#### L-4 — `buy_hook` Payment Uses `aptos_account::transfer` (CoinStore, Not FA)

**Location:** `pool_factory.move:289`

`buy_hook` collects payment via `aptos_account::transfer`, which uses the legacy `CoinStore<AptosCoin>` path. If the admin revenue address hasn't initialized a `CoinStore<AptosCoin>`, the transfer will auto-create one, but this is the legacy coin path. The rest of the protocol uses Fungible Asset stores exclusively. This inconsistency is minor but worth noting — future Aptos deprecation of CoinStore could require migration.

**Recommendation:** Acknowledge or migrate to FA-based APT handling when feasible.

### INFORMATIONAL findings

#### I-1 — Hardcoded Multisig Addresses

`pool_factory.move` hardcodes `TREASURY_ADDR`, `ADMIN_ADDR`, and `REVENUE_ADDR` as constants. These cannot be rotated without a package upgrade. This is a deliberate design choice ("zero admin surface") but means key rotation requires redeployment under `compatible` upgrade policy.

**Status:** Acknowledged by design. Ensure the multisig signers have robust operational security, as compromise of the admin multisig allows hook price manipulation (though not fund theft).

#### I-2 — `schema_version` Fields Are Set But Never Checked

All structs include `schema_version: u8` set to 1, and `_reserved: vector<u8>` for forward compatibility. However, no code path checks `schema_version` or reads `_reserved`. This is fine for v1 but the upgrade path should be documented — specifically how a v2 Pool struct would coexist with v1 LpPositions.

#### I-3 — No `amount_in` Cap on Swaps

There is no maximum `amount_in` enforced in `swap()`. While the u256 math prevents overflow, a single enormous swap can move the price to an extreme ratio. This is standard for constant-product AMMs (arbitrage corrects it), but worth noting that there's no circuit-breaker.

#### I-4 — LP Position NFTs Are Non-Mergeable

Each `add_liquidity` call creates a separate `LpPosition` NFT. Users who add liquidity multiple times accumulate many positions, each with its own fee debt snapshot. There is no merge/compound function. This is a UX consideration — positions with different debt snapshots do correctly track fees independently, but managing many positions can be cumbersome.

#### I-5 — `swap()` Takes `swapper: address` as an Unverified Attribution Parameter

The `swapper` address in `pool::swap()` is used only for event emission — it has no authorization role (the FA was already withdrawn by the caller). A caller could pass any address as `swapper`, which means Swapped events may attribute volume to arbitrary addresses. This is harmless for protocol security but could pollute analytics.

#### I-6 — Test Coverage Gaps

The test suite is thorough for the happy path and key regressions. A few scenarios lack coverage:

- **Dust swap insolvency** (M-1): No test drives repeated 1-unit swaps and then claims hook fees to verify store solvency.
- **Concurrent multi-position fee claims**: No test creates multiple LpPositions on the same pool and verifies total fee claims don't exceed the pool's fee budget.
- **3-hop router happy path**: `test_router_2hop_via_third_token` covers 2-hop but there's no 3-hop happy-path test.
- **Edge case: adding liquidity to a pool with asymmetric reserves** (after swaps have moved the ratio).

### Architecture review (verbatim)

**What's Done Well**

- **Reserve accounting (post-fix):** The separation of `reserve_a/b` (principal only) from `lp_fee_per_share_a/b` (fee accumulator) and `hook_X_fee_a/b` (absolute hook buckets) is clean. The fix documented in HIGH-1 comments is correct — reserves track principal, fees are tracked separately, and withdrawals draw from the right buckets.
- **Flash loan design:** The hot-potato `FlashReceipt` pattern is the gold standard for Move flash loans. No `drop` ability means the receipt *must* be consumed in the same transaction. The k-invariant check on repay and the `locked` flag preventing nested borrows are both correct.
- **Canonical pool addressing:** Using `create_named_object` with a deterministic seed from the sorted pair metadata addresses guarantees one pool per pair. The framework's own `EOBJECT_EXISTS` check prevents duplicates without custom bookkeeping.
- **Fee accumulator math:** The global `lp_fee_per_share` + per-position `fee_debt` pattern (MasterChef-style) is correctly implemented with u256 intermediates to prevent overflow.
- **Slippage protection:** Present on swaps (`min_out`), LP add (`min_shares_out`), LP remove (`min_amount_a/b`), and per-hop in the router.

**Upgrade Policy**

The package is published with `upgrade_policy = "compatible"`, which allows adding new modules and new public functions, but not changing existing function signatures or removing public functions. This is appropriate for a protocol that may need to add features (e.g., a `meta_router` satellite) without breaking existing integrations.

### Conclusion (verbatim)

DarbitexBeta is a carefully constructed AMM with evidence of iterative hardening across multiple audit rounds. The core swap, LP, and flash loan mechanics are sound. The three medium-severity findings (dust swap fee insolvency, TWAP design mismatch, and missing reentrancy lock on `remove_liquidity`) should be addressed before mainnet launch. The low and informational items are quality-of-life improvements that can be deferred to a follow-up release.

**Recommendation: Fix M-1, M-2, and M-3 before mainnet deployment. The remaining items can be addressed in a subsequent upgrade.**

*This audit was performed by Claude Opus 4.6 on the source code provided. It is not a substitute for a formal audit by a dedicated security firm. The auditor has no financial interest in the project.*

---

## Round 2 (post-mainnet) — Kimi K2

**Auditor:** Kimi K2 (Moonshot AI)
**Date:** 2026-04-13
**Commit reviewed:** `26493354fa4f22528a81ad73b7f015900a678163`
**Verdict:** ✅ Conditional approval — 1 MEDIUM / 1 LOW / 1 INFO

### Executive summary (verbatim)

**Overall Assessment**: The codebase demonstrates **mature security practices** with evidence of multiple prior audit rounds. However, I identified **2 new issues** (1 Medium, 1 Low) and **1 informational** observation not documented in the inline audit comments.

### MEDIUM findings

#### M-1 — Missing Deadline Check on `add_liquidity_entry`

**Location:** `pool.move`, line ~1040

The entry wrapper `add_liquidity_entry` lacks deadline protection, exposing LPs to sandwich attacks on liquidity additions.

```move
public entry fun add_liquidity_entry(
    provider: &signer,
    pool_addr: address,
    amount_a: u64,
    amount_b: u64,
    min_shares_out: u64,  // Only slippage protection, no time bound
) acquires Pool {
    let _ = add_liquidity(provider, pool_addr, amount_a, amount_b, min_shares_out);
}
```

**Impact:** MEV bots can delay transaction inclusion until pool ratio shifts unfavorably, causing LP to deposit at worse rates than expected.

**Recommendation:** Add deadline parameter consistent with router pattern:

```move
public entry fun add_liquidity_entry(
    provider: &signer,
    pool_addr: address,
    amount_a: u64,
    amount_b: u64,
    min_shares_out: u64,
    deadline: u64,  // Add this
) acquires Pool {
    assert!(timestamp::now_seconds() < deadline, E_DEADLINE);
    // ...
}
```

**Status:** Not addressed in prior audits (new finding).

### LOW findings

#### L-1 — Inconsistent Error Code Reuse

**Location:** `pool.move`, multiple locations

Error code `E_INSUFFICIENT_LIQUIDITY` (code 2) is overloaded for semantically different failures:

| Line | Context | Actual Meaning |
|------|---------|--------------|
| ~540 | `flash_borrow` | Borrow amount exceeds reserves |
| ~680 | `remove_liquidity` | Post-burn supply below minimum |
| ~870 | `flash_repay` | Repayment amount mismatch |

**Impact:** Debugging difficulty; failed transactions return same error code for different root causes.

**Recommendation:** Differentiate error codes:
```move
const E_FLASH_BORROW_TOO_LARGE: u64 = 16;
const E_MIN_LIQUIDITY_LOCKED: u64 = 17;
const E_REPAY_AMOUNT_MISMATCH: u64 = 18;
```

### INFORMATIONAL findings

#### I-1 — Hardcoded Constants Limit Flexibility

**Location:** `pool.move`, lines 18-25

Critical parameters are hardcoded with no governance mechanism:

```move
const SWAP_FEE_BPS: u64 = 1;        // 0.01%
const FLASH_FEE_BPS: u64 = 1;       // 0.01%
const HOOK_SPLIT_PCT: u64 = 50;     // 50/50 split
const EXTRA_FEE_DENOM: u64 = 100_000;
```

**Risk:** If market conditions require fee adjustments (competitive pressure, MEV mitigation), protocol cannot adapt without module redeployment.

**Recommendation:** Consider factory-governed fee parameters stored in `Factory` struct for future iterations.

### Prior audit verification (verbatim)

| Prior Finding | Verification | Status |
|-------------|------------|--------|
| **HIGH-1**: Reserve tracking in flash loans | `flash_borrow` does NOT decrement reserves; only fee accrued in `flash_repay` | ✅ Fixed |
| **MEDIUM-1**: u128 overflow in swap math | All swap math uses `u256` intermediates before casting to `u64` | ✅ Fixed |
| **MEDIUM-2**: Reentrancy on fee claims | `pool.locked = true` set in `claim_lp_fees` and `claim_hook_fees` | ✅ Fixed |
| **MEDIUM-1 (Round 3)**: Multi-hop sandwich | Per-hop `min_out` parameters on all router functions | ✅ Fixed |
| **LOW-2**: Exact repayment check | `assert!(fungible_asset::amount(&fa_in) == repay_total, ...)` | ✅ Fixed |

### Security scorecard (verbatim)

| Category | Rating | Notes |
|----------|--------|-------|
| **Access Control** | ✅ Strong | Multisig-governed, no single admin |
| **Reentrancy** | ✅ Protected | `locked` flag on all state-mutating functions |
| **Integer Safety** | ✅ Robust | u256 intermediates, explicit casting |
| **Economic Security** | ⚠️ Moderate | 1 bps fee may be MEV-extractable on shallow pools |
| **Composability** | ✅ Excellent | Clean FA-in/FA-out primitives |
| **Upgradeability** | ❌ None | Move immutability - plan for v2 migration |

### Final recommendation (verbatim)

**Conditional Mainnet Readiness**: ✅ **APPROVED** with minor fixes

**Required before deployment**:
1. Add deadline parameter to `add_liquidity_entry` (MEDIUM-1)
2. Consider differentiating error codes for operational clarity (LOW-1)

**Post-deployment monitoring**:
- Track MEV extraction rates on low-liquidity pools
- Monitor Hook NFT secondary market pricing vs. fee yield

*Audit conducted on 2026-04-13 against commit `26493354fa4f22528a81ad73b7f015900a678163`*

---

## Pending auditors (post-mainnet cycle)

Additional AI auditors will be distributed the same source. Sections will be appended to this document as findings come in, each as a separate commit under the auditor's own git author name:

- Gemini 2.5 Pro — pending
- DeepSeek — pending
- Grok 4 — pending
- Qwen — pending
- ChatGPT (GPT-5) — pending
- Others TBD

Consolidated triage, false-positive rebuttals, and fix commits will be batched at the end of the cycle — not per-auditor.
