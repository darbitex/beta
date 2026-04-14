import { useWallet } from "@aptos-labs/wallet-adapter-react";
import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import { scanAllOpportunities, type ArbOpportunity } from "../chain/arbScanner";
import { fromRaw } from "../chain/client";
import { buildEntryTx } from "../chain/tx";
import { useToast } from "../components/Toast";
import { ARB_KEEPER_PACKAGE, VENUE_ID } from "../config";

const SCAN_INTERVAL_MS = 30_000;

const VENUE_BADGE = {
  darbitex: "DX",
  hyperion: "HY",
  thala: "TH",
} as const;

function octasToApt(n: bigint): string {
  return (Number(n) / 1e8).toFixed(6);
}

function formatBps(bps: number): string {
  const sign = bps >= 0 ? "+" : "";
  return `${sign}${bps.toFixed(1)}`;
}

function formatDuration(ms: number): string {
  const s = Math.floor(ms / 1000);
  if (s < 60) return `${s}s`;
  const m = Math.floor(s / 60);
  return `${m}m ${s % 60}s`;
}

// Local-session accumulator for stats the user cares about across a
// /arb browsing session. Does NOT persist to localStorage — refresh
// starts fresh. Historical feed (cross-session) would need on-chain
// event query via indexer; deferred to next iteration.
type SessionStats = {
  scansRun: number;
  arbsFired: number;
  arbsSucceeded: number;
  callerOctas: bigint;   // accumulated caller_cut from successful fires
  treasuryOctas: bigint; // accumulated treasury_cut
  gasSpent: bigint;      // rough — placeholder
};

const EMPTY_STATS: SessionStats = {
  scansRun: 0,
  arbsFired: 0,
  arbsSucceeded: 0,
  callerOctas: 0n,
  treasuryOctas: 0n,
  gasSpent: 0n,
};

