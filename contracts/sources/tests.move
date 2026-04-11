#[test_only]
module darbitex::tests {
    use std::string;
    use std::option;
    use std::bcs;
    use aptos_framework::account;
    use aptos_framework::timestamp;
    use aptos_framework::object::{Self, Object};
    use aptos_framework::fungible_asset::{Self, Metadata, MintRef};
    use aptos_framework::primary_fungible_store;
    use aptos_framework::coin;
    use aptos_framework::aptos_coin::{Self, AptosCoin};

    use darbitex::pool::{Self, HookNFT};
    use darbitex::pool_factory;
    use darbitex::router;

    // ===== Test Constants =====

    const POOL_AMOUNT: u64 = 1_000_000_000_000; // 10_000 tokens @ 8 dec
    const APT_1: u64 = 100_000_000;             // 1 APT octas
    const MIN_HOOK_PRICE: u64 = 10_000_000_000; // 100 APT octas (Beta default)

    const TREASURY: address = @0xdbce89113a975826028236f910668c3ff99c8db8981be6a448caa2f8836f9576;
    const ADMIN: address = @0xf1b522effb90aef79395f97b9c39d6acbd8fdf84ec046361359a48de2e196566;

    // ===== MintRef storage =====

    struct TestMints has key {
        mint_a: MintRef,
        mint_b: MintRef,
    }

    struct TestMintC has key {
        mint_c: MintRef,
    }

    // ===== Helpers =====

    fun create_fa(creator: &signer, seed: vector<u8>, name: vector<u8>): (Object<Metadata>, MintRef) {
        let constructor_ref = object::create_named_object(creator, seed);
        primary_fungible_store::create_primary_store_enabled_fungible_asset(
            &constructor_ref,
            option::none(),
            string::utf8(name),
            string::utf8(name),
            8,
            string::utf8(b""),
            string::utf8(b""),
        );
        let mint_ref = fungible_asset::generate_mint_ref(&constructor_ref);
        let metadata = object::object_from_constructor_ref<Metadata>(&constructor_ref);
        (metadata, mint_ref)
    }

    fun mint(ref: &MintRef, to: address, amount: u64) {
        let fa = fungible_asset::mint(ref, amount);
        primary_fungible_store::deposit(to, fa);
    }

    fun bal(addr: address, meta: Object<Metadata>): u64 {
        primary_fungible_store::balance(addr, meta)
    }

    /// Full protocol setup. Returns sorted (meta_a, meta_b).
    fun setup(framework: &signer, darbitex_signer: &signer): (Object<Metadata>, Object<Metadata>) {
        timestamp::set_time_has_started_for_testing(framework);

        // AptosCoin for any APT-handling tests (auction-free Beta still uses
        // APT for buy_hook).
        let (burn_cap, mint_cap) = aptos_coin::initialize_for_test(framework);
        coin::destroy_burn_cap(burn_cap);
        coin::destroy_mint_cap(mint_cap);

        account::create_account_for_test(@darbitex);

        // Beta factory init
        pool_factory::init_factory(darbitex_signer);

        // Create two FA tokens. Creator is darbitex so the mint ref can be
        // stored in global TestMints on the darbitex account.
        let (meta_x, mint_x) = create_fa(darbitex_signer, b"coin_x", b"CoinX");
        let (meta_y, mint_y) = create_fa(darbitex_signer, b"coin_y", b"CoinY");

        // Sort by BCS address order (factory requires sorted input).
        let ax = bcs::to_bytes(&object::object_address(&meta_x));
        let ay = bcs::to_bytes(&object::object_address(&meta_y));
        let (meta_a, meta_b, mint_a, mint_b) = if (ax < ay) {
            (meta_x, meta_y, mint_x, mint_y)
        } else {
            (meta_y, meta_x, mint_y, mint_x)
        };

        // Stock darbitex with plenty of both sides.
        mint(&mint_a, @darbitex, POOL_AMOUNT * 10);
        mint(&mint_b, @darbitex, POOL_AMOUNT * 10);

        move_to(darbitex_signer, TestMints { mint_a, mint_b });

        (meta_a, meta_b)
    }

    /// Extended setup that also creates a third token (CoinC) for 2-hop and
    /// 3-hop router tests. Returns (meta_a, meta_b, meta_c) all sorted
    /// globally so any pairwise selection is already in canonical order.
    fun setup_with_third(
        framework: &signer, darbitex_signer: &signer,
    ): (Object<Metadata>, Object<Metadata>, Object<Metadata>) {
        let (meta_a, meta_b) = setup(framework, darbitex_signer);
        let (meta_c, mint_c) = create_fa(darbitex_signer, b"coin_c", b"CoinC");
        mint(&mint_c, @darbitex, POOL_AMOUNT * 10);
        move_to(darbitex_signer, TestMintC { mint_c });
        // Return (a, b, c) but do NOT sort a/b/c globally — callers that
        // need canonical ordering for pool creation sort on demand.
        (meta_a, meta_b, meta_c)
    }

