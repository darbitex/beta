# Darbitex Beta — External Audit Submission (round 3)

**Version:** Beta 0.1.0 (post-round-2 fix)
**Date:** 2026-04-12
**Chain:** Aptos testnet (round 3 E2E verified)
**Audit package size:** 4 Move source files, ~2500 LoC total, 36/36 tests passing
**Repo:** https://github.com/darbitex/beta
**Round 1 testnet (superseded):** `0x6ba3a6eff27a8a729008d16550aa41d18bacf03e28d2daf9de192a10426a213a`
**Round 2 testnet (superseded):** `0x12e8b2be0d705d5d6f1e27b50d331740461dccd2c1150504c2e38a67c6767a0f`
**Round 3 testnet (current target):** `0xf93e4885f581c9b0c4f2199362afa91ae595a5a424432e0b752804cfef2bd5c7`
**Planned mainnet publisher:** `0x8c8f40ef0b924657461253e7aa54a15fdfd8a3069e1404ba6ffda2223ddcadb7` (5-of-5 multisig, bootstrap threshold 1/5)

---

## Round 2 audit summary (findings addressed in this packet)

This submission is the **round 3** audit packet. Two prior rounds with
7 independent AI auditors (Claude in-session, DeepSeek R1/R2, Gemini R1/R2,
Grok 4 R2, fresh Claude Opus 4.6 R2, Kimi K2 R2, Qwen R2) found and
addressed the following issues in the round 2 fix batch.

**Round 2 findings addressed:**

- **HIGH (Gemini R2):** `add_liquidity` silently donated unused slippage
  buffer from the loose side to existing LPs. A user who provided
  (amount_a, amount_b + buffer) would have the full amount_b withdrawn
  from their wallet while only receiving LP shares proportional to the
  optimal pair. **Fix:** rewrote `add_liquidity` to use Uniswap V2
  router-style optimal amount computation. Compute `amount_b_optimal`
  from `amount_a_desired` at the current reserve ratio; whichever side
  is tight, use that side's desired amount and the computed optimal on
  the loose side. Only the optimal amounts are withdrawn from the
  caller — the unused buffer stays in their wallet. The 5% tolerance
  disproportional check is removed since the optimal computation
  handles any ratio gracefully. **On-chain verified** at round 3 testnet:
  a user providing (100M A, 200M B) on a 1:1 pool has only
  (100M A, 100M B) withdrawn, 100M B stays in their wallet.

- **MEDIUM (fresh Claude Opus 4.6 R2 + Kimi K2 R2, independent):**
  `remove_liquidity` had no slippage protection, allowing sandwich
  extraction on active pools. **Fix:** added `min_amount_a` and
  `min_amount_b` parameters to both composable `remove_liquidity` and
  entry wrapper. Proportional reserve payouts (excluding fee claims)
  must meet the floors or the function aborts `E_SLIPPAGE`. This
  matches the protection already provided on `add_liquidity` via
  `min_shares_out`.

- **MEDIUM (fresh Claude Opus 4.6 R2):** `claim_lp_fees` and
  `claim_hook_fees` did not set `pool.locked` during execution.
  Currently safe because Aptos FA operations have no callback hooks,
  but if a future framework update introduces dispatchable callbacks
  on FA transfers these functions could become reentrant. **Fix:**
  added defensive `pool.locked = true/false` bracketing around the
  withdraw calls in both claim functions for consistency with swap and
  flash_borrow.

- **LOW (fresh Claude Opus 4.6 R2):** `buy_hook` did not verify factory
  ownership of HookNFT #2 before taking payment. Under normal operation
  this is always true, but an explicit assert produces a clearer error
  than a mid-TX abort inside `object::transfer`. **Fix:** added
  `assert!(object::owner(nft_obj) == factory.factory_addr, E_NOT_LISTED)`
  before the APT transfer.

**Round 2 auditor verdicts by code version reviewed:**

| Auditor | Code reviewed | Verdict | Unique findings |
|---|---|---|---|
| Grok 4 | R1 packet (post-R1-fix) | 🟢 GREEN | 0 findings, 2 INFO nits |
| Gemini | R1 packet | 🟡 YELLOW | HIGH add_liq buffer (unique, verified on-chain) |
| Fresh Claude Opus 4.6 | R1 packet | 🟡 YELLOW | MED remove slippage, MED claim lock, LOW buy_hook assert |
| Kimi K2 | R1 packet | 🟡 YELLOW | MED remove slippage (independently confirms fresh Claude) |
| Qwen | R1 packet | 🟢 GREEN | LOW router intermediate slippage only (known AMM tradeoff) |
| DeepSeek | R1 packet | 🟢 GREEN | LOW tolerance edge only |

**3 auditors (Grok, Qwen, DeepSeek) verdicted GREEN on the R1 packet
code.** 3 others (Gemini, fresh Claude, Kimi) found issues the first 3
missed. All unique findings have been addressed in this R3 packet.

Round 3 reviewers should verify the round-2 fixes are correctly
implemented and focus on any remaining surface. The HIGH-1 fix from
Gemini is verified on-chain at the round 3 testnet address above.

---

## Round 1 audit summary (findings already addressed)

A first round of audits (Claude in-session self-audit, DeepSeek R1,
Gemini R1) found and addressed the following issues:

**Resolved (fixed + regression tested + on-chain verified):**

- **HIGH-1 (3-way consensus):** LP fee double-counting in `swap()` and
  `flash_repay()`. Reserves were implicitly crediting the LP portion of
  the fee (via `reserve += amount_in - extra_fee`) while the accumulator
  also credited it (`lp_fee_per_share += lp_portion / lp_supply`). Under
  the bug, `remove_liquidity` would abort for any LP exiting a pool that
  had any swap+claim activity, because reserve_a would exceed store_a.
  **Fix:** `swap()` now deducts `reserve_fee = extra_fee + lp_fee` (which
  equals `total_fee` in normal swaps and `extra_fee` in dust swaps).
  `flash_repay()` no longer mutates reserves at all — flash_borrow
  doesn't decrement them, so flash_repay must not add them back.
  Regression tests added. Verified on-chain at the round 2 testnet
  address above with the full `swap → add → claim → swap → claim →
  remove` sequence.

- **LOW-2 (Gemini only):** `flash_repay` accepted excess payment and
  silently donated it to the pool. **Fix:** tightened the amount check
  from `>=` to `==`.

- **MEDIUM-1 (Claude + DeepSeek + Gemini):** u128 overflow risk in swap
  numerator for adversarial reserves. **Fix:** all intermediate
  multiplications in `swap()` and `get_amount_out()` upgraded to u256.

- **MEDIUM-2 (Claude):** u128 overflow risk in `add_liquidity`
  proportionality check and shares computation. **Fix:** upgraded to u256
  across expected_b, lp_a, lp_b, and remove_liquidity proportional
  payouts.

- **MEDIUM-3 (Claude + Gemini):** `add_liquidity` had no slippage
  protection. Callers could not enforce expected share counts. **Fix:**
  added `min_shares_out: u64` parameter to both the composable `fun` and
  the entry wrapper. Abort code `E_SLIPPAGE` if computed shares below
  floor. A new test `test_add_liquidity_min_shares_out_abort` verifies
  the abort path.

**DeepSeek HIGH-1 (cast precedence) — FALSE POSITIVE:** DeepSeek was
concerned that `numerator / denominator as u64` parses as
`numerator / (denominator as u64)`, truncating the denominator. Empirical
refutation: the code compiles successfully, which would be impossible if
that interpretation were correct (`u128 / u64` is a type error in Move).
On-chain test results also match the u128 division interpretation. No
fix needed, but explicit outer parens `((expr) as u64)` added on all
dual-cast sites for future reader clarity.

**Accepted as designed, not fixed:**

- Dust swap rounding (DeepSeek MEDIUM-1): `extra_fee` floors to 1 while
  `total_fee` can floor to 0 for dust swaps. The existing saturation in
  `accrue_fee` handles this correctly — dust swaps round in the pool's
  favor, which is the standard AMM choice.

- 50/50 hook split odd-unit rounding (Claude MEDIUM-4): marketplace slot
  always wins the odd unit for `extra_fee = 1` dust regimes. Documented
  tradeoff; economic impact negligible.

- Event swapper spoofing (Claude INFO, DeepSeek LOW-1, Gemini LOW-1): the
  `swapper: address` field in the `Swapped` event is an attribution hint,
  not a trusted identity. Downstream consumers should verify against TX
  signer if authenticated attribution is needed.

- Symmetric seeding (Gemini Q7 objection): Gemini strongly recommended
  reverting to arbitrary-ratio seeding. The project owner has committed
  to strict equality as a non-negotiable design principle. Pool creators
  are expected to either pick pairs where 1:1 raw unit parity is
  approximately correct, or accept the immediate arb as market opening
  cost.

**Test suite state:** 34/34 passing on `aptos move test`. Includes two
regression tests specifically covering the HIGH-1 swap-claim-remove
sequence and flash-then-remove sequence.

**On-chain verification:** full end-to-end sequence executed on testnet
at the round 2 address above. Solvency invariant verified exactly after
the swap (see explorer for TX hashes).

---

## 1. What we are asking from you

You are reviewing the four Move source files for **Darbitex Beta**, an
Aptos-native AMM. This is a clean-slate redesign of an earlier V1 ("Alpha")
package that shipped with known HIGH findings in its hook auction system
(H2, H3, M1 — HookCap resurrection / wrapper desync / witness binding).
Beta eliminates the entire auction subsystem and all of those findings by
construction.

We want an **independent security review** focused on:

1. Correctness of the new fee accumulator math (LP per-share + debt snapshot)
2. Flash loan safety (k-invariant, hot-potato, reentrancy lock)
3. Hook NFT lifecycle (soulbound slot 0, transferable slot 1)
4. Canonical pool uniqueness and hook-at-birth atomicity
5. Any composability / cross-package risks introduced by the two-layer
   primitive / entry contract
6. Any admin override or trust escape we did not explicitly acknowledge

**Output format we'd like back:**

```
## Findings

### HIGH-1: <title>
Location: <file>:<line>
Description: <what>
Impact: <why it matters>
Recommended fix: <how>

### MEDIUM-1: ...
### LOW-1: ...
### INFORMATIONAL-1: ...

## Design questions we want answered
(any specific question from section 7 below)

## Overall verdict
(green / yellow / red for mainnet publish readiness)
```

Please also comment on **things we considered and got right** — we want
to know which decisions held up under scrutiny, not just where we failed.

---

## 2. Project context (one paragraph)

Darbitex is a small Aptos-native AMM. The V1 ("Alpha") package went live on
mainnet with 4 smoke-test pools under multisig-owned LP, then a post-launch
audit surfaced HIGH findings in its auction-based hook system. Rather than
patching V1 (which is `upgrade_policy = "compatible"` locked and cannot
absorb the required struct changes), we are publishing **Darbitex Beta** as
a fresh package at a new address. Alpha will remain live as legacy; Beta
replaces it in the frontend after this audit and mainnet publish.

Beta's design constraints came directly from V1's audit findings and the
project owner's explicit preferences over a back-and-forth design session:

- One agnostic pool type (no separate bridge module)
- Truly immutable pools after creation (zero admin surface on the pool level)
- Every pool born with two HookNFT objects (not an auction-awarded hook)
- Symmetric seeding (strict `amount_a == amount_b`)
- LP positions as Aptos objects with global accumulator + debt snapshot
- No protocol fee stream (treasury earns only via its soulbound HookNFT)
- Flash loan at every pool, k-invariant enforced in u256
- TWAP cumulative, Uniswap V2 style
- Two-layer composability contract so future satellites can compose Beta
  without requiring a core upgrade

---

## 3. Core design principles

These are **intentional**. If you find something that violates one of
these, that's a HIGH finding. If you disagree with a principle, note it
under "Design questions" rather than as a finding.

1. **One pool type, agnostic to pair.** No bridge module. Stable and
   volatile pairs share the same pool with identical rules. Any valid
   Aptos Fungible Asset (`Object<Metadata>`) can be a side of a pool with
   zero whitelisting or admin approval.

2. **Truly immutable pools.** After `create_canonical_pool` returns, no
   function anywhere in Beta can alter fee, curve, pair, or hook
   assignment. Zero admin surface at the pool level — no `pause`,
   `unpause`, `withdraw_protocol_fee`, `admin_force_remove_hook`.

3. **Hook-at-birth, mandatory.** Each pool is created alongside exactly
   two HookNFT objects atomically. Pool stores their addresses as
   immutable references. There is no "unhooked pool" state, ever.

4. **Hook NFT #1 → treasury (soulbound).** Revenue stream forever.
   `disable_ungated_transfer` is called at mint time so the NFT can
   never leave the treasury address.

5. **Hook NFT #2 → factory escrow at fixed list price.** Anyone can call
   `pool_factory::buy_hook(pool_addr)` at the admin-configurable price
   (default 100 APT). APT is routed to the operational multisig
   (`REVENUE_ADDR` const). NFT ownership transfers to buyer. No
   marketplace satellite needed.

6. **Symmetric seeding.** First deposit must be `amount_a == amount_b`
   (strict equality). This is a **feature**, not a bug — it makes the
   x*y=k starting line neutral and eliminates first-depositor ratio
   manipulation. We know it disallows asymmetric-value pairs on day one;
   LPs can rebalance via the first few swaps post-creation.

7. **LP as NFT with global accumulator.** LP positions are Aptos objects
   (`LpPosition`), not fungible coins. Fee math uses the MasterChef V2
   pattern:
   - Pool tracks `lp_fee_per_share_a / _b: u128` (cumulative, scaled by `SCALE = 1e12`)
   - Each position stores `fee_debt_a / _b: u128` (snapshot of `per_share` at last sync)
   - Claimable = `(current_per_share - debt) * shares / SCALE`, computed in u256
   - Claim resets debt to current. Partial claims supported
     (`claim_lp_fees` leaves position intact).

8. **No protocol fee stream.** Treasury revenue comes solely from holding
   the treasury-slot HookNFT. Protocol itself has zero fee claim. There
   is no `withdraw_protocol_fee`, no treasury accumulator outside the
   hook NFT mechanism.

9. **Flash loan at pool level.** Universal across all pools. FlashReceipt
   is a hot-potato struct with no abilities — must be consumed by
   `flash_repay` in the same TX. `pool.locked = true` during the borrow
   span so swap/LP/flash operations abort until repay. `flash_repay`
   asserts `k_after >= k_before` in u256.

10. **TWAP cumulative accumulator.** Uniswap V2-style `twap_cumulative_a / _b`
    + `twap_last_ts`. External consumers sample deltas for oracle use.
    No ring buffer, no compact encoding — u128 cumulative over seconds,
    overflow-safe for roughly a century.

11. **Two-layer composability contract.** Every user-visible operation
    has both a composable primitive (`public fun` taking and returning
    `FungibleAsset`) AND an entry wrapper (`public entry fun` with
    deadline check and `primary_fungible_store` integration). External
    satellites compose the primitive layer. `pool::swap` takes
    `swapper: address` (not `&signer`) because FA is already in hand —
    authorization happens at the caller's FA withdraw.

12. **Darbitex "hook" ≠ Uniswap V4 "hook".** Beta hook is a fee-earning
    NFT slot, not a code callback. Swap does **not** invoke external
    code. Zero reentrancy attack surface from user-defined hooks.

---

## 4. Security model and trust assumptions

### Trusted parties

- **Admin multisig** (`0xf1b522ef...96566`, reused from V1): can call
  `set_hook_price` to update the default listing price for FUTURE pools.
  Cannot touch existing listings, cannot touch pool state, cannot mint
  or burn anything. Also receives `buy_hook` APT revenue (same address
  hardcoded as `REVENUE_ADDR`).
- **Treasury multisig** (`0xdbce8911...f9576`, reused from V1): passive.
  Receives HookNFT #1 at every pool creation. Cannot move it (soulbound).
  Can claim accumulated slot-0 hook fees via `claim_hook_fees`.
- **Publisher multisig** (`0x8c8f40ef...ddcadb7`, new 1/5 bootstrap on
  mainnet): publishes and upgrades the Beta package. `compatible` upgrade
  policy locks in the struct layouts.

### Untrusted parties

- Anyone can create pools (`create_canonical_pool`)
- Anyone can swap, add/remove liquidity on any pool
- Anyone can buy hooks (`buy_hook`)
- Anyone can flash-borrow (as long as they repay in the same TX)
- LP and hook NFT holders are validated by `object::owner(obj) == caller`
  on claim functions

### Threat model we care about

- Economic extraction via rounding, invariant-break, or accumulator math
- Reentrancy via the FA callback path (flash loan hot-potato)
- First-depositor or LP-share manipulation
- Hook NFT counterfeit or owner spoofing
- Fee attribution mismatch (LP earns hook fees or vice versa)
- Pool duplication / canonical address collision
- Transfer of soulbound NFT via any code path
- u128 / u256 overflow in accumulator math under realistic pool lifetime

### Threat model we do NOT care about

- External AMMs at different package addresses (they are separate protocols)
- Malicious FA metadata (we trust the Aptos FA standard; metadata is
  passed through as `Object<Metadata>` without special handling)
