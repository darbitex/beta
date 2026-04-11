# Darbitex Beta

Aptos-native AMM, clean-slate redesign of Darbitex Alpha (V1). Built as a
minimal core package with a two-layer composability contract, intended to
stay stable while future features ship as independent satellite packages.

## Status

- **Design**: locked, see `docs/AUDIT-BETA-SUBMISSION.md` for full spec
- **Unit tests**: 31/31 passing (`aptos move test`)
- **Testnet playground**: LIVE on Aptos testnet, fully operational end-to-end
- **Mainnet**: pending multi-AI audit (hard gate)

## Core design in one paragraph

One pool type agnostic to pair, x*y=k curve, 1 bps swap fee, symmetric
seeding enforced. Every pool is born with two hook NFTs: slot 0 soulbound
to the treasury multisig for a permanent fee stream, slot 1 transferable
and held in a factory escrow for fixed-price sale at 100 APT (admin-
configurable, immutable at listing). LP positions are Aptos objects with
global per-share fee accumulator plus per-position debt snapshot
(MasterChef V2 pattern), supporting claim-without-withdraw. Flash loans
universal on every pool with u256 k-invariant check and hot-potato
receipt pattern. TWAP cumulative Uniswap V2 style. Two-layer composability
contract: `public fun` primitives taking and returning `FungibleAsset`
plus `public entry fun` wrappers with deadline + store integration. Zero
admin surface on the pool level. Alpha (V1) with its auction-based hook
system is frozen legacy.

## Testnet playground

Beta is deployed and fully operational on Aptos testnet. Anyone with a
testnet account can interact with the same code that will run on mainnet
after audit.

**Package address:**
```
0x6ba3a6eff27a8a729008d16550aa41d18bacf03e28d2daf9de192a10426a213a
```

**Deployment transaction:**
`0xb625652a0a0d778b99e0d102f62a2b7bb30d919f5fd0c769597e68d66a5c7832`

**Factory initialized at resource account:**
```
0xe5b3a3d49e3bd6255c2938c42cc9e08d76c1748f0b941808e87d0abef36c5c36
```

### Live test pool (DAI/USDC)

Created during end-to-end smoke test on 2026-04-12:

| Field | Value |
|---|---|
| Pool address | `0x153edb3d8759f0e694eda138a04c736f0b5258e587830723ca91428654abcf2` |
| Token A (DAI) | `0x3d31e703fd0c326d9868b7f0c328074338ec3f69771cddc4f97c6a21973fa30c` |
| Token B (USDC) | `0x998545d91426c8609e65344cdb0018dc4815247d2abc44cc3f8d7383889f579b` |
| HookNFT #1 (soulbound → treasury) | `0x884652c947e7f3aa56f0e057549fe714620313e26ea1acbb3ef9750d47eada1c` |
| HookNFT #2 (escrow, for sale at 100 APT) | `0xec87e2172efa8231eab422646278434db47c87e5e5d728bcec522523777663d0` |
| Initial seeding | 100B DAI + 100B USDC (raw units) |
| Current reserves | post-swap + LP cycle (see explorer) |

### Getting test tokens

Test DAI and USDC are available from the V1 legacy `test_token` module at
`0xd91195850afcf3c49a47e07337095f9ef81eee45e80d1643cb393c0a198ba754`.
These are permissionless — anyone with a testnet account can call
`mint_usdc(to, amount)` or `mint_dai(to, amount)` to fund their own
address:

```bash
aptos move run \
  --function-id 0xd91195850afcf3c49a47e07337095f9ef81eee45e80d1643cb393c0a198ba754::test_token::mint_usdc \
  --args address:YOUR_ADDRESS u64:1000000000 \
  --profile testnet
```

### Try the playground

After funding:

