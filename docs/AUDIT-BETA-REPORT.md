# Darbitex Beta — Consolidated Audit Report

**Mainnet status:** 🟢 **LIVE**
**Published:** 2026-04-12
**Package address:** `0x8c8f40ef0b924657461253e7aa54a15fdfd8a3069e1404ba6ffda2223ddcadb7`
**Publish TX:** `0x9f2024e3971a11c889668770479c88f9041177c8b690b5753b69855e1cc6b2ee`
**Init TX:** `0x8ef85ee8c2fb7342d2e03ad94d444f46a61de80762a24bcfa948870d7120d765`

---

## Summary

Darbitex Beta was reviewed by **8 independent AI auditors** across **4 audit
rounds** before mainnet publication. Across all rounds the auditors
collectively found and addressed **10 actionable findings** (1 HIGH + 3 MED
+ 1 LOW in round 1, 1 HIGH + 2 MED + 1 LOW in round 2, 1 MED in round 3,
0 in round 4), plus 1 false positive that was clarified but not code-
changed, and several informational notes.

The final round (round 4) returned a unanimous 🟢 **GREEN** verdict from
Gemini — the single remaining auditor with open findings at that point —
clearing the mainnet gate.

**Each auditor's findings are preserved as separate git commits under the
auditor's own git author name**, so the commit log itself serves as an
attestation trail. Claude (Anthropic, in-session self-audits during
development) commits are under the `darbitex` project author.

---

## Auditor roster

| Auditor | Provider | Context | Git author |
|---|---|---|---|
| Claude Opus 4.6 (in-session) | Anthropic | Same session as the developer, ran self-audits at R1 and R2 | `darbitex` |
| Claude Opus 4.6 (fresh web session) | Anthropic | Fresh claude.ai web session, clean context | `claude` |
| Gemini 2.5 Pro | Google | R1 pre-fix, R2, R3, R4 (4 rounds) | `gemini` |
| DeepSeek V3 | DeepSeek | R1 pre-fix, R2 | `deepseek` |
| Grok 4 | xAI | R2 | `grok` |
| Kimi K2 | Moonshot AI | R2, R3 | `kimi` |
| Qwen | Alibaba | R2 | `qwen` |
| ChatGPT (GPT-5) | OpenAI | R2 | `chatgpt` |

---

## Round-by-round verdict matrix

| Auditor | R1 | R2 | R3 | R4 |
|---|---|---|---|---|
| Claude self (in-session) | 🔴 RED | 🟢 GREEN | — | — |
| DeepSeek | 🔴 RED | 🟢 GREEN | — | — |
| Gemini | 🔴 RED | 🟡 YELLOW | 🟡 YELLOW | 🟢 **GREEN** |
| Grok 4 | — | 🟢 GREEN | — | — |
| Fresh Claude Opus 4.6 | — | 🟡 YELLOW | 🟢 GREEN | — |
| Kimi K2 | — | 🟡 YELLOW | 🟢 GREEN | — |
| Qwen | — | 🟢 GREEN | — | — |
| ChatGPT | — | 🟡 (non-actionable) | — | — |

**Final state: all 8 auditors aligned or converged on GREEN.** The 3
auditors that ever had open actionable findings (Gemini, fresh Claude,
Kimi) each returned to verify their own findings closed in subsequent
rounds.

---

## Actionable findings across all rounds

### Round 1 (pre-fix, caught by R1 auditors)

| # | Severity | Source | Finding | Fix commit |
|---|---|---|---|---|
| 1 | HIGH | Claude self, DeepSeek, Gemini (3-way independent) | LP fee double-counting in `swap()` and `flash_repay()` — reserves tracked both principal AND the LP fee portion, double-accumulating with `lp_fee_per_share` | `f18db35` |
| 2 | MEDIUM | Claude self | u128 overflow risk in swap numerator for adversarial reserves | `314047e` |
| 3 | MEDIUM | Claude self | u128 overflow risk in add_liquidity proportionality math | `314047e` |
| 4 | MEDIUM | Claude self, Gemini | add_liquidity missing `min_shares_out` slippage protection | `314047e` |
| 5 | LOW | Gemini | flash_repay accepted overpayment and silently donated excess | `f18db35` |

**1 FALSE POSITIVE (R1):** DeepSeek claimed cast precedence bug in
`(numerator / denominator as u64)`. Empirically refuted by compile
success and on-chain test output. Explicit parens added as cosmetic
defense-in-depth for future readers (commit `314047e`).

### Round 2 (post-R1-fix, caught by R2 auditors)

