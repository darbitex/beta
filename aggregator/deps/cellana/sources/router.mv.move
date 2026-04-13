module 0x4bf51972879e3b95c4781a5cdcb9e1ee24ef483e7d22f2d903626f126df62bd1::router {
    use 0x1::aptos_account;
    use 0x1::coin;
    use 0x1::error;
    use 0x1::fungible_asset;
    use 0x1::object;
    use 0x1::primary_fungible_store;
    use 0x1::vector;
    use 0x4bf51972879e3b95c4781a5cdcb9e1ee24ef483e7d22f2d903626f126df62bd1::coin_wrapper;
    use 0x4bf51972879e3b95c4781a5cdcb9e1ee24ef483e7d22f2d903626f126df62bd1::gauge;
    use 0x4bf51972879e3b95c4781a5cdcb9e1ee24ef483e7d22f2d903626f126df62bd1::liquidity_pool;
    use 0x4bf51972879e3b95c4781a5cdcb9e1ee24ef483e7d22f2d903626f126df62bd1::vote_manager;
    public fun swap(p0: fungible_asset::FungibleAsset, p1: u64, p2: object::Object<fungible_asset::Metadata>, p3: bool): fungible_asset::FungibleAsset {
        let _v0 = liquidity_pool::swap(liquidity_pool::liquidity_pool(fungible_asset::asset_metadata(&p0), p2, p3), p0);
        assert!(fungible_asset::amount(&_v0) >= p1, 1);
        _v0
    }
    public fun add_liquidity(p0: &signer, p1: fungible_asset::FungibleAsset, p2: fungible_asset::FungibleAsset, p3: bool) {
        abort 0
    }
    public entry fun add_liquidity_and_stake_both_coins_entry<T0, T1>(p0: &signer, p1: bool, p2: u64, p3: u64) {
        let _v0 = coin_wrapper::get_wrapper<T0>();
        let _v1 = coin_wrapper::get_wrapper<T1>();
        let _v2 = liquidity_pool::liquidity_pool(_v0, _v1, p1);
        let _v3 = coin_wrapper::get_wrapper<T0>();
        let _v4 = coin_wrapper::get_wrapper<T1>();
        let (_v5,_v6) = get_optimal_amounts(_v3, _v4, p1, p2, p3);
        let _v7 = coin::withdraw<T0>(p0, _v5);
        let _v8 = coin::withdraw<T1>(p0, _v6);
        let _v9 = coin_wrapper::wrap<T0>(_v7);
        let _v10 = coin_wrapper::wrap<T1>(_v8);
        let _v11 = liquidity_pool::mint_lp(p0, _v9, _v10, p1);
        let _v12 = vote_manager::get_gauge(_v2);
        gauge::stake(p0, _v12, _v11);
    }
    public entry fun add_liquidity_and_stake_coin_entry<T0>(p0: &signer, p1: object::Object<fungible_asset::Metadata>, p2: bool, p3: u64, p4: u64) {
        let _v0 = liquidity_pool::liquidity_pool(coin_wrapper::get_wrapper<T0>(), p1, p2);
        let (_v1,_v2) = get_optimal_amounts(coin_wrapper::get_wrapper<T0>(), p1, p2, p3, p4);
        let _v3 = _v2;
        let _v4 = coin::withdraw<T0>(p0, _v1);
        let _v5 = exact_withdraw<fungible_asset::Metadata>(p0, p1, _v3);
        let _v6 = fungible_asset::amount(&_v5);
        assert!(_v3 == _v6, 4);
        let _v7 = coin_wrapper::wrap<T0>(_v4);
        let _v8 = liquidity_pool::mint_lp(p0, _v7, _v5, p2);
        let _v9 = vote_manager::get_gauge(_v0);
        gauge::stake(p0, _v9, _v8);
    }
    public entry fun add_liquidity_and_stake_entry(p0: &signer, p1: object::Object<fungible_asset::Metadata>, p2: object::Object<fungible_asset::Metadata>, p3: bool, p4: u64, p5: u64) {
        let _v0 = liquidity_pool::liquidity_pool(p1, p2, p3);
        let (_v1,_v2) = get_optimal_amounts(p1, p2, p3, p4, p5);
        let _v3 = _v2;
        let _v4 = _v1;
        let _v5 = exact_withdraw<fungible_asset::Metadata>(p0, p1, _v4);
        let _v6 = fungible_asset::amount(&_v5);
        assert!(_v4 == _v6, 4);
        let _v7 = exact_withdraw<fungible_asset::Metadata>(p0, p2, _v3);
        let _v8 = fungible_asset::amount(&_v7);
        assert!(_v3 == _v8, 4);
        let _v9 = liquidity_pool::mint_lp(p0, _v5, _v7, p3);
        let _v10 = vote_manager::get_gauge(_v0);
        gauge::stake(p0, _v10, _v9);
    }
    public fun add_liquidity_both_coins<T0, T1>(p0: &signer, p1: coin::Coin<T0>, p2: coin::Coin<T1>, p3: bool) {
        abort 0
    }
    public entry fun add_liquidity_both_coins_entry<T0, T1>(p0: &signer, p1: bool, p2: u64, p3: u64) {
        abort 0
    }
    public fun add_liquidity_coin<T0>(p0: &signer, p1: coin::Coin<T0>, p2: fungible_asset::FungibleAsset, p3: bool) {
        abort 0
    }
    public entry fun add_liquidity_coin_entry<T0>(p0: &signer, p1: object::Object<fungible_asset::Metadata>, p2: bool, p3: u64, p4: u64) {
        abort 0
    }
    public entry fun add_liquidity_entry(p0: &signer, p1: object::Object<fungible_asset::Metadata>, p2: object::Object<fungible_asset::Metadata>, p3: bool, p4: u64, p5: u64) {
        abort 0
    }
    public entry fun create_pool(p0: object::Object<fungible_asset::Metadata>, p1: object::Object<fungible_asset::Metadata>, p2: bool) {
        let _v0 = liquidity_pool::create(p0, p1, p2);
        vote_manager::whitelist_default_reward_pool(_v0);
        vote_manager::create_gauge_internal(_v0);
    }
    public entry fun create_pool_both_coins<T0, T1>(p0: bool) {
        let _v0 = coin_wrapper::create_fungible_asset<T0>();
        let _v1 = coin_wrapper::create_fungible_asset<T1>();
        let _v2 = liquidity_pool::create(_v0, _v1, p0);
        vote_manager::whitelist_default_reward_pool(_v2);
        vote_manager::create_gauge_internal(_v2);
    }
    public entry fun create_pool_coin<T0>(p0: object::Object<fungible_asset::Metadata>, p1: bool) {
        let _v0 = liquidity_pool::create(coin_wrapper::create_fungible_asset<T0>(), p0, p1);
        vote_manager::whitelist_default_reward_pool(_v0);
        vote_manager::create_gauge_internal(_v0);
    }
    friend fun exact_deposit(p0: address, p1: fungible_asset::FungibleAsset) {
        let _v0 = fungible_asset::amount(&p1);
        let _v1 = fungible_asset::asset_metadata(&p1);
        let _v2 = primary_fungible_store::balance<fungible_asset::Metadata>(p0, _v1);
        primary_fungible_store::deposit(p0, p1);
        let _v3 = primary_fungible_store::balance<fungible_asset::Metadata>(p0, _v1) - _v2;
        assert!(_v0 == _v3, 6);
    }
    friend fun exact_withdraw<T0: key>(p0: &signer, p1: object::Object<T0>, p2: u64): fungible_asset::FungibleAsset {
        let _v0 = primary_fungible_store::withdraw<T0>(p0, p1, p2);
        assert!(fungible_asset::amount(&_v0) == p2, 6);
        _v0
    }
    public fun get_amount_out(p0: u64, p1: object::Object<fungible_asset::Metadata>, p2: object::Object<fungible_asset::Metadata>, p3: bool): (u64, u64) {
        let (_v0,_v1) = liquidity_pool::get_amount_out(liquidity_pool::liquidity_pool(p1, p2, p3), p1, p0);
        (_v0, _v1)
    }
    public fun get_amounts_out(p0: u64, p1: object::Object<fungible_asset::Metadata>, p2: vector<address>, p3: vector<bool>): u64 {
        let _v0 = vector::length<address>(&p2);
        let _v1 = vector::length<bool>(&p3);
        assert!(_v0 == _v1, 4);
        let _v2 = p0;
        let _v3 = p1;
        let _v4 = p3;
        let _v5 = p2;
        vector::reverse<address>(&mut _v5);
        vector::reverse<bool>(&mut _v4);
        let _v6 = _v4;
        let _v7 = _v5;
        let _v8 = vector::length<address>(&_v7);
        let _v9 = vector::length<bool>(&_v6);
        assert!(_v8 == _v9, 131074);
        while (_v8 > 0) {
            let _v10 = vector::pop_back<address>(&mut _v7);
            let _v11 = vector::pop_back<bool>(&mut _v6);
            let _v12 = object::address_to_object<fungible_asset::Metadata>(_v10);
            let (_v13,_v14) = get_amount_out(_v2, _v3, _v12, _v11);
            _v3 = _v12;
            _v2 = _v13;
            _v8 = _v8 - 1;
            continue
        };
        vector::destroy_empty<address>(_v7);
        vector::destroy_empty<bool>(_v6);
        _v2
    }
    fun get_optimal_amounts(p0: object::Object<fungible_asset::Metadata>, p1: object::Object<fungible_asset::Metadata>, p2: bool, p3: u64, p4: u64): (u64, u64) {
        let _v0;
        let _v1;
        let _v2;
        if (p3 > 0) _v2 = p4 > 0 else _v2 = false;
        assert!(_v2, 4);
        let _v3 = quote_liquidity(p0, p1, p2, p3);
        if (_v3 == 0) {
            _v0 = p4;
            _v1 = p3
        } else {
            let _v4;
            let _v5;
            if (_v3 <= p4) {
                _v4 = _v3;
                _v5 = p3
            } else {
                let _v6 = quote_liquidity(p1, p0, p2, p4);
                _v4 = p4;
                _v5 = _v6
            };
            _v0 = _v4;
            _v1 = _v5
        };
        (_v1, _v0)
    }
    public fun get_trade_diff(p0: u64, p1: object::Object<fungible_asset::Metadata>, p2: object::Object<fungible_asset::Metadata>, p3: bool): (u64, u64) {
        let (_v0,_v1) = liquidity_pool::get_trade_diff(liquidity_pool::liquidity_pool(p1, p2, p3), p1, p0);
        (_v0, _v1)
    }
    public fun liquidity_amount_out(p0: object::Object<fungible_asset::Metadata>, p1: object::Object<fungible_asset::Metadata>, p2: bool, p3: u64, p4: u64): u64 {
        liquidity_pool::liquidity_out(p0, p1, p2, p3, p4)
    }
    public fun quote_liquidity(p0: object::Object<fungible_asset::Metadata>, p1: object::Object<fungible_asset::Metadata>, p2: bool, p3: u64): u64 {
        let _v0;
        let _v1;
        let (_v2,_v3) = liquidity_pool::pool_reserves<liquidity_pool::LiquidityPool>(liquidity_pool::liquidity_pool(p0, p1, p2));
        let _v4 = _v3;
        let _v5 = _v2;
        if (!liquidity_pool::is_sorted(p0, p1)) {
            let _v6 = _v4;
            _v4 = _v5;
            _v5 = _v6
        };
        if (_v5 == 0) _v0 = true else _v0 = _v4 == 0;
        if (_v0) _v1 = 0 else {
            let _v7 = _v5;
            if (_v7 != 0) {
                let _v8 = p3 as u128;
                let _v9 = _v4 as u128;
                let _v10 = _v8 * _v9;
                let _v11 = _v7 as u128;
                _v1 = (_v10 / _v11) as u64
            } else {
                let _v12 = error::invalid_argument(4);
                abort _v12
            }
        };
        _v1
    }
    public fun redeemable_liquidity(p0: object::Object<liquidity_pool::LiquidityPool>, p1: u64): (u64, u64) {
        let (_v0,_v1) = liquidity_pool::liquidity_amounts(p0, p1);
        (_v0, _v1)
    }
    public fun remove_liquidity(p0: &signer, p1: object::Object<fungible_asset::Metadata>, p2: object::Object<fungible_asset::Metadata>, p3: bool, p4: u64, p5: u64, p6: u64): (fungible_asset::FungibleAsset, fungible_asset::FungibleAsset) {
        abort 0
    }
    public fun remove_liquidity_both_coins<T0, T1>(p0: &signer, p1: bool, p2: u64, p3: u64, p4: u64): (coin::Coin<T0>, coin::Coin<T1>) {
        abort 0
    }
    public entry fun remove_liquidity_both_coins_entry<T0, T1>(p0: &signer, p1: bool, p2: u64, p3: u64, p4: u64, p5: address) {
        abort 0
    }
    public fun remove_liquidity_coin<T0>(p0: &signer, p1: object::Object<fungible_asset::Metadata>, p2: bool, p3: u64, p4: u64, p5: u64): (coin::Coin<T0>, fungible_asset::FungibleAsset) {
        abort 0
    }
    public entry fun remove_liquidity_coin_entry<T0>(p0: &signer, p1: object::Object<fungible_asset::Metadata>, p2: bool, p3: u64, p4: u64, p5: u64, p6: address) {
        abort 0
    }
    public entry fun remove_liquidity_entry(p0: &signer, p1: object::Object<fungible_asset::Metadata>, p2: object::Object<fungible_asset::Metadata>, p3: bool, p4: u64, p5: u64, p6: u64, p7: address) {
        abort 0
    }
    fun remove_liquidity_internal(p0: &signer, p1: object::Object<fungible_asset::Metadata>, p2: object::Object<fungible_asset::Metadata>, p3: bool, p4: u64, p5: u64, p6: u64): (fungible_asset::FungibleAsset, fungible_asset::FungibleAsset) {
        let _v0;
        let (_v1,_v2) = liquidity_pool::burn(p0, p1, p2, p3, p4);
        let _v3 = _v2;
        let _v4 = _v1;
        let _v5 = fungible_asset::amount(&_v4);
        let _v6 = fungible_asset::amount(&_v3);
        if (_v5 >= p5) _v0 = _v6 >= p6 else _v0 = false;
        assert!(_v0, 1);
        (_v4, _v3)
    }
    public fun swap_asset_for_coin<T0>(p0: fungible_asset::FungibleAsset, p1: u64, p2: bool): coin::Coin<T0> {
        let _v0 = coin_wrapper::get_wrapper<T0>();
        coin_wrapper::unwrap<T0>(swap(p0, p1, _v0, p2))
    }
    public entry fun swap_asset_for_coin_entry<T0>(p0: &signer, p1: u64, p2: u64, p3: object::Object<fungible_asset::Metadata>, p4: bool, p5: address) {
        let _v0 = swap_asset_for_coin<T0>(exact_withdraw<fungible_asset::Metadata>(p0, p3, p1), p2, p4);
        coin::register<T0>(p0);
        aptos_account::deposit_coins<T0>(p5, _v0);
    }
    public fun swap_coin_for_asset<T0>(p0: coin::Coin<T0>, p1: u64, p2: object::Object<fungible_asset::Metadata>, p3: bool): fungible_asset::FungibleAsset {
        swap(coin_wrapper::wrap<T0>(p0), p1, p2, p3)
    }
    public entry fun swap_coin_for_asset_entry<T0>(p0: &signer, p1: u64, p2: u64, p3: object::Object<fungible_asset::Metadata>, p4: bool, p5: address) {
        let _v0 = swap_coin_for_asset<T0>(coin::withdraw<T0>(p0, p1), p2, p3, p4);
        exact_deposit(p5, _v0);
    }
    public fun swap_coin_for_coin<T0, T1>(p0: coin::Coin<T0>, p1: u64, p2: bool): coin::Coin<T1> {
        swap_asset_for_coin<T1>(coin_wrapper::wrap<T0>(p0), p1, p2)
    }
    public entry fun swap_coin_for_coin_entry<T0, T1>(p0: &signer, p1: u64, p2: u64, p3: bool, p4: address) {
        let _v0 = swap_coin_for_coin<T0, T1>(coin::withdraw<T0>(p0, p1), p2, p3);
        coin::register<T1>(p0);
        coin::deposit<T1>(p4, _v0);
    }
    public entry fun swap_entry(p0: &signer, p1: u64, p2: u64, p3: object::Object<fungible_asset::Metadata>, p4: object::Object<fungible_asset::Metadata>, p5: bool, p6: address) {
        assert!(!coin_wrapper::is_wrapper(p4), 3);
        let _v0 = swap(exact_withdraw<fungible_asset::Metadata>(p0, p3, p1), p2, p4, p5);
        exact_deposit(p6, _v0);
    }
    public entry fun swap_route_entry(p0: &signer, p1: u64, p2: u64, p3: object::Object<fungible_asset::Metadata>, p4: vector<object::Object<fungible_asset::Metadata>>, p5: vector<bool>, p6: address) {
        let _v0 = &p4;
        let _v1 = vector::length<object::Object<fungible_asset::Metadata>>(&p4) - 1;
        assert!(!coin_wrapper::is_wrapper(*vector::borrow<object::Object<fungible_asset::Metadata>>(_v0, _v1)), 3);
        let _v2 = swap_router(exact_withdraw<fungible_asset::Metadata>(p0, p3, p1), p2, p4, p5);
        exact_deposit(p6, _v2);
    }
    public entry fun swap_route_entry_both_coins<T0, T1>(p0: &signer, p1: u64, p2: u64, p3: vector<object::Object<fungible_asset::Metadata>>, p4: vector<bool>, p5: address) {
        let _v0 = swap_router(coin_wrapper::wrap<T0>(coin::withdraw<T0>(p0, p1)), p2, p3, p4);
        coin::register<T1>(p0);
        let _v1 = coin_wrapper::unwrap<T1>(_v0);
        coin::deposit<T1>(p5, _v1);
    }
    public entry fun swap_route_entry_from_coin<T0>(p0: &signer, p1: u64, p2: u64, p3: vector<object::Object<fungible_asset::Metadata>>, p4: vector<bool>, p5: address) {
        let _v0 = &p3;
        let _v1 = vector::length<object::Object<fungible_asset::Metadata>>(&p3) - 1;
        assert!(!coin_wrapper::is_wrapper(*vector::borrow<object::Object<fungible_asset::Metadata>>(_v0, _v1)), 3);
        let _v2 = swap_router(coin_wrapper::wrap<T0>(coin::withdraw<T0>(p0, p1)), p2, p3, p4);
        exact_deposit(p5, _v2);
    }
    public entry fun swap_route_entry_to_coin<T0>(p0: &signer, p1: u64, p2: u64, p3: object::Object<fungible_asset::Metadata>, p4: vector<object::Object<fungible_asset::Metadata>>, p5: vector<bool>, p6: address) {
        let _v0 = swap_router(exact_withdraw<fungible_asset::Metadata>(p0, p3, p1), p2, p4, p5);
        coin::register<T0>(p0);
        let _v1 = coin_wrapper::unwrap<T0>(_v0);
        coin::deposit<T0>(p6, _v1);
    }
    public fun swap_router(p0: fungible_asset::FungibleAsset, p1: u64, p2: vector<object::Object<fungible_asset::Metadata>>, p3: vector<bool>): fungible_asset::FungibleAsset {
        let _v0 = p0;
        let _v1 = p3;
        let _v2 = p2;
        vector::reverse<object::Object<fungible_asset::Metadata>>(&mut _v2);
        vector::reverse<bool>(&mut _v1);
        let _v3 = _v1;
        let _v4 = _v2;
        let _v5 = vector::length<object::Object<fungible_asset::Metadata>>(&_v4);
        let _v6 = vector::length<bool>(&_v3);
        assert!(_v5 == _v6, 131074);
        while (_v5 > 0) {
            let _v7 = vector::pop_back<object::Object<fungible_asset::Metadata>>(&mut _v4);
            let _v8 = vector::pop_back<bool>(&mut _v3);
            _v0 = swap(_v0, 0, _v7, _v8);
            _v5 = _v5 - 1;
            continue
        };
        vector::destroy_empty<object::Object<fungible_asset::Metadata>>(_v4);
        vector::destroy_empty<bool>(_v3);
        assert!(fungible_asset::amount(&_v0) >= p1, 1);
        _v0
    }
    public entry fun unstake_and_remove_liquidity_both_coins_entry<T0, T1>(p0: &signer, p1: bool, p2: u64, p3: u64, p4: u64, p5: address) {
        let _v0 = coin_wrapper::get_wrapper<T0>();
        let _v1 = coin_wrapper::get_wrapper<T1>();
        let _v2 = vote_manager::get_gauge(liquidity_pool::liquidity_pool(_v0, _v1, p1));
        gauge::unstake_lp(p0, _v2, p2);
        let (_v3,_v4) = remove_liquidity_internal(p0, _v0, _v1, p1, p2, p3, p4);
        let _v5 = coin_wrapper::unwrap<T0>(_v3);
        aptos_account::deposit_coins<T0>(p5, _v5);
        let _v6 = coin_wrapper::unwrap<T1>(_v4);
        aptos_account::deposit_coins<T1>(p5, _v6);
    }
    public entry fun unstake_and_remove_liquidity_coin_entry<T0>(p0: &signer, p1: object::Object<fungible_asset::Metadata>, p2: bool, p3: u64, p4: u64, p5: u64, p6: address) {
        let _v0 = coin_wrapper::get_wrapper<T0>();
        let _v1 = vote_manager::get_gauge(liquidity_pool::liquidity_pool(_v0, p1, p2));
        gauge::unstake_lp(p0, _v1, p3);
        assert!(!coin_wrapper::is_wrapper(p1), 3);
        let (_v2,_v3) = remove_liquidity_internal(p0, _v0, p1, p2, p3, p4, p5);
        let _v4 = coin_wrapper::unwrap<T0>(_v2);
        aptos_account::deposit_coins<T0>(p6, _v4);
        primary_fungible_store::deposit(p6, _v3);
    }
    public entry fun unstake_and_remove_liquidity_entry(p0: &signer, p1: object::Object<fungible_asset::Metadata>, p2: object::Object<fungible_asset::Metadata>, p3: bool, p4: u64, p5: u64, p6: u64, p7: address) {
        let _v0;
        let _v1 = vote_manager::get_gauge(liquidity_pool::liquidity_pool(p1, p2, p3));
        gauge::unstake_lp(p0, _v1, p4);
        if (!coin_wrapper::is_wrapper(p1)) _v0 = !coin_wrapper::is_wrapper(p2) else _v0 = false;
        assert!(_v0, 3);
        let (_v2,_v3) = remove_liquidity_internal(p0, p1, p2, p3, p4, p5, p6);
        primary_fungible_store::deposit(p7, _v2);
        primary_fungible_store::deposit(p7, _v3);
    }
}