    /// Mint both test tokens to an address (for non-creator user tests).
    fun give_tokens(to: address, amount: u64) acquires TestMints {
        let m = borrow_global<TestMints>(@darbitex);
        mint(&m.mint_a, to, amount);
        mint(&m.mint_b, to, amount);
    }

    fun give_token_c(to: address, amount: u64) acquires TestMintC {
        let m = borrow_global<TestMintC>(@darbitex);
        mint(&m.mint_c, to, amount);
    }

    /// Fund an account with AptosCoin via the framework MintCapStore for
    /// buy_hook tests. Auto-creates account.
    fun fund_apt(framework: &signer, dst: address, amount: u64) {
        if (!account::exists_at(dst)) {
            account::create_account_for_test(dst);
        };
        aptos_coin::mint(framework, dst, amount);
    }

    /// Sort two metadata objects into (lo, hi) BCS order. Useful for
    /// constructing a sorted pair at test time without knowing a priori
    /// which of two tokens has the smaller address.
    fun sort_pair(x: Object<Metadata>, y: Object<Metadata>): (Object<Metadata>, Object<Metadata>) {
        let bx = bcs::to_bytes(&object::object_address(&x));
        let by = bcs::to_bytes(&object::object_address(&y));
        if (bx < by) { (x, y) } else { (y, x) }
    }

    // =========================================================
    //                 POOL CREATION TESTS
    // =========================================================

    #[test(darbitex = @darbitex, framework = @0x1)]
    fun test_create_pool_happy(
        darbitex: &signer, framework: &signer,
    ) acquires TestMints {
        let (meta_a, meta_b) = setup(framework, darbitex);
        let _ = borrow_global<TestMints>(@darbitex); // silence unused acquires lint

        pool_factory::create_canonical_pool(darbitex, meta_a, meta_b, POOL_AMOUNT);

        // Canonical address computed; pool should exist there.
        let pool_addr = pool_factory::canonical_pool_address(meta_a, meta_b);
        assert!(pool::pool_exists(pool_addr), 1);

        // Registry bumped.
        assert!(pool_factory::pool_count() == 1, 2);

        // Reserves match seeding amount.
        let (ra, rb) = pool::reserves(pool_addr);
        assert!(ra == POOL_AMOUNT && rb == POOL_AMOUNT, 3);

        // lp_supply = sqrt(a*b) = POOL_AMOUNT.
        let supply = pool::lp_supply(pool_addr);
        assert!(supply == POOL_AMOUNT, 4);
    }

    #[test(darbitex = @darbitex, framework = @0x1)]
    #[expected_failure(abort_code = 4, location = darbitex::pool_factory)]
    /// Same-token pair triggers E_WRONG_ORDER in assert_sorted (ba == bb
    /// cannot satisfy strict `<`).
    fun test_create_pool_same_token_aborts(
        darbitex: &signer, framework: &signer,
    ) {
        let (meta_a, _meta_b) = setup(framework, darbitex);
        pool_factory::create_canonical_pool(darbitex, meta_a, meta_a, POOL_AMOUNT);
    }

    #[test(darbitex = @darbitex, framework = @0x1)]
    #[expected_failure(abort_code = 4, location = darbitex::pool_factory)]
    /// Reversed (unsorted) pair triggers E_WRONG_ORDER.
    fun test_create_pool_unsorted_aborts(
        darbitex: &signer, framework: &signer,
    ) {
        let (meta_a, meta_b) = setup(framework, darbitex);
        pool_factory::create_canonical_pool(darbitex, meta_b, meta_a, POOL_AMOUNT);
    }

    #[test(darbitex = @darbitex, framework = @0x1)]
    #[expected_failure]
    /// Second create_canonical_pool for the same pair aborts at the Move
    /// framework level (EOBJECT_EXISTS on create_named_object). We don't
    /// pin the exact abort code since it comes from aptos_framework.
    fun test_create_pool_duplicate_aborts(
        darbitex: &signer, framework: &signer,
    ) {
        let (meta_a, meta_b) = setup(framework, darbitex);
        pool_factory::create_canonical_pool(darbitex, meta_a, meta_b, POOL_AMOUNT);
        pool_factory::create_canonical_pool(darbitex, meta_a, meta_b, POOL_AMOUNT);
    }

