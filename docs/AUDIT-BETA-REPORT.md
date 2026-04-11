# Darbitex Beta — Consolidated Audit Report

**Scope:** `pool.move`, `pool_factory.move`, `router.move` (Beta 0.1.0)
**Commit under review:** `1b6c996` (and subsequent) on `github.com/darbitex/beta`
**Status:** WORK IN PROGRESS — this document collates findings from multiple
independent auditors. Each auditor's section is self-contained. Findings
are consolidated and deduplicated in the final summary at the bottom.

---

## Auditor roster

| Auditor | Role | Completed |
|---|---|---|
| Claude Opus 4.6 (in-session self-audit) | First auditor, original implementer reviewing own code | 2026-04-12 |
| _(external AI #1)_ | pending | — |
| _(external AI #2)_ | pending | — |
| _(external AI #3)_ | pending | — |
| _(external AI #4)_ | pending | — |
| _(external AI #5)_ | pending | — |

External findings will be added by commit author `msgmsg` into sections
below, preserving the original auditor's own writing and structure.

---

# Auditor 1: Claude Opus 4.6 — Self-audit

**Conflict of interest disclaimer:** I am the author of the code under
review. I have intentionally re-read each function with fresh eyes and
worked examples on paper rather than relying on memory of intent. I have
tried to be adversarial to my own implementation. External reviewers
should not treat this self-audit as a substitute for independent
review — it is a first pass to catch obvious issues before wider
distribution.

## HIGH findings

### HIGH-1: LP fee double-counted into reserves AND per-share accumulator

**Locations:**
- `pool.move:552` — `swap()` reserve update (side a)
- `pool.move:556` — `swap()` reserve update (side b)
- `pool.move:924-946` — `flash_repay()` reserve updates and `lp_remainder` credit

**Summary:**
The `swap` function adds the LP fee portion of each swap to two places
at once:

1. Implicitly into `reserve_a`/`reserve_b` via the line:
   ```move
   pool.reserve_a = pool.reserve_a + amount_in - extra_fee;
   ```
   Note this subtracts `extra_fee` (≈ 0.1 bps, hook pot portion) but
   NOT `total_fee`. The difference (`lp_portion ≈ 0.9 bps`) stays
   inside `reserve_a` and thereby grows the x*y=k curve's `k`
   — LPs benefit via reserve growth on subsequent swaps.

2. Explicitly into `pool.lp_fee_per_share_a` via `accrue_fee()`:
   ```move
   let add = (lp_portion as u128) * SCALE / (pool.lp_supply as u128);
   pool.lp_fee_per_share_a = pool.lp_fee_per_share_a + add;
   ```
   LPs can extract this via `claim_lp_fees` or proportional
   `remove_liquidity`, which withdraws from the pool's primary store.

**Concrete trace (numbers from the 2026-04-12 testnet smoke test at
pool `0x153edb3d...abcf2` after a 1 B-unit DAI → USDC swap):**

```
amount_in              = 1_000_000_000
SWAP_FEE_BPS           = 1
EXTRA_FEE_DENOM        = 100_000
total_fee              = 100_000
extra_fee              = 10_000
lp_portion             = total_fee - extra_fee = 90_000
hook_1_fee_a           =          5_000  (extra_fee * 50 / 100)
hook_2_fee_a           =          5_000
lp_fee_per_share_a Δ   =  900_000         (90_000 * 1e12 / 1e11)

store_a before         = 100_000_000_000  (also reserve_a)
store_a after          = 101_000_000_000  (+ amount_in)
reserve_a after code   = 100_999_990_000  (+ amount_in - extra_fee)
hook_1_fee_a           =          5_000
hook_2_fee_a           =          5_000
——————————————————————————————————————————
store - reserve - hook = 100_000 - 10_000 = 90_000  ← lp_portion lives here

pending_lp_fees (full lp_supply) = (900_000 × 100_000_000_000) / 1e12
                                 = 90_000                   ← accounted here too
```

The 90_000 unit `lp_portion` exists in both:
- `reserve_a` (part of `100_999_990_000`), AND
- `lp_fee_per_share_a` (claimable as `90_000`)

**What goes wrong when an LP claims:**

`claim_lp_fees()` (pool.move:732) withdraws the claimed amount from the
pool's primary store but does NOT decrement `reserve_a`. After a full
claim of the 90_000 units:

```
store_a        = 101_000_000_000 − 90_000 = 100_999_910_000
reserve_a      = 100_999_990_000            (unchanged)
hook buckets   = 10_000                     (unchanged)
——————————————————————————————
store − reserve − hook = 100_999_910_000 − 100_999_990_000 − 10_000
                       = −90_000    ← INSOLVENT
```

`reserve_a` now claims there are **more A tokens in the pool than
actually exist in the store**. Subsequent `remove_liquidity` for any LP
computes `amount_a = shares × reserve_a / lp_supply`, which is inflated
by `lp_portion`. When that inflated amount is withdrawn from the store,
`primary_fungible_store::withdraw` aborts with an insufficient-balance
error. **Proportional exit from the pool is broken after any LP fee
claim.**

Flash loans are affected by the same class of bug in `flash_repay`
(pool.move:924-946). `flash_borrow` never decrements `reserve_a` when
the borrowed amount leaves the store, but `flash_repay` adds the
principal back as if it had been subtracted:

```move
let pool = borrow_global_mut<Pool>(pool_addr);
primary_fungible_store::deposit(pool_addr, fa_in);
// ...
if (is_a) {
    pool.reserve_a = pool.reserve_a + amount;  // WRONG: amount was never subtracted
};
// ...
if (is_a) {
    pool.reserve_a = pool.reserve_a + lp_remainder;  // DOUBLE: lp_remainder also goes into per_share
};
```

After any flash loan, `reserve_a` is inflated by `amount + lp_remainder`.
The `k_after >= k_before` check at line 950 trivially passes because
`k_before` was computed from the pre-borrow reserve snapshot and
reserves have only grown on paper. The invariant check provides **zero
economic security** against this bug — it only catches the case where
a repay produces a smaller `k`, which is impossible when the code
inflates reserves.

**Why the test suite does not catch this:**
- `test_remove_liquidity_returns_reserves` runs an add → remove cycle
  with no intervening swap, so `claim_a == 0` and the bug has no
  surface.
- `test_claim_lp_fees_after_swap` only asserts `after_a >= before_a`
  (trivially true), not the solvency invariant
  `store_a == reserve_a + hook_1_fee_a + hook_2_fee_a + pending_all_lp_fees`.
- `test_flash_borrow_repay_happy` repays and succeeds but never follows
  up with a `remove_liquidity` on a large position, so the inflated
  `reserve_a` never gets converted to a store withdrawal.

No test asserts the solvency invariant directly, and the economic
symptom of the bug only surfaces in the "post-swap-or-flash, full LP
exit" sequence.

**Impact:** **HIGH** — not immediately exploitable for theft (the pool
still has all its tokens in the store; no one can withdraw more than
exists), but **the protocol becomes functionally insolvent**: `reserve`
accounting diverges from actual store balance, and `remove_liquidity`
fails for any LP whose share, when multiplied by the inflated
`reserve_a`, exceeds the store balance. The last LP out of any active
pool will always fail.

**Recommended fix:**
Pick one of these two mutually-exclusive accounting models and apply
it consistently across `swap`, `flash_repay`, and the claim paths:

**Option A (preferred) — MasterChef-style separation**
Track principal in reserves, fees in the accumulator, and never let
them overlap.

```move
// swap() line 552:
- pool.reserve_a = pool.reserve_a + amount_in - extra_fee;
+ pool.reserve_a = pool.reserve_a + amount_in - total_fee;
// same for side b at line 556

// flash_repay() — DELETE lines 923-928 and 941-946:
// (do not add `amount` back to reserves; do not credit lp_remainder
//  into reserves; accrue_fee already bumps lp_fee_per_share)

// Invariant after fix:
//   store_a == reserve_a + hook_1_fee_a + hook_2_fee_a
//              + Σ (pending_lp_fees across all positions in A)
```

With this fix, reserves track only the principal on the curve;
`lp_fee_per_share_a` tracks the per-share claim; hook buckets track
their absolute amounts; and claims from any of these three correctly
reduce the store with no double counting.

**Option B — Uniswap V2-style fee-in-reserves**
Revert to the original V2 model: LP fee lives in reserves only, no
per-share accumulator, no `claim_lp_fees`. LPs harvest exclusively via
`remove_liquidity`. This removes the "claim without withdraw" feature
from the design, which the project owner explicitly wanted, so I do
not recommend this path.

**Regression test to add after the fix:**

```move
#[test] fun test_swap_then_remove_solvency_invariant(...) {
    // create pool with 100B + 100B
    // swap 100B in (large enough to produce non-trivial lp_portion)
    // add_liquidity small amount
    // remove_liquidity the new position in full
    // Then: verify that sum over (
    //   original creator LP claim) + hook1 claim + hook2 claim
    //   CAN drain the pool to exactly minimum_liquidity dead shares
    //   without any withdraw aborting.
}
```

---

### HIGH-2: Pool address stored in Pool struct but not as sanity check on swap

**Location:** `pool.move:495-501`

**Summary:**
`swap()` takes `pool_addr: address` as an argument and does
`borrow_global_mut<Pool>(pool_addr)`. There is no self-check that the
Pool at that address believes itself to be at `pool_addr`. In Move, a
resource stored at address `X` can only be accessed via
`borrow_global<T>(X)`, so the resource is implicitly bound to its
storage address — you can't accidentally pass the wrong `pool_addr`
and borrow a different Pool. So this is actually **not a finding** —
Move's storage model handles the binding for us.

I initially flagged this as "missing address check" but on second
reading retracted it. Listing here for completeness so external
auditors know this angle has been looked at.

**Impact:** None. Retracted.

---

## MEDIUM findings

### MEDIUM-1: `swap` and `get_amount_out` u128 overflow for adversarial reserves

**Locations:**
- `pool.move:530-533` — `swap()`
- `pool.move:1076-1079` — `get_amount_out()` view

**Summary:**
The constant-product math computes:

```move
let amount_in_after_fee = (amount_in as u128) * ((BPS_DENOM - SWAP_FEE_BPS) as u128);
let numerator = amount_in_after_fee * (reserve_out as u128);
```

`amount_in ≤ u64::MAX ≈ 2^64`. So `amount_in_after_fee ≤ 2^64 × 9999 ≈ 2^78`.
`reserve_out ≤ u64::MAX ≈ 2^64`. So `numerator ≤ 2^78 × 2^64 = 2^142`.

`u128` max is `2^128`. The multiplication overflows by 14 bits in the
worst case. Move's unchecked u128 arithmetic aborts on overflow, so
the transaction reverts rather than silently corrupts — **no theft
vector**. But a sufficiently large pool (reserves near u64 max) combined
with a large `amount_in` produces a transaction that cannot execute.

**Realistic threshold:** for reserves of `R` and input of `A`,
overflow risk when `A × R × 10^4 > 2^128`. So for `R = 10^18` (1
quintillion raw units, implausibly large), `A_max ≈ 3.4 × 10^16`,
still enormous. For realistic pools (`R ≤ 10^14`), `A_max ≈ 10^20`,
well above any plausible swap. **This is not exploitable under normal
operation** but should be fixed before an adversary can construct a
pool with hostile reserve sizes to DoS swaps.

**Recommended fix:**
Upgrade the multiplication to `u256`, matching the choice already made
in `pending_from_accumulator` and the flash loan k-invariant check:

```move
let amount_in_after_fee = (amount_in as u256) * ((BPS_DENOM - SWAP_FEE_BPS) as u256);
let numerator = amount_in_after_fee * (reserve_out as u256);
let denominator = (reserve_in as u256) * (BPS_DENOM as u256) + amount_in_after_fee;
let amount_out = ((numerator / denominator) as u64);
```

Same treatment for the view function. The u64 cast on
`(numerator / denominator)` is safe because the result is an `amount_out`
bounded by `reserve_out ≤ u64::MAX`.

**Impact:** MEDIUM — no economic loss, but pool becomes DoSed for
large swaps above the overflow threshold. Fix is trivial and worth
applying for defense in depth.

---

### MEDIUM-2: `add_liquidity` proportionality check has the same u128 overflow risk

**Location:** `pool.move:609`

```move
let expected_b = ((amount_a as u128) * (pool.reserve_b as u128) / (pool.reserve_a as u128) as u64);
```

`amount_a × reserve_b ≤ 2^64 × 2^64 = 2^128`. This is exactly at the
u128 ceiling. Division happens after the multiply, so the intermediate
product is the overflow surface. Same fix as MEDIUM-1: use u256.

```move
let expected_b = (((amount_a as u256) * (pool.reserve_b as u256)
    / (pool.reserve_a as u256)) as u64);
```

Shares-minted math two lines down (`lp_a`, `lp_b`) has the same
property and should also be upgraded to u256.

**Impact:** MEDIUM — DoS only under adversarial pool sizes.

---

### MEDIUM-3: `add_liquidity` tolerance allows griefing first LP after pool is skewed

**Location:** `pool.move:608-618`

**Summary:**
The 5% tolerance is relative to `expected_b` computed from the current
reserve ratio. If a malicious pool creator performs a large swap before
the first external LP's add, they can force the ratio away from the
natural 1:1, and the new LP's deposit (which is presumably valued at
the creator's 1:1 seeding) gets valued at the post-swap ratio.

This is the standard AMM "first-depositor / sandwich-the-first-add"
problem. V2 AMMs typically mitigate this with the `MINIMUM_LIQUIDITY`
dead-share lock (already present here, 1000 units) plus frontend
guidance to LPs to check reserve ratios before adding.

**Impact:** MEDIUM — not a code bug, but a design concern worth
documenting. Beta's symmetric seeding rule on pool creation forces the
initial ratio to 1:1, but subsequent swaps can drift the ratio, and
later LPs inherit whatever ratio exists at their add time.

**Recommendation:** add a `min_shares_out` parameter to
`add_liquidity` (Uniswap V2 style) so LPs can specify a minimum share
count and abort if the ratio has drifted in a way that would hurt
them. Not a blocker for mainnet if the frontend handles slippage
protection, but strongly recommended for composability with external
callers who expect pure-primitive protection.

---

### MEDIUM-4: 50/50 hook split has odd-unit asymmetry

**Location:** `pool.move:254-255`

```move
let hook_1_portion = extra_fee * HOOK_SPLIT_PCT / 100;
let hook_2_portion = extra_fee - hook_1_portion;
```

For `extra_fee = 1`, integer division gives `hook_1 = 0`, `hook_2 = 1`.
For `extra_fee = 3`: `hook_1 = 1`, `hook_2 = 2`. For any odd `extra_fee`,
the marketplace/escrow slot always wins the odd unit, and the
treasury slot always loses it.

**Economic impact over a pool's lifetime:** At 1 bps swap fee and
10^5 `EXTRA_FEE_DENOM`, roughly half of the extra_fees in realistic
pool activity will be non-trivially large (multi-unit) and split
evenly. Only the `extra_fee = 1` dust regime has the 0/1 asymmetry,
which matters only for pools doing very small swaps.

Still — this is a long-term rounding asymmetry that strictly favors
the tradable slot over the soulbound treasury slot. Across a million
dust swaps, treasury is under-paid by ~1 million units (which, at
typical FA decimals, is economically negligible).

**Recommendation:** either
(a) accept as documented rounding tradeoff, or
(b) alternate the winner of the odd unit across swaps using a
counter (`pool.total_swaps % 2 == 0 ? hook_1_wins : hook_2_wins`)
for bounded long-run fairness. Option (b) adds complexity for
marginal benefit.

**Impact:** LOW economic, MEDIUM design cleanliness. Listed as
MEDIUM because the audit expects explicit acknowledgment.

---

## LOW findings

### LOW-1: Test suite does not assert solvency invariant

**Location:** `tests.move` (whole file)

**Summary:**
None of the 31 tests explicitly check that
```
store_balance(metadata) == reserve(side) + hook_1_fee(side) + hook_2_fee(side) + Σ pending_lp_fees(side across all positions)
```

If this invariant had been asserted in even one test after a swap,
HIGH-1 would have been caught immediately. The test suite verifies
state transitions (balances grow / shrink as expected) but not
cross-variable conservation.

**Recommendation:** add a helper `assert_pool_solvency(pool_addr)`
that reads the pool's primary store balance for both metadata sides,
sums the reserve + hook buckets + pending LP fees across all known
positions, and asserts equality with a small rounding tolerance.
Call this helper at the end of every test that mutates state.

**Impact:** LOW (test-only; doesn't affect production code, but
critical for catching economic bugs during development).

---

### LOW-2: `pending_from_accumulator` rounds down, user loses up to 1 raw unit per claim

**Location:** `pool.move:286-296`

```move
let product = (delta as u256) * (shares as u256);
let scaled = product / (SCALE as u256);
(scaled as u64)
```

Integer division rounds down. A claim of exactly half a unit returns
zero. Over many claims on a small position, the user can lose up to
1 raw unit per claim to rounding, which stays in the pool as implicit
dust.

**Impact:** LOW — favors the pool over the user by dust amounts per
claim, standard behavior for integer fee math. Consistent with the
"round in the pool's favor" defensive style. Noted for completeness.

---

### LOW-3: `update_twap` does not guard against `twap_last_ts > now` clock skew

**Location:** `pool.move:234-242`

```move
let now = timestamp::now_seconds();
let dt = now - pool.twap_last_ts;
```

If `now < pool.twap_last_ts` (impossible in practice on Aptos, which
has a monotonic global clock), the subtraction would underflow and
abort the TX. This is actually the correct defensive behavior — time
going backwards is a framework-level invariant violation and aborting
is safer than silently corrupting the TWAP. Noted for completeness.

**Impact:** None. Retained as design-correct.

---

### LOW-4: `add_liquidity_entry` discards the returned `LpPosition` handle

**Location:** `pool.move:967-974`

```move
public entry fun add_liquidity_entry(...) acquires Pool {
    let _ = add_liquidity(provider, pool_addr, amount_a, amount_b);
}
```

The entry function drops the returned Object<LpPosition> handle.
Callers must observe the `LiquidityAdded` event to discover the
position address, which is an off-chain lookup. Not a bug, but an
ergonomics gap — a frontend or SDK that wants to immediately chain
another operation on the new position has to round-trip to an
indexer.

**Recommendation:** leave as is; this is a genuine constraint of
entry functions (they cannot return values to an off-chain caller
in an addressable way). Alternative: have `add_liquidity_entry`
deposit a "receipt" resource to the caller's account that holds the
position address, but this adds more surface than it saves.

**Impact:** None. Design-correct.

---

### LOW-5: `create_pool` does not emit a separate `LiquidityAdded` event for the creator's initial position

**Location:** `pool.move:477-485`

Actually it does — there is a second `event::emit(LiquidityAdded {...})`
at line 477 that emits the creator's add alongside the `PoolCreated`
event. Retracted. Listing for auditor reference.

**Impact:** None.

---

## Informational findings

### INFO-1: `pool.move` unused `lp_fee` event attribution when LP double-counting fix is applied

**Location:** `pool.move:545-546`

```move
let (lp_fee, hook_1_fee, hook_2_fee) = accrue_fee(pool, total_fee, extra_fee, a_to_b);
let _ = lp_fee;
```

The `let _ = lp_fee;` silences an unused variable warning, but
`lp_fee` is then emitted in the `Swapped` event a few lines down at
line 580. The `let _` is cosmetic and can be removed.

**Recommendation:** delete `let _ = lp_fee;` (pool.move:546).

---

### INFO-2: Inconsistent use of `primary_fungible_store::deposit` vs `fungible_asset::merge` for split returns

`remove_liquidity` and `claim_lp_fees` compute `total_a = amount_a + claim_a`
and withdraw that as a single FA. This is efficient and correct. No
concern — noted for reviewer orientation.

---

### INFO-3: `FlashReceipt` has no `store` ability — correct hot-potato, but the `metadata` field is an `Object<Metadata>`

`Object<Metadata>` has `copy + drop` at the type level. Embedding it
in a struct that lacks `store` does not make the Object "hot" on its
own; only the receipt container is. This is correct Move semantics —
the hot-potato property travels with the container, not its fields.
Confirmed OK.

---

### INFO-4: Hook NFT transferability test is weak

`test_hook_nft_1_soulbound_abort` asserts that `object::transfer` aborts
for the treasury NFT, but doesn't check for other transfer paths
(e.g., direct call to `object::transfer_with_ref` using a fabricated
linear ref). The `transfer_ref` used at mint time goes out of scope
when `mint_hook_nft` returns, and Move's type system prevents
fabrication of a new `LinearTransferRef` for an existing object.
Confirmed no other transfer paths, but the test does not document
this reasoning.

**Recommendation:** add a comment to the test explaining that the
test exercises the user-facing `object::transfer` path and that ref-
based transfer is prevented at compile time by Move's type system.

---

## Design questions answered (per AUDIT-BETA-SUBMISSION.md section 7)

### Q1 — LP fee accumulator math correctness

**Not correct.** See HIGH-1. The math is internally consistent on its
own terms (the MasterChef V2 pattern is implemented correctly in
isolation), but the swap code also credits the LP portion into
reserves, producing double counting. Fix as described in HIGH-1.

### Q2 — Flash loan safety

**Principal is safe** (amount check in `flash_repay` prevents
under-repayment), **k-invariant check is cosmetic** (it always passes
because reserves are only inflated, never decremented, during the
borrow+repay span), and **the repay path has the same double-counting
bug as swap** (HIGH-1). Once HIGH-1 is fixed, the flash loan path
becomes economically consistent. The `pool.locked` reentrancy guard
is correctly placed and covers all mutation paths.

### Q3 — Hook NFT soulbound enforcement

**Correctly enforced** at mint time. `object::disable_ungated_transfer`
prevents the user-facing `object::transfer` path. Move's type system
prevents fabrication of a `LinearTransferRef` for an existing object
by any party that didn't receive the original ref at creation time.
The ref is scoped to `mint_hook_nft` and discarded at return, making
re-enablement impossible.

### Q4 — Canonical pool uniqueness and hook-at-birth atomicity

**Correctly enforced** by Move framework + factory code. Three layers:
- `assert_sorted` with strict `<` prevents same-token pairs
- `object::create_named_object` aborts `EOBJECT_EXISTS` on duplicate
  canonical address
- `public(friend)` on `pool::create_pool` prevents pool creation from
  outside `pool_factory` module

No attack vectors found. Hook-at-birth atomicity is guaranteed because
`create_canonical_pool` is a single entry that always mints both hooks
alongside pool creation; TX atomicity rolls back the entire state if
any step aborts.

### Q5 — Two-layer composability contract

**Generally clean** with one caveat: `pool::swap` takes
`swapper: address` as a parameter used only for event attribution, not
authentication. An adversarial satellite could spoof this field to
mislead off-chain indexers that trust events as user identity. This
is informational, not a security bug — the on-chain economic effect is
identical regardless of the `swapper` address, and indexers that need
reliable sender attribution should read the TX signer from chain data,
not from event fields.

No `public fun` functions found that should have been `public(friend)`-
gated. The friend gate on `create_pool` is the only hard authorization
barrier, and it is correctly placed.

### Q6 — Escrow sale sanity

**Flow is correct.** The order (remove listing → transfer APT →
transfer NFT) is safe under TX atomicity: any step that aborts rolls
back all prior state changes, so a buyer cannot end up paying without
receiving, and the listing cannot be removed without the NFT
transferring. The `set_hook_price` → `create_canonical_pool` race
condition (admin updates price between pool create calls) is within the
expected trust model (admin is trusted for price config) and not an
economic vulnerability.

### Q7 — Symmetric seeding rationale

**Strict equality is intentional and defensible** per the design
principle. It makes the starting reserve ratio neutral and eliminates
the first-depositor ratio-manipulation vector at pool birth. The
usability concern (pools where the creator has unbalanced holdings)
can be addressed by rebalancing swaps post-creation. External
reviewers may have different opinions; the self-audit accepts the
design decision as stated.

### Q8 — Anything else

Findings above. Other areas reviewed but found clean:
- `sqrt` Babylonian implementation
- `MINIMUM_LIQUIDITY` dead-share lock (1000, Uniswap V2 standard)
- Event emission coverage (all state mutations emit events)
- Error code usage (consistent across `pool`, `pool_factory`, `router`)
- Reentrancy `locked` flag (covers all mutation paths; TX atomicity
  rolls back on any abort, so failed-unlock is not a concern)
- Admin constant hardcoding (matches design intent, documented)

## Overall verdict

**RED — not ready for mainnet publish.**

HIGH-1 must be fixed before any mainnet deployment. The testnet
deployment at `0x6ba3a6eff27a8a729008d16550aa41d18bacf03e28d2daf9de192a10426a213a`
is already affected by this bug and should be considered "first draft"
rather than production-ready. On-chain smoke test passed because the
specific sequence that surfaces the bug (swap → claim → remove) was
not exercised.

MEDIUM-1, MEDIUM-2 (u128 overflow) should be fixed as defense in
depth. MEDIUM-3 (add_liquidity slippage protection) is a design-level
improvement worth considering. MEDIUM-4 (hook split rounding) can be
accepted as documented tradeoff.

**Action plan:**
1. Fix HIGH-1 in `swap()` and `flash_repay()` per option A
2. Add solvency invariant regression test per LOW-1
3. Upgrade swap math and add_liquidity math to u256 per MEDIUM-1/2
4. Re-run the testnet smoke test and verify the swap → claim →
   remove sequence with non-trivial values
5. Distribute the updated source to the 4 remaining external AI
   auditors for independent review

---

# Auditor 2: _(pending)_

_To be populated by commit author `msgmsg`._

---

# Auditor 3: _(pending)_

_To be populated by commit author `msgmsg`._

---

# Auditor 4: _(pending)_

_To be populated by commit author `msgmsg`._

---

# Auditor 5: _(pending)_

_To be populated by commit author `msgmsg`._

---

# Auditor 6: _(pending)_

_To be populated by commit author `msgmsg`._

---

# Consolidated summary (to be updated after all audits complete)

**Unresolved HIGH:** 1 (LP fee double-counting — Claude 1st pass)
**Unresolved MEDIUM:** 4 (swap u128 overflow, add_liquidity u128
  overflow, add_liquidity slippage protection, hook split rounding)
**Unresolved LOW:** 2 (test solvency invariant, accumulator rounding)
**Informational:** 4

**Mainnet gate:** BLOCKED until HIGH-1 is fixed and regression
verified on testnet, and at least 3 more independent audits complete.
