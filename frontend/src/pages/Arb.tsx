import { useWallet } from "@aptos-labs/wallet-adapter-react";
import { useCallback, useEffect, useMemo, useState } from "react";
import { scanAllOpportunities, type ArbOpportunity } from "../chain/arbScanner";
import { fromRaw } from "../chain/client";
import { buildEntryTx } from "../chain/tx";
import { useToast } from "../components/Toast";
import { ARB_KEEPER_PACKAGE, VENUE_ID } from "../config";

const SCAN_INTERVAL_MS = 30_000;

const VENUE_LABEL = {
  darbitex: "Darbitex",
  hyperion: "Hyperion",
  thala: "Thala",
} as const;

function octasToApt(n: bigint): string {
  return (Number(n) / 1e8).toFixed(6);
}

function formatBps(bps: number): string {
  return `${bps >= 0 ? "+" : ""}${bps.toFixed(1)} bps`;
}

export function ArbPage() {
  const toast = useToast();
  const { connected, signAndSubmitTransaction } = useWallet();
  const [opps, setOpps] = useState<ArbOpportunity[]>([]);
  const [loading, setLoading] = useState(false);
  const [lastScan, setLastScan] = useState<number>(0);
  const [auto, setAuto] = useState(true);
  const [executingIdx, setExecutingIdx] = useState<number | null>(null);

  const scan = useCallback(async () => {
    setLoading(true);
    try {
      const results = await scanAllOpportunities();
      setOpps(results);
      setLastScan(Date.now());
    } catch (e) {
      toast(`Scan failed: ${String((e as Error)?.message ?? e)}`, true);
    } finally {
      setLoading(false);
    }
  }, [toast]);

  // Initial scan on mount
  useEffect(() => {
    scan();
  }, [scan]);

  // Auto-refresh interval
  useEffect(() => {
    if (!auto) return;
    const timer = setInterval(() => {
      scan();
    }, SCAN_INTERVAL_MS);
    return () => clearInterval(timer);
  }, [auto, scan]);

  async function execute(opp: ArbOpportunity, idx: number) {
    if (!connected) {
      toast("Connect wallet first", true);
      return;
    }
    setExecutingIdx(idx);
    try {
      let tx;
      if (opp.mode === "2leg") {
        tx = buildEntryTx(
          "keeper",
          "execute_arb",
          [
            VENUE_ID[opp.legs[0].venue],
            opp.legs[0].pool,
            true, // venue_a_a_to_b — Hyperion checks this, others ignore
            VENUE_ID[opp.legs[1].venue],
            opp.legs[1].pool,
            false,
            opp.borrow_asset,
            opp.mids[0],
            opp.borrow_amount.toString(),
            "0", // min_profit_abs — rely on protocol 5 bps floor
          ],
          [],
          ARB_KEEPER_PACKAGE,
        );
      } else {
        // 3-leg triangular
        tx = buildEntryTx(
          "keeper",
          "execute_triangular_arb",
          [
            VENUE_ID[opp.legs[0].venue],
            opp.legs[0].pool,
            true,
            VENUE_ID[opp.legs[1].venue],
            opp.legs[1].pool,
            true,
            VENUE_ID[opp.legs[2].venue],
            opp.legs[2].pool,
            false,
            opp.borrow_asset,
            opp.mids[0],
            opp.mids[1],
            opp.borrow_amount.toString(),
            "0",
          ],
          [],
          ARB_KEEPER_PACKAGE,
        );
      }
      const resp = await signAndSubmitTransaction(tx);
      toast(`Arb sent: ${String(resp.hash).slice(0, 12)}...`);
      setTimeout(() => scan(), 2000);
    } catch (e) {
      toast(`Execute failed: ${String((e as Error)?.message ?? e)}`, true);
    } finally {
      setExecutingIdx(null);
    }
  }

  const profitable = useMemo(() => opps.filter((o) => o.profitable), [opps]);
  const sinceLastScan = lastScan ? Math.floor((Date.now() - lastScan) / 1000) : 0;

  return (
    <div className="container">
      <div className="card">
        <div className="arb-header">
          <h2 style={{ margin: 0, fontSize: 18, color: "#ff8800" }}>
            Live Arb Opportunities
          </h2>
          <div className="arb-controls">
            <label className="arb-auto">
              <input
                type="checkbox"
                checked={auto}
                onChange={(e) => setAuto(e.target.checked)}
              />
              <span>Auto-refresh 30s</span>
            </label>
            <button
              type="button"
              className="btn"
              onClick={scan}
              disabled={loading}
              style={{ padding: "6px 12px" }}
            >
              {loading ? "Scanning…" : "Scan now"}
            </button>
          </div>
        </div>
        <div className="arb-stats">
          <span>
            {profitable.length} / {opps.length} profitable
          </span>
          <span>
            Last scan: {lastScan ? `${sinceLastScan}s ago` : "—"}
          </span>
        </div>

        {opps.length === 0 && loading && (
          <div className="empty">
            <div className="icon">&#9881;</div>
            Scanning…
          </div>
        )}

        {opps.length > 0 && (
          <div className="arb-table">
            <div className="arb-row arb-head">
              <span>Mode</span>
              <span>Path</span>
              <span>Size</span>
              <span>Gross Out</span>
              <span>Net (bps)</span>
              <span>Caller cut</span>
              <span />
            </div>
            {opps.map((o, idx) => {
              const legLabels = o.legs
                .map((l) => VENUE_LABEL[l.venue])
                .join(" → ");
              const pair = o.legs[0].pairKey;
              return (
                <div
                  key={`${o.mode}-${idx}-${o.borrow_amount}`}
                  className={`arb-row ${o.profitable ? "arb-ok" : "arb-bad"}`}
                >
                  <span>{o.mode}</span>
                  <span>
                    {pair} · {legLabels}
                  </span>
                  <span>{octasToApt(o.borrow_amount)} APT</span>
                  <span>{octasToApt(o.gross_out)}</span>
                  <span>{formatBps(o.profit_bps)}</span>
                  <span>
                    {o.profitable
                      ? `+${fromRaw(o.caller_cut, 8).toFixed(6)} APT`
                      : "—"}
                  </span>
                  <button
                    type="button"
                    className="btn btn-primary"
                    disabled={!o.profitable || !connected || executingIdx === idx}
                    onClick={() => execute(o, idx)}
                    style={{ padding: "4px 10px", fontSize: 11 }}
                  >
                    {executingIdx === idx ? "…" : "Fire"}
                  </button>
                </div>
              );
            })}
          </div>
        )}

        <div className="arb-footer">
          Scan fires ~{Math.ceil((opps.length || 1) * 1.3)} RPC calls per
          cycle. Profit split on-chain: 95 % caller / 5 % treasury. Keeper:{" "}
          <code>{ARB_KEEPER_PACKAGE.slice(0, 14)}...::keeper</code>
        </div>
      </div>
    </div>
  );
}
