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

## Round 3 (post-mainnet) — Grok 4

**Auditor:** Grok 4 (xAI)
**Date:** 2026-04-13
**Verdict:** 🟢 GREEN — 0 CRITICAL / 0 HIGH / 0 MEDIUM / 3 LOW / 4 INFO
**Security rating:** 8.7/10

### Executive summary (verbatim)

**Security Rating: HIGH (8.7/10)**
**Mainnet Readiness: YES — with only minor/low recommendations**

The codebase is **excellent** for an Aptos constant-product AMM. It is clean, heavily tested, and already incorporates fixes for previous high/medium findings (explicitly referenced in the tests). Architecture is modular, uses best-practice Aptos patterns, and has strong defense-in-depth.

**Strengths**
- Deterministic canonical pools (no duplicate-pool risk)
- Excellent reentrancy protection (`locked` flag)
- Proper reserve vs. accumulator separation (fixes the HIGH-1 LP-fee double-counting bug)
- Flash-loan accounting is now correct (no reserve inflation)
- Per-hop slippage in router (addresses MEV sandwich risk)
- Soulbound HookNFT #1 + escrowed HookNFT #2 revenue mechanism
- u256 math everywhere critical paths could overflow
- Extremely thorough test suite (including regression tests for past audit issues)

### Severity summary

| Severity | Count | Summary |
|----------|-------|--------|
| **Critical** | 0 | None |
| **High** | 0 | None |
| **Medium** | 0 | None (all previous MEDIUMs fixed) |
| **Low** | 3 | Minor improvements |
| **Info** | 4 | Non-security notes |

### LOW findings

#### L-1 — Minor gas optimization in `accrue_fee` (pool.move)

The line `let lp_portion = if (total_fee > extra_fee) { total_fee - extra_fee } else { 0 };` is correct but can be simplified to `let lp_portion = total_fee.saturating_sub(extra_fee);` (using `u64::saturating_sub`). Current code is safe and readable. Not a bug.

#### L-2 — Timestamp manipulation surface (router + pool)

`swap_with_deadline`, `update_twap`, etc. rely on `timestamp::now_seconds()`. Aptos timestamps are not perfectly manipulable (validators have ~1–2 s leeway), but very large deadlines or TWAP windows could theoretically be gamed by a validator cartel.

**Recommendation:** Document that users should use reasonable deadlines (e.g., 15–60 minutes). Not exploitable in practice.

#### L-3 — No emergency pause / kill-switch

There is no global pause or admin emergency withdraw. In a catastrophic bug (e.g., future Aptos framework change), funds would be stuck until upgrade.

**Recommendation (optional):** Add a `paused: bool` flag + `emergency_withdraw` (only callable by multisig) to the Factory. Many production DEXes have this.

### INFORMATIONAL findings

#### I-1 — Excellent event coverage
Every state-changing function emits a rich event. Great for indexers/dashboards.

#### I-2 — Schema version fields
All structs have `schema_version: u8` and `_reserved: vector<u8>`. Forward-compatible upgrade pattern done correctly.

#### I-3 — Admin / Treasury addresses are hardcoded
Correct for mainnet (multisig addresses). No risk, but make sure the 3-of-5 and 2-of-3 multisigs are live and properly governed.

#### I-4 — Tests are outstanding
Regression tests for the exact HIGH-1 bug that was fixed. Coverage of same-pool abort, unsorted pairs, soulbound NFT transfer abort, flash-loan exact-repay, multi-hop, etc. The test suite alone would pass most auditors' checklist.

### Architecture & best practices (verbatim)

| Area | Status | Notes |
|---|---|---|
| Reentrancy | Protected | `locked` flag + `assert!(!pool.locked)` |
| Invariant (x × y = k) | Preserved | Flash repay k-check + correct reserve accounting |
| Overflow | Safe | u256 in all swap/LP math |
| Access Control | Strict | Only `@darbitex` can init, only `ADMIN_ADDR` can set price |
| Canonical pools | Perfect | Named-object + BCS-sorted metadata |
| HookNFT revenue split | Correct | 50/50 split of extra_fee (0.001%) |
| Flash loan accounting | Fixed | No reserve inflation (HIGH-1 fix) |
| Multi-hop MEV protection | Strong | Per-hop `min_out` (audit MEDIUM-1 fixed) |
| Primary store integration | Clean | Router entry functions are user-friendly |

### Final verdict (verbatim)

