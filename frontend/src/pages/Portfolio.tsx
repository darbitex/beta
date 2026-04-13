import { useWallet } from "@aptos-labs/wallet-adapter-react";
import { useEffect, useState } from "react";
import { fromRaw, viewFn } from "../chain/client";
import { loadPools, type Pool } from "../chain/pools";
import { buildEntryTx } from "../chain/tx";
import { useToast } from "../components/Toast";
import { RemoveLiquidityModal, type RemoveTarget } from "../components/RemoveLiquidityModal";
import { useAddress } from "../wallet/useConnect";

type Position = {
  objectAddr: string;
  poolAddr: string;
  shares: number;
  pendingA: number;
  pendingB: number;
  pool: Pool | null;
};

export function PortfolioPage() {
  const address = useAddress();
  const toast = useToast();
  const { connected, signAndSubmitTransaction } = useWallet();
  const [loading, setLoading] = useState(true);
  const [positions, setPositions] = useState<Position[]>([]);
  const [removeTarget, setRemoveTarget] = useState<RemoveTarget | null>(null);
  const [busy, setBusy] = useState<string | null>(null);

  useEffect(() => {
    let cancelled = false;
    async function run() {
      if (!address) {
        setPositions([]);
        setLoading(false);
        return;
      }
      setLoading(true);
      try {
        const pools = await loadPools();
        const poolMap = new Map<string, Pool>();
        for (const p of pools) poolMap.set(p.addr.toLowerCase(), p);

        const indexerUrl = "https://api.mainnet.aptoslabs.com/v1/graphql";
        const gqlRes = await fetch(indexerUrl, {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            query: `query($owner: String!) {
              current_objects(where: {owner_address: {_eq: $owner}, is_deleted: {_eq: false}}) {
                object_address
              }
            }`,
            variables: { owner: address },
          }),
        });
        const ownedAddrs: string[] = [];
        if (gqlRes.ok) {
          const gqlData = await gqlRes.json();
          const objs = gqlData?.data?.current_objects ?? [];
          for (const o of objs) ownedAddrs.push(o.object_address);
        }

        const rows: Position[] = [];
        await Promise.all(
          ownedAddrs.map(async (objAddr) => {
            try {
              const info = await viewFn<[string, string, string, string]>("pool::position_info", [], [objAddr]);
              const poolAddr = String(info[0]);
              const shares = Number(info[1]);
              const pending = await viewFn<[string, string]>("pool::pending_lp_fees", [], [objAddr]);
              rows.push({
                objectAddr: objAddr,
                poolAddr,
                shares,
                pendingA: Number(pending[0] ?? 0),
                pendingB: Number(pending[1] ?? 0),
                pool: poolMap.get(poolAddr.toLowerCase()) ?? null,
              });
            } catch {
              // Not an LpPosition — skip silently
            }
          }),
        );
        if (!cancelled) setPositions(rows);
      } finally {
        if (!cancelled) setLoading(false);
      }
    }
    run();
    return () => {
      cancelled = true;
    };
  }, [address]);

  async function claimFees(posAddr: string) {
    if (!connected) {
      toast("Connect wallet first", true);
      return;
    }
    setBusy(posAddr);
    try {
      const tx = buildEntryTx("pool", "claim_lp_fees_entry", [posAddr]);
      const resp = await signAndSubmitTransaction(tx);
      toast(`TX: ${String(resp.hash).slice(0, 12)}...`);
    } catch (e: unknown) {
      toast((e as Error)?.message ?? "TX failed", true);
    } finally {
      setBusy(null);
    }
  }

  if (!address) {
    return (
      <div className="container">
        <div className="empty">
          <div className="icon">&#128176;</div>
          Connect wallet to view LP positions
        </div>
      </div>
    );
  }

  if (loading) {
    return (
      <div className="container">
        <div className="empty">
          <div className="icon">&#9881;</div>
          Loading positions...
        </div>
      </div>
    );
  }

  if (positions.length === 0) {
    return (
      <div className="container">
        <div className="empty">
          <div className="icon">&#128167;</div>
          No LP positions found
        </div>
      </div>
    );
  }

  return (
    <div className="container">
      {positions.map((pos) => {
        const pool = pos.pool;
        const sA = pool?.token_a.symbol ?? "?";
        const sB = pool?.token_b.symbol ?? "?";
        const dA = pool?.token_a.decimals ?? 0;
        const dB = pool?.token_b.decimals ?? 0;
        const supply = pool ? Number(pool.lp_supply) : 0;
        const share = supply > 0 ? (pos.shares / supply) * 100 : 0;
        const valA = supply > 0 ? fromRaw((Number(pool!.reserve_a) * pos.shares) / supply, dA) : 0;
        const valB = supply > 0 ? fromRaw((Number(pool!.reserve_b) * pos.shares) / supply, dB) : 0;

        return (
          <div className="card" key={pos.objectAddr}>
            <div className="pool-pair">
              {sA}/{sB}
              <span className="badge badge-fee">LP NFT</span>
            </div>
            <div className="pool-grid">
              <div>
                <span className="label">Shares</span>
                <br />
                <span className="value">{pos.shares.toLocaleString()}</span>
              </div>
              <div>
                <span className="label">Pool Share</span>
                <br />
                <span className="value">{share.toFixed(2)}%</span>
              </div>
              <div>
                <span className="label">{sA} Value</span>
                <br />
                <span className="value">{valA.toFixed(4)}</span>
              </div>
              <div>
                <span className="label">{sB} Value</span>
                <br />
                <span className="value">{valB.toFixed(4)}</span>
              </div>
              <div>
                <span className="label">Pending {sA}</span>
                <br />
                <span className="value accent">{fromRaw(pos.pendingA, dA).toFixed(6)}</span>
              </div>
              <div>
                <span className="label">Pending {sB}</span>
                <br />
                <span className="value accent">{fromRaw(pos.pendingB, dB).toFixed(6)}</span>
              </div>
              <div>
                <span className="label">Position</span>
                <br />
                <span className="value mono">{pos.objectAddr.slice(0, 10)}...</span>
              </div>
              <div>
                <span className="label">Pool</span>
                <br />
                <span className="value mono">{pos.poolAddr.slice(0, 10)}...</span>
              </div>
            </div>
            <div className="pool-actions">
              <button
                type="button"
                className="btn btn-secondary"
                disabled={busy === pos.objectAddr}
                onClick={() => claimFees(pos.objectAddr)}
              >
                Claim Fees
              </button>
              <button
                type="button"
                className="btn btn-secondary"
                onClick={() => setRemoveTarget({ positionAddr: pos.objectAddr, pairLabel: `${sA}/${sB}`, pool: pos.pool, shares: pos.shares })}
              >
                Remove
              </button>
            </div>
          </div>
        );
      })}

      <RemoveLiquidityModal
        target={removeTarget}
        onClose={() => setRemoveTarget(null)}
        onDone={() => {
          const addr = removeTarget?.positionAddr;
          setRemoveTarget(null);
          setPositions((prev) => prev.filter((p) => p.objectAddr !== addr));
        }}
      />
    </div>
  );
}
