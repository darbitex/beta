import { TOKENS, type TokenConfig } from "../config";
import { normMeta, rotatedGetResource } from "./client";
import { logWarn } from "./logger";

const TOKEN_CACHE: Record<string, TokenConfig> = {};

for (const [, t] of Object.entries(TOKENS)) TOKEN_CACHE[normMeta(t.meta)] = t;

type MetadataResource = {
  symbol?: string;
  decimals?: number | string;
};

export async function getTokenInfo(meta: string): Promise<TokenConfig> {
  const key = normMeta(meta);
  const cached = TOKEN_CACHE[key];
  if (cached) return cached;

  try {
    const d = await rotatedGetResource<MetadataResource>(
      meta,
      "0x1::fungible_asset::Metadata",
    );
    const info: TokenConfig = {
      meta,
      symbol: d?.symbol || `${meta.slice(0, 6)}...`,
      decimals: Number.parseInt(String(d?.decimals ?? "0"), 10) || 0,
    };
    TOKEN_CACHE[key] = info;
    return info;
  } catch (e) {
    logWarn("getTokenInfo", `fallback for ${meta}`, e);
    const info: TokenConfig = { meta, symbol: `${meta.slice(0, 6)}...`, decimals: 0 };
    TOKEN_CACHE[key] = info;
    return info;
  }
}
