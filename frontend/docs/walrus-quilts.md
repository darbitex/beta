# Walrus Quilt Registry — Darbitex Beta Frontend

Source of truth for which Walrus blobs (quilts) back the live Darbitex Beta
site. Cross-check this file against on-chain state before any deploy, extend,
or burn operation.

## Live site

- **Site Object ID:** `0x050df98fbc08b6c4e5d8d41dc75835c2a2d491cc1c9687d8782a2b513a217718`
- **SuiNS binding:** bound (see `darbitex-beta` / live domain)
- **Walrus network:** mainnet
- **Wallet:** the wallet registered in `~/.sui/sui_config/client.yaml`

## Active quilts

Last verified: **2026-04-13** (Walrus mainnet epoch **28**, epoch duration **14 days**).

| # | Blob Object ID | Blob ID | Size | Exp. epoch | Exp. date | Resources |
|---|---|---|---|---|---|---|
| 1 | `0x824c7b6f6216699bba57dc59ebc48b893a9156b409aa269025e2d866e2c8a436` | `xCAFOx_4WhLPEJuDjC785vM8fhSVCUHh6bwGulix93U` | 1.70 MiB | 81 | 2028-04-18 | `/index.html`, `/assets/index-BktrgoBZ.js` |
| 2 | `0x76070409f3477f9d2e5f9b7d5a3adaa2acfaafba0363c770ffa2c057988d6b78` | `buszfmqC_J1iS-Vpqwt0UwD3X2vylhUe86c87bCWnDI` | 435 KiB | 81 | 2028-04-18 | `/assets/index-Dk_OrSqq.css`, `/favicon.svg`, `/manifest.json` |

Two quilts exist because CSS/favicon/manifest bytes stayed identical across the
last deploy while JS+HTML changed. Vite content-hashed filenames naturally
re-merge into a single quilt only when *every* file changes.

## How to verify on-chain state

```bash
# 1. Site → blob references
site-builder sitemap 0x050df98fbc08b6c4e5d8d41dc75835c2a2d491cc1c9687d8782a2b513a217718

# 2. Wallet blob list (should contain ONLY the blobs above)
walrus --context mainnet list-blobs

# 3. Walrus current epoch (so you can convert exp epoch → date)
walrus --context mainnet info | grep -iE "epoch|duration"
```

**Invariant:** `walrus list-blobs` output should match this file exactly — same
object IDs, same count. Any extra blob is an orphan (safe to burn after confirming
it is not in any other live site you care about). Any missing blob is a broken
live site (restore via `site-builder update --epochs 53`, then extend new blobs).

## How to update this file

Update this table whenever any of the following happens:

1. **Frontend deploy** — a `site-builder update` created new quilts and/or deleted old ones.
2. **Extend** — a `walrus extend` bumped an `Exp. epoch`.
3. **Burn** — a blob was burned.

After the op, run step 1 (sitemap) and step 2 (list-blobs), then edit this table
so it matches. Commit alongside the change that triggered it.

## Epoch reference

- Walrus mainnet epoch duration = **14 days**
- Max future epochs for a new blob = **53** (≈ 2 years lease ceiling)
- Storage price tier ≤ 16 MiB unencoded = **0.0015 WAL / epoch**

Convert epoch → date:
```
target_date = today + (target_epoch - current_epoch) * 14 days
```

## Deploy checklist

Every production deploy MUST follow these steps in order:

1. `npm run build`
2. `site-builder update --epochs 53 dist 0x050df98fbc08b6c4e5d8d41dc75835c2a2d491cc1c9687d8782a2b513a217718`
   - **Always** pass `--epochs 53` to get max lease on new blobs
   - **Always** use `update`, never `publish` (SuiNS binding is on the object ID)
3. `site-builder sitemap <site_id>` — copy new blob object IDs into this file
4. `walrus --context mainnet list-blobs` — verify no unexpected extras
5. For any blob that `update` created with a shorter lease than 53 epochs (e.g.,
   if site-builder's --epochs 53 path crashes with SIGILL on this host), run
   `walrus --context mainnet extend --blob-obj-id <id> --epochs-extended <n>`
   manually
6. Commit the updated `walrus-quilts.md`

## Destructive-op safety rules

- **NEVER run `site-builder destroy` on any site that shares blobs with the live
  Beta site.** `destroy` burns every referenced blob, even cross-site shared ones.
  See `feedback_walrus_destroy_shared_blob.md` in auto-memory for the incident
  that triggered this rule.
- **Burn orphan blobs individually** via `walrus burn-blobs --object-ids <...>`
  after cross-checking against this file.
- **Before burning**, confirm the blob object ID is NOT in the active quilts
  table above.