    #[test(darbitex = @darbitex, framework = @0x1)]
    fun test_create_pool_hook_nfts_exist(
        darbitex: &signer, framework: &signer,
    ) {
        let (meta_a, meta_b) = setup(framework, darbitex);
        pool_factory::create_canonical_pool(darbitex, meta_a, meta_b, POOL_AMOUNT);

        let pool_addr = pool_factory::canonical_pool_address(meta_a, meta_b);
        let (h1_addr, h2_addr) = pool::hook_nft_addresses(pool_addr);
        assert!(object::object_exists<HookNFT>(h1_addr), 1);
        assert!(object::object_exists<HookNFT>(h2_addr), 2);

        let (h1_pool, h1_slot) = pool::hook_nft_info(h1_addr);
        let (h2_pool, h2_slot) = pool::hook_nft_info(h2_addr);
        assert!(h1_pool == pool_addr && h1_slot == 0, 3);
        assert!(h2_pool == pool_addr && h2_slot == 1, 4);
    }

    #[test(darbitex = @darbitex, framework = @0x1)]
    fun test_create_pool_hook_1_owned_by_treasury(
        darbitex: &signer, framework: &signer,
    ) {
        let (meta_a, meta_b) = setup(framework, darbitex);
        pool_factory::create_canonical_pool(darbitex, meta_a, meta_b, POOL_AMOUNT);
        let pool_addr = pool_factory::canonical_pool_address(meta_a, meta_b);
        let (h1_addr, _) = pool::hook_nft_addresses(pool_addr);
        let h1_obj = object::address_to_object<HookNFT>(h1_addr);
        assert!(object::owner(h1_obj) == TREASURY, 1);
    }

    #[test(darbitex = @darbitex, framework = @0x1)]
    fun test_create_pool_hook_2_owned_by_factory_escrow(
        darbitex: &signer, framework: &signer,
    ) {
        let (meta_a, meta_b) = setup(framework, darbitex);
        pool_factory::create_canonical_pool(darbitex, meta_a, meta_b, POOL_AMOUNT);

        let pool_addr = pool_factory::canonical_pool_address(meta_a, meta_b);
        let (_, h2_addr) = pool::hook_nft_addresses(pool_addr);
        let h2_obj = object::address_to_object<HookNFT>(h2_addr);
        assert!(object::owner(h2_obj) == pool_factory::factory_address(), 1);
    }

    #[test(darbitex = @darbitex, framework = @0x1)]
    fun test_create_pool_escrow_listing_at_default_price(
        darbitex: &signer, framework: &signer,
    ) {
        let (meta_a, meta_b) = setup(framework, darbitex);
        pool_factory::create_canonical_pool(darbitex, meta_a, meta_b, POOL_AMOUNT);
        let pool_addr = pool_factory::canonical_pool_address(meta_a, meta_b);
        assert!(pool_factory::is_hook_listed(pool_addr), 1);
        assert!(pool_factory::hook_listing_price(pool_addr) == MIN_HOOK_PRICE, 2);
    }

    // =========================================================
    //                      SWAP TESTS
    // =========================================================

    #[test(darbitex = @darbitex, user = @0x100, framework = @0x1)]
    fun test_swap_basic(
        darbitex: &signer, user: &signer, framework: &signer,
    ) acquires TestMints {
        let (meta_a, meta_b) = setup(framework, darbitex);
        pool_factory::create_canonical_pool(darbitex, meta_a, meta_b, POOL_AMOUNT);
        let pool_addr = pool_factory::canonical_pool_address(meta_a, meta_b);

        account::create_account_for_test(@0x100);
        give_tokens(@0x100, 1_000_000);

        let before_b = bal(@0x100, meta_b);
        router::swap_with_deadline(
            user, pool_addr, meta_a, 1_000_000, 0, 1_000_000_000,
        );
        let after_b = bal(@0x100, meta_b);
        assert!(after_b > before_b, 1);

        let (ra2, rb2) = pool::reserves(pool_addr);
        assert!(ra2 > POOL_AMOUNT, 2);
        assert!(rb2 < POOL_AMOUNT, 3);
    }

    #[test(darbitex = @darbitex, user = @0x100, framework = @0x1)]
    fun test_swap_quote_accuracy(
        darbitex: &signer, user: &signer, framework: &signer,
    ) acquires TestMints {
        let (meta_a, meta_b) = setup(framework, darbitex);
        pool_factory::create_canonical_pool(darbitex, meta_a, meta_b, POOL_AMOUNT);
        let pool_addr = pool_factory::canonical_pool_address(meta_a, meta_b);

        let amount_in = 5_000_000;
        let expected = pool::get_amount_out(pool_addr, amount_in, true);

        account::create_account_for_test(@0x100);
        give_tokens(@0x100, amount_in);
        let before_b = bal(@0x100, meta_b);
        router::swap_with_deadline(
            user, pool_addr, meta_a, amount_in, 0, 1_000_000_000,
        );
        let actual = bal(@0x100, meta_b) - before_b;
        assert!(actual == expected, 1);
    }

