# Walrus Quilt Registry — Darbitex Frontend

Source of truth for which Walrus blobs (quilts) back the live Darbitex site.
Cross-check this file against on-chain state before any deploy, extend, share,
or burn operation.

> **⚠ IMPORTANT — read before funding anything.** `site-builder update` may
> repack resources into new quilts on any deploy, orphaning the previously
> referenced quilts. WAL funded into an orphaned `SharedBlob` pool is
> **permanently locked** — verified by reading
> `contracts/walrus/sources/system/shared_blob.move` (MystenLabs/walrus main):
> the module has no `destroy`/`withdraw`/`refund`/`take_funds` function, the
> `SharedBlob` is `share_object`'d at creation and never consumable by-value,
> and `extend` is a closed loop that cannot release funds to a caller. Even
> waiting for the underlying `Blob` lease to expire does not unlock anything —
> the `SharedBlob` becomes a permanent tombstone object with `Balance<WAL>`
> addressable via view but immovable. Recovery would require an upstream
> Walrus package upgrade adding a drain function. This means:
> - **Max-lease funding is only economical for quilts you commit not to
>   redeploy.** For an actively iterating frontend, each deploy can burn the
>   pool of the previous quilts — permanently, with no refund path.
> - **Extend cycles are load-bearing, not hygiene.** If a funded shared blob
>   misses enough `extend --shared` cron cycles that the underlying `Blob`
>   fully expires, every remaining WAL in the pool is burned at that moment
>   (extend on expired blob aborts). This is true even for quilts still
>   actively referenced by the live site.
> - **Public funding is currently PAUSED** (see "Public funding & extension"
>   below). Do not advertise donation flows until we have either a frozen
>   archival site object or verified quilt-reuse behavior across deploys.
> - **Default deploy lease is now short** (see Deploy checklist) to limit the
>   blast radius of any single deploy.
> - **Always run `site-builder update --dry-run ...` first** to see which
>   existing quilts would be reused vs created anew before paying FROST.

## Live site

- **Site Object ID:** `0x050df98fbc08b6c4e5d8d41dc75835c2a2d491cc1c9687d8782a2b513a217718`
- **SuiNS binding:** bound to the SuiNS NFT currently in the operational wallet
- **Walrus network:** mainnet
- **Operational wallet:** the wallet registered in `~/.sui/sui_config/client.yaml`
- **Blob ownership model:** **shared** (policy — see below)

## Blob ownership policy

**ALL quilts/blobs backing the live site MUST be shared, not owned.**

Rationale:
- Shared blobs are fundable by anyone via `walrus fund-shared-blob` — the
  frontend becomes self-sustaining without admin top-ups
- Shared blob content is still immutable (Walrus blobs cannot be mutated at all,
  owned or shared — sharing only unlocks public funding, not public write)
- Shared blobs survive loss of the operational wallet: even if the wallet that
  originally published them is gone, the blobs live on, funded by anyone
- Owner of the Site object (= operational wallet) is still the only party that
  can add/remove/replace resource mappings, so publishing control stays private

Anything that creates new owned blobs (e.g. a fresh `site-builder update`) MUST
be followed by `walrus share` on each newly-created blob before the deploy is
considered complete.

## Active shared quilts

Last verified: **2026-04-14** (Walrus mainnet epoch **28**, epoch duration **14 days**).

| # | Shared Object ID | Blob ID (content hash) | Size | Exp. epoch | Exp. date | Resources |
|---|---|---|---|---|---|---|
| 1 | `0x3bf1eb1483390e82cbb2e00afe69fddb8c7c2a0a94606ee17347f8a8d0a3186e` | `SfKgzCqgT0el4bO6TsRJ1nk8g4vYFTZIRiunWdtzZmU` | 1.70 MiB | 33 | ~2026-06-22 | bundle `index-BYfk1RoU.js` + CSS `index-BSEWc_rh.css` + index.html + favicon + manifest |

Short lease (epoch 33) per the post-incident SOP — frontend still iterating, no public funding attached. Will be superseded on the next deploy; don't fund.