**This code is mainnet-ready.** It is one of the cleaner Aptos DEX implementations I have audited. The team clearly learned from previous audit rounds (the regression tests and comments prove it). No critical or high issues exist. **You can deploy with high confidence.**

---

## Round 4 (post-mainnet) — Claude Opus 4.6 (in-session self-audit)

**Auditor:** Claude Opus 4.6 (Anthropic), same session as the developer who authored the code. Conflict-of-interest disclaimer: I wrote the code I'm reviewing. This is a sanity pass, not a substitute for external review.
**Date:** 2026-04-13
**Verdict:** 🟡 YELLOW — 0 HIGH / 0 MEDIUM / 3 LOW / 3 INFO, plus cross-auditor opinions on prior-round findings.

### New findings (not yet flagged by other post-mainnet auditors)

#### L-1 — Flash fee math uses u64 multiplication without u256 intermediates

**Location:** `pool.move:973`

```move
let fee_raw = amount * FLASH_FEE_BPS / BPS_DENOM;
```

Unlike the swap path which wraps all intermediates in `u256` (`pool.move:543-546`), the flash borrow fee uses raw u64 multiplication. With `FLASH_FEE_BPS = 1` this cannot overflow today (`u64::MAX * 1 < u64::MAX`), but the inconsistency is a footgun: any future `FLASH_FEE_BPS` bump (say to 30 for 0.3%) combined with `amount` near `u64::MAX` would overflow. The swap-side discipline ("always u256 for fee intermediates") should apply uniformly.

**Impact:** None at current constants. Defensive only.

**Recommendation:** Mirror the swap pattern: `let fee_raw = (((amount as u256) * (FLASH_FEE_BPS as u256) / (BPS_DENOM as u256)) as u64);`.

#### L-2 — `add_liquidity` optimal-amount cast can abort on pathologically skewed reserves

**Location:** `pool.move:645-648`, `pool.move:658-661`

```move
let amount_b_optimal = (
    ((amount_a_desired as u256) * (pool.reserve_b as u256)
        / (pool.reserve_a as u256)) as u64
);
```

If a pool is created with an extreme ratio (e.g., `reserve_a=1`, `reserve_b=2^63` — permitted today as long as `sqrt(a*b) > MINIMUM_LIQUIDITY`), then large `amount_a_desired` values make the u256 intermediate exceed `u64::MAX`, and the final `as u64` cast aborts with Move's arithmetic error rather than `E_DISPROPORTIONAL`. The pool becomes effectively frozen for growth from one side.

**Impact:** DoS on pathologically mis-seeded pools. Requires intentional bad seeding at create time (real APT/USDC-shaped pools are nowhere near this regime). No safety implication, only UX / frozen-pool risk for bad configs.

**Recommendation:** Either clamp the u256 result to `u64::MAX` before casting and handle the abort with a clearer error, or add an explicit `assert!(amount_b_optimal_u256 <= u64::MAX, E_INSUFFICIENT_LIQUIDITY)` pre-cast.

#### L-3 — `update_twap` not called in `claim_hook_fees` (cosmetic asymmetry)

**Location:** `pool.move:880-938`

`claim_lp_fees` calls `update_twap(pool)` (line 840); `claim_hook_fees` does not. Neither function mutates reserves, so the TWAP cumulative is semantically unaffected — the next reserve-mutating call will still accumulate the correct `reserve × dt` contribution spanning the claim. But the code is asymmetric for no reason; a reader glancing at the two functions would wonder whether the difference is load-bearing.

**Impact:** None. Cosmetic only.

**Recommendation:** Either add `update_twap(pool);` to `claim_hook_fees` for consistency, or remove it from `claim_lp_fees` (R2 self-audit noted it as redundant there — gas cost).

### Informational

#### I-1 — Hook split always rounds in favor of hook_2 (escrow slot)

**Location:** `pool.move:254-255`

```move
let hook_1_portion = extra_fee * HOOK_SPLIT_PCT / 100;
let hook_2_portion = extra_fee - hook_1_portion;
```

For `extra_fee = 1`: hook_1=0, hook_2=1. For `extra_fee = 3`: hook_1=1, hook_2=2. Odd `extra_fee` always gives the extra unit to hook_2 (escrow slot, tradable). Pre-mainnet R1 self-audit flagged this as "dust asymmetry" and accepted it. Re-noting for visibility: on dust-heavy flows the **treasury hook (slot 0) is under-compensated** relative to the tradable hook (slot 1). Dust-spray attacks therefore inflate the escrow slot's bucket, not the treasury's — which is a mild positive for treasury safety and a mild negative for treasury revenue.

