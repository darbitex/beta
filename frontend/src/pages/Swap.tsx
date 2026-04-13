import { useWallet } from "@aptos-labs/wallet-adapter-react";
import { useEffect, useMemo, useState } from "react";
import { useFaBalance } from "../chain/balance";
import { fromRaw, metaEq, toRaw, viewFn } from "../chain/client";
import { findPool, loadPools, type Pool } from "../chain/pools";
import { useSlippage } from "../chain/slippage";
import { buildEntryTx } from "../chain/tx";
import { useToast } from "../components/Toast";
import { TOKENS } from "../config";

export function SwapPage() {
  const toast = useToast();
  const { connected, signAndSubmitTransaction } = useWallet();
  const [slippage] = useSlippage();
  const [pools, setPools] = useState<Pool[]>([]);
  const [inSym, setInSym] = useState("APT");
  const [outSym, setOutSym] = useState("USDC");
  const [amount, setAmount] = useState("");
  const [quote, setQuote] = useState<{ amountOut: number; pool: Pool } | null>(null);
  const [busy, setBusy] = useState(false);

  useEffect(() => {
    loadPools().then(setPools).catch((e) => toast(`Load pools: ${String(e?.message ?? e)}`, true));
  }, [toast]);

  const tIn = TOKENS[inSym]!;
  const tOut = TOKENS[outSym]!;
  const amountNum = Number.parseFloat(amount);
  const balIn = useFaBalance(tIn.meta, tIn.decimals);
  const balOut = useFaBalance(tOut.meta, tOut.decimals);

  useEffect(() => {
    let cancelled = false;
    async function run() {
      if (!pools.length || !amountNum || amountNum <= 0 || inSym === outSym) {
        setQuote(null);
        return;
      }
      const pool = findPool(pools, tIn.meta, tOut.meta);
      if (!pool) {
        setQuote(null);
        return;
      }
      try {
        const rawIn = toRaw(amountNum, tIn.decimals);
        const aToB = metaEq(pool.meta_a, tIn.meta);
        const res = await viewFn<[string | number]>("pool::get_amount_out", [], [
          pool.addr,
          rawIn.toString(),
          aToB,
        ]);
        const rawOut = Number(res[0] ?? 0);
        if (!cancelled) setQuote({ amountOut: fromRaw(rawOut, tOut.decimals), pool });
      } catch (e) {
        if (!cancelled) {
          console.error(e);
          setQuote(null);
        }
      }
    }
    run();
    return () => {
      cancelled = true;
    };
  }, [pools, amountNum, inSym, outSym, tIn, tOut]);

  const disabled = !connected || !quote || busy;
  const btnLabel = useMemo(() => {
    if (!amountNum || amountNum <= 0) return "Enter amount";
    if (inSym === outSym) return "Select different tokens";
    if (!quote) return "No pool";
    if (!connected) return "Connect wallet";
    if (busy) return "Submitting...";
    return "Swap";
  }, [amountNum, inSym, outSym, quote, connected, busy]);

  async function doSwap() {
    if (!quote) return;
    setBusy(true);
    try {
      const rawIn = toRaw(amountNum, tIn.decimals);
      const minOut = toRaw(quote.amountOut * (1 - slippage), tOut.decimals);
      const deadline = Math.floor(Date.now() / 1000) + 120;
      const tx = buildEntryTx("router", "swap_with_deadline", [
        quote.pool.addr,
        tIn.meta,
        rawIn.toString(),
        minOut.toString(),
        deadline.toString(),
      ]);
      const resp = await signAndSubmitTransaction(tx);
      toast(`TX: ${String(resp.hash).slice(0, 12)}...`);
      setTimeout(() => {
        loadPools().then(setPools).catch(() => {});
        balIn.refresh();
        balOut.refresh();
      }, 3000);
    } catch (e: unknown) {
      toast((e as Error)?.message ?? "TX failed", true);
    } finally {
      setBusy(false);
    }
  }

  function setMax() {
    if (balIn.raw === 0n) return;
    setAmount(String(balIn.formatted));
  }

  function flip() {
    setInSym(outSym);
    setOutSym(inSym);
  }

  return (
    <div className="container">
      <div className="card">
        <div className="swap-label-row">
          <span className="swap-label">You pay</span>
          {connected && (
            <button
              type="button"
              className="bal-link"
              onClick={setMax}
              disabled={balIn.raw === 0n}
              title="Click for MAX"
            >
              Balance: {balIn.loading ? "…" : balIn.formatted.toFixed(6)} {inSym}
            </button>
          )}
        </div>
        <div className="swap-row">
          <input
            className="swap-input"
            type="number"
            placeholder="0.0"
            value={amount}
            onChange={(e) => setAmount(e.target.value)}
          />
          <select className="token-select" value={inSym} onChange={(e) => setInSym(e.target.value)}>
            {Object.keys(TOKENS).map((s) => (
              <option key={s} value={s}>{s}</option>
            ))}
          </select>
        </div>
        <div className="swap-arrow">
          <button type="button" onClick={flip} aria-label="Flip">&#8597;</button>
        </div>
        <div className="swap-label-row">
          <span className="swap-label">You receive</span>
          {connected && (
            <span className="bal-static">
              Balance: {balOut.loading ? "…" : balOut.formatted.toFixed(6)} {outSym}
            </span>
          )}
        </div>
        <div className="swap-row">
          <input
            className="swap-input"
            type="number"
            placeholder="0.0"
            value={quote ? quote.amountOut.toFixed(6) : ""}
            readOnly
          />
          <select
            className="token-select"
            value={outSym}
            onChange={(e) => setOutSym(e.target.value)}
          >
            {Object.keys(TOKENS).map((s) => (
              <option key={s} value={s}>{s}</option>
            ))}
          </select>
        </div>
        {quote && (
          <div className="swap-info">
            <div>
              <span>Rate</span>
              <span className="val">
                1 {inSym} = {amountNum > 0 ? (quote.amountOut / amountNum).toFixed(6) : "—"} {outSym}
              </span>
            </div>
            <div>
              <span>Fee</span>
              <span className="val">0.01% (1 BPS)</span>
            </div>
            <div>
              <span>Slippage</span>
              <span className="val">{(slippage * 100).toFixed(slippage < 0.01 ? 2 : 1)}%</span>
            </div>
            <div>
              <span>Pool</span>
              <span className="val">{quote.pool.addr.slice(0, 10)}...</span>
            </div>
            <div>
              <span>Min received</span>
              <span className="val">
                {(quote.amountOut * (1 - slippage)).toFixed(6)} {outSym}
              </span>
            </div>
          </div>
        )}
        <button
          type="button"
          className="btn btn-primary"
          disabled={disabled}
          onClick={doSwap}
          style={{ marginTop: 16 }}
        >
          {btnLabel}
        </button>
      </div>
    </div>
  );
}