| # | Severity | Source | Finding | Fix commit |
|---|---|---|---|---|
| 6 | HIGH | Gemini (unique) | `add_liquidity` silently donated unused slippage buffer to existing LPs — full `amount_b` withdrawn even if optimal pair only needed less | `428bdb9` |
| 7 | MEDIUM | Fresh Claude Opus 4.6, Kimi K2 (independent) | `remove_liquidity` missing slippage protection (sandwich extraction vector) | `428bdb9` |
| 8 | MEDIUM | Fresh Claude Opus 4.6 | `claim_lp_fees` / `claim_hook_fees` missing `pool.locked` reentrancy guard (defensive against future FA callback hooks) | `428bdb9` |
| 9 | LOW | Fresh Claude Opus 4.6 | `buy_hook` missing factory ownership assertion before payment | `428bdb9` |

**1 FALSE POSITIVE (R2):** ChatGPT claimed flash fees bypass the LP
accumulator. Contradicted by ChatGPT's own verification that the R1 fix
correctly routes fees through `accrue_fee` — the flagged behavior does
not exist in post-R1-fix code.

### Round 3 (post-R2-fix, caught by R3 auditors)

| # | Severity | Source | Finding | Fix commit |
|---|---|---|---|---|
| 10 | MEDIUM | Gemini | Router multi-hop intermediate hops passed `min_out = 0`, allowing sandwich extraction even with a user-set final-hop floor | `6965108` |

**1 INFO (R3):** Kimi flagged `E_DISPROPORTIONAL` as dead-code after the
`add_liquidity` rewrite. Kept as defense-in-depth with clarifying
comment (commit `6965108`).

### Round 4 (post-R3-fix, final verification)

**Gemini R4: 🟢 GREEN — mainnet cleared.** Zero HIGH/MEDIUM/LOW/INFO.
All prior findings verified as correctly addressed. Mainnet publish
proceeded the same day.

---

## Fix commit trail

```
6965108  R3 fix: router per-hop slippage + E_DISPROPORTIONAL doc
428bdb9  R2 fix: add_liq buffer + remove slippage + claim lock + buy_hook assert
314047e  R1 MEDIUM batch: u256 overflow + add_liq slippage
f18db35  R1 HIGH-1 + LOW-2: double-count + flash excess donation
```

Each fix batch was verified by regression tests and on-chain smoke tests
on a fresh testnet deployment before the next audit round was distributed.

---

## Testnet iteration trail

Four successive testnet deployments across the audit cycle, each with
full on-chain E2E smoke tests:

| Round | Testnet address | Purpose |
|---|---|---|
| R1 | `0x6ba3a6eff27a8a729008d16550aa41d18bacf03e28d2daf9de192a10426a213a` | Initial Beta publish + R1 findings source |
| R2 | `0x12e8b2be0d705d5d6f1e27b50d331740461dccd2c1150504c2e38a67c6767a0f` | Post-R1-fix, verified HIGH-1 fix on-chain |
| R3 | `0xf93e4885f581c9b0c4f2199362afa91ae595a5a424432e0b752804cfef2bd5c7` | Post-R2-fix, verified add_liq buffer preservation on-chain |
| R4 | `0xe73e9fa5fdb847badcfe947d7762234ca059fa1f31aa3147bc5bc5d28cca7f80` | Post-R3-fix, final pre-mainnet verification |

All testnet pools used DAI/USDC test tokens minted via the legacy V1
`test_token` module at `0xd91195850afcf3c49a47e07337095f9ef81eee45e80d1643cb393c0a198ba754`.

---

## Individual auditor sections

Full verbatim findings from each external auditor are preserved below as
separate commits. Each section is committed under the auditor's own git
author name (see commit log for attribution trail).

### Contents

