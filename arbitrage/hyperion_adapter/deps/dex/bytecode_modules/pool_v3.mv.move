module 0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c::pool_v3 {
    use 0x1::object;
    use 0x1::fungible_asset;
    use 0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c::i32;
    use 0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c::position_v3;
    use 0x1::smart_vector;
    use 0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c::position_blacklist;
    use 0x1::smart_table;
    use 0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c::tick;
    use 0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c::tick_bitmap;
    use 0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c::lp;
    use 0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c::rewarder;
    use 0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c::position_blacklist_v2;
    use 0x1::event;
    use 0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c::tick_math;
    use 0x1::timestamp;
    use 0x1::math128;
    use 0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c::swap_math;
    use 0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c::full_math_u128;
    use 0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c::i128;
    use 0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c::liquidity_math;
    use 0x661799897c0d2e94c1de976cb3f0e344672c71871e50188622d1b9192723b44c::commission;
    use 0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c::package_manager;
    use 0x1::dispatchable_fungible_asset;
    use 0x1::error;
    use 0x1::signer;
    use 0x1::primary_fungible_store;
    use 0x1::string;
    use 0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c::utils;
    use 0x1::option;
    use 0x1::coin;
    use 0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c::coin_wrapper;
    use 0x1::comparator;
    use 0x1::type_info;
    use 0x1::string_utils;
    friend 0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c::router_v3;
    struct AddLiquidityEvent has drop, store {
        pool_id: address,
        object_id: address,
        token_a: object::Object<fungible_asset::Metadata>,
        token_b: object::Object<fungible_asset::Metadata>,
        fee_tier: u8,
        is_delete: bool,
        added_lp_amount: u128,
        previous_liquidity_amount: u128,
        amount_a: u64,
        amount_b: u64,
    }
    struct AddLiquidityEventV2 has drop, store {
        pool_id: address,
        object_id: address,
        token_a: object::Object<fungible_asset::Metadata>,
        token_b: object::Object<fungible_asset::Metadata>,
        fee_tier: u8,
        is_delete: bool,
        added_lp_amount: u128,
        previous_liquidity_amount: u128,
        amount_a: u64,
        amount_b: u64,
        pool_reserve_a: u64,
        pool_reserve_b: u64,
    }
    struct AddLiquidityEventV3 has drop, store {
        pool_id: address,
        object_id: address,
        token_a: object::Object<fungible_asset::Metadata>,
        token_b: object::Object<fungible_asset::Metadata>,
        fee_tier: u8,
        is_delete: bool,
        added_lp_amount: u128,
        previous_liquidity_amount: u128,
        amount_a: u64,
        amount_b: u64,
        pool_reserve_a: u64,
        pool_reserve_b: u64,
        current_tick: i32::I32,
        sqrt_price: u128,
        active_liquidity: u128,
    }
    struct ClaimFeesEvent has drop, store {
        pool: object::Object<LiquidityPoolV3>,
        lp_object: object::Object<position_v3::Info>,
        token: object::Object<fungible_asset::Metadata>,
        amount: u64,
        owner: address,
    }
    struct LiquidityPoolV3 has key {
        token_a_liquidity: object::Object<fungible_asset::FungibleStore>,
        token_b_liquidity: object::Object<fungible_asset::FungibleStore>,
        token_a_fee: object::Object<fungible_asset::FungibleStore>,
        token_b_fee: object::Object<fungible_asset::FungibleStore>,
        sqrt_price: u128,
        liquidity: u128,
        tick: i32::I32,
        observation_index: u64,
        observation_cardinality: u64,
        observation_cardinality_next: u64,
        fee_rate: u64,
        fee_protocol: u64,
        unlocked: bool,
        fee_growth_global_a: u128,
        fee_growth_global_b: u128,
        seconds_per_liquidity_oracle: u128,
        seconds_per_liquidity_incentive: u128,
        position_blacklist: position_blacklist::PositionBlackList,
        last_update_timestamp: u64,
        tick_info: smart_table::SmartTable<i32::I32, tick::TickInfo>,
        tick_map: tick_bitmap::BitMap,
        tick_spacing: u32,
        protocol_fees: ProtocolFees,
        lp_token_refs: lp::LPTokenRefs,
        max_liquidity_per_tick: u128,
        rewarder_manager: rewarder::RewarderManager,
    }
    struct ProtocolFees has store {
        token_a: object::Object<fungible_asset::FungibleStore>,
        token_b: object::Object<fungible_asset::FungibleStore>,
    }
    struct ClaimFeesEventV2 has drop, store {
        pool: object::Object<LiquidityPoolV3>,
        lp_object: object::Object<position_v3::Info>,
        token: object::Object<fungible_asset::Metadata>,
        amount: u64,
        owner: address,
        token_a_liquidity_after_claim: u64,
        token_b_liquidity_after_claim: u64,
    }
    struct CreatePoolEvent has drop, store {
        pool: object::Object<LiquidityPoolV3>,
        token_a: object::Object<fungible_asset::Metadata>,
        token_b: object::Object<fungible_asset::Metadata>,
        fee_rate: u64,
        fee_tier: u8,
        sqrt_price: u128,
        tick: i32::I32,
    }
    struct LiquidityPoolConfigsV3 has key {
        all_pools: smart_vector::SmartVector<object::Object<LiquidityPoolV3>>,
        is_paused: bool,
        fee_manager: address,
        pauser: address,
        pending_fee_manager: address,
        pending_pauser: address,
        tick_spacing_list: vector<u64>,
    }
    struct LiquidityPoolInfoV3 has copy, drop {
        pool: object::Object<LiquidityPoolV3>,
        token_a: object::Object<fungible_asset::Metadata>,
        token_b: object::Object<fungible_asset::Metadata>,
        fee_rate: u64,
        token_a_reserve: u64,
        token_b_reserve: u64,
        liquidity_total: u128,
    }
    struct PageInfo has copy, drop {
        offset: u64,
        limit: u64,
        total: u64,
        take: u64,
    }
    struct PoolSnapshot has drop, store {
        pool_id: address,
        sqrt_price: u128,
        liquidity: u128,
        tick: i32::I32,
        observation_index: u64,
        observation_cardinality: u64,
        observation_cardinality_next: u64,
        fee_rate: u64,
        fee_rate_denominatore: u64,
        fee_growth_global_a: u128,
        fee_growth_global_b: u128,
        tick_spacing: u32,
    }
    struct PoolSnapshotV2 has drop, store {
        pool_id: address,
        sqrt_price: u128,
        liquidity: u128,
        tick: i32::I32,
        observation_index: u64,
        observation_cardinality: u64,
        observation_cardinality_next: u64,
        fee_rate: u64,
        fee_rate_denominatore: u64,
        fee_growth_global_a: u128,
        fee_growth_global_b: u128,
        tick_spacing: u32,
        token_a_reserve: u64,
        token_b_reserve: u64,
    }
    struct PoolTemporaryStorage has key {
        stores: vector<object::Object<fungible_asset::FungibleStore>>,
    }
    struct RemoveLiquidityEvent has drop, store {
        pool_id: address,
        object_id: address,
        token_a: object::Object<fungible_asset::Metadata>,
        token_b: object::Object<fungible_asset::Metadata>,
        fee_tier: u8,
        is_delete: bool,
        burned_lp_amount: u128,
        previous_liquidity_amount: u128,
        amount_a: u64,
        amount_b: u64,
    }
    struct RemoveLiquidityEventV2 has drop, store {
        pool_id: address,
        object_id: address,
        token_a: object::Object<fungible_asset::Metadata>,
        token_b: object::Object<fungible_asset::Metadata>,
        fee_tier: u8,
        is_delete: bool,
        burned_lp_amount: u128,
        previous_liquidity_amount: u128,
        amount_a: u64,
        amount_b: u64,
        pool_reserve_a: u64,
        pool_reserve_b: u64,
    }
    struct RemoveLiquidityEventV3 has drop, store {
        pool_id: address,
        object_id: address,
        token_a: object::Object<fungible_asset::Metadata>,
        token_b: object::Object<fungible_asset::Metadata>,
        fee_tier: u8,
        is_delete: bool,
        burned_lp_amount: u128,
        previous_liquidity_amount: u128,
        amount_a: u64,
        amount_b: u64,
        pool_reserve_a: u64,
        pool_reserve_b: u64,
        current_tick: i32::I32,
        sqrt_price: u128,
        active_liquidity: u128,
    }
    struct StepComputations has drop, store {
        sqrt_price_current: u128,
        sqrt_price_next: u128,
        amount_in: u64,
        amount_out: u64,
        fee_amount: u64,
        current_liquidity: u128,
    }
    struct SwapAfterEvent has drop, store {
        pool_id: address,
        tick: i32::I32,
        sqrt_price: u128,
        liquidity: u128,
    }
    struct SwapBeforeEvent has drop, store {
        pool_id: address,
        tick: i32::I32,
        sqrt_price: u128,
        liquidity: u128,
    }
    struct SwapEvent has drop, store {
        pool_id: address,
        from_token: object::Object<fungible_asset::Metadata>,
        to_token: object::Object<fungible_asset::Metadata>,
        amount_in: u64,
        amount_out: u64,
        fee_amount: u64,
        protocol_fee_amount: u64,
    }
    struct SwapEventV2 has drop, store {
        pool_id: address,
        from_token: object::Object<fungible_asset::Metadata>,
        to_token: object::Object<fungible_asset::Metadata>,
        amount_in: u64,
        amount_out: u64,
        fee_amount: u64,
        protocol_fee_amount: u64,
        pool_reserve_a: u64,
        pool_reserve_b: u64,
    }
    struct SwapEventV3 has drop, store {
        pool_id: address,
        from_token: object::Object<fungible_asset::Metadata>,
        to_token: object::Object<fungible_asset::Metadata>,
        amount_in: u64,
        amount_out: u64,
        fee_amount: u64,
        protocol_fee_amount: u64,
        pool_reserve_a: u64,
        pool_reserve_b: u64,
        current_tick: i32::I32,
        sqrt_price: u128,
        active_liquidity: u128,
    }
    struct SwapState has drop {
        amount_specified_remaining: u64,
        amount_calculated: u64,
        sqrt_price: u128,
        tick: i32::I32,
        fee_growth_global: u128,
        seconds_per_liquidity: u128,
        protocol_fee: u64,
        liquidity: u128,
        fee_amount_total: u64,
    }
    struct UpdateRemoveLiqudityAmount has copy, drop, store {
        pool_id: address,
        liquidity_delta: u128,
        tick_lower: u32,
        tick_upper: u32,
    }
    public fun swap(p0: object::Object<LiquidityPoolV3>, p1: bool, p2: bool, p3: u64, p4: fungible_asset::FungibleAsset, p5: u128): (u64, fungible_asset::FungibleAsset, fungible_asset::FungibleAsset)
        acquires LiquidityPoolConfigsV3, LiquidityPoolV3
    {
        let _v0;
        let _v1;
        let _v2;
        let _v3;
        let _v4;
        let _v5;
        assert!(p3 != 0, 100002);
        check_protocol_pause();
        let _v6 = object::object_address<LiquidityPoolV3>(&p0);
        let _v7 = borrow_global_mut<LiquidityPoolV3>(_v6);
        let _v8 = lp::get_signer(&_v7.lp_token_refs);
        position_blacklist_v2::new_v2(&_v8);
        let _v9 = object::object_address<LiquidityPoolV3>(&p0);
        let _v10 = freeze(_v7);
        let _v11 = *&_v10.sqrt_price;
        let _v12 = *&_v10.liquidity;
        let _v13 = *&_v10.tick;
        let _v14 = *&_v10.observation_index;
        let _v15 = *&_v10.observation_cardinality;
        let _v16 = *&_v10.observation_cardinality_next;
        let _v17 = *&_v10.fee_rate;
        let _v18 = *&_v10.fee_growth_global_a;
        let _v19 = *&_v10.fee_growth_global_b;
        let _v20 = *&_v10.tick_spacing;
        let _v21 = fungible_asset::balance<fungible_asset::FungibleStore>(*&_v10.token_a_liquidity);
        let _v22 = fungible_asset::balance<fungible_asset::FungibleStore>(*&_v10.token_b_liquidity);
        event::emit<PoolSnapshotV2>(PoolSnapshotV2{pool_id: _v9, sqrt_price: _v11, liquidity: _v12, tick: _v13, observation_index: _v14, observation_cardinality: _v15, observation_cardinality_next: _v16, fee_rate: _v17, fee_rate_denominatore: 1000000, fee_growth_global_a: _v18, fee_growth_global_b: _v19, tick_spacing: _v20, token_a_reserve: _v21, token_b_reserve: _v22});
        let _v23 = object::object_address<LiquidityPoolV3>(&p0);
        let _v24 = *&_v7.tick;
        let _v25 = *&_v7.sqrt_price;
        let _v26 = *&_v7.liquidity;
        event::emit<SwapBeforeEvent>(SwapBeforeEvent{pool_id: _v23, tick: _v24, sqrt_price: _v25, liquidity: _v26});
        assert!(*&_v7.unlocked, 100003);
        loop {
            let _v27;
            if (p1) {
                let _v28 = *&_v7.sqrt_price;
                if (p5 < _v28) {
                    let _v29 = tick_math::min_sqrt_price();
                    _v27 = p5 >= _v29
                } else _v27 = false;
                if (_v27) break;
                abort 100004
            };
            let _v30 = *&_v7.sqrt_price;
            if (p5 > _v30) {
                let _v31 = tick_math::max_sqrt_price();
                _v27 = p5 <= _v31
            } else _v27 = false;
            if (_v27) break;
            abort 100004
        };
        let _v32 = _v7;
        let _v33 = timestamp::now_seconds();
        let _v34 = *&_v32.last_update_timestamp;
        let _v35 = _v33 - _v34;
        if (*&_v32.liquidity != 0u128) {
            let _v36 = (_v35 as u128) << 64u8;
            let _v37 = *&_v32.liquidity;
            _v5 = _v36 / _v37
        } else _v5 = 0u128;
        _v10 = freeze(_v32);
        let _v38 = *&_v10.tick;
        let _v39 = position_blacklist_v2::blocked_out_liquidity_amount(_v6, _v38);
        _v39 = *&_v10.liquidity - _v39;
        if (_v39 != 0u128) _v4 = ((_v35 as u128) << 64u8) / _v39 else _v4 = 0u128;
        let _v40 = *&_v32.seconds_per_liquidity_oracle + _v5;
        let _v41 = &mut _v32.seconds_per_liquidity_oracle;
        *_v41 = _v40;
        let _v42 = *&_v32.seconds_per_liquidity_incentive + _v4;
        let _v43 = &mut _v32.seconds_per_liquidity_incentive;
        *_v43 = _v42;
        let _v44 = &mut _v32.last_update_timestamp;
        *_v44 = _v33;
        rewarder::flash(&mut _v32.rewarder_manager, _v39);
        let _v45 = rewarder::get_emissions_per_liquidity_list(&_v7.rewarder_manager);
        let _v46 = *&_v7.sqrt_price;
        let _v47 = *&_v7.tick;
        if (p1) _v3 = *&_v7.fee_growth_global_a else _v3 = *&_v7.fee_growth_global_b;
        let _v48 = *&_v7.seconds_per_liquidity_oracle;
        let _v49 = *&_v7.liquidity;
        let _v50 = 0;
        let _v51 = _v48;
        let _v52 = SwapState{amount_specified_remaining: p3, amount_calculated: 0, sqrt_price: _v46, tick: _v47, fee_growth_global: _v3, seconds_per_liquidity: _v51, protocol_fee: _v50, liquidity: _v49, fee_amount_total: 0};
        loop {
            let _v53;
            let _v54;
            if (*&(&_v52).amount_specified_remaining != 0) _v54 = *&(&_v52).sqrt_price != p5 else _v54 = false;
            if (!_v54) break;
            let _v55 = freeze(&mut _v7.tick_map);
            let _v56 = *&(&_v52).tick;
            let _v57 = *&_v7.tick_spacing;
            let (_v58,_v59) = tick_bitmap::next_initialized_tick_within_one_word(_v55, _v56, _v57, p1);
            let _v60 = _v58;
            let _v61 = tick_math::min_tick();
            if (i32::lte(_v60, _v61)) _v60 = tick_math::min_tick() else {
                let _v62 = tick_math::max_tick();
                if (i32::gte(_v60, _v62)) _v60 = tick_math::max_tick()
            };
            _v51 = tick_math::get_sqrt_price_at_tick(_v60);
            if (p1) _v49 = math128::max(_v51, p5) else _v49 = math128::min(_v51, p5);
            let _v63 = *&(&_v52).sqrt_price;
            let _v64 = *&(&_v52).liquidity;
            let _v65 = *&(&_v52).amount_specified_remaining;
            let _v66 = *&_v7.fee_rate;
            let (_v67,_v68,_v69,_v70) = swap_math::compute_swap_step(_v63, _v49, _v64, _v65, _v66, p1, p2);
            _v2 = _v70;
            let _v71 = _v69;
            _v1 = _v68;
            _v50 = _v67;
            let _v72 = *&(&_v52).fee_amount_total + _v2;
            let _v73 = &mut (&mut _v52).fee_amount_total;
            *_v73 = _v72;
            if (p2) {
                let _v74 = *&(&_v52).amount_specified_remaining;
                let _v75 = _v50 + _v2;
                let _v76 = _v74 - _v75;
                let _v77 = &mut (&mut _v52).amount_specified_remaining;
                *_v77 = _v76;
                let _v78 = *&(&_v52).amount_calculated + _v1;
                let _v79 = &mut (&mut _v52).amount_calculated;
                *_v79 = _v78
            } else {
                let _v80 = *&(&_v52).amount_specified_remaining - _v1;
                let _v81 = &mut (&mut _v52).amount_specified_remaining;
                *_v81 = _v80;
                let _v82 = *&(&_v52).amount_calculated + _v50 + _v2;
                let _v83 = &mut (&mut _v52).amount_calculated;
                *_v83 = _v82
            };
            let _v84 = *&(&_v52).sqrt_price;
            let _v85 = *&(&_v52).liquidity;
            let _v86 = StepComputations{sqrt_price_current: _v84, sqrt_price_next: _v71, amount_in: _v50, amount_out: _v1, fee_amount: _v2, current_liquidity: _v85};
            let _v87 = &mut (&mut _v52).sqrt_price;
            *_v87 = _v71;
            if (*&_v7.fee_protocol > 0) {
                let _v88 = _v2 as u128;
                let _v89 = (*&_v7.fee_protocol) as u128;
                let _v90 = (_v88 * _v89 / 1000000u128) as u64;
                _v2 = _v2 - _v90;
                let _v91 = *&(&_v52).protocol_fee + _v90;
                let _v92 = &mut (&mut _v52).protocol_fee;
                *_v92 = _v91
            };
            let _v93 = *&(&_v52).tick;
            let _v94 = position_blacklist_v2::blocked_out_liquidity_amount(_v6, _v93);
            _v94 = *&(&_v52).liquidity - _v94;
            if (*&(&_v52).liquidity > 0u128) _v53 = _v94 != 0u128 else _v53 = false;
            if (_v53) {
                let _v95 = *&(&_v52).fee_growth_global;
                let _v96 = full_math_u128::mul_div_ceil(_v2 as u128, 18446744073709551616u128, _v94);
                let _v97 = _v95 + _v96;
                let _v98 = &mut (&mut _v52).fee_growth_global;
                *_v98 = _v97
            };
            if (*&(&_v52).sqrt_price == _v51) {
                loop {
                    let _v99;
                    let _v100;
                    if (!_v59) break;
                    if (p1) {
                        _v100 = *&(&_v52).fee_growth_global;
                        _v99 = *&_v7.fee_growth_global_b
                    } else {
                        _v100 = *&_v7.fee_growth_global_a;
                        _v99 = *&(&_v52).fee_growth_global
                    };
                    let _v101 = get_tick_mut(&mut _v7.tick_info, _v60);
                    let _v102 = *&_v7.seconds_per_liquidity_oracle;
                    let _v103 = *&_v7.seconds_per_liquidity_incentive;
                    let _v104 = timestamp::now_seconds();
                    let _v105 = tick::cross(_v101, _v100, _v99, _v102, _v103, 0, _v45, _v104);
                    if (p1) {
                        let _v106 = i128::neg_from(1u128);
                        let _v107 = i128::mul(_v105, _v106);
                        if (i128::is_neg(_v107)) {
                            let _v108 = *&(&_v52).liquidity;
                            let _v109 = i128::abs_u128(_v107);
                            let _v110 = liquidity_math::sub_delta(_v108, _v109);
                            let _v111 = &mut (&mut _v52).liquidity;
                            *_v111 = _v110;
                            break
                        };
                        let _v112 = *&(&_v52).liquidity;
                        let _v113 = i128::abs_u128(_v107);
                        let _v114 = liquidity_math::add_delta(_v112, _v113);
                        let _v115 = &mut (&mut _v52).liquidity;
                        *_v115 = _v114;
                        break
                    };
                    if (i128::is_neg(_v105)) {
                        let _v116 = *&(&_v52).liquidity;
                        let _v117 = i128::abs_u128(_v105);
                        let _v118 = liquidity_math::sub_delta(_v116, _v117);
                        let _v119 = &mut (&mut _v52).liquidity;
                        *_v119 = _v118;
                        break
                    };
                    let _v120 = *&(&_v52).liquidity;
                    let _v121 = i128::abs_u128(_v105);
                    let _v122 = liquidity_math::add_delta(_v120, _v121);
                    let _v123 = &mut (&mut _v52).liquidity;
                    *_v123 = _v122;
                    break
                };
                if (p1) {
                    let _v124 = i32::from_u32(1u32);
                    let _v125 = i32::sub(_v60, _v124);
                    let _v126 = &mut (&mut _v52).tick;
                    *_v126 = _v125;
                    continue
                };
                let _v127 = &mut (&mut _v52).tick;
                *_v127 = _v60;
                continue
            };
            let _v128 = *&(&_v52).sqrt_price;
            let _v129 = *&(&_v86).sqrt_price_current;
            if (!(_v128 != _v129)) continue;
            let _v130 = tick_math::get_tick_at_sqrt_price(*&(&_v52).sqrt_price);
            let _v131 = &mut (&mut _v52).tick;
            *_v131 = _v130;
            continue
        };
        let _v132 = *&(&_v52).tick;
        let _v133 = *&_v7.tick;
        if (_v132 != _v133) {
            let _v134 = *&(&_v52).sqrt_price;
            let _v135 = &mut _v7.sqrt_price;
            *_v135 = _v134;
            let _v136 = *&(&_v52).tick;
            let _v137 = &mut _v7.tick;
            *_v137 = _v136
        } else {
            let _v138 = *&(&_v52).sqrt_price;
            let _v139 = &mut _v7.sqrt_price;
            *_v139 = _v138
        };
        let _v140 = *&_v7.liquidity;
        let _v141 = *&(&_v52).liquidity;
        if (_v140 != _v141) {
            let _v142 = *&(&_v52).liquidity;
            let _v143 = &mut _v7.liquidity;
            *_v143 = _v142
        };
        if (p1) {
            let _v144 = *&(&_v52).fee_growth_global;
            let _v145 = &mut _v7.fee_growth_global_a;
            *_v145 = _v144;
            let _v146 = &mut p4;
            let _v147 = *&(&_v52).protocol_fee;
            commission::distribute(fungible_asset::extract(_v146, _v147))
        } else {
            let _v148 = *&(&_v52).fee_growth_global;
            let _v149 = &mut _v7.fee_growth_global_b;
            *_v149 = _v148;
            let _v150 = &mut p4;
            let _v151 = *&(&_v52).protocol_fee;
            commission::distribute(fungible_asset::extract(_v150, _v151))
        };
        if (p1 == p2) {
            let _v152 = *&(&_v52).amount_specified_remaining;
            _v50 = p3 - _v152;
            _v1 = *&(&_v52).amount_calculated
        } else {
            _v50 = *&(&_v52).amount_calculated;
            let _v153 = *&(&_v52).amount_specified_remaining;
            _v1 = p3 - _v153
        };
        if (p1) {
            let _v154 = package_manager::get_signer();
            let _v155 = &_v154;
            let _v156 = *&(&_v52).protocol_fee;
            _v50 = _v50 - _v156;
            let _v157 = *&_v7.token_a_liquidity;
            let _v158 = fungible_asset::extract(&mut p4, _v50);
            dispatchable_fungible_asset::deposit<fungible_asset::FungibleStore>(_v157, _v158);
            _v2 = _v50;
            let _v159 = *&_v7.token_b_liquidity;
            _v0 = dispatchable_fungible_asset::withdraw<fungible_asset::FungibleStore>(_v155, _v159, _v1)
        } else {
            let _v160 = package_manager::get_signer();
            let _v161 = &_v160;
            let _v162 = *&(&_v52).protocol_fee;
            _v1 = _v1 - _v162;
            let _v163 = *&_v7.token_b_liquidity;
            let _v164 = fungible_asset::extract(&mut p4, _v1);
            dispatchable_fungible_asset::deposit<fungible_asset::FungibleStore>(_v163, _v164);
            _v2 = _v1;
            let _v165 = *&_v7.token_a_liquidity;
            _v0 = dispatchable_fungible_asset::withdraw<fungible_asset::FungibleStore>(_v161, _v165, _v50)
        };
        let _v166 = object::object_address<LiquidityPoolV3>(&p0);
        let _v167 = *&_v7.tick;
        let _v168 = *&_v7.sqrt_price;
        let _v169 = *&_v7.liquidity;
        event::emit<SwapAfterEvent>(SwapAfterEvent{pool_id: _v166, tick: _v167, sqrt_price: _v168, liquidity: _v169});
        let _v170 = object::object_address<LiquidityPoolV3>(&p0);
        _v10 = freeze(_v7);
        let _v171 = *&_v10.sqrt_price;
        let _v172 = *&_v10.liquidity;
        let _v173 = *&_v10.tick;
        let _v174 = *&_v10.observation_index;
        let _v175 = *&_v10.observation_cardinality;
        let _v176 = *&_v10.observation_cardinality_next;
        let _v177 = *&_v10.fee_rate;
        let _v178 = *&_v10.fee_growth_global_a;
        let _v179 = *&_v10.fee_growth_global_b;
        let _v180 = *&_v10.tick_spacing;
        let _v181 = fungible_asset::balance<fungible_asset::FungibleStore>(*&_v10.token_a_liquidity);
        let _v182 = fungible_asset::balance<fungible_asset::FungibleStore>(*&_v10.token_b_liquidity);
        event::emit<PoolSnapshotV2>(PoolSnapshotV2{pool_id: _v170, sqrt_price: _v171, liquidity: _v172, tick: _v173, observation_index: _v174, observation_cardinality: _v175, observation_cardinality_next: _v176, fee_rate: _v177, fee_rate_denominatore: 1000000, fee_growth_global_a: _v178, fee_growth_global_b: _v179, tick_spacing: _v180, token_a_reserve: _v181, token_b_reserve: _v182});
        let _v183 = object::object_address<LiquidityPoolV3>(&p0);
        let _v184 = fungible_asset::metadata_from_asset(&p4);
        let _v185 = fungible_asset::metadata_from_asset(&_v0);
        let _v186 = fungible_asset::amount(&_v0);
        let _v187 = *&(&_v52).fee_amount_total;
        let _v188 = *&(&_v52).protocol_fee;
        let _v189 = fungible_asset::balance<fungible_asset::FungibleStore>(*&_v7.token_a_liquidity);
        let _v190 = fungible_asset::balance<fungible_asset::FungibleStore>(*&_v7.token_b_liquidity);
        _v51 = *&_v7.sqrt_price;
        let _v191 = *&_v7.tick;
        let _v192 = *&_v7.liquidity;
        event::emit<SwapEventV3>(SwapEventV3{pool_id: _v183, from_token: _v184, to_token: _v185, amount_in: _v2, amount_out: _v186, fee_amount: _v187, protocol_fee_amount: _v188, pool_reserve_a: _v189, pool_reserve_b: _v190, current_tick: _v191, sqrt_price: _v51, active_liquidity: _v192});
        (_v2, p4, _v0)
    }
    public fun current_tick(p0: object::Object<fungible_asset::Metadata>, p1: object::Object<fungible_asset::Metadata>, p2: u8): i32::I32
        acquires LiquidityPoolV3
    {
        let _v0 = liquidity_pool_address(p0, p1, p2);
        *&borrow_global<LiquidityPoolV3>(_v0).tick
    }
    public fun all_pools(): vector<object::Object<LiquidityPoolV3>>
        acquires LiquidityPoolConfigsV3
    {
        let _v0 = package_manager::get_resource_address();
        let _v1 = &borrow_global<LiquidityPoolConfigsV3>(_v0).all_pools;
        let _v2 = 0x1::vector::empty<object::Object<LiquidityPoolV3>>();
        let _v3 = smart_vector::length<object::Object<LiquidityPoolV3>>(_v1);
        let _v4 = 0;
        while (_v4 < _v3) {
            let _v5 = &mut _v2;
            let _v6 = *smart_vector::borrow<object::Object<LiquidityPoolV3>>(_v1, _v4);
            0x1::vector::push_back<object::Object<LiquidityPoolV3>>(_v5, _v6);
            _v4 = _v4 + 1;
            continue
        };
        _v2
    }
    fun check_protocol_pause()
        acquires LiquidityPoolConfigsV3
    {
        let _v0 = package_manager::get_resource_address();
        if (*&borrow_global<LiquidityPoolConfigsV3>(_v0).is_paused) abort 100014;
    }
    fun get_tick_mut(p0: &mut smart_table::SmartTable<i32::I32, tick::TickInfo>, p1: i32::I32): &mut tick::TickInfo {
        if (!smart_table::contains<i32::I32, tick::TickInfo>(freeze(p0), p1)) {
            let _v0 = tick::empty();
            smart_table::add<i32::I32, tick::TickInfo>(p0, p1, _v0)
        };
        smart_table::borrow_mut<i32::I32, tick::TickInfo>(p0, p1)
    }
    public entry fun initialize() {
        if (is_initialized()) return ();
        let _v0 = package_manager::get_signer();
        let _v1 = &_v0;
        let _v2 = LiquidityPoolConfigsV3{all_pools: smart_vector::new<object::Object<LiquidityPoolV3>>(), is_paused: false, fee_manager: @0xd548f6e8ef91c57e7983b1051df686a3753f3d453d37ef781782450e61079fe9, pauser: @0xd548f6e8ef91c57e7983b1051df686a3753f3d453d37ef781782450e61079fe9, pending_fee_manager: @0x0, pending_pauser: @0x0, tick_spacing_list: vector[10, 60, 200]};
        move_to<LiquidityPoolConfigsV3>(_v1, _v2);
    }
    public fun is_initialized(): bool {
        let _v0 = package_manager::get_resource_address();
        exists<LiquidityPoolConfigsV3>(_v0)
    }
    fun init_module(p0: &signer) {
        initialize();
    }
    public fun current_price(p0: object::Object<fungible_asset::Metadata>, p1: object::Object<fungible_asset::Metadata>, p2: u8): u128
        acquires LiquidityPoolV3
    {
        let _v0 = liquidity_pool_address(p0, p1, p2);
        *&borrow_global<LiquidityPoolV3>(_v0).sqrt_price
    }
    public fun liquidity_pool_address(p0: object::Object<fungible_asset::Metadata>, p1: object::Object<fungible_asset::Metadata>, p2: u8): address {
        if (!utils::is_sorted(p0, p1)) return liquidity_pool_address(p1, p0, p2);
        let _v0 = package_manager::get_resource_address();
        let _v1 = &_v0;
        let _v2 = lp::get_pool_seeds(p0, p1, p2);
        object::create_object_address(_v1, _v2)
    }
    public entry fun update_net_only(p0: &signer, p1: address, p2: u128, p3: u32, p4: u32) {
        let _v0 = error::unavailable(11111111);
        abort _v0
    }
    public fun add_incentive(p0: &signer, p1: object::Object<LiquidityPoolV3>, p2: u64, p3: object::Object<fungible_asset::Metadata>, p4: u64)
        acquires LiquidityPoolV3
    {
        let _v0 = signer::address_of(p0);
        let _v1 = object::object_address<LiquidityPoolV3>(&p1);
        let _v2 = borrow_global_mut<LiquidityPoolV3>(_v1);
        let _v3 = primary_fungible_store::ensure_primary_store_exists<fungible_asset::Metadata>(_v0, p3);
        let _v4 = dispatchable_fungible_asset::withdraw<fungible_asset::FungibleStore>(p0, _v3, p4);
        let _v5 = &mut _v2.rewarder_manager;
        let _v6 = *&_v2.liquidity;
        rewarder::add_incentive(_v5, _v6, _v4, p2, _v1);
    }
    public fun add_rewarder(p0: &signer, p1: object::Object<LiquidityPoolV3>, p2: object::Object<fungible_asset::Metadata>, p3: u64, p4: u64, p5: u64)
        acquires LiquidityPoolV3
    {
        let _v0 = signer::address_of(p0);
        let _v1 = string::utf8(vector[97u8, 100u8, 100u8, 95u8, 114u8, 101u8, 119u8, 97u8, 114u8, 100u8, 101u8, 114u8]);
        package_manager::assert_admin(p0, _v1);
        let _v2 = object::object_address<LiquidityPoolV3>(&p1);
        let _v3 = borrow_global_mut<LiquidityPoolV3>(_v2);
        let _v4 = primary_fungible_store::ensure_primary_store_exists<fungible_asset::Metadata>(_v0, p2);
        let _v5 = dispatchable_fungible_asset::withdraw<fungible_asset::FungibleStore>(p0, _v4, p5);
        let _v6 = &mut _v3.rewarder_manager;
        let _v7 = *&_v3.liquidity;
        rewarder::add_rewarder(_v2, _v6, p3, p4, _v7, _v5);
    }
    public fun claim_rewards(p0: &signer, p1: object::Object<position_v3::Info>): vector<fungible_asset::FungibleAsset>
        acquires LiquidityPoolConfigsV3, LiquidityPoolV3
    {
        let _v0;
        let _v1;
        check_protocol_pause();
        let (_v2,_v3,_v4) = position_v3::get_pool_info(p1);
        let _v5 = liquidity_pool_address(_v2, _v3, _v4);
        let _v6 = signer::address_of(p0);
        assert!(object::is_owner<position_v3::Info>(p1, _v6), 100008);
        let _v7 = object::object_address<position_v3::Info>(&p1);
        if (position_blacklist_v2::does_position_blocked(_v5, _v7)) abort 100016;
        let _v8 = p1;
        let (_v9,_v10) = position_v3::get_tick(_v8);
        let _v11 = _v10;
        let _v12 = _v9;
        let (_v13,_v14,_v15) = position_v3::get_pool_info(_v8);
        let _v16 = _v15;
        let _v17 = _v14;
        let _v18 = _v13;
        let _v19 = liquidity_pool_address(_v18, _v17, _v16);
        let _v20 = borrow_global_mut<LiquidityPoolV3>(_v19);
        let _v21 = liquidity_pool_address(_v18, _v17, _v16);
        let _v22 = liquidity_pool_address(_v18, _v17, _v16);
        let _v23 = freeze(_v20);
        let _v24 = *&_v23.sqrt_price;
        let _v25 = *&_v23.liquidity;
        let _v26 = *&_v23.tick;
        let _v27 = *&_v23.observation_index;
        let _v28 = *&_v23.observation_cardinality;
        let _v29 = *&_v23.observation_cardinality_next;
        let _v30 = *&_v23.fee_rate;
        let _v31 = *&_v23.fee_growth_global_a;
        let _v32 = *&_v23.fee_growth_global_b;
        let _v33 = *&_v23.tick_spacing;
        let _v34 = fungible_asset::balance<fungible_asset::FungibleStore>(*&_v23.token_a_liquidity);
        let _v35 = fungible_asset::balance<fungible_asset::FungibleStore>(*&_v23.token_b_liquidity);
        event::emit<PoolSnapshotV2>(PoolSnapshotV2{pool_id: _v22, sqrt_price: _v24, liquidity: _v25, tick: _v26, observation_index: _v27, observation_cardinality: _v28, observation_cardinality_next: _v29, fee_rate: _v30, fee_rate_denominatore: 1000000, fee_growth_global_a: _v31, fee_growth_global_b: _v32, tick_spacing: _v33, token_a_reserve: _v34, token_b_reserve: _v35});
        let _v36 = _v20;
        let _v37 = timestamp::now_seconds();
        let _v38 = *&_v36.last_update_timestamp;
        let _v39 = _v37 - _v38;
        if (*&_v36.liquidity != 0u128) {
            let _v40 = (_v39 as u128) << 64u8;
            let _v41 = *&_v36.liquidity;
            _v1 = _v40 / _v41
        } else _v1 = 0u128;
        _v23 = freeze(_v36);
        let _v42 = *&_v23.tick;
        let _v43 = position_blacklist_v2::blocked_out_liquidity_amount(_v21, _v42);
        _v43 = *&_v23.liquidity - _v43;
        if (_v43 != 0u128) _v0 = ((_v39 as u128) << 64u8) / _v43 else _v0 = 0u128;
        let _v44 = *&_v36.seconds_per_liquidity_oracle + _v1;
        let _v45 = &mut _v36.seconds_per_liquidity_oracle;
        *_v45 = _v44;
        let _v46 = *&_v36.seconds_per_liquidity_incentive + _v0;
        let _v47 = &mut _v36.seconds_per_liquidity_incentive;
        *_v47 = _v46;
        let _v48 = &mut _v36.last_update_timestamp;
        *_v48 = _v37;
        rewarder::flash(&mut _v36.rewarder_manager, _v43);
        let _v49 = position_v3::get_position_rewards_v2(_v8);
        let _v50 = _v20;
        let _v51 = _v12;
        let _v52 = rewarder::get_emissions_rate_list(&_v50.rewarder_manager);
        let _v53 = get_tick(&_v50.tick_info, _v51);
        let _v54 = tick::get_emissions_per_liquidity_outside(&_v53);
        let _v55 = 0x1::vector::length<u64>(&_v52);
        let _v56 = 0x1::vector::length<u128>(&_v54);
        if (_v55 != _v56) {
            let _v57 = get_tick_mut(&mut _v50.tick_info, _v51);
            let _v58 = 0x1::vector::length<u64>(&_v52);
            tick::padding_emissions_list(_v57, _v58)
        };
        let _v59 = _v20;
        let _v60 = _v11;
        let _v61 = rewarder::get_emissions_rate_list(&_v59.rewarder_manager);
        let _v62 = get_tick(&_v59.tick_info, _v60);
        let _v63 = tick::get_emissions_per_liquidity_outside(&_v62);
        let _v64 = 0x1::vector::length<u64>(&_v61);
        let _v65 = 0x1::vector::length<u128>(&_v63);
        if (_v64 != _v65) {
            let _v66 = get_tick_mut(&mut _v59.tick_info, _v60);
            let _v67 = 0x1::vector::length<u64>(&_v61);
            tick::padding_emissions_list(_v66, _v67)
        };
        let _v68 = rewarder::get_emissions_per_liquidity_list(&_v20.rewarder_manager);
        let _v69 = get_tick(&_v20.tick_info, _v12);
        let _v70 = get_tick(&_v20.tick_info, _v11);
        let _v71 = *&_v20.tick;
        _v68 = tick::get_emissions_per_liquidity_incentive_inside(_v69, _v70, _v12, _v11, _v71, _v68);
        let _v72 = lp::get_signer(&_v20.lp_token_refs);
        let _v73 = &_v72;
        let _v74 = object::object_address<position_v3::Info>(&_v8);
        let _v75 = &mut _v20.rewarder_manager;
        let _v76 = *&_v20.liquidity;
        let _v77 = position_v3::get_liquidity(_v8);
        let (_v78,_v79) = rewarder::claim_rewards(_v73, _v6, _v74, _v75, _v49, _v68, _v76, _v77);
        position_v3::update_rewards(_v8, _v79);
        let _v80 = liquidity_pool_address(_v18, _v17, _v16);
        _v23 = freeze(_v20);
        let _v81 = *&_v23.sqrt_price;
        let _v82 = *&_v23.liquidity;
        let _v83 = *&_v23.tick;
        let _v84 = *&_v23.observation_index;
        let _v85 = *&_v23.observation_cardinality;
        let _v86 = *&_v23.observation_cardinality_next;
        let _v87 = *&_v23.fee_rate;
        let _v88 = *&_v23.fee_growth_global_a;
        let _v89 = *&_v23.fee_growth_global_b;
        let _v90 = *&_v23.tick_spacing;
        let _v91 = fungible_asset::balance<fungible_asset::FungibleStore>(*&_v23.token_a_liquidity);
        let _v92 = fungible_asset::balance<fungible_asset::FungibleStore>(*&_v23.token_b_liquidity);
        event::emit<PoolSnapshotV2>(PoolSnapshotV2{pool_id: _v80, sqrt_price: _v81, liquidity: _v82, tick: _v83, observation_index: _v84, observation_cardinality: _v85, observation_cardinality_next: _v86, fee_rate: _v87, fee_rate_denominatore: 1000000, fee_growth_global_a: _v88, fee_growth_global_b: _v89, tick_spacing: _v90, token_a_reserve: _v91, token_b_reserve: _v92});
        _v78
    }
    fun get_tick(p0: &smart_table::SmartTable<i32::I32, tick::TickInfo>, p1: i32::I32): tick::TickInfo {
        let _v0 = tick::empty();
        let _v1 = &_v0;
        *smart_table::borrow_with_default<i32::I32, tick::TickInfo>(p0, p1, _v1)
    }
    public entry fun remove_incentive(p0: &signer, p1: object::Object<LiquidityPoolV3>, p2: u64, p3: u64)
        acquires LiquidityPoolV3
    {
        let _v0 = signer::address_of(p0);
        let _v1 = string::utf8(vector[114u8, 101u8, 109u8, 111u8, 118u8, 101u8, 95u8, 105u8, 110u8, 99u8, 101u8, 110u8, 116u8, 105u8, 118u8, 101u8]);
        package_manager::assert_admin(p0, _v1);
        let _v2 = object::object_address<LiquidityPoolV3>(&p1);
        let _v3 = borrow_global_mut<LiquidityPoolV3>(_v2);
        let _v4 = lp::get_signer(&_v3.lp_token_refs);
        let _v5 = &_v4;
        let _v6 = &mut _v3.rewarder_manager;
        let _v7 = *&_v3.liquidity;
        let _v8 = rewarder::remove_incentive(_v5, _v6, _v7, p2, p3);
        let _v9 = fungible_asset::metadata_from_asset(&_v8);
        dispatchable_fungible_asset::deposit<fungible_asset::FungibleStore>(primary_fungible_store::ensure_primary_store_exists<fungible_asset::Metadata>(_v0, _v9), _v8);
    }
    public entry fun remove_incentive_to_pause(p0: &signer, p1: object::Object<LiquidityPoolV3>, p2: u64)
        acquires LiquidityPoolV3
    {
        let _v0 = signer::address_of(p0);
        let _v1 = string::utf8(vector[114u8, 101u8, 109u8, 111u8, 118u8, 101u8, 95u8, 105u8, 110u8, 99u8, 101u8, 110u8, 116u8, 105u8, 118u8, 101u8, 95u8, 116u8, 111u8, 95u8, 112u8, 97u8, 117u8, 115u8, 101u8]);
        package_manager::assert_admin(p0, _v1);
        let _v2 = object::object_address<LiquidityPoolV3>(&p1);
        let _v3 = borrow_global_mut<LiquidityPoolV3>(_v2);
        let _v4 = lp::get_signer(&_v3.lp_token_refs);
        let _v5 = &_v4;
        let _v6 = &mut _v3.rewarder_manager;
        let _v7 = *&_v3.liquidity;
        let _v8 = rewarder::remove_incentive_to_pause(_v5, _v6, _v7, p2);
        let _v9 = fungible_asset::metadata_from_asset(&_v8);
        dispatchable_fungible_asset::deposit<fungible_asset::FungibleStore>(primary_fungible_store::ensure_primary_store_exists<fungible_asset::Metadata>(_v0, _v9), _v8);
    }
    public entry fun set_rewarder_op_admin(p0: &signer, p1: address, p2: object::Object<LiquidityPoolV3>, p3: u64)
        acquires LiquidityPoolV3
    {
        let _v0 = string::utf8(vector[115u8, 101u8, 116u8, 95u8, 114u8, 101u8, 119u8, 97u8, 114u8, 100u8, 101u8, 114u8, 95u8, 111u8, 112u8, 95u8, 97u8, 100u8, 109u8, 105u8, 110u8]);
        package_manager::assert_admin(p0, _v0);
        let _v1 = object::object_address<LiquidityPoolV3>(&p2);
        assert!(rewarder::get_rewarder_list_length(&borrow_global<LiquidityPoolV3>(_v1).rewarder_manager) > p3, 100019);
        rewarder::set_rewarder_op_admin(p0, p1, _v1, p3);
    }
    public entry fun update_emissions_rate(p0: &signer, p1: object::Object<LiquidityPoolV3>, p2: u64, p3: u64)
        acquires LiquidityPoolV3
    {
        let _v0;
        let _v1 = signer::address_of(p0);
        let _v2 = object::object_address<LiquidityPoolV3>(&p1);
        if (package_manager::is_op_admin(_v1)) _v0 = true else _v0 = rewarder::is_rewarder_op_admin(_v1, _v2, p2);
        assert!(_v0, 100018);
        let _v3 = borrow_global_mut<LiquidityPoolV3>(_v2);
        let _v4 = &mut _v3.rewarder_manager;
        let _v5 = *&_v3.liquidity;
        rewarder::update_emissions_rate(_v2, _v4, _v5, p2, p3);
    }
    public entry fun update_emissions_rate_max(p0: &signer, p1: object::Object<LiquidityPoolV3>, p2: u64, p3: u64)
        acquires LiquidityPoolV3
    {
        let _v0;
        let _v1 = signer::address_of(p0);
        let _v2 = object::object_address<LiquidityPoolV3>(&p1);
        if (package_manager::is_op_admin(_v1)) _v0 = true else _v0 = rewarder::is_rewarder_op_admin(_v1, _v2, p2);
        assert!(_v0, 100018);
        let _v3 = borrow_global_mut<LiquidityPoolV3>(_v2);
        let _v4 = &mut _v3.rewarder_manager;
        let _v5 = *&_v3.liquidity;
        rewarder::update_emissions_rate_max(_v2, _v4, _v5, p2, p3);
    }
    public entry fun update_rewarder_owed(p0: &signer, p1: address, p2: u64, p3: u64) {
        let _v0 = error::unavailable(11111111);
        abort _v0
    }
    public fun user_managed_rewarders(p0: address): vector<string::String> {
        rewarder::user_managed_rewarders(p0)
    }
    public fun add_liquidity(p0: &signer, p1: object::Object<position_v3::Info>, p2: u128, p3: fungible_asset::FungibleAsset, p4: fungible_asset::FungibleAsset): (u64, u64, fungible_asset::FungibleAsset, fungible_asset::FungibleAsset) {
        let _v0 = error::unavailable(11111111);
        abort _v0
    }
    public fun claim_fees(p0: &signer, p1: object::Object<position_v3::Info>): (fungible_asset::FungibleAsset, fungible_asset::FungibleAsset)
        acquires LiquidityPoolConfigsV3, LiquidityPoolV3
    {
        let _v0;
        let _v1;
        let (_v2,_v3,_v4) = position_v3::get_pool_info(p1);
        let _v5 = liquidity_pool_address(_v2, _v3, _v4);
        let _v6 = signer::address_of(p0);
        assert!(object::is_owner<position_v3::Info>(p1, _v6), 100008);
        check_protocol_pause();
        let _v7 = object::object_address<position_v3::Info>(&p1);
        if (position_blacklist_v2::does_position_blocked(_v5, _v7)) abort 100016;
        _v6 = signer::address_of(p0);
        let _v8 = p1;
        let (_v9,_v10) = position_v3::get_tick(_v8);
        let _v11 = _v10;
        let _v12 = _v9;
        let (_v13,_v14,_v15) = position_v3::get_pool_info(_v8);
        let _v16 = _v15;
        let _v17 = _v14;
        let _v18 = _v13;
        let _v19 = liquidity_pool_address(_v18, _v17, _v16);
        let _v20 = object::object_address<position_v3::Info>(&_v8);
        if (position_blacklist_v2::does_position_blocked(_v19, _v20)) abort 100016;
        let _v21 = liquidity_pool_address(_v18, _v17, _v16);
        let _v22 = borrow_global_mut<LiquidityPoolV3>(_v21);
        let _v23 = liquidity_pool_address(_v18, _v17, _v16);
        let _v24 = liquidity_pool_address(_v18, _v17, _v16);
        let _v25 = freeze(_v22);
        let _v26 = *&_v25.sqrt_price;
        let _v27 = *&_v25.liquidity;
        let _v28 = *&_v25.tick;
        let _v29 = *&_v25.observation_index;
        let _v30 = *&_v25.observation_cardinality;
        let _v31 = *&_v25.observation_cardinality_next;
        let _v32 = *&_v25.fee_rate;
        let _v33 = *&_v25.fee_growth_global_a;
        let _v34 = *&_v25.fee_growth_global_b;
        let _v35 = *&_v25.tick_spacing;
        let _v36 = fungible_asset::balance<fungible_asset::FungibleStore>(*&_v25.token_a_liquidity);
        let _v37 = fungible_asset::balance<fungible_asset::FungibleStore>(*&_v25.token_b_liquidity);
        event::emit<PoolSnapshotV2>(PoolSnapshotV2{pool_id: _v24, sqrt_price: _v26, liquidity: _v27, tick: _v28, observation_index: _v29, observation_cardinality: _v30, observation_cardinality_next: _v31, fee_rate: _v32, fee_rate_denominatore: 1000000, fee_growth_global_a: _v33, fee_growth_global_b: _v34, tick_spacing: _v35, token_a_reserve: _v36, token_b_reserve: _v37});
        let _v38 = _v22;
        let _v39 = timestamp::now_seconds();
        let _v40 = *&_v38.last_update_timestamp;
        let _v41 = _v39 - _v40;
        if (*&_v38.liquidity != 0u128) {
            let _v42 = (_v41 as u128) << 64u8;
            let _v43 = *&_v38.liquidity;
            _v1 = _v42 / _v43
        } else _v1 = 0u128;
        _v25 = freeze(_v38);
        let _v44 = *&_v25.tick;
        let _v45 = position_blacklist_v2::blocked_out_liquidity_amount(_v23, _v44);
        _v45 = *&_v25.liquidity - _v45;
        if (_v45 != 0u128) _v0 = ((_v41 as u128) << 64u8) / _v45 else _v0 = 0u128;
        let _v46 = *&_v38.seconds_per_liquidity_oracle + _v1;
        let _v47 = &mut _v38.seconds_per_liquidity_oracle;
        *_v47 = _v46;
        let _v48 = *&_v38.seconds_per_liquidity_incentive + _v0;
        let _v49 = &mut _v38.seconds_per_liquidity_incentive;
        *_v49 = _v48;
        let _v50 = &mut _v38.last_update_timestamp;
        *_v50 = _v39;
        rewarder::flash(&mut _v38.rewarder_manager, _v45);
        let _v51 = rewarder::get_emissions_per_liquidity_list(&_v22.rewarder_manager);
        let _v52 = &mut _v22.tick_info;
        let _v53 = *&_v22.fee_growth_global_a;
        let _v54 = *&_v22.fee_growth_global_b;
        let _v55 = *&_v22.seconds_per_liquidity_oracle;
        let _v56 = *&_v22.seconds_per_liquidity_incentive;
        let _v57 = *&_v22.tick;
        let _v58 = update_tick(_v52, _v23, _v12, _v53, _v54, _v55, _v56, _v51, true, 0u128, _v57, false);
        let _v59 = &mut _v22.tick_info;
        let _v60 = *&_v22.fee_growth_global_a;
        let _v61 = *&_v22.fee_growth_global_b;
        let _v62 = *&_v22.seconds_per_liquidity_oracle;
        let _v63 = *&_v22.seconds_per_liquidity_incentive;
        let _v64 = *&_v22.tick;
        let _v65 = update_tick(_v59, _v23, _v11, _v60, _v61, _v62, _v63, _v51, true, 0u128, _v64, true);
        if (_v58) {
            let _v66 = &mut _v22.tick_map;
            let _v67 = *&_v22.tick_spacing;
            tick_bitmap::flip_tick(_v66, _v12, _v67)
        };
        if (_v65) {
            let _v68 = &mut _v22.tick_map;
            let _v69 = *&_v22.tick_spacing;
            tick_bitmap::flip_tick(_v68, _v11, _v69)
        };
        let _v70 = get_tick(&_v22.tick_info, _v12);
        let _v71 = get_tick(&_v22.tick_info, _v11);
        let _v72 = *&_v22.tick;
        let _v73 = *&_v22.fee_growth_global_a;
        let _v74 = *&_v22.fee_growth_global_b;
        let (_v75,_v76) = tick::get_fee_growth_inside(_v70, _v71, _v12, _v11, _v72, _v73, _v74);
        let (_v77,_v78) = position_v3::claim_fees(_v8, _v75, _v76);
        let _v79 = package_manager::get_signer();
        let _v80 = &_v79;
        let _v81 = *&_v22.token_a_liquidity;
        let _v82 = dispatchable_fungible_asset::withdraw<fungible_asset::FungibleStore>(_v80, _v81, _v77);
        let _v83 = *&_v22.token_b_liquidity;
        let _v84 = dispatchable_fungible_asset::withdraw<fungible_asset::FungibleStore>(_v80, _v83, _v78);
        let _v85 = liquidity_pool_address(_v18, _v17, _v16);
        _v25 = freeze(_v22);
        let _v86 = *&_v25.sqrt_price;
        let _v87 = *&_v25.liquidity;
        let _v88 = *&_v25.tick;
        let _v89 = *&_v25.observation_index;
        let _v90 = *&_v25.observation_cardinality;
        let _v91 = *&_v25.observation_cardinality_next;
        let _v92 = *&_v25.fee_rate;
        let _v93 = *&_v25.fee_growth_global_a;
        let _v94 = *&_v25.fee_growth_global_b;
        let _v95 = *&_v25.tick_spacing;
        let _v96 = fungible_asset::balance<fungible_asset::FungibleStore>(*&_v25.token_a_liquidity);
        let _v97 = fungible_asset::balance<fungible_asset::FungibleStore>(*&_v25.token_b_liquidity);
        event::emit<PoolSnapshotV2>(PoolSnapshotV2{pool_id: _v85, sqrt_price: _v86, liquidity: _v87, tick: _v88, observation_index: _v89, observation_cardinality: _v90, observation_cardinality_next: _v91, fee_rate: _v92, fee_rate_denominatore: 1000000, fee_growth_global_a: _v93, fee_growth_global_b: _v94, tick_spacing: _v95, token_a_reserve: _v96, token_b_reserve: _v97});
        let _v98 = liquidity_pool(_v18, _v17, _v16);
        let _v99 = fungible_asset::amount(&_v82);
        let _v100 = fungible_asset::balance<fungible_asset::FungibleStore>(*&_v22.token_a_liquidity);
        let _v101 = fungible_asset::balance<fungible_asset::FungibleStore>(*&_v22.token_b_liquidity);
        event::emit<ClaimFeesEventV2>(ClaimFeesEventV2{pool: _v98, lp_object: _v8, token: _v18, amount: _v99, owner: _v6, token_a_liquidity_after_claim: _v100, token_b_liquidity_after_claim: _v101});
        let _v102 = liquidity_pool(_v18, _v17, _v16);
        let _v103 = fungible_asset::amount(&_v84);
        let _v104 = fungible_asset::balance<fungible_asset::FungibleStore>(*&_v22.token_a_liquidity);
        let _v105 = fungible_asset::balance<fungible_asset::FungibleStore>(*&_v22.token_b_liquidity);
        event::emit<ClaimFeesEventV2>(ClaimFeesEventV2{pool: _v102, lp_object: _v8, token: _v17, amount: _v103, owner: _v6, token_a_liquidity_after_claim: _v104, token_b_liquidity_after_claim: _v105});
        (_v82, _v84)
    }
    fun update_tick(p0: &mut smart_table::SmartTable<i32::I32, tick::TickInfo>, p1: address, p2: i32::I32, p3: u128, p4: u128, p5: u128, p6: u128, p7: vector<u128>, p8: bool, p9: u128, p10: i32::I32, p11: bool): bool {
        tick::update_v2(get_tick_mut(p0, p2), p1, p2, p3, p4, p5, p6, p7, p8, p9, p10, p11)
    }
    public fun liquidity_pool(p0: object::Object<fungible_asset::Metadata>, p1: object::Object<fungible_asset::Metadata>, p2: u8): object::Object<LiquidityPoolV3> {
        object::address_to_object<LiquidityPoolV3>(liquidity_pool_address(p0, p1, p2))
    }
    public fun open_position(p0: &signer, p1: object::Object<fungible_asset::Metadata>, p2: object::Object<fungible_asset::Metadata>, p3: u8, p4: u32, p5: u32): object::Object<position_v3::Info>
        acquires LiquidityPoolConfigsV3, LiquidityPoolV3
    {
        let _v0;
        let _v1 = utils::is_sorted(p1, p2);
        loop {
            if (_v1) {
                check_protocol_pause();
                let _v2 = signer::address_of(p0);
                let _v3 = get_tick_spacing(p3);
                tick_math::check_tick_spacing(i32::from_u32(p4), _v3);
                tick_math::check_tick_spacing(i32::from_u32(p5), _v3);
                let _v4 = i32::from_u32(p4);
                let _v5 = i32::from_u32(p5);
                tick_math::check_tick(_v4, _v5);
                assert!(liquidity_pool_exists(p1, p2, p3), 100011);
                let _v6 = liquidity_pool_address(p1, p2, p3);
                let _v7 = borrow_global_mut<LiquidityPoolV3>(_v6);
                let _v8 = lp::get_signer(&_v7.lp_token_refs);
                position_blacklist_v2::new_v2(&_v8);
                let _v9 = object::create_object(_v2);
                let _v10 = &_v9;
                lp::new_lp_object(_v10, p1, p2, p3);
                let _v11 = i32::from_u32(p4);
                let _v12 = i32::from_u32(p5);
                let _v13 = liquidity_pool_address(p1, p2, p3);
                _v0 = position_v3::open_position(_v10, _v11, _v12, p1, p2, p3, _v13);
                let _v14 = rewarder::new_rewards_record(&_v7.rewarder_manager);
                position_v3::update_rewards(_v0, _v14);
                if (!position_blacklist_v2::does_address_blocked(_v2)) break;
                let _v15 = liquidity_pool_address(p1, p2, p3);
                let _v16 = object::object_address<position_v3::Info>(&_v0);
                position_blacklist_v2::check_address_then_block_position(_v15, _v2, _v16);
                break
            };
            let _v17 = i32::from_u32(p5);
            let _v18 = i32::neg_from(1u32);
            let _v19 = i32::as_u32(i32::mul(_v17, _v18));
            let _v20 = i32::from_u32(p4);
            let _v21 = i32::neg_from(1u32);
            let _v22 = i32::as_u32(i32::mul(_v20, _v21));
            return open_position(p0, p2, p1, p3, _v19, _v22)
        };
        _v0
    }
    public fun get_tick_spacing(p0: u8): u32 {
        let _v0 = vector[1u32, 10u32, 60u32, 200u32, 20u32, 50u32];
        let _v1 = &_v0;
        let _v2 = p0 as u64;
        *0x1::vector::borrow<u32>(_v1, _v2)
    }
    public fun liquidity_pool_exists(p0: object::Object<fungible_asset::Metadata>, p1: object::Object<fungible_asset::Metadata>, p2: u8): bool {
        let _v0;
        if (utils::is_sorted(p0, p1)) _v0 = liquidity_pool_address(p0, p1, p2) else _v0 = liquidity_pool_address(p1, p0, p2);
        object::object_exists<LiquidityPoolV3>(_v0)
    }
    public fun remove_liquidity(p0: &signer, p1: object::Object<position_v3::Info>, p2: u128): (option::Option<fungible_asset::FungibleAsset>, option::Option<fungible_asset::FungibleAsset>) {
        let _v0 = error::unavailable(11111111);
        abort _v0
    }
    friend fun remove_liquidity_v2(p0: &signer, p1: object::Object<position_v3::Info>, p2: u128): (option::Option<fungible_asset::FungibleAsset>, option::Option<fungible_asset::FungibleAsset>)
        acquires LiquidityPoolConfigsV3, LiquidityPoolV3
    {
        let _v0;
        let _v1;
        let _v2;
        let _v3 = signer::address_of(p0);
        assert!(object::is_owner<position_v3::Info>(p1, _v3), 100008);
        check_protocol_pause();
        let (_v4,_v5) = position_v3::get_tick(p1);
        let _v6 = _v5;
        let _v7 = _v4;
        let (_v8,_v9,_v10) = position_v3::get_pool_info(p1);
        let _v11 = _v10;
        let _v12 = _v9;
        let _v13 = _v8;
        let _v14 = liquidity_pool_address(_v13, _v12, _v11);
        let _v15 = object::object_address<position_v3::Info>(&p1);
        let _v16 = position_blacklist_v2::does_position_blocked(_v14, _v15);
        if (position_v3::get_liquidity(p1) == p2) {
            if (!_v16) {
                _v2 = signer::address_of(p0);
                claim_rewards_after_destory_position(p0, p1, _v2);
                claim_fees_after_destory_position(p0, p1, _v2)
            }};
        let _v17 = liquidity_pool_address(_v13, _v12, _v11);
        let _v18 = borrow_global_mut<LiquidityPoolV3>(_v17);
        _v2 = liquidity_pool_address(_v13, _v12, _v11);
        let _v19 = _v18;
        let _v20 = _v7;
        let _v21 = rewarder::get_emissions_rate_list(&_v19.rewarder_manager);
        let _v22 = get_tick(&_v19.tick_info, _v20);
        let _v23 = tick::get_emissions_per_liquidity_outside(&_v22);
        let _v24 = 0x1::vector::length<u64>(&_v21);
        let _v25 = 0x1::vector::length<u128>(&_v23);
        if (_v24 != _v25) {
            let _v26 = get_tick_mut(&mut _v19.tick_info, _v20);
            let _v27 = 0x1::vector::length<u64>(&_v21);
            tick::padding_emissions_list(_v26, _v27)
        };
        let _v28 = _v18;
        let _v29 = _v6;
        let _v30 = rewarder::get_emissions_rate_list(&_v28.rewarder_manager);
        let _v31 = get_tick(&_v28.tick_info, _v29);
        let _v32 = tick::get_emissions_per_liquidity_outside(&_v31);
        let _v33 = 0x1::vector::length<u64>(&_v30);
        let _v34 = 0x1::vector::length<u128>(&_v32);
        if (_v33 != _v34) {
            let _v35 = get_tick_mut(&mut _v28.tick_info, _v29);
            let _v36 = 0x1::vector::length<u64>(&_v30);
            tick::padding_emissions_list(_v35, _v36)
        };
        let _v37 = liquidity_pool_address(_v13, _v12, _v11);
        let _v38 = freeze(_v18);
        let _v39 = *&_v38.sqrt_price;
        let _v40 = *&_v38.liquidity;
        let _v41 = *&_v38.tick;
        let _v42 = *&_v38.observation_index;
        let _v43 = *&_v38.observation_cardinality;
        let _v44 = *&_v38.observation_cardinality_next;
        let _v45 = *&_v38.fee_rate;
        let _v46 = *&_v38.fee_growth_global_a;
        let _v47 = *&_v38.fee_growth_global_b;
        let _v48 = *&_v38.tick_spacing;
        let _v49 = fungible_asset::balance<fungible_asset::FungibleStore>(*&_v38.token_a_liquidity);
        let _v50 = fungible_asset::balance<fungible_asset::FungibleStore>(*&_v38.token_b_liquidity);
        event::emit<PoolSnapshotV2>(PoolSnapshotV2{pool_id: _v37, sqrt_price: _v39, liquidity: _v40, tick: _v41, observation_index: _v42, observation_cardinality: _v43, observation_cardinality_next: _v44, fee_rate: _v45, fee_rate_denominatore: 1000000, fee_growth_global_a: _v46, fee_growth_global_b: _v47, tick_spacing: _v48, token_a_reserve: _v49, token_b_reserve: _v50});
        let _v51 = _v18;
        let _v52 = timestamp::now_seconds();
        let _v53 = *&_v51.last_update_timestamp;
        let _v54 = _v52 - _v53;
        if (*&_v51.liquidity != 0u128) {
            let _v55 = (_v54 as u128) << 64u8;
            let _v56 = *&_v51.liquidity;
            _v1 = _v55 / _v56
        } else _v1 = 0u128;
        _v38 = freeze(_v51);
        let _v57 = *&_v38.tick;
        let _v58 = position_blacklist_v2::blocked_out_liquidity_amount(_v2, _v57);
        _v58 = *&_v38.liquidity - _v58;
        if (_v58 != 0u128) _v0 = ((_v54 as u128) << 64u8) / _v58 else _v0 = 0u128;
        let _v59 = *&_v51.seconds_per_liquidity_oracle + _v1;
        let _v60 = &mut _v51.seconds_per_liquidity_oracle;
        *_v60 = _v59;
        let _v61 = *&_v51.seconds_per_liquidity_incentive + _v0;
        let _v62 = &mut _v51.seconds_per_liquidity_incentive;
        *_v62 = _v61;
        let _v63 = &mut _v51.last_update_timestamp;
        *_v63 = _v52;
        rewarder::flash(&mut _v51.rewarder_manager, _v58);
        let _v64 = rewarder::get_emissions_per_liquidity_list(&_v18.rewarder_manager);
        let _v65 = &mut _v18.tick_info;
        let _v66 = *&_v18.fee_growth_global_a;
        let _v67 = *&_v18.fee_growth_global_b;
        let _v68 = *&_v18.seconds_per_liquidity_oracle;
        let _v69 = *&_v18.seconds_per_liquidity_incentive;
        let _v70 = *&_v18.tick;
        let _v71 = update_tick(_v65, _v2, _v7, _v66, _v67, _v68, _v69, _v64, false, p2, _v70, false);
        let _v72 = &mut _v18.tick_info;
        let _v73 = *&_v18.fee_growth_global_a;
        let _v74 = *&_v18.fee_growth_global_b;
        let _v75 = *&_v18.seconds_per_liquidity_oracle;
        let _v76 = *&_v18.seconds_per_liquidity_incentive;
        let _v77 = *&_v18.tick;
        let _v78 = update_tick(_v72, _v2, _v6, _v73, _v74, _v75, _v76, _v64, false, p2, _v77, true);
        if (_v71) {
            let _v79 = &mut _v18.tick_map;
            let _v80 = *&_v18.tick_spacing;
            tick_bitmap::flip_tick(_v79, _v7, _v80)
        };
        if (_v78) {
            let _v81 = &mut _v18.tick_map;
            let _v82 = *&_v18.tick_spacing;
            tick_bitmap::flip_tick(_v81, _v6, _v82)
        };
        let _v83 = get_tick(&_v18.tick_info, _v7);
        let _v84 = get_tick(&_v18.tick_info, _v6);
        let _v85 = *&_v18.tick;
        _v64 = tick::get_emissions_per_liquidity_incentive_inside(_v83, _v84, _v7, _v6, _v85, _v64);
        let _v86 = &mut _v18.rewarder_manager;
        let _v87 = position_v3::get_position_rewards(p0, p1);
        let _v88 = position_v3::get_liquidity(p1);
        let _v89 = rewarder::refresh_position_rewarder(_v86, _v87, _v64, _v88);
        position_v3::update_rewards(p1, _v89);
        let _v90 = get_tick(&_v18.tick_info, _v7);
        let _v91 = get_tick(&_v18.tick_info, _v6);
        let _v92 = *&_v18.tick;
        let _v93 = *&_v18.fee_growth_global_a;
        let _v94 = *&_v18.fee_growth_global_b;
        let (_v95,_v96) = tick::get_fee_growth_inside(_v90, _v91, _v7, _v6, _v92, _v93, _v94);
        let (_v97,_v98,_v99) = position_v3::remove_liquidity_v2(p1, p2, _v95, _v96, _v16);
        let _v100 = _v99;
        let (_v101,_v102,_v103,_v104,_v105) = dividen_from_pool(_v18, _v7, _v6, p2);
        let _v106 = &_v18.lp_token_refs;
        let _v107 = object::address_to_object<fungible_asset::Metadata>(liquidity_pool_address(_v13, _v12, _v11));
        let _v108 = object::object_address<position_v3::Info>(&p1);
        lp::burn_from(_v106, _v107, _v101, _v108);
        if (_v100) {
            let _v109 = &_v18.lp_token_refs;
            let _v110 = object::address_to_object<fungible_asset::Metadata>(liquidity_pool_address(_v13, _v12, _v11));
            let _v111 = object::object_address<position_v3::Info>(&p1);
            lp::destroy(_v109, _v110, _v111);
            let _v112 = liquidity_pool_address(_v13, _v12, _v11);
            if (_v16) position_blacklist_v2::remove_blocked_position(signer::address_of(p0), _v112, _v15)
        };
        if (_v71) clear_tick(&mut _v18.tick_info, _v7);
        if (_v78) clear_tick(&mut _v18.tick_info, _v6);
        let _v113 = liquidity_pool_address(_v13, _v12, _v11);
        let _v114 = object::object_address<position_v3::Info>(&p1);
        let _v115 = fungible_asset::balance<fungible_asset::FungibleStore>(*&_v18.token_a_liquidity);
        let _v116 = fungible_asset::balance<fungible_asset::FungibleStore>(*&_v18.token_b_liquidity);
        let _v117 = *&_v18.tick;
        let _v118 = *&_v18.sqrt_price;
        let _v119 = *&_v18.liquidity;
        event::emit<RemoveLiquidityEventV3>(RemoveLiquidityEventV3{pool_id: _v113, object_id: _v114, token_a: _v13, token_b: _v12, fee_tier: _v11, is_delete: _v100, burned_lp_amount: _v98, previous_liquidity_amount: _v97, amount_a: _v102, amount_b: _v103, pool_reserve_a: _v115, pool_reserve_b: _v116, current_tick: _v117, sqrt_price: _v118, active_liquidity: _v119});
        let _v120 = liquidity_pool_address(_v13, _v12, _v11);
        _v38 = freeze(_v18);
        let _v121 = *&_v38.sqrt_price;
        let _v122 = *&_v38.liquidity;
        let _v123 = *&_v38.tick;
        let _v124 = *&_v38.observation_index;
        let _v125 = *&_v38.observation_cardinality;
        let _v126 = *&_v38.observation_cardinality_next;
        let _v127 = *&_v38.fee_rate;
        let _v128 = *&_v38.fee_growth_global_a;
        let _v129 = *&_v38.fee_growth_global_b;
        let _v130 = *&_v38.tick_spacing;
        let _v131 = fungible_asset::balance<fungible_asset::FungibleStore>(*&_v38.token_a_liquidity);
        let _v132 = fungible_asset::balance<fungible_asset::FungibleStore>(*&_v38.token_b_liquidity);
        event::emit<PoolSnapshotV2>(PoolSnapshotV2{pool_id: _v120, sqrt_price: _v121, liquidity: _v122, tick: _v123, observation_index: _v124, observation_cardinality: _v125, observation_cardinality_next: _v126, fee_rate: _v127, fee_rate_denominatore: 1000000, fee_growth_global_a: _v128, fee_growth_global_b: _v129, tick_spacing: _v130, token_a_reserve: _v131, token_b_reserve: _v132});
        (_v104, _v105)
    }
    fun claim_rewards_after_destory_position(p0: &signer, p1: object::Object<position_v3::Info>, p2: address)
        acquires LiquidityPoolV3
    {
        let _v0;
        let _v1;
        let _v2 = p1;
        let (_v3,_v4) = position_v3::get_tick(_v2);
        let _v5 = _v4;
        let _v6 = _v3;
        let (_v7,_v8,_v9) = position_v3::get_pool_info(_v2);
        let _v10 = _v9;
        let _v11 = _v8;
        let _v12 = _v7;
        let _v13 = liquidity_pool_address(_v12, _v11, _v10);
        let _v14 = borrow_global_mut<LiquidityPoolV3>(_v13);
        let _v15 = liquidity_pool_address(_v12, _v11, _v10);
        let _v16 = liquidity_pool_address(_v12, _v11, _v10);
        let _v17 = freeze(_v14);
        let _v18 = *&_v17.sqrt_price;
        let _v19 = *&_v17.liquidity;
        let _v20 = *&_v17.tick;
        let _v21 = *&_v17.observation_index;
        let _v22 = *&_v17.observation_cardinality;
        let _v23 = *&_v17.observation_cardinality_next;
        let _v24 = *&_v17.fee_rate;
        let _v25 = *&_v17.fee_growth_global_a;
        let _v26 = *&_v17.fee_growth_global_b;
        let _v27 = *&_v17.tick_spacing;
        let _v28 = fungible_asset::balance<fungible_asset::FungibleStore>(*&_v17.token_a_liquidity);
        let _v29 = fungible_asset::balance<fungible_asset::FungibleStore>(*&_v17.token_b_liquidity);
        event::emit<PoolSnapshotV2>(PoolSnapshotV2{pool_id: _v16, sqrt_price: _v18, liquidity: _v19, tick: _v20, observation_index: _v21, observation_cardinality: _v22, observation_cardinality_next: _v23, fee_rate: _v24, fee_rate_denominatore: 1000000, fee_growth_global_a: _v25, fee_growth_global_b: _v26, tick_spacing: _v27, token_a_reserve: _v28, token_b_reserve: _v29});
        let _v30 = _v14;
        let _v31 = timestamp::now_seconds();
        let _v32 = *&_v30.last_update_timestamp;
        let _v33 = _v31 - _v32;
        if (*&_v30.liquidity != 0u128) {
            let _v34 = (_v33 as u128) << 64u8;
            let _v35 = *&_v30.liquidity;
            _v1 = _v34 / _v35
        } else _v1 = 0u128;
        _v17 = freeze(_v30);
        let _v36 = *&_v17.tick;
        let _v37 = position_blacklist_v2::blocked_out_liquidity_amount(_v15, _v36);
        _v37 = *&_v17.liquidity - _v37;
        if (_v37 != 0u128) _v0 = ((_v33 as u128) << 64u8) / _v37 else _v0 = 0u128;
        let _v38 = *&_v30.seconds_per_liquidity_oracle + _v1;
        let _v39 = &mut _v30.seconds_per_liquidity_oracle;
        *_v39 = _v38;
        let _v40 = *&_v30.seconds_per_liquidity_incentive + _v0;
        let _v41 = &mut _v30.seconds_per_liquidity_incentive;
        *_v41 = _v40;
        let _v42 = &mut _v30.last_update_timestamp;
        *_v42 = _v31;
        rewarder::flash(&mut _v30.rewarder_manager, _v37);
        let _v43 = position_v3::get_position_rewards_v2(_v2);
        let _v44 = _v14;
        let _v45 = _v6;
        let _v46 = rewarder::get_emissions_rate_list(&_v44.rewarder_manager);
        let _v47 = get_tick(&_v44.tick_info, _v45);
        let _v48 = tick::get_emissions_per_liquidity_outside(&_v47);
        let _v49 = 0x1::vector::length<u64>(&_v46);
        let _v50 = 0x1::vector::length<u128>(&_v48);
        if (_v49 != _v50) {
            let _v51 = get_tick_mut(&mut _v44.tick_info, _v45);
            let _v52 = 0x1::vector::length<u64>(&_v46);
            tick::padding_emissions_list(_v51, _v52)
        };
        let _v53 = _v14;
        let _v54 = _v5;
        let _v55 = rewarder::get_emissions_rate_list(&_v53.rewarder_manager);
        let _v56 = get_tick(&_v53.tick_info, _v54);
        let _v57 = tick::get_emissions_per_liquidity_outside(&_v56);
        let _v58 = 0x1::vector::length<u64>(&_v55);
        let _v59 = 0x1::vector::length<u128>(&_v57);
        if (_v58 != _v59) {
            let _v60 = get_tick_mut(&mut _v53.tick_info, _v54);
            let _v61 = 0x1::vector::length<u64>(&_v55);
            tick::padding_emissions_list(_v60, _v61)
        };
        let _v62 = rewarder::get_emissions_per_liquidity_list(&_v14.rewarder_manager);
        let _v63 = get_tick(&_v14.tick_info, _v6);
        let _v64 = get_tick(&_v14.tick_info, _v5);
        let _v65 = *&_v14.tick;
        _v62 = tick::get_emissions_per_liquidity_incentive_inside(_v63, _v64, _v6, _v5, _v65, _v62);
        let _v66 = lp::get_signer(&_v14.lp_token_refs);
        p0 = &_v66;
        let _v67 = object::object_address<position_v3::Info>(&_v2);
        let _v68 = &mut _v14.rewarder_manager;
        let _v69 = *&_v14.liquidity;
        let _v70 = position_v3::get_liquidity(_v2);
        let (_v71,_v72) = rewarder::claim_rewards(p0, p2, _v67, _v68, _v43, _v62, _v69, _v70);
        position_v3::update_rewards(_v2, _v72);
        let _v73 = liquidity_pool_address(_v12, _v11, _v10);
        _v17 = freeze(_v14);
        let _v74 = *&_v17.sqrt_price;
        let _v75 = *&_v17.liquidity;
        let _v76 = *&_v17.tick;
        let _v77 = *&_v17.observation_index;
        let _v78 = *&_v17.observation_cardinality;
        let _v79 = *&_v17.observation_cardinality_next;
        let _v80 = *&_v17.fee_rate;
        let _v81 = *&_v17.fee_growth_global_a;
        let _v82 = *&_v17.fee_growth_global_b;
        let _v83 = *&_v17.tick_spacing;
        let _v84 = fungible_asset::balance<fungible_asset::FungibleStore>(*&_v17.token_a_liquidity);
        let _v85 = fungible_asset::balance<fungible_asset::FungibleStore>(*&_v17.token_b_liquidity);
        event::emit<PoolSnapshotV2>(PoolSnapshotV2{pool_id: _v73, sqrt_price: _v74, liquidity: _v75, tick: _v76, observation_index: _v77, observation_cardinality: _v78, observation_cardinality_next: _v79, fee_rate: _v80, fee_rate_denominatore: 1000000, fee_growth_global_a: _v81, fee_growth_global_b: _v82, tick_spacing: _v83, token_a_reserve: _v84, token_b_reserve: _v85});
        let _v86 = _v71;
        let _v87 = 0x1::vector::length<fungible_asset::FungibleAsset>(&_v86);
        while (_v87 != 0) {
            _v87 = _v87 - 1;
            let _v88 = 0x1::vector::pop_back<fungible_asset::FungibleAsset>(&mut _v86);
            let _v89 = fungible_asset::metadata_from_asset(&_v88);
            dispatchable_fungible_asset::deposit<fungible_asset::FungibleStore>(primary_fungible_store::ensure_primary_store_exists<fungible_asset::Metadata>(p2, _v89), _v88);
            continue
        };
        0x1::vector::destroy_empty<fungible_asset::FungibleAsset>(_v86);
    }
    fun claim_fees_after_destory_position(p0: &signer, p1: object::Object<position_v3::Info>, p2: address)
        acquires LiquidityPoolV3
    {
        let _v0;
        let _v1;
        let _v2 = p2;
        let _v3 = p1;
        let (_v4,_v5) = position_v3::get_tick(_v3);
        let _v6 = _v5;
        let _v7 = _v4;
        let (_v8,_v9,_v10) = position_v3::get_pool_info(_v3);
        let _v11 = _v10;
        let _v12 = _v9;
        let _v13 = _v8;
        let _v14 = liquidity_pool_address(_v13, _v12, _v11);
        let _v15 = object::object_address<position_v3::Info>(&_v3);
        if (position_blacklist_v2::does_position_blocked(_v14, _v15)) abort 100016;
        let _v16 = liquidity_pool_address(_v13, _v12, _v11);
        let _v17 = borrow_global_mut<LiquidityPoolV3>(_v16);
        let _v18 = liquidity_pool_address(_v13, _v12, _v11);
        let _v19 = liquidity_pool_address(_v13, _v12, _v11);
        let _v20 = freeze(_v17);
        let _v21 = *&_v20.sqrt_price;
        let _v22 = *&_v20.liquidity;
        let _v23 = *&_v20.tick;
        let _v24 = *&_v20.observation_index;
        let _v25 = *&_v20.observation_cardinality;
        let _v26 = *&_v20.observation_cardinality_next;
        let _v27 = *&_v20.fee_rate;
        let _v28 = *&_v20.fee_growth_global_a;
        let _v29 = *&_v20.fee_growth_global_b;
        let _v30 = *&_v20.tick_spacing;
        let _v31 = fungible_asset::balance<fungible_asset::FungibleStore>(*&_v20.token_a_liquidity);
        let _v32 = fungible_asset::balance<fungible_asset::FungibleStore>(*&_v20.token_b_liquidity);
        event::emit<PoolSnapshotV2>(PoolSnapshotV2{pool_id: _v19, sqrt_price: _v21, liquidity: _v22, tick: _v23, observation_index: _v24, observation_cardinality: _v25, observation_cardinality_next: _v26, fee_rate: _v27, fee_rate_denominatore: 1000000, fee_growth_global_a: _v28, fee_growth_global_b: _v29, tick_spacing: _v30, token_a_reserve: _v31, token_b_reserve: _v32});
        let _v33 = _v17;
        let _v34 = timestamp::now_seconds();
        let _v35 = *&_v33.last_update_timestamp;
        let _v36 = _v34 - _v35;
        if (*&_v33.liquidity != 0u128) {
            let _v37 = (_v36 as u128) << 64u8;
            let _v38 = *&_v33.liquidity;
            _v1 = _v37 / _v38
        } else _v1 = 0u128;
        _v20 = freeze(_v33);
        let _v39 = *&_v20.tick;
        let _v40 = position_blacklist_v2::blocked_out_liquidity_amount(_v18, _v39);
        _v40 = *&_v20.liquidity - _v40;
        if (_v40 != 0u128) _v0 = ((_v36 as u128) << 64u8) / _v40 else _v0 = 0u128;
        let _v41 = *&_v33.seconds_per_liquidity_oracle + _v1;
        let _v42 = &mut _v33.seconds_per_liquidity_oracle;
        *_v42 = _v41;
        let _v43 = *&_v33.seconds_per_liquidity_incentive + _v0;
        let _v44 = &mut _v33.seconds_per_liquidity_incentive;
        *_v44 = _v43;
        let _v45 = &mut _v33.last_update_timestamp;
        *_v45 = _v34;
        rewarder::flash(&mut _v33.rewarder_manager, _v40);
        let _v46 = rewarder::get_emissions_per_liquidity_list(&_v17.rewarder_manager);
        let _v47 = &mut _v17.tick_info;
        let _v48 = *&_v17.fee_growth_global_a;
        let _v49 = *&_v17.fee_growth_global_b;
        let _v50 = *&_v17.seconds_per_liquidity_oracle;
        let _v51 = *&_v17.seconds_per_liquidity_incentive;
        let _v52 = *&_v17.tick;
        let _v53 = update_tick(_v47, _v18, _v7, _v48, _v49, _v50, _v51, _v46, true, 0u128, _v52, false);
        let _v54 = &mut _v17.tick_info;
        let _v55 = *&_v17.fee_growth_global_a;
        let _v56 = *&_v17.fee_growth_global_b;
        let _v57 = *&_v17.seconds_per_liquidity_oracle;
        let _v58 = *&_v17.seconds_per_liquidity_incentive;
        let _v59 = *&_v17.tick;
        let _v60 = update_tick(_v54, _v18, _v6, _v55, _v56, _v57, _v58, _v46, true, 0u128, _v59, true);
        if (_v53) {
            let _v61 = &mut _v17.tick_map;
            let _v62 = *&_v17.tick_spacing;
            tick_bitmap::flip_tick(_v61, _v7, _v62)
        };
        if (_v60) {
            let _v63 = &mut _v17.tick_map;
            let _v64 = *&_v17.tick_spacing;
            tick_bitmap::flip_tick(_v63, _v6, _v64)
        };
        let _v65 = get_tick(&_v17.tick_info, _v7);
        let _v66 = get_tick(&_v17.tick_info, _v6);
        let _v67 = *&_v17.tick;
        let _v68 = *&_v17.fee_growth_global_a;
        let _v69 = *&_v17.fee_growth_global_b;
        let (_v70,_v71) = tick::get_fee_growth_inside(_v65, _v66, _v7, _v6, _v67, _v68, _v69);
        let (_v72,_v73) = position_v3::claim_fees(_v3, _v70, _v71);
        let _v74 = package_manager::get_signer();
        p0 = &_v74;
        let _v75 = *&_v17.token_a_liquidity;
        let _v76 = dispatchable_fungible_asset::withdraw<fungible_asset::FungibleStore>(p0, _v75, _v72);
        let _v77 = *&_v17.token_b_liquidity;
        let _v78 = dispatchable_fungible_asset::withdraw<fungible_asset::FungibleStore>(p0, _v77, _v73);
        let _v79 = liquidity_pool_address(_v13, _v12, _v11);
        _v20 = freeze(_v17);
        let _v80 = *&_v20.sqrt_price;
        let _v81 = *&_v20.liquidity;
        let _v82 = *&_v20.tick;
        let _v83 = *&_v20.observation_index;
        let _v84 = *&_v20.observation_cardinality;
        let _v85 = *&_v20.observation_cardinality_next;
        let _v86 = *&_v20.fee_rate;
        let _v87 = *&_v20.fee_growth_global_a;
        let _v88 = *&_v20.fee_growth_global_b;
        let _v89 = *&_v20.tick_spacing;
        let _v90 = fungible_asset::balance<fungible_asset::FungibleStore>(*&_v20.token_a_liquidity);
        let _v91 = fungible_asset::balance<fungible_asset::FungibleStore>(*&_v20.token_b_liquidity);
        event::emit<PoolSnapshotV2>(PoolSnapshotV2{pool_id: _v79, sqrt_price: _v80, liquidity: _v81, tick: _v82, observation_index: _v83, observation_cardinality: _v84, observation_cardinality_next: _v85, fee_rate: _v86, fee_rate_denominatore: 1000000, fee_growth_global_a: _v87, fee_growth_global_b: _v88, tick_spacing: _v89, token_a_reserve: _v90, token_b_reserve: _v91});
        let _v92 = liquidity_pool(_v13, _v12, _v11);
        let _v93 = fungible_asset::amount(&_v76);
        let _v94 = fungible_asset::balance<fungible_asset::FungibleStore>(*&_v17.token_a_liquidity);
        let _v95 = fungible_asset::balance<fungible_asset::FungibleStore>(*&_v17.token_b_liquidity);
        event::emit<ClaimFeesEventV2>(ClaimFeesEventV2{pool: _v92, lp_object: _v3, token: _v13, amount: _v93, owner: _v2, token_a_liquidity_after_claim: _v94, token_b_liquidity_after_claim: _v95});
        let _v96 = liquidity_pool(_v13, _v12, _v11);
        let _v97 = fungible_asset::amount(&_v78);
        let _v98 = fungible_asset::balance<fungible_asset::FungibleStore>(*&_v17.token_a_liquidity);
        let _v99 = fungible_asset::balance<fungible_asset::FungibleStore>(*&_v17.token_b_liquidity);
        event::emit<ClaimFeesEventV2>(ClaimFeesEventV2{pool: _v96, lp_object: _v3, token: _v12, amount: _v97, owner: _v2, token_a_liquidity_after_claim: _v98, token_b_liquidity_after_claim: _v99});
        primary_fungible_store::deposit(p2, _v76);
        primary_fungible_store::deposit(p2, _v78);
    }
    fun dividen_from_pool(p0: &mut LiquidityPoolV3, p1: i32::I32, p2: i32::I32, p3: u128): (u128, u64, u64, option::Option<fungible_asset::FungibleAsset>, option::Option<fungible_asset::FungibleAsset>) {
        let _v0 = option::none<fungible_asset::FungibleAsset>();
        let _v1 = option::none<fungible_asset::FungibleAsset>();
        let _v2 = 0;
        let _v3 = 0;
        if (p3 != 0u128) {
            let _v4;
            if (i32::lt(*&p0.tick, p1)) {
                let _v5 = tick_math::get_sqrt_price_at_tick(p1);
                let _v6 = tick_math::get_sqrt_price_at_tick(p2);
                _v2 = swap_math::get_delta_a(_v5, _v6, p3, false);
                let _v7 = package_manager::get_signer();
                let _v8 = &_v7;
                let _v9 = *&p0.token_a_liquidity;
                _v4 = dispatchable_fungible_asset::withdraw<fungible_asset::FungibleStore>(_v8, _v9, _v2);
                option::fill<fungible_asset::FungibleAsset>(&mut _v0, _v4)
            } else if (i32::lt(*&p0.tick, p2)) {
                let _v10 = *&p0.sqrt_price;
                let _v11 = tick_math::get_sqrt_price_at_tick(p2);
                _v2 = swap_math::get_delta_a(_v10, _v11, p3, false);
                let _v12 = package_manager::get_signer();
                let _v13 = &_v12;
                let _v14 = *&p0.token_a_liquidity;
                _v4 = dispatchable_fungible_asset::withdraw<fungible_asset::FungibleStore>(_v13, _v14, _v2);
                option::fill<fungible_asset::FungibleAsset>(&mut _v0, _v4);
                let _v15 = tick_math::get_sqrt_price_at_tick(p1);
                let _v16 = *&p0.sqrt_price;
                _v3 = swap_math::get_delta_b(_v15, _v16, p3, false);
                let _v17 = *&p0.token_b_liquidity;
                _v4 = dispatchable_fungible_asset::withdraw<fungible_asset::FungibleStore>(_v13, _v17, _v3);
                option::fill<fungible_asset::FungibleAsset>(&mut _v1, _v4);
                let _v18 = liquidity_math::sub_delta(*&p0.liquidity, p3);
                let _v19 = &mut p0.liquidity;
                *_v19 = _v18
            } else {
                let _v20 = tick_math::get_sqrt_price_at_tick(p1);
                let _v21 = tick_math::get_sqrt_price_at_tick(p2);
                _v3 = swap_math::get_delta_b(_v20, _v21, p3, false);
                let _v22 = package_manager::get_signer();
                let _v23 = &_v22;
                let _v24 = *&p0.token_b_liquidity;
                _v4 = dispatchable_fungible_asset::withdraw<fungible_asset::FungibleStore>(_v23, _v24, _v3);
                option::fill<fungible_asset::FungibleAsset>(&mut _v1, _v4)
            }
        };
        (p3, _v2, _v3, _v0, _v1)
    }
    fun clear_tick(p0: &mut smart_table::SmartTable<i32::I32, tick::TickInfo>, p1: i32::I32) {
        if (smart_table::contains<i32::I32, tick::TickInfo>(freeze(p0), p1)) {
            let _v0 = smart_table::remove<i32::I32, tick::TickInfo>(p0, p1);
            return ()
        };
    }
    entry fun add_blocked_position_to_new_blacklist(p0: &signer, p1: address, p2: object::Object<position_v3::Info>)
        acquires LiquidityPoolConfigsV3, LiquidityPoolV3
    {
        let _v0;
        let _v1;
        check_protocol_pause();
        let _v2 = string::utf8(vector[97u8, 100u8, 100u8, 95u8, 98u8, 108u8, 111u8, 99u8, 107u8, 101u8, 100u8, 95u8, 112u8, 111u8, 115u8, 105u8, 116u8, 105u8, 111u8, 110u8, 95u8, 116u8, 111u8, 95u8, 110u8, 101u8, 119u8, 95u8, 98u8, 108u8, 97u8, 99u8, 107u8, 108u8, 105u8, 115u8, 116u8]);
        package_manager::assert_admin(p0, _v2);
        let (_v3,_v4,_v5) = position_v3::get_pool_info(p2);
        let _v6 = liquidity_pool_address(_v3, _v4, _v5);
        let _v7 = object::object_address<position_v3::Info>(&p2);
        let (_v8,_v9) = position_v3::get_tick(p2);
        let _v10 = _v9;
        let _v11 = _v8;
        let (_v12,_v13,_v14) = position_v3::get_pool_info(p2);
        let _v15 = _v14;
        let _v16 = _v13;
        let _v17 = _v12;
        let _v18 = liquidity_pool_address(_v17, _v16, _v15);
        let _v19 = borrow_global_mut<LiquidityPoolV3>(_v18);
        let _v20 = liquidity_pool_address(_v17, _v16, _v15);
        let _v21 = freeze(_v19);
        let _v22 = *&_v21.sqrt_price;
        let _v23 = *&_v21.liquidity;
        let _v24 = *&_v21.tick;
        let _v25 = *&_v21.observation_index;
        let _v26 = *&_v21.observation_cardinality;
        let _v27 = *&_v21.observation_cardinality_next;
        let _v28 = *&_v21.fee_rate;
        let _v29 = *&_v21.fee_growth_global_a;
        let _v30 = *&_v21.fee_growth_global_b;
        let _v31 = *&_v21.tick_spacing;
        let _v32 = fungible_asset::balance<fungible_asset::FungibleStore>(*&_v21.token_a_liquidity);
        let _v33 = fungible_asset::balance<fungible_asset::FungibleStore>(*&_v21.token_b_liquidity);
        event::emit<PoolSnapshotV2>(PoolSnapshotV2{pool_id: _v20, sqrt_price: _v22, liquidity: _v23, tick: _v24, observation_index: _v25, observation_cardinality: _v26, observation_cardinality_next: _v27, fee_rate: _v28, fee_rate_denominatore: 1000000, fee_growth_global_a: _v29, fee_growth_global_b: _v30, tick_spacing: _v31, token_a_reserve: _v32, token_b_reserve: _v33});
        let _v34 = _v19;
        let _v35 = timestamp::now_seconds();
        let _v36 = *&_v34.last_update_timestamp;
        let _v37 = _v35 - _v36;
        if (*&_v34.liquidity != 0u128) {
            let _v38 = (_v37 as u128) << 64u8;
            let _v39 = *&_v34.liquidity;
            _v1 = _v38 / _v39
        } else _v1 = 0u128;
        _v21 = freeze(_v34);
        let _v40 = *&_v21.tick;
        let _v41 = position_blacklist_v2::blocked_out_liquidity_amount(_v6, _v40);
        _v41 = *&_v21.liquidity - _v41;
        if (_v41 != 0u128) _v0 = ((_v37 as u128) << 64u8) / _v41 else _v0 = 0u128;
        let _v42 = *&_v34.seconds_per_liquidity_oracle + _v1;
        let _v43 = &mut _v34.seconds_per_liquidity_oracle;
        *_v43 = _v42;
        let _v44 = *&_v34.seconds_per_liquidity_incentive + _v0;
        let _v45 = &mut _v34.seconds_per_liquidity_incentive;
        *_v45 = _v44;
        let _v46 = &mut _v34.last_update_timestamp;
        *_v46 = _v35;
        rewarder::flash(&mut _v34.rewarder_manager, _v41);
        let _v47 = position_v3::get_position_rewards_v2(p2);
        let _v48 = _v19;
        let _v49 = _v11;
        let _v50 = rewarder::get_emissions_rate_list(&_v48.rewarder_manager);
        let _v51 = get_tick(&_v48.tick_info, _v49);
        let _v52 = tick::get_emissions_per_liquidity_outside(&_v51);
        let _v53 = 0x1::vector::length<u64>(&_v50);
        let _v54 = 0x1::vector::length<u128>(&_v52);
        if (_v53 != _v54) {
            let _v55 = get_tick_mut(&mut _v48.tick_info, _v49);
            let _v56 = 0x1::vector::length<u64>(&_v50);
            tick::padding_emissions_list(_v55, _v56)
        };
        let _v57 = _v19;
        let _v58 = _v10;
        let _v59 = rewarder::get_emissions_rate_list(&_v57.rewarder_manager);
        let _v60 = get_tick(&_v57.tick_info, _v58);
        let _v61 = tick::get_emissions_per_liquidity_outside(&_v60);
        let _v62 = 0x1::vector::length<u64>(&_v59);
        let _v63 = 0x1::vector::length<u128>(&_v61);
        if (_v62 != _v63) {
            let _v64 = get_tick_mut(&mut _v57.tick_info, _v58);
            let _v65 = 0x1::vector::length<u64>(&_v59);
            tick::padding_emissions_list(_v64, _v65)
        };
        let _v66 = rewarder::get_emissions_per_liquidity_list(&_v19.rewarder_manager);
        let _v67 = get_tick(&_v19.tick_info, _v11);
        let _v68 = get_tick(&_v19.tick_info, _v10);
        let _v69 = *&_v19.tick;
        _v66 = tick::get_emissions_per_liquidity_incentive_inside(_v67, _v68, _v11, _v10, _v69, _v66);
        let _v70 = rewarder::refresh_position_rewarder_to_zero(&mut _v19.rewarder_manager, _v47, _v66);
        position_v3::update_rewards(p2, _v70);
        position_blacklist_v2::add_blocked_position_internal(p1, _v6, _v7);
    }
    public fun add_coin_incentive<T0>(p0: &signer, p1: object::Object<LiquidityPoolV3>, p2: u64, p3: u64)
        acquires LiquidityPoolV3
    {
        let _v0 = string::utf8(vector[97u8, 100u8, 100u8, 95u8, 99u8, 111u8, 105u8, 110u8, 95u8, 105u8, 110u8, 99u8, 101u8, 110u8, 116u8, 105u8, 118u8, 101u8]);
        package_manager::assert_admin(p0, _v0);
        let _v1 = object::object_address<LiquidityPoolV3>(&p1);
        let _v2 = borrow_global_mut<LiquidityPoolV3>(_v1);
        let _v3 = coin_wrapper::wrap<T0>(coin::withdraw<T0>(p0, p3));
        let _v4 = &mut _v2.rewarder_manager;
        let _v5 = *&_v2.liquidity;
        rewarder::add_incentive(_v4, _v5, _v3, p2, _v1);
    }
    public fun add_coin_incentive_v2<T0>(p0: &signer, p1: object::Object<LiquidityPoolV3>, p2: u64, p3: u64, p4: u64)
        acquires LiquidityPoolV3, PoolTemporaryStorage
    {
        let _v0;
        let _v1 = p0;
        let _v2 = string::utf8(vector[97u8, 100u8, 100u8, 95u8, 99u8, 111u8, 105u8, 110u8, 95u8, 105u8, 110u8, 99u8, 101u8, 110u8, 116u8, 105u8, 118u8, 101u8, 95u8, 118u8, 50u8]);
        package_manager::assert_admin(_v1, _v2);
        let _v3 = object::object_address<LiquidityPoolV3>(&p1);
        let _v4 = borrow_global_mut<LiquidityPoolV3>(_v3);
        let _v5 = lp::get_signer(&_v4.lp_token_refs);
        let _v6 = option::destroy_some<object::Object<fungible_asset::Metadata>>(coin::paired_metadata<T0>());
        _v1 = &_v5;
        let _v7 = _v6;
        let _v8 = signer::address_of(_v1);
        if (!exists<PoolTemporaryStorage>(_v8)) {
            let _v9 = PoolTemporaryStorage{stores: 0x1::vector::empty<object::Object<fungible_asset::FungibleStore>>()};
            move_to<PoolTemporaryStorage>(_v1, _v9)
        };
        let _v10 = signer::address_of(_v1);
        let _v11 = borrow_global_mut<PoolTemporaryStorage>(_v10);
        let _v12 = &_v11.stores;
        let _v13 = false;
        let _v14 = 0;
        let _v15 = 0;
        let _v16 = 0x1::vector::length<object::Object<fungible_asset::FungibleStore>>(_v12);
        'l0: loop {
            loop {
                if (!(_v15 < _v16)) break 'l0;
                if (fungible_asset::store_metadata<fungible_asset::FungibleStore>(*0x1::vector::borrow<object::Object<fungible_asset::FungibleStore>>(_v12, _v15)) == _v7) break;
                _v15 = _v15 + 1
            };
            _v13 = true;
            _v14 = _v15;
            break
        };
        if (_v13) _v0 = *0x1::vector::borrow<object::Object<fungible_asset::FungibleStore>>(&_v11.stores, _v14) else {
            let _v17 = object::create_object_from_object(_v1);
            let _v18 = fungible_asset::create_store<fungible_asset::Metadata>(&_v17, _v7);
            0x1::vector::push_back<object::Object<fungible_asset::FungibleStore>>(&mut _v11.stores, _v18);
            _v0 = _v18
        };
        let _v19 = coin::withdraw<T0>(p0, p3);
        let _v20 = coin::coin_to_fungible_asset<T0>(coin::extract<T0>(&mut _v19, p4));
        dispatchable_fungible_asset::deposit<fungible_asset::FungibleStore>(_v0, _v20);
        let _v21 = coin::coin_to_fungible_asset<T0>(_v19);
        let _v22 = &mut _v4.rewarder_manager;
        let _v23 = *&_v4.liquidity;
        rewarder::add_incentive(_v22, _v23, _v21, p2, _v3);
    }
    public fun add_incentive_v2(p0: &signer, p1: object::Object<LiquidityPoolV3>, p2: u64, p3: object::Object<fungible_asset::Metadata>, p4: u64, p5: u64)
        acquires LiquidityPoolV3, PoolTemporaryStorage
    {
        let _v0;
        let _v1 = object::object_address<LiquidityPoolV3>(&p1);
        let _v2 = borrow_global_mut<LiquidityPoolV3>(_v1);
        let _v3 = lp::get_signer(&_v2.lp_token_refs);
        let _v4 = &_v3;
        let _v5 = p3;
        let _v6 = signer::address_of(_v4);
        if (!exists<PoolTemporaryStorage>(_v6)) {
            let _v7 = PoolTemporaryStorage{stores: 0x1::vector::empty<object::Object<fungible_asset::FungibleStore>>()};
            move_to<PoolTemporaryStorage>(_v4, _v7)
        };
        let _v8 = signer::address_of(_v4);
        let _v9 = borrow_global_mut<PoolTemporaryStorage>(_v8);
        let _v10 = &_v9.stores;
        let _v11 = false;
        let _v12 = 0;
        let _v13 = 0;
        let _v14 = 0x1::vector::length<object::Object<fungible_asset::FungibleStore>>(_v10);
        'l0: loop {
            loop {
                if (!(_v13 < _v14)) break 'l0;
                if (fungible_asset::store_metadata<fungible_asset::FungibleStore>(*0x1::vector::borrow<object::Object<fungible_asset::FungibleStore>>(_v10, _v13)) == _v5) break;
                _v13 = _v13 + 1
            };
            _v11 = true;
            _v12 = _v13;
            break
        };
        if (_v11) _v0 = *0x1::vector::borrow<object::Object<fungible_asset::FungibleStore>>(&_v9.stores, _v12) else {
            let _v15 = object::create_object_from_object(_v4);
            let _v16 = fungible_asset::create_store<fungible_asset::Metadata>(&_v15, _v5);
            0x1::vector::push_back<object::Object<fungible_asset::FungibleStore>>(&mut _v9.stores, _v16);
            _v0 = _v16
        };
        let _v17 = primary_fungible_store::withdraw<fungible_asset::Metadata>(p0, p3, p4);
        let _v18 = fungible_asset::extract(&mut _v17, p5);
        dispatchable_fungible_asset::deposit<fungible_asset::FungibleStore>(_v0, _v18);
        let _v19 = &mut _v2.rewarder_manager;
        let _v20 = *&_v2.liquidity;
        rewarder::add_incentive(_v19, _v20, _v17, p2, _v1);
    }
    friend fun add_liquidity_v2(p0: &signer, p1: object::Object<position_v3::Info>, p2: u128, p3: fungible_asset::FungibleAsset, p4: fungible_asset::FungibleAsset): (u64, u64, fungible_asset::FungibleAsset, fungible_asset::FungibleAsset)
        acquires LiquidityPoolConfigsV3, LiquidityPoolV3
    {
        let _v0;
        let _v1;
        let _v2 = signer::address_of(p0);
        assert!(object::is_owner<position_v3::Info>(p1, _v2), 100008);
        let (_v3,_v4) = position_v3::get_tick(p1);
        let _v5 = _v4;
        let _v6 = _v3;
        let (_v7,_v8,_v9) = position_v3::get_pool_info(p1);
        let _v10 = _v9;
        let _v11 = _v8;
        let _v12 = _v7;
        let _v13 = liquidity_pool_address(_v12, _v11, _v10);
        let _v14 = borrow_global_mut<LiquidityPoolV3>(_v13);
        let _v15 = liquidity_pool_address(_v12, _v11, _v10);
        check_protocol_pause();
        let _v16 = liquidity_pool_address(_v12, _v11, _v10);
        let _v17 = freeze(_v14);
        let _v18 = *&_v17.sqrt_price;
        let _v19 = *&_v17.liquidity;
        let _v20 = *&_v17.tick;
        let _v21 = *&_v17.observation_index;
        let _v22 = *&_v17.observation_cardinality;
        let _v23 = *&_v17.observation_cardinality_next;
        let _v24 = *&_v17.fee_rate;
        let _v25 = *&_v17.fee_growth_global_a;
        let _v26 = *&_v17.fee_growth_global_b;
        let _v27 = *&_v17.tick_spacing;
        let _v28 = fungible_asset::balance<fungible_asset::FungibleStore>(*&_v17.token_a_liquidity);
        let _v29 = fungible_asset::balance<fungible_asset::FungibleStore>(*&_v17.token_b_liquidity);
        event::emit<PoolSnapshotV2>(PoolSnapshotV2{pool_id: _v16, sqrt_price: _v18, liquidity: _v19, tick: _v20, observation_index: _v21, observation_cardinality: _v22, observation_cardinality_next: _v23, fee_rate: _v24, fee_rate_denominatore: 1000000, fee_growth_global_a: _v25, fee_growth_global_b: _v26, tick_spacing: _v27, token_a_reserve: _v28, token_b_reserve: _v29});
        let _v30 = _v14;
        let _v31 = timestamp::now_seconds();
        let _v32 = *&_v30.last_update_timestamp;
        let _v33 = _v31 - _v32;
        if (*&_v30.liquidity != 0u128) {
            let _v34 = (_v33 as u128) << 64u8;
            let _v35 = *&_v30.liquidity;
            _v1 = _v34 / _v35
        } else _v1 = 0u128;
        _v17 = freeze(_v30);
        let _v36 = *&_v17.tick;
        let _v37 = position_blacklist_v2::blocked_out_liquidity_amount(_v15, _v36);
        _v37 = *&_v17.liquidity - _v37;
        if (_v37 != 0u128) _v0 = ((_v33 as u128) << 64u8) / _v37 else _v0 = 0u128;
        let _v38 = *&_v30.seconds_per_liquidity_oracle + _v1;
        let _v39 = &mut _v30.seconds_per_liquidity_oracle;
        *_v39 = _v38;
        let _v40 = *&_v30.seconds_per_liquidity_incentive + _v0;
        let _v41 = &mut _v30.seconds_per_liquidity_incentive;
        *_v41 = _v40;
        let _v42 = &mut _v30.last_update_timestamp;
        *_v42 = _v31;
        rewarder::flash(&mut _v30.rewarder_manager, _v37);
        let _v43 = rewarder::get_emissions_per_liquidity_list(&_v14.rewarder_manager);
        let _v44 = &mut _v14.tick_info;
        let _v45 = *&_v14.fee_growth_global_a;
        let _v46 = *&_v14.fee_growth_global_b;
        let _v47 = *&_v14.seconds_per_liquidity_oracle;
        let _v48 = *&_v14.seconds_per_liquidity_incentive;
        let _v49 = *&_v14.tick;
        let _v50 = update_tick(_v44, _v15, _v6, _v45, _v46, _v47, _v48, _v43, true, p2, _v49, false);
        let _v51 = &mut _v14.tick_info;
        let _v52 = *&_v14.fee_growth_global_a;
        let _v53 = *&_v14.fee_growth_global_b;
        let _v54 = *&_v14.seconds_per_liquidity_oracle;
        let _v55 = *&_v14.seconds_per_liquidity_incentive;
        let _v56 = *&_v14.tick;
        let _v57 = update_tick(_v51, _v15, _v5, _v52, _v53, _v54, _v55, _v43, true, p2, _v56, true);
        if (_v50) {
            let _v58 = &mut _v14.tick_map;
            let _v59 = *&_v14.tick_spacing;
            tick_bitmap::flip_tick(_v58, _v6, _v59)
        };
        if (_v57) {
            let _v60 = &mut _v14.tick_map;
            let _v61 = *&_v14.tick_spacing;
            tick_bitmap::flip_tick(_v60, _v5, _v61)
        };
        let _v62 = _v14;
        let _v63 = _v6;
        let _v64 = rewarder::get_emissions_rate_list(&_v62.rewarder_manager);
        let _v65 = get_tick(&_v62.tick_info, _v63);
        let _v66 = tick::get_emissions_per_liquidity_outside(&_v65);
        let _v67 = 0x1::vector::length<u64>(&_v64);
        let _v68 = 0x1::vector::length<u128>(&_v66);
        if (_v67 != _v68) {
            let _v69 = get_tick_mut(&mut _v62.tick_info, _v63);
            let _v70 = 0x1::vector::length<u64>(&_v64);
            tick::padding_emissions_list(_v69, _v70)
        };
        let _v71 = _v14;
        let _v72 = _v5;
        let _v73 = rewarder::get_emissions_rate_list(&_v71.rewarder_manager);
        let _v74 = get_tick(&_v71.tick_info, _v72);
        let _v75 = tick::get_emissions_per_liquidity_outside(&_v74);
        let _v76 = 0x1::vector::length<u64>(&_v73);
        let _v77 = 0x1::vector::length<u128>(&_v75);
        if (_v76 != _v77) {
            let _v78 = get_tick_mut(&mut _v71.tick_info, _v72);
            let _v79 = 0x1::vector::length<u64>(&_v73);
            tick::padding_emissions_list(_v78, _v79)
        };
        let _v80 = get_tick(&_v14.tick_info, _v6);
        let _v81 = get_tick(&_v14.tick_info, _v5);
        let _v82 = *&_v14.tick;
        let _v83 = tick::get_emissions_per_liquidity_incentive_inside(_v80, _v81, _v6, _v5, _v82, _v43);
        let _v84 = &mut _v14.rewarder_manager;
        let _v85 = position_v3::get_position_rewards(p0, p1);
        let _v86 = position_v3::get_liquidity(p1);
        let _v87 = rewarder::refresh_position_rewarder(_v84, _v85, _v83, _v86);
        position_v3::update_rewards(p1, _v87);
        let _v88 = get_tick(&_v14.tick_info, _v6);
        let _v89 = get_tick(&_v14.tick_info, _v5);
        let _v90 = *&_v14.tick;
        let _v91 = *&_v14.fee_growth_global_a;
        let _v92 = *&_v14.fee_growth_global_b;
        let (_v93,_v94) = tick::get_fee_growth_inside(_v88, _v89, _v6, _v5, _v90, _v91, _v92);
        let (_v95,_v96,_v97) = position_v3::add_liquidity(p1, p2, _v93, _v94);
        let (_v98,_v99,_v100,_v101,_v102) = merge_into_pool(_v14, _v6, _v5, p2, p3, p4);
        let _v103 = &_v14.lp_token_refs;
        let _v104 = object::address_to_object<fungible_asset::Metadata>(liquidity_pool_address(_v12, _v11, _v10));
        let _v105 = _v100;
        let _v106 = _v99;
        let _v107 = object::object_address<position_v3::Info>(&p1);
        lp::mint_to(_v103, _v104, _v98, _v107);
        let _v108 = liquidity_pool_address(_v12, _v11, _v10);
        _v17 = freeze(_v14);
        let _v109 = *&_v17.sqrt_price;
        let _v110 = *&_v17.liquidity;
        let _v111 = *&_v17.tick;
        let _v112 = *&_v17.observation_index;
        let _v113 = *&_v17.observation_cardinality;
        let _v114 = *&_v17.observation_cardinality_next;
        let _v115 = *&_v17.fee_rate;
        let _v116 = *&_v17.fee_growth_global_a;
        let _v117 = *&_v17.fee_growth_global_b;
        let _v118 = *&_v17.tick_spacing;
        let _v119 = fungible_asset::balance<fungible_asset::FungibleStore>(*&_v17.token_a_liquidity);
        let _v120 = fungible_asset::balance<fungible_asset::FungibleStore>(*&_v17.token_b_liquidity);
        event::emit<PoolSnapshotV2>(PoolSnapshotV2{pool_id: _v108, sqrt_price: _v109, liquidity: _v110, tick: _v111, observation_index: _v112, observation_cardinality: _v113, observation_cardinality_next: _v114, fee_rate: _v115, fee_rate_denominatore: 1000000, fee_growth_global_a: _v116, fee_growth_global_b: _v117, tick_spacing: _v118, token_a_reserve: _v119, token_b_reserve: _v120});
        let _v121 = liquidity_pool_address(_v12, _v11, _v10);
        let _v122 = object::object_address<position_v3::Info>(&p1);
        let _v123 = fungible_asset::balance<fungible_asset::FungibleStore>(*&_v14.token_a_liquidity);
        let _v124 = fungible_asset::balance<fungible_asset::FungibleStore>(*&_v14.token_b_liquidity);
        let _v125 = *&_v14.tick;
        let _v126 = *&_v14.sqrt_price;
        let _v127 = *&_v14.liquidity;
        event::emit<AddLiquidityEventV3>(AddLiquidityEventV3{pool_id: _v121, object_id: _v122, token_a: _v12, token_b: _v11, fee_tier: _v10, is_delete: _v97, added_lp_amount: _v96, previous_liquidity_amount: _v95, amount_a: _v106, amount_b: _v105, pool_reserve_a: _v123, pool_reserve_b: _v124, current_tick: _v125, sqrt_price: _v126, active_liquidity: _v127});
        (_v106, _v105, _v101, _v102)
    }
    fun merge_into_pool(p0: &mut LiquidityPoolV3, p1: i32::I32, p2: i32::I32, p3: u128, p4: fungible_asset::FungibleAsset, p5: fungible_asset::FungibleAsset): (u128, u64, u64, fungible_asset::FungibleAsset, fungible_asset::FungibleAsset) {
        let _v0 = 0;
        let _v1 = 0;
        assert!(p3 != 0u128, 100005);
        if (i32::lt(*&p0.tick, p1)) {
            let _v2 = tick_math::get_sqrt_price_at_tick(p1);
            let _v3 = tick_math::get_sqrt_price_at_tick(p2);
            _v0 = swap_math::get_delta_a(_v2, _v3, p3, true);
            assert!(fungible_asset::amount(&p4) >= _v0, 100006);
            assert!(_v0 != 0, 100015);
            let _v4 = *&p0.token_a_liquidity;
            let _v5 = fungible_asset::extract(&mut p4, _v0);
            dispatchable_fungible_asset::deposit<fungible_asset::FungibleStore>(_v4, _v5)
        } else if (i32::lt(*&p0.tick, p2)) {
            let _v6 = *&p0.sqrt_price;
            let _v7 = tick_math::get_sqrt_price_at_tick(p2);
            _v0 = swap_math::get_delta_a(_v6, _v7, p3, true);
            assert!(fungible_asset::amount(&p4) >= _v0, 100006);
            let _v8 = *&p0.token_a_liquidity;
            let _v9 = fungible_asset::extract(&mut p4, _v0);
            dispatchable_fungible_asset::deposit<fungible_asset::FungibleStore>(_v8, _v9);
            let _v10 = tick_math::get_sqrt_price_at_tick(p1);
            let _v11 = *&p0.sqrt_price;
            _v1 = swap_math::get_delta_b(_v10, _v11, p3, true);
            assert!(fungible_asset::amount(&p5) >= _v1, 100007);
            assert!(_v0 != 0, 100015);
            assert!(_v1 != 0, 100015);
            let _v12 = *&p0.token_b_liquidity;
            let _v13 = fungible_asset::extract(&mut p5, _v1);
            dispatchable_fungible_asset::deposit<fungible_asset::FungibleStore>(_v12, _v13);
            let _v14 = liquidity_math::add_delta(*&p0.liquidity, p3);
            let _v15 = &mut p0.liquidity;
            *_v15 = _v14
        } else {
            let _v16 = tick_math::get_sqrt_price_at_tick(p1);
            let _v17 = tick_math::get_sqrt_price_at_tick(p2);
            _v1 = swap_math::get_delta_b(_v16, _v17, p3, true);
            if (fungible_asset::amount(&p5) >= _v1) if (_v1 != 0) {
                let _v18 = *&p0.token_b_liquidity;
                let _v19 = fungible_asset::extract(&mut p5, _v1);
                dispatchable_fungible_asset::deposit<fungible_asset::FungibleStore>(_v18, _v19)
            } else abort 100015 else abort 100007
        };
        (p3, _v0, _v1, p4, p5)
    }
    public fun add_rewarder_coin<T0>(p0: &signer, p1: object::Object<LiquidityPoolV3>, p2: u64, p3: u64, p4: u64)
        acquires LiquidityPoolV3
    {
        let _v0 = string::utf8(vector[97u8, 100u8, 100u8, 95u8, 114u8, 101u8, 119u8, 97u8, 114u8, 100u8, 101u8, 114u8, 95u8, 99u8, 111u8, 105u8, 110u8]);
        package_manager::assert_admin(p0, _v0);
        let _v1 = object::object_address<LiquidityPoolV3>(&p1);
        let _v2 = borrow_global_mut<LiquidityPoolV3>(_v1);
        let _v3 = coin_wrapper::wrap<T0>(coin::withdraw<T0>(p0, p4));
        let _v4 = &mut _v2.rewarder_manager;
        let _v5 = *&_v2.liquidity;
        rewarder::add_rewarder(_v1, _v4, p2, p3, _v5, _v3);
    }
    public fun all_pools_with_info(p0: u64, p1: u64): (vector<LiquidityPoolInfoV3>, PageInfo)
        acquires LiquidityPoolConfigsV3, LiquidityPoolV3
    {
        let _v0 = all_pools();
        let _v1 = 0x1::vector::length<object::Object<LiquidityPoolV3>>(&_v0);
        let _v2 = 0x1::vector::empty<LiquidityPoolInfoV3>();
        assert!(p0 < _v1, 100010);
        let _v3 = p0;
        loop {
            let _v4;
            if (_v3 < _v1) {
                let _v5 = p0 + p1;
                _v4 = _v3 < _v5
            } else _v4 = false;
            if (!_v4) break;
            let _v6 = *0x1::vector::borrow<object::Object<LiquidityPoolV3>>(&_v0, _v3);
            let _v7 = object::object_address<LiquidityPoolV3>(&_v6);
            let _v8 = borrow_global<LiquidityPoolV3>(_v7);
            let _v9 = fungible_asset::store_metadata<fungible_asset::FungibleStore>(*&_v8.token_a_liquidity);
            let _v10 = fungible_asset::store_metadata<fungible_asset::FungibleStore>(*&_v8.token_b_liquidity);
            let _v11 = dispatchable_fungible_asset::derived_balance<fungible_asset::FungibleStore>(*&_v8.token_a_liquidity);
            let _v12 = dispatchable_fungible_asset::derived_balance<fungible_asset::FungibleStore>(*&_v8.token_b_liquidity);
            let _v13 = option::destroy_some<u128>(fungible_asset::supply<LiquidityPoolV3>(_v6));
            let _v14 = *&_v8.fee_rate;
            let _v15 = LiquidityPoolInfoV3{pool: _v6, token_a: _v9, token_b: _v10, fee_rate: _v14, token_a_reserve: _v11, token_b_reserve: _v12, liquidity_total: _v13};
            0x1::vector::push_back<LiquidityPoolInfoV3>(&mut _v2, _v15);
            _v3 = _v3 + 1;
            continue
        };
        let _v16 = 0x1::vector::length<LiquidityPoolInfoV3>(&_v2);
        let _v17 = PageInfo{offset: p0, limit: p1, total: _v1, take: _v16};
        (_v2, _v17)
    }
    public entry fun block_position(p0: &signer, p1: object::Object<LiquidityPoolV3>, p2: object::Object<position_v3::Info>) {
        let _v0 = error::unavailable(11111111);
        abort _v0
    }
    public entry fun block_position_batch(p0: &signer, p1: vector<object::Object<position_v3::Info>>) {
        let _v0 = error::unavailable(11111111);
        abort _v0
    }
    public entry fun claim_protocol_fees_all(p0: &signer, p1: object::Object<fungible_asset::Metadata>, p2: object::Object<fungible_asset::Metadata>, p3: u8)
        acquires LiquidityPoolConfigsV3, LiquidityPoolV3
    {
        let _v0 = string::utf8(vector[99u8, 108u8, 97u8, 105u8, 109u8, 95u8, 112u8, 114u8, 111u8, 116u8, 111u8, 99u8, 111u8, 108u8, 95u8, 102u8, 101u8, 101u8, 115u8, 95u8, 97u8, 108u8, 108u8]);
        package_manager::assert_admin(p0, _v0);
        let _v1 = get_protocol_fee_receiver();
        let _v2 = liquidity_pool_address(p1, p2, p3);
        let _v3 = borrow_global_mut<LiquidityPoolV3>(_v2);
        let _v4 = package_manager::get_signer();
        p0 = &_v4;
        let _v5 = *&(&_v3.protocol_fees).token_a;
        let _v6 = fungible_asset::balance<fungible_asset::FungibleStore>(*&(&_v3.protocol_fees).token_a);
        let _v7 = dispatchable_fungible_asset::withdraw<fungible_asset::FungibleStore>(p0, _v5, _v6);
        let _v8 = *&(&_v3.protocol_fees).token_b;
        let _v9 = fungible_asset::balance<fungible_asset::FungibleStore>(*&(&_v3.protocol_fees).token_b);
        let _v10 = dispatchable_fungible_asset::withdraw<fungible_asset::FungibleStore>(p0, _v8, _v9);
        primary_fungible_store::deposit(_v1, _v7);
        primary_fungible_store::deposit(_v1, _v10);
    }
    public fun get_protocol_fee_receiver(): address
        acquires LiquidityPoolConfigsV3
    {
        let _v0 = package_manager::get_resource_address();
        *&borrow_global<LiquidityPoolConfigsV3>(_v0).fee_manager
    }
    public fun create_pool(p0: object::Object<fungible_asset::Metadata>, p1: object::Object<fungible_asset::Metadata>, p2: u8, p3: u32): object::Object<LiquidityPoolV3>
        acquires LiquidityPoolConfigsV3
    {
        if (!utils::is_sorted(p0, p1)) {
            let _v0 = i32::from_u32(p3);
            let _v1 = i32::neg_from(1u32);
            let _v2 = i32::mul(_v0, _v1);
            let _v3 = vector[1u32, 10u32, 60u32, 200u32, 20u32, 50u32];
            let _v4 = &_v3;
            let _v5 = p2 as u64;
            let _v6 = *0x1::vector::borrow<u32>(_v4, _v5);
            let _v7 = i32::as_u32(i32::round_to_spacing(_v2, _v6, false));
            return create_pool(p1, p0, p2, _v7)
        };
        check_protocol_pause();
        let _v8 = package_manager::get_resource_address();
        let _v9 = borrow_global_mut<LiquidityPoolConfigsV3>(_v8);
        let (_v10,_v11,_v12) = lp::create_lp_token(p0, p1, p2);
        let _v13 = _v12;
        let _v14 = _v11;
        let _v15 = i32::from_u32(p3);
        let _v16 = tick_math::get_sqrt_price_at_tick(_v15);
        let _v17 = &_v14;
        let _v18 = object::create_object_from_object(&_v14);
        let _v19 = fungible_asset::create_store<fungible_asset::Metadata>(&_v18, p0);
        let _v20 = object::create_object_from_object(&_v14);
        let _v21 = fungible_asset::create_store<fungible_asset::Metadata>(&_v20, p1);
        let _v22 = object::create_object_from_object(&_v14);
        let _v23 = fungible_asset::create_store<fungible_asset::Metadata>(&_v22, p0);
        let _v24 = object::create_object_from_object(&_v14);
        let _v25 = fungible_asset::create_store<fungible_asset::Metadata>(&_v24, p1);
        let _v26 = vector[100, 500, 3000, 10000, 1000, 2500];
        let _v27 = &_v26;
        let _v28 = p2 as u64;
        let _v29 = *0x1::vector::borrow<u64>(_v27, _v28);
        let _v30 = position_blacklist::new();
        let _v31 = timestamp::now_seconds();
        let _v32 = smart_table::new<i32::I32, tick::TickInfo>();
        let _v33 = tick_bitmap::new();
        let _v34 = object::create_object_from_object(&_v14);
        let _v35 = fungible_asset::create_store<fungible_asset::Metadata>(&_v34, p0);
        let _v36 = object::create_object_from_object(&_v14);
        let _v37 = fungible_asset::create_store<fungible_asset::Metadata>(&_v36, p1);
        let _v38 = ProtocolFees{token_a: _v35, token_b: _v37};
        let _v39 = vector[1u32, 10u32, 60u32, 200u32, 20u32, 50u32];
        let _v40 = &_v39;
        let _v41 = p2 as u64;
        let _v42 = *0x1::vector::borrow<u32>(_v40, _v41);
        let _v43 = vector[1u32, 10u32, 60u32, 200u32, 20u32, 50u32];
        let _v44 = &_v43;
        let _v45 = p2 as u64;
        let _v46 = tick::tick_spacing_to_max_liquidity_per_tick(*0x1::vector::borrow<u32>(_v44, _v45));
        let _v47 = rewarder::init();
        let _v48 = LiquidityPoolV3{token_a_liquidity: _v19, token_b_liquidity: _v21, token_a_fee: _v23, token_b_fee: _v25, sqrt_price: _v16, liquidity: 0u128, tick: _v15, observation_index: 0, observation_cardinality: 0, observation_cardinality_next: 0, fee_rate: _v29, fee_protocol: 200000, unlocked: true, fee_growth_global_a: 0u128, fee_growth_global_b: 0u128, seconds_per_liquidity_oracle: 0u128, seconds_per_liquidity_incentive: 0u128, position_blacklist: _v30, last_update_timestamp: _v31, tick_info: _v32, tick_map: _v33, tick_spacing: _v42, protocol_fees: _v38, lp_token_refs: _v10, max_liquidity_per_tick: _v46, rewarder_manager: _v47};
        move_to<LiquidityPoolV3>(_v17, _v48);
        let _v49 = &mut _v9.all_pools;
        let _v50 = object::convert<fungible_asset::Metadata, LiquidityPoolV3>(_v13);
        smart_vector::push_back<object::Object<LiquidityPoolV3>>(_v49, _v50);
        let _v51 = object::convert<fungible_asset::Metadata, LiquidityPoolV3>(_v13);
        let _v52 = vector[100, 500, 3000, 10000, 1000, 2500];
        let _v53 = &_v52;
        let _v54 = p2 as u64;
        let _v55 = *0x1::vector::borrow<u64>(_v53, _v54);
        event::emit<CreatePoolEvent>(CreatePoolEvent{pool: _v51, token_a: p0, token_b: p1, fee_rate: _v55, fee_tier: p2, sqrt_price: _v16, tick: _v15});
        _v51
    }
    public fun current_tick_and_price(p0: address): (u32, u128)
        acquires LiquidityPoolV3
    {
        let _v0 = borrow_global<LiquidityPoolV3>(p0);
        let _v1 = i32::as_u32(*&_v0.tick);
        let _v2 = *&_v0.sqrt_price;
        (_v1, _v2)
    }
    public entry fun deposit_liquidity_token(p0: &signer, p1: address, p2: object::Object<fungible_asset::Metadata>, p3: u64) {
        let _v0 = error::unavailable(11111111);
        abort _v0
    }
    public fun get_amount_in(p0: object::Object<LiquidityPoolV3>, p1: object::Object<fungible_asset::Metadata>, p2: u64): (u64, u64)
        acquires LiquidityPoolV3
    {
        let _v0;
        let _v1;
        let _v2;
        let _v3;
        let _v4;
        assert!(p2 != 0, 100002);
        let _v5 = object::object_address<LiquidityPoolV3>(&p0);
        let _v6 = borrow_global<LiquidityPoolV3>(_v5);
        assert!(*&_v6.unlocked, 100003);
        let _v7 = fungible_asset::store_metadata<fungible_asset::FungibleStore>(*&_v6.token_a_liquidity);
        let _v8 = &_v7;
        let _v9 = &p1;
        let _v10 = comparator::compare<object::Object<fungible_asset::Metadata>>(_v8, _v9);
        if (comparator::is_equal(&_v10)) _v4 = false else _v4 = true;
        let _v11 = *&_v6.sqrt_price;
        let _v12 = *&_v6.tick;
        if (_v4) _v3 = *&_v6.fee_growth_global_a else _v3 = *&_v6.fee_growth_global_b;
        let _v13 = *&_v6.seconds_per_liquidity_oracle;
        let _v14 = *&_v6.liquidity;
        let _v15 = 0;
        let _v16 = _v13;
        let _v17 = SwapState{amount_specified_remaining: p2, amount_calculated: 0, sqrt_price: _v11, tick: _v12, fee_growth_global: _v3, seconds_per_liquidity: _v16, protocol_fee: _v15, liquidity: _v14, fee_amount_total: 0};
        _v15 = 0;
        while (*&(&_v17).amount_specified_remaining != 0) {
            let _v18 = &_v6.tick_map;
            let _v19 = *&(&_v17).tick;
            let _v20 = *&_v6.tick_spacing;
            let (_v21,_v22) = tick_bitmap::next_initialized_tick_within_one_word(_v18, _v19, _v20, _v4);
            let _v23 = _v21;
            let _v24 = tick_math::min_tick();
            if (i32::lte(_v23, _v24)) _v23 = tick_math::min_tick() else {
                let _v25 = tick_math::max_tick();
                if (i32::gte(_v23, _v25)) _v23 = tick_math::max_tick()
            };
            _v16 = tick_math::get_sqrt_price_at_tick(_v23);
            let _v26 = *&(&_v17).sqrt_price;
            let _v27 = *&(&_v17).liquidity;
            let _v28 = *&(&_v17).amount_specified_remaining;
            let _v29 = *&_v6.fee_rate;
            let (_v30,_v31,_v32,_v33) = swap_math::compute_swap_step(_v26, _v16, _v27, _v28, _v29, _v4, false);
            _v1 = _v33;
            _v14 = _v32;
            _v0 = _v31;
            _v2 = _v30;
            _v15 = _v15 + _v1;
            let _v34 = *&(&_v17).amount_specified_remaining - _v0;
            let _v35 = &mut (&mut _v17).amount_specified_remaining;
            *_v35 = _v34;
            let _v36 = *&(&_v17).amount_calculated + _v2 + _v1;
            let _v37 = &mut (&mut _v17).amount_calculated;
            *_v37 = _v36;
            let _v38 = *&(&_v17).sqrt_price;
            let _v39 = *&(&_v17).liquidity;
            let _v40 = StepComputations{sqrt_price_current: _v38, sqrt_price_next: _v14, amount_in: _v2, amount_out: _v0, fee_amount: _v1, current_liquidity: _v39};
            let _v41 = &mut (&mut _v17).sqrt_price;
            *_v41 = _v14;
            if (*&(&_v17).sqrt_price == _v16) {
                while (_v22) {
                    let _v42 = get_tick(&_v6.tick_info, _v23);
                    let _v43 = tick::get_liquidity_net(&_v42);
                    if (_v4) {
                        let _v44 = i128::neg_from(1u128);
                        let _v45 = i128::mul(_v43, _v44);
                        if (i128::is_neg(_v45)) {
                            let _v46 = *&(&_v17).liquidity;
                            let _v47 = i128::abs_u128(_v45);
                            let _v48 = liquidity_math::sub_delta(_v46, _v47);
                            let _v49 = &mut (&mut _v17).liquidity;
                            *_v49 = _v48;
                            break
                        };
                        let _v50 = *&(&_v17).liquidity;
                        let _v51 = i128::abs_u128(_v45);
                        let _v52 = liquidity_math::add_delta(_v50, _v51);
                        let _v53 = &mut (&mut _v17).liquidity;
                        *_v53 = _v52;
                        break
                    };
                    if (i128::is_neg(_v43)) {
                        let _v54 = *&(&_v17).liquidity;
                        let _v55 = i128::abs_u128(_v43);
                        let _v56 = liquidity_math::sub_delta(_v54, _v55);
                        let _v57 = &mut (&mut _v17).liquidity;
                        *_v57 = _v56;
                        break
                    };
                    let _v58 = *&(&_v17).liquidity;
                    let _v59 = i128::abs_u128(_v43);
                    let _v60 = liquidity_math::add_delta(_v58, _v59);
                    let _v61 = &mut (&mut _v17).liquidity;
                    *_v61 = _v60;
                    break
                };
                if (_v4) {
                    let _v62 = i32::from_u32(1u32);
                    let _v63 = i32::sub(_v23, _v62);
                    let _v64 = &mut (&mut _v17).tick;
                    *_v64 = _v63;
                    continue
                };
                let _v65 = &mut (&mut _v17).tick;
                *_v65 = _v23;
                continue
            };
            let _v66 = *&(&_v17).sqrt_price;
            let _v67 = *&(&_v40).sqrt_price_current;
            if (!(_v66 != _v67)) continue;
            let _v68 = tick_math::get_tick_at_sqrt_price(*&(&_v17).sqrt_price);
            let _v69 = &mut (&mut _v17).tick;
            *_v69 = _v68;
            continue
        };
        if (_v4) {
            _v2 = *&(&_v17).amount_calculated;
            _v0 = *&(&_v17).amount_specified_remaining
        } else {
            _v2 = *&(&_v17).amount_specified_remaining;
            _v0 = *&(&_v17).amount_calculated
        };
        if (_v4) {
            assert!(_v0 == 0, 100009);
            _v1 = _v2
        } else if (_v2 == 0) _v1 = _v0 else abort 100009;
        (_v1, _v15)
    }
    public fun get_amount_out(p0: object::Object<LiquidityPoolV3>, p1: object::Object<fungible_asset::Metadata>, p2: u64): (u64, u64)
        acquires LiquidityPoolV3
    {
        let _v0;
        let _v1;
        let _v2;
        let _v3;
        let _v4;
        assert!(p2 != 0, 100002);
        let _v5 = object::object_address<LiquidityPoolV3>(&p0);
        let _v6 = borrow_global<LiquidityPoolV3>(_v5);
        assert!(*&_v6.unlocked, 100003);
        let _v7 = fungible_asset::store_metadata<fungible_asset::FungibleStore>(*&_v6.token_a_liquidity);
        let _v8 = &_v7;
        let _v9 = &p1;
        let _v10 = comparator::compare<object::Object<fungible_asset::Metadata>>(_v8, _v9);
        if (comparator::is_equal(&_v10)) _v4 = true else _v4 = false;
        let _v11 = *&_v6.sqrt_price;
        let _v12 = *&_v6.tick;
        if (_v4) _v3 = *&_v6.fee_growth_global_a else _v3 = *&_v6.fee_growth_global_b;
        let _v13 = *&_v6.seconds_per_liquidity_oracle;
        let _v14 = *&_v6.liquidity;
        let _v15 = 0;
        let _v16 = _v13;
        let _v17 = SwapState{amount_specified_remaining: p2, amount_calculated: 0, sqrt_price: _v11, tick: _v12, fee_growth_global: _v3, seconds_per_liquidity: _v16, protocol_fee: _v15, liquidity: _v14, fee_amount_total: 0};
        _v15 = 0;
        while (*&(&_v17).amount_specified_remaining != 0) {
            let _v18 = &_v6.tick_map;
            let _v19 = *&(&_v17).tick;
            let _v20 = *&_v6.tick_spacing;
            let (_v21,_v22) = tick_bitmap::next_initialized_tick_within_one_word(_v18, _v19, _v20, _v4);
            let _v23 = _v21;
            let _v24 = tick_math::min_tick();
            if (i32::lte(_v23, _v24)) _v23 = tick_math::min_tick() else {
                let _v25 = tick_math::max_tick();
                if (i32::gte(_v23, _v25)) _v23 = tick_math::max_tick()
            };
            _v16 = tick_math::get_sqrt_price_at_tick(_v23);
            let _v26 = *&(&_v17).sqrt_price;
            let _v27 = *&(&_v17).liquidity;
            let _v28 = *&(&_v17).amount_specified_remaining;
            let _v29 = *&_v6.fee_rate;
            let (_v30,_v31,_v32,_v33) = swap_math::compute_swap_step(_v26, _v16, _v27, _v28, _v29, _v4, true);
            _v1 = _v33;
            _v14 = _v32;
            _v0 = _v31;
            _v2 = _v30;
            _v15 = _v15 + _v1;
            let _v34 = *&(&_v17).amount_specified_remaining;
            let _v35 = _v2 + _v1;
            let _v36 = _v34 - _v35;
            let _v37 = &mut (&mut _v17).amount_specified_remaining;
            *_v37 = _v36;
            let _v38 = *&(&_v17).amount_calculated + _v0;
            let _v39 = &mut (&mut _v17).amount_calculated;
            *_v39 = _v38;
            let _v40 = *&(&_v17).sqrt_price;
            let _v41 = *&(&_v17).liquidity;
            let _v42 = StepComputations{sqrt_price_current: _v40, sqrt_price_next: _v14, amount_in: _v2, amount_out: _v0, fee_amount: _v1, current_liquidity: _v41};
            let _v43 = &mut (&mut _v17).sqrt_price;
            *_v43 = _v14;
            if (*&(&_v17).sqrt_price == _v16) {
                while (_v22) {
                    let _v44 = get_tick(&_v6.tick_info, _v23);
                    let _v45 = tick::get_liquidity_net(&_v44);
                    if (_v4) {
                        let _v46 = i128::neg_from(1u128);
                        let _v47 = i128::mul(_v45, _v46);
                        if (i128::is_neg(_v47)) {
                            let _v48 = *&(&_v17).liquidity;
                            let _v49 = i128::abs_u128(_v47);
                            let _v50 = liquidity_math::sub_delta(_v48, _v49);
                            let _v51 = &mut (&mut _v17).liquidity;
                            *_v51 = _v50;
                            break
                        };
                        let _v52 = *&(&_v17).liquidity;
                        let _v53 = i128::abs_u128(_v47);
                        let _v54 = liquidity_math::add_delta(_v52, _v53);
                        let _v55 = &mut (&mut _v17).liquidity;
                        *_v55 = _v54;
                        break
                    };
                    if (i128::is_neg(_v45)) {
                        let _v56 = *&(&_v17).liquidity;
                        let _v57 = i128::abs_u128(_v45);
                        let _v58 = liquidity_math::sub_delta(_v56, _v57);
                        let _v59 = &mut (&mut _v17).liquidity;
                        *_v59 = _v58;
                        break
                    };
                    let _v60 = *&(&_v17).liquidity;
                    let _v61 = i128::abs_u128(_v45);
                    let _v62 = liquidity_math::add_delta(_v60, _v61);
                    let _v63 = &mut (&mut _v17).liquidity;
                    *_v63 = _v62;
                    break
                };
                if (_v4) {
                    let _v64 = i32::from_u32(1u32);
                    let _v65 = i32::sub(_v23, _v64);
                    let _v66 = &mut (&mut _v17).tick;
                    *_v66 = _v65;
                    continue
                };
                let _v67 = &mut (&mut _v17).tick;
                *_v67 = _v23;
                continue
            };
            let _v68 = *&(&_v17).sqrt_price;
            let _v69 = *&(&_v42).sqrt_price_current;
            if (!(_v68 != _v69)) continue;
            let _v70 = tick_math::get_tick_at_sqrt_price(*&(&_v17).sqrt_price);
            let _v71 = &mut (&mut _v17).tick;
            *_v71 = _v70;
            continue
        };
        if (_v4) {
            _v2 = *&(&_v17).amount_specified_remaining;
            _v0 = *&(&_v17).amount_calculated
        } else {
            _v2 = *&(&_v17).amount_calculated;
            _v0 = *&(&_v17).amount_specified_remaining
        };
        if (_v4) {
            assert!(_v2 == 0, 100009);
            _v1 = _v0
        } else if (_v0 == 0) _v1 = _v2 else abort 100009;
        (_v1, _v15)
    }
    public fun get_blocked_position(p0: object::Object<LiquidityPoolV3>): vector<address> {
        position_blacklist_v2::view_list(object::object_address<LiquidityPoolV3>(&p0))
    }
    public fun get_fee_rate(p0: u8): u64 {
        let _v0 = vector[100, 500, 3000, 10000, 1000, 2500];
        let _v1 = &_v0;
        let _v2 = p0 as u64;
        *0x1::vector::borrow<u64>(_v1, _v2)
    }
    public fun get_pending_fees(p0: object::Object<position_v3::Info>): vector<u64>
        acquires LiquidityPoolV3
    {
        let (_v0,_v1) = position_v3::get_tick(p0);
        let _v2 = _v1;
        let _v3 = _v0;
        let (_v4,_v5,_v6) = position_v3::get_pool_info(p0);
        let _v7 = _v6;
        let _v8 = _v5;
        let _v9 = _v4;
        let _v10 = liquidity_pool_address(_v9, _v8, _v7);
        let _v11 = position_v3::get_liquidity(p0);
        loop {
            if (_v11 == 0u128) return vector[0, 0] else {
                let _v12 = object::object_address<position_v3::Info>(&p0);
                if (!position_blacklist_v2::does_position_blocked(_v10, _v12)) break
            };
            return vector[0, 0]
        };
        let _v13 = liquidity_pool_address(_v9, _v8, _v7);
        let _v14 = borrow_global<LiquidityPoolV3>(_v13);
        let _v15 = get_tick(&_v14.tick_info, _v3);
        let _v16 = get_tick(&_v14.tick_info, _v2);
        let _v17 = *&_v14.tick;
        let _v18 = *&_v14.fee_growth_global_a;
        let _v19 = *&_v14.fee_growth_global_b;
        let (_v20,_v21) = tick::get_fee_growth_inside(_v15, _v16, _v3, _v2, _v17, _v18, _v19);
        let (_v22,_v23) = position_v3::calc_fees(p0, _v20, _v21);
        let _v24 = 0x1::vector::empty<u64>();
        let _v25 = &mut _v24;
        0x1::vector::push_back<u64>(_v25, _v22);
        0x1::vector::push_back<u64>(_v25, _v23);
        _v24
    }
    public fun get_pending_fees_blocked(p0: object::Object<position_v3::Info>): vector<u64>
        acquires LiquidityPoolV3
    {
        let (_v0,_v1) = position_v3::get_tick(p0);
        let _v2 = _v1;
        let _v3 = _v0;
        let (_v4,_v5,_v6) = position_v3::get_pool_info(p0);
        let _v7 = _v6;
        let _v8 = _v5;
        let _v9 = _v4;
        let _v10 = liquidity_pool_address(_v9, _v8, _v7);
        let _v11 = position_v3::get_liquidity(p0);
        loop {
            if (!(_v11 == 0u128)) {
                let _v12 = object::object_address<position_v3::Info>(&p0);
                if (position_blacklist_v2::does_position_blocked(_v10, _v12)) break;
                abort 100017
            };
            return vector[0, 0]
        };
        let _v13 = liquidity_pool_address(_v9, _v8, _v7);
        let _v14 = borrow_global<LiquidityPoolV3>(_v13);
        let _v15 = get_tick(&_v14.tick_info, _v3);
        let _v16 = get_tick(&_v14.tick_info, _v2);
        let _v17 = *&_v14.tick;
        let _v18 = *&_v14.fee_growth_global_a;
        let _v19 = *&_v14.fee_growth_global_b;
        let (_v20,_v21) = tick::get_fee_growth_inside(_v15, _v16, _v3, _v2, _v17, _v18, _v19);
        let (_v22,_v23) = position_v3::calc_fees(p0, _v20, _v21);
        let _v24 = 0x1::vector::empty<u64>();
        let _v25 = &mut _v24;
        0x1::vector::push_back<u64>(_v25, _v22);
        0x1::vector::push_back<u64>(_v25, _v23);
        _v24
    }
    public fun get_pending_rewards(p0: object::Object<position_v3::Info>): vector<rewarder::PendingReward>
        acquires LiquidityPoolV3
    {
        let (_v0,_v1) = position_v3::get_tick(p0);
        let _v2 = _v1;
        let _v3 = _v0;
        let (_v4,_v5,_v6) = position_v3::get_pool_info(p0);
        let _v7 = _v6;
        let _v8 = _v5;
        let _v9 = _v4;
        let _v10 = liquidity_pool_address(_v9, _v8, _v7);
        let _v11 = liquidity_pool_address(_v9, _v8, _v7);
        let _v12 = borrow_global<LiquidityPoolV3>(_v11);
        let _v13 = object::object_address<position_v3::Info>(&p0);
        if (position_blacklist_v2::does_position_blocked(_v10, _v13)) return 0x1::vector::empty<rewarder::PendingReward>();
        let _v14 = &_v12.rewarder_manager;
        let _v15 = *&_v12.liquidity;
        let _v16 = rewarder::get_emissions_per_liquidity_list_realtime(_v14, _v15);
        let _v17 = position_v3::copy_position_rewards(p0);
        let _v18 = get_tick(&_v12.tick_info, _v3);
        let _v19 = &mut _v18;
        let _v20 = 0x1::vector::length<u128>(&_v16);
        tick::padding_emissions_list(_v19, _v20);
        let _v21 = get_tick(&_v12.tick_info, _v2);
        let _v22 = &mut _v21;
        let _v23 = 0x1::vector::length<u128>(&_v16);
        tick::padding_emissions_list(_v22, _v23);
        let _v24 = *&_v12.tick;
        let _v25 = tick::get_emissions_per_liquidity_incentive_inside(_v18, _v21, _v3, _v2, _v24, _v16);
        let _v26 = &_v12.rewarder_manager;
        let _v27 = position_v3::get_liquidity(p0);
        rewarder::pending_rewards(_v26, _v17, _v25, _v27)
    }
    public fun get_pending_rewards_blocked(p0: object::Object<position_v3::Info>): vector<rewarder::PendingReward>
        acquires LiquidityPoolV3
    {
        let (_v0,_v1) = position_v3::get_tick(p0);
        let _v2 = _v1;
        let _v3 = _v0;
        let (_v4,_v5,_v6) = position_v3::get_pool_info(p0);
        let _v7 = _v6;
        let _v8 = _v5;
        let _v9 = _v4;
        let _v10 = liquidity_pool_address(_v9, _v8, _v7);
        let _v11 = liquidity_pool_address(_v9, _v8, _v7);
        let _v12 = borrow_global<LiquidityPoolV3>(_v11);
        let _v13 = object::object_address<position_v3::Info>(&p0);
        assert!(position_blacklist_v2::does_position_blocked(_v10, _v13), 100017);
        let _v14 = _v12;
        let _v15 = *&_v14.tick;
        let _v16 = position_blacklist_v2::blocked_out_liquidity_amount(_v10, _v15);
        _v16 = *&_v14.liquidity - _v16;
        let _v17 = rewarder::get_emissions_per_liquidity_list_realtime(&_v12.rewarder_manager, _v16);
        let _v18 = position_v3::copy_position_rewards(p0);
        let _v19 = get_tick(&_v12.tick_info, _v3);
        let _v20 = &mut _v19;
        let _v21 = 0x1::vector::length<u128>(&_v17);
        tick::padding_emissions_list(_v20, _v21);
        let _v22 = get_tick(&_v12.tick_info, _v2);
        let _v23 = &mut _v22;
        let _v24 = 0x1::vector::length<u128>(&_v17);
        tick::padding_emissions_list(_v23, _v24);
        let _v25 = *&_v12.tick;
        let _v26 = tick::get_emissions_per_liquidity_incentive_inside(_v19, _v22, _v3, _v2, _v25, _v17);
        let _v27 = &_v12.rewarder_manager;
        let _v28 = position_v3::get_liquidity(p0);
        rewarder::pending_rewards(_v27, _v18, _v26, _v28)
    }
    public fun get_pool_liquidity(p0: object::Object<LiquidityPoolV3>): u128
        acquires LiquidityPoolV3
    {
        let _v0 = object::object_address<LiquidityPoolV3>(&p0);
        *&borrow_global<LiquidityPoolV3>(_v0).liquidity
    }
    public fun get_pool_tick_info(p0: object::Object<LiquidityPoolV3>, p1: u32): tick::TickInfo
        acquires LiquidityPoolV3
    {
        let _v0 = object::object_address<LiquidityPoolV3>(&p0);
        let _v1 = &borrow_global<LiquidityPoolV3>(_v0).tick_info;
        let _v2 = i32::from_u32(p1);
        get_tick(_v1, _v2)
    }
    public fun get_pool_tick_info_batch(p0: object::Object<LiquidityPoolV3>, p1: vector<u32>): vector<tick::TickInfo>
        acquires LiquidityPoolV3
    {
        let _v0 = 0x1::vector::empty<tick::TickInfo>();
        let _v1 = 0;
        loop {
            let _v2 = 0x1::vector::length<u32>(&p1);
            if (!(_v1 < _v2)) break;
            let _v3 = &mut _v0;
            let _v4 = *0x1::vector::borrow<u32>(&p1, _v1);
            let _v5 = get_pool_tick_info(p0, _v4);
            0x1::vector::push_back<tick::TickInfo>(_v3, _v5);
            _v1 = _v1 + 1;
            continue
        };
        _v0
    }
    public fun get_position_emission_rate(p0: object::Object<position_v3::Info>): vector<rewarder::RewardRate>
        acquires LiquidityPoolV3
    {
        let (_v0,_v1,_v2) = position_v3::get_pool_info(p0);
        let _v3 = liquidity_pool_address(_v0, _v1, _v2);
        let _v4 = borrow_global<LiquidityPoolV3>(_v3);
        let _v5 = position_v3::get_liquidity(p0);
        let _v6 = &_v4.rewarder_manager;
        let _v7 = *&_v4.liquidity;
        rewarder::position_reward_rate(_v6, _v7, _v5)
    }
    public fun get_protocol_fee_rate(p0: object::Object<LiquidityPoolV3>): u64
        acquires LiquidityPoolV3
    {
        let _v0 = object::object_address<LiquidityPoolV3>(&p0);
        *&borrow_global<LiquidityPoolV3>(_v0).fee_protocol
    }
    public fun get_remaining_incentive(p0: object::Object<LiquidityPoolV3>): vector<rewarder::RemainingIncentive>
        acquires LiquidityPoolV3
    {
        let _v0 = object::object_address<LiquidityPoolV3>(&p0);
        rewarder::remaining_incentive(&borrow_global<LiquidityPoolV3>(_v0).rewarder_manager)
    }
    public fun get_rewarder_numbers(p0: object::Object<LiquidityPoolV3>): vector<rewarder::Numbers>
        acquires LiquidityPoolV3
    {
        let _v0 = object::object_address<LiquidityPoolV3>(&p0);
        rewarder::numbers(&borrow_global<LiquidityPoolV3>(_v0).rewarder_manager)
    }
    public fun get_rewarder_numbers_v1(p0: object::Object<LiquidityPoolV3>): vector<rewarder::NumbersV1>
        acquires LiquidityPoolV3
    {
        let _v0 = object::object_address<LiquidityPoolV3>(&p0);
        rewarder::numbers_v1(&borrow_global<LiquidityPoolV3>(_v0).rewarder_manager)
    }
    fun get_token_name_metadata(p0: object::Object<fungible_asset::Metadata>): (string::String, string::String) {
        let _v0 = coin::paired_coin(p0);
        if (option::is_some<type_info::TypeInfo>(&_v0)) {
            let _v1 = fungible_asset::name<fungible_asset::Metadata>(p0);
            let _v2 = coin_wrapper::get_coin_type(p0);
            return (_v1, _v2)
        };
        let _v3 = fungible_asset::name<fungible_asset::Metadata>(p0);
        let _v4 = coin_wrapper::format_fungible_asset(p0);
        (_v3, _v4)
    }
    public fun liquidity_pool_address_safe(p0: object::Object<fungible_asset::Metadata>, p1: object::Object<fungible_asset::Metadata>, p2: u8): (bool, address) {
        let _v0 = liquidity_pool_address(p0, p1, p2);
        (exists<LiquidityPoolV3>(_v0), _v0)
    }
    public fun liquidity_pool_info(p0: object::Object<LiquidityPoolV3>): vector<string::String>
        acquires LiquidityPoolV3
    {
        let _v0 = object::object_address<LiquidityPoolV3>(&p0);
        let _v1 = borrow_global<LiquidityPoolV3>(_v0);
        let (_v2,_v3) = get_token_name_metadata(fungible_asset::store_metadata<fungible_asset::FungibleStore>(*&_v1.token_a_liquidity));
        let (_v4,_v5) = get_token_name_metadata(fungible_asset::store_metadata<fungible_asset::FungibleStore>(*&_v1.token_b_liquidity));
        let _v6 = 0x1::vector::empty<string::String>();
        let _v7 = &mut _v6;
        0x1::vector::push_back<string::String>(_v7, _v2);
        0x1::vector::push_back<string::String>(_v7, _v3);
        0x1::vector::push_back<string::String>(_v7, _v4);
        0x1::vector::push_back<string::String>(_v7, _v5);
        _v6
    }
    public fun liquidity_pool_info_both_coin<T0, T1>(p0: u8): vector<string::String>
        acquires LiquidityPoolV3
    {
        let _v0 = coin::paired_metadata<T0>();
        if (option::is_none<object::Object<fungible_asset::Metadata>>(&_v0)) return 0x1::vector::empty<string::String>();
        liquidity_pool_info_with_coin_fa<T1>(option::destroy_some<object::Object<fungible_asset::Metadata>>(_v0), p0)
    }
    public fun liquidity_pool_info_with_coin_fa<T0>(p0: object::Object<fungible_asset::Metadata>, p1: u8): vector<string::String>
        acquires LiquidityPoolV3
    {
        let _v0 = coin::paired_metadata<T0>();
        if (option::is_none<object::Object<fungible_asset::Metadata>>(&_v0)) return 0x1::vector::empty<string::String>();
        liquidity_pool_info_both_fa(option::destroy_some<object::Object<fungible_asset::Metadata>>(_v0), p0, p1)
    }
    public fun liquidity_pool_info_both_fa(p0: object::Object<fungible_asset::Metadata>, p1: object::Object<fungible_asset::Metadata>, p2: u8): vector<string::String>
        acquires LiquidityPoolV3
    {
        let _v0;
        let _v1 = utils::is_sorted(p0, p1);
        'l0: loop {
            loop {
                if (_v1) {
                    let _v2 = lp::get_pool_seeds(p0, p1, p2);
                    let _v3 = package_manager::get_resource_address();
                    _v0 = object::create_object_address(&_v3, _v2);
                    if (!object::is_object(_v0)) break;
                    break 'l0
                };
                return liquidity_pool_info_both_fa(p1, p0, p2)
            };
            return 0x1::vector::empty<string::String>()
        };
        let _v4 = borrow_global<LiquidityPoolV3>(_v0);
        let (_v5,_v6) = get_token_name_metadata(fungible_asset::store_metadata<fungible_asset::FungibleStore>(*&_v4.token_a_liquidity));
        let (_v7,_v8) = get_token_name_metadata(fungible_asset::store_metadata<fungible_asset::FungibleStore>(*&_v4.token_b_liquidity));
        let _v9 = string_utils::to_string<address>(&_v0);
        let _v10 = &_v9;
        let _v11 = string::length(&_v9);
        let _v12 = string::sub_string(_v10, 1, _v11);
        let _v13 = fungible_asset::balance<fungible_asset::FungibleStore>(*&_v4.token_a_liquidity);
        let _v14 = string_utils::to_string<u64>(&_v13);
        let _v15 = fungible_asset::balance<fungible_asset::FungibleStore>(*&_v4.token_b_liquidity);
        let _v16 = string_utils::to_string<u64>(&_v15);
        let _v17 = option::destroy_with_default<u128>(fungible_asset::supply<fungible_asset::Metadata>(object::address_to_object<fungible_asset::Metadata>(_v0)), 0u128);
        let _v18 = string_utils::to_string<u128>(&_v17);
        let _v19 = string_utils::to_string<u8>(&p2);
        let _v20 = string_utils::to_string<u64>(&_v4.fee_rate);
        let _v21 = 0x1::vector::empty<string::String>();
        let _v22 = &mut _v21;
        0x1::vector::push_back<string::String>(_v22, _v5);
        0x1::vector::push_back<string::String>(_v22, _v6);
        0x1::vector::push_back<string::String>(_v22, _v7);
        0x1::vector::push_back<string::String>(_v22, _v8);
        0x1::vector::push_back<string::String>(_v22, _v12);
        0x1::vector::push_back<string::String>(_v22, _v14);
        0x1::vector::push_back<string::String>(_v22, _v16);
        0x1::vector::push_back<string::String>(_v22, _v18);
        0x1::vector::push_back<string::String>(_v22, _v19);
        0x1::vector::push_back<string::String>(_v22, _v20);
        _v21
    }
    public entry fun pause_pool(p0: &signer, p1: object::Object<LiquidityPoolV3>)
        acquires LiquidityPoolV3
    {
        let _v0 = string::utf8(vector[112u8, 97u8, 117u8, 115u8, 101u8, 95u8, 112u8, 111u8, 111u8, 108u8]);
        package_manager::assert_admin(p0, _v0);
        let _v1 = object::object_address<LiquidityPoolV3>(&p1);
        let _v2 = &mut borrow_global_mut<LiquidityPoolV3>(_v1).unlocked;
        *_v2 = false;
    }
    public entry fun pause_protocol(p0: &signer)
        acquires LiquidityPoolConfigsV3
    {
        let _v0 = string::utf8(vector[112u8, 97u8, 117u8, 115u8, 101u8, 95u8, 112u8, 114u8, 111u8, 116u8, 111u8, 99u8, 111u8, 108u8]);
        package_manager::assert_admin(p0, _v0);
        let _v1 = package_manager::get_resource_address();
        let _v2 = &mut borrow_global_mut<LiquidityPoolConfigsV3>(_v1).is_paused;
        *_v2 = true;
    }
    public entry fun pause_rewarder_manager(p0: &signer, p1: object::Object<LiquidityPoolV3>)
        acquires LiquidityPoolV3
    {
        let _v0;
        let _v1;
        let _v2 = string::utf8(vector[112u8, 97u8, 117u8, 115u8, 101u8, 95u8, 114u8, 101u8, 119u8, 97u8, 114u8, 100u8, 101u8, 114u8, 95u8, 109u8, 97u8, 110u8, 97u8, 103u8, 101u8, 114u8]);
        package_manager::assert_admin(p0, _v2);
        let _v3 = object::object_address<LiquidityPoolV3>(&p1);
        let _v4 = borrow_global_mut<LiquidityPoolV3>(_v3);
        let _v5 = _v4;
        let _v6 = timestamp::now_seconds();
        let _v7 = *&_v5.last_update_timestamp;
        let _v8 = _v6 - _v7;
        if (*&_v5.liquidity != 0u128) {
            let _v9 = (_v8 as u128) << 64u8;
            let _v10 = *&_v5.liquidity;
            _v1 = _v9 / _v10
        } else _v1 = 0u128;
        let _v11 = freeze(_v5);
        let _v12 = *&_v11.tick;
        let _v13 = position_blacklist_v2::blocked_out_liquidity_amount(_v3, _v12);
        _v13 = *&_v11.liquidity - _v13;
        if (_v13 != 0u128) _v0 = ((_v8 as u128) << 64u8) / _v13 else _v0 = 0u128;
        let _v14 = *&_v5.seconds_per_liquidity_oracle + _v1;
        let _v15 = &mut _v5.seconds_per_liquidity_oracle;
        *_v15 = _v14;
        let _v16 = *&_v5.seconds_per_liquidity_incentive + _v0;
        let _v17 = &mut _v5.seconds_per_liquidity_incentive;
        *_v17 = _v16;
        let _v18 = &mut _v5.last_update_timestamp;
        *_v18 = _v6;
        rewarder::flash(&mut _v5.rewarder_manager, _v13);
        rewarder::set_pause(&mut _v4.rewarder_manager, true);
    }
    public fun pool_next_initialize_tick(p0: object::Object<LiquidityPoolV3>, p1: bool): (i32::I32, bool)
        acquires LiquidityPoolV3
    {
        let _v0 = object::object_address<LiquidityPoolV3>(&p0);
        let _v1 = borrow_global<LiquidityPoolV3>(_v0);
        let _v2 = &_v1.tick_map;
        let _v3 = *&_v1.tick;
        let _v4 = *&_v1.tick_spacing;
        let (_v5,_v6) = tick_bitmap::next_initialized_tick_within_one_word(_v2, _v3, _v4, p1);
        (_v5, _v6)
    }
    public fun pool_reserve_amount(p0: object::Object<LiquidityPoolV3>): (u64, u64)
        acquires LiquidityPoolV3
    {
        let _v0 = object::object_address<LiquidityPoolV3>(&p0);
        let _v1 = borrow_global<LiquidityPoolV3>(_v0);
        let _v2 = dispatchable_fungible_asset::derived_balance<fungible_asset::FungibleStore>(*&_v1.token_a_liquidity);
        let _v3 = dispatchable_fungible_asset::derived_balance<fungible_asset::FungibleStore>(*&_v1.token_b_liquidity);
        (_v2, _v3)
    }
    public fun pool_rewarder_list(p0: object::Object<LiquidityPoolV3>): vector<rewarder::Rewarder>
        acquires LiquidityPoolV3
    {
        let _v0 = object::object_address<LiquidityPoolV3>(&p0);
        rewarder::get_rewarder_list(&borrow_global<LiquidityPoolV3>(_v0).rewarder_manager)
    }
    public entry fun remove_position_block(p0: &signer, p1: object::Object<LiquidityPoolV3>, p2: object::Object<position_v3::Info>) {
        let _v0 = error::unavailable(11111111);
        abort _v0
    }
    public entry fun restart_rewarder_manager(p0: &signer, p1: object::Object<LiquidityPoolV3>)
        acquires LiquidityPoolV3
    {
        let _v0;
        let _v1;
        let _v2 = string::utf8(vector[114u8, 101u8, 115u8, 116u8, 97u8, 114u8, 116u8, 95u8, 114u8, 101u8, 119u8, 97u8, 114u8, 100u8, 101u8, 114u8, 95u8, 109u8, 97u8, 110u8, 97u8, 103u8, 101u8, 114u8]);
        package_manager::assert_admin(p0, _v2);
        let _v3 = object::object_address<LiquidityPoolV3>(&p1);
        let _v4 = borrow_global_mut<LiquidityPoolV3>(_v3);
        rewarder::set_pause(&mut _v4.rewarder_manager, false);
        let _v5 = timestamp::now_seconds();
        let _v6 = *&_v4.last_update_timestamp;
        let _v7 = _v5 - _v6;
        if (*&_v4.liquidity != 0u128) {
            let _v8 = (_v7 as u128) << 64u8;
            let _v9 = *&_v4.liquidity;
            _v1 = _v8 / _v9
        } else _v1 = 0u128;
        let _v10 = freeze(_v4);
        let _v11 = *&_v10.tick;
        let _v12 = position_blacklist_v2::blocked_out_liquidity_amount(_v3, _v11);
        _v12 = *&_v10.liquidity - _v12;
        if (_v12 != 0u128) _v0 = ((_v7 as u128) << 64u8) / _v12 else _v0 = 0u128;
        let _v13 = *&_v4.seconds_per_liquidity_oracle + _v1;
        let _v14 = &mut _v4.seconds_per_liquidity_oracle;
        *_v14 = _v13;
        let _v15 = *&_v4.seconds_per_liquidity_incentive + _v0;
        let _v16 = &mut _v4.seconds_per_liquidity_incentive;
        *_v16 = _v15;
        let _v17 = &mut _v4.last_update_timestamp;
        *_v17 = _v5;
        rewarder::flash(&mut _v4.rewarder_manager, _v12);
    }
    public entry fun resume_pool(p0: &signer, p1: object::Object<LiquidityPoolV3>)
        acquires LiquidityPoolV3
    {
        let _v0 = string::utf8(vector[114u8, 101u8, 115u8, 117u8, 109u8, 101u8, 95u8, 112u8, 111u8, 111u8, 108u8]);
        package_manager::assert_admin(p0, _v0);
        let _v1 = object::object_address<LiquidityPoolV3>(&p1);
        let _v2 = &mut borrow_global_mut<LiquidityPoolV3>(_v1).unlocked;
        *_v2 = true;
    }
    entry fun set_protocol_fee_receiver(p0: &signer, p1: address)
        acquires LiquidityPoolConfigsV3
    {
        let _v0 = string::utf8(vector[115u8, 101u8, 116u8, 95u8, 112u8, 114u8, 111u8, 116u8, 111u8, 99u8, 111u8, 108u8, 95u8, 102u8, 101u8, 101u8, 95u8, 114u8, 101u8, 99u8, 101u8, 105u8, 118u8, 101u8, 114u8]);
        package_manager::assert_admin(p0, _v0);
        let _v1 = package_manager::get_resource_address();
        let _v2 = &mut borrow_global_mut<LiquidityPoolConfigsV3>(_v1).fee_manager;
        *_v2 = p1;
    }
    public entry fun start_protocol(p0: &signer)
        acquires LiquidityPoolConfigsV3
    {
        let _v0 = string::utf8(vector[115u8, 116u8, 97u8, 114u8, 116u8, 95u8, 112u8, 114u8, 111u8, 116u8, 111u8, 99u8, 111u8, 108u8]);
        package_manager::assert_admin(p0, _v0);
        let _v1 = package_manager::get_resource_address();
        let _v2 = &mut borrow_global_mut<LiquidityPoolConfigsV3>(_v1).is_paused;
        *_v2 = false;
    }
    public fun supported_inner_assets(p0: object::Object<LiquidityPoolV3>): vector<object::Object<fungible_asset::Metadata>>
        acquires LiquidityPoolV3
    {
        let _v0 = object::object_address<LiquidityPoolV3>(&p0);
        let _v1 = borrow_global<LiquidityPoolV3>(_v0);
        let _v2 = fungible_asset::store_metadata<fungible_asset::FungibleStore>(*&_v1.token_a_liquidity);
        let _v3 = fungible_asset::store_metadata<fungible_asset::FungibleStore>(*&_v1.token_b_liquidity);
        let _v4 = 0x1::vector::empty<object::Object<fungible_asset::Metadata>>();
        let _v5 = &mut _v4;
        0x1::vector::push_back<object::Object<fungible_asset::Metadata>>(_v5, _v2);
        0x1::vector::push_back<object::Object<fungible_asset::Metadata>>(_v5, _v3);
        _v4
    }
    fun update_net(p0: &mut smart_table::SmartTable<i32::I32, tick::TickInfo>, p1: i32::I32, p2: bool, p3: u128, p4: bool) {
        tick::update_net_only(get_tick_mut(p0, p1), p1, p2, p3, p4);
    }
    public entry fun update_pool_liquidity(p0: &signer, p1: address, p2: u128) {
        let _v0 = error::unavailable(11111111);
        abort _v0
    }
    public entry fun update_protocol_fee_rate(p0: &signer, p1: object::Object<LiquidityPoolV3>, p2: u64)
        acquires LiquidityPoolV3
    {
        let _v0 = string::utf8(vector[117u8, 112u8, 100u8, 97u8, 116u8, 101u8, 95u8, 112u8, 114u8, 111u8, 116u8, 111u8, 99u8, 111u8, 108u8, 95u8, 102u8, 101u8, 101u8, 95u8, 114u8, 97u8, 116u8, 101u8]);
        package_manager::assert_admin(p0, _v0);
        assert!(p2 <= 1000000, 100013);
        let _v1 = object::object_address<LiquidityPoolV3>(&p1);
        let _v2 = &mut borrow_global_mut<LiquidityPoolV3>(_v1).fee_protocol;
        *_v2 = p2;
    }
    public entry fun update_remove_liquidity_amount(p0: &signer, p1: address, p2: u128, p3: u32, p4: u32) {
        let _v0 = error::unavailable(11111111);
        abort _v0
    }
    public entry fun update_reward_amount(p0: &signer, p1: address, p2: object::Object<fungible_asset::Metadata>, p3: u64) {
        let _v0 = error::unavailable(11111111);
        abort _v0
    }
    fun update_tick_net_and_gross(p0: &mut smart_table::SmartTable<i32::I32, tick::TickInfo>, p1: i32::I32, p2: bool, p3: u128, p4: bool): bool {
        tick::update_net_and_gross(get_tick_mut(p0, p1), p1, p2, p3, p4)
    }
    public entry fun withdraw_temporary_coin<T0>(p0: &signer, p1: object::Object<LiquidityPoolV3>, p2: u64, p3: address)
        acquires LiquidityPoolV3, PoolTemporaryStorage
    {
        let _v0;
        let _v1 = string::utf8(vector[119u8, 105u8, 116u8, 104u8, 100u8, 114u8, 97u8, 119u8, 95u8, 116u8, 101u8, 109u8, 112u8, 111u8, 114u8, 97u8, 114u8, 121u8, 95u8, 99u8, 111u8, 105u8, 110u8]);
        package_manager::assert_admin(p0, _v1);
        let _v2 = object::object_address<LiquidityPoolV3>(&p1);
        let _v3 = lp::get_signer(&borrow_global_mut<LiquidityPoolV3>(_v2).lp_token_refs);
        let _v4 = option::destroy_some<object::Object<fungible_asset::Metadata>>(coin::paired_metadata<T0>());
        p0 = &_v3;
        let _v5 = _v4;
        let _v6 = signer::address_of(p0);
        if (!exists<PoolTemporaryStorage>(_v6)) {
            let _v7 = PoolTemporaryStorage{stores: 0x1::vector::empty<object::Object<fungible_asset::FungibleStore>>()};
            move_to<PoolTemporaryStorage>(p0, _v7)
        };
        let _v8 = signer::address_of(p0);
        let _v9 = borrow_global_mut<PoolTemporaryStorage>(_v8);
        let _v10 = &_v9.stores;
        let _v11 = false;
        let _v12 = 0;
        let _v13 = 0;
        let _v14 = 0x1::vector::length<object::Object<fungible_asset::FungibleStore>>(_v10);
        'l0: loop {
            loop {
                if (!(_v13 < _v14)) break 'l0;
                if (fungible_asset::store_metadata<fungible_asset::FungibleStore>(*0x1::vector::borrow<object::Object<fungible_asset::FungibleStore>>(_v10, _v13)) == _v5) break;
                _v13 = _v13 + 1
            };
            _v11 = true;
            _v12 = _v13;
            break
        };
        if (_v11) _v0 = *0x1::vector::borrow<object::Object<fungible_asset::FungibleStore>>(&_v9.stores, _v12) else {
            let _v15 = object::create_object_from_object(p0);
            let _v16 = fungible_asset::create_store<fungible_asset::Metadata>(&_v15, _v5);
            0x1::vector::push_back<object::Object<fungible_asset::FungibleStore>>(&mut _v9.stores, _v16);
            _v0 = _v16
        };
        let _v17 = dispatchable_fungible_asset::withdraw<fungible_asset::FungibleStore>(&_v3, _v0, p2);
        primary_fungible_store::deposit(p3, _v17);
    }
    public entry fun withdraw_temporary_token(p0: &signer, p1: object::Object<LiquidityPoolV3>, p2: object::Object<fungible_asset::Metadata>, p3: u64, p4: address)
        acquires LiquidityPoolV3, PoolTemporaryStorage
    {
        let _v0;
        let _v1 = string::utf8(vector[119u8, 105u8, 116u8, 104u8, 100u8, 114u8, 97u8, 119u8, 95u8, 116u8, 101u8, 109u8, 112u8, 111u8, 114u8, 97u8, 114u8, 121u8, 95u8, 116u8, 111u8, 107u8, 101u8, 110u8]);
        package_manager::assert_admin(p0, _v1);
        let _v2 = object::object_address<LiquidityPoolV3>(&p1);
        let _v3 = lp::get_signer(&borrow_global_mut<LiquidityPoolV3>(_v2).lp_token_refs);
        p0 = &_v3;
        let _v4 = p2;
        let _v5 = signer::address_of(p0);
        if (!exists<PoolTemporaryStorage>(_v5)) {
            let _v6 = PoolTemporaryStorage{stores: 0x1::vector::empty<object::Object<fungible_asset::FungibleStore>>()};
            move_to<PoolTemporaryStorage>(p0, _v6)
        };
        let _v7 = signer::address_of(p0);
        let _v8 = borrow_global_mut<PoolTemporaryStorage>(_v7);
        let _v9 = &_v8.stores;
        let _v10 = false;
        let _v11 = 0;
        let _v12 = 0;
        let _v13 = 0x1::vector::length<object::Object<fungible_asset::FungibleStore>>(_v9);
        'l0: loop {
            loop {
                if (!(_v12 < _v13)) break 'l0;
                if (fungible_asset::store_metadata<fungible_asset::FungibleStore>(*0x1::vector::borrow<object::Object<fungible_asset::FungibleStore>>(_v9, _v12)) == _v4) break;
                _v12 = _v12 + 1
            };
            _v10 = true;
            _v11 = _v12;
            break
        };
        if (_v10) _v0 = *0x1::vector::borrow<object::Object<fungible_asset::FungibleStore>>(&_v8.stores, _v11) else {
            let _v14 = object::create_object_from_object(p0);
            let _v15 = fungible_asset::create_store<fungible_asset::Metadata>(&_v14, _v4);
            0x1::vector::push_back<object::Object<fungible_asset::FungibleStore>>(&mut _v8.stores, _v15);
            _v0 = _v15
        };
        let _v16 = dispatchable_fungible_asset::withdraw<fungible_asset::FungibleStore>(&_v3, _v0, p3);
        primary_fungible_store::deposit(p4, _v16);
    }
}
