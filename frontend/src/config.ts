import { Network } from "@aptos-labs/ts-sdk";

export const PACKAGE = "0x2656e373ace5ccbc191aedaa65f12a50b9d4ea2b8e6f2d0166741994449c7ec2";
export const RPC = "https://fullnode.mainnet.aptoslabs.com/v1";
export const NETWORK = Network.MAINNET;
export const SLIPPAGE = 0.005;

export type TokenConfig = {
  meta: string;
  decimals: number;
  symbol: string;
};

export const TOKENS: Record<string, TokenConfig> = {
  APT: {
    meta: "0x000000000000000000000000000000000000000000000000000000000000000a",
    decimals: 8,
    symbol: "APT",
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
};
