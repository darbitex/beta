import { useWallet } from "@aptos-labs/wallet-adapter-react";
import { useState } from "react";
import { useFaBalance } from "../chain/balance";
import { toRaw, fromRaw } from "../chain/client";
import type { Pool } from "../chain/pools";
import { useSlippage } from "../chain/slippage";
import { buildEntryTx } from "../chain/tx";
import { Modal } from "./Modal";
import { useToast } from "./Toast";

export function AddLiquidityModal({
  pool,
  onClose,
  onDone,
}: {
  pool: Pool | null;
  onClose: () => void;
  onDone: () => void;
}) {
  const toast = useToast();
  const { signAndSubmitTransaction, connected } = useWallet();
  const [slippage] = useSlippage();
  const [amtA, setAmtA] = useState("");
  const [amtB, setAmtB] = useState("");
  const [busy, setBusy] = useState(false);

  const balA = useFaBalance(pool?.token_a.meta ?? null, pool?.token_a.decimals ?? 0);
  const balB = useFaBalance(pool?.token_b.meta ?? null, pool?.token_b.decimals ?? 0);

  if (!pool) return null;

  const resA = Number(pool.reserve_a);
  const resB = Number(pool.reserve_b);
  const supply = Number(pool.lp_supply);
  const hasReserves = resA > 0 && resB > 0;

  function onChangeA(val: string) {
    setAmtA(val);
    if (!pool || !hasReserves || !val) return;
    const a = Number.parseFloat(val);
    if (a > 0) {
      const rawA = toRaw(a, pool.token_a.decimals);
      const rawB = (rawA * BigInt(pool.reserve_b)) / BigInt(pool.reserve_a);
      setAmtB(String(fromRaw(rawB, pool.token_b.decimals)));
    } else {
      setAmtB("");
    }
  }

  function onChangeB(val: string) {
    setAmtB(val);
    if (!pool || !hasReserves || !val) return;
    const b = Number.parseFloat(val);
    if (b > 0) {
      const rawB = toRaw(b, pool.token_b.decimals);
      const rawA = (rawB * BigInt(pool.reserve_a)) / BigInt(pool.reserve_b);
      setAmtA(String(fromRaw(rawA, pool.token_a.decimals)));
    } else {
      setAmtA("");
    }
  }

  function setMaxA() {
    if (balA.raw === 0n) return;
    onChangeA(String(balA.formatted));
  }

  function setMaxB() {
    if (balB.raw === 0n) return;
    onChangeB(String(balB.formatted));
  }

  async function submit() {
    if (!connected || !pool) {
      toast("Connect wallet first", true);
      return;
    }
    const a = Number.parseFloat(amtA);
    const b = Number.parseFloat(amtB);
    if (!a || !b || a <= 0 || b <= 0) {
      toast("Amounts must be > 0", true);
      return;
    }
    setBusy(true);
    try {
      const rawA = toRaw(a, pool.token_a.decimals);
      const rawB = toRaw(b, pool.token_b.decimals);
      let expectedLp: bigint;
      if (supply === 0 || !hasReserves) {
        const prod = Number(rawA) * Number(rawB);
        expectedLp = BigInt(Math.floor(Math.sqrt(prod)));
      } else {
        const lpFromA = (rawA * BigInt(supply)) / BigInt(resA);
        const lpFromB = (rawB * BigInt(supply)) / BigInt(resB);
        expectedLp = lpFromA < lpFromB ? lpFromA : lpFromB;
      }
      const slipBps = BigInt(Math.floor((1 - slippage) * 10000));
      const minLp = (expectedLp * slipBps) / 10000n;
      const tx = buildEntryTx("pool", "add_liquidity_entry", [
        pool.addr,
        rawA.toString(),
        rawB.toString(),
        minLp.toString(),
      ]);
      const resp = await signAndSubmitTransaction(tx);
      toast(`TX: ${String(resp.hash).slice(0, 12)}...`);
      setAmtA("");
      setAmtB("");
      balA.refresh();
      balB.refresh();
      onDone();
    } catch (e: unknown) {
      toast((e as Error)?.message ?? "TX failed", true);
    } finally {
      setBusy(false);
    }
  }

  const priceDisplay = hasReserves
    ? `1 ${pool.token_a.symbol} ≈ ${(resB / resA * (10 ** pool.token_a.decimals / 10 ** pool.token_b.decimals)).toFixed(pool.token_b.decimals)} ${pool.token_b.symbol}`
    : null;

  return (
    <Modal open={!!pool} onClose={onClose} title={`Add ${pool.token_a.symbol}/${pool.token_b.symbol}`}>
      <label>Amount {pool.token_a.symbol}</label>
      <input
        type="number"
        placeholder={`Amount ${pool.token_a.symbol}`}
        value={amtA}
        onChange={(e) => onChangeA(e.target.value)}
      />
      {connected && (
        <button
          type="button"
          className="bal-link bal-link-modal"
          onClick={setMaxA}
          disabled={balA.raw === 0n}
        >
          Balance: {balA.loading ? "…" : balA.formatted.toFixed(6)} {pool.token_a.symbol}
        </button>
      )}
      <label>Amount {pool.token_b.symbol}</label>
      <input
        type="number"
        placeholder={`Amount ${pool.token_b.symbol}`}
        value={amtB}
        onChange={(e) => onChangeB(e.target.value)}
      />
      {connected && (
        <button
          type="button"
          className="bal-link bal-link-modal"
          onClick={setMaxB}
          disabled={balB.raw === 0n}
        >
          Balance: {balB.loading ? "…" : balB.formatted.toFixed(6)} {pool.token_b.symbol}
        </button>
      )}
      {priceDisplay && <div className="modal-note">{priceDisplay}</div>}
      <div className="modal-note">
        Provide a small buffer — unused tokens stay in your wallet. Mints a new LpPosition NFT. Min LP applies slippage {(slippage * 100).toFixed(slippage < 0.01 ? 2 : 1)}%.
      </div>
      <button type="button" className="btn btn-primary" onClick={submit} disabled={busy}>
        {busy ? "Submitting..." : "Add Liquidity"}
      </button>
    </Modal>
  );
}
