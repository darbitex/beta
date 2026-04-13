module 0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c::router_v3 {
    use 0x1::object;
    use 0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c::position_v3;
    use 0x1::fungible_asset;
    use 0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c::i32;
    use 0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c::pool_v3;
    use 0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c::swap_math;
    use 0x1::primary_fungible_store;
    use 0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c::utils;
    use 0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c::tick_math;
    use 0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c::rate_limiter_check;
    use 0x1::signer;
    use 0x1::vector;
    use 0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c::caas_integration;
    use 0x92af222254470faeda82d447067ce14b38ceafedb4c7ea462bf6b1e98cecf1f8::passkey;
    use 0x1::coin;
    use 0x1::option;
    use 0x1::dispatchable_fungible_asset;
    use 0x1::comparator;
    use 0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c::coin_wrapper;
    use 0x1::aptos_coin;
    use 0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c::fridge;
    use 0x1::string;
    use 0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c::user_label;
    use 0x1::event;
    use 0x1::math64;
    struct AddSingleLiquidityEvent has copy, drop, store {
        pool_id: address,
        caller: address,
        position: object::Object<position_v3::Info>,
        input_amount: u64,
        swap_from: object::Object<fungible_asset::Metadata>,
        swap_to: object::Object<fungible_asset::Metadata>,
        swap_amount_in: u64,
        swap_amount_out: u64,
        delta_lp_amount: u128,
        add_amount_a: u64,
        add_amount_b: u64,
    }
    struct RemoveSingleLiquidityEvent has copy, drop, store {
        pool_id: address,
        caller: address,
        position: object::Object<position_v3::Info>,
        swap_from: object::Object<fungible_asset::Metadata>,
        swap_to: object::Object<fungible_asset::Metadata>,
        swap_amount_in: u64,
        swap_amount_out: u64,
        delta_lp_amount: u128,
        remove_amount_a: u64,
        remove_amount_b: u64,
        output_amount: u64,
    }
    public fun get_amount_by_liquidity(p0: object::Object<position_v3::Info>): (u64, u64) {
        let (_v0,_v1,_v2) = position_v3::get_pool_info(p0);
        let _v3 = _v2;
        let _v4 = _v1;
        let _v5 = _v0;
        let _v6 = position_v3::get_liquidity(p0);
        let (_v7,_v8) = position_v3::get_tick(p0);
        let _v9 = pool_v3::current_tick(_v5, _v4, _v3);
        let _v10 = pool_v3::current_price(_v5, _v4, _v3);
        let (_v11,_v12) = swap_math::get_amount_by_liquidity(_v7, _v8, _v9, _v10, _v6, false);
        (_v11, _v12)
    }
    public entry fun add_incentive(p0: &signer, p1: object::Object<pool_v3::LiquidityPoolV3>, p2: u64, p3: object::Object<fungible_asset::Metadata>, p4: u64) {
        pool_v3::add_incentive(p0, p1, p2, p3, p4);
    }
    public entry fun add_rewarder(p0: &signer, p1: object::Object<pool_v3::LiquidityPoolV3>, p2: object::Object<fungible_asset::Metadata>, p3: u64, p4: u64, p5: u64) {
        pool_v3::add_rewarder(p0, p1, p2, p3, p4, p5);
    }
    public entry fun claim_rewards(p0: &signer, p1: object::Object<position_v3::Info>, p2: address) {
        let _v0 = pool_v3::claim_rewards(p0, p1);
        let _v1 = vector::length<fungible_asset::FungibleAsset>(&_v0);
        while (_v1 != 0) {
            _v1 = _v1 - 1;
            let _v2 = vector::pop_back<fungible_asset::FungibleAsset>(&mut _v0);
            primary_fungible_store::deposit(p2, _v2);
            continue
        };
        vector::destroy_empty<fungible_asset::FungibleAsset>(_v0);
    }
    public entry fun remove_incentive(p0: &signer, p1: object::Object<pool_v3::LiquidityPoolV3>, p2: u64, p3: u64) {
        pool_v3::remove_incentive(p0, p1, p2, p3);
    }
    public entry fun update_emissions_rate(p0: &signer, p1: object::Object<pool_v3::LiquidityPoolV3>, p2: u64, p3: u64) {
        pool_v3::update_emissions_rate(p0, p1, p2, p3);
    }
    public entry fun add_liquidity(p0: &signer, p1: object::Object<position_v3::Info>, p2: object::Object<fungible_asset::Metadata>, p3: object::Object<fungible_asset::Metadata>, p4: u8, p5: u64, p6: u64, p7: u64, p8: u64, p9: u64) {
        let _v0;
        let _v1;
        let _v2;
        let _v3;
        let _v4;
        let _v5;
        let _v6;
        let _v7;
        let _v8 = utils::is_sorted(p2, p3);
        loop {
            if (_v8) {
                let _v9;
                let _v10;
                let (_v11,_v12) = position_v3::get_tick(p1);
                let _v13 = tick_math::get_sqrt_price_at_tick(_v11);
                let _v14 = tick_math::get_sqrt_price_at_tick(_v12);
                let _v15 = pool_v3::current_price(p2, p3, p4);
                if (_v15 <= _v13) {
                    let _v16 = p5 - 1;
                    _v9 = swap_math::get_liquidity_from_a(_v13, _v14, _v16, true);
                    p9 = swap_math::get_delta_a(_v13, _v14, _v9, true);
                    utils::check_diff_tolerance(p9, p5, 1);
                    _v10 = 0
                } else if (_v15 < _v14) {
                    let _v17;
                    let _v18 = p5 - 1;
                    let _v19 = swap_math::get_liquidity_from_a(_v15, _v14, _v18, true);
                    let _v20 = p6 - 1;
                    let _v21 = swap_math::get_liquidity_from_b(_v13, _v15, _v20, true);
                    if (_v19 <= _v21) _v17 = _v19 else _v17 = _v21;
                    let _v22 = swap_math::get_delta_a(_v15, _v14, _v17, true);
                    let _v23 = swap_math::get_delta_b(_v13, _v15, _v17, true);
                    if (_v19 <= _v21) utils::check_diff_tolerance(_v22, p5, 1) else utils::check_diff_tolerance(_v23, p6, 1);
                    _v9 = _v17;
                    p9 = _v22;
                    _v10 = _v23
                } else {
                    let _v24 = p6 - 1;
                    _v15 = swap_math::get_liquidity_from_b(_v13, _v14, _v24, true);
                    let _v25 = swap_math::get_delta_b(_v13, _v14, _v15, true);
                    _v9 = _v15;
                    p9 = 0;
                    _v10 = _v25
                };
                _v0 = p0;
                _v5 = primary_fungible_store::withdraw<fungible_asset::Metadata>(_v0, p2, p9);
                _v0 = p0;
                _v4 = primary_fungible_store::withdraw<fungible_asset::Metadata>(_v0, p3, _v10);
                _v0 = p0;
                _v3 = p2;
                _v2 = p3;
                _v6 = p1;
                let (_v26,_v27,_v28,_v29) = pool_v3::add_liquidity_v2(_v0, _v6, _v9, _v5, _v4);
                _v4 = _v29;
                _v5 = _v28;
                _v1 = _v27;
                _v7 = _v26;
                assert!(_v7 >= p7, 200001);
                if (_v1 >= p8) break;
                abort 200002
            };
            add_liquidity(p0, p1, p3, p2, p4, p6, p5, p8, p7, p9);
            return ()
        };
        let (_v30,_v31,_v32) = position_v3::get_pool_info(_v6);
        let _v33 = pool_v3::liquidity_pool_address(_v30, _v31, _v32);
        let _v34 = object::object_address<fungible_asset::Metadata>(&_v3);
        rate_limiter_check::recover_rate_limiter_v2(_v0, _v33, _v34, _v7);
        let _v35 = object::object_address<fungible_asset::Metadata>(&_v2);
        rate_limiter_check::recover_rate_limiter_v2(_v0, _v33, _v35, _v1);
        primary_fungible_store::deposit(signer::address_of(_v0), _v5);
        primary_fungible_store::deposit(signer::address_of(_v0), _v4);
    }
    public entry fun claim_fees(p0: &signer, p1: vector<address>, p2: address) {
        let _v0 = p1;
        vector::reverse<address>(&mut _v0);
        let _v1 = _v0;
        let _v2 = vector::length<address>(&_v1);
        while (_v2 > 0) {
            let _v3 = object::address_to_object<position_v3::Info>(vector::pop_back<address>(&mut _v1));
            let (_v4,_v5) = pool_v3::claim_fees(p0, _v3);
            primary_fungible_store::deposit(p2, _v4);
            primary_fungible_store::deposit(p2, _v5);
            _v2 = _v2 - 1;
            continue
        };
        vector::destroy_empty<address>(_v1);
    }
    public entry fun open_position(p0: &signer, p1: object::Object<fungible_asset::Metadata>, p2: object::Object<fungible_asset::Metadata>, p3: u8, p4: u32, p5: u32, p6: u64) {
        let _v0 = pool_v3::open_position(p0, p1, p2, p3, p4, p5);
    }
    public entry fun remove_liquidity(p0: &signer, p1: object::Object<position_v3::Info>, p2: u128, p3: u64, p4: u64, p5: address, p6: u64) {
        if (passkey::is_user_registered<caas_integration::Witness>(signer::address_of(p0))) abort 200030;
        remove_liquidity_internal_for_normal_interface(p0, p1, p2, p3, p4, p5, p6);
    }
    fun remove_liquidity_internal_for_normal_interface(p0: &signer, p1: object::Object<position_v3::Info>, p2: u128, p3: u64, p4: u64, p5: address, p6: u64) {
        let _v0;
        let _v1;
        let _v2;
        let _v3;
        let _v4;
        let (_v5,_v6,_v7) = position_v3::get_pool_info(p1);
        let _v8 = _v6;
        let _v9 = _v5;
        let _v10 = pool_v3::liquidity_pool_address(_v9, _v8, _v7);
        let _v11 = object::object_address<position_v3::Info>(&p1);
        let _v12 = p0;
        let (_v13,_v14) = pool_v3::remove_liquidity_v2(_v12, p1, p2);
        _v12 = p0;
        let _v15 = _v14;
        let _v16 = _v13;
        let _v17 = _v15;
        let _v18 = _v9;
        let _v19 = _v8;
        let _v20 = object::object_address<fungible_asset::Metadata>(&_v18);
        let _v21 = object::object_address<fungible_asset::Metadata>(&_v19);
        if (option::is_some<fungible_asset::FungibleAsset>(&_v16)) {
            p6 = fungible_asset::amount(option::borrow<fungible_asset::FungibleAsset>(&_v16));
            assert!(p6 >= p3, 200001);
            _v3 = p6
        } else if (p3 == 0) _v3 = 0 else abort 200001;
        if (option::is_some<fungible_asset::FungibleAsset>(&_v17)) {
            let _v22 = fungible_asset::amount(option::borrow<fungible_asset::FungibleAsset>(&_v17));
            assert!(_v22 >= p4, 200002);
            _v2 = _v22
        } else if (p4 == 0) _v2 = 0 else abort 200002;
        if (rate_limiter_check::is_rate_limiter_passed(_v12, _v20, _v3)) _v1 = rate_limiter_check::is_rate_limiter_passed(_v12, _v21, _v2) else _v1 = false;
        if (_v1) {
            _v4 = _v16;
            _v15 = _v17
        } else {
            fridge::set_box(_v12, _v10, _v11, _v16, _v17, _v18, _v19);
            _v4 = option::none<fungible_asset::FungibleAsset>();
            _v15 = option::none<fungible_asset::FungibleAsset>()
        };
        let _v23 = _v4;
        let _v24 = _v15;
        if (option::is_some<fungible_asset::FungibleAsset>(&_v23)) {
            _v0 = option::destroy_some<fungible_asset::FungibleAsset>(_v23);
            primary_fungible_store::deposit(p5, _v0)
        } else option::destroy_none<fungible_asset::FungibleAsset>(_v23);
        if (option::is_some<fungible_asset::FungibleAsset>(&_v24)) {
            _v0 = option::destroy_some<fungible_asset::FungibleAsset>(_v24);
            primary_fungible_store::deposit(p5, _v0);
            return ()
        };
        option::destroy_none<fungible_asset::FungibleAsset>(_v24);
    }
    public entry fun add_coin_incentive<T0>(p0: &signer, p1: object::Object<pool_v3::LiquidityPoolV3>, p2: u64, p3: u64) {
        pool_v3::add_coin_incentive<T0>(p0, p1, p2, p3);
    }
    public entry fun add_coin_incentive_v2<T0>(p0: &signer, p1: object::Object<pool_v3::LiquidityPoolV3>, p2: u64, p3: u64, p4: u64) {
        pool_v3::add_coin_incentive_v2<T0>(p0, p1, p2, p3, p4);
    }
    public entry fun add_incentive_v2(p0: &signer, p1: object::Object<pool_v3::LiquidityPoolV3>, p2: u64, p3: object::Object<fungible_asset::Metadata>, p4: u64, p5: u64) {
        pool_v3::add_incentive_v2(p0, p1, p2, p3, p4, p5);
    }
    public entry fun create_pool(p0: object::Object<fungible_asset::Metadata>, p1: object::Object<fungible_asset::Metadata>, p2: u8, p3: u32) {
        let _v0 = pool_v3::create_pool(p0, p1, p2, p3);
    }
    public entry fun exact_input_asset_for_coin_entry<T0>(p0: &signer, p1: u8, p2: u64, p3: u64, p4: u128, p5: object::Object<fungible_asset::Metadata>, p6: address, p7: u64) {
        let _v0 = coin::paired_metadata<T0>();
        let _v1 = option::extract<object::Object<fungible_asset::Metadata>>(&mut _v0);
        exact_input_swap_entry(p0, p1, p2, p3, p4, p5, _v1, p6, p7);
    }
    public entry fun exact_input_swap_entry(p0: &signer, p1: u8, p2: u64, p3: u64, p4: u128, p5: object::Object<fungible_asset::Metadata>, p6: object::Object<fungible_asset::Metadata>, p7: address, p8: u64) {
        let _v0 = pool_v3::liquidity_pool(p5, p6, p1);
        let _v1 = utils::is_sorted(p5, p6);
        if (!_v1) ();
        let _v2 = primary_fungible_store::primary_store<fungible_asset::Metadata>(signer::address_of(p0), p5);
        let _v3 = dispatchable_fungible_asset::withdraw<fungible_asset::FungibleStore>(p0, _v2, p2);
        let (_v4,_v5,_v6) = pool_v3::swap(_v0, _v1, true, p2, _v3, p4);
        let _v7 = _v6;
        assert!(fungible_asset::amount(&_v7) >= p3, 200003);
        primary_fungible_store::deposit(p7, _v7);
        primary_fungible_store::deposit(p7, _v5);
    }
    public entry fun exact_input_coin_for_asset_entry<T0>(p0: &signer, p1: u8, p2: u64, p3: u64, p4: u128, p5: object::Object<fungible_asset::Metadata>, p6: address, p7: u64) {
        let _v0 = coin::balance<T0>(signer::address_of(p0));
        let _v1 = coin::coin_to_fungible_asset<T0>(coin::withdraw<T0>(p0, _v0));
        primary_fungible_store::deposit(signer::address_of(p0), _v1);
        let _v2 = coin::paired_metadata<T0>();
        let _v3 = option::extract<object::Object<fungible_asset::Metadata>>(&mut _v2);
        exact_input_swap_entry(p0, p1, p2, p3, p4, _v3, p5, p6, p7);
    }
    public entry fun exact_input_coin_for_coin_entry<T0, T1>(p0: &signer, p1: u8, p2: u64, p3: u64, p4: u128, p5: address, p6: u64) {
        let _v0 = coin::balance<T0>(signer::address_of(p0));
        let _v1 = coin::coin_to_fungible_asset<T0>(coin::withdraw<T0>(p0, _v0));
        primary_fungible_store::deposit(signer::address_of(p0), _v1);
        let _v2 = coin::paired_metadata<T0>();
        let _v3 = option::extract<object::Object<fungible_asset::Metadata>>(&mut _v2);
        let _v4 = coin::paired_metadata<T1>();
        let _v5 = option::extract<object::Object<fungible_asset::Metadata>>(&mut _v4);
        exact_input_swap_entry(p0, p1, p2, p3, p4, _v3, _v5, p5, p6);
    }
    public entry fun exact_output_asset_for_coin_entry<T0>(p0: &signer, p1: u8, p2: u64, p3: u64, p4: u128, p5: object::Object<fungible_asset::Metadata>, p6: address, p7: u64) {
        let _v0 = coin::paired_metadata<T0>();
        let _v1 = option::extract<object::Object<fungible_asset::Metadata>>(&mut _v0);
        exact_output_swap_entry(p0, p1, p2, p3, p4, p5, _v1, p6, p7);
    }
    public entry fun exact_output_swap_entry(p0: &signer, p1: u8, p2: u64, p3: u64, p4: u128, p5: object::Object<fungible_asset::Metadata>, p6: object::Object<fungible_asset::Metadata>, p7: address, p8: u64) {
        let _v0 = pool_v3::liquidity_pool(p5, p6, p1);
        let _v1 = utils::is_sorted(p5, p6);
        if (!_v1) ();
        let _v2 = primary_fungible_store::primary_store<fungible_asset::Metadata>(signer::address_of(p0), p5);
        let _v3 = dispatchable_fungible_asset::withdraw<fungible_asset::FungibleStore>(p0, _v2, p2);
        let (_v4,_v5,_v6) = pool_v3::swap(_v0, _v1, false, p3, _v3, p4);
        let _v7 = _v6;
        let _v8 = fungible_asset::amount(&_v7);
        assert!(_v4 <= p2, 200004);
        primary_fungible_store::deposit(p7, _v7);
        primary_fungible_store::deposit(p7, _v5);
    }
    public entry fun exact_output_coin_for_asset_entry<T0>(p0: &signer, p1: u8, p2: u64, p3: u64, p4: u128, p5: object::Object<fungible_asset::Metadata>, p6: address, p7: u64) {
        let _v0 = coin::balance<T0>(signer::address_of(p0));
        let _v1 = coin::coin_to_fungible_asset<T0>(coin::withdraw<T0>(p0, _v0));
        primary_fungible_store::deposit(signer::address_of(p0), _v1);
        let _v2 = coin::paired_metadata<T0>();
        let _v3 = option::extract<object::Object<fungible_asset::Metadata>>(&mut _v2);
        exact_output_swap_entry(p0, p1, p2, p3, p4, _v3, p5, p6, p7);
    }
    public entry fun exact_output_coin_for_coin_entry<T0, T1>(p0: &signer, p1: u8, p2: u64, p3: u64, p4: u128, p5: address, p6: u64) {
        let _v0 = coin::paired_metadata<T0>();
        let _v1 = option::extract<object::Object<fungible_asset::Metadata>>(&mut _v0);
        let _v2 = coin::paired_metadata<T1>();
        let _v3 = option::extract<object::Object<fungible_asset::Metadata>>(&mut _v2);
        exact_output_swap_entry(p0, p1, p2, p3, p4, _v1, _v3, p5, p6);
    }
    public entry fun swap_batch(p0: &signer, p1: vector<address>, p2: object::Object<fungible_asset::Metadata>, p3: object::Object<fungible_asset::Metadata>, p4: u64, p5: u64, p6: address) {
        let _v0 = p2;
        let _v1 = primary_fungible_store::withdraw<fungible_asset::Metadata>(p0, p2, p4);
        let _v2 = p1;
        vector::reverse<address>(&mut _v2);
        let _v3 = _v2;
        let _v4 = vector::length<address>(&_v3);
        'l0: loop {
            loop {
                let _v5;
                let _v6;
                let _v7;
                if (!(_v4 > 0)) break 'l0;
                let _v8 = object::address_to_object<pool_v3::LiquidityPoolV3>(vector::pop_back<address>(&mut _v3));
                let _v9 = pool_v3::supported_inner_assets(_v8);
                let _v10 = *vector::borrow<object::Object<fungible_asset::Metadata>>(&_v9, 0);
                let _v11 = *vector::borrow<object::Object<fungible_asset::Metadata>>(&_v9, 1);
                let _v12 = &_v10;
                let _v13 = &_v0;
                let _v14 = comparator::compare<object::Object<fungible_asset::Metadata>>(_v12, _v13);
                if (comparator::is_equal(&_v14)) _v7 = true else {
                    let _v15 = &_v11;
                    let _v16 = &_v0;
                    let _v17 = comparator::compare<object::Object<fungible_asset::Metadata>>(_v15, _v16);
                    _v7 = comparator::is_equal(&_v17)
                };
                if (!_v7) break;
                let _v18 = &_v10;
                let _v19 = &_v0;
                let _v20 = comparator::compare<object::Object<fungible_asset::Metadata>>(_v18, _v19);
                if (comparator::is_equal(&_v20)) {
                    p2 = _v11;
                    _v6 = true
                } else {
                    p2 = _v10;
                    _v6 = false
                };
                if (_v6) _v5 = tick_math::min_sqrt_price() else _v5 = tick_math::max_sqrt_price();
                let (_v21,_v22,_v23) = pool_v3::swap(_v8, _v6, true, p4, _v1, _v5);
                let _v24 = _v23;
                primary_fungible_store::deposit(signer::address_of(p0), _v22);
                p4 = fungible_asset::amount(&_v24);
                _v1 = _v24;
                _v0 = p2;
                _v4 = _v4 - 1;
                continue
            };
            abort 200006
        };
        vector::destroy_empty<address>(_v3);
        let _v25 = _v1;
        let _v26 = &_v0;
        let _v27 = &p3;
        let _v28 = comparator::compare<object::Object<fungible_asset::Metadata>>(_v26, _v27);
        assert!(comparator::is_equal(&_v28), 200007);
        assert!(fungible_asset::amount(&_v25) >= p5, 200008);
        primary_fungible_store::deposit(p6, _v25);
    }
    public entry fun swap_batch_coin_directly_deposit_entry<T0>(p0: &signer, p1: vector<address>, p2: object::Object<fungible_asset::Metadata>, p3: object::Object<fungible_asset::Metadata>, p4: u64, p5: u64) {
        let _v0 = signer::address_of(p0);
        swap_batch_coin_entry<T0>(p0, p1, p2, p3, p4, p5, _v0);
    }
    public entry fun swap_batch_coin_entry<T0>(p0: &signer, p1: vector<address>, p2: object::Object<fungible_asset::Metadata>, p3: object::Object<fungible_asset::Metadata>, p4: u64, p5: u64, p6: address) {
        let _v0 = coin::balance<T0>(signer::address_of(p0));
        let _v1 = coin::coin_to_fungible_asset<T0>(coin::withdraw<T0>(p0, _v0));
        primary_fungible_store::deposit(signer::address_of(p0), _v1);
        swap_batch(p0, p1, p2, p3, p4, p5, p6);
    }
    public entry fun swap_batch_directly_deposit(p0: &signer, p1: vector<address>, p2: object::Object<fungible_asset::Metadata>, p3: object::Object<fungible_asset::Metadata>, p4: u64, p5: u64) {
        let _v0 = signer::address_of(p0);
        swap_batch(p0, p1, p2, p3, p4, p5, _v0);
    }
    public entry fun add_coin_rewarder<T0>(p0: &signer, p1: object::Object<pool_v3::LiquidityPoolV3>, p2: u64, p3: u64, p4: u64) {
        pool_v3::add_rewarder_coin<T0>(p0, p1, p2, p3, p4);
    }
    public entry fun add_liquidity_both_coins<T0, T1>(p0: &signer, p1: object::Object<position_v3::Info>, p2: u8, p3: u64, p4: u64, p5: u64, p6: u64, p7: u64) {
        let _v0;
        let _v1;
        let _v2;
        let _v3;
        let _v4;
        let _v5;
        let _v6;
        let _v7;
        let _v8;
        let _v9;
        let _v10;
        let _v11;
        let _v12;
        let _v13 = coin::paired_metadata<T0>();
        let _v14 = option::extract<object::Object<fungible_asset::Metadata>>(&mut _v13);
        let _v15 = coin::paired_metadata<T1>();
        let _v16 = option::extract<object::Object<fungible_asset::Metadata>>(&mut _v15);
        if (utils::is_sorted(_v14, _v16)) {
            _v12 = _v14;
            _v11 = _v16;
            _v10 = true;
            p7 = p3;
            _v9 = p4;
            _v8 = p5;
            _v7 = p6
        } else {
            _v12 = _v16;
            _v11 = _v14;
            _v10 = false;
            p7 = p4;
            _v9 = p3;
            _v8 = p6;
            _v7 = p5
        };
        let (_v17,_v18) = position_v3::get_tick(p1);
        let _v19 = tick_math::get_sqrt_price_at_tick(_v17);
        let _v20 = tick_math::get_sqrt_price_at_tick(_v18);
        let _v21 = pool_v3::current_price(_v12, _v11, p2);
        let _v22 = p7;
        let _v23 = _v9;
        if (_v21 <= _v19) {
            let _v24 = _v22 - 1;
            _v6 = swap_math::get_liquidity_from_a(_v19, _v20, _v24, true);
            _v5 = swap_math::get_delta_a(_v19, _v20, _v6, true);
            utils::check_diff_tolerance(_v5, _v22, 1);
            _v4 = 0
        } else if (_v21 < _v20) {
            let _v25;
            let _v26 = _v22 - 1;
            let _v27 = swap_math::get_liquidity_from_a(_v21, _v20, _v26, true);
            let _v28 = _v23 - 1;
            let _v29 = swap_math::get_liquidity_from_b(_v19, _v21, _v28, true);
            if (_v27 <= _v29) _v25 = _v27 else _v25 = _v29;
            _v3 = swap_math::get_delta_a(_v21, _v20, _v25, true);
            _v2 = swap_math::get_delta_b(_v19, _v21, _v25, true);
            if (_v27 <= _v29) utils::check_diff_tolerance(_v3, _v22, 1) else utils::check_diff_tolerance(_v2, _v23, 1);
            _v6 = _v25;
            _v5 = _v3;
            _v4 = _v2
        } else {
            let _v30 = _v23 - 1;
            _v21 = swap_math::get_liquidity_from_b(_v19, _v20, _v30, true);
            let _v31 = swap_math::get_delta_b(_v19, _v20, _v21, true);
            _v6 = _v21;
            _v5 = 0;
            _v4 = _v31
        };
        _v3 = _v5;
        _v2 = _v4;
        if (_v10) {
            _v1 = coin_wrapper::wrap<T0>(coin::withdraw<T0>(p0, _v3));
            _v0 = coin_wrapper::wrap<T1>(coin::withdraw<T1>(p0, _v2))
        } else {
            let _v32 = coin_wrapper::wrap<T1>(coin::withdraw<T1>(p0, _v3));
            let _v33 = coin_wrapper::wrap<T0>(coin::withdraw<T0>(p0, _v2));
            _v1 = _v32;
            _v0 = _v33
        };
        let _v34 = p0;
        let _v35 = _v12;
        let _v36 = _v11;
        let _v37 = p1;
        let (_v38,_v39,_v40,_v41) = pool_v3::add_liquidity_v2(_v34, _v37, _v6, _v1, _v0);
        let _v42 = _v39;
        let _v43 = _v38;
        assert!(_v43 >= _v8, 200001);
        assert!(_v42 >= _v7, 200002);
        let (_v44,_v45,_v46) = position_v3::get_pool_info(_v37);
        let _v47 = pool_v3::liquidity_pool_address(_v44, _v45, _v46);
        let _v48 = object::object_address<fungible_asset::Metadata>(&_v35);
        rate_limiter_check::recover_rate_limiter_v2(_v34, _v47, _v48, _v43);
        let _v49 = object::object_address<fungible_asset::Metadata>(&_v36);
        rate_limiter_check::recover_rate_limiter_v2(_v34, _v47, _v49, _v42);
        primary_fungible_store::deposit(signer::address_of(_v34), _v40);
        primary_fungible_store::deposit(signer::address_of(_v34), _v41);
    }
    public fun add_liquidity_by_contract(p0: &signer, p1: object::Object<position_v3::Info>, p2: u64, p3: u64, p4: u64, p5: u64, p6: fungible_asset::FungibleAsset, p7: fungible_asset::FungibleAsset, p8: u64): (u64, u64, fungible_asset::FungibleAsset, fungible_asset::FungibleAsset) {
        let _v0;
        let (_v1,_v2) = position_v3::get_tick(p1);
        let (_v3,_v4,_v5) = position_v3::get_pool_info(p1);
        let _v6 = _v5;
        let _v7 = _v4;
        let _v8 = _v3;
        let _v9 = pool_v3::liquidity_pool_address(_v8, _v7, _v6);
        let _v10 = tick_math::get_sqrt_price_at_tick(_v1);
        let _v11 = tick_math::get_sqrt_price_at_tick(_v2);
        let _v12 = pool_v3::current_price(_v8, _v7, _v6);
        if (_v12 <= _v10) {
            let _v13 = p2 - 1;
            _v0 = swap_math::get_liquidity_from_a(_v10, _v11, _v13, true);
            utils::check_diff_tolerance(swap_math::get_delta_a(_v10, _v11, _v0, true), p2, 1)
        } else if (_v12 < _v11) {
            let _v14;
            let _v15 = p2 - 1;
            let _v16 = swap_math::get_liquidity_from_a(_v12, _v11, _v15, true);
            let _v17 = p3 - 1;
            let _v18 = swap_math::get_liquidity_from_b(_v10, _v12, _v17, true);
            if (_v16 <= _v18) _v14 = _v16 else _v14 = _v18;
            p8 = swap_math::get_delta_a(_v12, _v11, _v14, true);
            let _v19 = swap_math::get_delta_b(_v10, _v12, _v14, true);
            if (_v16 <= _v18) utils::check_diff_tolerance(p8, p2, 1) else utils::check_diff_tolerance(_v19, p3, 1);
            _v0 = _v14
        } else {
            let _v20 = p3 - 1;
            _v12 = swap_math::get_liquidity_from_b(_v10, _v11, _v20, true);
            let _v21 = swap_math::get_delta_b(_v10, _v11, _v12, true);
            _v0 = _v12
        };
        let (_v22,_v23,_v24,_v25) = pool_v3::add_liquidity_v2(p0, p1, _v0, p6, p7);
        let _v26 = _v23;
        p8 = _v22;
        assert!(p8 >= p4, 200001);
        assert!(_v26 >= p5, 200002);
        let _v27 = object::object_address<fungible_asset::Metadata>(&_v8);
        rate_limiter_check::recover_rate_limiter_v2(p0, _v9, _v27, p8);
        let _v28 = object::object_address<fungible_asset::Metadata>(&_v7);
        rate_limiter_check::recover_rate_limiter_v2(p0, _v9, _v28, _v26);
        (p8, _v26, _v24, _v25)
    }
    public entry fun add_liquidity_coin<T0>(p0: &signer, p1: object::Object<position_v3::Info>, p2: object::Object<fungible_asset::Metadata>, p3: u8, p4: u64, p5: u64, p6: u64, p7: u64, p8: u64) {
        let _v0;
        let _v1;
        let _v2;
        let _v3;
        let _v4;
        let _v5;
        let _v6;
        let _v7;
        let _v8;
        let _v9;
        let _v10;
        let _v11;
        let _v12;
        let _v13;
        let _v14 = coin::paired_metadata<T0>();
        let _v15 = option::extract<object::Object<fungible_asset::Metadata>>(&mut _v14);
        if (utils::is_sorted(_v15, p2)) {
            _v13 = _v15;
            _v12 = p2;
            _v11 = true;
            p8 = p4;
            _v10 = p5;
            _v9 = p6;
            _v8 = p7
        } else {
            _v13 = p2;
            _v12 = _v15;
            _v11 = false;
            p8 = p5;
            _v10 = p4;
            _v9 = p7;
            _v8 = p6
        };
        let (_v16,_v17) = position_v3::get_tick(p1);
        let _v18 = tick_math::get_sqrt_price_at_tick(_v16);
        let _v19 = tick_math::get_sqrt_price_at_tick(_v17);
        let _v20 = pool_v3::current_price(_v13, _v12, p3);
        let _v21 = p8;
        let _v22 = _v10;
        if (_v20 <= _v18) {
            let _v23 = _v21 - 1;
            _v7 = swap_math::get_liquidity_from_a(_v18, _v19, _v23, true);
            _v6 = swap_math::get_delta_a(_v18, _v19, _v7, true);
            utils::check_diff_tolerance(_v6, _v21, 1);
            _v5 = 0
        } else if (_v20 < _v19) {
            let _v24;
            let _v25 = _v21 - 1;
            let _v26 = swap_math::get_liquidity_from_a(_v20, _v19, _v25, true);
            let _v27 = _v22 - 1;
            let _v28 = swap_math::get_liquidity_from_b(_v18, _v20, _v27, true);
            if (_v26 <= _v28) _v24 = _v26 else _v24 = _v28;
            _v4 = swap_math::get_delta_a(_v20, _v19, _v24, true);
            _v3 = swap_math::get_delta_b(_v18, _v20, _v24, true);
            if (_v26 <= _v28) utils::check_diff_tolerance(_v4, _v21, 1) else utils::check_diff_tolerance(_v3, _v22, 1);
            _v7 = _v24;
            _v6 = _v4;
            _v5 = _v3
        } else {
            let _v29 = _v22 - 1;
            _v20 = swap_math::get_liquidity_from_b(_v18, _v19, _v29, true);
            let _v30 = swap_math::get_delta_b(_v18, _v19, _v20, true);
            _v7 = _v20;
            _v6 = 0;
            _v5 = _v30
        };
        _v4 = _v6;
        _v3 = _v5;
        if (_v11) {
            _v1 = coin_wrapper::wrap<T0>(coin::withdraw<T0>(p0, _v4));
            _v2 = p0;
            _v0 = primary_fungible_store::withdraw<fungible_asset::Metadata>(_v2, _v12, _v3)
        } else {
            _v2 = p0;
            let _v31 = primary_fungible_store::withdraw<fungible_asset::Metadata>(_v2, _v13, _v4);
            let _v32 = coin_wrapper::wrap<T0>(coin::withdraw<T0>(p0, _v3));
            _v1 = _v31;
            _v0 = _v32
        };
        _v2 = p0;
        let _v33 = _v13;
        let _v34 = _v12;
        let _v35 = p1;
        let (_v36,_v37,_v38,_v39) = pool_v3::add_liquidity_v2(_v2, _v35, _v7, _v1, _v0);
        let _v40 = _v37;
        let _v41 = _v36;
        assert!(_v41 >= _v9, 200001);
        assert!(_v40 >= _v8, 200002);
        let (_v42,_v43,_v44) = position_v3::get_pool_info(_v35);
        let _v45 = pool_v3::liquidity_pool_address(_v42, _v43, _v44);
        let _v46 = object::object_address<fungible_asset::Metadata>(&_v33);
        rate_limiter_check::recover_rate_limiter_v2(_v2, _v45, _v46, _v41);
        let _v47 = object::object_address<fungible_asset::Metadata>(&_v34);
        rate_limiter_check::recover_rate_limiter_v2(_v2, _v45, _v47, _v40);
        primary_fungible_store::deposit(signer::address_of(_v2), _v38);
        primary_fungible_store::deposit(signer::address_of(_v2), _v39);
    }
    public entry fun add_liquidity_single(p0: &signer, p1: object::Object<position_v3::Info>, p2: object::Object<fungible_asset::Metadata>, p3: object::Object<fungible_asset::Metadata>, p4: u64, p5: u256, p6: u256, p7: u256, p8: u256) {
        let _v0 = primary_fungible_store::withdraw<fungible_asset::Metadata>(p0, p2, p4);
        single_liquidity(p0, p1, _v0, p3, p5, p6, p7, p8);
    }
    fun single_liquidity(p0: &signer, p1: object::Object<position_v3::Info>, p2: fungible_asset::FungibleAsset, p3: object::Object<fungible_asset::Metadata>, p4: u256, p5: u256, p6: u256, p7: u256) {
        let _v0;
        let _v1;
        let _v2;
        let _v3;
        let _v4;
        let _v5;
        let _v6;
        assert!(p6 > 0u256, 200019);
        assert!(p7 > 0u256, 200020);
        assert!(p4 > 0u256, 200010);
        assert!(p5 > 0u256, 200011);
        assert!(p5 >= p4, 200012);
        let _v7 = fungible_asset::amount(&p2);
        assert!(_v7 > 0, 200013);
        let _v8 = fungible_asset::metadata_from_asset(&p2);
        assert!(_v8 != p3, 200014);
        let (_v9,_v10,_v11) = position_v3::get_pool_info(p1);
        let _v12 = _v11;
        let _v13 = _v10;
        let _v14 = _v9;
        let (_v15,_v16) = position_v3::get_tick(p1);
        let _v17 = _v16;
        let _v18 = _v15;
        let _v19 = pool_v3::liquidity_pool(_v14, _v13, _v12);
        let _v20 = pool_v3::liquidity_pool_address(_v14, _v13, _v12);
        if (_v8 == _v14) _v6 = p3 == _v13 else _v6 = false;
        if (_v6) {
            let _v21 = i32::as_u32(_v18);
            let _v22 = i32::as_u32(_v17);
            let (_v23,_v24,_v25) = optimal_liquidity_amounts(_v21, _v22, _v14, _v13, _v12, _v7, 100000000000, 0, 0);
            _v5 = _v25;
            _v4 = _v24
        } else {
            if (_v8 == _v13) _v3 = p3 == _v14 else _v3 = false;
            if (_v3) {
                let _v26 = i32::as_u32(_v18);
                let _v27 = i32::as_u32(_v17);
                let (_v28,_v29,_v30) = optimal_liquidity_amounts(_v26, _v27, _v14, _v13, _v12, 100000000000, _v7, 0, 0);
                _v5 = _v30;
                _v4 = _v29
            } else abort 200009
        };
        if (_v4 != 0) _v3 = true else _v3 = _v5 != 0;
        assert!(_v3, 200025);
        if (_v4 != 0) _v2 = _v5 != 0 else _v2 = false;
        'l1: loop {
            let _v31;
            'l2: loop {
                let _v32;
                let _v33;
                let _v34;
                let _v35;
                let _v36;
                'l0: loop {
                    let _v37;
                    let _v38;
                    let _v39;
                    let _v40;
                    loop {
                        let _v41;
                        let _v42;
                        let _v43;
                        let _v44;
                        let _v45;
                        let _v46;
                        let _v47;
                        let _v48;
                        let _v49;
                        if (_v2) {
                            let _v50;
                            let (_v51,_v52) = pool_v3::get_amount_out(_v19, _v8, _v7);
                            let _v53 = fungible_asset::decimals<fungible_asset::Metadata>(_v8) as u64;
                            _v49 = math64::pow(10, _v53) as u256;
                            if (_v8 == _v14) {
                                let _v54 = (_v4 as u256) * _v49;
                                let _v55 = _v5 as u256;
                                _v50 = _v54 / _v55
                            } else {
                                let _v56 = (_v5 as u256) * _v49;
                                let _v57 = _v4 as u256;
                                _v50 = _v56 / _v57
                            };
                            let _v58 = (_v51 as u256) * _v49;
                            let _v59 = _v7 as u256;
                            let _v60 = _v58 / _v59;
                            let _v61 = (_v7 as u256) * _v49 * _v49;
                            let _v62 = _v50 * _v60;
                            let _v63 = _v49 * _v49;
                            let _v64 = _v62 + _v63;
                            _v40 = (_v61 / _v64) as u64;
                            assert!(_v40 > 0, 200015);
                            let (_v65,_v66) = pool_v3::get_amount_out(_v19, _v8, _v40);
                            let _v67 = _v65;
                            let _v68 = _v7 - _v40;
                            if (_v8 == _v14) {
                                let _v69 = i32::as_u32(_v18);
                                let _v70 = i32::as_u32(_v17);
                                let (_v71,_v72,_v73) = optimal_liquidity_amounts(_v69, _v70, _v8, p3, _v12, _v68, _v67, 0, 0);
                                let _v74 = _v73;
                                _v74 = _v67 - _v74;
                                let (_v75,_v76) = pool_v3::get_amount_in(_v19, p3, _v74);
                                _v39 = _v75
                            } else {
                                let _v77 = i32::as_u32(_v18);
                                let _v78 = i32::as_u32(_v17);
                                let (_v79,_v80,_v81) = optimal_liquidity_amounts(_v77, _v78, p3, _v8, _v12, _v67, _v68, 0, 0);
                                _v35 = _v80;
                                _v67 = _v67 - _v35;
                                let (_v82,_v83) = pool_v3::get_amount_in(_v19, p3, _v67);
                                _v39 = _v82
                            };
                            assert!(_v40 > _v39, 200027);
                            let _v84 = (1u256 * _v49) as u64;
                            let (_v85,_v86) = pool_v3::get_amount_out(_v19, _v8, _v84);
                            let _v87 = _v85 as u256;
                            let _v88 = (_v40 - _v39) as u256;
                            _v60 = _v87 * _v88 / _v49 * p4 / p5;
                            if (_v8 == _v14) {
                                _v0 = tick_math::min_sqrt_price();
                                _v47 = true
                            } else {
                                _v0 = tick_math::max_sqrt_price();
                                _v47 = false
                            };
                            assert!(_v40 - _v39 > 0, 200017);
                            let _v89 = ((_v40 - _v39) as u256) * p7;
                            let _v90 = (_v7 as u256) * p6;
                            assert!(_v89 < _v90, 200018);
                            let _v91 = &mut p2;
                            let _v92 = _v40 - _v39;
                            _v36 = fungible_asset::extract(_v91, _v92);
                            let _v93 = _v40 - _v39;
                            let (_v94,_v95,_v96) = pool_v3::swap(_v19, _v47, true, _v93, _v36, _v0);
                            let _v97 = _v96;
                            let _v98 = fungible_asset::amount(&_v97);
                            let _v99 = _v60 as u64;
                            assert!(_v98 >= _v99, 200003);
                            fungible_asset::merge(&mut p2, _v95);
                            assert!(fungible_asset::amount(&_v97) > 0, 200021);
                            assert!(fungible_asset::amount(&p2) > 0, 200022);
                            _v35 = fungible_asset::amount(&_v97);
                            if (fungible_asset::metadata_from_asset(&p2) == _v14) _v46 = fungible_asset::metadata_from_asset(&_v97) == _v13 else _v46 = false;
                            if (_v46) {
                                _v38 = p2;
                                _v37 = _v97;
                                break
                            };
                            if (fungible_asset::metadata_from_asset(&p2) == _v13) _v45 = fungible_asset::metadata_from_asset(&_v97) == _v14 else _v45 = false;
                            assert!(_v45, 200009);
                            _v38 = _v97;
                            _v37 = p2;
                            break
                        };
                        if (_v8 == _v13) _v47 = p3 == _v14 else _v47 = false;
                        if (_v47) _v46 = _v4 == 0 else _v46 = false;
                        if (_v46) _v45 = _v5 != 0 else _v45 = false;
                        if (_v45) {
                            _v44 = false;
                            _v1 = 0;
                            _v43 = false;
                            _v42 = false
                        } else {
                            let _v100;
                            if (_v8 == _v13) _v41 = p3 == _v14 else _v41 = false;
                            if (_v41) _v48 = _v4 != 0 else _v48 = false;
                            if (_v48) _v100 = _v5 == 0 else _v100 = false;
                            if (_v100) {
                                _v44 = true;
                                _v1 = _v7;
                                _v43 = false;
                                _v42 = false
                            } else {
                                let _v101;
                                let _v102;
                                let _v103;
                                if (_v8 == _v14) _v103 = p3 == _v13 else _v103 = false;
                                if (_v103) _v102 = _v4 != 0 else _v102 = false;
                                if (_v102) _v101 = _v5 == 0 else _v101 = false;
                                if (_v101) {
                                    _v44 = false;
                                    _v1 = 0;
                                    _v43 = false;
                                    _v42 = true
                                } else {
                                    let _v104;
                                    let _v105;
                                    let _v106;
                                    if (_v8 == _v14) _v106 = p3 == _v13 else _v106 = false;
                                    if (_v106) _v105 = _v4 == 0 else _v105 = false;
                                    if (_v105) _v104 = _v5 != 0 else _v104 = false;
                                    if (_v104) {
                                        _v44 = true;
                                        _v1 = _v7;
                                        _v43 = true;
                                        _v42 = false
                                    } else abort 200026
                                }
                            }
                        };
                        if (_v44) {
                            let _v107;
                            let _v108;
                            if (_v8 == _v14) _v0 = tick_math::min_sqrt_price() else _v0 = tick_math::max_sqrt_price();
                            let _v109 = fungible_asset::decimals<fungible_asset::Metadata>(_v8) as u64;
                            _v49 = math64::pow(10, _v109) as u256;
                            let _v110 = (1u256 * _v49) as u64;
                            let (_v111,_v112) = pool_v3::get_amount_out(_v19, _v8, _v110);
                            let _v113 = _v111 as u256;
                            let _v114 = _v7 as u256;
                            _v49 = _v113 * _v114 / _v49 * p4 / p5;
                            let (_v115,_v116,_v117) = pool_v3::swap(_v19, _v43, true, _v7, p2, _v0);
                            let _v118 = _v117;
                            let _v119 = _v116;
                            let _v120 = fungible_asset::amount(&_v118);
                            let _v121 = _v49 as u64;
                            assert!(_v120 >= _v121, 200003);
                            _v35 = fungible_asset::amount(&_v118);
                            if (fungible_asset::metadata_from_asset(&_v119) == _v14) _v41 = fungible_asset::metadata_from_asset(&_v118) == _v13 else _v41 = false;
                            if (_v41) {
                                _v108 = _v119;
                                _v107 = _v118
                            } else {
                                if (fungible_asset::metadata_from_asset(&_v119) == _v13) _v48 = fungible_asset::metadata_from_asset(&_v118) == _v14 else _v48 = false;
                                if (_v48) {
                                    _v108 = _v118;
                                    _v107 = _v119
                                } else abort 200009
                            };
                            let _v122 = i32::as_u32(_v18);
                            let _v123 = i32::as_u32(_v17);
                            let _v124 = fungible_asset::amount(&_v108);
                            let _v125 = fungible_asset::amount(&_v107);
                            let (_v126,_v127,_v128) = optimal_liquidity_amounts(_v122, _v123, _v14, _v13, _v12, _v124, _v125, 0, 0);
                            _v34 = _v126;
                            let (_v129,_v130,_v131,_v132) = pool_v3::add_liquidity_v2(p0, p1, _v34, _v108, _v107);
                            _v33 = _v132;
                            _v36 = _v131;
                            _v31 = _v130;
                            _v32 = _v129;
                            if (_v43) {
                                let _v133 = object::object_address<fungible_asset::Metadata>(&_v14);
                                rate_limiter_check::recover_rate_limiter_v2(p0, _v20, _v133, _v32);
                                break 'l0
                            };
                            let _v134 = object::object_address<fungible_asset::Metadata>(&_v13);
                            rate_limiter_check::recover_rate_limiter_v2(p0, _v20, _v134, _v31);
                            break 'l0
                        };
                        if (!_v42) break 'l1;
                        break 'l2
                    };
                    let _v135 = i32::as_u32(_v18);
                    let _v136 = i32::as_u32(_v17);
                    let _v137 = fungible_asset::amount(&_v38);
                    let _v138 = fungible_asset::amount(&_v37);
                    let (_v139,_v140,_v141) = optimal_liquidity_amounts(_v135, _v136, _v14, _v13, _v12, _v137, _v138, 0, 0);
                    _v34 = _v139;
                    let _v142 = fungible_asset::amount(&_v38);
                    let _v143 = fungible_asset::amount(&_v37);
                    let (_v144,_v145,_v146,_v147) = pool_v3::add_liquidity_v2(p0, p1, _v34, _v38, _v37);
                    _v31 = _v145;
                    _v32 = _v144;
                    let _v148 = object::object_address<fungible_asset::Metadata>(&_v14);
                    rate_limiter_check::recover_rate_limiter_v2(p0, _v20, _v148, _v142);
                    let _v149 = object::object_address<fungible_asset::Metadata>(&_v13);
                    rate_limiter_check::recover_rate_limiter_v2(p0, _v20, _v149, _v143);
                    let _v150 = i32::as_u32(_v18);
                    let _v151 = i32::as_u32(_v17);
                    let (_v152,_v153,_v154) = optimal_liquidity_amounts(_v150, _v151, _v14, _v13, _v12, _v32, _v31, 0, 0);
                    primary_fungible_store::deposit(signer::address_of(p0), _v146);
                    primary_fungible_store::deposit(signer::address_of(p0), _v147);
                    let _v155 = signer::address_of(p0);
                    let _v156 = _v40 - _v39;
                    event::emit<AddSingleLiquidityEvent>(AddSingleLiquidityEvent{pool_id: _v20, caller: _v155, position: p1, input_amount: _v7, swap_from: _v8, swap_to: p3, swap_amount_in: _v156, swap_amount_out: _v35, delta_lp_amount: _v34, add_amount_a: _v32, add_amount_b: _v31});
                    return ()
                };
                primary_fungible_store::deposit(signer::address_of(p0), _v36);
                primary_fungible_store::deposit(signer::address_of(p0), _v33);
                let _v157 = signer::address_of(p0);
                event::emit<AddSingleLiquidityEvent>(AddSingleLiquidityEvent{pool_id: _v20, caller: _v157, position: p1, input_amount: _v7, swap_from: _v8, swap_to: p3, swap_amount_in: _v1, swap_amount_out: _v35, delta_lp_amount: _v34, add_amount_a: _v32, add_amount_b: _v31});
                return ()
            };
            let _v158 = i32::as_u32(_v18);
            let _v159 = i32::as_u32(_v17);
            let (_v160,_v161,_v162) = optimal_liquidity_amounts(_v158, _v159, _v14, _v13, _v12, _v7, 0, 0, 0);
            _v0 = _v160;
            let _v163 = fungible_asset::zero<fungible_asset::Metadata>(_v13);
            let (_v164,_v165,_v166,_v167) = pool_v3::add_liquidity_v2(p0, p1, _v0, p2, _v163);
            _v31 = _v164;
            let _v168 = object::object_address<fungible_asset::Metadata>(&_v14);
            rate_limiter_check::recover_rate_limiter_v2(p0, _v20, _v168, _v31);
            primary_fungible_store::deposit(signer::address_of(p0), _v166);
            primary_fungible_store::deposit(signer::address_of(p0), _v167);
            let _v169 = signer::address_of(p0);
            event::emit<AddSingleLiquidityEvent>(AddSingleLiquidityEvent{pool_id: _v20, caller: _v169, position: p1, input_amount: _v7, swap_from: _v8, swap_to: p3, swap_amount_in: _v1, swap_amount_out: 0, delta_lp_amount: _v0, add_amount_a: _v31, add_amount_b: _v165});
            return ()
        };
        let _v170 = i32::as_u32(_v18);
        let _v171 = i32::as_u32(_v17);
        let (_v172,_v173,_v174) = optimal_liquidity_amounts(_v170, _v171, _v14, _v13, _v12, 0, _v7, 0, 0);
        _v0 = _v172;
        let _v175 = fungible_asset::zero<fungible_asset::Metadata>(_v14);
        let (_v176,_v177,_v178,_v179) = pool_v3::add_liquidity_v2(p0, p1, _v0, _v175, p2);
        let _v180 = _v177;
        let _v181 = object::object_address<fungible_asset::Metadata>(&_v13);
        rate_limiter_check::recover_rate_limiter_v2(p0, _v20, _v181, _v180);
        primary_fungible_store::deposit(signer::address_of(p0), _v178);
        primary_fungible_store::deposit(signer::address_of(p0), _v179);
        let _v182 = signer::address_of(p0);
        event::emit<AddSingleLiquidityEvent>(AddSingleLiquidityEvent{pool_id: _v20, caller: _v182, position: p1, input_amount: _v7, swap_from: _v8, swap_to: p3, swap_amount_in: _v1, swap_amount_out: 0, delta_lp_amount: _v0, add_amount_a: _v176, add_amount_b: _v180});
    }
    public entry fun add_liquidity_single_coins<T0>(p0: &signer, p1: object::Object<position_v3::Info>, p2: object::Object<fungible_asset::Metadata>, p3: u64, p4: u256, p5: u256, p6: u256, p7: u256) {
        let _v0 = coin::coin_to_fungible_asset<T0>(coin::withdraw<T0>(p0, p3));
        single_liquidity(p0, p1, _v0, p2, p4, p5, p6, p7);
    }
    public fun apt_transfer_to_coin(p0: &signer) {
        let _v0 = signer::address_of(p0);
        let _v1 = object::address_to_object<fungible_asset::Metadata>(@0xa);
        if (primary_fungible_store::balance<fungible_asset::Metadata>(_v0, _v1) > 0) {
            let _v2 = coin::balance<aptos_coin::AptosCoin>(signer::address_of(p0));
            let _v3 = coin::withdraw<aptos_coin::AptosCoin>(p0, _v2);
            coin::deposit<aptos_coin::AptosCoin>(signer::address_of(p0), _v3);
            return ()
        };
    }
    public entry fun claim_fees_and_rewards(p0: &signer, p1: vector<address>, p2: address) {
        claim_fees(p0, p1, p2);
        let _v0 = p1;
        vector::reverse<address>(&mut _v0);
        let _v1 = _v0;
        let _v2 = vector::length<address>(&_v1);
        while (_v2 > 0) {
            let _v3 = object::address_to_object<position_v3::Info>(vector::pop_back<address>(&mut _v1));
            claim_rewards(p0, _v3, p2);
            _v2 = _v2 - 1;
            continue
        };
        vector::destroy_empty<address>(_v1);
    }
    public entry fun claim_fees_and_rewards_directly_deposit(p0: &signer, p1: vector<address>) {
        let _v0 = signer::address_of(p0);
        claim_fees_and_rewards(p0, p1, _v0);
    }
    public entry fun create_liquidity(p0: &signer, p1: object::Object<fungible_asset::Metadata>, p2: object::Object<fungible_asset::Metadata>, p3: u8, p4: u32, p5: u32, p6: u32, p7: u64, p8: u64, p9: u64, p10: u64, p11: u64) {
        if (!pool_v3::liquidity_pool_exists(p1, p2, p3)) create_pool(p1, p2, p3, p6);
        let _v0 = pool_v3::open_position(p0, p1, p2, p3, p4, p5);
        add_liquidity(p0, _v0, p1, p2, p3, p7, p8, p9, p10, p11);
    }
    public entry fun create_liquidity_both_coins<T0, T1>(p0: &signer, p1: u8, p2: u32, p3: u32, p4: u32, p5: u64, p6: u64, p7: u64, p8: u64, p9: u64) {
        let _v0;
        let _v1;
        let _v2;
        let _v3;
        let _v4;
        let _v5 = coin::paired_metadata<T0>();
        let _v6 = option::extract<object::Object<fungible_asset::Metadata>>(&mut _v5);
        let _v7 = coin::paired_metadata<T1>();
        let _v8 = option::extract<object::Object<fungible_asset::Metadata>>(&mut _v7);
        if (!pool_v3::liquidity_pool_exists(_v6, _v8, p1)) create_pool(_v6, _v8, p1, p4);
        if (utils::is_sorted(_v6, _v8)) {
            _v4 = p5;
            _v3 = p6;
            _v2 = p7;
            _v1 = p8;
            _v0 = true
        } else {
            _v4 = p6;
            _v3 = p5;
            _v2 = p8;
            _v1 = p7;
            _v0 = false
        };
        let _v9 = pool_v3::open_position(p0, _v6, _v8, p1, p2, p3);
        if (_v0) {
            add_liquidity_both_coins<T0, T1>(p0, _v9, p1, _v4, _v3, _v2, _v1, p9);
            return ()
        };
        add_liquidity_both_coins<T1, T0>(p0, _v9, p1, _v4, _v3, _v2, _v1, p9);
    }
    public entry fun create_liquidity_coin<T0>(p0: &signer, p1: object::Object<fungible_asset::Metadata>, p2: u8, p3: u32, p4: u32, p5: u32, p6: u64, p7: u64, p8: u64, p9: u64, p10: u64) {
        let _v0 = coin::paired_metadata<T0>();
        let _v1 = option::extract<object::Object<fungible_asset::Metadata>>(&mut _v0);
        if (!pool_v3::liquidity_pool_exists(p1, _v1, p2)) create_pool(_v1, p1, p2, p5);
        let _v2 = pool_v3::open_position(p0, _v1, p1, p2, p3, p4);
        add_liquidity_coin<T0>(p0, _v2, p1, p2, p6, p7, p8, p9, p10);
    }
    public entry fun create_liquidity_single(p0: &signer, p1: object::Object<fungible_asset::Metadata>, p2: object::Object<fungible_asset::Metadata>, p3: u8, p4: u32, p5: u32, p6: u64, p7: u256, p8: u256, p9: u256, p10: u256) {
        let _v0;
        if (utils::is_sorted(p1, p2)) _v0 = pool_v3::open_position(p0, p1, p2, p3, p4, p5) else _v0 = pool_v3::open_position(p0, p2, p1, p3, p4, p5);
        add_liquidity_single(p0, _v0, p1, p2, p6, p7, p8, p9, p10);
    }
    public entry fun create_liquidity_single_coins<T0>(p0: &signer, p1: object::Object<fungible_asset::Metadata>, p2: u8, p3: u32, p4: u32, p5: u64, p6: u256, p7: u256, p8: u256, p9: u256) {
        let _v0;
        let _v1 = coin::paired_metadata<T0>();
        let _v2 = *option::borrow<object::Object<fungible_asset::Metadata>>(&_v1);
        if (utils::is_sorted(_v2, p1)) _v0 = pool_v3::open_position(p0, _v2, p1, p2, p3, p4) else _v0 = pool_v3::open_position(p0, p1, _v2, p2, p3, p4);
        add_liquidity_single_coins<T0>(p0, _v0, p1, p5, p6, p7, p8, p9);
    }
    public entry fun create_pool_both_coins<T0, T1>(p0: u8, p1: u32) {
        let _v0 = coin::paired_metadata<T0>();
        let _v1 = option::extract<object::Object<fungible_asset::Metadata>>(&mut _v0);
        let _v2 = coin::paired_metadata<T1>();
        let _v3 = option::extract<object::Object<fungible_asset::Metadata>>(&mut _v2);
        create_pool(_v1, _v3, p0, p1);
    }
    public entry fun create_pool_coin<T0>(p0: object::Object<fungible_asset::Metadata>, p1: u8, p2: u32) {
        let _v0 = coin::paired_metadata<T0>();
        create_pool(option::extract<object::Object<fungible_asset::Metadata>>(&mut _v0), p0, p1, p2);
    }
    public fun get_batch_amount_in(p0: vector<address>, p1: u64, p2: object::Object<fungible_asset::Metadata>, p3: object::Object<fungible_asset::Metadata>): u64 {
        let _v0 = p3;
        let _v1 = p0;
        let _v2 = vector::length<address>(&_v1);
        'l0: loop {
            loop {
                let _v3;
                if (!(_v2 > 0)) break 'l0;
                let _v4 = object::address_to_object<pool_v3::LiquidityPoolV3>(vector::pop_back<address>(&mut _v1));
                let _v5 = pool_v3::supported_inner_assets(_v4);
                let _v6 = *vector::borrow<object::Object<fungible_asset::Metadata>>(&_v5, 0);
                let _v7 = *vector::borrow<object::Object<fungible_asset::Metadata>>(&_v5, 1);
                let _v8 = &_v6;
                let _v9 = &_v0;
                let _v10 = comparator::compare<object::Object<fungible_asset::Metadata>>(_v8, _v9);
                if (comparator::is_equal(&_v10)) _v3 = true else {
                    let _v11 = &_v7;
                    let _v12 = &_v0;
                    let _v13 = comparator::compare<object::Object<fungible_asset::Metadata>>(_v11, _v12);
                    _v3 = comparator::is_equal(&_v13)
                };
                if (!_v3) break;
                let _v14 = &_v6;
                let _v15 = &_v0;
                let _v16 = comparator::compare<object::Object<fungible_asset::Metadata>>(_v14, _v15);
                if (comparator::is_equal(&_v16)) p3 = _v7 else p3 = _v6;
                let (_v17,_v18) = pool_v3::get_amount_in(_v4, _v0, p1);
                p1 = _v17 + _v18;
                _v0 = p3;
                _v2 = _v2 - 1;
                continue
            };
            abort 200006
        };
        vector::destroy_empty<address>(_v1);
        let _v19 = &_v0;
        let _v20 = &p2;
        let _v21 = comparator::compare<object::Object<fungible_asset::Metadata>>(_v19, _v20);
        assert!(comparator::is_equal(&_v21), 200009);
        p1
    }
    public fun get_batch_amount_out(p0: vector<address>, p1: u64, p2: object::Object<fungible_asset::Metadata>, p3: object::Object<fungible_asset::Metadata>): u64 {
        let _v0 = p2;
        let _v1 = p0;
        vector::reverse<address>(&mut _v1);
        let _v2 = _v1;
        let _v3 = vector::length<address>(&_v2);
        'l0: loop {
            loop {
                let _v4;
                if (!(_v3 > 0)) break 'l0;
                let _v5 = object::address_to_object<pool_v3::LiquidityPoolV3>(vector::pop_back<address>(&mut _v2));
                let _v6 = pool_v3::supported_inner_assets(_v5);
                let _v7 = *vector::borrow<object::Object<fungible_asset::Metadata>>(&_v6, 0);
                let _v8 = *vector::borrow<object::Object<fungible_asset::Metadata>>(&_v6, 1);
                let _v9 = &_v7;
                let _v10 = &_v0;
                let _v11 = comparator::compare<object::Object<fungible_asset::Metadata>>(_v9, _v10);
                if (comparator::is_equal(&_v11)) _v4 = true else {
                    let _v12 = &_v8;
                    let _v13 = &_v0;
                    let _v14 = comparator::compare<object::Object<fungible_asset::Metadata>>(_v12, _v13);
                    _v4 = comparator::is_equal(&_v14)
                };
                if (!_v4) break;
                let _v15 = &_v7;
                let _v16 = &_v0;
                let _v17 = comparator::compare<object::Object<fungible_asset::Metadata>>(_v15, _v16);
                if (comparator::is_equal(&_v17)) p2 = _v8 else p2 = _v7;
                let (_v18,_v19) = pool_v3::get_amount_out(_v5, _v0, p1);
                p1 = _v18;
                _v0 = p2;
                _v3 = _v3 - 1;
                continue
            };
            abort 200006
        };
        vector::destroy_empty<address>(_v2);
        let _v20 = &_v0;
        let _v21 = &p3;
        let _v22 = comparator::compare<object::Object<fungible_asset::Metadata>>(_v20, _v21);
        assert!(comparator::is_equal(&_v22), 200007);
        p1
    }
    public entry fun open_position_both_coins<T0, T1>(p0: &signer, p1: u8, p2: u32, p3: u32, p4: u64) {
        let _v0 = coin::paired_metadata<T0>();
        let _v1 = option::extract<object::Object<fungible_asset::Metadata>>(&mut _v0);
        let _v2 = coin::paired_metadata<T1>();
        let _v3 = option::extract<object::Object<fungible_asset::Metadata>>(&mut _v2);
        let _v4 = pool_v3::open_position(p0, _v1, _v3, p1, p2, p3);
    }
    public entry fun open_position_coin<T0>(p0: &signer, p1: object::Object<fungible_asset::Metadata>, p2: u8, p3: u32, p4: u32, p5: u64) {
        let _v0 = coin::paired_metadata<T0>();
        let _v1 = option::extract<object::Object<fungible_asset::Metadata>>(&mut _v0);
        let _v2 = pool_v3::open_position(p0, _v1, p1, p2, p3, p4);
    }
    public fun optimal_liquidity_amounts(p0: u32, p1: u32, p2: object::Object<fungible_asset::Metadata>, p3: object::Object<fungible_asset::Metadata>, p4: u8, p5: u64, p6: u64, p7: u64, p8: u64): (u128, u64, u64) {
        let _v0;
        let _v1 = utils::is_sorted(p2, p3);
        loop {
            if (_v1) {
                let _v2;
                let _v3;
                let _v4 = i32::from_u32(p0);
                let _v5 = i32::from_u32(p1);
                let (_v6,_v7) = pool_v3::current_tick_and_price(pool_v3::liquidity_pool_address(p2, p3, p4));
                let _v8 = _v7;
                let _v9 = tick_math::get_sqrt_price_at_tick(_v4);
                let _v10 = tick_math::get_sqrt_price_at_tick(_v5);
                if (_v8 <= _v9) {
                    let _v11 = p5 - 1;
                    _v0 = swap_math::get_liquidity_from_a(_v9, _v10, _v11, false);
                    p7 = swap_math::get_delta_a(_v9, _v10, _v0, true);
                    p8 = 0;
                    break
                };
                if (!(_v8 < _v10)) {
                    let _v12 = p6 - 1;
                    _v3 = swap_math::get_liquidity_from_b(_v9, _v10, _v12, false);
                    let _v13 = swap_math::get_delta_b(_v9, _v10, _v3, true);
                    _v0 = _v3;
                    p7 = 0;
                    p8 = _v13;
                    break
                };
                let _v14 = p5 - 1;
                _v3 = swap_math::get_liquidity_from_a(_v8, _v10, _v14, false);
                let _v15 = p6 - 1;
                let _v16 = swap_math::get_liquidity_from_b(_v9, _v8, _v15, false);
                if (_v3 <= _v16) _v2 = _v3 else _v2 = _v16;
                let _v17 = tick_math::get_sqrt_price_at_tick(_v5);
                let _v18 = swap_math::get_delta_a(_v8, _v17, _v2, true);
                let _v19 = swap_math::get_delta_b(tick_math::get_sqrt_price_at_tick(_v4), _v8, _v2, true);
                _v0 = _v2;
                p7 = _v18;
                p8 = _v19;
                break
            };
            let _v20 = i32::from_u32(p1);
            let _v21 = i32::neg_from(1u32);
            let _v22 = i32::mul(_v20, _v21);
            let _v23 = pool_v3::get_tick_spacing(p4);
            let _v24 = i32::as_u32(i32::round_to_spacing(_v22, _v23, false));
            let _v25 = i32::from_u32(p0);
            let _v26 = i32::neg_from(1u32);
            let _v27 = i32::mul(_v25, _v26);
            let _v28 = pool_v3::get_tick_spacing(p4);
            let _v29 = i32::as_u32(i32::round_to_spacing(_v27, _v28, true));
            let (_v30,_v31,_v32) = optimal_liquidity_amounts(_v24, _v29, p3, p2, p4, p6, p5, p8, p7);
            return (_v30, _v31, _v32)
        };
        (_v0, p7, p8)
    }
    public fun optimal_liquidity_amounts_from_a(p0: u32, p1: u32, p2: u32, p3: object::Object<fungible_asset::Metadata>, p4: object::Object<fungible_asset::Metadata>, p5: u8, p6: u64, p7: u64, p8: u64): (u128, u64) {
        let _v0;
        let _v1 = utils::is_sorted(p3, p4);
        loop {
            if (_v1) {
                let _v2;
                let _v3 = i32::from_u32(p0);
                let _v4 = i32::from_u32(p1);
                let _v5 = tick_math::get_sqrt_price_at_tick(_v3);
                let _v6 = tick_math::get_sqrt_price_at_tick(_v4);
                if (pool_v3::liquidity_pool_exists(p3, p4, p5)) _v2 = pool_v3::current_price(p3, p4, p5) else _v2 = tick_math::get_sqrt_price_at_tick(i32::from_u32(p2));
                if (_v2 <= _v5) {
                    let _v7 = p6 - 1;
                    _v0 = swap_math::get_liquidity_from_a(_v5, _v6, _v7, false);
                    let _v8 = tick_math::get_sqrt_price_at_tick(_v3);
                    let _v9 = tick_math::get_sqrt_price_at_tick(_v4);
                    let _v10 = swap_math::get_delta_a(_v8, _v9, _v0, true);
                    p8 = 0;
                    break
                };
                assert!(_v2 <= _v6, 200005);
                let _v11 = p6 - 1;
                let _v12 = swap_math::get_liquidity_from_a(_v2, _v6, _v11, false);
                let _v13 = swap_math::get_delta_b(tick_math::get_sqrt_price_at_tick(_v3), _v2, _v12, true);
                _v0 = _v12;
                p8 = _v13;
                break
            };
            let _v14 = i32::from_u32(p1);
            let _v15 = i32::neg_from(1u32);
            let _v16 = i32::as_u32(i32::mul(_v14, _v15));
            let _v17 = i32::from_u32(p0);
            let _v18 = i32::neg_from(1u32);
            let _v19 = i32::as_u32(i32::mul(_v17, _v18));
            let _v20 = i32::from_u32(p2);
            let _v21 = i32::neg_from(1u32);
            let _v22 = i32::as_u32(i32::mul(_v20, _v21));
            let (_v23,_v24) = optimal_liquidity_amounts_from_b(_v16, _v19, _v22, p4, p3, p5, p6, p8, p7);
            return (_v23, _v24)
        };
        (_v0, p8)
    }
    public fun optimal_liquidity_amounts_from_b(p0: u32, p1: u32, p2: u32, p3: object::Object<fungible_asset::Metadata>, p4: object::Object<fungible_asset::Metadata>, p5: u8, p6: u64, p7: u64, p8: u64): (u128, u64) {
        let _v0;
        let _v1 = utils::is_sorted(p3, p4);
        loop {
            if (_v1) {
                let _v2;
                let _v3 = i32::from_u32(p0);
                let _v4 = i32::from_u32(p1);
                let _v5 = tick_math::get_sqrt_price_at_tick(_v3);
                let _v6 = tick_math::get_sqrt_price_at_tick(_v4);
                if (pool_v3::liquidity_pool_exists(p3, p4, p5)) _v2 = pool_v3::current_price(p3, p4, p5) else _v2 = tick_math::get_sqrt_price_at_tick(i32::from_u32(p2));
                if (_v2 <= _v5) abort 200005;
                if (_v2 < _v6) {
                    let _v7 = tick_math::get_sqrt_price_at_tick(_v3);
                    let _v8 = p6 - 1;
                    _v0 = swap_math::get_liquidity_from_b(_v7, _v2, _v8, false);
                    let _v9 = tick_math::get_sqrt_price_at_tick(_v4);
                    p7 = swap_math::get_delta_a(_v2, _v9, _v0, true);
                    break
                };
                let _v10 = p6 - 1;
                let _v11 = swap_math::get_liquidity_from_b(_v5, _v6, _v10, false);
                let _v12 = tick_math::get_sqrt_price_at_tick(_v3);
                let _v13 = tick_math::get_sqrt_price_at_tick(_v4);
                let _v14 = swap_math::get_delta_b(_v12, _v13, _v11, true);
                _v0 = _v11;
                p7 = 0;
                break
            };
            let _v15 = i32::from_u32(p1);
            let _v16 = i32::neg_from(1u32);
            let _v17 = i32::as_u32(i32::mul(_v15, _v16));
            let _v18 = i32::from_u32(p0);
            let _v19 = i32::neg_from(1u32);
            let _v20 = i32::as_u32(i32::mul(_v18, _v19));
            let _v21 = i32::from_u32(p2);
            let _v22 = i32::neg_from(1u32);
            let _v23 = i32::as_u32(i32::mul(_v21, _v22));
            let (_v24,_v25) = optimal_liquidity_amounts_from_a(_v17, _v20, _v23, p4, p3, p5, p6, p8, p7);
            return (_v24, _v25)
        };
        (_v0, p7)
    }
    public entry fun remove_liquidity_both_coins<T0, T1>(p0: &signer, p1: object::Object<position_v3::Info>, p2: u128, p3: u64, p4: u64, p5: address, p6: u64) {
        remove_liquidity_internal_for_normal_interface(p0, p1, p2, p3, p4, p5, p6);
    }
    public entry fun remove_liquidity_both_coins_directly_deposit<T0, T1>(p0: &signer, p1: object::Object<position_v3::Info>, p2: u128, p3: u64, p4: u64, p5: u64) {
        let _v0 = signer::address_of(p0);
        remove_liquidity_both_coins<T0, T1>(p0, p1, p2, p3, p4, _v0, p5);
    }
    public fun remove_liquidity_by_contract(p0: &signer, p1: object::Object<position_v3::Info>, p2: u128, p3: u64, p4: u64, p5: u64): (option::Option<fungible_asset::FungibleAsset>, option::Option<fungible_asset::FungibleAsset>) {
        let _v0;
        let _v1;
        let _v2;
        let _v3;
        if (passkey::is_user_registered<caas_integration::Witness>(signer::address_of(p0))) abort 200030;
        let (_v4,_v5,_v6) = position_v3::get_pool_info(p1);
        let _v7 = _v5;
        let _v8 = _v4;
        let _v9 = pool_v3::liquidity_pool_address(_v8, _v7, _v6);
        let _v10 = object::object_address<position_v3::Info>(&p1);
        let _v11 = p0;
        let (_v12,_v13) = pool_v3::remove_liquidity_v2(_v11, p1, p2);
        _v11 = p0;
        let _v14 = _v13;
        let _v15 = _v12;
        let _v16 = _v14;
        let _v17 = _v8;
        let _v18 = _v7;
        p5 = p3;
        let _v19 = p4;
        let _v20 = object::object_address<fungible_asset::Metadata>(&_v17);
        let _v21 = object::object_address<fungible_asset::Metadata>(&_v18);
        if (option::is_some<fungible_asset::FungibleAsset>(&_v15)) {
            let _v22 = fungible_asset::amount(option::borrow<fungible_asset::FungibleAsset>(&_v15));
            assert!(_v22 >= p5, 200001);
            _v2 = _v22
        } else if (p5 == 0) _v2 = 0 else abort 200001;
        if (option::is_some<fungible_asset::FungibleAsset>(&_v16)) {
            let _v23 = fungible_asset::amount(option::borrow<fungible_asset::FungibleAsset>(&_v16));
            assert!(_v23 >= _v19, 200002);
            _v1 = _v23
        } else if (_v19 == 0) _v1 = 0 else abort 200002;
        if (rate_limiter_check::is_rate_limiter_passed(_v11, _v20, _v2)) _v0 = rate_limiter_check::is_rate_limiter_passed(_v11, _v21, _v1) else _v0 = false;
        if (_v0) {
            _v3 = _v15;
            _v14 = _v16
        } else {
            fridge::set_box(_v11, _v9, _v10, _v15, _v16, _v17, _v18);
            _v3 = option::none<fungible_asset::FungibleAsset>();
            _v14 = option::none<fungible_asset::FungibleAsset>()
        };
        (_v3, _v14)
    }
    public fun remove_liquidity_by_contract_with_second_signer(p0: &signer, p1: &signer, p2: object::Object<position_v3::Info>, p3: u128, p4: u64, p5: u64, p6: u64): (option::Option<fungible_asset::FungibleAsset>, option::Option<fungible_asset::FungibleAsset>) {
        let _v0;
        let _v1;
        let _v2;
        let _v3;
        let _v4 = signer::address_of(p0);
        let _v5 = string::utf8(vector[86u8, 65u8, 85u8, 76u8, 84u8, 95u8, 80u8, 79u8, 79u8, 76u8]);
        assert!(user_label::has_label(_v4, _v5), 200028);
        let (_v6,_v7,_v8) = position_v3::get_pool_info(p2);
        let _v9 = _v7;
        let _v10 = _v6;
        let _v11 = pool_v3::liquidity_pool_address(_v10, _v9, _v8);
        let _v12 = object::object_address<position_v3::Info>(&p2);
        let _v13 = p0;
        let (_v14,_v15) = pool_v3::remove_liquidity_v2(_v13, p2, p3);
        _v13 = p1;
        let _v16 = _v15;
        let _v17 = _v14;
        let _v18 = _v16;
        let _v19 = _v10;
        let _v20 = _v9;
        p6 = p4;
        let _v21 = p5;
        let _v22 = object::object_address<fungible_asset::Metadata>(&_v19);
        let _v23 = object::object_address<fungible_asset::Metadata>(&_v20);
        if (option::is_some<fungible_asset::FungibleAsset>(&_v17)) {
            let _v24 = fungible_asset::amount(option::borrow<fungible_asset::FungibleAsset>(&_v17));
            assert!(_v24 >= p6, 200001);
            _v2 = _v24
        } else if (p6 == 0) _v2 = 0 else abort 200001;
        if (option::is_some<fungible_asset::FungibleAsset>(&_v18)) {
            let _v25 = fungible_asset::amount(option::borrow<fungible_asset::FungibleAsset>(&_v18));
            assert!(_v25 >= _v21, 200002);
            _v1 = _v25
        } else if (_v21 == 0) _v1 = 0 else abort 200002;
        if (rate_limiter_check::is_rate_limiter_passed_v2(_v13, _v11, _v22, _v2)) _v0 = rate_limiter_check::is_rate_limiter_passed_v2(_v13, _v11, _v23, _v1) else _v0 = false;
        if (_v0) {
            _v3 = _v17;
            _v16 = _v18
        } else {
            fridge::set_box(_v13, _v11, _v12, _v17, _v18, _v19, _v20);
            _v3 = option::none<fungible_asset::FungibleAsset>();
            _v16 = option::none<fungible_asset::FungibleAsset>()
        };
        (_v3, _v16)
    }
    public entry fun remove_liquidity_coin<T0>(p0: &signer, p1: object::Object<position_v3::Info>, p2: u128, p3: u64, p4: u64, p5: address, p6: u64) {
        remove_liquidity_internal_for_normal_interface(p0, p1, p2, p3, p4, p5, p6);
    }
    public entry fun remove_liquidity_coin_directly_deposit<T0>(p0: &signer, p1: object::Object<position_v3::Info>, p2: u128, p3: u64, p4: u64, p5: u64) {
        let _v0 = signer::address_of(p0);
        remove_liquidity_coin<T0>(p0, p1, p2, p3, p4, _v0, p5);
    }
    public entry fun remove_liquidity_directly_deposit(p0: &signer, p1: object::Object<position_v3::Info>, p2: u128, p3: u64, p4: u64, p5: u64) {
        let _v0 = signer::address_of(p0);
        remove_liquidity(p0, p1, p2, p3, p4, _v0, p5);
    }
    fun remove_liquidity_internal(p0: &signer, p1: object::Object<position_v3::Info>, p2: u128, p3: u64, p4: u64, p5: address, p6: u64) {
        let _v0;
        let _v1;
        let _v2;
        let _v3;
        let _v4;
        let (_v5,_v6,_v7) = position_v3::get_pool_info(p1);
        let _v8 = _v6;
        let _v9 = _v5;
        let _v10 = pool_v3::liquidity_pool_address(_v9, _v8, _v7);
        let _v11 = object::object_address<position_v3::Info>(&p1);
        let _v12 = p0;
        let (_v13,_v14) = pool_v3::remove_liquidity_v2(_v12, p1, p2);
        _v12 = p0;
        let _v15 = _v14;
        let _v16 = _v13;
        let _v17 = _v15;
        let _v18 = _v9;
        let _v19 = _v8;
        let _v20 = object::object_address<fungible_asset::Metadata>(&_v18);
        let _v21 = object::object_address<fungible_asset::Metadata>(&_v19);
        if (option::is_some<fungible_asset::FungibleAsset>(&_v16)) {
            p6 = fungible_asset::amount(option::borrow<fungible_asset::FungibleAsset>(&_v16));
            assert!(p6 >= p3, 200001);
            _v3 = p6
        } else if (p3 == 0) _v3 = 0 else abort 200001;
        if (option::is_some<fungible_asset::FungibleAsset>(&_v17)) {
            let _v22 = fungible_asset::amount(option::borrow<fungible_asset::FungibleAsset>(&_v17));
            assert!(_v22 >= p4, 200002);
            _v2 = _v22
        } else if (p4 == 0) _v2 = 0 else abort 200002;
        if (rate_limiter_check::is_rate_limiter_passed_v2(_v12, _v10, _v20, _v3)) _v1 = rate_limiter_check::is_rate_limiter_passed_v2(_v12, _v10, _v21, _v2) else _v1 = false;
        if (_v1) {
            _v4 = _v16;
            _v15 = _v17
        } else {
            fridge::set_box(_v12, _v10, _v11, _v16, _v17, _v18, _v19);
            _v4 = option::none<fungible_asset::FungibleAsset>();
            _v15 = option::none<fungible_asset::FungibleAsset>()
        };
        let _v23 = _v4;
        let _v24 = _v15;
        if (option::is_some<fungible_asset::FungibleAsset>(&_v23)) {
            _v0 = option::destroy_some<fungible_asset::FungibleAsset>(_v23);
            primary_fungible_store::deposit(p5, _v0)
        } else option::destroy_none<fungible_asset::FungibleAsset>(_v23);
        if (option::is_some<fungible_asset::FungibleAsset>(&_v24)) {
            _v0 = option::destroy_some<fungible_asset::FungibleAsset>(_v24);
            primary_fungible_store::deposit(p5, _v0);
            return ()
        };
        option::destroy_none<fungible_asset::FungibleAsset>(_v24);
    }
    public entry fun remove_liquidity_single(p0: &signer, p1: object::Object<position_v3::Info>, p2: u128, p3: object::Object<fungible_asset::Metadata>, p4: u256, p5: u256) {
        if (passkey::is_user_registered<caas_integration::Witness>(signer::address_of(p0))) abort 200030;
        remove_single(p0, p1, p2, p3, p4, p5);
    }
    fun remove_single(p0: &signer, p1: object::Object<position_v3::Info>, p2: u128, p3: object::Object<fungible_asset::Metadata>, p4: u256, p5: u256) {
        let _v0;
        let _v1;
        let _v2;
        let _v3;
        let _v4;
        let _v5;
        let _v6;
        let _v7;
        let _v8;
        let _v9;
        let _v10;
        let _v11;
        assert!(p4 > 0u256, 200010);
        assert!(p5 > 0u256, 200011);
        let (_v12,_v13,_v14) = position_v3::get_pool_info(p1);
        let _v15 = _v14;
        let _v16 = _v13;
        let _v17 = _v12;
        if (p3 == _v17) _v7 = _v16 else if (p3 == _v16) _v7 = _v17 else abort 200006;
        let _v18 = object::object_address<position_v3::Info>(&p1);
        let _v19 = p0;
        let (_v20,_v21) = pool_v3::remove_liquidity_v2(_v19, p1, p2);
        let _v22 = pool_v3::liquidity_pool_address(_v17, _v16, _v15);
        _v19 = p0;
        let _v23 = _v21;
        let _v24 = _v20;
        let _v25 = _v23;
        let _v26 = _v17;
        let _v27 = _v16;
        let _v28 = object::object_address<fungible_asset::Metadata>(&_v26);
        let _v29 = object::object_address<fungible_asset::Metadata>(&_v27);
        if (option::is_some<fungible_asset::FungibleAsset>(&_v24)) {
            let _v30 = fungible_asset::amount(option::borrow<fungible_asset::FungibleAsset>(&_v24));
            if (_v30 >= 0) _v10 = _v30 else abort 200001
        } else _v10 = 0;
        if (option::is_some<fungible_asset::FungibleAsset>(&_v25)) {
            let _v31 = fungible_asset::amount(option::borrow<fungible_asset::FungibleAsset>(&_v25));
            if (_v31 >= 0) _v9 = _v31 else abort 200002
        } else _v9 = 0;
        if (rate_limiter_check::is_rate_limiter_passed(_v19, _v28, _v10)) _v8 = rate_limiter_check::is_rate_limiter_passed(_v19, _v29, _v9) else _v8 = false;
        if (_v8) {
            _v11 = _v24;
            _v23 = _v25
        } else {
            fridge::set_box(_v19, _v22, _v18, _v24, _v25, _v26, _v27);
            _v11 = option::none<fungible_asset::FungibleAsset>();
            _v23 = option::none<fungible_asset::FungibleAsset>()
        };
        let _v32 = _v11;
        let _v33 = _v23;
        let _v34 = pool_v3::liquidity_pool(_v17, _v16, _v15);
        let _v35 = option::is_none<fungible_asset::FungibleAsset>(&_v32);
        let _v36 = option::is_none<fungible_asset::FungibleAsset>(&_v33);
        let _v37 = 0;
        let _v38 = 0;
        let _v39 = 0;
        if (_v35) _v6 = 0 else _v6 = fungible_asset::amount(option::borrow<fungible_asset::FungibleAsset>(&_v32));
        if (_v36) _v5 = 0 else _v5 = fungible_asset::amount(option::borrow<fungible_asset::FungibleAsset>(&_v33));
        if (_v35) option::destroy_none<fungible_asset::FungibleAsset>(_v32) else {
            let _v40 = option::destroy_some<fungible_asset::FungibleAsset>(_v32);
            let _v41 = fungible_asset::metadata_from_asset(&_v40);
            if (p3 == _v41) {
                _v39 = fungible_asset::amount(&_v40);
                primary_fungible_store::deposit(signer::address_of(p0), _v40)
            } else {
                _v4 = fungible_asset::metadata_from_asset(&_v40);
                _v38 = fungible_asset::amount(&_v40);
                let _v42 = fungible_asset::decimals<fungible_asset::Metadata>(_v4) as u64;
                _v3 = math64::pow(10, _v42) as u256;
                let _v43 = (1u256 * _v3) as u64;
                let (_v44,_v45) = pool_v3::get_amount_out(_v34, _v4, _v43);
                let _v46 = _v44 as u256;
                let _v47 = _v38 as u256;
                _v3 = _v46 * _v47 / _v3 * p4 / p5;
                if (fungible_asset::metadata_from_asset(&_v40) == _v17) {
                    _v2 = tick_math::min_sqrt_price();
                    _v1 = true
                } else {
                    _v2 = tick_math::max_sqrt_price();
                    _v1 = false
                };
                let (_v48,_v49,_v50) = pool_v3::swap(_v34, _v1, true, _v38, _v40, _v2);
                let _v51 = _v50;
                _v0 = fungible_asset::amount(&_v51);
                let _v52 = _v3 as u64;
                if (_v0 >= _v52) {
                    primary_fungible_store::deposit(signer::address_of(p0), _v49);
                    primary_fungible_store::deposit(signer::address_of(p0), _v51);
                    _v37 = _v0
                } else abort 200003
            }
        };
        if (_v36) option::destroy_none<fungible_asset::FungibleAsset>(_v33) else {
            let _v53 = option::destroy_some<fungible_asset::FungibleAsset>(_v33);
            let _v54 = fungible_asset::metadata_from_asset(&_v53);
            if (p3 == _v54) {
                _v39 = fungible_asset::amount(&_v53);
                primary_fungible_store::deposit(signer::address_of(p0), _v53)
            } else {
                _v4 = fungible_asset::metadata_from_asset(&_v53);
                _v38 = fungible_asset::amount(&_v53);
                let _v55 = fungible_asset::decimals<fungible_asset::Metadata>(_v4) as u64;
                _v3 = math64::pow(10, _v55) as u256;
                let _v56 = (1u256 * _v3) as u64;
                let (_v57,_v58) = pool_v3::get_amount_out(_v34, _v4, _v56);
                let _v59 = _v57 as u256;
                let _v60 = _v38 as u256;
                _v3 = _v59 * _v60 / _v3 * p4 / p5;
                if (fungible_asset::metadata_from_asset(&_v53) == _v17) {
                    _v2 = tick_math::min_sqrt_price();
                    _v1 = true
                } else {
                    _v2 = tick_math::max_sqrt_price();
                    _v1 = false
                };
                let (_v61,_v62,_v63) = pool_v3::swap(_v34, _v1, true, _v38, _v53, _v2);
                let _v64 = _v63;
                _v0 = fungible_asset::amount(&_v64);
                let _v65 = _v3 as u64;
                if (_v0 >= _v65) {
                    primary_fungible_store::deposit(signer::address_of(p0), _v62);
                    primary_fungible_store::deposit(signer::address_of(p0), _v64);
                    _v37 = _v0
                } else abort 200003
            }
        };
        let _v66 = signer::address_of(p0);
        let _v67 = _v37 + _v39;
        event::emit<RemoveSingleLiquidityEvent>(RemoveSingleLiquidityEvent{pool_id: _v22, caller: _v66, position: p1, swap_from: _v7, swap_to: p3, swap_amount_in: _v38, swap_amount_out: _v37, delta_lp_amount: p2, remove_amount_a: _v6, remove_amount_b: _v5, output_amount: _v67});
    }
    public entry fun remove_liquidity_single_coins<T0>(p0: &signer, p1: object::Object<position_v3::Info>, p2: u128, p3: u256, p4: u256) {
        if (passkey::is_user_registered<caas_integration::Witness>(signer::address_of(p0))) abort 200030;
        let _v0 = coin::paired_metadata<T0>();
        let _v1 = *option::borrow<object::Object<fungible_asset::Metadata>>(&_v0);
        remove_single(p0, p1, p2, _v1, p3, p4);
    }
    public entry fun remove_liquidity_single_to_fridge_with_multiagent(p0: &signer, p1: &signer, p2: &signer, p3: object::Object<position_v3::Info>, p4: u128, p5: object::Object<fungible_asset::Metadata>, p6: u256, p7: u256) {
        passkey::passkey_verify<caas_integration::Witness>(p0, p1, p2);
        let (_v0,_v1,_v2) = position_v3::get_pool_info(p3);
        let _v3 = _v1;
        p5 = _v0;
        let _v4 = pool_v3::liquidity_pool_address(p5, _v3, _v2);
        let _v5 = object::object_address<position_v3::Info>(&p3);
        let (_v6,_v7) = pool_v3::remove_liquidity_v2(p0, p3, p4);
        fridge::set_box(p0, _v4, _v5, _v6, _v7, p5, _v3);
    }
    public entry fun remove_liquidity_single_with_multiagent(p0: &signer, p1: &signer, p2: &signer, p3: object::Object<position_v3::Info>, p4: u128, p5: object::Object<fungible_asset::Metadata>, p6: u256, p7: u256) {
        passkey::passkey_verify<caas_integration::Witness>(p0, p1, p2);
        remove_single(p0, p3, p4, p5, p6, p7);
    }
    public entry fun remove_liquidity_to_fridge_with_multiagent(p0: &signer, p1: &signer, p2: &signer, p3: object::Object<position_v3::Info>, p4: u128, p5: u64, p6: u64, p7: u64) {
        passkey::passkey_verify<caas_integration::Witness>(p0, p1, p2);
        let (_v0,_v1,_v2) = position_v3::get_pool_info(p3);
        let _v3 = _v1;
        let _v4 = _v0;
        let _v5 = pool_v3::liquidity_pool_address(_v4, _v3, _v2);
        let _v6 = object::object_address<position_v3::Info>(&p3);
        let (_v7,_v8) = pool_v3::remove_liquidity_v2(p0, p3, p4);
        let _v9 = _v8;
        let _v10 = _v7;
        let _v11 = option::is_some<fungible_asset::FungibleAsset>(&_v10);
        loop {
            if (_v11) {
                if (fungible_asset::amount(option::borrow<fungible_asset::FungibleAsset>(&_v10)) >= p5) break;
                abort 200001
            };
            if (p5 == 0) break;
            abort 200001
        };
        let _v12 = option::is_some<fungible_asset::FungibleAsset>(&_v9);
        loop {
            if (_v12) {
                if (fungible_asset::amount(option::borrow<fungible_asset::FungibleAsset>(&_v9)) >= p6) break;
                abort 200002
            };
            if (p6 == 0) break;
            abort 200002
        };
        fridge::set_box(p0, _v5, _v6, _v10, _v9, _v4, _v3);
    }
    public entry fun remove_liquidity_with_multiagent(p0: &signer, p1: &signer, p2: &signer, p3: object::Object<position_v3::Info>, p4: u128, p5: u64, p6: u64, p7: address, p8: u64) {
        passkey::passkey_verify<caas_integration::Witness>(p0, p1, p2);
        remove_liquidity_internal(p0, p3, p4, p5, p6, p7, p8);
    }
    public fun remove_liquidity_with_multiagent_and_second_signer_by_contract<T0: drop>(p0: &signer, p1: &signer, p2: &signer, p3: &signer, p4: object::Object<position_v3::Info>, p5: u128, p6: u64, p7: u64, p8: u64, p9: T0): (option::Option<fungible_asset::FungibleAsset>, option::Option<fungible_asset::FungibleAsset>) {
        let _v0;
        let _v1;
        let _v2;
        let _v3;
        caas_integration::verify_authorization<T0>(p9);
        passkey::passkey_verify<T0>(p0, p1, p2);
        let _v4 = signer::address_of(p0);
        let _v5 = string::utf8(vector[86u8, 65u8, 85u8, 76u8, 84u8, 95u8, 80u8, 79u8, 79u8, 76u8]);
        assert!(user_label::has_label(_v4, _v5), 200028);
        let (_v6,_v7,_v8) = position_v3::get_pool_info(p4);
        let _v9 = _v7;
        let _v10 = _v6;
        let _v11 = pool_v3::liquidity_pool_address(_v10, _v9, _v8);
        let _v12 = object::object_address<position_v3::Info>(&p4);
        p1 = p0;
        let (_v13,_v14) = pool_v3::remove_liquidity_v2(p1, p4, p5);
        p1 = p3;
        let _v15 = _v14;
        let _v16 = _v13;
        let _v17 = _v15;
        let _v18 = _v10;
        let _v19 = _v9;
        p8 = p6;
        let _v20 = p7;
        let _v21 = object::object_address<fungible_asset::Metadata>(&_v18);
        let _v22 = object::object_address<fungible_asset::Metadata>(&_v19);
        if (option::is_some<fungible_asset::FungibleAsset>(&_v16)) {
            let _v23 = fungible_asset::amount(option::borrow<fungible_asset::FungibleAsset>(&_v16));
            assert!(_v23 >= p8, 200001);
            _v2 = _v23
        } else if (p8 == 0) _v2 = 0 else abort 200001;
        if (option::is_some<fungible_asset::FungibleAsset>(&_v17)) {
            let _v24 = fungible_asset::amount(option::borrow<fungible_asset::FungibleAsset>(&_v17));
            assert!(_v24 >= _v20, 200002);
            _v1 = _v24
        } else if (_v20 == 0) _v1 = 0 else abort 200002;
        if (rate_limiter_check::is_rate_limiter_passed_v2(p1, _v11, _v21, _v2)) _v0 = rate_limiter_check::is_rate_limiter_passed_v2(p1, _v11, _v22, _v1) else _v0 = false;
        if (_v0) {
            _v3 = _v16;
            _v15 = _v17
        } else {
            fridge::set_box(p1, _v11, _v12, _v16, _v17, _v18, _v19);
            _v3 = option::none<fungible_asset::FungibleAsset>();
            _v15 = option::none<fungible_asset::FungibleAsset>()
        };
        (_v3, _v15)
    }
    public fun remove_liquidity_with_multiagent_by_contract<T0: drop>(p0: &signer, p1: &signer, p2: &signer, p3: object::Object<position_v3::Info>, p4: u128, p5: u64, p6: u64, p7: address, p8: u64, p9: T0) {
        caas_integration::verify_authorization<T0>(p9);
        passkey::passkey_verify<T0>(p0, p1, p2);
        remove_liquidity_internal(p0, p3, p4, p5, p6, p7, p8);
    }
    public entry fun remove_liquidity_with_multiagent_directly_deposit(p0: &signer, p1: &signer, p2: &signer, p3: object::Object<position_v3::Info>, p4: u128, p5: u64, p6: u64, p7: u64) {
        let _v0 = signer::address_of(p0);
        remove_liquidity_with_multiagent(p0, p1, p2, p3, p4, p5, p6, _v0, p7);
    }
    public fun remove_liquidity_with_multiagent_directly_deposit_by_contract<T0: drop>(p0: &signer, p1: &signer, p2: &signer, p3: object::Object<position_v3::Info>, p4: u128, p5: u64, p6: u64, p7: u64, p8: T0) {
        caas_integration::verify_authorization<T0>(p8);
        passkey::passkey_verify<T0>(p0, p1, p2);
        let _v0 = signer::address_of(p0);
        remove_liquidity_internal(p0, p3, p4, p5, p6, _v0, p7);
    }
}
