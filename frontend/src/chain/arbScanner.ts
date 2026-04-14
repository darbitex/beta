// Arb opportunity scanner. Queries live chain state from 3 venues
// (Darbitex, Hyperion, Thala), simulates 2-leg + 3-leg paths for a
// small set of pair/size combinations, and returns ranked
// opportunities. UI at /arb consumes this.
//
// RPC budget-aware: each scan cycle fires ~20-30 view calls (well
// within Geomi 200/5min limit). Debounced, not continuous.

import { AGGREGATOR_PACKAGE, THALA_ADAPTER_PACKAGE } from "../config";
import { viewFn } from "./client";

// ===== Pool registry =====

// Metadata addresses (native FA)
export const META = {
  APT: "0x000000000000000000000000000000000000000000000000000000000000000a",
  USDC: "0xbae207659db88bea0cbead6da0ed00aac12edcdda169e591cd41c94180b46f3b",
  USDt: "0x357b0b74bc833e95a115ad22604854d6b0fca151cecd94111770e5d6ffc9dc2b",
} as const;

// Pool registry per (venue, pair). Pair key is canonical "A/B" with
// A < B lex order so lookups are stable. Add entries here when new
// pools open or new venues join.
export type VenueKey = "darbitex" | "hyperion" | "thala";
type PoolMap = Partial<Record<VenueKey, string>>;

export const POOL_REGISTRY: Record<string, PoolMap> = {
  "APT/USDC": {
    darbitex: "0x69a3913973d7009aa687d2f542363690937da74ea94c953853dd81004db0e2af",
    hyperion: "0x925660b8618394809f89f8002e2926600c775221f43bf1919782b297a79400d8",
    thala:    "0xa928222429caf1924c944973c2cd9fc306ec41152ba4de27a001327021a4dff7",
  },
  "APT/USDt": {
    darbitex: "0xe0824bf4e29f430266bc93a1a16f62b26aef82a7a1029b2a6562e31f6bf59256",
    hyperion: "0x18269b1090d668fbbc01902fa6a5ac6e75565d61860ddae636ac89741c883cbc",
    thala:    "0x99d34f16193e251af236d5a5c3114fa54e22ca512280317eda2f8faf1514c395",
  },
  "USDt/USDC": {
    darbitex: "0xa540e3e43e91f46fd0d8e03bd57d14491244dbbc511b23be53dbe3611894329e",
  },
};

export const PAIR_ASSETS: Record<string, { a: string; b: string }> = {
  "APT/USDC": { a: META.APT, b: META.USDC },
  "APT/USDt": { a: META.APT, b: META.USDt },
  "USDt/USDC": { a: META.USDt, b: META.USDC },
};

// ===== Quote helpers per venue =====

async function quoteDarbitex(poolAddr: string, metaIn: string, amountIn: bigint): Promise<bigint> {
  // Darbitex has no aggregator view — compute from reserves + 1 bps fee.
  try {
    const [reservesRes, tokensRes] = await Promise.all([
      viewFn<[string, string]>("pool::reserves", [], [poolAddr]),
      viewFn<[unknown, unknown]>("pool::pool_tokens", [], [poolAddr]),
    ]);
    const metaA = extractInner(tokensRes[0]).toLowerCase();
    const ra = BigInt(String(reservesRes[0]));
    const rb = BigInt(String(reservesRes[1]));
    const inIsA = metaIn.toLowerCase() === metaA;
    const rIn = inIsA ? ra : rb;
    const rOut = inIsA ? rb : ra;
    // 1 bps fee, constant product
    const xInEff = (amountIn * 9999n) / 10000n;
    return (rOut * xInEff) / (rIn + xInEff);
  } catch {
    return 0n;
  }
}

async function quoteHyperion(poolAddr: string, metaIn: string, amountIn: bigint): Promise<bigint> {
  try {
    const res = await viewFn<[string | number]>(
      "aggregator::quote_hyperion",
      [],
      [poolAddr, metaIn, amountIn.toString()],
      AGGREGATOR_PACKAGE,
    );
    return BigInt(String(res[0] ?? "0"));
  } catch {
    return 0n;
  }
}

