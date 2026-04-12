import { useWallet } from "@aptos-labs/wallet-adapter-react";
import { useEffect, useState } from "react";
import { fromRaw, viewFn } from "../chain/client";
import { loadPools, type Pool } from "../chain/pools";
import { buildEntryTx } from "../chain/tx";
import { useToast } from "../components/Toast";

type HookListing = {
  pool: Pool;
  listed: boolean;
  price: number;
  hookFees: { h1_a: number; h1_b: number; h2_a: number; h2_b: number };
};

export function HooksPage() {
  const toast = useToast();
  const { connected, signAndSubmitTransaction } = useWallet();
  const [listings, setListings] = useState<HookListing[]>([]);
  const [loading, setLoading] = useState(true);
  const [busy, setBusy] = useState<string | null>(null);

  async function reload() {
    setLoading(true);
    try {
      const pools = await loadPools();
      const items: HookListing[] = [];
      for (const pool of pools) {
        try {
          const [listedRes, feesRes] = await Promise.all([
            viewFn<[boolean]>("pool_factory::is_hook_listed", [], [pool.addr]),
            viewFn<[string, string, string, string]>("pool::hook_fee_buckets", [], [pool.addr]),
          ]);
          const listed = Boolean(listedRes[0]);
          let price = 0;
          if (listed) {
            const priceRes = await viewFn<[string]>("pool_factory::hook_listing_price", [], [pool.addr]);
            price = Number(priceRes[0] ?? 0);
          }
          items.push({
            pool,
            listed,
            price,
            hookFees: {
              h1_a: Number(feesRes[0] ?? 0),
              h1_b: Number(feesRes[1] ?? 0),
              h2_a: Number(feesRes[2] ?? 0),
              h2_b: Number(feesRes[3] ?? 0),
            },
          });
        } catch (e) {
          console.error("hook listing load failed", pool.addr, e);
        }
      }
      setListings(items);
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    reload();
  }, []);

  async function buyHook(poolAddr: string) {
    if (!connected) {
      toast("Connect wallet first", true);
      return;
    }
    setBusy(poolAddr);
    try {
      const tx = buildEntryTx("pool_factory", "buy_hook", [poolAddr]);
      const resp = await signAndSubmitTransaction(tx);
      toast(`TX: ${String(resp.hash).slice(0, 12)}...`);
      setTimeout(reload, 3000);
    } catch (e: unknown) {
      toast((e as Error)?.message ?? "TX failed", true);
    } finally {
      setBusy(null);
    }
  }

  async function claimHookFees(nftAddr: string) {
    if (!connected) {
      toast("Connect wallet first", true);
      return;
    }
    setBusy(nftAddr);
    try {
      const tx = buildEntryTx("pool", "claim_hook_fees_entry", [nftAddr]);
      const resp = await signAndSubmitTransaction(tx);
      toast(`TX: ${String(resp.hash).slice(0, 12)}...`);
      setTimeout(reload, 3000);
    } catch (e: unknown) {
      toast((e as Error)?.message ?? "TX failed", true);
    } finally {
      setBusy(null);
    }
  }

  if (loading) {
    return (
      <div className="container">
        <div className="empty">
          <div className="icon">&#9881;</div>
          Loading hooks...
        </div>
      </div>
    );
  }

  return (
    <div className="container">
      <div className="card">
        <div className="pool-pair">Hook NFT Marketplace</div>
        <div className="modal-note" style={{ margin: "8px 0" }}>
          Every pool mints 2 HookNFTs at birth. Slot 0 is treasury (soulbound). Slot 1 is listed here at a fixed price. Buy to earn 50% of hook fees.
        </div>
      </div>

      {listings.map((item) => {
        const { pool, listed, price, hookFees } = item;
        const sA = pool.token_a.symbol;
        const sB = pool.token_b.symbol;
        const dA = pool.token_a.decimals;
        const dB = pool.token_b.decimals;
        return (
          <div className="card" key={pool.addr}>
            <div className="pool-pair">
              {sA}/{sB}
              {listed ? (
                <span className="badge badge-hook">FOR SALE</span>
              ) : (
                <span className="badge badge-fee">SOLD</span>
              )}
            </div>
            <div className="pool-grid">
              {listed && (
                <div>
                  <span className="label">Price</span>
                  <br />
                  <span className="value">{fromRaw(price, 8).toFixed(2)} APT</span>
                </div>
              )}
              <div>
                <span className="label">Hook #1 fees ({sA})</span>
                <br />
                <span className="value">{fromRaw(hookFees.h1_a, dA).toFixed(6)}</span>
              </div>
              <div>
                <span className="label">Hook #1 fees ({sB})</span>
                <br />
                <span className="value">{fromRaw(hookFees.h1_b, dB).toFixed(6)}</span>
              </div>
              <div>
                <span className="label">Hook #2 fees ({sA})</span>
                <br />
                <span className="value">{fromRaw(hookFees.h2_a, dA).toFixed(6)}</span>
              </div>
              <div>
                <span className="label">Hook #2 fees ({sB})</span>
                <br />
                <span className="value">{fromRaw(hookFees.h2_b, dB).toFixed(6)}</span>
              </div>
              <div>
                <span className="label">NFT #1 (treasury)</span>
                <br />
                <span className="value mono">{pool.hook_nft_1.slice(0, 10)}...</span>
              </div>
              <div>
                <span className="label">NFT #2</span>
                <br />
                <span className="value mono">{pool.hook_nft_2.slice(0, 10)}...</span>
              </div>
            </div>
            <div className="pool-actions">
              {listed && (
                <button
                  type="button"
                  className="btn btn-primary"
                  style={{ flex: 1, padding: "10px 16px", fontSize: 13 }}
                  disabled={busy === pool.addr}
                  onClick={() => buyHook(pool.addr)}
                >
                  {busy === pool.addr ? "Buying..." : `Buy Hook (${fromRaw(price, 8)} APT)`}
                </button>
              )}
              <button
                type="button"
                className="btn btn-secondary"
                disabled={busy === pool.hook_nft_1}
                onClick={() => claimHookFees(pool.hook_nft_1)}
              >
                Claim #1
              </button>
              <button
                type="button"
                className="btn btn-secondary"
                disabled={busy === pool.hook_nft_2}
                onClick={() => claimHookFees(pool.hook_nft_2)}
              >
                Claim #2
              </button>
            </div>
          </div>
        );
      })}
    </div>
  );
}