    #[test(darbitex = @darbitex, user = @0x100, framework = @0x1)]
    #[expected_failure(abort_code = 3, location = darbitex::pool)]
    fun test_swap_slippage_abort(
        darbitex: &signer, user: &signer, framework: &signer,
    ) acquires TestMints {
        let (meta_a, meta_b) = setup(framework, darbitex);
        pool_factory::create_canonical_pool(darbitex, meta_a, meta_b, POOL_AMOUNT);
        let pool_addr = pool_factory::canonical_pool_address(meta_a, meta_b);

        account::create_account_for_test(@0x100);
        give_tokens(@0x100, 1_000_000);
        router::swap_with_deadline(
            user, pool_addr, meta_a, 1_000_000, 999_999_999, 1_000_000_000,
        );
    }

    #[test(darbitex = @darbitex, user = @0x100, framework = @0x1)]
    fun test_swap_hook_buckets_grow_5050(
        darbitex: &signer, user: &signer, framework: &signer,
    ) acquires TestMints {
        let (meta_a, meta_b) = setup(framework, darbitex);
        pool_factory::create_canonical_pool(darbitex, meta_a, meta_b, POOL_AMOUNT);
        let pool_addr = pool_factory::canonical_pool_address(meta_a, meta_b);

        account::create_account_for_test(@0x100);
        give_tokens(@0x100, POOL_AMOUNT);
        router::swap_with_deadline(
            user, pool_addr, meta_a, 10_000_000, 0, 1_000_000_000,
        );

        let (h1_a, _h1_b, h2_a, _h2_b) = pool::hook_fee_buckets(pool_addr);
        // extra_fee on 10M input at EXTRA_FEE_DENOM=100_000 is 100 units.
        // 50/50 split → 50 each. Allow ±1 for rounding.
        assert!(h1_a + h2_a >= 99 && h1_a + h2_a <= 101, 1);
        assert!(h1_a == h2_a || (h1_a + 1 == h2_a) || (h1_a == h2_a + 1), 2);
    }

    #[test(darbitex = @darbitex, user = @0x100, framework = @0x1)]
    fun test_swap_lp_accumulator_grows(
        darbitex: &signer, user: &signer, framework: &signer,
    ) acquires TestMints {
        let (meta_a, meta_b) = setup(framework, darbitex);
        pool_factory::create_canonical_pool(darbitex, meta_a, meta_b, POOL_AMOUNT);
        let pool_addr = pool_factory::canonical_pool_address(meta_a, meta_b);

        let (start_a, start_b) = pool::lp_fee_per_share(pool_addr);
        assert!(start_a == 0 && start_b == 0, 1);

        account::create_account_for_test(@0x100);
        give_tokens(@0x100, POOL_AMOUNT);
        router::swap_with_deadline(
            user, pool_addr, meta_a, 10_000_000, 0, 1_000_000_000,
        );

        let (end_a, _end_b) = pool::lp_fee_per_share(pool_addr);
        // LP portion = total_fee - extra_fee = 1000 - 100 = 900 units
        // accumulator += 900 * SCALE / lp_supply
        assert!(end_a > start_a, 2);
    }

    // =========================================================
    //                   LIQUIDITY TESTS
    // =========================================================

    #[test(darbitex = @darbitex, user = @0x100, framework = @0x1)]
    fun test_add_liquidity_happy(
        darbitex: &signer, user: &signer, framework: &signer,
    ) acquires TestMints {
        let (meta_a, meta_b) = setup(framework, darbitex);
        pool_factory::create_canonical_pool(darbitex, meta_a, meta_b, POOL_AMOUNT);
        let pool_addr = pool_factory::canonical_pool_address(meta_a, meta_b);

        account::create_account_for_test(@0x100);
        give_tokens(@0x100, POOL_AMOUNT);

        let add = 100_000_000;
        let position = pool::add_liquidity(user, pool_addr, add, add);
        let position_addr = object::object_address(&position);
        let (pos_pool, pos_shares, _, _) = pool::position_info(position_addr);
        assert!(pos_pool == pool_addr, 1);
        assert!(pos_shares > 0, 2);
    }