async function quoteThala(poolAddr: string, metaIn: string, metaOut: string, amountIn: bigint): Promise<bigint> {
  try {
    const res = await viewFn<[string | number]>(
      "adapter::quote",
      [],
      [poolAddr, metaIn, metaOut, amountIn.toString()],
      THALA_ADAPTER_PACKAGE,
    );
    return BigInt(String(res[0] ?? "0"));
  } catch {
    return 0n;
  }
}

function extractInner(x: unknown): string {
  if (x && typeof x === "object" && "inner" in (x as Record<string, unknown>)) {
    return String((x as { inner: unknown }).inner);
  }
  return String(x);
}

async function quoteVenue(
  venue: VenueKey,
  poolAddr: string,
  metaIn: string,
  metaOut: string,
  amountIn: bigint,
): Promise<bigint> {
  if (venue === "darbitex") return quoteDarbitex(poolAddr, metaIn, amountIn);
  if (venue === "hyperion") return quoteHyperion(poolAddr, metaIn, amountIn);
  if (venue === "thala")    return quoteThala(poolAddr, metaIn, metaOut, amountIn);
  return 0n;
}

// ===== Profit math (mirror of keeper::compute_split) =====

const MIN_PROFIT_BPS = 5n;
const TREASURY_BPS = 500n;
const TOTAL_BPS = 10_000n;

function computeSplit(grossOut: bigint, borrow: bigint, minAbs: bigint) {
  const bpsFloor = (borrow * MIN_PROFIT_BPS) / TOTAL_BPS;
  const minProfit = minAbs > bpsFloor ? minAbs : bpsFloor;
  if (grossOut < borrow + minProfit) return { passes: false, net: 0n, caller: 0n, treasury: 0n };
  const net = grossOut - borrow;
  const treasury = (net * TREASURY_BPS) / TOTAL_BPS;
  const caller = net - treasury;
  return { passes: true, net, caller, treasury };
}

// ===== Opportunity type =====

export type ArbOpportunity = {
  mode: "2leg" | "3leg";
  label: string;
  legs: { venue: VenueKey; pool: string; pairKey: string }[];
  borrow_asset: string;
  mids: string[];
  borrow_amount: bigint;
  gross_out: bigint;
  net_profit: bigint;
  profit_bps: number;
  caller_cut: bigint;
  treasury_cut: bigint;
  profitable: boolean;
};

// ===== 2-leg scan =====

// For each pair, compute profit of arbing via venue_a → venue_b (both
// directions). `borrow_asset` is always asset A of the pair, intermediate
// is asset B. Returns one best-profit opportunity per (pair, venueA, venueB)
// combo at the given size.
async function scan2LegPair(
  pairKey: string,
  borrowAmount: bigint,
): Promise<ArbOpportunity[]> {
  const assets = PAIR_ASSETS[pairKey];
  const venues = Object.entries(POOL_REGISTRY[pairKey]).filter(([, v]) => v) as [VenueKey, string][];
  const opps: ArbOpportunity[] = [];

  for (const [vA, poolA] of venues) {
    // leg 1: A → B on venue vA
    const mid = await quoteVenue(vA, poolA, assets.a, assets.b, borrowAmount);
    if (mid === 0n) continue;
    for (const [vB, poolB] of venues) {
      if (vA === vB) continue;
      // leg 2: B → A on venue vB
      const back = await quoteVenue(vB, poolB, assets.b, assets.a, mid);
      if (back === 0n) continue;
      const split = computeSplit(back, borrowAmount, 0n);
      const netProfit = back > borrowAmount ? back - borrowAmount : 0n;
      const bps = Number((netProfit * 10_000n) / borrowAmount);
      opps.push({
        mode: "2leg",
        label: `${pairKey}: ${vA} → ${vB}`,
        legs: [
          { venue: vA, pool: poolA, pairKey },
          { venue: vB, pool: poolB, pairKey },
        ],
        borrow_asset: assets.a,
        mids: [assets.b],
        borrow_amount: borrowAmount,
        gross_out: back,
        net_profit: netProfit,
        profit_bps: bps,
        caller_cut: split.caller,
        treasury_cut: split.treasury,
        profitable: split.passes,
      });
    }
  }
  return opps;
}

// ===== 3-leg triangular scan (Darbitex-only for now) =====

