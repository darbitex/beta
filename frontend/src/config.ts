import { Network } from "@aptos-labs/ts-sdk";

export const PACKAGE = "0x2656e373ace5ccbc191aedaa65f12a50b9d4ea2b8e6f2d0166741994449c7ec2";
export const AGGREGATOR_PACKAGE = "0x838a981b43c5bf6fb1139a60ccd7851a4031cd31c775f71f963163c49ab62b47";

// Public Aptos RPC pool — verified 2026-04-13 for chain_id=1 and POST /view.
// Client rotates round-robin per request to spread load and improve resilience.
// All endpoints are free, unauthenticated, and per-IP rate-limited on the
// caller side (preserves the decentralized "each user brings own budget"
// model — no shared paid quota).
// Polkachu was dropped 2026-04-13: their CORS preflight returns two
// `Access-Control-Allow-Origin` headers (specific + wildcard), which
// violates the spec and causes browsers to reject the response with
// "TypeError: Failed to fetch". Aptos Labs' three hostnames have clean
// CORS and are currently the only viable public browser-callable options.
//
// 3rd-party RPC landscape verified 2026-04-14 (all failed): Nodit,
// NodeReal, BlastAPI, AllThatNode → require API key; Ankr, Tatum,
// publicnode.com → different API shape (JSON-RPC not REST); llamarpc,
// chainbase, omnia → DNS/reachability failures. No viable browser-
// callable 3rd-party public Aptos mainnet REST endpoint exists. The
// real fix is a CloudFlare Worker proxy (see roadmap) — these 3 Aptos
// Labs hostnames are the interim best-effort.
export const RPC_LIST: string[] = [
  "https://fullnode.mainnet.aptoslabs.com/v1",
  "https://api.mainnet.aptoslabs.com/v1",
  "https://mainnet.aptoslabs.com/v1",
];

// Legacy single-RPC export; points to the first entry. Some consumers may
// still import this directly. Prefer RPC_LIST + rotation for new code.
export const RPC = RPC_LIST[0];

export const NETWORK = Network.MAINNET;
export const SLIPPAGE = 0.005;

// Aggregator quote debounce (ms). Waits this long after input stops changing
// before firing the parallel view calls. Tuned conservatively — on a heavily
// rate-limited IP (dev laptop with past bot traffic) every burst counts, so
// we let the user pause briefly before firing quotes. Raised from 1500 to
// 2000 on 2026-04-14 after observing rate-limit storms still surviving the
// semaphore on aggressive typing.
export const QUOTE_DEBOUNCE_MS = 2000;

// Hyperion CLMM: we only query tier 1 (5 bps). Tier enumeration across all
// six valid u8 values was retired 2026-04-14 — verified on mainnet that only
// tier 1 holds meaningful liquidity, the other five are dust or empty, so
// burning 18 RPC calls per quote to discover what we already know is wasted
// budget. If a new tier becomes liquid later, bump this constant or expand
// back to enumeration.
export const HYPERION_ACTIVE_TIER = 1;

export type TokenConfig = {
  meta: string;
  decimals: number;
  symbol: string;
  // Optional Coin type string for LiquidSwap generic calls (e.g. "0x1::aptos_coin::AptosCoin").
  // Only tokens with a known Coin wrapper need this. LiquidSwap routing is skipped
  // for tokens that leave this undefined.
  coinType?: string;
};

export const TOKENS: Record<string, TokenConfig> = {
  APT: {
    meta: "0x000000000000000000000000000000000000000000000000000000000000000a",
    decimals: 8,
    symbol: "APT",
    coinType: "0x1::aptos_coin::AptosCoin",
  },
  USDC: {
    meta: "0xbae207659db88bea0cbead6da0ed00aac12edcdda169e591cd41c94180b46f3b",
    decimals: 6,
    symbol: "USDC",
  },
  USDt: {
    meta: "0x357b0b74bc833e95a115ad22604854d6b0fca151cecd94111770e5d6ffc9dc2b",
    decimals: 6,
    symbol: "USDt",
  },
  lzUSDC: {
    // Framework-paired canonical FA for the LayerZero USDC coin type.
    meta: "0x2b3be0a97a73c87ff62cbdd36837a9fb5bbd1d7f06a73b7ed62ec15c5326c1b8",
    decimals: 6,
    symbol: "lzUSDC",
    coinType: "0xf22bede237a07e121b56d91a491eb7bcdfd1f5907926a9e58338f964a01b17fa::asset::USDC",
  },
};