#### I-2 — `hook_listing_price` view aborts on unknown pool

**Location:** `pool_factory.move:384-387`

```move
*table::borrow(&f.hook_listings, pool_addr)
```

Should be wrapped with `table::contains` check or return `Option<u64>`. Frontends calling this for a pool that has already been bought (listing removed) will get an abort instead of a clean "not listed" signal. UX-only nit for integrators.

#### I-3 — `buy_hook` has no deadline parameter

**Location:** `pool_factory.move:269-306`

Price is locked at listing time, so no economic exposure from mempool delay. But a buyer who wants to cancel a stalled TX has no escape hatch. Unlike the router which gates every entry on a deadline, this one is unconditional. Extremely low severity; noting for completeness.

### Cross-auditor opinions on prior findings

#### Fresh Claude M-1 (dust swap insolvency) — **I believe this is a FALSE POSITIVE**

I traced the arithmetic at `pool.move:554-575` with `amount_in = 1`:

- `total_fee = 1 * 1 / 10000 = 0`
- `extra_fee_raw = 1 / 100_000 = 0` → `extra_fee = 1` (floored)
- `accrue_fee(pool, 0, 1, a_side=true)`: `hook_1_portion = 1*50/100 = 0`, `hook_2_portion = 1 - 0 = 1`, `lp_portion = 0` (saturated since `total_fee ≤ extra_fee`)
- Returns `(lp_fee=0, hook_1_fee=0, hook_2_fee=1)`
- `reserve_fee = extra_fee + lp_fee = 1 + 0 = 1`
- `pool.reserve_a = pool.reserve_a + 1 - 1 = pool.reserve_a + 0` (unchanged)
- `pool.reserve_b -= amount_out = 0` (amount_out floors to 0)
- Store: `+1` (deposit `fa_in`) and `-0` (withdraw `fa_out`). Net store delta: `+1`.
- Tracked delta: `reserve_a +0`, `hook_2_fee_a +1`. Net tracked: `+1`. ✅

The fresh-Claude reading that "`reserve_a += amount_in - 1` while hook records 1 unit unbacked" mis-reads line 567: the reserve update is `amount_in - reserve_fee = amount_in - (extra_fee + lp_fee)`, not `amount_in - extra_fee` only. The hook bucket increment is exactly matched by the reserve shortfall. Solvency invariant holds.

I recommend that at triage phase, fresh-Claude M-1 be marked FALSE POSITIVE with a regression test driving repeated dust swaps and asserting `store_balance == reserve + hook_1 + hook_2 + lp_pending_sum` after each.

#### Fresh Claude M-2 (TWAP not a price oracle) — **Agreed, design clarification**

The `twap_cumulative_a/b` fields do accumulate `reserve × dt`, not `price × dt`. The doc comment on `update_twap` ("Uniswap V2 style") is misleading. I recommend Option A (doc-only rename to "liquidity-depth cumulative") over Option B (add real price-cumulative fields). Rationale: no satellite consumes these fields as a price oracle today, and adding fields via compat upgrade is a bigger surface than just correcting the doc comment. The meta_router satellite can compute price TWAP off-chain from the reserve history if ever needed.

#### Fresh Claude M-3 (`remove_liquidity` missing lock) — **Agreed, accept**

Confirmed at `pool.move:734-810`: asserts `!pool.locked` but never sets it during execution. Inconsistent with the R2 hardening of `claim_lp_fees`/`claim_hook_fees`. Compat-safe fix: bracket body with `pool.locked = true; ... pool.locked = false;` before each return path.

#### Kimi M-1 (`add_liquidity_entry` missing deadline) — **Agreed, but compat-breaking**

Adding a new parameter to a `public entry fun` is a compat break under Aptos compat policy — existing callers lose. Proper fix is to add a sibling `add_liquidity_entry_v2(provider, pool_addr, amount_a, amount_b, min_shares_out, deadline)` and deprecate the old one via doc comment. Cannot modify `add_liquidity_entry` in place.

Same applies to `remove_liquidity_entry`, `claim_lp_fees_entry`, `claim_hook_fees_entry` — none have deadlines. Kimi only flagged `add_liquidity_entry`; the others have the same gap.

#### Grok L-3 (no emergency pause) — **Disagree, reject**