async function scan3LegDarbitexTriangle(borrowAmount: bigint): Promise<ArbOpportunity[]> {
  const opps: ArbOpportunity[] = [];

  const apt = META.APT;
  const usdc = META.USDC;
  const usdt = META.USDt;

  const p_apt_usdc = POOL_REGISTRY["APT/USDC"]?.darbitex;
  const p_apt_usdt = POOL_REGISTRY["APT/USDt"]?.darbitex;
  const p_usdt_usdc = POOL_REGISTRY["USDt/USDC"]?.darbitex;
  if (!p_apt_usdc || !p_apt_usdt || !p_usdt_usdc) return opps;

  // Direction A: APT → USDC → USDt → APT
  {
    const l1 = await quoteDarbitex(p_apt_usdc, apt, borrowAmount);
    if (l1 > 0n) {
      const l2 = await quoteDarbitex(p_usdt_usdc, usdc, l1); // USDC → USDt (b→a of stable)
      if (l2 > 0n) {
        const l3 = await quoteDarbitex(p_apt_usdt, usdt, l2); // USDt → APT (b→a)
        if (l3 > 0n) {
          const split = computeSplit(l3, borrowAmount, 0n);
          const net = l3 > borrowAmount ? l3 - borrowAmount : 0n;
          const bps = Number((net * 10_000n) / borrowAmount);
          opps.push({
            mode: "3leg",
            label: "Darbitex: APT→USDC→USDt→APT",
            legs: [
              { venue: "darbitex", pool: p_apt_usdc, pairKey: "APT/USDC" },
              { venue: "darbitex", pool: p_usdt_usdc, pairKey: "USDt/USDC" },
              { venue: "darbitex", pool: p_apt_usdt, pairKey: "APT/USDt" },
            ],
            borrow_asset: apt,
            mids: [usdc, usdt],
            borrow_amount: borrowAmount,
            gross_out: l3,
            net_profit: net,
            profit_bps: bps,
            caller_cut: split.caller,
            treasury_cut: split.treasury,
            profitable: split.passes,
          });
        }
      }
    }
  }

  // Direction B: APT → USDt → USDC → APT
  {
    const l1 = await quoteDarbitex(p_apt_usdt, apt, borrowAmount);
    if (l1 > 0n) {
      const l2 = await quoteDarbitex(p_usdt_usdc, usdt, l1); // USDt → USDC (a→b of stable)
      if (l2 > 0n) {
        const l3 = await quoteDarbitex(p_apt_usdc, usdc, l2); // USDC → APT (b→a)
        if (l3 > 0n) {
          const split = computeSplit(l3, borrowAmount, 0n);
          const net = l3 > borrowAmount ? l3 - borrowAmount : 0n;
          const bps = Number((net * 10_000n) / borrowAmount);
          opps.push({
            mode: "3leg",
            label: "Darbitex: APT→USDt→USDC→APT",
            legs: [
              { venue: "darbitex", pool: p_apt_usdt, pairKey: "APT/USDt" },
              { venue: "darbitex", pool: p_usdt_usdc, pairKey: "USDt/USDC" },
              { venue: "darbitex", pool: p_apt_usdc, pairKey: "APT/USDC" },
            ],
            borrow_asset: apt,
            mids: [usdt, usdc],
            borrow_amount: borrowAmount,
            gross_out: l3,
            net_profit: net,
            profit_bps: bps,
            caller_cut: split.caller,
            treasury_cut: split.treasury,
            profitable: split.passes,
          });
        }
      }
    }
  }

  return opps;
}

// ===== Top-level scan =====

// Default probe sizes (octas, i.e. APT*10^8). Geometric spread so
// optimum for current state can be found without a full sweep.
const DEFAULT_SIZES: bigint[] = [
  100_000n,    // 0.001 APT
  1_000_000n,  // 0.01 APT
  10_000_000n, // 0.1 APT
];

export async function scanAllOpportunities(sizes: bigint[] = DEFAULT_SIZES): Promise<ArbOpportunity[]> {
  const all: ArbOpportunity[] = [];
  const pairs = ["APT/USDC", "APT/USDt"];

  for (const size of sizes) {
    for (const pair of pairs) {
      const legOpps = await scan2LegPair(pair, size);
      all.push(...legOpps);
    }
    const triOpps = await scan3LegDarbitexTriangle(size);
    all.push(...triOpps);
  }

  // Sort by net profit descending, then by whether profitable
  all.sort((a, b) => {
    if (a.profitable !== b.profitable) return a.profitable ? -1 : 1;
    return Number(b.net_profit - a.net_profit);
  });
  return all;
}
