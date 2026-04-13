import { useWallet } from "@aptos-labs/wallet-adapter-react";
import { useEffect, useMemo, useState } from "react";
import { aggregateQuotes, type AggregatorResult, type Quote, type Venue } from "../chain/aggregator";
import { useFaBalance } from "../chain/balance";
import { fromRaw, metaEq, normMeta, toRaw } from "../chain/client";
import { findPool, loadPools, type Pool } from "../chain/pools";
import { useSlippage } from "../chain/slippage";
import { buildEntryTx } from "../chain/tx";
import { useToast } from "../components/Toast";
import { AGGREGATOR_PACKAGE, QUOTE_DEBOUNCE_MS, TOKENS, type TokenConfig } from "../config";

type Mode = "swap" | "aggregator";

const VENUE_LABEL: Record<Venue, string> = {
  darbitex: "Darbitex",
  hyperion: "Hyperion",
  liquidswap_stable: "LiquidSwap",
  cellana: "Cellana",
};

// Build the token universe from (a) hardcoded TOKENS in config and (b) any
// token that appears in a live Darbitex pool. Deduped by metadata address.
// If two tokens share a symbol (e.g. nUSDC and lzUSDC both symbol "USDC"),
// append a short meta suffix to the label to disambiguate.
function buildAvailableTokens(pools: Pool[]): TokenConfig[] {
  const map = new Map<string, TokenConfig>();
  for (const t of Object.values(TOKENS)) map.set(normMeta(t.meta), t);
  for (const p of pools) {
    const a = normMeta(p.token_a.meta);
    const b = normMeta(p.token_b.meta);
    if (!map.has(a)) map.set(a, p.token_a);
    if (!map.has(b)) map.set(b, p.token_b);
  }
  return Array.from(map.values()).sort((x, y) =>
    x.symbol.localeCompare(y.symbol),
  );
}

function tokenLabel(t: TokenConfig, all: TokenConfig[]): string {
  const sameSymbol = all.filter((o) => o.symbol === t.symbol);
  if (sameSymbol.length <= 1) return t.symbol;
  return `${t.symbol} · ${t.meta.slice(2, 6)}`;
}

