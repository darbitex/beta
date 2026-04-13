import { useWallet } from "@aptos-labs/wallet-adapter-react";
import { useState } from "react";
import type { Pool } from "../chain/pools";
import { useSlippage } from "../chain/slippage";
import { buildEntryTx } from "../chain/tx";
import { Modal } from "./Modal";
import { useToast } from "./Toast";

export type RemoveTarget = {
  positionAddr: string;
  pairLabel: string;
  pool: Pool | null;
  shares: number;
};

export function RemoveLiquidityModal({
  target,
  onClose,
  onDone,
}: {
  target: RemoveTarget | null;
  onClose: () => void;
  onDone: () => void;
}) {
  const toast = useToast();
  const { signAndSubmitTransaction, connected } = useWallet();
  const [slippage] = useSlippage();
  const [busy, setBusy] = useState(false);

  if (!target) return null;

  const { positionAddr, pairLabel, pool, shares } = target;

  let expectedA = 0n;
  let expectedB = 0n;
  if (pool && shares > 0) {
    const supply = BigInt(pool.lp_supply);
    if (supply > 0n) {
      expectedA = (BigInt(pool.reserve_a) * BigInt(shares)) / supply;
      expectedB = (BigInt(pool.reserve_b) * BigInt(shares)) / supply;
    }
  }
  const slipBps = BigInt(Math.floor((1 - slippage) * 10000));
  const minA = (expectedA * slipBps) / 10000n;
  const minB = (expectedB * slipBps) / 10000n;

  async function submit() {
    if (!connected) {
      toast("Connect wallet first", true);
      return;
    }
    setBusy(true);
    try {
      const tx = buildEntryTx("pool", "remove_liquidity_entry", [
        positionAddr,
        minA.toString(),
        minB.toString(),
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

  const sA = pool?.token_a.symbol ?? "?";
  const sB = pool?.token_b.symbol ?? "?";
  const dA = pool?.token_a.decimals ?? 0;
  const dB = pool?.token_b.decimals ?? 0;
  const fmtA = Number(expectedA) / 10 ** dA;
  const fmtB = Number(expectedB) / 10 ** dB;
  const minFmtA = Number(minA) / 10 ** dA;
  const minFmtB = Number(minB) / 10 ** dB;

  return (
    <Modal open={!!target} onClose={onClose} title={`Remove ${pairLabel}`}>
      <div className="modal-note">
        Burns this LpPosition NFT and returns proportional reserves plus accumulated fees. Position: {positionAddr.slice(0, 14)}...
      </div>
      {pool ? (
        <>
          <div className="remove-preview">
            <div>
              <span className="label">Expected {sA}</span>
              <span className="value">{fmtA.toFixed(6)}</span>
            </div>
            <div>
              <span className="label">Expected {sB}</span>
              <span className="value">{fmtB.toFixed(6)}</span>
            </div>
            <div>
              <span className="label">Min {sA} ({(slippage * 100).toFixed(slippage < 0.01 ? 2 : 1)}%)</span>
              <span className="value accent">{minFmtA.toFixed(6)}</span>
            </div>
            <div>
              <span className="label">Min {sB} ({(slippage * 100).toFixed(slippage < 0.01 ? 2 : 1)}%)</span>
              <span className="value accent">{minFmtB.toFixed(6)}</span>
            </div>
          </div>
        </>
      ) : (
        <div className="modal-note">Pool details unavailable — min amounts will default to 0.</div>
      )}
      <button type="button" className="btn btn-primary" onClick={submit} disabled={busy}>
        {busy ? "Submitting..." : "Remove Liquidity"}
      </button>
    </Modal>
  );
}