    #[test(darbitex = @darbitex, user = @0x100, framework = @0x1)]
    #[expected_failure(abort_code = 5, location = darbitex::pool)]
    fun test_add_liquidity_disproportional_aborts(
        darbitex: &signer, user: &signer, framework: &signer,
    ) acquires TestMints {
        let (meta_a, meta_b) = setup(framework, darbitex);
        pool_factory::create_canonical_pool(darbitex, meta_a, meta_b, POOL_AMOUNT);
        let pool_addr = pool_factory::canonical_pool_address(meta_a, meta_b);

        account::create_account_for_test(@0x100);
        give_tokens(@0x100, POOL_AMOUNT);
        // 1000:2000 is 100% skew from the 1:1 reserve ratio; tolerance 5%.
        pool::add_liquidity(user, pool_addr, 100_000_000, 200_000_000);
    }

    #[test(darbitex = @darbitex, user = @0x100, framework = @0x1)]
    fun test_remove_liquidity_returns_reserves(
        darbitex: &signer, user: &signer, framework: &signer,
    ) acquires TestMints {
        let (meta_a, meta_b) = setup(framework, darbitex);
        pool_factory::create_canonical_pool(darbitex, meta_a, meta_b, POOL_AMOUNT);
        let pool_addr = pool_factory::canonical_pool_address(meta_a, meta_b);

        account::create_account_for_test(@0x100);
        give_tokens(@0x100, POOL_AMOUNT);
        let before_a = bal(@0x100, meta_a);
        let before_b = bal(@0x100, meta_b);

        let position = pool::add_liquidity(user, pool_addr, 100_000_000, 100_000_000);

        let (fa_a, fa_b) = pool::remove_liquidity(user, position);
        primary_fungible_store::deposit(@0x100, fa_a);
        primary_fungible_store::deposit(@0x100, fa_b);

        let final_a = bal(@0x100, meta_a);
        let final_b = bal(@0x100, meta_b);
        // Within 1 unit rounding tolerance.
        assert!(final_a >= before_a - 1, 1);
        assert!(final_b >= before_b - 1, 2);
    }

    #[test(darbitex = @darbitex, provider = @0x100, swapper = @0x200, framework = @0x1)]
    fun test_claim_lp_fees_after_swap(
        darbitex: &signer, provider: &signer, swapper: &signer, framework: &signer,
    ) acquires TestMints {
        let (meta_a, meta_b) = setup(framework, darbitex);
        pool_factory::create_canonical_pool(darbitex, meta_a, meta_b, POOL_AMOUNT);
        let pool_addr = pool_factory::canonical_pool_address(meta_a, meta_b);

        account::create_account_for_test(@0x100);
        account::create_account_for_test(@0x200);
        give_tokens(@0x100, POOL_AMOUNT);
        give_tokens(@0x200, POOL_AMOUNT);

        // Provider adds a mid-sized position.
        let position = pool::add_liquidity(provider, pool_addr, 100_000_000, 100_000_000);

        // Swapper drives fee accrual with a meaningful swap.
        router::swap_with_deadline(
            swapper, pool_addr, meta_a, 100_000_000, 0, 1_000_000_000,
        );

        // Claim. Expect at least some A fee (provider's share of the wedge).
        let before_a = bal(@0x100, meta_a);
        let (fa_a, fa_b) = pool::claim_lp_fees(provider, position);
        primary_fungible_store::deposit(@0x100, fa_a);
        primary_fungible_store::deposit(@0x100, fa_b);
        let after_a = bal(@0x100, meta_a);
        assert!(after_a >= before_a, 1);
    }

    #[test(darbitex = @darbitex, user = @0x100, framework = @0x1)]
    fun test_lp_position_is_transferable(
        darbitex: &signer, user: &signer, framework: &signer,
    ) acquires TestMints {
        let (meta_a, meta_b) = setup(framework, darbitex);
        pool_factory::create_canonical_pool(darbitex, meta_a, meta_b, POOL_AMOUNT);
        let pool_addr = pool_factory::canonical_pool_address(meta_a, meta_b);

        account::create_account_for_test(@0x100);
        give_tokens(@0x100, POOL_AMOUNT);
        let position = pool::add_liquidity(user, pool_addr, 100_000_000, 100_000_000);

        // Transfer to @0x200.
        account::create_account_for_test(@0x200);
        object::transfer(user, position, @0x200);
        assert!(object::owner(position) == @0x200, 1);
    }

    // =========================================================
    //                    HOOK FEE TESTS
    // =========================================================

