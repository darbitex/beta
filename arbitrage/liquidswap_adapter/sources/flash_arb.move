/// Atomic flash loan arbitrage: Aave (0 fee) → LiquidSwap V0 → Darbitex → repay.
///
/// LiquidSwap is Coin-based so FA↔Coin bridge is embedded in the arb flow.
/// Tier 1 target: stablecoin bridge routes (lzUSDC↔wUSDC, lzUSDC↔lzUSDT).

module liquidswap_adapter::darbitex_liquidswap_arb {
    use std::signer;
    use aptos_framework::coin::{Self, Coin};
    use aptos_framework::fungible_asset::{Self, Metadata};
    use aptos_framework::object::{Self, Object};
    use aptos_framework::primary_fungible_store;

    use liquidswap::router_v2;
    use liquidswap::curves::{Stable, Uncorrelated};
    use aave_pool::flashloan_logic;
    use darbitex::pool;

    // ===== Errors =====

    const E_NO_PROFIT: u64 = 1;
    const E_ZERO_AMOUNT: u64 = 2;

    // ===== Arb: LiquidSwap → Darbitex =====

    /// Flash arb: borrow CoinType from Aave (as FA) →
    /// FA→Coin → swap Coin on LiquidSwap stable →
    /// Coin→FA → swap FA on Darbitex → repay Aave → profit.
    ///
    /// X = borrow token (CoinType), Y = intermediate token.
    /// Route: X →(LiquidSwap)→ Y →(Darbitex)→ X
    public entry fun arb_liquidswap_to_darbitex<X, Y>(
        caller: &signer,
        darbitex_pool: address,
        borrow_metadata: Object<Metadata>,
        borrow_amount: u64,
        min_profit: u64,
    ) {
        assert!(borrow_amount > 0, E_ZERO_AMOUNT);
        let caller_addr = signer::address_of(caller);
        let borrow_asset_addr = object::object_address(&borrow_metadata);

        // 1. Flash borrow from Aave (deposits FA to caller's store)
        let receipt = flashloan_logic::flash_loan_simple(
            caller,
            caller_addr,
            borrow_asset_addr,
            (borrow_amount as u256),
            0u16,
        );

        // 2. FA → Coin via deposit + withdraw pattern
        let coin_in = coin::withdraw<X>(caller, borrow_amount);

        // 3. Swap on LiquidSwap stable: X → Y
        let coin_mid = router_v2::swap_exact_coin_for_coin<X, Y, Stable>(coin_in, 0);

        // 4. Coin → FA for Darbitex
        let fa_mid = coin::coin_to_fungible_asset(coin_mid);

        // 5. Swap on Darbitex: Y → X (FA based)
        let fa_result = pool::swap(darbitex_pool, caller_addr, fa_mid, 0);

        // 6. Deposit result, repay Aave, check profit
        let result_amount = fungible_asset::amount(&fa_result);
        primary_fungible_store::deposit(caller_addr, fa_result);
        flashloan_logic::pay_flash_loan_simple(caller, receipt);
        assert!(result_amount >= borrow_amount + min_profit, E_NO_PROFIT);
    }

    // ===== Uncorrelated variants (for APT pairs, 30 bps) =====

    /// Same as arb_liquidswap_to_darbitex but on uncorrelated curve.
    public entry fun arb_liquidswap_uncorr_to_darbitex<X, Y>(
        caller: &signer,
        darbitex_pool: address,
        borrow_metadata: Object<Metadata>,
        borrow_amount: u64,
        min_profit: u64,
    ) {
        assert!(borrow_amount > 0, E_ZERO_AMOUNT);
        let caller_addr = signer::address_of(caller);
        let borrow_asset_addr = object::object_address(&borrow_metadata);

        let receipt = flashloan_logic::flash_loan_simple(
            caller, caller_addr, borrow_asset_addr, (borrow_amount as u256), 0u16,
        );
        let coin_in = coin::withdraw<X>(caller, borrow_amount);
        let coin_mid = router_v2::swap_exact_coin_for_coin<X, Y, Uncorrelated>(coin_in, 0);
        let fa_mid = coin::coin_to_fungible_asset(coin_mid);
        let fa_result = pool::swap(darbitex_pool, caller_addr, fa_mid, 0);
        let result_amount = fungible_asset::amount(&fa_result);
        primary_fungible_store::deposit(caller_addr, fa_result);
        flashloan_logic::pay_flash_loan_simple(caller, receipt);
        assert!(result_amount >= borrow_amount + min_profit, E_NO_PROFIT);
    }

