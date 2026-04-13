# Darbitex Beta — Version history

Tracks every source version of the Beta core package (`darbitex-beta/contracts`). Each entry names the version, its git tag, the on-chain status, and a short changelog.

## v0.2.0 — STAGED (not published)

- **Git tag:** none yet — tag applied at actual multisig publish time
- **Mainnet status:** NOT DEPLOYED. Source lives on `main`; mainnet package still runs v0.1.0.
- **Rationale for staging without publishing:** R9 post-mainnet audit cycle surfaced 0 critical/high findings. All fixes are defense-in-depth (Aptos FA has no callback hooks today, so reentrancy brackets are hypothetical), additive (new `_v2` entry wrappers — v1 still works), doc-only (TWAP semantic clarification), or source cleanup. No live exploit on v0.1.0. Upgrade deferred until there is a material reason to spend a multisig round (e.g., a bundle with a new feature, or a genuine live bug).

### Changes in v0.2.0

**Defense-in-depth:**
- Lock bracket added to `pool::add_liquidity` (Qwen L-1).
- Lock bracket added to `pool::remove_liquidity` (fresh Claude M-3).
- `pool::claim_hook_fees` now asserts `slot == 0 || slot == 1` via the new `E_INVALID_HOOK_SLOT` error code (DeepSeek L-02).
- `pool::flash_borrow` fee math moved to u256 intermediates for consistency with the swap path (in-session L-1).
- `pool::add_liquidity` optimal-amount u256 → u64 cast now guarded by an explicit `E_INSUFFICIENT_LIQUIDITY` assert for pathologically skewed pools; opaque arithmetic abort replaced with a descriptive error (in-session L-2).

**Additive (compat-safe):**
- Four new `_v2` entry wrappers with `deadline: u64` parameter: `add_liquidity_entry_v2`, `remove_liquidity_entry_v2`, `claim_lp_fees_entry_v2`, `claim_hook_fees_entry_v2` (Kimi M-1 + in-session extension). v1 entries kept, now doc-marked deprecated.
- New error code `E_DEADLINE = 16`.
- Renamed `E_RESERVED_9 = 9` → `E_INVALID_HOOK_SLOT = 9` (DeepSeek I-03 cleanup).

**Documentation:**
- Pool TWAP fields commented as "liquidity-depth cumulative, not price oracle" with u128 overflow ceiling rationale (fresh Claude M-2 + Gemini L-1). No field layout change.
- `update_twap` function doc updated to match.
- `twap_cumulative` view function doc updated with integrator warning.

**Tests (+4, 36 → 40):**
- `test_regression_r9_dust_swap_solvency` — drives 100 amount_in=1 swaps and asserts `store >= reserve + hook_1 + hook_2` post-storm. Proves fresh-Claude M-1 is a false positive.
- `test_regression_r9_add_liquidity_locked_during_flash` — expects `E_LOCKED` when add_liquidity is called with an outstanding flash borrow.
- `test_regression_r9_remove_liquidity_locked_during_flash` — same, for remove_liquidity.
- `test_regression_r9_add_liquidity_pathological_cast_abort` — expects `E_INSUFFICIENT_LIQUIDITY` when the u256 optimal-amount intermediate exceeds u64::MAX on a 5e9:1 ratio pool.

**Known deferrals (not in v0.2.0):**
- Rebuttal section in `docs/AUDIT-BETA-POSTMAINNET.md` documenting the 4 false positives (fresh Claude M-1, ChatGPT H-1, ChatGPT H-2, Grok L-3). Not blocking; can be added any time.
- Multisig compat upgrade to mainnet — deferred until there is a material reason.
- Mainnet smoke test — deferred until the upgrade actually ships.

## v0.1.0 — LIVE on Aptos mainnet

- **Git tag:** `v0.1.0` (retroactive, applied 2026-04-13 at commit `26493354fa4f22528a81ad73b7f015900a678163`)
- **Published:** 2026-04-12
- **Package address:** `0x2656e373ace5ccbc191aedaa65f12a50b9d4ea2b8e6f2d0166741994449c7ec2`
- **Publish TX:** `0x9f2024e3971a11c889668770479c88f9041177c8b690b5753b69855e1cc6b2ee`
- **Init TX:** `0x8ef85ee8c2fb7342d2e03ad94d444f46a61de80762a24bcfa948870d7120d765`
- **Publisher multisig:** 3/5 at `0x2656e373...`
- **Audit history:** 5 pre-mainnet rounds (Claude in-session, fresh Claude web, Gemini 2.5 Pro, DeepSeek, Grok 4, Kimi K2, Qwen, ChatGPT) + symmetric-seeding removal delta round, all cleared GREEN. See `docs/AUDIT-BETA-REPORT.md`.
- **Post-mainnet audit:** 8 auditors (fresh Claude, Kimi, Grok, in-session Claude, Gemini, ChatGPT, Qwen, DeepSeek) — 0 HIGH, findings batched into v0.2.0 staged next release. See `docs/AUDIT-BETA-POSTMAINNET.md`.
- **Changes from V1 Alpha:** fresh package publish, clean-slate design (immutable pools, hook-at-birth via two NFTs, LP-as-NFT with MasterChef-style accumulator, flash loan at pool level, escrow-based fixed-price hook sale, no auction module, no admin surface at pool level). See `docs/AUDIT-BETA-REPORT.md` for the full design rationale.
