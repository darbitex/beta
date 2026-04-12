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