**Superseded shared quilts (orphaned, not funded, left to expire naturally — shared blobs cannot be burned):**
- `0xabedf95a39d9f66c9be059cfc169f28e1f678e72de07283c87c753d9add13cb2` (blob `KEtii76gWXE9KyhkN2hwQDXQEvGjS7N9EazheqIcnuQ`) — full bundle from the 2026-04-13 Thala-venue deploy (`index-CdA4OOgP.js` + `index-DkpC2sT9.css`). **Not funded**, zero WAL loss.
- `0xa8d80bbdfe0c51eab69890b70b22996d4c5a16447795405a93b34b67b8de5ddc` (blob `xCAFOx_4WhLPEJuDjC785vM8fhSVCUHh6bwGulix93U`) — formerly `/index.html` + old JS. **Locked ~3.229 WAL in the pool.** Expiry epoch 81 (~2028-04-18).
- `0x107f20be0eb16849e170836bde87d6b2d24ffca35431b819631c9aa8818b770b` (blob `buszfmqC_J1iS-Vpqwt0UwD3X2vylhUe86c87bCWnDI`) — formerly CSS + favicon + manifest. **Locked ~3.229 WAL in the pool.** Expiry epoch 81 (~2028-04-18).
- `0x64eb452541d150191d46c0522edc3072509875c543d86779475613d7828e1f46` (blob `LIa6r1DiE6ZmWKmygE2gzdCoO-P4V-_JulZxFZx4LcM`) — full bundle from the 2026-04-13 Treasury 3/5 deploy. **Not funded**, zero WAL loss.
- `0x4333ad3c58743371c675ec47f2d22ded9a95c89e3946b515fdc4b9c177f89150` (blob `07wfnaTbEb1L9Vj1I-cFyg7D7-V_zt4XEE_7mQlE2pU`) — full bundle from the 2026-04-13 balance/slippage deploy. **Not funded**, zero WAL loss.
- `0x085861efa4660e4019509a7efe489d22a4280d05ab7b7b352581c576aff5529f` (blob `rBZ5UMvle5AOf349equlhXSnBWJ3Cra5N7mPbD1TiN8`) — full bundle from the 2026-04-13 aggregator mode deploy. **Not funded**, zero WAL loss.
- `0x5cef144f2da6c74b9e55248e6dbd6499cb57d6fdeb9d87dd139cc1ca1209e2d7` (blob `Mivy_hUy-UZvkv33XMC3mNxhC-DxVQCKo5396ggbQtw`) — full bundle from the 2026-04-13 multi-RPC + debounce deploy. **Not funded**, zero WAL loss.
- `0x595658d1c3f70c5859296ccd26291d7be44948eee9b30b271611dd36be9e483f` (blob `KPlwW7jm-688GYf_6ufAb5xsw4bYjw3q5fS5DMJlJZo`) — full bundle from the 2026-04-13 Cellana wire-up + token auto-detect deploy. **Not funded**, zero WAL loss.

Site references blobs by content hash (blob ID), so the shared migration was
zero-downtime and no site-object update was required.

## Public funding & extension

> **⚠ PAUSED as of 2026-04-13.** See warning at top of file. Do not advertise
> public funding or run max-lease extend campaigns while the frontend is still
> iterating — any `site-builder update` can orphan the funded quilt and lock
> WAL in an unrecoverable pool. The mechanics below are preserved as reference
> for when we have a frozen archival site, but MUST NOT be promoted
> externally until that split exists (see "Planned dev/archival split" below).

Anyone — community members, users, bots — can keep these quilts alive without
access to the operational wallet. The flow is **two separate operations**:

### Step 1 — Fund the shared blob (add WAL to its internal pool)

```bash
walrus --context mainnet fund-shared-blob \
    --shared-blob-obj-id <SHARED_OBJECT_ID_FROM_TABLE> \
    --amount <FROST>
```

`--amount` is in FROST (1 WAL = 1_000_000_000 FROST). This deposits WAL into
the `SharedBlob` object's internal balance. It does NOT extend the lease yet —
it only top-ups the pool.

### Step 2 — Trigger the extension (consumes from the pool)

```bash
walrus --context mainnet extend \
    --shared \
    --blob-obj-id <SHARED_OBJECT_ID_FROM_TABLE> \
    --epochs-extended <N>
```

Anyone can call this. The cost is paid from the SharedBlob's internal pool
(funded in Step 1), not from the caller's wallet. Extension is capped by
Walrus `max_epochs_ahead` (currently 53 epochs / ~2 years).