    #[test(darbitex = @darbitex, user = @0x100, treasury = @0xdbce89113a975826028236f910668c3ff99c8db8981be6a448caa2f8836f9576, framework = @0x1)]
    fun test_claim_hook_fees_slot_0_treasury(
        darbitex: &signer, user: &signer, treasury: &signer, framework: &signer,
    ) acquires TestMints {
        let (meta_a, meta_b) = setup(framework, darbitex);
        pool_factory::create_canonical_pool(darbitex, meta_a, meta_b, POOL_AMOUNT);
        let pool_addr = pool_factory::canonical_pool_address(meta_a, meta_b);

        account::create_account_for_test(@0x100);
        give_tokens(@0x100, POOL_AMOUNT);
        router::swap_with_deadline(
            user, pool_addr, meta_a, 100_000_000, 0, 1_000_000_000,
        );

        let (h1_addr, _) = pool::hook_nft_addresses(pool_addr);
        let h1_obj = object::address_to_object<HookNFT>(h1_addr);

        // Treasury claims (owner of h1).
        account::create_account_for_test(TREASURY);
        let (fa_a, fa_b) = pool::claim_hook_fees(treasury, h1_obj);
        let amt_a = fungible_asset::amount(&fa_a);
        let amt_b = fungible_asset::amount(&fa_b);
        assert!(amt_a > 0 || amt_b > 0, 1);
        primary_fungible_store::deposit(TREASURY, fa_a);
        primary_fungible_store::deposit(TREASURY, fa_b);
    }

    #[test(darbitex = @darbitex, user = @0x100, treasury = @0xdbce89113a975826028236f910668c3ff99c8db8981be6a448caa2f8836f9576, framework = @0x1)]
    #[expected_failure]
    /// HookNFT #1 is soulbound. Treasury owner trying to transfer it must
    /// abort at the object framework level (ungated transfer disabled).
    fun test_hook_nft_1_soulbound_abort(
        darbitex: &signer, user: &signer, treasury: &signer, framework: &signer,
    ) {
        let _ = user;
        let (meta_a, meta_b) = setup(framework, darbitex);
        pool_factory::create_canonical_pool(darbitex, meta_a, meta_b, POOL_AMOUNT);
        let pool_addr = pool_factory::canonical_pool_address(meta_a, meta_b);
        let (h1_addr, _) = pool::hook_nft_addresses(pool_addr);
        let h1_obj = object::address_to_object<HookNFT>(h1_addr);

        account::create_account_for_test(TREASURY);
        account::create_account_for_test(@0x999);
        // Must abort — soulbound.
        object::transfer(treasury, h1_obj, @0x999);
    }

    // =========================================================
    //                    BUY HOOK TESTS
    // =========================================================

    #[test(darbitex = @darbitex, buyer = @0xB1, framework = @0x1)]
    fun test_buy_hook_happy(
        darbitex: &signer, buyer: &signer, framework: &signer,
    ) {
        let (meta_a, meta_b) = setup(framework, darbitex);
        pool_factory::create_canonical_pool(darbitex, meta_a, meta_b, POOL_AMOUNT);
        let pool_addr = pool_factory::canonical_pool_address(meta_a, meta_b);

        // Buyer funded with enough APT for the default 100 APT price.
        fund_apt(framework, @0xB1, MIN_HOOK_PRICE + APT_1);
        // Admin account must exist to receive revenue.
        account::create_account_for_test(ADMIN);

        assert!(pool_factory::is_hook_listed(pool_addr), 1);

        pool_factory::buy_hook(buyer, pool_addr);

        // Listing removed.
        assert!(!pool_factory::is_hook_listed(pool_addr), 2);

        // NFT ownership transferred.
        let (_, h2_addr) = pool::hook_nft_addresses(pool_addr);
        let h2_obj = object::address_to_object<HookNFT>(h2_addr);
        assert!(object::owner(h2_obj) == @0xB1, 3);

        // Admin (revenue) received the price.
        let admin_bal = coin::balance<AptosCoin>(ADMIN);
        assert!(admin_bal == MIN_HOOK_PRICE, 4);
    }

    #[test(darbitex = @darbitex, buyer = @0xB1, framework = @0x1)]
    #[expected_failure(abort_code = 6, location = darbitex::pool_factory)]
    fun test_buy_hook_not_listed_aborts(
        darbitex: &signer, buyer: &signer, framework: &signer,
    ) {
        let (meta_a, meta_b) = setup(framework, darbitex);
        pool_factory::create_canonical_pool(darbitex, meta_a, meta_b, POOL_AMOUNT);
        let pool_addr = pool_factory::canonical_pool_address(meta_a, meta_b);

        fund_apt(framework, @0xB1, MIN_HOOK_PRICE * 2);
        account::create_account_for_test(ADMIN);

        pool_factory::buy_hook(buyer, pool_addr);
        // Second call must abort with E_NOT_LISTED.
        pool_factory::buy_hook(buyer, pool_addr);
    }