Grok's "add `paused: bool` + `emergency_withdraw`" recommendation directly contradicts Beta's explicit **zero admin surface** design principle (locked in `darbitex_beta_plan.md` as Core Principle #2: "After `create_canonical_pool` returns, no function anywhere in Beta core can alter fee, curve, pair, or hook assignment. Zero admin surface at the pool level."). Adding a pause would reintroduce the exact admin-pause-risk category Beta was designed to eliminate. Users chose Beta specifically because their LP positions cannot be frozen by any multisig vote.

Recommendation: document the design rationale in the triage response. Accept Grok's observation ("there is no pause") as a factually correct statement that describes the design, not as a finding to fix.

### Summary

3 new LOWs I found on top of prior-round findings. Net cycle state:

| Finding | Origin | My position |
|---|---|---|
| Dust swap insolvency | Fresh Claude M-1 | FALSE POSITIVE (verified by trace) |
| TWAP not price oracle | Fresh Claude M-2 | Accept, doc-only fix |
| `remove_liquidity` missing lock | Fresh Claude M-3 | Accept, compat-safe fix |
| `add_liquidity_entry` deadline | Kimi M-1 | Accept, needs `_v2` sibling (+ same for other entry wrappers) |
| No emergency pause | Grok L-3 | Reject, conflicts with design principle |
| Flash fee u256 | this audit L-1 | Accept, defensive |
| add_liquidity cast on extreme ratios | this audit L-2 | Accept, defensive |
| `update_twap` asymmetry | this audit L-3 | Cosmetic |
| Hook split rounding | this audit I-1 | Known, accepted R1 |
| `hook_listing_price` view aborts | this audit I-2 | UX only |
| `buy_hook` no deadline | this audit I-3 | Completeness only |

Still awaiting: Gemini, DeepSeek, Qwen, ChatGPT. No fixes until cycle ends.

---

## Round 5 (post-mainnet) — Gemini 2.5 Pro

**Auditor:** Gemini 2.5 Pro (Google)
**Date:** 2026-04-13
**Verdict:** 🟡 YELLOW — 0 HIGH / 0 MEDIUM / 1 LOW (TWAP bricking) / 2 INFO

### Executive summary (verbatim)

The DarbitexBeta protocol demonstrates a high standard of defensive programming. The developers have clearly integrated learnings from previous audits, particularly regarding sandwich attacks, overflow risks, and flash loan reserve accounting. The codebase is well-structured and uses Aptos standards effectively.

### Code quality & defenses (verbatim)

- **Robust Multi-Hop Slippage Protection:** The `router.move` module enforces per-hop minimum outputs (`min_out_hop1`, `min_out_hop2`, etc.) for multi-hop swaps. This effectively mitigates intermediate sandwich attacks where an attacker might extract value from unprotected middle routing pools.
- **Overflow Preventions in AMM Math:** The `pool.move` module correctly casts values to `u256` before performing intermediate multiplications in the $x \cdot y = k$ swap equation. This addresses the risk of `u128` overflows when both `amount_in` and `reserve_out` are near their maximum `u64` limits.
- **Flash Loan Reserve Accounting:** The contract correctly avoids inflating pool reserves during a flash loan. The `flash_borrow` function does not deduct from reserves, and `flash_repay` does not add the principal back to the reserves.
- **Strict Equality on Repayment:** The `flash_repay` function enforces strict equality (`repay_total == amount + fee`). This ensures users do not accidentally trap excess funds in the pool's primary store due to clumsy slippage or overpayment.
- **Reentrancy Protections:** Although Aptos Fungible Asset (FA) transfers currently lack dynamic dispatch hooks that allow reentrancy, the code includes a `pool.locked` boolean flag to guard against future framework updates.
- **First-Depositor Attack Mitigation:** During pool creation, a dead `MINIMUM_LIQUIDITY` (1,000 shares) is locked to prevent inflation attacks from the first depositor.

### Findings

#### L-1 — TWAP Accumulator Bricking Risk

**Location:** `pool.move:234-242`

The Time-Weighted Average Price (TWAP) accumulator calculates updates using `pool.twap_cumulative_a + (pool.reserve_a as u128) * (dt as u128)`. Unlike Solidity, where variables can silently wrap around on overflow, Move arithmetic aborts on overflow by default. If a pool holds a massive reserve of high-decimal tokens and runs for many years, this `u128` addition could eventually overflow. This would abort the `update_twap` call, effectively bricking the pool for all future swaps.

**Recommendation:** Consider tracking cumulative prices using `u256` or implementing a safe, explicit wrapping math mechanism to ensure perpetual pool longevity.

#### I-1 — Unguarded `buy_hook` Front-running

**Location:** `pool_factory.move`

The `buy_hook` function allows permissionless purchasing of HookNFT #2 from the factory escrow at a listed price. Because `set_hook_price` only impacts *future* pools, if an admin sets a higher price, a bot might front-run a pool creation to buy the hook at the old price before the ecosystem realizes it.

**Recommendation:** This is likely acceptable given the design, but frontends should be aware of this dynamic.

#### I-2 — Zero-Value Swap Edge Cases

**Location:** `pool.move` `swap()` / `accrue_fee()`

While `swap_with_deadline` enforces `amount_in > 0`, the internal `swap` function floors the swap fee logic. For "dust swaps," the protocol explicitly forces `extra_fee` to a minimum of 1 so that these tiny swaps still generate hook revenue.

**Recommendation:** Validate that these forced minimal fees cannot be exploited in loops to drain small user balances unexpectedly.

---

## Round 6 (post-mainnet) — ChatGPT (GPT-5)

**Auditor:** ChatGPT / GPT-5 (OpenAI)
**Date:** 2026-04-13
**Verdict:** 🟠 ORANGE (self-reported B+) — 2 HIGH / 4 MEDIUM / 3 LOW / design notes

### Strengths validated (verbatim)

- **Reserve accounting (HIGH-1 fix):** Correct — reserves now track principal only. Fees routed via LP accumulator + hook buckets. No double counting in `swap()` or `flash_repay()`.
- **Flash loan design:** Uses hot-potato receipt → cannot be dropped. Enforces exact repayment equality. Correct invariant intent (`k_before`).
- **u256 usage:** Good coverage for overflow-critical paths.
- **Optimal liquidity provision:** Prevents silent donation bug (Uniswap V2 parity).

### HIGH findings

#### H-1 — Missing explicit k-invariant enforcement in `flash_repay`

**Auditor's claim:** "You *record* `k_before`, but I do NOT see enforcement… no visible check like `assert!(k_after >= k_before, E_K_VIOLATED);`"

**Impact (per auditor):** "An attacker can borrow token A, manipulate pool via external state (if composability expands later), repay nominally but break invariant silently." Rated HIGH.

**Recommendation (per auditor):**
```move
let k_after = (pool.reserve_a as u256) * (pool.reserve_b as u256);
assert!(k_after >= k_before, E_K_VIOLATED);
```

#### H-2 — Reentrancy lock not fail-safe (panic = permanent lock risk)

**Auditor's claim:** "If any abort happens after locking → pool remains permanently locked." Affected: `swap`, `flash_borrow`, `claim_lp_fees`, `claim_hook_fees`. Rated HIGH.

**Recommendation (per auditor):** "Minimize lock window, or structured pattern:"
```move
pool.locked = true;
let result = (|| { /* logic */ })();
pool.locked = false;
result
```

### MEDIUM findings

#### M-1 — Dust swap fee extraction can exceed intended fee model

```move
let extra_fee = if (extra_fee_raw == 0 && amount_in > 0) { 1 } else { extra_fee_raw };
```

For very small trades: `total_fee = 0`, `extra_fee = 1`, so user pays 1 unit fee even if trade is tiny. Breaks fee predictability, allows griefing, micro-swap exploitation, distorted price behavior.

**Recommendation:** Cap `extra_fee = min(extra_fee, total_fee)` or enforce a minimum trade size.

#### M-2 — LP fee accumulator precision loss over time

```move
let add = (lp_portion as u128) * SCALE / (pool.lp_supply as u128);
```

Integer division truncation — lost dust permanently. Long-term LPs are underpaid and the protocol accumulates invisible value. Not critical but noticeable at scale.

**Fix (optional):** track remainder bucket or accumulate dust.

#### M-3 — No slippage protection in `flash_borrow`

Flash borrow only checks `amount < reserve_in` — no price / state validation. Currently safe due to `locked = true`, but if future hooks or callbacks added → unsafe. Document assumption or enforce stricter invariant checks.

#### M-4 — TWAP can be manipulated within single transaction window

TWAP only updates on interaction. Attacker can manipulate reserves, trigger update, revert position later. Oracle consumers vulnerable. Fix: enforce minimum time window externally or recommend off-chain TWAP usage.

### LOW findings

#### L-1 — Hook fee claim drains without rate limiting

```move
pool.hook_1_fee_a = 0;
```

Entire bucket claimable instantly — MEV race on hook NFT ownership transfers.

#### L-2 — No explicit NFT burn event on LP position removal

`LiquidityRemoved` is emitted but no dedicated NFT burn event — indexers must infer.

#### L-3 — Hardcoded constants reduce flexibility

`SWAP_FEE_BPS = 1`, `FLASH_FEE_BPS = 1` — not upgradeable without contract upgrade.

### Design-level observations (verbatim)

**Strong architecture:** Clean separation of pool / factory / router. Object model well used. NFT-based LP = modern and flexible.

**Biggest latent risk:** "Your system is safe today because of assumptions, not enforcement." Main assumptions: no callbacks, no composability hooks, no cross-module interactions. History shows these assumptions break over time.

### Final verdict (verbatim)

**Security posture: B+ (production viable, but not battle-hardened yet)**

Critical to fix before serious TVL:
1. Add **k-invariant check in flash_repay**
2. Harden **lock mechanism**
3. Fix **dust fee asymmetry**

---

## Round 7 (post-mainnet) — Qwen

**Auditor:** Qwen (Alibaba)
**Date:** 2026-04-13
**Verdict:** 🟢 LOW overall — 0 HIGH / 0 MEDIUM / 1 LOW / 2 INFO

### Executive summary (verbatim)

The Darbitex Beta source code represents a mature, production-ready AMM primitive on Aptos. The codebase demonstrates rigorous engineering practices, extensive defense-in-depth measures, and explicit incorporation of fixes from multiple prior audit rounds. **No Critical or High severity vulnerabilities were identified.** The contract correctly handles fee accounting, flash loan invariants, reentrancy guards, slippage protection, and deterministic pool creation.

### LOW findings

#### L-1 — Inconsistent Reentrancy Guard in `add_liquidity`

**Location:** `pool.move::add_liquidity`

All mutating pool functions (`swap`, `remove_liquidity`, `claim_lp_fees`, `claim_hook_fees`, `flash_borrow`, `flash_repay`) explicitly set `pool.locked = true` at entry and `false` at exit. `add_liquidity` checks `!pool.locked` but does not toggle it.

**Impact:** Currently negligible. Aptos' `primary_fungible_store` does not support callback hooks, making synchronous reentrancy impossible today. However, if Aptos introduces FA dispatch hooks in a future framework upgrade, this function would become vulnerable to reentrancy.

**Recommendation:** Add `pool.locked = true;` after the `assert!(!pool.locked, E_LOCKED);` check, and `pool.locked = false;` before the final return. This aligns with the defense-in-depth philosophy already documented in `claim_lp_fees`.

> **Note (in-session observation):** Qwen's claim that `remove_liquidity` sets the lock is factually wrong — fresh Claude R1 (post-mainnet) independently flagged `remove_liquidity` as missing the exact same lock bracket. Together, the two findings reveal that **both** `add_liquidity` and `remove_liquidity` have the defense-in-depth gap that `claim_*` functions got in pre-mainnet R2.

### INFORMATIONAL findings

#### I-1 — Hardcoded Multisig & Revenue Addresses

**Location:** `pool_factory.move` (`TREASURY_ADDR`, `ADMIN_ADDR`, `REVENUE_ADDR`)

Critical operational addresses are hardcoded as constants. While acceptable for a beta, key compromise or multisig rotation would require a full package upgrade. Operational flexibility is reduced.

**Recommendation:** For v1.0+, consider a `GovernanceConfig` object stored at `@darbitex` that holds these addresses. The factory could borrow it at runtime, allowing admin rotation without code upgrades.

#### I-2 — `schema_version` Unused for Upgrade Migration

**Location:** All core structs (`Pool`, `LpPosition`, `HookNFT`, `Factory`)

Each struct includes `schema_version: u8` and `_reserved: vector<u8>`, which is excellent for `compatible` upgrade padding. However, no version-checking or migration logic exists. Document a migration strategy for future upgrades.

### Positive security controls (verbatim)

1. **Flash loan solvency invariant:** `flash_borrow` intentionally leaves reserves untouched. `flash_repay` deposits `amount + fee` into the store but routes the fee only to LP/Hook accumulators, never to `reserve_a/b`. The `k_after >= k_before` check acts as a robust safety net.
2. **Per-hop sandwich protection:** `swap_2hop_composable` and `swap_3hop_composable` enforce `min_out` on every intermediate hop, not just the final output.
3. **Dust swap fee floor:** `extra_fee = if (extra_fee_raw == 0 && amount_in > 0) { 1 } else { extra_fee_raw };` ensures hook fee buckets accumulate revenue even on sub-basis-point swaps.
4. **Deterministic canonical pool creation:** Uses `object::create_named_object` with `POOL_SEED_PREFIX || bcs(meta_a) || bcs(meta_b)`. Duplicate pair creation aborts at the framework level.
5. **LP fee accounting architecture:** Global `lp_fee_per_share` accumulator + per-position `fee_debt` snapshots. Avoids O(N) fee distribution and prevents double-counting.
6. **Comprehensive test coverage:** Happy paths, slippage aborts, buffer-return logic, TWAP accumulation, flash loan strict equality, hook soulbound enforcement, historical regression cases.

### Recommendations table (verbatim)

| Area | Recommendation | Priority |
|------|----------------|----------|
| `add_liquidity` | Add `pool.locked = true/false` toggle for future-proofing against FA callback hooks. | Low |
| Governance | Replace hardcoded addresses with a fetchable `GovernanceConfig` object for key rotation. | Low |
| TWAP Oracle | Document expected latency & block-time assumptions for oracle consumers. | Info |
| Event Indexing | Ensure off-chain indexers parse `Object<LpPosition>` and `Object<HookNFT>` addresses correctly. | Info |
| Upgrade Planning | Draft a migration script template for `compatible` upgrades. | Info |

### Conclusion (verbatim)

The Darbitex Beta codebase is **secure, well-architected, and production-ready** for its current scope. With the minor defense-in-depth adjustment to `add_liquidity` and consideration of a governance config object for future operational flexibility, the protocol is well-positioned for mainnet scaling. No code changes are required prior to continued operation.

---

## Round 8 (post-mainnet) — DeepSeek

**Auditor:** DeepSeek
**Date:** 2026-04-13
**Verdict:** ✅ Recommended for deployment — 0 HIGH / 3 MEDIUM / 3 LOW / 3 INFO

### Executive summary (verbatim)

The code demonstrates a strong understanding of Move and the Aptos object model. The most critical vulnerability identified in prior audits (double-counting of LP fees leading to insolvency) has been correctly mitigated in the current version. **No new Critical or High severity issues were found.** We did identify several Medium and Low issues, primarily related to economic edge cases, rounding behavior, and minor implementation quirks.

### Findings summary

| ID | Title | Severity | Status |
|----|-------|----------|--------|
| M-01 | Flash loan fee can be smaller than `EXTRA_FEE_DENOM` portion, causing hook fee miscalculation | Medium | Requires fix |
| M-02 | `get_amount_out` may return zero for very small input amounts | Medium | Acceptable risk |
| M-03 | First depositor can set extreme initial ratio, causing loss for subsequent LPs | Medium | Acknowledged |
| L-01 | `add_liquidity` may mint zero shares due to rounding | Low | Mitigated |
| L-02 | `claim_hook_fees` does not check `slot` bounds | Low | Redundant |
| L-03 | `flash_repay` strict equality may cause unnecessary reverts | Low | Design choice |
| I-01 | TWAP accumulator can be manipulated via flash loans | Informational | Known |
| I-02 | `pending_from_accumulator` can underflow in extreme scenarios | Informational | Safe |
| I-03 | Unused `E_SYMMETRIC_REQUIRED` error code | Informational | Cleanup |

### MEDIUM findings

#### M-01 — Flash loan fee naming / comment mismatch

**Location:** `pool::flash_repay`

```move
let extra_fee_raw = amount / EXTRA_FEE_DENOM;
let extra_fee = if (extra_fee_raw == 0) { 1 } else { extra_fee_raw };
let extra_fee = if (extra_fee > fee) { fee } else { extra_fee };
```

For small flash borrows where `fee < extra_fee_raw`, `extra_fee` is capped to `fee`, meaning the entire flash fee goes to hook buckets and LP portion becomes zero. This is intentional and matches the swap path, but the variable naming `extra_fee` (meaning "hook portion") can mislead readers into thinking it should always be strictly less than `fee`.

**Impact:** No direct security impact; fee accounting remains correct. Confusion could cause a regression on future refactor.

**Recommendation:** Rename `extra_fee` to `hook_fee_portion` and clarify in comments that it may equal the entire flash fee for small borrows.

#### M-02 — `get_amount_out` may return zero for very small input

**Location:** `pool::get_amount_out`

Due to integer division and the fee wedge, very small `amount_in` values yield `0`. Mathematically correct but can mislead off-chain integrators. Front-ends might display zero output, causing users to submit swaps with `min_out = 0` that then abort in `swap` (because `amount_out == 0` triggers `E_INSUFFICIENT_LIQUIDITY`).

**Impact:** UX/off-chain issue, not on-chain vulnerability.

**Recommendation:** Document that `get_amount_out` may return zero for dust amounts, or return `option::none()` in such cases.

#### M-03 — First depositor can set extreme initial ratio

**Location:** `pool::create_pool`

The first LP (pool creator) can freely choose `amount_a` and `amount_b`. Mispricing loss is absorbed by the creator via arbitrage; subsequent LPs are protected by `add_liquidity`'s optimal-amount path. Standard Uniswap V2 property.

**Impact:** No direct exploit; economic risk for early LPs who misprice.

**Recommendation:** Front-end guidance to pool creators. No code change requested.

### LOW findings

#### L-01 — `add_liquidity` may mint zero shares due to rounding

For very small `amount_a`/`amount_b` relative to reserves, both `lp_a` and `lp_b` can round to 0, aborting with `E_ZERO_AMOUNT`. Acceptable — prevents dust attacks. No action required.

#### L-02 — `claim_hook_fees` does not check `slot` bounds

The function branches on `slot == 0` vs `else`. If a malicious `HookNFT` with `slot ∉ {0, 1}` existed, the `else` branch would claim from slot 1 buckets. Not exploitable today (only slots 0 and 1 are minted by factory).

**Recommendation:** Defense-in-depth — assert `slot == 0 || slot == 1`, or match both explicitly with abort for unexpected slots.

#### L-03 — `flash_repay` strict equality may cause unnecessary reverts

Exact `==` repayment check prevents surplus donation but causes 1-unit-off miscalculations to abort. Design choice per pre-mainnet R1 LOW-2 rationale. Consider `>=` with excess return, or keep as-is with clear docs.

### INFORMATIONAL findings

#### I-01 — TWAP accumulator can be manipulated via flash loans

`update_twap` uses current reserves. A flash loan can temporarily skew reserves and influence TWAP contribution for that block. Known V2 oracle limitation; mitigated by sufficiently long averaging windows.

**Recommendation:** Document single-block manipulation susceptibility.

#### I-02 — `pending_from_accumulator` underflow guard verified

The `if (per_share_current <= per_share_debt) return 0;` guard safely avoids underflow, and u256 intermediates prevent overflow. No action needed.

#### I-03 — Unused `E_SYMMETRIC_REQUIRED` error code

Error code slot 9 is reserved with a comment (`E_RESERVED_9`, was `E_SYMMETRIC_REQUIRED` in early drafts, removed during symmetric-seeding removal delta). Remove or repurpose in a future upgrade.

### Conclusion (verbatim)

The Darbitex Beta codebase is robust and has clearly benefited from multiple rounds of auditing. The critical double-counting bug has been fixed, and the current implementation adheres to best practices for Move development on Aptos. The findings above are either edge cases or informational notes that do not pose immediate security threats. With minor clarifications (M-01) and documentation updates, the protocol is ready for mainnet operation.

**Final Verdict:** ✅ **Recommended for deployment with noted caveats.**

---

## Cycle status: 🟢 COLLECTING COMPLETE

All 8 scheduled post-mainnet auditors have returned:

| Auditor | Verdict | Git author |
|---|---|---|
| Claude Opus 4.6 (fresh web, extended) | 🟡 YELLOW (3 MED / 4 LOW / 6 INFO) | `claude` |
| Kimi K2 | ✅ Conditional approval (1 MED / 1 LOW / 1 INFO) | `kimi` |
| Grok 4 | 🟢 GREEN (0 MED / 3 LOW / 4 INFO) | `grok` |
| Claude Opus 4.6 (in-session self-audit) | 🟡 YELLOW (3 LOW / 3 INFO + triage) | `darbitex` |
| Gemini 2.5 Pro | 🟡 YELLOW (0 MED / 1 LOW / 2 INFO) | `gemini` |
| ChatGPT (GPT-5) | 🟠 B+ (2 HIGH / 4 MED / 3 LOW — 2 FPs) | `chatgpt` |
| Qwen | 🟢 LOW overall (0 MED / 1 LOW / 2 INFO) | `qwen` |
| DeepSeek | ✅ Recommended (0 HIGH / 3 MED / 3 LOW / 3 INFO) | `deepseek` |

Next phase: consolidated triage + fix batch. See `darbitex_beta_mainnet_audit.md` memory for running cross-auditor tally and in-session disposition notes on each finding.
