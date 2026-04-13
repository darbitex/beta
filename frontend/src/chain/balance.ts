import { useCallback, useEffect, useState } from "react";
import { aptos, fromRaw } from "./client";
import { useAddress } from "../wallet/useConnect";

export async function fetchFaBalance(owner: string, metadata: string): Promise<bigint> {
  try {
    const res = await aptos.view({
      payload: {
        function: "0x1::primary_fungible_store::balance",
        typeArguments: ["0x1::fungible_asset::Metadata"],
        functionArguments: [owner, metadata],
      },
    });
    return BigInt(String(res[0] ?? "0"));
  } catch {
    return 0n;
  }
}

export type FaBalanceState = {
  raw: bigint;
  formatted: number;
  loading: boolean;
  refresh: () => void;
};

export function useFaBalance(metadata: string | null, decimals: number): FaBalanceState {
  const address = useAddress();
  const [raw, setRaw] = useState<bigint>(0n);
  const [loading, setLoading] = useState(false);
  const [tick, setTick] = useState(0);

  const refresh = useCallback(() => setTick((t) => t + 1), []);

  useEffect(() => {
    let cancelled = false;
    if (!address || !metadata) {
      setRaw(0n);
      return;
    }
    setLoading(true);
    fetchFaBalance(address, metadata)
      .then((b) => {
        if (!cancelled) setRaw(b);
      })
      .finally(() => {
        if (!cancelled) setLoading(false);
      });
    return () => {
      cancelled = true;
    };
  }, [address, metadata, tick]);

  return { raw, formatted: fromRaw(raw, decimals), loading, refresh };
}
