import { useEffect, useState } from "react";
import { fromRaw, viewFn } from "../chain/client";
import { loadPools, type Pool } from "../chain/pools";
import { PACKAGE } from "../config";

type ProtoState = {
  admin: string;
  treasury: string;
  revenue: string;
  factory: string;
  hookPrice: number;
  pools: Pool[];
  hookFees: Record<string, [number, number, number, number]>;
  stats: Record<string, { swaps: number; volA: string; volB: string }>;
};

function explorer(addr: string, label?: string) {
  return (
    <a
      href={`https://explorer.aptoslabs.com/account/${addr}?network=mainnet`}
      target="_blank"
      rel="noopener noreferrer"
    >
      {label ?? `${addr.slice(0, 10)}...${addr.slice(-6)}`}
    </a>
  );
}

export function ProtocolPage() {
  const [state, setState] = useState<ProtoState | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    async function run() {
      try {
        const [adminRes, treasuryRes, revenueRes, factoryRes, hookPriceRes] = await Promise.all([
          viewFn<[string]>("pool_factory::admin_address"),
          viewFn<[string]>("pool_factory::treasury_address"),
          viewFn<[string]>("pool_factory::revenue_address"),
          viewFn<[string]>("pool_factory::factory_address"),
          viewFn<[string]>("pool_factory::current_hook_price"),
        ]);
        const pools = await loadPools();
        const hookFees: Record<string, [number, number, number, number]> = {};
        const stats: Record<string, { swaps: number; volA: string; volB: string }> = {};
        for (const p of pools) {
          try {
            const f = await viewFn<[string, string, string, string]>("pool::hook_fee_buckets", [], [p.addr]);
            hookFees[p.addr] = [Number(f[0]), Number(f[1]), Number(f[2]), Number(f[3])];
          } catch {
            hookFees[p.addr] = [0, 0, 0, 0];
          }
          try {
            const s = await viewFn<[string, string, string]>("pool::total_stats", [], [p.addr]);
            stats[p.addr] = { swaps: Number(s[0]), volA: String(s[1]), volB: String(s[2]) };
          } catch {
            stats[p.addr] = { swaps: 0, volA: "0", volB: "0" };
          }
        }
        setState({
          admin: String(adminRes[0]),
          treasury: String(treasuryRes[0]),
          revenue: String(revenueRes[0]),
          factory: String(factoryRes[0]),
          hookPrice: Number(hookPriceRes[0]),
          pools,
          hookFees,
          stats,
        });
      } catch (e: unknown) {
        setError((e as Error)?.message ?? String(e));
      }
    }
    run();
  }, []);

  if (error)
    return (
      <div className="container">
        <div className="empty">
          <div className="icon">&#9888;</div>
          Failed to load protocol state: {error}
        </div>
      </div>
    );
  if (!state)
    return (
      <div className="container">
        <div className="empty">
          <div className="icon">&#9881;</div>
          Loading protocol state...
        </div>
      </div>
    );

  return (
    <div className="container">
      <div className="card">
        <div className="pool-pair">Protocol</div>
        <div className="pool-grid">
          <div>
            <span className="label">Package</span>
            <br />
            <span className="value mono">{explorer(PACKAGE)}</span>
          </div>
          <div>
            <span className="label">Factory</span>
            <br />
            <span className="value mono">{explorer(state.factory)}</span>
          </div>
          <div>
            <span className="label">Admin (3/5 msig)</span>
            <br />
            <span className="value mono">{explorer(state.admin)}</span>
          </div>
          <div>
            <span className="label">Treasury (2/3 msig)</span>
            <br />
            <span className="value mono">{explorer(state.treasury)}</span>
          </div>
          <div>
            <span className="label">Revenue</span>
            <br />
            <span className="value mono">{explorer(state.revenue)}</span>
          </div>
          <div>
            <span className="label">Pools</span>
            <br />
            <span className="value">{state.pools.length}</span>
          </div>
          <div>
            <span className="label">Hook Price</span>
            <br />
            <span className="value">{fromRaw(state.hookPrice, 8)} APT</span>
          </div>
          <div>
            <span className="label">Fee</span>
            <br />
            <span className="value">1 BPS (0.01%)</span>
          </div>
        </div>
      </div>

      {state.pools.map((p) => {
        const f = state.hookFees[p.addr] ?? [0, 0, 0, 0];
        const s = state.stats[p.addr] ?? { swaps: 0, volA: "0", volB: "0" };
        const sA = p.token_a.symbol;
        const sB = p.token_b.symbol;
        const dA = p.token_a.decimals;
        const dB = p.token_b.decimals;
        return (
          <div className="card" key={p.addr}>
            <div className="pool-pair">
              {sA}/{sB}
              <span className="badge badge-hook">2 HOOKS</span>
            </div>
            <div className="pool-grid">
              <div>
                <span className="label">Address</span>
                <br />
                <span className="value mono">{explorer(p.addr)}</span>
              </div>
              <div>
                <span className="label">LP Supply</span>
                <br />
                <span className="value">{Number(p.lp_supply).toLocaleString()}</span>
              </div>
              <div>
                <span className="label">Reserve {sA}</span>
                <br />
                <span className="value">{fromRaw(p.reserve_a, dA).toFixed(4)}</span>
              </div>
              <div>
                <span className="label">Reserve {sB}</span>
                <br />
                <span className="value">{fromRaw(p.reserve_b, dB).toFixed(4)}</span>
              </div>
              <div>
                <span className="label">Hook #1 fees {sA}</span>
                <br />
                <span className="value">{fromRaw(f[0], dA).toFixed(6)}</span>
              </div>
              <div>
                <span className="label">Hook #1 fees {sB}</span>
                <br />
                <span className="value">{fromRaw(f[1], dB).toFixed(6)}</span>
              </div>
              <div>
                <span className="label">Hook #2 fees {sA}</span>
                <br />
                <span className="value">{fromRaw(f[2], dA).toFixed(6)}</span>
              </div>
              <div>
                <span className="label">Hook #2 fees {sB}</span>
                <br />
                <span className="value">{fromRaw(f[3], dB).toFixed(6)}</span>
              </div>
              <div>
                <span className="label">Total Swaps</span>
                <br />
                <span className="value">{s.swaps.toLocaleString()}</span>
              </div>
              <div>
                <span className="label">Volume {sA}</span>
                <br />
                <span className="value">{fromRaw(s.volA, dA).toFixed(4)}</span>
              </div>
              <div>
                <span className="label">Volume {sB}</span>
                <br />
                <span className="value">{fromRaw(s.volB, dB).toFixed(4)}</span>
              </div>
            </div>
          </div>
        );
      })}
    </div>
  );
}