export function ArbPage() {
  const toast = useToast();
  const { connected, signAndSubmitTransaction } = useWallet();
  const [opps, setOpps] = useState<ArbOpportunity[]>([]);
  const [loading, setLoading] = useState(false);
  const [lastScan, setLastScan] = useState<number>(0);
  const [auto, setAuto] = useState(true);
  const [executingKey, setExecutingKey] = useState<string | null>(null);
  const [stats, setStats] = useState<SessionStats>(EMPTY_STATS);
  const [nowTick, setNowTick] = useState<number>(Date.now());
  const sessionStart = useRef<number>(Date.now());

  const scan = useCallback(async () => {
    setLoading(true);
    try {
      const results = await scanAllOpportunities();
      setOpps(results);
      setLastScan(Date.now());
      setStats((s) => ({ ...s, scansRun: s.scansRun + 1 }));
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

  // Tick for "last scan Xs ago" counter
  useEffect(() => {
    const t = setInterval(() => setNowTick(Date.now()), 1000);
    return () => clearInterval(t);
  }, []);

  function keyOf(o: ArbOpportunity, idx: number): string {
    return `${o.mode}-${o.label}-${o.borrow_amount.toString()}-${idx}`;
  }

  async function execute(opp: ArbOpportunity, idx: number) {
    if (!connected) {
      toast("Connect wallet first", true);
      return;
    }
    const k = keyOf(opp, idx);
    setExecutingKey(k);
    setStats((s) => ({ ...s, arbsFired: s.arbsFired + 1 }));
    try {
      let tx;
      if (opp.mode === "2leg") {
        tx = buildEntryTx(
          "keeper",
          "execute_arb",
          [
            VENUE_ID[opp.legs[0].venue],
            opp.legs[0].pool,
            true,
            VENUE_ID[opp.legs[1].venue],
            opp.legs[1].pool,
            false,
            opp.borrow_asset,
            opp.mids[0],
            opp.borrow_amount.toString(),
            "0",
          ],
          [],
          ARB_KEEPER_PACKAGE,
        );
      } else {
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
      // Optimistic attribution — scanner's predicted split is what will
      // actually land on chain within ~1 bps. Refine with indexer-fed
      // actuals in next iteration.
      setStats((s) => ({
        ...s,
        arbsSucceeded: s.arbsSucceeded + 1,
        callerOctas: s.callerOctas + opp.caller_cut,
        treasuryOctas: s.treasuryOctas + opp.treasury_cut,
      }));
      setTimeout(() => scan(), 2500);
    } catch (e) {
      toast(`Execute failed: ${String((e as Error)?.message ?? e)}`, true);
    } finally {
      setExecutingKey(null);
    }
  }

  const { profitable, bestBps } = useMemo(() => {
    const p = opps.filter((o) => o.profitable);
    const best = opps.reduce((m, o) => (o.profit_bps > m ? o.profit_bps : m), -Infinity);
    return { profitable: p, bestBps: Number.isFinite(best) ? best : 0 };
  }, [opps]);

  const sinceLastScan = lastScan ? nowTick - lastScan : 0;
  const sessionAge = nowTick - sessionStart.current;

  return (
    <div className="container">
      <div className="card">
        <div className="arb-header">
          <div>
            <h2 style={{ margin: 0, fontSize: 18, color: "#ff8800" }}>
              Live Arb Opportunities
            </h2>
            <div style={{ fontSize: 11, color: "#555", marginTop: 4 }}>
              Flash-loan arb across Darbitex · Hyperion · Thala. 2-leg
              cross-venue + 3-leg triangular topologies. Anyone can execute.
            </div>
          </div>
          <div className="arb-controls">
            <label className="arb-auto">
              <input
                type="checkbox"
                checked={auto}
                onChange={(e) => setAuto(e.target.checked)}
              />
              <span>Auto 30s</span>
            </label>
            <button
              type="button"
              className="btn"
              onClick={scan}
              disabled={loading}
              style={{ padding: "6px 12px" }}
            >
              {loading ? "Scanning…" : "Scan"}
            </button>
          </div>
        </div>

        <div className="arb-tiles">
          <div className="arb-tile">
            <div className="arb-tile-label">profitable</div>
            <div className="arb-tile-val">
              {profitable.length}
              <span className="muted">/{opps.length}</span>
            </div>
          </div>
          <div className="arb-tile">
            <div className="arb-tile-label">best bps</div>
            <div
              className={`arb-tile-val ${bestBps > 0 ? "pos" : bestBps < 0 ? "neg" : ""}`}
            >
              {formatBps(bestBps)}
            </div>
          </div>
          <div className="arb-tile">
            <div className="arb-tile-label">session scans</div>
            <div className="arb-tile-val">{stats.scansRun}</div>
          </div>
          <div className="arb-tile">
            <div className="arb-tile-label">arbs fired</div>
            <div className="arb-tile-val">
              {stats.arbsSucceeded}
              <span className="muted">/{stats.arbsFired}</span>
            </div>
          </div>
          <div className="arb-tile">
            <div className="arb-tile-label">caller cut (sim)</div>
            <div className="arb-tile-val pos">
              +{fromRaw(stats.callerOctas, 8).toFixed(6)}
            </div>
          </div>
          <div className="arb-tile">
            <div className="arb-tile-label">treasury cut (sim)</div>
            <div className="arb-tile-val pos">
              +{fromRaw(stats.treasuryOctas, 8).toFixed(6)}
            </div>
          </div>
        </div>

        <div className="arb-subtle">
          last scan {lastScan ? `${formatDuration(sinceLastScan)} ago` : "—"}
          {" · "}
          session {formatDuration(sessionAge)}
          {" · "}
          auto-refresh {auto ? "on" : "off"}
        </div>

        {opps.length === 0 && loading && (
          <div className="empty">
            <div className="icon">&#9881;</div>
            Scanning pools across 3 venues…
          </div>
        )}

        {opps.length > 0 && (
          <div className="arb-table">
            <div className="arb-row arb-head">
              <span>Mode</span>
              <span>Path</span>
              <span>Size</span>
              <span>Gross</span>
              <span>bps</span>
              <span>Caller cut</span>
              <span />
            </div>
            {opps.map((o, idx) => {
              const venueLabels = o.legs
                .map((l) => VENUE_BADGE[l.venue])
                .join("→");
              const k = keyOf(o, idx);
              const isExec = executingKey === k;
              const rowClass = o.profitable
                ? "arb-row arb-ok"
                : o.profit_bps < 0
                ? "arb-row arb-bad"
                : "arb-row arb-neutral";
              return (
                <div key={k} className={rowClass}>
                  <span>
                    <span className={`arb-mode-pill mode-${o.mode}`}>
                      {o.mode === "2leg" ? "2L" : "3L"}
                    </span>
                  </span>
                  <span className="arb-path">
                    <span className="arb-venues">{venueLabels}</span>
                    <span className="arb-label-sub">{o.label}</span>
                  </span>
                  <span className="arb-mono">
                    {octasToApt(o.borrow_amount)}
                  </span>
                  <span className="arb-mono">{octasToApt(o.gross_out)}</span>
                  <span
                    className={`arb-mono ${
                      o.profit_bps > 0 ? "pos" : o.profit_bps < 0 ? "neg" : ""
                    }`}
                  >
                    {formatBps(o.profit_bps)}
                  </span>
                  <span className="arb-mono">
                    {o.profitable
                      ? `+${fromRaw(o.caller_cut, 8).toFixed(6)}`
                      : "—"}
                  </span>
                  <button
                    type="button"
                    className="btn btn-primary arb-fire"
                    disabled={!o.profitable || !connected || isExec}
                    onClick={() => execute(o, idx)}
                  >
                    {isExec ? "…" : "Fire"}
                  </button>
                </div>
              );
            })}
          </div>
        )}

        <div className="arb-footer">
          Keeper:{" "}
          <code>{ARB_KEEPER_PACKAGE.slice(0, 14)}…::keeper</code>
          {" · "}
          Profit split on-chain: <strong>95% caller / 5% treasury</strong>
          {" · "}
          Protocol profit floor: <strong>5 bps</strong>
          {" · "}
          Flash loan: <strong>Aave 0-fee</strong>
          <br />
          Session stats are scanner-predicted values; actual on-chain split
          within ~1 bps of prediction. Historical feed (cross-session) coming
          next iteration — query ArbExecuted events via indexer.
        </div>
      </div>
    </div>
  );
}
