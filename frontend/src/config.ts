import { Network } from "@aptos-labs/ts-sdk";

export const PACKAGE = "0x2656e373ace5ccbc191aedaa65f12a50b9d4ea2b8e6f2d0166741994449c7ec2";
export const AGGREGATOR_PACKAGE = "0x838a981b43c5bf6fb1139a60ccd7851a4031cd31c775f71f963163c49ab62b47";
// ThalaSwap V2 adapter satellite — primitive-only wrapper around
// thalaswap_v2::pool preview/swap with FA-native interface. 3/5 multisig.
// See `darbitex_thala_adapter` memory for deployment record + pool registry.
export const THALA_ADAPTER_PACKAGE = "0x583d93de79a3f175f1e3751513b2be767f097376f22ea2e7a5aac331e60f206f";
// Arb keeper satellite — permissionless flash-loan arb executor across
// Darbitex / Hyperion / Thala. 2-leg (execute_arb) + 3-leg triangular
// (execute_triangular_arb) entry functions. Splits 95% caller / 5%
// treasury on-chain. Published to owner1 EOA (single-sig), compat
// upgrade policy. See `darbitex_arb_keeper` repo for source.
export const ARB_KEEPER_PACKAGE = "0x85d1e4047bde5c02b1915e5677b44ff5a6ba13452184d794da4658a4814efd30";
// Keeper venue enum — must match sources/keeper.move `VENUE_*` constants
export const VENUE_ID = {
  darbitex: 0,
  hyperion: 1,
  thala: 2,
} as const;

// Geomi (Aptos Labs developer portal) frontend API key. Domain-restricted
// server-side: the key is only accepted when the `Origin` header matches
// one of the whitelisted URLs on the Geomi dashboard (currently
// darbitex.wal.app + localhost variants). A leaked key from the public
// bundle is therefore useless to any attacker who can't fake the Origin
// from a browser — which is impossible in modern browsers because fetch()
// sets Origin automatically from the actual page origin.
//
// Rate limit on this key: 200 req / 5 min per IP on the Node API upstream
// (see Geomi dashboard > Per-IP Rate Limit Rules). Free tier is $10/mo in
// compute credits; at current darbitex scale this is effectively unlimited.
//
// Fallback: if Geomi ever returns 401/5xx, rotatedView falls through to
// the anonymous public endpoints below. Degraded UX (rate-limited), but
// functional, until Geomi recovers.
export const GEOMI_API_KEY = "AG-95EUWG1FUEIKI1QAG1EAAWFRFVQNOJURS";

export type RpcEndpoint = {
  url: string;
  // When set, these headers are baked into the Aptos SDK client config for
  // this endpoint. Used to inject Geomi's `Authorization: Bearer <key>`.
  headers?: Record<string, string>;
};

// Primary: Geomi-authenticated Node API. Our own quota bucket (~8M
// calls/month free tier), breaks the anonymous per-IP dependency that
// caused the 2026-04-11..14 rate-limit storms.
//
// Fallbacks: the same Aptos Labs hostnames as anonymous public access.
// These are worse under load (IP-penalized) but preserve graceful
// degradation if Geomi goes down.
export const RPC_LIST: RpcEndpoint[] = [
  {
    url: "https://api.mainnet.aptoslabs.com/v1",
    headers: { Authorization: `Bearer ${GEOMI_API_KEY}` },
  },
  { url: "https://fullnode.mainnet.aptoslabs.com/v1" },
  { url: "https://mainnet.aptoslabs.com/v1" },
];

// Legacy single-RPC export; points to the first entry URL. Some consumers
// may still import this directly. Prefer RPC_LIST + rotation for new code.
export const RPC = RPC_LIST[0].url;

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