### Pricing reference

- Tier ≤16 MiB unencoded = **0.0015 WAL / epoch**
- The 2026-04-13 deploy orphaned the two previously funded quilts
  (`0xa8d80bbd...` and `0x107f20be...`), locking ~6.458 WAL in their
  SharedBlob pools until natural expiry at epoch 81. This is why
  max-lease public funding is now paused — see warning at top of file.

### When to trigger extend

Both blobs are currently at epoch 81 (max). Extension calls will start
succeeding once the Walrus network's current epoch advances and
`current_epoch + 53 > 81`. Until then, extend calls will either no-op or
error because the blob is already at the max-future ceiling.

After every epoch tick (every 14 days), anyone can run Step 2 with
`--epochs-extended 1` to keep the blob pinned at the ceiling. Automation
via a cron / public script is the intended long-term pattern.

## How to verify on-chain state

```bash
# 1. Site → resource → blob ID mapping
site-builder sitemap 0x050df98fbc08b6c4e5d8d41dc75835c2a2d491cc1c9687d8782a2b513a217718

# 2. Owned blobs (should be EMPTY — any entry here is a new deploy that
#    still needs to be shared, or an orphan)
walrus --context mainnet list-blobs

# 3. Walrus current epoch (for epoch → date conversion)
walrus --context mainnet info | grep -iE "epoch|duration"

# 4. Confirm a shared blob's on-chain state
sui client object <SHARED_OBJECT_ID> | grep -iE "owner|shared|type"
```

**Invariant:** `walrus list-blobs` should be EMPTY after any deploy. Each
shared object in the table above must show `owner: Shared` and type
`...::shared_blob::SharedBlob`.

## Deploy checklist (MANDATORY ORDER)

Every production deploy MUST follow every step:

1. `npm run build`
2. **Dry-run first** (no FROST spent):
   `site-builder update --dry-run --epochs 5 dist 0x050df98fbc08b6c4e5d8d41dc75835c2a2d491cc1c9687d8782a2b513a217718`
   - Review: which existing quilts are REUSED vs which will be CREATED anew
   - If the output shows ALL existing referenced quilts being replaced on a
     small change, STOP and investigate `--max-quilt-size` or file-level
     changes before paying — a repack orphans every referenced quilt
   - `site-builder` help states: *"Existing quilts are reused automatically
     without additional FROST spending"* — verify this is actually happening
3. `site-builder update --epochs 5 dist 0x050df98fbc08b6c4e5d8d41dc75835c2a2d491cc1c9687d8782a2b513a217718`
   - **Always** use `update`, never `publish` (SuiNS is bound to the object ID)
   - **Default `--epochs 5`** (≈ 10 weeks) while frontend is iterating. Short
     lease limits blast radius if the next deploy orphans this quilt. DO NOT
     use `--epochs 53` / `--epochs max` unless you are publishing an
     **archival frozen snapshot** (see "Planned dev/archival split")
4. `site-builder sitemap <site_id>` — verify new resource → blob mapping
5. `walrus --context mainnet list-blobs` — find any new OWNED blob object IDs
6. For each NEW owned blob: `walrus --context mainnet share --blob-obj-id <id>`
   - Record the resulting shared object ID
7. Re-run `walrus list-blobs` — MUST be empty
8. Update the table in this file with new shared object IDs + exp epochs.
   Move any newly-orphaned quilts to the "Superseded" list (do NOT try to
   burn them — shared blobs are unburnable)
9. Commit and push — the table on `main` must match on-chain reality

## Planned dev/archival split (not yet implemented)

**Status:** concept, pending decision. Not deployed yet.

The current single-site model mixes two incompatible concerns:

| Concern | Lease needs | Update frequency | Public funding? |
|---|---|---|---|
| **Working site** (active frontend) | Short (5–10 epochs) | Frequent | ❌ No — would orphan funds |
| **Archival site** (frozen snapshot) | Max (53 epochs + extend) | Never | ✅ Yes — funds are safe |

Proposed split:
1. Keep `0x050df98f...` as the **working site** — short lease, no public
   funding advertised, frequent updates allowed
