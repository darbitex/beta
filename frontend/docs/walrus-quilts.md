# Walrus Quilt Registry — Darbitex Frontend

Source of truth for which Walrus blobs (quilts) back the live Darbitex site.
Cross-check this file against on-chain state before any deploy, extend, share,
or burn operation.

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

Last verified: **2026-04-13** (Walrus mainnet epoch **28**, epoch duration **14 days**).

| # | Shared Object ID | Blob ID (content hash) | Size | Exp. epoch | Exp. date | Resources |
|---|---|---|---|---|---|---|
| 1 | `0x64eb452541d150191d46c0522edc3072509875c543d86779475613d7828e1f46` | `LIa6r1DiE6ZmWKmygE2gzdCoO-P4V-_JulZxFZx4LcM` | 1.70 MiB | 81 | 2028-04-18 | `/index.html`, `/assets/index-Bw0NLo27.js`, `/assets/index-Dk_OrSqq.css`, `/favicon.svg`, `/manifest.json` |

**Superseded shared quilts (no longer referenced by the site, left to expire naturally — shared blobs cannot be burned):**
- `0xa8d80bbdfe0c51eab69890b70b22996d4c5a16447795405a93b34b67b8de5ddc` (blob `xCAFOx_4WhLPEJuDjC785vM8fhSVCUHh6bwGulix93U`) — formerly held `/index.html` + old JS
- `0x107f20be0eb16849e170836bde87d6b2d24ffca35431b819631c9aa8818b770b` (blob `buszfmqC_J1iS-Vpqwt0UwD3X2vylhUe86c87bCWnDI`) — formerly held CSS + favicon + manifest

Site references blobs by content hash (blob ID), so the shared migration was
zero-downtime and no site-object update was required.

## Public funding & extension

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

- Tier ≤16 MiB unencoded = **0.0015 WAL / epoch** (both quilts fall in this tier)
- Both quilts fully funded 2026-04-13 with 3.229 WAL each (= 6.458 WAL total,
  the entire operational wallet WAL balance). At 0.0015 WAL per epoch, that
  is ~2150 epochs of runway per quilt, far exceeding any practical horizon
  (Walrus protocol caps lease extensions at 53 epochs ahead, so most of the
  pool sits idle as future headroom)
- Any community top-ups further extend the runway

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
2. `site-builder update --epochs 53 dist 0x050df98fbc08b6c4e5d8d41dc75835c2a2d491cc1c9687d8782a2b513a217718`
   - **Always** use `update`, never `publish` (SuiNS is bound to the object ID)
   - **Always** pass `--epochs 53` to buy max lease
3. `site-builder sitemap <site_id>` — note which blob object IDs are new
4. `walrus --context mainnet list-blobs` — find new owned blob object IDs
5. For each NEW owned blob: `walrus --context mainnet share --blob-obj-id <id>`
   - Record the resulting shared object ID
6. If any new blob got a lease < 53 epochs (e.g. site-builder SIGILL workaround):
   `walrus --context mainnet extend --blob-obj-id <id> --epochs-extended <n>`
   **BEFORE** sharing (extend must be done by the owner)
7. Re-run `walrus list-blobs` — MUST be empty
8. Update the table in this file with new shared object IDs + exp epochs
9. Commit and push — the table on `main` must match on-chain reality

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