    /// Same as arb_darbitex_to_liquidswap but on uncorrelated curve.
    public entry fun arb_darbitex_to_liquidswap_uncorr<X, Y>(
        caller: &signer,
        darbitex_pool: address,
        borrow_metadata: Object<Metadata>,
        borrow_amount: u64,
        min_profit: u64,
    ) {
        assert!(borrow_amount > 0, E_ZERO_AMOUNT);
        let caller_addr = signer::address_of(caller);
        let borrow_asset_addr = object::object_address(&borrow_metadata);

        let receipt = flashloan_logic::flash_loan_simple(
            caller, caller_addr, borrow_asset_addr, (borrow_amount as u256), 0u16,
        );
        let fa_in = primary_fungible_store::withdraw(caller, borrow_metadata, borrow_amount);
        let fa_mid = pool::swap(darbitex_pool, caller_addr, fa_in, 0);
        let mid_amount = fungible_asset::amount(&fa_mid);
        primary_fungible_store::deposit(caller_addr, fa_mid);
        let coin_mid = coin::withdraw<Y>(caller, mid_amount);
        let coin_result = router_v2::swap_exact_coin_for_coin<Y, X, Uncorrelated>(coin_mid, 0);
        let fa_result = coin::coin_to_fungible_asset(coin_result);
        let result_amount = fungible_asset::amount(&fa_result);
        primary_fungible_store::deposit(caller_addr, fa_result);
        flashloan_logic::pay_flash_loan_simple(caller, receipt);
        assert!(result_amount >= borrow_amount + min_profit, E_NO_PROFIT);
    }

    // ===== Arb: Darbitex → LiquidSwap (Stable) =====

    /// Reverse direction: borrow X → Darbitex X→Y → LiquidSwap Y→X → repay.
    public entry fun arb_darbitex_to_liquidswap<X, Y>(
        caller: &signer,
        darbitex_pool: address,
        borrow_metadata: Object<Metadata>,
        borrow_amount: u64,
        min_profit: u64,
    ) {
        assert!(borrow_amount > 0, E_ZERO_AMOUNT);
        let caller_addr = signer::address_of(caller);
        let borrow_asset_addr = object::object_address(&borrow_metadata);

        // 1. Flash borrow from Aave
        let receipt = flashloan_logic::flash_loan_simple(
            caller,
            caller_addr,
            borrow_asset_addr,
            (borrow_amount as u256),
            0u16,
        );

        // 2. Withdraw FA from store (Aave deposited it)
        let fa_in = primary_fungible_store::withdraw(caller, borrow_metadata, borrow_amount);

        // 3. Swap on Darbitex: X → Y (FA based)
        let fa_mid = pool::swap(darbitex_pool, caller_addr, fa_in, 0);

        // 4. FA → Coin for LiquidSwap
        let mid_amount = fungible_asset::amount(&fa_mid);
        primary_fungible_store::deposit(caller_addr, fa_mid);
        let coin_mid = coin::withdraw<Y>(caller, mid_amount);

        // 5. Swap on LiquidSwap stable: Y → X
        let coin_result = router_v2::swap_exact_coin_for_coin<Y, X, Stable>(coin_mid, 0);

        // 6. Coin → FA → deposit, repay, check profit
        let fa_result = coin::coin_to_fungible_asset(coin_result);
        let result_amount = fungible_asset::amount(&fa_result);
        primary_fungible_store::deposit(caller_addr, fa_result);
        flashloan_logic::pay_flash_loan_simple(caller, receipt);
        assert!(result_amount >= borrow_amount + min_profit, E_NO_PROFIT);
    }
}