    #[test(darbitex = @darbitex, buyer = @0xB1, user = @0x100, framework = @0x1)]
    fun test_buy_hook_then_claim_slot_1_fees(
        darbitex: &signer, buyer: &signer, user: &signer, framework: &signer,
    ) acquires TestMints {
        let (meta_a, meta_b) = setup(framework, darbitex);
        pool_factory::create_canonical_pool(darbitex, meta_a, meta_b, POOL_AMOUNT);
        let pool_addr = pool_factory::canonical_pool_address(meta_a, meta_b);

        // Drive swap volume to accrue slot 1 fees.
        account::create_account_for_test(@0x100);
        give_tokens(@0x100, POOL_AMOUNT);
        router::swap_with_deadline(
            user, pool_addr, meta_a, 100_000_000, 0, 1_000_000_000,
        );

        // Buyer acquires the NFT at list price.
        fund_apt(framework, @0xB1, MIN_HOOK_PRICE + APT_1);
        account::create_account_for_test(ADMIN);
        pool_factory::buy_hook(buyer, pool_addr);

        // Buyer claims the accumulated slot 1 fees.
        let (_, h2_addr) = pool::hook_nft_addresses(pool_addr);
        let h2_obj = object::address_to_object<HookNFT>(h2_addr);
        let (fa_a, fa_b) = pool::claim_hook_fees(buyer, h2_obj);
        let amt_a = fungible_asset::amount(&fa_a);
        let amt_b = fungible_asset::amount(&fa_b);
        assert!(amt_a > 0 || amt_b > 0, 1);
        primary_fungible_store::deposit(@0xB1, fa_a);
        primary_fungible_store::deposit(@0xB1, fa_b);
    }

    #[test(darbitex = @darbitex, admin = @0xf1b522effb90aef79395f97b9c39d6acbd8fdf84ec046361359a48de2e196566, framework = @0x1)]
    fun test_set_hook_price_affects_future_only(
        darbitex: &signer, admin: &signer, framework: &signer,
    ) {
        let (meta_a, meta_b) = setup(framework, darbitex);

        // Create first pool at DEFAULT price.
        pool_factory::create_canonical_pool(darbitex, meta_a, meta_b, POOL_AMOUNT);
        let pool1 = pool_factory::canonical_pool_address(meta_a, meta_b);
        let p1_listed = pool_factory::hook_listing_price(pool1);
        assert!(p1_listed == MIN_HOOK_PRICE, 1);

        // Admin raises the default.
        let new_price = MIN_HOOK_PRICE * 2;
        pool_factory::set_hook_price(admin, new_price);

        // First pool keeps its locked-in price.
        assert!(pool_factory::hook_listing_price(pool1) == MIN_HOOK_PRICE, 2);

        // current_hook_price view reflects the new value.
        assert!(pool_factory::current_hook_price() == new_price, 3);
    }

    #[test(darbitex = @darbitex, attacker = @0xBEEF, framework = @0x1)]
    #[expected_failure(abort_code = 1, location = darbitex::pool_factory)]
    fun test_set_hook_price_non_admin_aborts(
        darbitex: &signer, attacker: &signer, framework: &signer,
    ) {
        let (meta_a, _) = setup(framework, darbitex);
        let _ = meta_a;
        account::create_account_for_test(@0xBEEF);
        pool_factory::set_hook_price(attacker, MIN_HOOK_PRICE * 5);
    }

    // =========================================================
    //                   FLASH LOAN TESTS
    // =========================================================

    #[test(darbitex = @darbitex, framework = @0x1)]
    fun test_flash_borrow_repay_happy(
        darbitex: &signer, framework: &signer,
    ) acquires TestMints {
        let (meta_a, meta_b) = setup(framework, darbitex);
        pool_factory::create_canonical_pool(darbitex, meta_a, meta_b, POOL_AMOUNT);
        let pool_addr = pool_factory::canonical_pool_address(meta_a, meta_b);

        let borrow_amount = 1_000_000;
        let (fa_borrowed, receipt) = pool::flash_borrow(pool_addr, meta_a, borrow_amount);
        assert!(fungible_asset::amount(&fa_borrowed) == borrow_amount, 1);

        // Repay with principal + fee. We need extra meta_a for the fee; pull
        // from darbitex's stash.
        let m = borrow_global<TestMints>(@darbitex);
        let fa_extra = fungible_asset::mint(&m.mint_a, 1_000);
        fungible_asset::merge(&mut fa_borrowed, fa_extra);

        pool::flash_repay(pool_addr, fa_borrowed, receipt);
    }

    #[test(darbitex = @darbitex, framework = @0x1)]
    #[expected_failure]
    /// Repaying with less than principal+fee aborts.
    fun test_flash_repay_insufficient_aborts(
        darbitex: &signer, framework: &signer,
    ) {
        let (meta_a, meta_b) = setup(framework, darbitex);
        pool_factory::create_canonical_pool(darbitex, meta_a, meta_b, POOL_AMOUNT);
        let pool_addr = pool_factory::canonical_pool_address(meta_a, meta_b);

        let (fa, receipt) = pool::flash_borrow(pool_addr, meta_a, 1_000_000);
        // Repay without adding any fee — principal only is insufficient.
        pool::flash_repay(pool_addr, fa, receipt);
    }

