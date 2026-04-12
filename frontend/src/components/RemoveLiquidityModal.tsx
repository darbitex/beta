import { useWallet } from "@aptos-labs/wallet-adapter-react";
import { useState } from "react";
import { buildEntryTx } from "../chain/tx";
import { Modal } from "./Modal";
import { useToast } from "./Toast";

export function RemoveLiquidityModal({
  positionAddr,
  pairLabel,
  onClose,
  onDone,
}: {
  positionAddr: string | null;
  pairLabel: string;
  onClose: () => void;
  onDone: () => void;
}) {
  const toast = useToast();
  const { signAndSubmitTransaction, connected } = useWallet();
  const [busy, setBusy] = useState(false);

  if (!positionAddr) return null;

  async function submit() {
    if (!connected || !positionAddr) {
      toast("Connect wallet first", true);
      return;
    }
    setBusy(true);
    try {
      const tx = buildEntryTx("pool", "remove_liquidity_entry", [
        positionAddr,
        "0",
        "0",
      ]);
      const resp = await signAndSubmitTransaction(tx);
      toast(`TX: ${String(resp.hash).slice(0, 12)}...`);
      onDone();
    } catch (e: unknown) {
      toast((e as Error)?.message ?? "TX failed", true);
    } finally {
      setBusy(false);
    }
  }

  return (
    <Modal open={!!positionAddr} onClose={onClose} title={`Remove ${pairLabel}`}>
      <div className="modal-note">
        Burns this LpPosition NFT and returns proportional reserves plus accumulated fees. Position: {positionAddr.slice(0, 14)}...
      </div>
      <button type="button" className="btn btn-primary" onClick={submit} disabled={busy}>
        {busy ? "Submitting..." : "Remove Liquidity"}
      </button>
    </Modal>
  );
}