export function SwapPage() {
  const toast = useToast();
  const { connected, signAndSubmitTransaction } = useWallet();
  const [slippage] = useSlippage();
  const [mode, setMode] = useState<Mode>("swap");
  const [pools, setPools] = useState<Pool[]>([]);
  const [inMeta, setInMeta] = useState<string>(TOKENS.APT.meta);
  const [outMeta, setOutMeta] = useState<string>(TOKENS.USDC.meta);
  const [amount, setAmount] = useState("");
  const [darbitexPool, setDarbitexPool] = useState<Pool | null>(null);
  const [darbitexAToB, setDarbitexAToB] = useState(true);
  const [agg, setAgg] = useState<AggregatorResult | null>(null);
  const [aggLoading, setAggLoading] = useState(false);
  const [selectedVenue, setSelectedVenue] = useState<Venue | null>(null);
  const [busy, setBusy] = useState(false);

  useEffect(() => {
    loadPools().then(setPools).catch((e) => toast(`Load pools: ${String(e?.message ?? e)}`, true));
  }, [toast]);

  // Token universe = hardcoded TOKENS + unique tokens from loaded pools.
  // Grows as pools are loaded so freshly-created pools (e.g. lzUSDC) show
  // up without a frontend redeploy.
  const availableTokens = useMemo(() => buildAvailableTokens(pools), [pools]);

  const tIn: TokenConfig = useMemo(
    () => availableTokens.find((t) => metaEq(t.meta, inMeta)) ?? TOKENS.APT!,
    [availableTokens, inMeta],
  );
  const tOut: TokenConfig = useMemo(
    () => availableTokens.find((t) => metaEq(t.meta, outMeta)) ?? TOKENS.USDC!,
    [availableTokens, outMeta],
  );

  const amountNum = Number.parseFloat(amount);
  const balIn = useFaBalance(tIn.meta, tIn.decimals);
  const balOut = useFaBalance(tOut.meta, tOut.decimals);

  // Track darbitex pool context separately so both modes can use it.
  useEffect(() => {
    if (!pools.length || metaEq(inMeta, outMeta)) {
      setDarbitexPool(null);
      return;
    }
    const pool = findPool(pools, tIn.meta, tOut.meta);
    if (!pool) {
      setDarbitexPool(null);
      return;
    }
    setDarbitexPool(pool);
    setDarbitexAToB(metaEq(pool.meta_a, tIn.meta));
  }, [pools, inMeta, outMeta, tIn, tOut]);

  // Fetch quotes whenever inputs change. Debounced so rapid typing doesn't
  // burst the RPC pool — only the last stable input within the debounce window
  // actually fires view calls.
  useEffect(() => {
    if (!amountNum || amountNum <= 0 || metaEq(inMeta, outMeta)) {
      setAgg(null);
      setSelectedVenue(null);
      setAggLoading(false);
      return;
    }
    let cancelled = false;
    setAggLoading(true);
    const timer = setTimeout(async () => {
      if (cancelled) return;
      const rawIn = toRaw(amountNum, tIn.decimals);
      try {
        const result = await aggregateQuotes({
          tokenIn: tIn,
          tokenOut: tOut,
          amountInRaw: rawIn,
          darbitexPool: darbitexPool?.addr ?? null,
          darbitexAToB,
        });
        if (cancelled) return;
        setAgg(result);
        if (mode === "swap") {
          setSelectedVenue(result.darbitex ? "darbitex" : null);
        } else {
          setSelectedVenue(result.best?.venue ?? null);
        }
      } catch (e) {
        if (!cancelled) {
          console.error(e);
          setAgg(null);
          setSelectedVenue(null);
        }
      } finally {
        if (!cancelled) setAggLoading(false);
      }
    }, QUOTE_DEBOUNCE_MS);
    return () => {
      cancelled = true;
      clearTimeout(timer);
    };
  }, [amountNum, inMeta, outMeta, tIn, tOut, darbitexPool, darbitexAToB, mode]);

  const activeQuote: Quote | null = useMemo(() => {
    if (!agg || !selectedVenue) return null;
    if (selectedVenue === "darbitex") return agg.darbitex;
    if (selectedVenue === "hyperion") return agg.hyperion;
    if (selectedVenue === "liquidswap_stable") return agg.liquidswapStable;
    return agg.cellana;
  }, [agg, selectedVenue]);

  const amountOutFormatted = activeQuote
    ? fromRaw(activeQuote.amountOutRaw, tOut.decimals)
    : 0;

  const disabled = !connected || !activeQuote || busy;
  const btnLabel = useMemo(() => {
    if (!amountNum || amountNum <= 0) return "Enter amount";
    if (metaEq(inMeta, outMeta)) return "Select different tokens";
    if (aggLoading) return "Quoting...";
    if (!activeQuote) return "No route";
    if (!connected) return "Connect wallet";
    if (busy) return "Submitting...";
    return mode === "swap" ? "Swap" : `Swap via ${VENUE_LABEL[activeQuote.venue]}`;
  }, [amountNum, inMeta, outMeta, activeQuote, connected, busy, aggLoading, mode]);

  async function doSwap() {
    if (!activeQuote) return;
    setBusy(true);
    try {
      const rawIn = toRaw(amountNum, tIn.decimals);
      const minOut = toRaw(amountOutFormatted * (1 - slippage), tOut.decimals);
      const deadline = Math.floor(Date.now() / 1000) + 120;

      let tx;
      if (activeQuote.venue === "darbitex") {
        // Mode "swap" uses the core router directly (fewer hops, lower gas).
        // Mode "aggregator" with darbitex winner uses aggregator::swap_darbitex
        // so the namespace is consistent with the other venues.
        if (mode === "swap") {
          tx = buildEntryTx("router", "swap_with_deadline", [
            activeQuote.darbitexPool!,
            tIn.meta,
            rawIn.toString(),
            minOut.toString(),
            deadline.toString(),
          ]);
        } else {
          tx = buildEntryTx(
            "aggregator",
            "swap_darbitex",
            [
              activeQuote.darbitexPool!,
              tIn.meta,
              rawIn.toString(),
              minOut.toString(),
              deadline.toString(),
            ],
            [],
            AGGREGATOR_PACKAGE,
          );
        }
      } else if (activeQuote.venue === "hyperion") {
        // Hyperion a_to_b: true iff input meta sorts before output meta lexicographically.
        const aToB = tIn.meta.toLowerCase() < tOut.meta.toLowerCase();
        tx = buildEntryTx(
          "aggregator",
          "swap_hyperion",
          [
            activeQuote.hyperionPool!,
            tIn.meta,
            aToB,
            rawIn.toString(),
            minOut.toString(),
            deadline.toString(),
          ],
          [],
          AGGREGATOR_PACKAGE,
        );
      } else if (activeQuote.venue === "liquidswap_stable") {
        tx = buildEntryTx(
          "aggregator",
          "swap_liquidswap_stable",
          [tIn.meta, rawIn.toString(), minOut.toString(), deadline.toString()],
          activeQuote.liquidswapTypes ?? [],
          AGGREGATOR_PACKAGE,
        );
      } else {
        // cellana
        tx = buildEntryTx(
          "aggregator",
          "swap_cellana",
          [
            tIn.meta,
            tOut.meta,
            activeQuote.cellanaIsStable ?? false,
            rawIn.toString(),
            minOut.toString(),
            deadline.toString(),
          ],
          [],
          AGGREGATOR_PACKAGE,
        );
      }

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
    const prev = inMeta;
    setInMeta(outMeta);
    setOutMeta(prev);
  }

  const rate = amountNum > 0 && activeQuote
    ? amountOutFormatted / amountNum
    : 0;

  return (
    <div className="container">
      <div className="card">
        <div className="mode-tabs">
          <button
            type="button"
            className={`mode-tab${mode === "swap" ? " active" : ""}`}
            onClick={() => setMode("swap")}
          >
            Swap
          </button>
          <button
            type="button"
            className={`mode-tab${mode === "aggregator" ? " active" : ""}`}
            onClick={() => setMode("aggregator")}
          >
            Aggregator
          </button>
        </div>

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
              Balance: {balIn.loading ? "…" : balIn.formatted.toFixed(6)} {tIn.symbol}
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
          <select
            className="token-select"
            value={inMeta}
            onChange={(e) => setInMeta(e.target.value)}
          >
            {availableTokens.map((t) => (
              <option key={t.meta} value={t.meta}>
                {tokenLabel(t, availableTokens)}
              </option>
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
              Balance: {balOut.loading ? "…" : balOut.formatted.toFixed(6)} {tOut.symbol}
            </span>
          )}
        </div>
        <div className="swap-row">
          <input
            className="swap-input"
            type="number"
            placeholder="0.0"
            value={activeQuote ? amountOutFormatted.toFixed(6) : ""}
            readOnly
          />
          <select
            className="token-select"
            value={outMeta}
            onChange={(e) => setOutMeta(e.target.value)}
          >
            {availableTokens.map((t) => (
              <option key={t.meta} value={t.meta}>
                {tokenLabel(t, availableTokens)}
              </option>
            ))}
          </select>
        </div>

        {mode === "aggregator" && agg && (
          <div className="venue-list">
            <div className="venue-list-title">Routes</div>
            <VenueRow
              label="Darbitex"
              quote={agg.darbitex}
              decimals={tOut.decimals}
              isBest={agg.best?.venue === "darbitex"}
              selected={selectedVenue === "darbitex"}
              onSelect={() => agg.darbitex && setSelectedVenue("darbitex")}
            />
            <VenueRow
              label="Hyperion"
              quote={agg.hyperion}
              decimals={tOut.decimals}
              isBest={agg.best?.venue === "hyperion"}
              selected={selectedVenue === "hyperion"}
              onSelect={() => agg.hyperion && setSelectedVenue("hyperion")}
            />
            <VenueRow
              label="LiquidSwap"
              quote={agg.liquidswapStable}
              decimals={tOut.decimals}
              isBest={agg.best?.venue === "liquidswap_stable"}
              selected={selectedVenue === "liquidswap_stable"}
              onSelect={() => agg.liquidswapStable && setSelectedVenue("liquidswap_stable")}
            />
            <VenueRow
              label="Cellana"
              quote={agg.cellana}
              decimals={tOut.decimals}
              isBest={agg.best?.venue === "cellana"}
              selected={selectedVenue === "cellana"}
              onSelect={() => agg.cellana && setSelectedVenue("cellana")}
            />
            {agg.best && (
              <div className="venue-row best-external">
                <span className="venue-label">BEST EXTERNAL</span>
                <span className="venue-amount">
                  {fromRaw(agg.best.amountOutRaw, tOut.decimals).toFixed(6)} {tOut.symbol}
                </span>
                <span className="venue-tag">{VENUE_LABEL[agg.best.venue]}</span>
              </div>
            )}
          </div>
        )}

        {activeQuote && (
          <div className="swap-info">
            <div>
              <span>Route</span>
              <span className="val">{VENUE_LABEL[activeQuote.venue]}</span>
            </div>
            <div>
              <span>Rate</span>
              <span className="val">
                1 {tIn.symbol} = {rate > 0 ? rate.toFixed(6) : "—"} {tOut.symbol}
              </span>
            </div>
            <div>
              <span>Slippage</span>
              <span className="val">{(slippage * 100).toFixed(slippage < 0.01 ? 2 : 1)}%</span>
            </div>
            <div>
              <span>Min received</span>
              <span className="val">
                {(amountOutFormatted * (1 - slippage)).toFixed(6)} {tOut.symbol}
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

function VenueRow({
  label,
  quote,
  decimals,
  isBest,
  selected,
  onSelect,
}: {
  label: string;
  quote: Quote | null;
  decimals: number;
  isBest: boolean;
  selected: boolean;
  onSelect: () => void;
}) {
  const available = quote !== null;
  const amount = quote ? fromRaw(quote.amountOutRaw, decimals) : 0;
  return (
    <button
      type="button"
      className={`venue-row${selected ? " selected" : ""}${available ? "" : " unavailable"}`}
      onClick={onSelect}
      disabled={!available}
    >
      <span className="venue-label">{label}</span>
      <span className="venue-amount">
        {available ? amount.toFixed(6) : "—"}
      </span>
      {isBest && <span className="venue-tag best">BEST</span>}
    </button>
  );
}