    // =========================================================
    //                      TWAP TEST
    // =========================================================

    #[test(darbitex = @darbitex, user = @0x100, framework = @0x1)]
    fun test_twap_accumulates(
        darbitex: &signer, user: &signer, framework: &signer,
    ) acquires TestMints {
        let (meta_a, meta_b) = setup(framework, darbitex);
        pool_factory::create_canonical_pool(darbitex, meta_a, meta_b, POOL_AMOUNT);
        let pool_addr = pool_factory::canonical_pool_address(meta_a, meta_b);

        let (twap_a0, twap_b0, _) = pool::twap_cumulative(pool_addr);
        assert!(twap_a0 == 0 && twap_b0 == 0, 1);

        // Advance time.
        timestamp::fast_forward_seconds(100);

        // Trigger update_twap via a swap (any mutation suffices).
        account::create_account_for_test(@0x100);
        give_tokens(@0x100, 1_000_000);
        router::swap_with_deadline(
            user, pool_addr, meta_a, 1_000_000, 0, 1_000_000_000_000,
        );

        let (twap_a1, twap_b1, _) = pool::twap_cumulative(pool_addr);
        // cumulative grew by reserve × dt where dt=100 seconds.
        assert!(twap_a1 >= (POOL_AMOUNT as u128) * 100, 2);
        assert!(twap_b1 >= (POOL_AMOUNT as u128) * 100, 3);
    }

    // =========================================================
    //                     ROUTER TESTS
    // =========================================================

    #[test(darbitex = @darbitex, user = @0x100, framework = @0x1)]
    #[expected_failure(abort_code = 1, location = darbitex::router)]
    fun test_router_deadline_abort(
        darbitex: &signer, user: &signer, framework: &signer,
    ) acquires TestMints {
        let (meta_a, meta_b) = setup(framework, darbitex);
        pool_factory::create_canonical_pool(darbitex, meta_a, meta_b, POOL_AMOUNT);
        let pool_addr = pool_factory::canonical_pool_address(meta_a, meta_b);

        account::create_account_for_test(@0x100);
        give_tokens(@0x100, 1_000_000);

        timestamp::fast_forward_seconds(1000);
        router::swap_with_deadline(user, pool_addr, meta_a, 1_000_000, 0, 500);
    }

    #[test(darbitex = @darbitex, user = @0x100, framework = @0x1)]
    #[expected_failure(abort_code = 2, location = darbitex::router)]
    fun test_router_2hop_same_pool_abort(
        darbitex: &signer, user: &signer, framework: &signer,
    ) acquires TestMints {
        let (meta_a, meta_b) = setup(framework, darbitex);
        pool_factory::create_canonical_pool(darbitex, meta_a, meta_b, POOL_AMOUNT);
        let pool_addr = pool_factory::canonical_pool_address(meta_a, meta_b);
        account::create_account_for_test(@0x100);
        give_tokens(@0x100, 1_000_000);
        router::swap_2hop(
            user, pool_addr, pool_addr, meta_a, 1_000_000, 0, 1_000_000_000,
        );
    }

    #[test(darbitex = @darbitex, user = @0x100, framework = @0x1)]
    fun test_router_2hop_via_third_token(
        darbitex: &signer, user: &signer, framework: &signer,
    ) acquires TestMints, TestMintC {
        let (meta_a, meta_b, meta_c) = setup_with_third(framework, darbitex);

        // Build pool A↔C and pool C↔B (sort each pair).
        let (a1, a2) = sort_pair(meta_a, meta_c);
        let (b1, b2) = sort_pair(meta_c, meta_b);
        pool_factory::create_canonical_pool(darbitex, a1, a2, POOL_AMOUNT);
        pool_factory::create_canonical_pool(darbitex, b1, b2, POOL_AMOUNT);
        let pool_ac = pool_factory::canonical_pool_address(a1, a2);
        let pool_cb = pool_factory::canonical_pool_address(b1, b2);
        assert!(pool_ac != pool_cb, 1);

        account::create_account_for_test(@0x100);
        give_tokens(@0x100, 2_000_000);
        give_token_c(@0x100, 2_000_000);

        let before_b = bal(@0x100, meta_b);
        router::swap_2hop(
            user, pool_ac, pool_cb, meta_a, 1_000_000, 0, 1_000_000_000,
        );
        let after_b = bal(@0x100, meta_b);
        assert!(after_b > before_b, 2);
    }
}
