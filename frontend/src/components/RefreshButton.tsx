import { useState } from "react";
import { refreshPools } from "../chain/pools";
import { useToast } from "./Toast";

// Manual pool-universe refresh. Invalidates localStorage cache, forces a
// fresh chain load, and broadcasts the new state to every subscribed page.
// Used when a user just created a new pool and wants it visible immediately,
// or to confirm reserves are up to date after an out-of-band swap.
export function RefreshButton() {
  const toast = useToast();
  const [busy, setBusy] = useState(false);
  async function handle() {
    if (busy) return;
    setBusy(true);
    try {
      const fresh = await refreshPools();
      toast(`Refreshed: ${fresh.length} pools`);
    } catch (e) {
      toast(`Refresh failed: ${String((e as Error)?.message ?? e)}`, true);
    } finally {
      setBusy(false);
    }
  }
  return (
    <button
      type="button"
      className="refresh-btn"
      onClick={handle}
      disabled={busy}
      title="Refresh pool universe (chain read)"
      aria-label="Refresh pools"
    >
      {busy ? "…" : "↻"}
    </button>
  );
}