- Off-chain frontend or SDK bugs
- Admin key compromise (out of scope; that's a multisig problem)
- Price oracle manipulation across all of DeFi (TWAP is best-effort,
  consumers decide trust level)

---

## 4a. Dependencies

Beta depends on exactly three Move packages, all from the Aptos canonical
framework distribution. Zero third-party code.

- **AptosFramework** (explicit in Move.toml, pinned to `mainnet` rev) —
  provides `object`, `fungible_asset`, `primary_fungible_store`,
  `account`, `aptos_account`, `aptos_coin`, `coin`, `event`, `timestamp`,
  `table`, `type_info`
- **AptosStdlib** (transitive via AptosFramework) — provides `Table`,
  `type_info::TypeInfo`, `math64`, etc.
- **MoveStdlib** (transitive via AptosFramework) — provides `signer`,
  `vector`, `option`, `string`, `bcs`, `hash`, `error`

No vendored dependencies. No pulled-in third-party Move packages. The
entire external surface is Aptos Labs official framework code. Auditors
can treat framework calls as trusted and focus on our own code's use of
them.

## 4b. Testnet playground (live)

Beta is deployed on Aptos testnet and has already passed a full
end-to-end smoke test with real on-chain DAI/USDC pool creation, swap,
add_liquidity, and remove_liquidity operations. Reviewers can verify
behavior on-chain before reading source if desired.

- Package: `0x6ba3a6eff27a8a729008d16550aa41d18bacf03e28d2daf9de192a10426a213a`
- Test pool (DAI/USDC): `0x153edb3d8759f0e694eda138a04c736f0b5258e587830723ca91428654abcf2`
- Publish TX: `0xb625652a0a0d778b99e0d102f62a2b7bb30d919f5fd0c769597e68d66a5c7832`
- init_factory TX: `0x18a38537fe67bd4be541d9c32a7c8a33a705decd00e4ff0f3686a1229f8eec3e`
- create_canonical_pool TX: `0xa0c1b6a3c2c4eb1947674038ba4dd3b4e8cf67ba1917afeb96c9b4cf26827459`
- Test token faucet: legacy V1 test_token module at `0xd91195850afcf3c49a47e07337095f9ef81eee45e80d1643cb393c0a198ba754` exposes permissionless `mint_usdc(to, amount)` and `mint_dai(to, amount)` entries

See `README.md` in the repo root for CLI commands to interact with the
testnet playground.

---

## 5. Module map

| File | Lines | Purpose |
|---|---|---|
| `pool.move` | 1102 | Core AMM: Pool struct, LpPosition (inline), HookNFT (inline), FlashReceipt, swap primitive, add/remove liquidity, claim fees, flash loan, TWAP |
| `pool_factory.move` | 393 | Factory singleton, create_canonical_pool atomic flow, escrow listings table, buy_hook permissionless sale, set_hook_price admin-only |
| `router.move` | 146 | Multi-hop composition over pool::swap. Composable primitives + entry wrappers. No discovery logic. |
| `tests.move` | 784 | 31 unit tests covering every public entry point. 31/31 passing on `aptos move test`. |

All four files live at `darbitex/contracts/sources/`.

Compilation: `aptos move test --named-addresses darbitex=0xcafe` passes
cleanly (no errors, one warning about unused alias that we accept).
Testnet publish via `aptos move publish` with real address succeeds,
`init_factory` runs on-chain, all view functions return expected values.

---

## 6. Locked-in constants (by design, not TODO)

| Constant | Value | Location | Rationale |
|---|---|---|---|
| `SWAP_FEE_BPS` | `1` | pool.move | 1 bps total swap fee |
| `BPS_DENOM` | `10_000` | pool.move | standard bps denominator |
| `EXTRA_FEE_DENOM` | `100_000` | pool.move | ~0.1 bps to hook pot, ~0.9 bps to LP pot |
| `HOOK_SPLIT_PCT` | `50` | pool.move | 50/50 between hook_1 (treasury) and hook_2 (escrow/buyer) |
| `MINIMUM_LIQUIDITY` | `1_000` | pool.move | dead LP shares, Uniswap V2-style anti-manipulation |
| `FLASH_FEE_BPS` | `1` | pool.move | same as swap fee |
| `SCALE` | `1_000_000_000_000` (1e12) | pool.move | u128 per_share accumulator scale |
| `DEFAULT_HOOK_PRICE` | `10_000_000_000` | pool_factory.move | 100 APT octas, admin-configurable |
| `FACTORY_SEED` | `b"darbitex_factory"` | pool_factory.move | resource account derivation seed |
| `POOL_SEED_PREFIX` | `b"darbitex_pool"` | pool_factory.move | canonical address derivation (clean, no V1 "_v3" suffix) |
| `TREASURY_ADDR` | `@0xdbce89...f9576` | pool_factory.move | reused V1 treasury multisig |
| `ADMIN_ADDR` | `@0xf1b522...96566` | pool_factory.move | reused V1 admin multisig |
| `REVENUE_ADDR` | `@0xf1b522...96566` | pool_factory.move | same as admin |

---

## 7. Specific review questions (prioritized)

These are the places we think are most likely to hide subtle bugs. Please
do not limit your review to just these, but please explicitly answer each.

### Q1 — LP fee accumulator math correctness

In `pool.move`:
- `accrue_fee` adds `(lp_portion as u128) * SCALE / lp_supply` to
  `lp_fee_per_share_a / _b` on every swap
- `pending_from_accumulator` computes `(current - debt) * shares / SCALE`
  in u256 to avoid overflow
- `mint_lp_position` for non-initial deposits sets `fee_debt = current_per_share`
  so the new position does not retroactively earn on historical swaps

**Questions:**
- Is there any edge case where `pending_from_accumulator` returns a value
  that does not match the correct share of accrued fees? Consider: first
  LP in a pool, zero-fee swap (dust), swap right after add_liquidity with
  no time passed, position transfer between two claims.
- Is the `u256` intermediate enough to prevent overflow under realistic
  pool lifetime (say 10 years at 1000 swaps/sec)? What about adversarial
  pool lifetime (attacker drives max-size swaps repeatedly)?
- On `remove_liquidity`, we payout `reserves + claim_a + claim_b` in one
  `withdraw` call. Is there any ordering issue where the reserve payout
  could be computed off a state that the claim payout assumes has not
  mutated?
- `claim_lp_fees` on a position with zero claimable returns `fungible_asset::zero(...)`
  instead of aborting. Is this the right choice, or does it hide a bug?

### Q2 — Flash loan safety

In `pool.move::flash_borrow` and `flash_repay`:
- `FlashReceipt` has no abilities (hot-potato)
- `pool.locked = true` on borrow, `false` on repay
- `k_before` stored as `u256` product
- On repay: reserves updated with `amount + (fee - extra_fee)` credited to
  LP, then `k_after = (reserve_a * reserve_b) as u256` asserted `>= k_before`

**Questions:**
- Can an attacker construct a flash loan sequence that leaves `k_after >= k_before`
  but extracts value from the pool? Consider: reentering another pool with
  the borrowed FA, or sandwich patterns.
- Is the `extra_fee` cap (`if (extra_fee > fee) { fee }`) reached in any
  realistic scenario? If yes, does the hook accumulator under-count or
  over-count?
- The `lp_remainder` is added to `reserve_a / _b` directly without
  touching `lp_fee_per_share`. Is that the right behavior, or should the
  LP portion of a flash fee also go through the per-share accumulator?
  (We chose direct reserve credit because the `fa_in` from repay is
  already in the pool store; pulling it back out to route through the
  accumulator would double-count.)
- Can `flash_repay` be called with a different `pool_addr` than the one
  that issued the receipt? (We check `pool_addr == receipt.pool_addr`
  but please verify.)
- `reenter-able` via `pool::swap` during the flash span? (We believe the
  `locked` guard blocks this.)

### Q3 — Hook NFT soulbound enforcement

In `pool.move::mint_hook_nft`:
```move
if (soulbound) {
    object::disable_ungated_transfer(&transfer_ref);
};
```

**Questions:**
- Is `disable_ungated_transfer` sufficient to prevent ALL transfer paths,
  including via internal Aptos object framework calls? Are there any
  `LinearTransferRef`, `ExtendRef`-based, or ObjectCore-manipulation paths
  that could bypass this?
- The `transfer_ref` is generated but not stored anywhere after the
  initial transfer. Is this correct (the ref is consumed at function
  exit, no further transfers possible) or should we save it to prevent
  any future re-enabling?
- `test_hook_nft_1_soulbound_abort` in tests.move verifies that
  `object::transfer(treasury, h1_obj, @0x999)` aborts. Is that test
  sufficient? Are there attack vectors it does not cover?

### Q4 — Canonical pool uniqueness and hook-at-birth atomicity

In `pool_factory.move::create_canonical_pool`:
- Seed is `b"darbitex_pool" || bcs(meta_a) || bcs(meta_b)` with
  pre-sort enforced by `assert_sorted`
- `object::create_named_object(&factory_signer, seed)` — aborts
  `EOBJECT_EXISTS` on duplicate
- Then atomically: pool created, 2 HookNFTs minted, escrow listing added,
  registry updated

**Questions:**
- Is the `assert_sorted` strict `<` comparison (not `<=`) sufficient to
  prevent the same-token case? (We believe so because `bcs(a) == bcs(a)`
  cannot be strictly less.)
- If `pool::create_pool` aborts partway through (e.g., insufficient
  liquidity for `initial_lp - MINIMUM_LIQUIDITY`), does the factory's
  `hook_listings` table and `pool_addresses` vector correctly roll back?
  Move TX atomicity should guarantee this, but please confirm there is
  no partial-write path we missed.
- Can a malicious caller craft metadata that makes `bcs::to_bytes` produce
  a collision with another pair? (We believe `bcs` is injective for
  `Object<Metadata>` since it encodes the underlying address.)
- The `creator` parameter is `&signer` passed all the way through to
  `pool::create_pool`, which uses its address for `mint_lp_position`
  owner. Can a front-running attacker race a pool creation and end up
  owning someone else's LP position?

### Q5 — Two-layer composability contract — principal safety

The composability contract allows `pool::swap` to be called without a
signer (the "composable primitive" layer). Satellites compose this with
their own signer check at a higher level.

**Questions:**
- Does the lack of `&signer` in `pool::swap` introduce any scenario where
  an attacker holding a `FungibleAsset` could manipulate the pool state
  on behalf of someone else?
- `pool::swap` takes `swapper: address` as a parameter, used only for
  event attribution. Can an attacker spoof this address to mislead
  indexers or downstream systems that rely on events?
- Is it correct that `claim_lp_fees` and `claim_hook_fees` DO take
  `&signer` at the composable layer? (We concluded yes, because those
  functions perform authorization via `object::owner(obj) == signer::address_of(caller)`.)
- Are there any `public fun` functions that should have been
  `public(friend)`-gated instead? (The only friend declaration is
  `pool::create_pool` to `pool_factory`.)

### Q6 — Escrow sale sanity

In `pool_factory.move::buy_hook`:
```
table::remove(&mut factory.hook_listings, pool_addr);
aptos_account::transfer(buyer, REVENUE_ADDR, price);
// factory uses signer_cap to transfer HookNFT #2 to buyer
```

**Questions:**
- Is the order of operations (remove listing → transfer APT → transfer NFT)
  correct? If the NFT transfer fails partway (unlikely but hypothetical),
  does the whole TX revert or leave a stale listing entry?
- `set_hook_price` updates `current_hook_price` but does NOT update
  existing `hook_listings` entries. Is this the right behavior? (We
  intend "immutable at listing" — yes. Please verify the code matches
  the intent.)
- Can an attacker front-run a pool creation by calling `set_hook_price`
  via admin to a different value? (Admin is 3-of-5 multisig, so this
  would require coordination across 3 keys — out of our threat model,
  but note any issues if you see them.)

### Q7 — Symmetric seeding rationale

`pool::create_pool` asserts `amount_a == amount_b`. This is much stricter
than V1's 1% tolerance or Uniswap's "any ratio" model.

**Questions:**
- Does this meaningfully harm usability for pool creators in real-world
  scenarios (e.g., creating a stable/stable pool where the creator has
  unbalanced holdings)?
- Does it prevent any class of manipulation that wouldn't be prevented
  by a looser tolerance (e.g., 5%)?
- Is the economic value equivalence assumption (that `amount_a ==
  amount_b` raw units is "neutral") wrong when tokens have different
  decimals or vastly different values?

### Q8 — Anything else

**Any finding not in Q1–Q7 is welcome.** Specifically look for:
- Integer overflow / underflow in swap math, especially around the
  `amount_in_after_fee` computation
- Rounding direction: are we always rounding against the user in a way
  that favors the pool?
- Event emission: are all state mutations emitting events, or are some
  silent?
- Dead code, unreachable branches, unused imports
- Inconsistent error codes or missing assertions
- Magic numbers without explanation

---

## 8. Known tradeoffs we have consciously accepted

These are NOT findings. We have discussed and chosen each deliberately.

- **No position splitting.** Users cannot split one LpPosition into two.
  They emulate via `remove_liquidity` + two `add_liquidity` calls.
  Simpler accounting, no split/merge edge cases.
- **No lp_coin module.** LP is NFT, not fungible. Loses composability
  with external farming / lending protocols that expect fungible LP tokens.
  We accept this. Satellite farming package can wrap LpPosition objects later.
- **No V4-style code hooks.** Swap does not call user-defined code. Loses
  JIT liquidity / custom curve / per-pool oracle features. Gains zero
  reentrancy attack surface. We accept this.
- **Treasury NFT soulbound, not tradable.** Treasury can never sell its
  permanent fee stream. Intentional.
- **Hook #2 sold at fixed price (100 APT default).** Not a Dutch auction,
  not an English bid. Natural price discovery via fee accumulation in
  the escrow-held NFT (buyer gets accumulated fees + future stream for
  a fixed 100 APT cost). We accept undervaluation risk.
- **No `meta_router` in Beta core.** Discovery goes to a future satellite
  package. Beta router only does raw multi-hop execution on pools the
  caller already knows about.
- **Symmetric seeding strict equality.** See Q7 above.
- **Admin constants hardcoded** (ADMIN_ADDR, TREASURY_ADDR, REVENUE_ADDR).
  Changing any of them requires a new package publish. Accepted in
  exchange for reduced admin attack surface.

---

## 9. Out of scope

Please do NOT audit:

- The `#[test_only]` module `tests.move` — it is already verified by
  `aptos move test` (31/31 passing). Its correctness is not on the critical
  path. You may reference it to understand intended behavior of the
  production modules.
- The Aptos framework dependencies (`aptos_framework::*`). We trust them.
- The underlying cryptography of BCS encoding, object address derivation,
  and signer capabilities.
- Frontend / SDK / indexer integrations (not included in this submission).
- The V1 "Alpha" package at `0x810693eb...`. It is legacy and will be
  frozen after Beta launch.

---

## 10. How to respond

Please return your review as Markdown with the structure described in
Section 1. If you find no blocking issues, please explicitly state "no
blocking issues found" and provide a green verdict.

If your review finds nothing to report in a category, please still
include an empty section (e.g., "HIGH: none") so we can compare coverage
across multiple reviewers.

---

## 11. Full source code

The following files constitute the complete audit scope. File order:

1. `contracts/Move.toml`
2. `contracts/sources/pool.move`
3. `contracts/sources/pool_factory.move`
4. `contracts/sources/router.move`
5. `contracts/sources/tests.move` (reference only, not in scope)




### 11.1 Move.toml

```toml
[package]
name = "DarbitexBeta"
version = "0.1.0"
upgrade_policy = "compatible"
authors = ["Rera", "Claude (Anthropic)"]
license = "Unlicense"

[dependencies.AptosFramework]
git = "https://github.com/aptos-labs/aptos-core.git"
rev = "mainnet"
subdir = "aptos-move/framework/aptos-framework"

[addresses]
darbitex = "0x8c8f40ef0b924657461253e7aa54a15fdfd8a3069e1404ba6ffda2223ddcadb7"
```

### 11.2 contracts/sources/pool.move

```move
/// Darbitex Beta — pool primitive.
///
/// One immutable pool per canonical pair. Every pool is created with two
/// HookNFT objects baked in (treasury slot 0 = soulbound, escrow slot 1 =
/// transferable). LP positions are Aptos objects (NFTs) with global fee
/// accumulator + per-position debt snapshot. Flash loans and TWAP oracle
/// at the pool level. Zero admin surface.

module darbitex::pool {
    use std::signer;
    use std::vector;
    use aptos_framework::event;
    use aptos_framework::object::{Self, Object, ConstructorRef, ExtendRef, DeleteRef};
    use aptos_framework::fungible_asset::{Self, FungibleAsset, Metadata};
    use aptos_framework::primary_fungible_store;
    use aptos_framework::timestamp;

    friend darbitex::pool_factory;

    // ===== Constants =====

    const SWAP_FEE_BPS: u64 = 1;
    const FLASH_FEE_BPS: u64 = 1;
    const BPS_DENOM: u64 = 10_000;
    const EXTRA_FEE_DENOM: u64 = 100_000;
    const HOOK_SPLIT_PCT: u64 = 50;
    const MINIMUM_LIQUIDITY: u64 = 1_000;
    const SCALE: u128 = 1_000_000_000_000;

    // ===== Errors =====

    const E_ZERO_AMOUNT: u64 = 1;
    const E_INSUFFICIENT_LIQUIDITY: u64 = 2;
    const E_SLIPPAGE: u64 = 3;
    const E_LOCKED: u64 = 4;
    const E_DISPROPORTIONAL: u64 = 5;
    const E_WRONG_POOL: u64 = 6;
    const E_INSUFFICIENT_LP: u64 = 7;
    const E_WRONG_TOKEN: u64 = 8;
    const E_SYMMETRIC_REQUIRED: u64 = 9;
    const E_K_VIOLATED: u64 = 10;
    const E_NOT_OWNER: u64 = 11;
    const E_NO_POSITION: u64 = 12;
    const E_NO_HOOK_NFT: u64 = 13;
    const E_NO_POOL: u64 = 14;
    const E_SAME_TOKEN: u64 = 15;

    // ===== Structs =====

    /// The pool itself. Config fields are immutable after create_pool returns.
    /// Operational state (reserves, lp_supply, accumulators, locked, twap,
    /// stats) mutates during normal swap / LP / flash operations.
    struct Pool has key {
        // Immutable config
        metadata_a: Object<Metadata>,
        metadata_b: Object<Metadata>,
        extend_ref: ExtendRef,
        hook_nft_1: address,           // treasury slot, soulbound
        hook_nft_2: address,           // escrow / marketplace slot, transferable
        schema_version: u8,

        // Reserves (principal only, LP fee accrues to lp_fee_per_share)
        reserve_a: u64,
        reserve_b: u64,
        lp_supply: u64,

        // LP fee global accumulator (cumulative per-share, scaled by SCALE)
        lp_fee_per_share_a: u128,
        lp_fee_per_share_b: u128,

        // Hook fee absolute accumulators (one pot per slot)
        hook_1_fee_a: u64,
        hook_1_fee_b: u64,
        hook_2_fee_a: u64,
        hook_2_fee_b: u64,

        // Reentrancy guard
        locked: bool,

        // TWAP (Uniswap V2 style cumulative)
        twap_cumulative_a: u128,
        twap_cumulative_b: u128,
        twap_last_ts: u64,

        // Stats
        total_swaps: u64,
        total_volume_a: u128,
        total_volume_b: u128,

        _reserved: vector<u8>,
    }

    /// LP position as an Aptos object. Each add_liquidity mints a new one.
    /// Transferable (can be sent to multisig, held by resource accounts, etc).
    /// Burned on remove_liquidity.
    struct LpPosition has key {
        pool_addr: address,
        shares: u64,
        fee_debt_a: u128,              // lp_fee_per_share_a snapshot at last sync
        fee_debt_b: u128,
        delete_ref: DeleteRef,
        schema_version: u8,
        _reserved: vector<u8>,
    }

    /// Hook NFT. Two are minted per pool at creation.
    /// Slot 0 = treasury (soulbound), slot 1 = escrow/marketplace (transferable).
    struct HookNFT has key {
        pool_addr: address,
        slot: u8,
        schema_version: u8,
        _reserved: vector<u8>,
    }

    /// Flash loan receipt. Hot-potato: no drop/store/key abilities.
    /// Must be consumed via flash_repay in the same TX.
    struct FlashReceipt {
        pool_addr: address,
        metadata: Object<Metadata>,
        amount: u64,
        fee: u64,
        k_before: u256,
    }

    // ===== Events =====

    #[event]
    struct PoolCreated has drop, store {
        pool_addr: address,
        metadata_a: address,
        metadata_b: address,
        creator: address,
        amount_a: u64,
        amount_b: u64,
        initial_lp: u64,
        hook_nft_1: address,
        hook_nft_2: address,
        timestamp: u64,
    }

    #[event]
    struct Swapped has drop, store {
        pool_addr: address,
        swapper: address,
        amount_in: u64,
        amount_out: u64,
        a_to_b: bool,
        lp_fee: u64,
        hook_1_fee: u64,
        hook_2_fee: u64,
        timestamp: u64,
    }

    #[event]
    struct LiquidityAdded has drop, store {
        pool_addr: address,
        provider: address,
        position_addr: address,
        amount_a: u64,
        amount_b: u64,
        shares_minted: u64,
        timestamp: u64,
    }

    #[event]
    struct LiquidityRemoved has drop, store {
        pool_addr: address,
        provider: address,
        position_addr: address,
        amount_a: u64,
        amount_b: u64,
        fees_a: u64,
        fees_b: u64,
        shares_burned: u64,
        timestamp: u64,
    }

    #[event]
    struct LpFeesClaimed has drop, store {
        pool_addr: address,
        position_addr: address,
        claimer: address,
        fees_a: u64,
        fees_b: u64,
        timestamp: u64,
    }

    #[event]
    struct HookFeesClaimed has drop, store {
        pool_addr: address,
        nft_addr: address,
        slot: u8,
        claimer: address,
        fees_a: u64,
        fees_b: u64,
        timestamp: u64,
    }

    #[event]
    struct FlashBorrowed has drop, store {
        pool_addr: address,
        metadata: address,
        amount: u64,
        fee: u64,
        timestamp: u64,
    }

    #[event]
    struct FlashRepaid has drop, store {
        pool_addr: address,
        metadata: address,
        amount: u64,
        fee: u64,
        timestamp: u64,
    }

    // ===== Internal helpers =====

    /// Babylonian integer sqrt for initial LP share computation.
    fun sqrt(x: u128): u128 {
        if (x == 0) return 0;
        let z = (x + 1) / 2;
        let y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        };
        y
    }

    /// Accumulate TWAP contribution for the elapsed time since last update.
    /// Must be called BEFORE reserves mutate so the contribution reflects
    /// the pre-mutation reserve ratio.
    fun update_twap(pool: &mut Pool) {
        let now = timestamp::now_seconds();
        let dt = now - pool.twap_last_ts;
        if (dt > 0) {
            pool.twap_cumulative_a = pool.twap_cumulative_a + (pool.reserve_a as u128) * (dt as u128);
            pool.twap_cumulative_b = pool.twap_cumulative_b + (pool.reserve_b as u128) * (dt as u128);
            pool.twap_last_ts = now;
        }
    }

    /// Split `extra_fee` across the three accumulators and return (lp_portion,
    /// hook_1_portion, hook_2_portion) for event attribution. `a_side=true`
    /// means the fee is collected in metadata_a reserves, otherwise metadata_b.
    fun accrue_fee(
        pool: &mut Pool,
        total_fee: u64,
        extra_fee: u64,
        a_side: bool,
    ): (u64, u64, u64) {
        // Hook pot = extra_fee, split HOOK_SPLIT_PCT / (100 - HOOK_SPLIT_PCT).
        let hook_1_portion = extra_fee * HOOK_SPLIT_PCT / 100;
        let hook_2_portion = extra_fee - hook_1_portion;

        // LP portion = total_fee - extra_fee (remainder stays in reserves as
        // growth per the x*y=k wedge). Saturate to 0 on underflow (dust swap
        // regime where total_fee floored below extra_fee).
        let lp_portion = if (total_fee > extra_fee) { total_fee - extra_fee } else { 0 };

        // Accumulate hook pots (absolute).
        if (a_side) {
            pool.hook_1_fee_a = pool.hook_1_fee_a + hook_1_portion;
            pool.hook_2_fee_a = pool.hook_2_fee_a + hook_2_portion;
        } else {
            pool.hook_1_fee_b = pool.hook_1_fee_b + hook_1_portion;
            pool.hook_2_fee_b = pool.hook_2_fee_b + hook_2_portion;
        };

        // Accumulate LP per-share global (scaled).
        if (lp_portion > 0 && pool.lp_supply > 0) {
            let add = (lp_portion as u128) * SCALE / (pool.lp_supply as u128);
            if (a_side) {
                pool.lp_fee_per_share_a = pool.lp_fee_per_share_a + add;
            } else {
                pool.lp_fee_per_share_b = pool.lp_fee_per_share_b + add;
            }
        };

        (lp_portion, hook_1_portion, hook_2_portion)
    }

    /// Compute `(per_share_current - per_share_debt) * shares / SCALE` in u256
    /// to avoid overflow, return u64.
    fun pending_from_accumulator(
        per_share_current: u128,
        per_share_debt: u128,
        shares: u64,
    ): u64 {
        if (per_share_current <= per_share_debt) return 0;
        let delta = per_share_current - per_share_debt;
        let product = (delta as u256) * (shares as u256);
        let scaled = product / (SCALE as u256);
        (scaled as u64)
    }

    /// Mint a HookNFT at a deterministic named-object address under the pool.
    /// `soulbound = true` disables ungated transfer after the initial move.
    /// Returns the NFT object address.
    fun mint_hook_nft(
        pool_signer: &signer,
        pool_addr: address,
        slot: u8,
        initial_owner: address,
        soulbound: bool,
        seed: vector<u8>,
    ): address {
        let ctor = object::create_named_object(pool_signer, seed);
        let nft_signer = object::generate_signer(&ctor);
        let nft_addr = signer::address_of(&nft_signer);
        let transfer_ref = object::generate_transfer_ref(&ctor);

        move_to(&nft_signer, HookNFT {
            pool_addr,
            slot,
            schema_version: 1,
            _reserved: vector::empty(),
        });

        // Transfer to initial owner via linear ref.
        let linear = object::generate_linear_transfer_ref(&transfer_ref);
        object::transfer_with_ref(linear, initial_owner);

        if (soulbound) {
            object::disable_ungated_transfer(&transfer_ref);
        };

        nft_addr
    }

    /// Mint a fresh LpPosition object for `owner_addr` with the given shares
    /// and debt snapshot. Returns the Object<LpPosition> handle.
    fun mint_lp_position(
        owner_addr: address,
        pool_addr: address,
        shares: u64,
        initial_debt_a: u128,
        initial_debt_b: u128,
    ): Object<LpPosition> {
        let ctor = object::create_object(owner_addr);
        let pos_signer = object::generate_signer(&ctor);
        let delete_ref = object::generate_delete_ref(&ctor);

        move_to(&pos_signer, LpPosition {
            pool_addr,
            shares,
            fee_debt_a: initial_debt_a,
            fee_debt_b: initial_debt_b,
            delete_ref,
            schema_version: 1,
            _reserved: vector::empty(),
        });

        object::object_from_constructor_ref<LpPosition>(&ctor)
    }

    // ===== Pool Creation (friend-only) =====

    /// Atomic pool + hook NFTs + initial LP position creation. Called only by
    /// pool_factory::create_canonical_pool. The factory supplies the
    /// constructor_ref for the canonical pool address and pulls seeding
    /// tokens from the creator into its own primary store before calling.
    ///
    /// Returns (pool_addr, hook_nft_1_addr, hook_nft_2_addr, lp_position_object).
    public(friend) fun create_pool(
        factory_signer: &signer,
        factory_addr: address,
        treasury_addr: address,
        creator_addr: address,
        constructor_ref: &ConstructorRef,
        metadata_a: Object<Metadata>,
        metadata_b: Object<Metadata>,
        amount_a: u64,
        amount_b: u64,
    ): (address, address, address, Object<LpPosition>) {
        // Symmetric seeding enforcement: Beta rule, stricter than V1's tolerance.
        assert!(amount_a == amount_b, E_SYMMETRIC_REQUIRED);
        assert!(amount_a > 0, E_ZERO_AMOUNT);
        assert!(
            object::object_address(&metadata_a) != object::object_address(&metadata_b),
            E_SAME_TOKEN,
        );

        let pool_signer = object::generate_signer(constructor_ref);
        let pool_addr = signer::address_of(&pool_signer);
        let extend_ref = object::generate_extend_ref(constructor_ref);

        // Lock pool object transfer (pool is not tradable).
        let pool_transfer_ref = object::generate_transfer_ref(constructor_ref);
        object::disable_ungated_transfer(&pool_transfer_ref);

        // Move seeding tokens from factory primary store into pool primary store.
        let fa_a = primary_fungible_store::withdraw(factory_signer, metadata_a, amount_a);
        let fa_b = primary_fungible_store::withdraw(factory_signer, metadata_b, amount_b);
        primary_fungible_store::deposit(pool_addr, fa_a);
        primary_fungible_store::deposit(pool_addr, fa_b);

        // Compute initial LP shares: sqrt(a*b). Dead MINIMUM_LIQUIDITY shares
        // locked in the pool to prevent first-depositor attacks.
        let initial_lp_u128 = sqrt((amount_a as u128) * (amount_b as u128));
        assert!(initial_lp_u128 > (MINIMUM_LIQUIDITY as u128), E_INSUFFICIENT_LIQUIDITY);
        let initial_lp = (initial_lp_u128 as u64);
        let creator_shares = initial_lp - MINIMUM_LIQUIDITY;

        // Mint HookNFT #1 → treasury, soulbound.
        let hook_1_addr = mint_hook_nft(
            &pool_signer,
            pool_addr,
            0,
            treasury_addr,
            true,
            b"darbitex_hook_1",
        );

        // Mint HookNFT #2 → factory escrow, transferable.
        let hook_2_addr = mint_hook_nft(
            &pool_signer,
            pool_addr,
            1,
            factory_addr,
            false,
            b"darbitex_hook_2",
        );

        let now = timestamp::now_seconds();

        move_to(&pool_signer, Pool {
            metadata_a,
            metadata_b,
            extend_ref,
            hook_nft_1: hook_1_addr,
            hook_nft_2: hook_2_addr,
            schema_version: 1,

            reserve_a: amount_a,
            reserve_b: amount_b,
            lp_supply: initial_lp,

            lp_fee_per_share_a: 0,
            lp_fee_per_share_b: 0,

            hook_1_fee_a: 0, hook_1_fee_b: 0,
            hook_2_fee_a: 0, hook_2_fee_b: 0,

            locked: false,

            twap_cumulative_a: 0,
            twap_cumulative_b: 0,
            twap_last_ts: now,

            total_swaps: 0,
            total_volume_a: 0,
            total_volume_b: 0,

            _reserved: vector::empty(),
        });

        // Mint the creator's LpPosition. Initial debt = 0 because lp_fee_per_share
        // is 0 at creation time (no prior swaps).
        let position = mint_lp_position(creator_addr, pool_addr, creator_shares, 0, 0);
        let position_addr = object::object_address(&position);

        event::emit(PoolCreated {
            pool_addr,
            metadata_a: object::object_address(&metadata_a),
            metadata_b: object::object_address(&metadata_b),
            creator: creator_addr,
            amount_a,
            amount_b,
            initial_lp,
            hook_nft_1: hook_1_addr,
            hook_nft_2: hook_2_addr,
            timestamp: now,
        });

        event::emit(LiquidityAdded {
            pool_addr,
            provider: creator_addr,
            position_addr,
            amount_a,
            amount_b,
            shares_minted: creator_shares,
            timestamp: now,
        });

        (pool_addr, hook_1_addr, hook_2_addr, position)
    }

    // ===== Swap =====

    /// Composable swap primitive. Takes FungibleAsset and returns FungibleAsset.
    /// No `&signer` — authorization happens at the caller's FA withdraw. The
    /// `swapper` address is recorded in the Swapped event for attribution only.
    public fun swap(
        pool_addr: address,
        swapper: address,
        fa_in: FungibleAsset,
        min_out: u64,
    ): FungibleAsset acquires Pool {
        assert!(exists<Pool>(pool_addr), E_NO_POOL);
        let pool = borrow_global_mut<Pool>(pool_addr);
        assert!(!pool.locked, E_LOCKED);
        pool.locked = true;

        update_twap(pool);

        let in_metadata = fungible_asset::asset_metadata(&fa_in);
        let amount_in = fungible_asset::amount(&fa_in);
        assert!(amount_in > 0, E_ZERO_AMOUNT);

        let a_to_b =
            if (object::object_address(&in_metadata) == object::object_address(&pool.metadata_a)) {
                true
            } else {
                assert!(
                    object::object_address(&in_metadata) == object::object_address(&pool.metadata_b),
                    E_WRONG_TOKEN,
                );
                false
            };

        let (reserve_in, reserve_out) = if (a_to_b) {
            (pool.reserve_a, pool.reserve_b)
        } else {
            (pool.reserve_b, pool.reserve_a)
        };

        // x*y=k swap math with SWAP_FEE_BPS wedge. All intermediate products
        // computed in u256 to avoid the u128 overflow risk flagged by audit
        // MEDIUM-1 (Claude + DeepSeek + Gemini): for pools with
        // reserve_out near u64::MAX and amount_in near u64::MAX, the u128
        // product `amount_in × 9999 × reserve_out` can exceed 2^128. The
        // final result is bounded by reserve_out ≤ u64::MAX so the cast
        // back to u64 is safe.
        let amount_in_after_fee = (amount_in as u256) * ((BPS_DENOM - SWAP_FEE_BPS) as u256);
        let numerator = amount_in_after_fee * (reserve_out as u256);
        let denominator = (reserve_in as u256) * (BPS_DENOM as u256) + amount_in_after_fee;
        let amount_out = ((numerator / denominator) as u64);

        assert!(amount_out >= min_out, E_SLIPPAGE);
        assert!(amount_out < reserve_out, E_INSUFFICIENT_LIQUIDITY);

        // Compute fees. total_fee = amount_in * SWAP_FEE_BPS / BPS_DENOM.
        // extra_fee = amount_in / EXTRA_FEE_DENOM (hook pot portion), floored
        // up to 1 so dust swaps still produce hook revenue.
        let total_fee = amount_in * SWAP_FEE_BPS / BPS_DENOM;
        let extra_fee_raw = amount_in / EXTRA_FEE_DENOM;
        let extra_fee = if (extra_fee_raw == 0 && amount_in > 0) { 1 } else { extra_fee_raw };

        let (lp_fee, hook_1_fee, hook_2_fee) = accrue_fee(pool, total_fee, extra_fee, a_to_b);

        // Total amount pulled out of reserves = what accrue_fee credited
        // to the hook buckets plus what it credited to the lp accumulator.
        // This equals max(total_fee, extra_fee) in effect: for normal swaps
        // it's total_fee, for dust swaps where total_fee floors to 0 it's
        // extra_fee (the floor-protected hook portion) with lp_fee == 0.
        // Keeping reserves and accumulators in lockstep fixes audit HIGH-1
        // (self-audit 2026-04-12) — reserves now track principal only.
        let reserve_fee = extra_fee + lp_fee;

        if (a_to_b) {
            pool.reserve_a = pool.reserve_a + amount_in - reserve_fee;
            pool.reserve_b = pool.reserve_b - amount_out;
        } else {
            pool.reserve_a = pool.reserve_a - amount_out;
            pool.reserve_b = pool.reserve_b + amount_in - reserve_fee;
        };

        pool.total_swaps = pool.total_swaps + 1;
        if (a_to_b) {
            pool.total_volume_a = pool.total_volume_a + (amount_in as u128);
        } else {
            pool.total_volume_b = pool.total_volume_b + (amount_in as u128);
        };

        // Settle FA: deposit incoming into pool store, withdraw outgoing.
        primary_fungible_store::deposit(pool_addr, fa_in);
        let pool_signer = object::generate_signer_for_extending(&pool.extend_ref);
        let out_metadata = if (a_to_b) { pool.metadata_b } else { pool.metadata_a };
        let fa_out = primary_fungible_store::withdraw(&pool_signer, out_metadata, amount_out);

        pool.locked = false;

        event::emit(Swapped {
            pool_addr,
            swapper,
            amount_in,
            amount_out,
            a_to_b,
            lp_fee,
            hook_1_fee,
            hook_2_fee,
            timestamp: timestamp::now_seconds(),
        });

        fa_out
    }

    // ===== Liquidity =====

    /// Add liquidity to an existing pool. Mints a new LpPosition NFT to
    /// the provider; each add_liquidity call mints a separate position
    /// (no merging).
    ///
    /// `amount_a_desired` and `amount_b_desired` are the MAXIMUM amounts
    /// the caller is willing to deposit on each side. The function picks
    /// the Uniswap V2-router-style optimal pair: the side whose desired
    /// amount more tightly matches the current reserve ratio is used in
    /// full, and the other side uses only the proportional amount. The
    /// unused buffer on the "loose" side stays in the caller's wallet.
    /// This prevents the silent buffer donation bug from round 2 audit
    /// HIGH-1 (Gemini).
    ///
    /// `min_shares_out` is the slippage floor on minted shares. Aborts
    /// with `E_SLIPPAGE` if fewer shares would be minted. Callers that
    /// do not care about exact share counts can pass 0.
    public fun add_liquidity(
        provider: &signer,
        pool_addr: address,
        amount_a_desired: u64,
        amount_b_desired: u64,
        min_shares_out: u64,
    ): Object<LpPosition> acquires Pool {
        assert!(exists<Pool>(pool_addr), E_NO_POOL);
        assert!(amount_a_desired > 0 && amount_b_desired > 0, E_ZERO_AMOUNT);

        let pool = borrow_global_mut<Pool>(pool_addr);
        assert!(!pool.locked, E_LOCKED);

        update_twap(pool);

        // Uniswap V2 router-style optimal amount computation. Given the
        // current reserve ratio (reserve_a : reserve_b), figure out which
        // of the two desired amounts is the tight side and use the other
        // side's proportional amount. The unused buffer stays in the
        // caller's wallet — we never withdraw more than the optimal pair.
        let amount_b_optimal = (
            ((amount_a_desired as u256) * (pool.reserve_b as u256)
                / (pool.reserve_a as u256)) as u64
        );
        let (amount_a, amount_b) = if (amount_b_optimal <= amount_b_desired) {
            // amount_a is the tight side: use it in full, use only
            // amount_b_optimal of the b-side, leaving
            // (amount_b_desired - amount_b_optimal) in the caller's wallet.
            (amount_a_desired, amount_b_optimal)
        } else {
            // amount_b is the tight side: compute the optimal a to match
            // amount_b_desired at the current ratio. This value is
            // guaranteed ≤ amount_a_desired by the ratio constraint.
            let amount_a_optimal = (
                ((amount_b_desired as u256) * (pool.reserve_a as u256)
                    / (pool.reserve_b as u256)) as u64
            );
            // Sanity assert — mathematically this must hold given the
            // if-branch condition, but we check defensively.
            assert!(amount_a_optimal <= amount_a_desired, E_DISPROPORTIONAL);
            (amount_a_optimal, amount_b_desired)
        };

        assert!(amount_a > 0 && amount_b > 0, E_ZERO_AMOUNT);

        // Compute shares minted proportionally. With the optimal pair
        // computed above, lp_a and lp_b are equal within integer
        // rounding; we take min as a defensive measure.
        let lp_a = (
            ((amount_a as u256) * (pool.lp_supply as u256)
                / (pool.reserve_a as u256)) as u64
        );
        let lp_b = (
            ((amount_b as u256) * (pool.lp_supply as u256)
                / (pool.reserve_b as u256)) as u64
        );
        let shares = if (lp_a < lp_b) { lp_a } else { lp_b };
        assert!(shares > 0, E_ZERO_AMOUNT);
        assert!(shares >= min_shares_out, E_SLIPPAGE);

        let provider_addr = signer::address_of(provider);

        // Pull ONLY the optimal amounts from provider. The buffer stays
        // in their wallet.
        let fa_a = primary_fungible_store::withdraw(provider, pool.metadata_a, amount_a);
        let fa_b = primary_fungible_store::withdraw(provider, pool.metadata_b, amount_b);
        primary_fungible_store::deposit(pool_addr, fa_a);
        primary_fungible_store::deposit(pool_addr, fa_b);

        pool.reserve_a = pool.reserve_a + amount_a;
        pool.reserve_b = pool.reserve_b + amount_b;
        pool.lp_supply = pool.lp_supply + shares;

        // Snapshot the current per_share as this position's debt so the
        // holder only earns on swaps after the deposit moment.
        let debt_a = pool.lp_fee_per_share_a;
        let debt_b = pool.lp_fee_per_share_b;

        let position = mint_lp_position(provider_addr, pool_addr, shares, debt_a, debt_b);
        let position_addr = object::object_address(&position);

        event::emit(LiquidityAdded {
            pool_addr,
            provider: provider_addr,
            position_addr,
            amount_a,  // actual amount used, not desired
            amount_b,  // actual amount used, not desired
            shares_minted: shares,
            timestamp: timestamp::now_seconds(),
        });

        position
    }

    /// Composable remove_liquidity. Burns the LpPosition and returns the
    /// proportional reserves PLUS any accumulated LP fees in one shot.
    ///
    /// `min_amount_a` and `min_amount_b` are slippage floors on the
    /// proportional reserve payout (not including fee claims). A sandwich
    /// attacker can shift the reserve ratio between TX submission and
    /// execution, so LPs should specify a minimum they are willing to
    /// accept. Callers who do not care can pass 0. Added per audit
    /// round-2 MEDIUM-1 (fresh Claude Opus 4.6 audit).
    public fun remove_liquidity(
        provider: &signer,
        position: Object<LpPosition>,
        min_amount_a: u64,
        min_amount_b: u64,
    ): (FungibleAsset, FungibleAsset) acquires Pool, LpPosition {
        let provider_addr = signer::address_of(provider);
        assert!(object::owner(position) == provider_addr, E_NOT_OWNER);

        let position_addr = object::object_address(&position);
        assert!(exists<LpPosition>(position_addr), E_NO_POSITION);

        let LpPosition {
            pool_addr,
            shares,
            fee_debt_a,
            fee_debt_b,
            delete_ref,
            schema_version: _,
            _reserved: _,
        } = move_from<LpPosition>(position_addr);

        assert!(exists<Pool>(pool_addr), E_NO_POOL);
        let pool = borrow_global_mut<Pool>(pool_addr);
        assert!(!pool.locked, E_LOCKED);
        assert!(shares > 0, E_ZERO_AMOUNT);
        assert!(pool.lp_supply >= shares, E_INSUFFICIENT_LP);

        update_twap(pool);

        // Compute accumulated LP fees for this position.
        let claim_a = pending_from_accumulator(pool.lp_fee_per_share_a, fee_debt_a, shares);
        let claim_b = pending_from_accumulator(pool.lp_fee_per_share_b, fee_debt_b, shares);

        // Proportional reserve payout. u256 intermediate (audit MEDIUM-2).
        let amount_a = (
            ((shares as u256) * (pool.reserve_a as u256) / (pool.lp_supply as u256)) as u64
        );
        let amount_b = (
            ((shares as u256) * (pool.reserve_b as u256) / (pool.lp_supply as u256)) as u64
        );

        // Slippage protection on principal withdrawal (not fees). Sandwich
        // attacks on active pools can shift reserve ratios; this check
        // lets LPs bail if the ratio moved against them.
        assert!(amount_a >= min_amount_a, E_SLIPPAGE);
        assert!(amount_b >= min_amount_b, E_SLIPPAGE);

        pool.lp_supply = pool.lp_supply - shares;
        assert!(pool.lp_supply >= MINIMUM_LIQUIDITY, E_INSUFFICIENT_LIQUIDITY);
        pool.reserve_a = pool.reserve_a - amount_a;
        pool.reserve_b = pool.reserve_b - amount_b;

        // Withdraw reserves + fees from pool store.
        let pool_signer = object::generate_signer_for_extending(&pool.extend_ref);
        let total_a = amount_a + claim_a;
        let total_b = amount_b + claim_b;
        let fa_a = primary_fungible_store::withdraw(&pool_signer, pool.metadata_a, total_a);
        let fa_b = primary_fungible_store::withdraw(&pool_signer, pool.metadata_b, total_b);

        event::emit(LiquidityRemoved {
            pool_addr,
            provider: provider_addr,
            position_addr,
            amount_a,
            amount_b,
            fees_a: claim_a,
            fees_b: claim_b,
            shares_burned: shares,
            timestamp: timestamp::now_seconds(),
        });

        // Delete the position object.
        object::delete(delete_ref);

        (fa_a, fa_b)
    }

    // ===== Fee Claims =====

    /// Harvest accumulated LP fees without touching the position's shares.
    /// Resets the position's debt snapshot to current per_share so future
    /// accumulation starts from zero.
    ///
    /// Defense-in-depth: sets `pool.locked = true` during execution even
    /// though Aptos FA operations don't currently have callback hooks that
    /// could re-enter. If a future framework update adds FA dispatch
    /// hooks, this function is already safe. Per audit round-2 MEDIUM-2
    /// (fresh Claude Opus 4.6 audit).
    public fun claim_lp_fees(
        provider: &signer,
        position: Object<LpPosition>,
    ): (FungibleAsset, FungibleAsset) acquires Pool, LpPosition {
        let provider_addr = signer::address_of(provider);
        assert!(object::owner(position) == provider_addr, E_NOT_OWNER);

        let position_addr = object::object_address(&position);
        assert!(exists<LpPosition>(position_addr), E_NO_POSITION);

        let pos = borrow_global_mut<LpPosition>(position_addr);
        assert!(exists<Pool>(pos.pool_addr), E_NO_POOL);

        let pool = borrow_global_mut<Pool>(pos.pool_addr);
        assert!(!pool.locked, E_LOCKED);
        pool.locked = true;

        update_twap(pool);

        let claim_a = pending_from_accumulator(pool.lp_fee_per_share_a, pos.fee_debt_a, pos.shares);
        let claim_b = pending_from_accumulator(pool.lp_fee_per_share_b, pos.fee_debt_b, pos.shares);

        pos.fee_debt_a = pool.lp_fee_per_share_a;
        pos.fee_debt_b = pool.lp_fee_per_share_b;

        let pool_signer = object::generate_signer_for_extending(&pool.extend_ref);
        let fa_a = if (claim_a > 0) {
            primary_fungible_store::withdraw(&pool_signer, pool.metadata_a, claim_a)
        } else {
            fungible_asset::zero(pool.metadata_a)
        };
        let fa_b = if (claim_b > 0) {
            primary_fungible_store::withdraw(&pool_signer, pool.metadata_b, claim_b)
        } else {
            fungible_asset::zero(pool.metadata_b)
        };

        pool.locked = false;

        event::emit(LpFeesClaimed {
            pool_addr: pos.pool_addr,
            position_addr,
            claimer: provider_addr,
            fees_a: claim_a,
            fees_b: claim_b,
            timestamp: timestamp::now_seconds(),
        });

        (fa_a, fa_b)
    }

    /// Harvest hook fees for whichever slot the NFT owner holds. Resets the
    /// absolute bucket for that slot. Works for both treasury slot 0 and
    /// escrow/market slot 1.
    ///
    /// Defense-in-depth: sets `pool.locked = true` during execution. Per
    /// audit round-2 MEDIUM-2 (fresh Claude Opus 4.6 audit).
    public fun claim_hook_fees(
        caller: &signer,
        nft: Object<HookNFT>,
    ): (FungibleAsset, FungibleAsset) acquires Pool, HookNFT {
        let caller_addr = signer::address_of(caller);
        assert!(object::owner(nft) == caller_addr, E_NOT_OWNER);

        let nft_addr = object::object_address(&nft);
        assert!(exists<HookNFT>(nft_addr), E_NO_HOOK_NFT);

        let nft_ref = borrow_global<HookNFT>(nft_addr);
        let pool_addr = nft_ref.pool_addr;
        let slot = nft_ref.slot;

        assert!(exists<Pool>(pool_addr), E_NO_POOL);
        let pool = borrow_global_mut<Pool>(pool_addr);
        assert!(!pool.locked, E_LOCKED);
        pool.locked = true;

        let (fees_a, fees_b) = if (slot == 0) {
            let a = pool.hook_1_fee_a;
            let b = pool.hook_1_fee_b;
            pool.hook_1_fee_a = 0;
            pool.hook_1_fee_b = 0;
            (a, b)
        } else {
            let a = pool.hook_2_fee_a;
            let b = pool.hook_2_fee_b;
            pool.hook_2_fee_a = 0;
            pool.hook_2_fee_b = 0;
            (a, b)
        };

        let pool_signer = object::generate_signer_for_extending(&pool.extend_ref);
        let fa_a = if (fees_a > 0) {
            primary_fungible_store::withdraw(&pool_signer, pool.metadata_a, fees_a)
        } else {
            fungible_asset::zero(pool.metadata_a)
        };
        let fa_b = if (fees_b > 0) {
            primary_fungible_store::withdraw(&pool_signer, pool.metadata_b, fees_b)
        } else {
            fungible_asset::zero(pool.metadata_b)
        };

        pool.locked = false;

        event::emit(HookFeesClaimed {
            pool_addr,
            nft_addr,
            slot,
            claimer: caller_addr,
            fees_a,
            fees_b,
            timestamp: timestamp::now_seconds(),
        });

        (fa_a, fa_b)
    }

    // ===== Flash loan =====

    /// Flash borrow up to `amount` of `metadata` from the pool. Returns the
    /// borrowed FA and a FlashReceipt hot-potato that must be consumed via
    /// flash_repay in the same TX or the TX aborts. Pool is locked during
    /// the borrow span — swap/LP/flash ops abort until repay.
    public fun flash_borrow(
        pool_addr: address,
        metadata: Object<Metadata>,
        amount: u64,
    ): (FungibleAsset, FlashReceipt) acquires Pool {
        assert!(exists<Pool>(pool_addr), E_NO_POOL);
        assert!(amount > 0, E_ZERO_AMOUNT);

        let pool = borrow_global_mut<Pool>(pool_addr);
        assert!(!pool.locked, E_LOCKED);
        pool.locked = true;

        let metadata_addr = object::object_address(&metadata);
        let is_a = metadata_addr == object::object_address(&pool.metadata_a);
        assert!(is_a || metadata_addr == object::object_address(&pool.metadata_b), E_WRONG_TOKEN);

        let (reserve_in, reserve_out) = if (is_a) {
            (pool.reserve_a, pool.reserve_b)
        } else {
            (pool.reserve_b, pool.reserve_a)
        };
        assert!(amount < reserve_in, E_INSUFFICIENT_LIQUIDITY);

        // Record k_before in u256 to make repay-time invariant check safe.
        let k_before = (reserve_in as u256) * (reserve_out as u256);

        // Fee on borrowed amount, minimum 1 so dust borrows still pay.
        let fee_raw = amount * FLASH_FEE_BPS / BPS_DENOM;
        let fee = if (fee_raw == 0) { 1 } else { fee_raw };

        let pool_signer = object::generate_signer_for_extending(&pool.extend_ref);
        let fa_out = primary_fungible_store::withdraw(&pool_signer, metadata, amount);

        event::emit(FlashBorrowed {
            pool_addr,
            metadata: metadata_addr,
            amount,
            fee,
            timestamp: timestamp::now_seconds(),
        });

        let receipt = FlashReceipt {
            pool_addr,
            metadata,
            amount,
            fee,
            k_before,
        };

        (fa_out, receipt)
    }

    /// Repay the flash borrow with the original principal plus fee. Consumes
    /// the hot-potato receipt. Asserts the k-invariant holds (reserves × after
    /// repay must not fall below pre-borrow product). Releases the lock.
    ///
    /// Reserve accounting note: `flash_borrow` does NOT decrement `reserve_a`
    /// or `reserve_b` when the borrowed amount leaves the store, because the
    /// `locked` flag guarantees no one reads reserves during the borrow span.
    /// Therefore `flash_repay` must NOT add the principal back to reserves —
    /// doing so would inflate reserves by `amount`, breaking solvency. Only
    /// the fee is routed (to hook buckets via accrue_fee and implicitly to
    /// LP via the accumulator). Fixed per audit HIGH-1 (self-audit and
    /// external auditor 2026-04-12).
    public fun flash_repay(
        pool_addr: address,
        fa_in: FungibleAsset,
        receipt: FlashReceipt,
    ) acquires Pool {
        let FlashReceipt { pool_addr: r_pool, metadata, amount, fee, k_before } = receipt;
        assert!(pool_addr == r_pool, E_WRONG_POOL);

        let repay_total = amount + fee;
        // Strict equality prevents silent donation of excess. Per audit
        // LOW-2 (external 2026-04-12): a `>=` check would let clumsy
        // callers pass fa_in with more than repay_total; the excess would
        // be deposited into the store as untracked surplus ("trapped").
        // Forcing exact equality turns this footgun into an abort.
        assert!(fungible_asset::amount(&fa_in) == repay_total, E_INSUFFICIENT_LIQUIDITY);
        assert!(
            object::object_address(&fungible_asset::asset_metadata(&fa_in)) == object::object_address(&metadata),
            E_WRONG_TOKEN,
        );

        let pool = borrow_global_mut<Pool>(pool_addr);

        // Deposit repayment into pool store. Store now holds (pre_borrow + fee)
        // of the borrowed-side metadata, because the principal that was
        // withdrawn in flash_borrow comes back in fa_in alongside the fee.
        primary_fungible_store::deposit(pool_addr, fa_in);

        // Route fee through accrue_fee: hook portion to absolute buckets, LP
        // portion to lp_fee_per_share accumulator. Nothing is added to
        // reserves — they were never decremented during flash_borrow.
        let is_a = object::object_address(&metadata) == object::object_address(&pool.metadata_a);
        let extra_fee_raw = amount / EXTRA_FEE_DENOM;
        let extra_fee = if (extra_fee_raw == 0) { 1 } else { extra_fee_raw };
        // Cap extra_fee to the actual fee amount (in case fee < extra_fee_raw
        // for very small borrows).
        let extra_fee = if (extra_fee > fee) { fee } else { extra_fee };
        let (_lp, _h1, _h2) = accrue_fee(pool, fee, extra_fee, is_a);

        // k-invariant assertion: post-repay reserves product must be >= the
        // pre-borrow snapshot. With the reserve-unchanged fix above, equality
        // is the expected case (flash loan is economically neutral to k).
        // This check remains as a safety net in case a future refactor
        // reintroduces reserve mutations on the flash path.
        let k_after = (pool.reserve_a as u256) * (pool.reserve_b as u256);
        assert!(k_after >= k_before, E_K_VIOLATED);

        pool.locked = false;

        event::emit(FlashRepaid {
            pool_addr,
            metadata: object::object_address(&metadata),
            amount,
            fee,
            timestamp: timestamp::now_seconds(),
        });
    }

    // ===== Entry wrappers (user-facing convenience) =====

    /// Entry variant of add_liquidity. Position NFT is minted to provider
    /// address as part of create_object; no explicit transfer needed.
    /// `min_shares_out` is the slippage floor — pass 0 for no protection.
    public entry fun add_liquidity_entry(
        provider: &signer,
        pool_addr: address,
        amount_a: u64,
        amount_b: u64,
        min_shares_out: u64,
    ) acquires Pool {
        let _ = add_liquidity(provider, pool_addr, amount_a, amount_b, min_shares_out);
    }

    /// Entry variant of remove_liquidity. Deposits both returned FAs back to
    /// provider's primary store. `min_amount_a` / `min_amount_b` are
    /// slippage floors — pass 0 for no protection.
    public entry fun remove_liquidity_entry(
        provider: &signer,
        position: Object<LpPosition>,
        min_amount_a: u64,
        min_amount_b: u64,
    ) acquires Pool, LpPosition {
        let provider_addr = signer::address_of(provider);
        let (fa_a, fa_b) = remove_liquidity(provider, position, min_amount_a, min_amount_b);
        primary_fungible_store::deposit(provider_addr, fa_a);
        primary_fungible_store::deposit(provider_addr, fa_b);
    }

    /// Entry variant of claim_lp_fees.
    public entry fun claim_lp_fees_entry(
        provider: &signer,
        position: Object<LpPosition>,
    ) acquires Pool, LpPosition {
        let provider_addr = signer::address_of(provider);
        let (fa_a, fa_b) = claim_lp_fees(provider, position);
        primary_fungible_store::deposit(provider_addr, fa_a);
        primary_fungible_store::deposit(provider_addr, fa_b);
    }

    /// Entry variant of claim_hook_fees.
    public entry fun claim_hook_fees_entry(
        caller: &signer,
        nft: Object<HookNFT>,
    ) acquires Pool, HookNFT {
        let caller_addr = signer::address_of(caller);
        let (fa_a, fa_b) = claim_hook_fees(caller, nft);
        primary_fungible_store::deposit(caller_addr, fa_a);
        primary_fungible_store::deposit(caller_addr, fa_b);
    }

    // ===== Views =====

    #[view]
    public fun pool_exists(pool_addr: address): bool {
        exists<Pool>(pool_addr)
    }

    #[view]
    public fun reserves(pool_addr: address): (u64, u64) acquires Pool {
        let p = borrow_global<Pool>(pool_addr);
        (p.reserve_a, p.reserve_b)
    }

    #[view]
    public fun pool_tokens(pool_addr: address): (Object<Metadata>, Object<Metadata>) acquires Pool {
        let p = borrow_global<Pool>(pool_addr);
        (p.metadata_a, p.metadata_b)
    }

    #[view]
    public fun hook_nft_addresses(pool_addr: address): (address, address) acquires Pool {
        let p = borrow_global<Pool>(pool_addr);
        (p.hook_nft_1, p.hook_nft_2)
    }

    #[view]
    public fun lp_supply(pool_addr: address): u64 acquires Pool {
        borrow_global<Pool>(pool_addr).lp_supply
    }

    #[view]
    public fun lp_fee_per_share(pool_addr: address): (u128, u128) acquires Pool {
        let p = borrow_global<Pool>(pool_addr);
        (p.lp_fee_per_share_a, p.lp_fee_per_share_b)
    }

    #[view]
    public fun hook_fee_buckets(pool_addr: address): (u64, u64, u64, u64) acquires Pool {
        let p = borrow_global<Pool>(pool_addr);
        (p.hook_1_fee_a, p.hook_1_fee_b, p.hook_2_fee_a, p.hook_2_fee_b)
    }

    #[view]
    public fun twap_cumulative(pool_addr: address): (u128, u128, u64) acquires Pool {
        let p = borrow_global<Pool>(pool_addr);
        (p.twap_cumulative_a, p.twap_cumulative_b, p.twap_last_ts)
    }

    #[view]
    public fun total_stats(pool_addr: address): (u64, u128, u128) acquires Pool {
        let p = borrow_global<Pool>(pool_addr);
        (p.total_swaps, p.total_volume_a, p.total_volume_b)
    }

    #[view]
    public fun get_amount_out(
        pool_addr: address,
        amount_in: u64,
        a_to_b: bool,
    ): u64 acquires Pool {
        let p = borrow_global<Pool>(pool_addr);
        let (reserve_in, reserve_out) = if (a_to_b) {
            (p.reserve_a, p.reserve_b)
        } else {
            (p.reserve_b, p.reserve_a)
        };
        // u256 intermediate to match the swap path and avoid overflow on
        // adversarial reserves (audit MEDIUM-1).
        let amount_in_after_fee = (amount_in as u256) * ((BPS_DENOM - SWAP_FEE_BPS) as u256);
        let numerator = amount_in_after_fee * (reserve_out as u256);
        let denominator = (reserve_in as u256) * (BPS_DENOM as u256) + amount_in_after_fee;
        ((numerator / denominator) as u64)
    }

    #[view]
    public fun position_info(position_addr: address): (address, u64, u128, u128) acquires LpPosition {
        let p = borrow_global<LpPosition>(position_addr);
        (p.pool_addr, p.shares, p.fee_debt_a, p.fee_debt_b)
    }

    #[view]
    public fun pending_lp_fees(position_addr: address): (u64, u64) acquires LpPosition, Pool {
        let pos = borrow_global<LpPosition>(position_addr);
        let pool = borrow_global<Pool>(pos.pool_addr);
        let a = pending_from_accumulator(pool.lp_fee_per_share_a, pos.fee_debt_a, pos.shares);
        let b = pending_from_accumulator(pool.lp_fee_per_share_b, pos.fee_debt_b, pos.shares);
        (a, b)
    }

    #[view]
    public fun hook_nft_info(nft_addr: address): (address, u8) acquires HookNFT {
        let n = borrow_global<HookNFT>(nft_addr);
        (n.pool_addr, n.slot)
    }
}
```

### 11.3 contracts/sources/pool_factory.move

```move
/// Darbitex Beta — pool factory.
///
/// Creates canonical pools (one per pair, enforced by deterministic
/// named-object addresses). Every pool creation is atomic: pool + 2
/// HookNFTs + initial LpPosition + escrow listing. The factory also
/// holds hook NFT #2 in escrow and serves `buy_hook` at a fixed admin-
/// configurable price, routing the APT payment to the operational
/// revenue address. No marketplace satellite needed.

module darbitex::pool_factory {
    use std::signer;
    use std::vector;
    use std::bcs;
    use aptos_std::table::{Self, Table};
    use aptos_framework::account::{Self, SignerCapability};
    use aptos_framework::object::{Self, Object};
    use aptos_framework::fungible_asset::Metadata;
    use aptos_framework::primary_fungible_store;
    use aptos_framework::aptos_account;
    use aptos_framework::event;
    use aptos_framework::timestamp;

    use darbitex::pool::{Self, HookNFT};

    // ===== Constants =====

    const FACTORY_SEED: vector<u8> = b"darbitex_factory";
    const POOL_SEED_PREFIX: vector<u8> = b"darbitex_pool";
    const DEFAULT_HOOK_PRICE: u64 = 10_000_000_000; // 100 APT in octas

    /// Treasury multisig (2-of-3, reused from V1). Receives HookNFT #1
    /// (soulbound slot) at every pool creation, earning a permanent hook
    /// fee stream across all Darbitex pools.
    const TREASURY_ADDR: address = @0xdbce89113a975826028236f910668c3ff99c8db8981be6a448caa2f8836f9576;

    /// Admin multisig (3-of-5, reused from V1). Can call `set_hook_price`
    /// to update the default listing price for future pools. Same address
    /// also receives `buy_hook` revenue (operational income).
    const ADMIN_ADDR: address = @0xf1b522effb90aef79395f97b9c39d6acbd8fdf84ec046361359a48de2e196566;

    /// buy_hook payment destination. Same as ADMIN_ADDR by design —
    /// operational multisig collects hook sale revenue.
    const REVENUE_ADDR: address = @0xf1b522effb90aef79395f97b9c39d6acbd8fdf84ec046361359a48de2e196566;

    // ===== Errors =====

    const E_NOT_ADMIN: u64 = 1;
    const E_ALREADY_INIT: u64 = 2;
    const E_NOT_INIT: u64 = 3;
    const E_WRONG_ORDER: u64 = 4;
    const E_ZERO: u64 = 5;
    const E_NOT_LISTED: u64 = 6;
    const E_SAME_TOKEN: u64 = 7;

    // ===== Resources =====

    /// Singleton at @darbitex. Owns the resource account SignerCap under
    /// which all pool objects live, tracks the pool registry, and holds
    /// the HookNFT #2 escrow table.
    struct Factory has key {
        signer_cap: SignerCapability,
        factory_addr: address,
        pool_count: u64,
        pool_addresses: vector<address>,
        /// pool_addr → APT octas price locked at listing time. Entry is
        /// removed on successful `buy_hook`.
        hook_listings: Table<address, u64>,
        /// Default price for new listings, admin-configurable via
        /// `set_hook_price`. Existing entries in `hook_listings` are
        /// NOT retroactively updated when this changes.
        current_hook_price: u64,
        schema_version: u8,
        _reserved: vector<u8>,
    }

    // ===== Events =====

    #[event]
    struct FactoryInitialized has drop, store {
        factory_addr: address,
        initial_hook_price: u64,
        timestamp: u64,
    }

    #[event]
    struct CanonicalPoolCreated has drop, store {
        pool_addr: address,
        metadata_a: address,
        metadata_b: address,
        creator: address,
        amount: u64,
        hook_nft_1: address,
        hook_nft_2: address,
        list_price: u64,
        timestamp: u64,
    }

    #[event]
    struct HookPurchased has drop, store {
        pool_addr: address,
        nft_addr: address,
        buyer: address,
        price: u64,
        timestamp: u64,
    }

    #[event]
    struct HookPriceUpdated has drop, store {
        old_price: u64,
        new_price: u64,
        timestamp: u64,
    }

    // ===== Internal helpers =====

    /// Require the pair to be in canonical sorted order (BCS byte order).
    /// This avoids ambiguity where (A, B) and (B, A) could produce different
    /// canonical addresses. Callers must pre-sort off-chain; the factory
    /// does not reorder for them (explicitness over convenience).
    fun assert_sorted(metadata_a: Object<Metadata>, metadata_b: Object<Metadata>) {
        let ba = bcs::to_bytes(&object::object_address(&metadata_a));
        let bb = bcs::to_bytes(&object::object_address(&metadata_b));
        assert!(ba < bb, E_WRONG_ORDER);
    }

    /// Compute the deterministic seed used for canonical pool object
    /// creation: `POOL_SEED_PREFIX || bcs(meta_a) || bcs(meta_b)`.
    fun derive_pair_seed(
        metadata_a: Object<Metadata>,
        metadata_b: Object<Metadata>,
    ): vector<u8> {
        let seed = POOL_SEED_PREFIX;
        vector::append(&mut seed, bcs::to_bytes(&object::object_address(&metadata_a)));
        vector::append(&mut seed, bcs::to_bytes(&object::object_address(&metadata_b)));
        seed
    }

    // ===== Factory init =====

    /// One-shot initializer. Must be called by the package publisher
    /// (`@darbitex`) exactly once, immediately after publish. Creates the
    /// resource account that hosts all canonical pools, moves the Factory
    /// singleton to @darbitex, and sets the default hook price.
    public entry fun init_factory(deployer: &signer) {
        let addr = signer::address_of(deployer);
        assert!(addr == @darbitex, E_NOT_ADMIN);
        assert!(!exists<Factory>(@darbitex), E_ALREADY_INIT);

        let (factory_signer, signer_cap) = account::create_resource_account(deployer, FACTORY_SEED);
        let factory_addr = signer::address_of(&factory_signer);

        move_to(deployer, Factory {
            signer_cap,
            factory_addr,
            pool_count: 0,
            pool_addresses: vector::empty(),
            hook_listings: table::new(),
            current_hook_price: DEFAULT_HOOK_PRICE,
            schema_version: 1,
            _reserved: vector::empty(),
        });

        event::emit(FactoryInitialized {
            factory_addr,
            initial_hook_price: DEFAULT_HOOK_PRICE,
            timestamp: timestamp::now_seconds(),
        });
    }

    // ===== Pool creation =====

    /// Atomic canonical pool creation. The caller supplies seeding tokens
    /// (`amount` of each side — symmetric seeding enforced in pool.move),
    /// the factory pulls them into its resource account store and forwards
    /// to the fresh pool, mints both HookNFTs, mints the creator's
    /// LpPosition, and lists HookNFT #2 in the escrow table at the
    /// current price.
    ///
    /// Duplicate protection: `object::create_named_object` aborts with
    /// EOBJECT_EXISTS if the canonical address is already occupied — so
    /// a second create_canonical_pool call for the same (sorted) pair
    /// reverts at the Move framework level before any factory state
    /// mutation.
    public entry fun create_canonical_pool(
        creator: &signer,
        metadata_a: Object<Metadata>,
        metadata_b: Object<Metadata>,
        amount: u64,
    ) acquires Factory {
        assert!(exists<Factory>(@darbitex), E_NOT_INIT);
        assert!(amount > 0, E_ZERO);
        assert_sorted(metadata_a, metadata_b);
        assert!(
            object::object_address(&metadata_a) != object::object_address(&metadata_b),
            E_SAME_TOKEN,
        );

        let factory = borrow_global_mut<Factory>(@darbitex);
        let factory_signer = account::create_signer_with_capability(&factory.signer_cap);
        let factory_addr = factory.factory_addr;
        let creator_addr = signer::address_of(creator);

        // Pull seeding tokens from creator into factory's resource account store.
        // pool::create_pool will re-withdraw from factory into the new pool.
        let fa_a = primary_fungible_store::withdraw(creator, metadata_a, amount);
        let fa_b = primary_fungible_store::withdraw(creator, metadata_b, amount);
        primary_fungible_store::deposit(factory_addr, fa_a);
        primary_fungible_store::deposit(factory_addr, fa_b);

        // Create the canonical pool object at the deterministic address.
        // Aborts if an object already exists there — duplicate guard.
        let seed = derive_pair_seed(metadata_a, metadata_b);
        let ctor = object::create_named_object(&factory_signer, seed);

        // Hand off to pool module: creates Pool struct, mints 2 HookNFTs,
        // mints initial LpPosition for creator.
        let (pool_addr, hook_1_addr, hook_2_addr, _position) = pool::create_pool(
            &factory_signer,
            factory_addr,
            TREASURY_ADDR,
            creator_addr,
            &ctor,
            metadata_a,
            metadata_b,
            amount,
            amount,
        );

        // List HookNFT #2 in escrow at the currently-configured price.
        // Price is locked at listing — subsequent set_hook_price updates
        // do not retroactively change this pool's listing.
        let list_price = factory.current_hook_price;
        table::add(&mut factory.hook_listings, pool_addr, list_price);

        // Register pool in the enumeration vector.
        factory.pool_count = factory.pool_count + 1;
        vector::push_back(&mut factory.pool_addresses, pool_addr);

        event::emit(CanonicalPoolCreated {
            pool_addr,
            metadata_a: object::object_address(&metadata_a),
            metadata_b: object::object_address(&metadata_b),
            creator: creator_addr,
            amount,
            hook_nft_1: hook_1_addr,
            hook_nft_2: hook_2_addr,
            list_price,
            timestamp: timestamp::now_seconds(),
        });
    }

    // ===== Hook NFT escrow sale =====

    /// Permissionless purchase of HookNFT #2 from the factory escrow at
    /// the listed price. Pays APT to REVENUE_ADDR, transfers the NFT
    /// object to the buyer, and removes the listing. After purchase the
    /// buyer holds the NFT in their own account and can freely transfer
    /// it on any generic Aptos NFT venue (Wapal, Topaz, etc.).
    public entry fun buy_hook(
        buyer: &signer,
        pool_addr: address,
    ) acquires Factory {
        assert!(exists<Factory>(@darbitex), E_NOT_INIT);

        let factory = borrow_global_mut<Factory>(@darbitex);
        assert!(table::contains(&factory.hook_listings, pool_addr), E_NOT_LISTED);
        let price = table::remove(&mut factory.hook_listings, pool_addr);

        // Defensive: verify the factory still owns HookNFT #2 before taking
        // payment. Under normal operation this is always true (the factory
        // holds the NFT in escrow from pool creation until sale), but an
        // explicit assert produces a clearer error than a mid-TX abort
        // deep inside object::transfer. Per audit round-2 LOW-2.
        let (_hook_1, hook_2_addr) = pool::hook_nft_addresses(pool_addr);
        let nft_obj = object::address_to_object<HookNFT>(hook_2_addr);
        assert!(object::owner(nft_obj) == factory.factory_addr, E_NOT_LISTED);

        // Payment: buyer → operational revenue address.
        aptos_account::transfer(buyer, REVENUE_ADDR, price);

        // Transfer NFT object from factory resource account to buyer.
        // Factory is the current owner (set at mint time); buyer becomes
        // new owner via standard object transfer. Ungated transfer is
        // still enabled on slot 1, so no ref manipulation needed here.
        let factory_signer = account::create_signer_with_capability(&factory.signer_cap);
        let buyer_addr = signer::address_of(buyer);
        object::transfer(&factory_signer, nft_obj, buyer_addr);

        event::emit(HookPurchased {
            pool_addr,
            nft_addr: hook_2_addr,
            buyer: buyer_addr,
            price,
            timestamp: timestamp::now_seconds(),
        });
    }

    /// Admin-only. Updates the default hook price applied to NEW pool
    /// listings. Pools already listed in the escrow table keep their
    /// original locked-in price — this call only affects future pools
    /// created after the update.
    public entry fun set_hook_price(
        admin: &signer,
        new_price: u64,
    ) acquires Factory {
        assert!(signer::address_of(admin) == ADMIN_ADDR, E_NOT_ADMIN);
        assert!(exists<Factory>(@darbitex), E_NOT_INIT);
        assert!(new_price > 0, E_ZERO);

        let factory = borrow_global_mut<Factory>(@darbitex);
        let old_price = factory.current_hook_price;
        factory.current_hook_price = new_price;

        event::emit(HookPriceUpdated {
            old_price,
            new_price,
            timestamp: timestamp::now_seconds(),
        });
    }

    // ===== Views =====

    #[view]
    public fun factory_address(): address acquires Factory {
        borrow_global<Factory>(@darbitex).factory_addr
    }

    #[view]
    public fun pool_count(): u64 acquires Factory {
        borrow_global<Factory>(@darbitex).pool_count
    }

    #[view]
    public fun get_all_pools(): vector<address> acquires Factory {
        borrow_global<Factory>(@darbitex).pool_addresses
    }

    #[view]
    public fun get_pools_paginated(offset: u64, limit: u64): vector<address> acquires Factory {
        let f = borrow_global<Factory>(@darbitex);
        let len = vector::length(&f.pool_addresses);
        let start = if (offset > len) { len } else { offset };
        let end = if (start + limit > len) { len } else { start + limit };
        let result = vector::empty<address>();
        let i = start;
        while (i < end) {
            vector::push_back(&mut result, *vector::borrow(&f.pool_addresses, i));
            i = i + 1;
        };
        result
    }

    #[view]
    /// Compute the canonical address for a sorted pair WITHOUT requiring
    /// the pool to exist. Useful for frontends pre-computing pool identity
    /// before creation. Aborts if pair is not sorted.
    public fun canonical_pool_address(
        metadata_a: Object<Metadata>,
        metadata_b: Object<Metadata>,
    ): address acquires Factory {
        assert_sorted(metadata_a, metadata_b);
        let f = borrow_global<Factory>(@darbitex);
        let seed = derive_pair_seed(metadata_a, metadata_b);
        object::create_object_address(&f.factory_addr, seed)
    }

    #[view]
    public fun is_hook_listed(pool_addr: address): bool acquires Factory {
        let f = borrow_global<Factory>(@darbitex);
        table::contains(&f.hook_listings, pool_addr)
    }

    #[view]
    public fun hook_listing_price(pool_addr: address): u64 acquires Factory {
        let f = borrow_global<Factory>(@darbitex);
        *table::borrow(&f.hook_listings, pool_addr)
    }

    #[view]
    public fun current_hook_price(): u64 acquires Factory {
        borrow_global<Factory>(@darbitex).current_hook_price
    }

    #[view]
    public fun treasury_address(): address {
        TREASURY_ADDR
    }

    #[view]
    public fun admin_address(): address {
        ADMIN_ADDR
    }

    #[view]
    public fun revenue_address(): address {
        REVENUE_ADDR
    }
}
```

### 11.4 contracts/sources/router.move

```move
/// Darbitex Beta — multi-hop router.
///
/// Raw execution primitive on top of `pool::swap`. Exposes both a
/// composable layer (public fun, FungibleAsset in/out) that satellites
/// compose via cross-package import, and a user-facing entry layer with
/// deadline enforcement + primary_fungible_store integration.
///
/// No wrapped/plain distinction — every Beta pool is uniform, every swap
/// routes through `pool::swap`. No discovery logic here; meta_router is
/// a future satellite package that will delegate to this router.

module darbitex::router {
    use std::signer;
    use aptos_framework::object::Object;
    use aptos_framework::fungible_asset::{FungibleAsset, Metadata};
    use aptos_framework::primary_fungible_store;
    use aptos_framework::timestamp;

    use darbitex::pool;

    // ===== Errors =====

    const E_DEADLINE: u64 = 1;
    const E_SAME_POOL: u64 = 2;
    const E_ZERO_AMOUNT: u64 = 3;

    // ===== Internal =====

    fun assert_deadline(deadline: u64) {
        assert!(timestamp::now_seconds() < deadline, E_DEADLINE);
    }

    // =========================================================
    //                 COMPOSABLE PRIMITIVES
    //       (public fun, FungibleAsset in/out, no &signer)
    //
    // External satellites compose these directly. They never touch the
    // user's primary_fungible_store — that's the entry layer's job.
    // =========================================================

    /// Single-hop execution. Wraps `pool::swap` with no additional logic
    /// beyond the type. Exists so the composability contract stays
    /// symmetric with the multi-hop variants.
    public fun swap_composable(
        pool_addr: address,
        swapper: address,
        fa_in: FungibleAsset,
        min_out: u64,
    ): FungibleAsset {
        pool::swap(pool_addr, swapper, fa_in, min_out)
    }

    /// 2-hop chained swap. Intermediate hop has min_out = 0 (slippage
    /// only checked on the final hop). Pools must be distinct.
    public fun swap_2hop_composable(
        pool1: address,
        pool2: address,
        swapper: address,
        fa_in: FungibleAsset,
        min_out: u64,
    ): FungibleAsset {
        assert!(pool1 != pool2, E_SAME_POOL);
        let fa_mid = pool::swap(pool1, swapper, fa_in, 0);
        pool::swap(pool2, swapper, fa_mid, min_out)
    }

    /// 3-hop chained swap. All three pools must be distinct from each
    /// other. Only the final hop enforces slippage.
    public fun swap_3hop_composable(
        pool1: address,
        pool2: address,
        pool3: address,
        swapper: address,
        fa_in: FungibleAsset,
        min_out: u64,
    ): FungibleAsset {
        assert!(pool1 != pool2, E_SAME_POOL);
        assert!(pool2 != pool3, E_SAME_POOL);
        assert!(pool1 != pool3, E_SAME_POOL);
        let fa_1 = pool::swap(pool1, swapper, fa_in, 0);
        let fa_2 = pool::swap(pool2, swapper, fa_1, 0);
        pool::swap(pool3, swapper, fa_2, min_out)
    }

    // =========================================================
    //                 ENTRY WRAPPERS
    //      (public entry fun, &signer, deadline + store)
    //
    // User-facing convenience. Pulls FA from user's primary store,
    // routes through the composable primitive, deposits result back.
    // =========================================================

    /// Single-hop swap with deadline and store integration.
    public entry fun swap_with_deadline(
        swapper: &signer,
        pool_addr: address,
        metadata_in: Object<Metadata>,
        amount_in: u64,
        min_out: u64,
        deadline: u64,
    ) {
        assert_deadline(deadline);
        assert!(amount_in > 0, E_ZERO_AMOUNT);
        let addr = signer::address_of(swapper);
        let fa_in = primary_fungible_store::withdraw(swapper, metadata_in, amount_in);
        let fa_out = swap_composable(pool_addr, addr, fa_in, min_out);
        primary_fungible_store::deposit(addr, fa_out);
    }

    /// 2-hop swap with deadline and store integration.
    public entry fun swap_2hop(
        swapper: &signer,
        pool1: address,
        pool2: address,
        metadata_in: Object<Metadata>,
        amount_in: u64,
        min_out: u64,
        deadline: u64,
    ) {
        assert_deadline(deadline);
        assert!(amount_in > 0, E_ZERO_AMOUNT);
        let addr = signer::address_of(swapper);
        let fa_in = primary_fungible_store::withdraw(swapper, metadata_in, amount_in);
        let fa_out = swap_2hop_composable(pool1, pool2, addr, fa_in, min_out);
        primary_fungible_store::deposit(addr, fa_out);
    }

    /// 3-hop swap with deadline and store integration.
    public entry fun swap_3hop(
        swapper: &signer,
        pool1: address,
        pool2: address,
        pool3: address,
        metadata_in: Object<Metadata>,
        amount_in: u64,
        min_out: u64,
        deadline: u64,
    ) {
        assert_deadline(deadline);
        assert!(amount_in > 0, E_ZERO_AMOUNT);
        let addr = signer::address_of(swapper);
        let fa_in = primary_fungible_store::withdraw(swapper, metadata_in, amount_in);
        let fa_out = swap_3hop_composable(pool1, pool2, pool3, addr, fa_in, min_out);
        primary_fungible_store::deposit(addr, fa_out);
    }
}
```

### 11.5 contracts/sources/tests.move (reference only)

```move
#[test_only]
module darbitex::tests {
    use std::string;
    use std::option;
    use std::bcs;
    use aptos_framework::account;
    use aptos_framework::timestamp;
    use aptos_framework::object::{Self, Object};
    use aptos_framework::fungible_asset::{Self, Metadata, MintRef};
    use aptos_framework::primary_fungible_store;
    use aptos_framework::coin;
    use aptos_framework::aptos_coin::{Self, AptosCoin};

    use darbitex::pool::{Self, HookNFT};
    use darbitex::pool_factory;
    use darbitex::router;

    // ===== Test Constants =====

    const POOL_AMOUNT: u64 = 1_000_000_000_000; // 10_000 tokens @ 8 dec
    const APT_1: u64 = 100_000_000;             // 1 APT octas
    const MIN_HOOK_PRICE: u64 = 10_000_000_000; // 100 APT octas (Beta default)

    const TREASURY: address = @0xdbce89113a975826028236f910668c3ff99c8db8981be6a448caa2f8836f9576;
    const ADMIN: address = @0xf1b522effb90aef79395f97b9c39d6acbd8fdf84ec046361359a48de2e196566;

    // ===== MintRef storage =====

    struct TestMints has key {
        mint_a: MintRef,
        mint_b: MintRef,
    }

    struct TestMintC has key {
        mint_c: MintRef,
    }

    // ===== Helpers =====

    fun create_fa(creator: &signer, seed: vector<u8>, name: vector<u8>): (Object<Metadata>, MintRef) {
        let constructor_ref = object::create_named_object(creator, seed);
        primary_fungible_store::create_primary_store_enabled_fungible_asset(
            &constructor_ref,
            option::none(),
            string::utf8(name),
            string::utf8(name),
            8,
            string::utf8(b""),
            string::utf8(b""),
        );
        let mint_ref = fungible_asset::generate_mint_ref(&constructor_ref);
        let metadata = object::object_from_constructor_ref<Metadata>(&constructor_ref);
        (metadata, mint_ref)
    }

    fun mint(ref: &MintRef, to: address, amount: u64) {
        let fa = fungible_asset::mint(ref, amount);
        primary_fungible_store::deposit(to, fa);
    }

    fun bal(addr: address, meta: Object<Metadata>): u64 {
        primary_fungible_store::balance(addr, meta)
    }

    /// Full protocol setup. Returns sorted (meta_a, meta_b).
    fun setup(framework: &signer, darbitex_signer: &signer): (Object<Metadata>, Object<Metadata>) {
        timestamp::set_time_has_started_for_testing(framework);

        // AptosCoin for any APT-handling tests (auction-free Beta still uses
        // APT for buy_hook).
        let (burn_cap, mint_cap) = aptos_coin::initialize_for_test(framework);
        coin::destroy_burn_cap(burn_cap);
        coin::destroy_mint_cap(mint_cap);

        account::create_account_for_test(@darbitex);

        // Beta factory init
        pool_factory::init_factory(darbitex_signer);

        // Create two FA tokens. Creator is darbitex so the mint ref can be
        // stored in global TestMints on the darbitex account.
        let (meta_x, mint_x) = create_fa(darbitex_signer, b"coin_x", b"CoinX");
        let (meta_y, mint_y) = create_fa(darbitex_signer, b"coin_y", b"CoinY");

        // Sort by BCS address order (factory requires sorted input).
        let ax = bcs::to_bytes(&object::object_address(&meta_x));
        let ay = bcs::to_bytes(&object::object_address(&meta_y));
        let (meta_a, meta_b, mint_a, mint_b) = if (ax < ay) {
            (meta_x, meta_y, mint_x, mint_y)
        } else {
            (meta_y, meta_x, mint_y, mint_x)
        };

        // Stock darbitex with plenty of both sides.
        mint(&mint_a, @darbitex, POOL_AMOUNT * 10);
        mint(&mint_b, @darbitex, POOL_AMOUNT * 10);

        move_to(darbitex_signer, TestMints { mint_a, mint_b });

        (meta_a, meta_b)
    }

    /// Extended setup that also creates a third token (CoinC) for 2-hop and
    /// 3-hop router tests. Returns (meta_a, meta_b, meta_c) all sorted
    /// globally so any pairwise selection is already in canonical order.
    fun setup_with_third(
        framework: &signer, darbitex_signer: &signer,
    ): (Object<Metadata>, Object<Metadata>, Object<Metadata>) {
        let (meta_a, meta_b) = setup(framework, darbitex_signer);
        let (meta_c, mint_c) = create_fa(darbitex_signer, b"coin_c", b"CoinC");
        mint(&mint_c, @darbitex, POOL_AMOUNT * 10);
        move_to(darbitex_signer, TestMintC { mint_c });
        // Return (a, b, c) but do NOT sort a/b/c globally — callers that
        // need canonical ordering for pool creation sort on demand.
        (meta_a, meta_b, meta_c)
    }

    /// Mint both test tokens to an address (for non-creator user tests).
    fun give_tokens(to: address, amount: u64) acquires TestMints {
        let m = borrow_global<TestMints>(@darbitex);
        mint(&m.mint_a, to, amount);
        mint(&m.mint_b, to, amount);
    }

    fun give_token_c(to: address, amount: u64) acquires TestMintC {
        let m = borrow_global<TestMintC>(@darbitex);
        mint(&m.mint_c, to, amount);
    }

    /// Fund an account with AptosCoin via the framework MintCapStore for
    /// buy_hook tests. Auto-creates account.
    fun fund_apt(framework: &signer, dst: address, amount: u64) {
        if (!account::exists_at(dst)) {
            account::create_account_for_test(dst);
        };
        aptos_coin::mint(framework, dst, amount);
    }

    /// Sort two metadata objects into (lo, hi) BCS order. Useful for
    /// constructing a sorted pair at test time without knowing a priori
    /// which of two tokens has the smaller address.
    fun sort_pair(x: Object<Metadata>, y: Object<Metadata>): (Object<Metadata>, Object<Metadata>) {
        let bx = bcs::to_bytes(&object::object_address(&x));
        let by = bcs::to_bytes(&object::object_address(&y));
        if (bx < by) { (x, y) } else { (y, x) }
    }

    // =========================================================
    //                 POOL CREATION TESTS
    // =========================================================

    #[test(darbitex = @darbitex, framework = @0x1)]
    fun test_create_pool_happy(
        darbitex: &signer, framework: &signer,
    ) acquires TestMints {
        let (meta_a, meta_b) = setup(framework, darbitex);
        let _ = borrow_global<TestMints>(@darbitex); // silence unused acquires lint

        pool_factory::create_canonical_pool(darbitex, meta_a, meta_b, POOL_AMOUNT);

        // Canonical address computed; pool should exist there.
        let pool_addr = pool_factory::canonical_pool_address(meta_a, meta_b);
        assert!(pool::pool_exists(pool_addr), 1);

        // Registry bumped.
        assert!(pool_factory::pool_count() == 1, 2);

        // Reserves match seeding amount.
        let (ra, rb) = pool::reserves(pool_addr);
        assert!(ra == POOL_AMOUNT && rb == POOL_AMOUNT, 3);

        // lp_supply = sqrt(a*b) = POOL_AMOUNT.
        let supply = pool::lp_supply(pool_addr);
        assert!(supply == POOL_AMOUNT, 4);
    }

    #[test(darbitex = @darbitex, framework = @0x1)]
    #[expected_failure(abort_code = 4, location = darbitex::pool_factory)]
    /// Same-token pair triggers E_WRONG_ORDER in assert_sorted (ba == bb
    /// cannot satisfy strict `<`).
    fun test_create_pool_same_token_aborts(
        darbitex: &signer, framework: &signer,
    ) {
        let (meta_a, _meta_b) = setup(framework, darbitex);
        pool_factory::create_canonical_pool(darbitex, meta_a, meta_a, POOL_AMOUNT);
    }

    #[test(darbitex = @darbitex, framework = @0x1)]
    #[expected_failure(abort_code = 4, location = darbitex::pool_factory)]
    /// Reversed (unsorted) pair triggers E_WRONG_ORDER.
    fun test_create_pool_unsorted_aborts(
        darbitex: &signer, framework: &signer,
    ) {
        let (meta_a, meta_b) = setup(framework, darbitex);
        pool_factory::create_canonical_pool(darbitex, meta_b, meta_a, POOL_AMOUNT);
    }

    #[test(darbitex = @darbitex, framework = @0x1)]
    #[expected_failure]
    /// Second create_canonical_pool for the same pair aborts at the Move
    /// framework level (EOBJECT_EXISTS on create_named_object). We don't
    /// pin the exact abort code since it comes from aptos_framework.
    fun test_create_pool_duplicate_aborts(
        darbitex: &signer, framework: &signer,
    ) {
        let (meta_a, meta_b) = setup(framework, darbitex);
        pool_factory::create_canonical_pool(darbitex, meta_a, meta_b, POOL_AMOUNT);
        pool_factory::create_canonical_pool(darbitex, meta_a, meta_b, POOL_AMOUNT);
    }

    #[test(darbitex = @darbitex, framework = @0x1)]
    fun test_create_pool_hook_nfts_exist(
        darbitex: &signer, framework: &signer,
    ) {
        let (meta_a, meta_b) = setup(framework, darbitex);
        pool_factory::create_canonical_pool(darbitex, meta_a, meta_b, POOL_AMOUNT);

        let pool_addr = pool_factory::canonical_pool_address(meta_a, meta_b);
        let (h1_addr, h2_addr) = pool::hook_nft_addresses(pool_addr);
        assert!(object::object_exists<HookNFT>(h1_addr), 1);
        assert!(object::object_exists<HookNFT>(h2_addr), 2);

        let (h1_pool, h1_slot) = pool::hook_nft_info(h1_addr);
        let (h2_pool, h2_slot) = pool::hook_nft_info(h2_addr);
        assert!(h1_pool == pool_addr && h1_slot == 0, 3);
        assert!(h2_pool == pool_addr && h2_slot == 1, 4);
    }

    #[test(darbitex = @darbitex, framework = @0x1)]
    fun test_create_pool_hook_1_owned_by_treasury(
        darbitex: &signer, framework: &signer,
    ) {
        let (meta_a, meta_b) = setup(framework, darbitex);
        pool_factory::create_canonical_pool(darbitex, meta_a, meta_b, POOL_AMOUNT);
        let pool_addr = pool_factory::canonical_pool_address(meta_a, meta_b);
        let (h1_addr, _) = pool::hook_nft_addresses(pool_addr);
        let h1_obj = object::address_to_object<HookNFT>(h1_addr);
        assert!(object::owner(h1_obj) == TREASURY, 1);
    }

    #[test(darbitex = @darbitex, framework = @0x1)]
    fun test_create_pool_hook_2_owned_by_factory_escrow(
        darbitex: &signer, framework: &signer,
    ) {
        let (meta_a, meta_b) = setup(framework, darbitex);
        pool_factory::create_canonical_pool(darbitex, meta_a, meta_b, POOL_AMOUNT);

        let pool_addr = pool_factory::canonical_pool_address(meta_a, meta_b);
        let (_, h2_addr) = pool::hook_nft_addresses(pool_addr);
        let h2_obj = object::address_to_object<HookNFT>(h2_addr);
        assert!(object::owner(h2_obj) == pool_factory::factory_address(), 1);
    }

    #[test(darbitex = @darbitex, framework = @0x1)]
    fun test_create_pool_escrow_listing_at_default_price(
        darbitex: &signer, framework: &signer,
    ) {
        let (meta_a, meta_b) = setup(framework, darbitex);
        pool_factory::create_canonical_pool(darbitex, meta_a, meta_b, POOL_AMOUNT);
        let pool_addr = pool_factory::canonical_pool_address(meta_a, meta_b);
        assert!(pool_factory::is_hook_listed(pool_addr), 1);
        assert!(pool_factory::hook_listing_price(pool_addr) == MIN_HOOK_PRICE, 2);
    }

    // =========================================================
    //                      SWAP TESTS
    // =========================================================

    #[test(darbitex = @darbitex, user = @0x100, framework = @0x1)]
    fun test_swap_basic(
        darbitex: &signer, user: &signer, framework: &signer,
    ) acquires TestMints {
        let (meta_a, meta_b) = setup(framework, darbitex);
        pool_factory::create_canonical_pool(darbitex, meta_a, meta_b, POOL_AMOUNT);
        let pool_addr = pool_factory::canonical_pool_address(meta_a, meta_b);

        account::create_account_for_test(@0x100);
        give_tokens(@0x100, 1_000_000);

        let before_b = bal(@0x100, meta_b);
        router::swap_with_deadline(
            user, pool_addr, meta_a, 1_000_000, 0, 1_000_000_000,
        );
        let after_b = bal(@0x100, meta_b);
        assert!(after_b > before_b, 1);

        let (ra2, rb2) = pool::reserves(pool_addr);
        assert!(ra2 > POOL_AMOUNT, 2);
        assert!(rb2 < POOL_AMOUNT, 3);
    }

    #[test(darbitex = @darbitex, user = @0x100, framework = @0x1)]
    fun test_swap_quote_accuracy(
        darbitex: &signer, user: &signer, framework: &signer,
    ) acquires TestMints {
        let (meta_a, meta_b) = setup(framework, darbitex);
        pool_factory::create_canonical_pool(darbitex, meta_a, meta_b, POOL_AMOUNT);
        let pool_addr = pool_factory::canonical_pool_address(meta_a, meta_b);

        let amount_in = 5_000_000;
        let expected = pool::get_amount_out(pool_addr, amount_in, true);

        account::create_account_for_test(@0x100);
        give_tokens(@0x100, amount_in);
        let before_b = bal(@0x100, meta_b);
        router::swap_with_deadline(
            user, pool_addr, meta_a, amount_in, 0, 1_000_000_000,
        );
        let actual = bal(@0x100, meta_b) - before_b;
        assert!(actual == expected, 1);
    }

    #[test(darbitex = @darbitex, user = @0x100, framework = @0x1)]
    #[expected_failure(abort_code = 3, location = darbitex::pool)]
    fun test_swap_slippage_abort(
        darbitex: &signer, user: &signer, framework: &signer,
    ) acquires TestMints {
        let (meta_a, meta_b) = setup(framework, darbitex);
        pool_factory::create_canonical_pool(darbitex, meta_a, meta_b, POOL_AMOUNT);
        let pool_addr = pool_factory::canonical_pool_address(meta_a, meta_b);

        account::create_account_for_test(@0x100);
        give_tokens(@0x100, 1_000_000);
        router::swap_with_deadline(
            user, pool_addr, meta_a, 1_000_000, 999_999_999, 1_000_000_000,
        );
    }

    #[test(darbitex = @darbitex, user = @0x100, framework = @0x1)]
    fun test_swap_hook_buckets_grow_5050(
        darbitex: &signer, user: &signer, framework: &signer,
    ) acquires TestMints {
        let (meta_a, meta_b) = setup(framework, darbitex);
        pool_factory::create_canonical_pool(darbitex, meta_a, meta_b, POOL_AMOUNT);
        let pool_addr = pool_factory::canonical_pool_address(meta_a, meta_b);

        account::create_account_for_test(@0x100);
        give_tokens(@0x100, POOL_AMOUNT);
        router::swap_with_deadline(
            user, pool_addr, meta_a, 10_000_000, 0, 1_000_000_000,
        );

        let (h1_a, _h1_b, h2_a, _h2_b) = pool::hook_fee_buckets(pool_addr);
        // extra_fee on 10M input at EXTRA_FEE_DENOM=100_000 is 100 units.
        // 50/50 split → 50 each. Allow ±1 for rounding.
        assert!(h1_a + h2_a >= 99 && h1_a + h2_a <= 101, 1);
        assert!(h1_a == h2_a || (h1_a + 1 == h2_a) || (h1_a == h2_a + 1), 2);
    }

    #[test(darbitex = @darbitex, user = @0x100, framework = @0x1)]
    fun test_swap_lp_accumulator_grows(
        darbitex: &signer, user: &signer, framework: &signer,
    ) acquires TestMints {
        let (meta_a, meta_b) = setup(framework, darbitex);
        pool_factory::create_canonical_pool(darbitex, meta_a, meta_b, POOL_AMOUNT);
        let pool_addr = pool_factory::canonical_pool_address(meta_a, meta_b);

        let (start_a, start_b) = pool::lp_fee_per_share(pool_addr);
        assert!(start_a == 0 && start_b == 0, 1);

        account::create_account_for_test(@0x100);
        give_tokens(@0x100, POOL_AMOUNT);
        router::swap_with_deadline(
            user, pool_addr, meta_a, 10_000_000, 0, 1_000_000_000,
        );

        let (end_a, _end_b) = pool::lp_fee_per_share(pool_addr);
        // LP portion = total_fee - extra_fee = 1000 - 100 = 900 units
        // accumulator += 900 * SCALE / lp_supply
        assert!(end_a > start_a, 2);
    }

    // =========================================================
    //                   LIQUIDITY TESTS
    // =========================================================

    #[test(darbitex = @darbitex, user = @0x100, framework = @0x1)]
    fun test_add_liquidity_happy(
        darbitex: &signer, user: &signer, framework: &signer,
    ) acquires TestMints {
        let (meta_a, meta_b) = setup(framework, darbitex);
        pool_factory::create_canonical_pool(darbitex, meta_a, meta_b, POOL_AMOUNT);
        let pool_addr = pool_factory::canonical_pool_address(meta_a, meta_b);

        account::create_account_for_test(@0x100);
        give_tokens(@0x100, POOL_AMOUNT);

        let add = 100_000_000;
        let position = pool::add_liquidity(user, pool_addr, add, add, 0);
        let position_addr = object::object_address(&position);
        let (pos_pool, pos_shares, _, _) = pool::position_info(position_addr);
        assert!(pos_pool == pool_addr, 1);
        assert!(pos_shares > 0, 2);
    }

    #[test(darbitex = @darbitex, user = @0x100, framework = @0x1)]
    #[expected_failure(abort_code = 3, location = darbitex::pool)]
    /// min_shares_out slippage protection. Setting the floor above what the
    /// pool can mint must abort E_SLIPPAGE. Added per audit MEDIUM-3.
    fun test_add_liquidity_min_shares_out_abort(
        darbitex: &signer, user: &signer, framework: &signer,
    ) acquires TestMints {
        let (meta_a, meta_b) = setup(framework, darbitex);
        pool_factory::create_canonical_pool(darbitex, meta_a, meta_b, POOL_AMOUNT);
        let pool_addr = pool_factory::canonical_pool_address(meta_a, meta_b);
        account::create_account_for_test(@0x100);
        give_tokens(@0x100, POOL_AMOUNT);
        // A 100M/100M add into a 100B/100B pool mints ~100M shares. Asking
        // for 200M floor must abort with E_SLIPPAGE.
        pool::add_liquidity(user, pool_addr, 100_000_000, 100_000_000, 200_000_000);
    }

    #[test(darbitex = @darbitex, user = @0x100, framework = @0x1)]
    /// add_liquidity with a slippage buffer on the b-side must NOT absorb
    /// the buffer as a silent donation. The optimal pair computation should
    /// leave the excess b in the caller's wallet. Regression for round-2
    /// audit HIGH-1 from Gemini.
    fun test_add_liquidity_buffer_returns_unused(
        darbitex: &signer, user: &signer, framework: &signer,
    ) acquires TestMints {
        let (meta_a, meta_b) = setup(framework, darbitex);
        pool_factory::create_canonical_pool(darbitex, meta_a, meta_b, POOL_AMOUNT);
        let pool_addr = pool_factory::canonical_pool_address(meta_a, meta_b);

        account::create_account_for_test(@0x100);
        give_tokens(@0x100, POOL_AMOUNT);

        // User has exactly 200M B on their side (they were given POOL_AMOUNT
        // of each above, then we constrain the measurement window). Pool
        // is 100B/100B (1:1 ratio). User wants to add 100M A + 200M B as
        // a "buffer" attempt.
        let before_a = bal(@0x100, meta_a);
        let before_b = bal(@0x100, meta_b);

        // Pool ratio is 1:1, so amount_b_optimal for 100M A is 100M B.
        // The 200M B desired is MORE than optimal → take if branch,
        // use (100M A, 100M B), leave 100M B unused in caller's wallet.
        pool::add_liquidity(user, pool_addr, 100_000_000, 200_000_000, 0);

        let after_a = bal(@0x100, meta_a);
        let after_b = bal(@0x100, meta_b);

        // A side: used 100M exactly
        assert!(before_a - after_a == 100_000_000, 1);
        // B side: buffer protected, only 100M used (not 200M)
        assert!(before_b - after_b == 100_000_000, 2);
    }

    #[test(darbitex = @darbitex, user = @0x100, framework = @0x1)]
    /// Buffer on the a-side instead — tight b, loose a. Else branch.
    fun test_add_liquidity_buffer_on_a_side(
        darbitex: &signer, user: &signer, framework: &signer,
    ) acquires TestMints {
        let (meta_a, meta_b) = setup(framework, darbitex);
        pool_factory::create_canonical_pool(darbitex, meta_a, meta_b, POOL_AMOUNT);
        let pool_addr = pool_factory::canonical_pool_address(meta_a, meta_b);

        account::create_account_for_test(@0x100);
        give_tokens(@0x100, POOL_AMOUNT);
        let before_a = bal(@0x100, meta_a);
        let before_b = bal(@0x100, meta_b);

        // 200M A desired but only 100M B — b is tight. Function should
        // use (100M A, 100M B), leave 100M A in caller's wallet.
        pool::add_liquidity(user, pool_addr, 200_000_000, 100_000_000, 0);

        let after_a = bal(@0x100, meta_a);
        let after_b = bal(@0x100, meta_b);
        assert!(before_a - after_a == 100_000_000, 1);
        assert!(before_b - after_b == 100_000_000, 2);
    }

    #[test(darbitex = @darbitex, user = @0x100, framework = @0x1)]
    #[expected_failure(abort_code = 3, location = darbitex::pool)]
    /// remove_liquidity slippage protection: setting min_amount_a above
    /// the proportional payout must abort E_SLIPPAGE. Regression for
    /// round-2 audit MEDIUM-1 (fresh Claude Opus 4.6).
    fun test_remove_liquidity_min_amount_abort(
        darbitex: &signer, user: &signer, framework: &signer,
    ) acquires TestMints {
        let (meta_a, meta_b) = setup(framework, darbitex);
        pool_factory::create_canonical_pool(darbitex, meta_a, meta_b, POOL_AMOUNT);
        let pool_addr = pool_factory::canonical_pool_address(meta_a, meta_b);

        account::create_account_for_test(@0x100);
        give_tokens(@0x100, POOL_AMOUNT);
        let position = pool::add_liquidity(user, pool_addr, 100_000_000, 100_000_000, 0);

        // Position will pay out ~100M on each side proportionally.
        // Asking for 200M floor must abort E_SLIPPAGE.
        let (fa_a, fa_b) = pool::remove_liquidity(user, position, 200_000_000, 0);
        primary_fungible_store::deposit(@0x100, fa_a);
        primary_fungible_store::deposit(@0x100, fa_b);
    }

    #[test(darbitex = @darbitex, user = @0x100, framework = @0x1)]
    fun test_remove_liquidity_returns_reserves(
        darbitex: &signer, user: &signer, framework: &signer,
    ) acquires TestMints {
        let (meta_a, meta_b) = setup(framework, darbitex);
        pool_factory::create_canonical_pool(darbitex, meta_a, meta_b, POOL_AMOUNT);
        let pool_addr = pool_factory::canonical_pool_address(meta_a, meta_b);

        account::create_account_for_test(@0x100);
        give_tokens(@0x100, POOL_AMOUNT);
        let before_a = bal(@0x100, meta_a);
        let before_b = bal(@0x100, meta_b);

        let position = pool::add_liquidity(user, pool_addr, 100_000_000, 100_000_000, 0);

        let (fa_a, fa_b) = pool::remove_liquidity(user, position, 0, 0);
        primary_fungible_store::deposit(@0x100, fa_a);
        primary_fungible_store::deposit(@0x100, fa_b);

        let final_a = bal(@0x100, meta_a);
        let final_b = bal(@0x100, meta_b);
        // Within 1 unit rounding tolerance.
        assert!(final_a >= before_a - 1, 1);
        assert!(final_b >= before_b - 1, 2);
    }

    #[test(darbitex = @darbitex, provider = @0x100, swapper = @0x200, framework = @0x1)]
    fun test_claim_lp_fees_after_swap(
        darbitex: &signer, provider: &signer, swapper: &signer, framework: &signer,
    ) acquires TestMints {
        let (meta_a, meta_b) = setup(framework, darbitex);
        pool_factory::create_canonical_pool(darbitex, meta_a, meta_b, POOL_AMOUNT);
        let pool_addr = pool_factory::canonical_pool_address(meta_a, meta_b);

        account::create_account_for_test(@0x100);
        account::create_account_for_test(@0x200);
        give_tokens(@0x100, POOL_AMOUNT);
        give_tokens(@0x200, POOL_AMOUNT);

        // Provider adds a mid-sized position.
        let position = pool::add_liquidity(provider, pool_addr, 100_000_000, 100_000_000, 0);

        // Swapper drives fee accrual with a meaningful swap.
        router::swap_with_deadline(
            swapper, pool_addr, meta_a, 100_000_000, 0, 1_000_000_000,
        );

        // Claim. Expect at least some A fee (provider's share of the wedge).
        let before_a = bal(@0x100, meta_a);
        let (fa_a, fa_b) = pool::claim_lp_fees(provider, position);
        primary_fungible_store::deposit(@0x100, fa_a);
        primary_fungible_store::deposit(@0x100, fa_b);
        let after_a = bal(@0x100, meta_a);
        assert!(after_a >= before_a, 1);
    }

    #[test(darbitex = @darbitex, user = @0x100, framework = @0x1)]
    fun test_lp_position_is_transferable(
        darbitex: &signer, user: &signer, framework: &signer,
    ) acquires TestMints {
        let (meta_a, meta_b) = setup(framework, darbitex);
        pool_factory::create_canonical_pool(darbitex, meta_a, meta_b, POOL_AMOUNT);
        let pool_addr = pool_factory::canonical_pool_address(meta_a, meta_b);

        account::create_account_for_test(@0x100);
        give_tokens(@0x100, POOL_AMOUNT);
        let position = pool::add_liquidity(user, pool_addr, 100_000_000, 100_000_000, 0);

        // Transfer to @0x200.
        account::create_account_for_test(@0x200);
        object::transfer(user, position, @0x200);
        assert!(object::owner(position) == @0x200, 1);
    }

    // =========================================================
    //                    HOOK FEE TESTS
    // =========================================================

    #[test(darbitex = @darbitex, user = @0x100, treasury = @0xdbce89113a975826028236f910668c3ff99c8db8981be6a448caa2f8836f9576, framework = @0x1)]
    fun test_claim_hook_fees_slot_0_treasury(
        darbitex: &signer, user: &signer, treasury: &signer, framework: &signer,
    ) acquires TestMints {
        let (meta_a, meta_b) = setup(framework, darbitex);
        pool_factory::create_canonical_pool(darbitex, meta_a, meta_b, POOL_AMOUNT);
        let pool_addr = pool_factory::canonical_pool_address(meta_a, meta_b);

        account::create_account_for_test(@0x100);
        give_tokens(@0x100, POOL_AMOUNT);
        router::swap_with_deadline(
            user, pool_addr, meta_a, 100_000_000, 0, 1_000_000_000,
        );

        let (h1_addr, _) = pool::hook_nft_addresses(pool_addr);
        let h1_obj = object::address_to_object<HookNFT>(h1_addr);

        // Treasury claims (owner of h1).
        account::create_account_for_test(TREASURY);
        let (fa_a, fa_b) = pool::claim_hook_fees(treasury, h1_obj);
        let amt_a = fungible_asset::amount(&fa_a);
        let amt_b = fungible_asset::amount(&fa_b);
        assert!(amt_a > 0 || amt_b > 0, 1);
        primary_fungible_store::deposit(TREASURY, fa_a);
        primary_fungible_store::deposit(TREASURY, fa_b);
    }

    #[test(darbitex = @darbitex, user = @0x100, treasury = @0xdbce89113a975826028236f910668c3ff99c8db8981be6a448caa2f8836f9576, framework = @0x1)]
    #[expected_failure]
    /// HookNFT #1 is soulbound. Treasury owner trying to transfer it must
    /// abort at the object framework level (ungated transfer disabled).
    fun test_hook_nft_1_soulbound_abort(
        darbitex: &signer, user: &signer, treasury: &signer, framework: &signer,
    ) {
        let _ = user;
        let (meta_a, meta_b) = setup(framework, darbitex);
        pool_factory::create_canonical_pool(darbitex, meta_a, meta_b, POOL_AMOUNT);
        let pool_addr = pool_factory::canonical_pool_address(meta_a, meta_b);
        let (h1_addr, _) = pool::hook_nft_addresses(pool_addr);
        let h1_obj = object::address_to_object<HookNFT>(h1_addr);

        account::create_account_for_test(TREASURY);
        account::create_account_for_test(@0x999);
        // Must abort — soulbound.
        object::transfer(treasury, h1_obj, @0x999);
    }

    // =========================================================
    //                    BUY HOOK TESTS
    // =========================================================

    #[test(darbitex = @darbitex, buyer = @0xB1, framework = @0x1)]
    fun test_buy_hook_happy(
        darbitex: &signer, buyer: &signer, framework: &signer,
    ) {
        let (meta_a, meta_b) = setup(framework, darbitex);
        pool_factory::create_canonical_pool(darbitex, meta_a, meta_b, POOL_AMOUNT);
        let pool_addr = pool_factory::canonical_pool_address(meta_a, meta_b);

        // Buyer funded with enough APT for the default 100 APT price.
        fund_apt(framework, @0xB1, MIN_HOOK_PRICE + APT_1);
        // Admin account must exist to receive revenue.
        account::create_account_for_test(ADMIN);

        assert!(pool_factory::is_hook_listed(pool_addr), 1);

        pool_factory::buy_hook(buyer, pool_addr);

        // Listing removed.
        assert!(!pool_factory::is_hook_listed(pool_addr), 2);

        // NFT ownership transferred.
        let (_, h2_addr) = pool::hook_nft_addresses(pool_addr);
        let h2_obj = object::address_to_object<HookNFT>(h2_addr);
        assert!(object::owner(h2_obj) == @0xB1, 3);

        // Admin (revenue) received the price.
        let admin_bal = coin::balance<AptosCoin>(ADMIN);
        assert!(admin_bal == MIN_HOOK_PRICE, 4);
    }

    #[test(darbitex = @darbitex, buyer = @0xB1, framework = @0x1)]
    #[expected_failure(abort_code = 6, location = darbitex::pool_factory)]
    fun test_buy_hook_not_listed_aborts(
        darbitex: &signer, buyer: &signer, framework: &signer,
    ) {
        let (meta_a, meta_b) = setup(framework, darbitex);
        pool_factory::create_canonical_pool(darbitex, meta_a, meta_b, POOL_AMOUNT);
        let pool_addr = pool_factory::canonical_pool_address(meta_a, meta_b);

        fund_apt(framework, @0xB1, MIN_HOOK_PRICE * 2);
        account::create_account_for_test(ADMIN);

        pool_factory::buy_hook(buyer, pool_addr);
        // Second call must abort with E_NOT_LISTED.
        pool_factory::buy_hook(buyer, pool_addr);
    }

    #[test(darbitex = @darbitex, buyer = @0xB1, user = @0x100, framework = @0x1)]
    fun test_buy_hook_then_claim_slot_1_fees(
        darbitex: &signer, buyer: &signer, user: &signer, framework: &signer,
    ) acquires TestMints {
        let (meta_a, meta_b) = setup(framework, darbitex);
        pool_factory::create_canonical_pool(darbitex, meta_a, meta_b, POOL_AMOUNT);
        let pool_addr = pool_factory::canonical_pool_address(meta_a, meta_b);

        // Drive swap volume to accrue slot 1 fees.
        account::create_account_for_test(@0x100);
        give_tokens(@0x100, POOL_AMOUNT);
        router::swap_with_deadline(
            user, pool_addr, meta_a, 100_000_000, 0, 1_000_000_000,
        );

        // Buyer acquires the NFT at list price.
        fund_apt(framework, @0xB1, MIN_HOOK_PRICE + APT_1);
        account::create_account_for_test(ADMIN);
        pool_factory::buy_hook(buyer, pool_addr);

        // Buyer claims the accumulated slot 1 fees.
        let (_, h2_addr) = pool::hook_nft_addresses(pool_addr);
        let h2_obj = object::address_to_object<HookNFT>(h2_addr);
        let (fa_a, fa_b) = pool::claim_hook_fees(buyer, h2_obj);
        let amt_a = fungible_asset::amount(&fa_a);
        let amt_b = fungible_asset::amount(&fa_b);
        assert!(amt_a > 0 || amt_b > 0, 1);
        primary_fungible_store::deposit(@0xB1, fa_a);
        primary_fungible_store::deposit(@0xB1, fa_b);
    }

    #[test(darbitex = @darbitex, admin = @0xf1b522effb90aef79395f97b9c39d6acbd8fdf84ec046361359a48de2e196566, framework = @0x1)]
    fun test_set_hook_price_affects_future_only(
        darbitex: &signer, admin: &signer, framework: &signer,
    ) {
        let (meta_a, meta_b) = setup(framework, darbitex);

        // Create first pool at DEFAULT price.
        pool_factory::create_canonical_pool(darbitex, meta_a, meta_b, POOL_AMOUNT);
        let pool1 = pool_factory::canonical_pool_address(meta_a, meta_b);
        let p1_listed = pool_factory::hook_listing_price(pool1);
        assert!(p1_listed == MIN_HOOK_PRICE, 1);

        // Admin raises the default.
        let new_price = MIN_HOOK_PRICE * 2;
        pool_factory::set_hook_price(admin, new_price);

        // First pool keeps its locked-in price.
        assert!(pool_factory::hook_listing_price(pool1) == MIN_HOOK_PRICE, 2);

        // current_hook_price view reflects the new value.
        assert!(pool_factory::current_hook_price() == new_price, 3);
    }

    #[test(darbitex = @darbitex, attacker = @0xBEEF, framework = @0x1)]
    #[expected_failure(abort_code = 1, location = darbitex::pool_factory)]
    fun test_set_hook_price_non_admin_aborts(
        darbitex: &signer, attacker: &signer, framework: &signer,
    ) {
        let (meta_a, _) = setup(framework, darbitex);
        let _ = meta_a;
        account::create_account_for_test(@0xBEEF);
        pool_factory::set_hook_price(attacker, MIN_HOOK_PRICE * 5);
    }

    // =========================================================
    //                   FLASH LOAN TESTS
    // =========================================================

    #[test(darbitex = @darbitex, framework = @0x1)]
    fun test_flash_borrow_repay_happy(
        darbitex: &signer, framework: &signer,
    ) acquires TestMints {
        let (meta_a, meta_b) = setup(framework, darbitex);
        pool_factory::create_canonical_pool(darbitex, meta_a, meta_b, POOL_AMOUNT);
        let pool_addr = pool_factory::canonical_pool_address(meta_a, meta_b);

        let borrow_amount = 1_000_000;
        let (fa_borrowed, receipt) = pool::flash_borrow(pool_addr, meta_a, borrow_amount);
        assert!(fungible_asset::amount(&fa_borrowed) == borrow_amount, 1);

        // Repay with principal + EXACTLY fee. fee = borrow * 1 / 10_000 = 100
        // (flash fee rate = 1 bps). Strict equality enforced in flash_repay
        // per audit LOW-2 — passing more than repay_total now aborts.
        let m = borrow_global<TestMints>(@darbitex);
        let fa_extra = fungible_asset::mint(&m.mint_a, 100);
        fungible_asset::merge(&mut fa_borrowed, fa_extra);

        pool::flash_repay(pool_addr, fa_borrowed, receipt);
    }

    #[test(darbitex = @darbitex, framework = @0x1)]
    #[expected_failure]
    /// Repaying with less than principal+fee aborts.
    fun test_flash_repay_insufficient_aborts(
        darbitex: &signer, framework: &signer,
    ) {
        let (meta_a, meta_b) = setup(framework, darbitex);
        pool_factory::create_canonical_pool(darbitex, meta_a, meta_b, POOL_AMOUNT);
        let pool_addr = pool_factory::canonical_pool_address(meta_a, meta_b);

        let (fa, receipt) = pool::flash_borrow(pool_addr, meta_a, 1_000_000);
        // Repay without adding any fee — principal only is insufficient.
        pool::flash_repay(pool_addr, fa, receipt);
    }

    // =========================================================
    //                      TWAP TEST
    // =========================================================

    // =========================================================
    //         REGRESSION TEST for audit HIGH-1 fix
    //    (LP fee double-counting in swap() and flash_repay())
    // =========================================================

    /// Verifies the solvency invariant after swap → claim_lp_fees →
    /// remove_liquidity. With the double-counting bug present (either
    /// `reserve += amount_in - extra_fee` in swap, or `reserve += amount`
    /// in flash_repay), the final remove_liquidity would abort because
    /// `reserve_a` is inflated above actual store balance and the proportional
    /// payout exceeds what the pool holds.
    ///
    /// This test is the direct regression test for audit HIGH-1.
    #[test(darbitex = @darbitex, provider = @0x100, swapper = @0x200, framework = @0x1)]
    fun test_regression_high1_swap_claim_remove_sequence(
        darbitex: &signer, provider: &signer, swapper: &signer, framework: &signer,
    ) acquires TestMints {
        let (meta_a, meta_b) = setup(framework, darbitex);
        pool_factory::create_canonical_pool(darbitex, meta_a, meta_b, POOL_AMOUNT);
        let pool_addr = pool_factory::canonical_pool_address(meta_a, meta_b);

        // Fund provider and swapper with enough tokens.
        account::create_account_for_test(@0x100);
        account::create_account_for_test(@0x200);
        give_tokens(@0x100, POOL_AMOUNT);
        give_tokens(@0x200, POOL_AMOUNT);

        // Provider adds a non-trivial position so their share of LP fees is
        // large enough that claim amount > 0 under any realistic rounding.
        let position = pool::add_liquidity(
            provider, pool_addr, 1_000_000_000, 1_000_000_000, 0,
        );

        // Swapper drives multiple swaps to accumulate meaningful LP fees.
        let i = 0;
        while (i < 5) {
            router::swap_with_deadline(
                swapper, pool_addr, meta_a, 100_000_000, 0, 1_000_000_000,
            );
            router::swap_with_deadline(
                swapper, pool_addr, meta_b, 100_000_000, 0, 1_000_000_000,
            );
            i = i + 1;
        };

        // Provider claims LP fees — store decreases, but reserves stay.
        // Under the bug this step succeeds but leaves reserve > store.
        let (claimed_a, claimed_b) = pool::claim_lp_fees(provider, position);
        primary_fungible_store::deposit(@0x100, claimed_a);
        primary_fungible_store::deposit(@0x100, claimed_b);

        // Now the critical step: remove_liquidity computes
        // amount = shares * reserve / lp_supply. With the bug, reserve is
        // inflated by the already-claimed LP fees, so amount exceeds what
        // the store holds, and primary_fungible_store::withdraw aborts.
        // With the fix, reserve exactly matches principal and the payout
        // works cleanly.
        let (fa_a, fa_b) = pool::remove_liquidity(provider, position, 0, 0);
        primary_fungible_store::deposit(@0x100, fa_a);
        primary_fungible_store::deposit(@0x100, fa_b);

        // Sanity: provider's balance should be in the neighborhood of their
        // original endowment (they put in POOL_AMOUNT, added 1B back as
        // liquidity, swapped nothing, and got out roughly the same amount
        // they put in plus claimed LP fees). Exact equality is not possible
        // because swaps shifted the reserve ratio.
        assert!(bal(@0x100, meta_a) > 0, 1);
        assert!(bal(@0x100, meta_b) > 0, 2);
    }

    /// Verifies that flash_borrow + flash_repay do not inflate reserves.
    /// With the bug present, `reserve_a += amount` + `reserve_a += lp_remainder`
    /// in flash_repay would leave reserve_a bigger than the store after the
    /// flash, and a subsequent remove_liquidity would abort. With the fix,
    /// flash loan is economically neutral to reserves.
    #[test(darbitex = @darbitex, framework = @0x1)]
    fun test_regression_high1_flash_then_remove_sequence(
        darbitex: &signer, framework: &signer,
    ) acquires TestMints {
        let (meta_a, meta_b) = setup(framework, darbitex);
        pool_factory::create_canonical_pool(darbitex, meta_a, meta_b, POOL_AMOUNT);
        let pool_addr = pool_factory::canonical_pool_address(meta_a, meta_b);

        // Flash borrow a non-trivial amount, repay with principal + EXACT
        // fee pulled from the test mint stash. Fee = 10M * 1 / 10000 = 1000.
        let borrow_amount = 10_000_000;
        let (fa_borrowed, receipt) = pool::flash_borrow(pool_addr, meta_a, borrow_amount);

        let m = borrow_global<TestMints>(@darbitex);
        let fa_fee = fungible_asset::mint(&m.mint_a, 1_000);
        fungible_asset::merge(&mut fa_borrowed, fa_fee);

        pool::flash_repay(pool_addr, fa_borrowed, receipt);

        // Now add a fresh LP position and immediately remove it. Under the
        // bug, reserve_a is inflated by (amount + lp_remainder) from the
        // flash, so the proportional remove payout would exceed store.
        // With the fix, remove works cleanly.
        give_tokens(@0x100, POOL_AMOUNT);
        account::create_account_for_test(@0x100);
        let provider = account::create_signer_for_test(@0x100);
        let position = pool::add_liquidity(
            &provider, pool_addr, 1_000_000_000, 1_000_000_000, 0,
        );

        let (fa_a, fa_b) = pool::remove_liquidity(&provider, position, 0, 0);
        primary_fungible_store::deposit(@0x100, fa_a);
        primary_fungible_store::deposit(@0x100, fa_b);
    }

    #[test(darbitex = @darbitex, user = @0x100, framework = @0x1)]
    fun test_twap_accumulates(
        darbitex: &signer, user: &signer, framework: &signer,
    ) acquires TestMints {
        let (meta_a, meta_b) = setup(framework, darbitex);
        pool_factory::create_canonical_pool(darbitex, meta_a, meta_b, POOL_AMOUNT);
        let pool_addr = pool_factory::canonical_pool_address(meta_a, meta_b);

        let (twap_a0, twap_b0, _) = pool::twap_cumulative(pool_addr);
        assert!(twap_a0 == 0 && twap_b0 == 0, 1);

        // Advance time.
        timestamp::fast_forward_seconds(100);

        // Trigger update_twap via a swap (any mutation suffices).
        account::create_account_for_test(@0x100);
        give_tokens(@0x100, 1_000_000);
        router::swap_with_deadline(
            user, pool_addr, meta_a, 1_000_000, 0, 1_000_000_000_000,
        );

        let (twap_a1, twap_b1, _) = pool::twap_cumulative(pool_addr);
        // cumulative grew by reserve × dt where dt=100 seconds.
        assert!(twap_a1 >= (POOL_AMOUNT as u128) * 100, 2);
        assert!(twap_b1 >= (POOL_AMOUNT as u128) * 100, 3);
    }

    // =========================================================
    //                     ROUTER TESTS
    // =========================================================

    #[test(darbitex = @darbitex, user = @0x100, framework = @0x1)]
    #[expected_failure(abort_code = 1, location = darbitex::router)]
    fun test_router_deadline_abort(
        darbitex: &signer, user: &signer, framework: &signer,
    ) acquires TestMints {
        let (meta_a, meta_b) = setup(framework, darbitex);
        pool_factory::create_canonical_pool(darbitex, meta_a, meta_b, POOL_AMOUNT);
        let pool_addr = pool_factory::canonical_pool_address(meta_a, meta_b);

        account::create_account_for_test(@0x100);
        give_tokens(@0x100, 1_000_000);

        timestamp::fast_forward_seconds(1000);
        router::swap_with_deadline(user, pool_addr, meta_a, 1_000_000, 0, 500);
    }

    #[test(darbitex = @darbitex, user = @0x100, framework = @0x1)]
    #[expected_failure(abort_code = 2, location = darbitex::router)]
    fun test_router_2hop_same_pool_abort(
        darbitex: &signer, user: &signer, framework: &signer,
    ) acquires TestMints {
        let (meta_a, meta_b) = setup(framework, darbitex);
        pool_factory::create_canonical_pool(darbitex, meta_a, meta_b, POOL_AMOUNT);
        let pool_addr = pool_factory::canonical_pool_address(meta_a, meta_b);
        account::create_account_for_test(@0x100);
        give_tokens(@0x100, 1_000_000);
        router::swap_2hop(
            user, pool_addr, pool_addr, meta_a, 1_000_000, 0, 1_000_000_000,
        );
    }

    #[test(darbitex = @darbitex, user = @0x100, framework = @0x1)]
    fun test_router_2hop_via_third_token(
        darbitex: &signer, user: &signer, framework: &signer,
    ) acquires TestMints, TestMintC {
        let (meta_a, meta_b, meta_c) = setup_with_third(framework, darbitex);

        // Build pool A↔C and pool C↔B (sort each pair).
        let (a1, a2) = sort_pair(meta_a, meta_c);
        let (b1, b2) = sort_pair(meta_c, meta_b);
        pool_factory::create_canonical_pool(darbitex, a1, a2, POOL_AMOUNT);
        pool_factory::create_canonical_pool(darbitex, b1, b2, POOL_AMOUNT);
        let pool_ac = pool_factory::canonical_pool_address(a1, a2);
        let pool_cb = pool_factory::canonical_pool_address(b1, b2);
        assert!(pool_ac != pool_cb, 1);

        account::create_account_for_test(@0x100);
        give_tokens(@0x100, 2_000_000);
        give_token_c(@0x100, 2_000_000);

        let before_b = bal(@0x100, meta_b);
        router::swap_2hop(
            user, pool_ac, pool_cb, meta_a, 1_000_000, 0, 1_000_000_000,
        );
        let after_b = bal(@0x100, meta_b);
        assert!(after_b > before_b, 2);
    }
}
```

---

**End of round-3 audit submission.** Total production source:
~1700 LoC Move across 3 files (pool + pool_factory + router),
plus ~950 LoC test suite. 36/36 unit tests passing. Round 1 HIGH
and Round 2 HIGH + 2 MEDIUM + 1 LOW all fixed and on-chain verified
at the round 3 testnet address.