2. Publish a **separate archival site object** once we have a canonical
   "v1.0 launch" snapshot we commit never to update — fund to max, open to
   public funding, point a *different* SuiNS name at it (e.g.
   `darbitex-archive.wal.app`)
3. Main brand SuiNS continues pointing at the working site; archival exists
   as parallel permanent mirror

**Do not publish the archival site until:**
- Frontend is feature-complete for a release we commit to freezing
- Quilt-reuse behavior across `site-builder update` is understood well
  enough to guarantee the archival quilts will not be touched

## Destructive-op safety rules

- **NEVER run `site-builder destroy` on any site that references blobs used by
  the live Darbitex site.** `destroy` burns every referenced blob, even
  cross-site shared ones. See `feedback_walrus_destroy_shared_blob.md` in
  auto-memory for the incident.
- **NEVER transfer the Site object** `0x050df98f...` unless the destination
  wallet is explicitly the new admin.
- **Burn orphan blobs individually** via
  `walrus burn-blobs --object-ids <...>` only for blobs owned by the wallet
  (listed by `walrus list-blobs`) AND verified absent from the Active shared
  quilts table.
- Shared blobs **cannot be burned** by this wallet anymore — they will live
  until their lease expires naturally.

## Recovery procedure (wallet loss / compromise)

**Key invariant:** continuity of the brand URL depends on the **SuiNS
registration NFT**, NOT on the operational wallet. As long as the SuiNS NFT is
safe, the public URL can always be re-pointed to a new Site object.

### Threat model

| Loss scenario | Recoverable? | Path |
|---|---|---|
| Operational wallet compromised but SuiNS NFT in cold wallet | **Yes** | Publish new Site from new wallet → re-point SuiNS → done |
| Operational wallet lost AND SuiNS NFT in same wallet | **No** for the URL; users can still reach the old Site object directly until blobs expire | — |
| Shared blob lease runs out | Partial — blobs expire; site goes blank until a re-deploy to fresh blobs and SuiNS re-point | Community can keep funding before expiry |

### Why shared blobs matter for recovery

Because blobs are shared, they **do not expire when the operational wallet is
lost**. The community can keep extending them via `fund-shared-blob`. This
gives you a long grace window to execute recovery.

### Recovery runbook

Assumes: you still control the SuiNS registration NFT in a separate cold wallet.

1. **Provision new operational wallet**
   - Generate new Sui keypair, fund with SUI (gas) + WAL (storage)
2. **Clone & build frontend from `main`**
   - `git clone <repo> && cd frontend && npm ci && npm run build`
3. **Publish fresh Site object**
   - `site-builder publish --epochs 53 dist --site-name "Darbitex"`
   - Record the new Site Object ID
4. **Share all new blobs** (per policy)
   - `walrus list-blobs` → for each entry: `walrus share --blob-obj-id <id>`
5. **Re-point SuiNS** from the cold wallet
   - Use SuiNS dApp or CLI: set target to new Site Object ID
6. **Verify** via `https://<subdomain>.wal.app`
7. **Update this file** on `main`:
   - New Site Object ID
   - New shared blob object IDs and expirations
   - New "operational wallet" description

### SuiNS NFT protection (highest priority)

The SuiNS registration NFT is the single-most-valuable object in the recovery
chain. Its current location and required protection:

- **Current state (2026-04-13):** SuiNS NFT resides in the operational wallet
  — this is a known single-point-of-failure
- **Target state:** SuiNS NFT transferred to a cold wallet (hardware / multisig
  / air-gapped), operational wallet retains only:
  - Site object ownership
  - WAL balance for future shares / fundings
  - SUI gas
- **Cold wallet role:** holds the SuiNS NFT, signs only SuiNS re-point txs and
  SuiNS renewal payments
- **Renewal:** SuiNS registrations are themselves subject to expiry — set a
  calendar reminder or automate renewal from cold wallet well before the NFT's
  expiry date

Until the SuiNS NFT is moved, treat the operational wallet as a high-severity
credential and rotate it at the first sign of compromise.

## Epoch reference

- Walrus mainnet epoch duration = **14 days**
- Max future epochs per blob = **53** (≈ 2 years lease ceiling)
- Storage price tier ≤ 16 MiB unencoded = **0.0015 WAL / epoch**

Convert epoch → date:

```
target_date = today + (target_epoch - current_epoch) * 14 days
```