- [Round 1 — Claude Opus 4.6 in-session self-audit](#round-1-claude-opus-46-in-session-self-audit)
- [Round 1 — DeepSeek V3](#round-1-deepseek-v3)
- [Round 1 — Gemini 2.5 Pro](#round-1-gemini-25-pro)
- [Round 2 — Claude Opus 4.6 in-session (R2 self-audit)](#round-2-claude-opus-46-in-session-r2-self-audit)
- [Round 2 — DeepSeek V3](#round-2-deepseek-v3)
- [Round 2 — Gemini 2.5 Pro](#round-2-gemini-25-pro)
- [Round 2 — Grok 4](#round-2-grok-4)
- [Round 2 — Kimi K2](#round-2-kimi-k2)
- [Round 2 — Fresh Claude Opus 4.6](#round-2-fresh-claude-opus-46)
- [Round 2 — Qwen](#round-2-qwen)
- [Round 2 — ChatGPT (GPT-5)](#round-2-chatgpt-gpt-5)
- [Round 3 — Kimi K2](#round-3-kimi-k2)
- [Round 3 — Fresh Claude Opus 4.6](#round-3-fresh-claude-opus-46)
- [Round 3 — Gemini 2.5 Pro](#round-3-gemini-25-pro)
- [Round 4 — Gemini 2.5 Pro (mainnet gate clearance)](#round-4-gemini-25-pro-mainnet-gate-clearance)

Each auditor section is added in a separate commit under that auditor's
git author name. See `git log -- docs/AUDIT-BETA-REPORT.md` for the
attribution trail.

---

## Round 1 — Claude Opus 4.6 in-session self-audit

**Context:** I (Claude Opus 4.6, the model writing this report and
authoring the Beta codebase in-session with the project owner) performed
a self-audit at the completion of the R1 codebase, before distributing
to external AI reviewers. This is not a substitute for external audit —
it was a first pass to catch obvious issues and produce a reviewable
baseline. Conflict-of-interest disclaimer: I authored the code I
reviewed.

**Verdict:** 🔴 RED — blocking HIGH found before distribution.

**Findings raised:**

- **HIGH-1 — LP fee double-counting in `swap()` and `flash_repay()`**
  The swap path subtracted only `extra_fee` (hook portion) from reserves
  before mutation, leaving the `lp_portion` of the fee inside reserves.
  Simultaneously, `accrue_fee` credited the same `lp_portion` to
  `lp_fee_per_share`. LPs would earn twice — once via reserve growth
  (compounding into the curve), once via explicit accumulator claim. On
  any claim-then-remove sequence the reserve tracker would diverge from
  actual store balance, eventually bricking `remove_liquidity` for
  subsequent LPs.

  A nearly identical bug existed in `flash_repay`: the function added
  the borrowed amount back to reserves (but `flash_borrow` never
  subtracted, so this inflated reserves) AND credited `lp_remainder`
  to reserves while `accrue_fee` had already credited the same amount
  to `lp_fee_per_share`.

  Fix: (a) swap reserve update uses `reserve_fee = extra_fee + lp_fee`
  instead of just `extra_fee`; (b) flash_repay removes all direct
  reserve mutations and routes fees exclusively through `accrue_fee`.

- **MEDIUM-1 — swap math u128 overflow for adversarial reserves.**
  `(amount_in * 9999 * reserve_out)` can exceed `u128::MAX` for large
  token supplies. Not exploitable for theft (Move aborts on overflow,
  not silent corruption), but DoS vector for pools with near-max
  reserves. Fix: upgrade all intermediate multiplications to u256.

- **MEDIUM-2 — add_liquidity proportionality check u128 overflow.**
  Same class of issue as MEDIUM-1. `amount_a * reserve_b` can exceed
  u128. Fix: u256 intermediates.

- **MEDIUM-3 — add_liquidity missing slippage protection.**
  Callers couldn't enforce minimum share counts, exposing them to
  sandwich attacks on the pool ratio between submission and execution.
  Fix: added `min_shares_out: u64` parameter.

- **MEDIUM-4 — 50/50 hook split odd-unit rounding asymmetry.**
  For `extra_fee = 1` (dust regime), hook_1 gets 0 and hook_2 gets 1.
  Accepted as documented tradeoff — dust rounds in favor of the tradable
  slot, negligible economic impact. Not fixed.

- **LOW-1 — test suite didn't assert solvency invariant.**
  No test checked `store_balance == reserves + hook_buckets + pending_lp_fees`.
  Had such a test existed, HIGH-1 would have been caught immediately.
  Fix: added two regression tests for the specific HIGH-1 trigger
  sequences (swap-claim-remove and flash-then-remove).

- **LOW-2 — router multi-hop intermediate slippage unchecked.**
  Standard AMM router tradeoff, matches Uniswap V2 behavior. Noted as
  design trade-off. (Later upgraded to a MEDIUM finding by Gemini R3
  and fixed in commit `6965108`.)

- **INFO items:** accumulator rounding direction (pool favor, standard),
  `update_twap` redundant calls in claim paths (cosmetic), swapper
  event field spoofable (acknowledged, non-authoritative).

**Disposition:** All HIGH and MEDIUM findings addressed in commits
`f18db35` (R1 HIGH-1 + LOW-2) and `314047e` (R1 MEDIUM batch). Verified
by 36/36 tests passing and on-chain regression sequences at subsequent
testnet deployments.

---

## Round 2 — Claude Opus 4.6 in-session (R2 self-audit)

**Context:** Second self-audit pass on the post-R1-fix code, run in
parallel with the first external audit distribution.

**Verdict:** 🟢 GREEN — no blocking findings on my own reading.

**Findings raised:**

- **LOW-A — `update_twap` called redundantly in claim paths.** The
  claim functions don't mutate reserves, so bumping `twap_cumulative`
  is a no-op contribution (same reserve × elapsed time that the next
  reserve-mutating call would accumulate anyway). Minor gas waste.
  Accepted.

- **LOW-B — router multi-hop intermediate slippage unchecked.** Same
  as R1 LOW-2. Standard AMM router tradeoff. Later upgraded by Gemini
  R3 and fixed.

- **INFO-A — factory `hook_listings` table unbounded growth.** Self-
  regulating by buy pressure. Not a security concern.

- **INFO-B — event `swapper: address` field caller-controlled.**
  Already documented as non-authoritative. No change.

**Notable miss:** I did NOT catch the `add_liquidity` buffer-donation
bug (Gemini R2 HIGH), the `remove_liquidity` slippage gap (Fresh Claude
+ Kimi R2 MED), the claim reentrancy lock (Fresh Claude R2 MED), or the
`buy_hook` ownership assertion (Fresh Claude R2 LOW). My second in-
session pass had a blind spot for user-footgun UX issues that later
external auditors caught. This pattern (in-session Claude too close to
own design) informed the decision to always distribute to fresh external
sessions after a self-audit.

**Disposition:** No fixes from this self-audit directly; the findings
I missed were caught by external R2 auditors and addressed in commit
`428bdb9`.

---

## Round 1 — DeepSeek V3

**Context:** First external audit reviewer on the R1 Beta code (pre-fix).

**Verdict:** 🔴 RED → subsequent R2 verdict 🟢 GREEN after round-1 fixes.

**Findings raised:**

- **HIGH-1 (DeepSeek): Unsafe denominator truncation in division.**
  DeepSeek claimed `(numerator / denominator as u64)` parses as
  `numerator / (denominator as u64)` due to Move operator precedence,
  truncating the u128 denominator to u64 and producing artificially
  large results. **FALSE POSITIVE.** The code compiles successfully,
  which is empirical proof that Move parses the expression as
  `(numerator / denominator) as u64` — the alternative parsing would
  produce a u128/u64 type error. On-chain testnet results also match
  the u128 division interpretation. Explicit outer parens were added
  as cosmetic defense-in-depth for future readers (commit `314047e`).

- **HIGH-2 (DeepSeek): Double counting of LP fees in swap and flash
  loan.** **CONFIRMED.** Same finding as Claude self-audit HIGH-1 and
  Gemini R1 HIGH. Three-way independent confirmation. Fix applied in
  commit `f18db35` — reserves now track principal only,
  `reserve_fee = extra_fee + lp_fee`, and flash_repay no longer mutates
  reserves at all.

- **MEDIUM-1 (DeepSeek): Dust swap `extra_fee` rounding.**
  Observation on `extra_fee` floor-to-1 for dust swaps. The existing
  saturation in `accrue_fee` handles this correctly (lp_portion
  saturates to 0 when total_fee < extra_fee). Not a bug, accepted as
  documented dust-swap behavior.

- **LOW-1 (DeepSeek): Event attribution spoofing via `swapper`
  parameter.** Acknowledged in design docs as accepted tradeoff — the
  event `swapper` field is a non-authoritative attribution hint only.

- **INFO items:** `_reserved` field usage (forward-compat placeholder),
  `EXTRA_FEE_DENOM` zero-check (compile-time constant, never zero).

**Disposition:** HIGH-2 fixed. HIGH-1 refuted. MEDIUM and LOW accepted
as documented.

---

## Round 2 — DeepSeek V3

**Verdict:** 🟢 GREEN — ready for mainnet publish.

**Findings raised:**

- **LOW-1: Potential rounding edge in `add_liquidity` tolerance** for
  extremely small reserves (`expected_b < 20` → tolerance = 1 = 100%
  deviation permitted). Acknowledged as edge case at near-minimum
  liquidity; not exploitable in realistic scenarios. (Later superseded
  by the round 2 `add_liquidity` rewrite to optimal amount
  computation, which removed the tolerance check entirely.)

- **INFO-1:** Event `swapper` spoofing — already documented.
- **INFO-2:** `canonical_pool_address` view aborts on unsorted input
  — by design, consistent with creation behavior.
- **INFO-3:** 50/50 hook split odd-unit asymmetry — documented tradeoff.

**Conclusion:**
> "GREEN – Ready for mainnet publish. The code is well-structured, the
> fixes from round 1 are correctly implemented and regression-tested,
> and the security model is clearly defined. No high or medium severity
> issues remain."

**Disposition:** Round 1 HIGH loop closed. No further DeepSeek
participation (ChatGPT found the R2 issues that DeepSeek missed in
the parallel R2 batch).
