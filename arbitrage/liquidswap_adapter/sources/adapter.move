/// LiquidSwap V0 adapter for Darbitex meta router.
///
/// Wraps LiquidSwap's Coin-based swap into FA-compatible entry functions.
/// Uses coin::withdraw (which internally calls private fungible_asset_to_coin)
/// and coin_to_fungible_asset for the FA↔Coin bridge.
///
/// Each pair requires explicit generic instantiation — no dynamic routing.
/// Tier 1 targets: lzUSDC↔wUSDC stable (4 bps), lzUSDC↔lzUSDT stable (4 bps).

module liquidswap_adapter::darbitex_liquidswap {
    use std::signer;
    use aptos_framework::coin::{Self, Coin};
    use aptos_framework::fungible_asset::{Self, FungibleAsset, Metadata};
    use aptos_framework::object::Object;
    use aptos_framework::primary_fungible_store;

    use liquidswap::router_v2;
    use liquidswap::curves::Stable;

    // ===== Errors =====

    const E_ZERO_AMOUNT: u64 = 1;
    const E_MIN_OUT: u64 = 2;

    // ===== FA↔Coin bridge helpers =====

    /// Convert FA to Coin<T>. Requires &signer because fungible_asset_to_coin
    /// is private — we deposit FA to user's store then coin::withdraw.
    fun fa_to_coin<CoinType>(
        caller: &signer,
        fa: FungibleAsset,
        _metadata: Object<Metadata>,
    ): Coin<CoinType> {
        let amount = fungible_asset::amount(&fa);
        let caller_addr = signer::address_of(caller);
        primary_fungible_store::deposit(caller_addr, fa);
        coin::withdraw<CoinType>(caller, amount)
    }

    /// Convert Coin<T> to FA. Public, no signer needed.
    fun coin_to_fa<CoinType>(coin_out: Coin<CoinType>): FungibleAsset {
        coin::coin_to_fungible_asset(coin_out)
    }

    // ===== Generic stable swap (entry only) =====

    /// Swap CoinX → CoinY on LiquidSwap V0 stable curve.
    /// Entry-only because FA→Coin bridge requires &signer.
    /// Caller sends FA in, receives FA out.
    public entry fun swap_stable<X, Y>(
        caller: &signer,
        metadata_in: Object<Metadata>,
        amount_in: u64,
        min_out: u64,
    ) {
        assert!(amount_in > 0, E_ZERO_AMOUNT);
        let caller_addr = signer::address_of(caller);

        // Withdraw FA from caller's store
        let fa_in = primary_fungible_store::withdraw(caller, metadata_in, amount_in);

        // FA → Coin
        let coin_in = fa_to_coin<X>(caller, fa_in, metadata_in);

        // Swap on LiquidSwap stable curve
        let coin_out = router_v2::swap_exact_coin_for_coin<X, Y, Stable>(
            coin_in,
            min_out,
        );

        // Coin → FA → deposit back
        let fa_out = coin_to_fa<Y>(coin_out);
        let out_amount = fungible_asset::amount(&fa_out);
        assert!(out_amount >= min_out, E_MIN_OUT);
        primary_fungible_store::deposit(caller_addr, fa_out);
    }

    // ===== Composable primitive (Coin layer) =====

    /// Composable swap for callers that already have Coin<X>.
    /// No signer needed — pure Coin in/out.
    public fun swap_stable_coin<X, Y>(
        coin_in: Coin<X>,
        min_out: u64,
    ): Coin<Y> {
        router_v2::swap_exact_coin_for_coin<X, Y, Stable>(coin_in, min_out)
    }

    // ===== Views =====

    /// Quote: how much CoinY out for amount_in of CoinX on stable curve.
    public fun get_amount_out_stable<X, Y>(amount_in: u64): u64 {
        router_v2::get_amount_out<X, Y, Stable>(amount_in)
    }
}