```bash
BETA=0x6ba3a6eff27a8a729008d16550aa41d18bacf03e28d2daf9de192a10426a213a
POOL=0x153edb3d8759f0e694eda138a04c736f0b5258e587830723ca91428654abcf2
DAI=0x3d31e703fd0c326d9868b7f0c328074338ec3f69771cddc4f97c6a21973fa30c
USDC=0x998545d91426c8609e65344cdb0018dc4815247d2abc44cc3f8d7383889f579b

# Swap 100M DAI for USDC
aptos move run \
  --function-id ${BETA}::router::swap_with_deadline \
  --args address:$POOL address:$DAI u64:100000000 u64:0 u64:99999999999 \
  --profile testnet

# Add liquidity
aptos move run \
  --function-id ${BETA}::pool::add_liquidity_entry \
  --args address:$POOL u64:1000000000 u64:1000000000 \
  --profile testnet

# Read pool reserves
aptos move view \
  --function-id ${BETA}::pool::reserves \
  --args address:$POOL \
  --profile testnet

# Get a swap quote
aptos move view \
  --function-id ${BETA}::pool::get_amount_out \
  --args address:$POOL u64:1000000 bool:true \
  --profile testnet
```

## Dependencies

Beta depends on exactly three Move packages, all from the Aptos canonical
framework distribution. No third-party, vendored, or external code.

| Dependency | Provides | Source |
|---|---|---|
| **AptosFramework** | `object`, `fungible_asset`, `primary_fungible_store`, `account`, `aptos_account`, `aptos_coin`, `coin`, `event`, `timestamp`, `table` | `aptos-core` at `aptos-move/framework/aptos-framework`, pinned to `mainnet` rev |
| **AptosStdlib** | `table::Table`, `type_info`, `math64` etc. (transitive via AptosFramework) | `aptos-core` at `aptos-move/framework/aptos-stdlib` |
| **MoveStdlib** | `signer`, `vector`, `option`, `string`, `bcs`, `hash`, `error` etc. (transitive via AptosFramework) | `aptos-core` at `third_party/move/move-stdlib` |

`Move.toml` only declares `AptosFramework` explicitly; `AptosStdlib` and
`MoveStdlib` are pulled in transitively. See `contracts/Move.toml` for
the exact pin.

## Module map

```
contracts/
├── Move.toml
└── sources/
    ├── pool.move           1102 LoC  Pool, LpPosition, HookNFT, FlashReceipt,
    │                                 swap, LP, claim fees, flash loan, TWAP
    ├── pool_factory.move    393 LoC  create_canonical_pool, escrow, buy_hook,
    │                                 set_hook_price
    ├── router.move          146 LoC  multi-hop composable primitives + entry
    │                                 wrappers
    └── tests.move           784 LoC  31 unit tests (test_only)
```

Total production source: ~1640 LoC.

## Build and test

```bash
cd contracts

# Compile with placeholder address (for development)
aptos move compile \
  --named-addresses darbitex=0xcafe \
  --skip-fetch-latest-git-deps

# Run all unit tests
aptos move test \
  --skip-fetch-latest-git-deps

# Publish to testnet from your own profile
aptos move publish \
  --named-addresses darbitex=YOUR_TESTNET_ADDR \
  --profile testnet \
  --skip-fetch-latest-git-deps
```

## Audit

Multi-AI audit is a **hard gate** before mainnet publish. The audit
submission packet for external reviewers is at
`docs/AUDIT-BETA-SUBMISSION.md` (~2960 lines, self-contained, includes
full source inline). Review findings will be collated in
`docs/AUDIT-BETA-REPORT.md` under contributor handle `msgmsg`.

Once the audit clears with no unaddressed HIGH findings, Beta will be
published to mainnet via the publisher multisig at
`0x8c8f40ef0b924657461253e7aa54a15fdfd8a3069e1404ba6ffda2223ddcadb7`.

## Related

- Darbitex Alpha (V1) repository: https://github.com/darbitex/alpha-v1
- Darbitex Beta repository: https://github.com/darbitex/beta (this repo)
- Aptos Explorer — Beta testnet package: [https://explorer.aptoslabs.com/account/0x6ba3a6eff27a8a729008d16550aa41d18bacf03e28d2daf9de192a10426a213a?network=testnet](https://explorer.aptoslabs.com/account/0x6ba3a6eff27a8a729008d16550aa41d18bacf03e28d2daf9de192a10426a213a?network=testnet)
