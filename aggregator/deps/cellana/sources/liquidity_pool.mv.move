module 0x4bf51972879e3b95c4781a5cdcb9e1ee24ef483e7d22f2d903626f126df62bd1::liquidity_pool {
    use 0x1::bcs;
    use 0x1::comparator;
    use 0x1::dispatchable_fungible_asset;
    use 0x1::error;
    use 0x1::event;
    use 0x1::fungible_asset;
    use 0x1::math128;
    use 0x1::math64;
    use 0x1::object;
    use 0x1::option;
    use 0x1::primary_fungible_store;
    use 0x1::signer;
    use 0x1::smart_table;
    use 0x1::smart_vector;
    use 0x1::string;
    use 0x1::vector;
    use 0x4bf51972879e3b95c4781a5cdcb9e1ee24ef483e7d22f2d903626f126df62bd1::coin_wrapper;
    use 0x4bf51972879e3b95c4781a5cdcb9e1ee24ef483e7d22f2d903626f126df62bd1::package_manager;
    friend 0x4bf51972879e3b95c4781a5cdcb9e1ee24ef483e7d22f2d903626f126df62bd1::gauge;
    friend 0x4bf51972879e3b95c4781a5cdcb9e1ee24ef483e7d22f2d903626f126df62bd1::rewards_pool;
    friend 0x4bf51972879e3b95c4781a5cdcb9e1ee24ef483e7d22f2d903626f126df62bd1::router;
    struct AddLiquidityEvent has drop, store {
        lp: address,
        pool: address,
        amount_1: u64,
        amount_2: u64,
    }
    struct ClaimFeesEvent has drop, store {
        pool: address,
        amount_1: u64,
        amount_2: u64,
    }
    struct CreatePoolEvent has drop, store {
        pool: object::Object<LiquidityPool>,
        token_1: string::String,
        token_2: string::String,
        is_stable: bool,
    }
    struct LiquidityPool has key {
        token_store_1: object::Object<fungible_asset::FungibleStore>,
        token_store_2: object::Object<fungible_asset::FungibleStore>,
        fees_store_1: object::Object<fungible_asset::FungibleStore>,
        fees_store_2: object::Object<fungible_asset::FungibleStore>,
        lp_token_refs: LPTokenRefs,
        swap_fee_bps: u64,
        is_stable: bool,
    }
    struct FeesAccounting has key {
        total_fees_1: u128,
        total_fees_2: u128,
        total_fees_at_last_claim_1: smart_table::SmartTable<address, u128>,
        total_fees_at_last_claim_2: smart_table::SmartTable<address, u128>,
        claimable_1: smart_table::SmartTable<address, u128>,
        claimable_2: smart_table::SmartTable<address, u128>,
    }
    struct LPTokenRefs has store {
        burn_ref: fungible_asset::BurnRef,
        mint_ref: fungible_asset::MintRef,
        transfer_ref: fungible_asset::TransferRef,
    }
    struct LiquidityPoolConfigs has key {
        all_pools: smart_vector::SmartVector<object::Object<LiquidityPool>>,
        is_paused: bool,
        fee_manager: address,
        pauser: address,
        pending_fee_manager: address,
        pending_pauser: address,
        stable_fee_bps: u64,
        volatile_fee_bps: u64,
    }
    struct RemoveLiquidityEvent has drop, store {
        lp: address,
        pool: address,
        amount_lp: u64,
        amount_1: u64,
        amount_2: u64,
    }
    struct SwapEvent has drop, store {
        pool: address,
        from_token: string::String,
        to_token: string::String,
        amount_in: u64,
        amount_out: u64,
    }
    struct SyncEvent has drop, store {
        pool: address,
        reserves_1: u128,
        reserves_2: u128,
    }
    struct TransferEvent has drop, store {
        pool: address,
        amount: u64,
        from: address,
        to: address,
    }
    public fun liquidity_pool(p0: object::Object<fungible_asset::Metadata>, p1: object::Object<fungible_asset::Metadata>, p2: bool): object::Object<LiquidityPool> {
        object::address_to_object<LiquidityPool>(liquidity_pool_address(p0, p1, p2))
    }
    friend fun swap(p0: object::Object<LiquidityPool>, p1: fungible_asset::FungibleAsset): fungible_asset::FungibleAsset
        acquires FeesAccounting, LiquidityPool, LiquidityPoolConfigs
    {
        let _v0;
        let _v1;
        let _v2;
        let _v3;
        let _v4;
        assert!(!*&borrow_global<LiquidityPoolConfigs>(@0x4bf51972879e3b95c4781a5cdcb9e1ee24ef483e7d22f2d903626f126df62bd1).is_paused, 5);
        let _v5 = fungible_asset::metadata_from_asset(&p1);
        let _v6 = fungible_asset::amount(&p1);
        let (_v7,_v8) = get_amount_out(p0, _v5, _v6);
        let _v9 = _v8;
        let _v10 = _v7;
        let _v11 = fungible_asset::extract(&mut p1, _v9);
        let _v12 = object::object_address<LiquidityPool>(&p0);
        let _v13 = borrow_global<LiquidityPool>(_v12);
        let _v14 = *&_v13.token_store_1;
        let _v15 = *&_v13.token_store_2;
        let _v16 = fungible_asset::decimals<fungible_asset::Metadata>(fungible_asset::store_metadata<fungible_asset::FungibleStore>(_v14));
        let _v17 = fungible_asset::decimals<fungible_asset::Metadata>(fungible_asset::store_metadata<fungible_asset::FungibleStore>(_v15));
        let _v18 = fungible_asset::balance<fungible_asset::FungibleStore>(_v14) as u256;
        let _v19 = fungible_asset::balance<fungible_asset::FungibleStore>(_v15) as u256;
        if (*&_v13.is_stable) {
            let (_v20,_v21) = standardize_reserve(_v18, _v19, _v16, _v17);
            _v4 = _v21;
            _v0 = _v20
        } else {
            _v4 = _v19;
            _v0 = _v18
        };
        let _v22 = *&_v13.is_stable;
        let _v23 = calculate_k(_v0, _v4, _v22);
        let _v24 = object::object_address<LiquidityPool>(&p0);
        let _v25 = borrow_global_mut<FeesAccounting>(_v24);
        let _v26 = package_manager::get_signer();
        let _v27 = &_v26;
        let _v28 = _v9 as u128;
        let _v29 = fungible_asset::store_metadata<fungible_asset::FungibleStore>(*&_v13.token_store_1);
        if (_v5 == _v29) {
            dispatchable_exact_deposit<fungible_asset::FungibleStore>(_v14, p1);
            dispatchable_exact_deposit<fungible_asset::FungibleStore>(*&_v13.fees_store_1, _v11);
            let _v30 = *&_v25.total_fees_1 + _v28;
            let _v31 = &mut _v25.total_fees_1;
            *_v31 = _v30;
            _v3 = dispatchable_exact_withdraw<fungible_asset::FungibleStore>(_v27, _v15, _v10)
        } else {
            dispatchable_exact_deposit<fungible_asset::FungibleStore>(_v15, p1);
            dispatchable_exact_deposit<fungible_asset::FungibleStore>(*&_v13.fees_store_2, _v11);
            let _v32 = *&_v25.total_fees_2 + _v28;
            let _v33 = &mut _v25.total_fees_2;
            *_v33 = _v32;
            _v3 = dispatchable_exact_withdraw<fungible_asset::FungibleStore>(_v27, _v14, _v10)
        };
        let _v34 = _v3;
        _v18 = fungible_asset::balance<fungible_asset::FungibleStore>(_v14) as u256;
        _v19 = fungible_asset::balance<fungible_asset::FungibleStore>(_v15) as u256;
        if (*&_v13.is_stable) {
            let (_v35,_v36) = standardize_reserve(_v18, _v19, _v16, _v17);
            _v1 = _v36;
            _v2 = _v35
        } else {
            _v1 = _v19;
            _v2 = _v18
        };
        let _v37 = *&_v13.is_stable;
        let _v38 = calculate_k(_v2, _v1, _v37);
        assert!(_v23 <= _v38, 6);
        let _v39 = object::object_address<LiquidityPool>(&p0);
        let _v40 = coin_wrapper::get_original(_v5);
        let _v41 = coin_wrapper::get_original(fungible_asset::metadata_from_asset(&_v34));
        event::emit<SwapEvent>(SwapEvent{pool: _v39, from_token: _v40, to_token: _v41, amount_in: _v6, amount_out: _v10});
        let _v42 = object::object_address<LiquidityPool>(&p0);
        let _v43 = fungible_asset::balance<fungible_asset::FungibleStore>(*&_v13.token_store_1) as u128;
        let _v44 = fungible_asset::balance<fungible_asset::FungibleStore>(*&_v13.token_store_2) as u128;
        event::emit<SyncEvent>(SyncEvent{pool: _v42, reserves_1: _v43, reserves_2: _v44});
        _v34
    }
    public fun is_stable(p0: object::Object<LiquidityPool>): bool
        acquires LiquidityPool
    {
        let _v0 = object::object_address<LiquidityPool>(&p0);
        *&borrow_global<LiquidityPool>(_v0).is_stable
    }
    public fun swap_fee_bps(p0: object::Object<LiquidityPool>): u64
        acquires LiquidityPool
    {
        let _v0 = object::object_address<LiquidityPool>(&p0);
        *&borrow_global<LiquidityPool>(_v0).swap_fee_bps
    }
    public entry fun accept_fee_manager(p0: &signer)
        acquires LiquidityPoolConfigs
    {
        let _v0 = borrow_global_mut<LiquidityPoolConfigs>(@0x4bf51972879e3b95c4781a5cdcb9e1ee24ef483e7d22f2d903626f126df62bd1);
        let _v1 = signer::address_of(p0);
        let _v2 = *&_v0.pending_fee_manager;
        assert!(_v1 == _v2, 4);
        let _v3 = *&_v0.pending_fee_manager;
        let _v4 = &mut _v0.fee_manager;
        *_v4 = _v3;
        let _v5 = &mut _v0.pending_fee_manager;
        *_v5 = @0x0;
    }
    public entry fun accept_pauser(p0: &signer)
        acquires LiquidityPoolConfigs
    {
        let _v0 = borrow_global_mut<LiquidityPoolConfigs>(@0x4bf51972879e3b95c4781a5cdcb9e1ee24ef483e7d22f2d903626f126df62bd1);
        let _v1 = signer::address_of(p0);
        let _v2 = *&_v0.pending_pauser;
        assert!(_v1 == _v2, 4);
        let _v3 = *&_v0.pending_pauser;
        let _v4 = &mut _v0.pauser;
        *_v4 = _v3;
        let _v5 = &mut _v0.pending_pauser;
        *_v5 = @0x0;
    }
    public fun all_pool_addresses(): vector<object::Object<LiquidityPool>>
        acquires LiquidityPoolConfigs
    {
        smart_vector::to_vector<object::Object<LiquidityPool>>(&borrow_global<LiquidityPoolConfigs>(@0x4bf51972879e3b95c4781a5cdcb9e1ee24ef483e7d22f2d903626f126df62bd1).all_pools)
    }
    friend fun burn(p0: &signer, p1: object::Object<fungible_asset::Metadata>, p2: object::Object<fungible_asset::Metadata>, p3: bool, p4: u64): (fungible_asset::FungibleAsset, fungible_asset::FungibleAsset)
        acquires LiquidityPool
    {
        let _v0;
        assert!(p4 > 0, 1);
        let _v1 = signer::address_of(p0);
        let _v2 = liquidity_pool(p1, p2, p3);
        let _v3 = ensure_lp_token_store<LiquidityPool>(_v1, _v2);
        let (_v4,_v5) = liquidity_amounts(_v2, p4);
        let _v6 = _v5;
        let _v7 = _v4;
        if (_v7 > 0) _v0 = _v6 > 0 else _v0 = false;
        assert!(_v0, 3);
        let _v8 = object::object_address<LiquidityPool>(&_v2);
        let _v9 = borrow_global<LiquidityPool>(_v8);
        fungible_asset::burn_from<fungible_asset::FungibleStore>(&(&_v9.lp_token_refs).burn_ref, _v3, p4);
        let _v10 = package_manager::get_signer();
        let _v11 = &_v10;
        let _v12 = *&_v9.token_store_1;
        let _v13 = dispatchable_fungible_asset::withdraw<fungible_asset::FungibleStore>(_v11, _v12, _v7);
        let _v14 = *&_v9.token_store_2;
        let _v15 = dispatchable_fungible_asset::withdraw<fungible_asset::FungibleStore>(_v11, _v14, _v6);
        if (!is_sorted(p1, p2)) {
            let _v16 = _v15;
            _v15 = _v13;
            _v13 = _v16
        };
        let _v17 = object::object_address<LiquidityPool>(&_v2);
        event::emit<RemoveLiquidityEvent>(RemoveLiquidityEvent{lp: _v1, pool: _v17, amount_lp: p4, amount_1: _v7, amount_2: _v6});
        let _v18 = object::object_address<LiquidityPool>(&_v2);
        let _v19 = fungible_asset::balance<fungible_asset::FungibleStore>(*&_v9.token_store_1) as u128;
        let _v20 = fungible_asset::balance<fungible_asset::FungibleStore>(*&_v9.token_store_2) as u128;
        event::emit<SyncEvent>(SyncEvent{pool: _v18, reserves_1: _v19, reserves_2: _v20});
        (_v13, _v15)
    }
    fun calculate_constant_k(p0: &LiquidityPool): u256 {
        let _v0;
        let _v1 = fungible_asset::balance<fungible_asset::FungibleStore>(*&p0.token_store_1) as u256;
        let _v2 = fungible_asset::balance<fungible_asset::FungibleStore>(*&p0.token_store_2) as u256;
        if (*&p0.is_stable) {
            let _v3 = _v1 * _v1 * _v1 * _v2;
            let _v4 = _v2 * _v2 * _v2 * _v1;
            _v0 = _v3 + _v4
        } else _v0 = _v1 * _v2;
        _v0
    }
    fun calculate_k(p0: u256, p1: u256, p2: bool): u256 {
        let _v0;
        if (p2) {
            let _v1 = p0 * p0 * p0 * p1;
            let _v2 = p1 * p1 * p1 * p0;
            _v0 = _v1 + _v2
        } else _v0 = p0 * p1;
        _v0
    }
    friend fun claim_fees(p0: &signer, p1: object::Object<LiquidityPool>): (fungible_asset::FungibleAsset, fungible_asset::FungibleAsset)
        acquires LiquidityPool
    {
        let _v0;
        let _v1;
        let (_v2,_v3) = gauge_claimable_fees(p1);
        let _v4 = _v3;
        let _v5 = _v2;
        let _v6 = object::object_address<LiquidityPool>(&p1);
        let _v7 = borrow_global<LiquidityPool>(_v6);
        let _v8 = package_manager::get_signer();
        let _v9 = &_v8;
        if (_v5 > 0) {
            let _v10 = *&_v7.fees_store_1;
            _v1 = dispatchable_fungible_asset::withdraw<fungible_asset::FungibleStore>(_v9, _v10, _v5)
        } else _v1 = fungible_asset::zero<fungible_asset::Metadata>(fungible_asset::store_metadata<fungible_asset::FungibleStore>(*&_v7.fees_store_1));
        if (_v4 > 0) {
            let _v11 = *&_v7.fees_store_2;
            _v0 = dispatchable_fungible_asset::withdraw<fungible_asset::FungibleStore>(_v9, _v11, _v4)
        } else _v0 = fungible_asset::zero<fungible_asset::Metadata>(fungible_asset::store_metadata<fungible_asset::FungibleStore>(*&_v7.fees_store_2));
        let _v12 = object::object_address<LiquidityPool>(&p1);
        let _v13 = _v5 as u64;
        let _v14 = _v4 as u64;
        event::emit<ClaimFeesEvent>(ClaimFeesEvent{pool: _v12, amount_1: _v13, amount_2: _v14});
        (_v1, _v0)
    }
    public fun claimable_fees(p0: address, p1: object::Object<LiquidityPool>): (u128, u128) {
        abort 0
    }
    friend fun create(p0: object::Object<fungible_asset::Metadata>, p1: object::Object<fungible_asset::Metadata>, p2: bool): object::Object<LiquidityPool>
        acquires LiquidityPoolConfigs
    {
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
        let _v10 = !is_sorted(p0, p1);
        loop {
            if (!_v10) {
                _v0 = borrow_global_mut<LiquidityPoolConfigs>(@0x4bf51972879e3b95c4781a5cdcb9e1ee24ef483e7d22f2d903626f126df62bd1);
                let _v11 = p1;
                let _v12 = p0;
                let _v13 = lp_token_name(_v12, _v11);
                let _v14 = p2;
                let _v15 = _v11;
                let _v16 = _v12;
                let _v17 = vector[];
                let _v18 = &mut _v17;
                let _v19 = object::object_address<fungible_asset::Metadata>(&_v16);
                let _v20 = bcs::to_bytes<address>(&_v19);
                vector::append<u8>(_v18, _v20);
                let _v21 = &mut _v17;
                let _v22 = object::object_address<fungible_asset::Metadata>(&_v15);
                let _v23 = bcs::to_bytes<address>(&_v22);
                vector::append<u8>(_v21, _v23);
                let _v24 = &mut _v17;
                let _v25 = bcs::to_bytes<bool>(&_v14);
                vector::append<u8>(_v24, _v25);
                let _v26 = package_manager::get_signer();
                let _v27 = object::create_named_object(&_v26, _v17);
                let _v28 = &_v27;
                let _v29 = option::none<u128>();
                let _v30 = string::utf8(vector[76u8, 80u8]);
                let _v31 = string::utf8(vector[]);
                let _v32 = string::utf8(vector[]);
                primary_fungible_store::create_primary_store_enabled_fungible_asset(_v28, _v29, _v13, _v30, 8u8, _v31, _v32);
                let _v33 = _v28;
                let _v34 = object::generate_signer(_v33);
                _v2 = &_v34;
                _v3 = object::object_from_constructor_ref<fungible_asset::Metadata>(_v33);
                let _v35 = fungible_asset::create_store<fungible_asset::Metadata>(_v33, _v3);
                _v4 = _v2;
                _v6 = create_token_store(_v2, p0);
                _v7 = create_token_store(_v2, p1);
                _v8 = create_token_store(_v2, p0);
                _v9 = create_token_store(_v2, p1);
                let _v36 = _v33;
                let _v37 = fungible_asset::generate_burn_ref(_v36);
                let _v38 = fungible_asset::generate_mint_ref(_v36);
                let _v39 = fungible_asset::generate_transfer_ref(_v36);
                _v5 = LPTokenRefs{burn_ref: _v37, mint_ref: _v38, transfer_ref: _v39};
                if (p2) {
                    _v1 = *&_v0.stable_fee_bps;
                    break
                };
                _v1 = *&_v0.volatile_fee_bps;
                break
            };
            return create(p1, p0, p2)
        };
        let _v40 = LiquidityPool{token_store_1: _v6, token_store_2: _v7, fees_store_1: _v8, fees_store_2: _v9, lp_token_refs: _v5, swap_fee_bps: _v1, is_stable: p2};
        move_to<LiquidityPool>(_v4, _v40);
        let _v41 = smart_table::new<address, u128>();
        let _v42 = smart_table::new<address, u128>();
        let _v43 = smart_table::new<address, u128>();
        let _v44 = smart_table::new<address, u128>();
        let _v45 = FeesAccounting{total_fees_1: 0u128, total_fees_2: 0u128, total_fees_at_last_claim_1: _v41, total_fees_at_last_claim_2: _v42, claimable_1: _v43, claimable_2: _v44};
        move_to<FeesAccounting>(_v2, _v45);
        let _v46 = object::convert<fungible_asset::Metadata, LiquidityPool>(_v3);
        smart_vector::push_back<object::Object<LiquidityPool>>(&mut _v0.all_pools, _v46);
        let _v47 = coin_wrapper::get_original(p0);
        let _v48 = coin_wrapper::get_original(p1);
        event::emit<CreatePoolEvent>(CreatePoolEvent{pool: _v46, token_1: _v47, token_2: _v48, is_stable: p2});
        _v46
    }
    fun create_token_store(p0: &signer, p1: object::Object<fungible_asset::Metadata>): object::Object<fungible_asset::FungibleStore> {
        let _v0 = object::create_object_from_object(p0);
        fungible_asset::create_store<fungible_asset::Metadata>(&_v0, p1)
    }
    friend fun deposit_fungible_asset<T0: key>(p0: object::Object<T0>, p1: fungible_asset::FungibleAsset): u64 {
        let _v0 = fungible_asset::balance<T0>(p0);
        dispatchable_fungible_asset::deposit<T0>(p0, p1);
        fungible_asset::balance<T0>(p0) - _v0
    }
    friend fun dispatchable_exact_deposit<T0: key>(p0: object::Object<T0>, p1: fungible_asset::FungibleAsset) {
        let _v0 = fungible_asset::amount(&p1);
        let _v1 = deposit_fungible_asset<T0>(p0, p1);
        assert!(_v0 == _v1, 11);
    }
    friend fun dispatchable_exact_withdraw<T0: key>(p0: &signer, p1: object::Object<T0>, p2: u64): fungible_asset::FungibleAsset {
        let _v0 = dispatchable_fungible_asset::withdraw<T0>(p0, p1, p2);
        assert!(fungible_asset::amount(&_v0) == p2, 11);
        _v0
    }
    fun ensure_lp_token_store<T0: key>(p0: address, p1: object::Object<T0>): object::Object<fungible_asset::FungibleStore>
        acquires LiquidityPool
    {
        let _v0 = primary_fungible_store::ensure_primary_store_exists<T0>(p0, p1);
        let _v1 = primary_fungible_store::primary_store<T0>(p0, p1);
        if (!fungible_asset::is_frozen<fungible_asset::FungibleStore>(_v1)) {
            let _v2 = object::object_address<T0>(&p1);
            fungible_asset::set_frozen_flag<fungible_asset::FungibleStore>(&(&borrow_global<LiquidityPool>(_v2).lp_token_refs).transfer_ref, _v1, true)
        };
        _v1
    }
    public fun gauge_claimable_fees(p0: object::Object<LiquidityPool>): (u64, u64)
        acquires LiquidityPool
    {
        let _v0 = object::object_address<LiquidityPool>(&p0);
        let _v1 = borrow_global<LiquidityPool>(_v0);
        let _v2 = fungible_asset::balance<fungible_asset::FungibleStore>(*&_v1.fees_store_1);
        let _v3 = fungible_asset::balance<fungible_asset::FungibleStore>(*&_v1.fees_store_2);
        (_v2, _v3)
    }
    public fun get_amount_out(p0: object::Object<LiquidityPool>, p1: object::Object<fungible_asset::Metadata>, p2: u64): (u64, u64)
        acquires LiquidityPool
    {
        let _v0;
        let _v1;
        let _v2;
        let _v3;
        let _v4;
        let _v5;
        let (_v6,_v7,_v8,_v9,_v10,_v11) = pool_metadata(p0);
        let _v12 = _v11;
        let _v13 = _v10;
        let _v14 = _v6;
        let _v15 = object::object_address<LiquidityPool>(&p0);
        let _v16 = borrow_global<LiquidityPool>(_v15);
        if (p1 == _v14) _v5 = true else _v5 = p1 == _v7;
        assert!(_v5, 10);
        let _v17 = _v8 as u256;
        let _v18 = _v9 as u256;
        let _v19 = _v17;
        if (p1 == _v14) {
            _v1 = _v12;
            _v2 = _v13;
            _v3 = _v18;
            _v4 = _v19
        } else {
            _v1 = _v13;
            _v2 = _v12;
            _v3 = _v19;
            _v4 = _v18
        };
        let _v20 = _v1;
        let _v21 = _v2;
        let _v22 = _v3;
        let _v23 = _v4;
        let _v24 = *&_v16.swap_fee_bps;
        let _v25 = 10000 - _v24;
        let _v26 = 10000;
        if (!(_v26 != 0)) {
            let _v27 = error::invalid_argument(4);
            abort _v27
        };
        let _v28 = p2 as u128;
        let _v29 = _v25 as u128;
        let _v30 = _v28 * _v29;
        let _v31 = _v26 as u128;
        let _v32 = (_v30 / _v31) as u64;
        let _v33 = p2 - _v32;
        let _v34 = _v32 as u256;
        if (*&_v16.is_stable) {
            let (_v35,_v36) = standardize_reserve(_v23, _v22, _v21, _v20);
            _v22 = _v36;
            _v23 = _v35;
            let _v37 = _v21 as u128;
            let _v38 = math128::pow(10u128, _v37);
            let _v39 = _v20 as u128;
            let _v40 = math128::pow(10u128, _v39);
            let _v41 = _v34 as u128;
            let _v42 = _v38;
            if (_v42 != 0u128) {
                let _v43 = _v41 as u256;
                let _v44 = (100000000 as u128) as u256;
                let _v45 = _v43 * _v44;
                let _v46 = _v42 as u256;
                _v34 = ((_v45 / _v46) as u128) as u256;
                let _v47 = *&_v16.is_stable;
                let _v48 = calculate_k(_v23, _v22, _v47);
                let _v49 = get_y(_v34 + _v23, _v48, _v22);
                let _v50 = (_v22 - _v49) as u128;
                let _v51 = 100000000 as u128;
                if (_v51 != 0u128) {
                    let _v52 = _v50 as u256;
                    let _v53 = _v40 as u256;
                    let _v54 = _v52 * _v53;
                    let _v55 = _v51 as u256;
                    _v0 = ((_v54 / _v55) as u128) as u256
                } else {
                    let _v56 = error::invalid_argument(4);
                    abort _v56
                }
            } else {
                let _v57 = error::invalid_argument(4);
                abort _v57
            }
        } else {
            let _v58 = _v34 * _v22;
            let _v59 = _v23 + _v34;
            _v0 = _v58 / _v59
        };
        (_v0 as u64, _v33)
    }
    public fun get_trade_diff(p0: object::Object<LiquidityPool>, p1: object::Object<fungible_asset::Metadata>, p2: u64): (u64, u64)
        acquires LiquidityPool
    {
        let _v0;
        let _v1;
        let (_v2,_v3,_v4,_v5,_v6,_v7) = pool_metadata(p0);
        let _v8 = _v7;
        let _v9 = _v6;
        let _v10 = _v5;
        let _v11 = _v4;
        let _v12 = _v2;
        if (p1 == _v12) _v1 = _v9 as u64 else _v1 = _v8 as u64;
        let _v13 = _v1;
        if (p1 == _v12) {
            let _v14 = _v8 as u64;
            let _v15 = math64::pow(10, _v14);
            let _v16 = _v10;
            if (!(_v16 != 0)) {
                let _v17 = error::invalid_argument(4);
                abort _v17
            };
            let _v18 = _v11 as u128;
            let _v19 = _v15 as u128;
            let _v20 = _v18 * _v19;
            let _v21 = _v16 as u128;
            _v0 = (_v20 / _v21) as u64
        } else {
            let _v22 = _v9 as u64;
            let _v23 = math64::pow(10, _v22);
            let _v24 = _v11;
            if (_v24 != 0) {
                let _v25 = _v10 as u128;
                let _v26 = _v23 as u128;
                let _v27 = _v25 * _v26;
                let _v28 = _v24 as u128;
                _v0 = (_v27 / _v28) as u64
            } else {
                let _v29 = error::invalid_argument(4);
                abort _v29
            }
        };
        let _v30 = _v0;
        let (_v31,_v32) = get_amount_out(p0, p1, _v30);
        let _v33 = math64::pow(10, _v13);
        let _v34 = _v30;
        if (!(_v34 != 0)) {
            let _v35 = error::invalid_argument(4);
            abort _v35
        };
        let _v36 = _v31 as u128;
        let _v37 = _v33 as u128;
        let _v38 = _v36 * _v37;
        let _v39 = _v34 as u128;
        let _v40 = (_v38 / _v39) as u64;
        let (_v41,_v42) = get_amount_out(p0, p1, p2);
        let _v43 = math64::pow(10, _v13);
        let _v44 = p2;
        if (!(_v44 != 0)) {
            let _v45 = error::invalid_argument(4);
            abort _v45
        };
        let _v46 = _v41 as u128;
        let _v47 = _v43 as u128;
        let _v48 = _v46 * _v47;
        let _v49 = _v44 as u128;
        let _v50 = (_v48 / _v49) as u64;
        (_v40, _v50)
    }
    fun get_y(p0: u256, p1: u256, p2: u256): u256 {
        let _v0 = 0;
        'l0: loop {
            'l2: loop {
                'l1: loop {
                    if (!(_v0 < 255)) break 'l0;
                    let _v1 = p2;
                    let _v2 = p2;
                    let _v3 = p0;
                    let _v4 = _v2 * _v2 * _v2;
                    let _v5 = _v3 * _v4;
                    let _v6 = _v3 * _v3 * _v3 * _v2;
                    let _v7 = _v5 + _v6;
                    if (_v7 < p1) {
                        let _v8 = p2;
                        let _v9 = p0;
                        let _v10 = p1 - _v7;
                        let _v11 = 3u256 * _v9;
                        let _v12 = _v8 * _v8;
                        let _v13 = _v11 * _v12;
                        let _v14 = _v9 * _v9 * _v9;
                        let _v15 = _v13 + _v14;
                        let _v16 = _v10 / _v15;
                        p2 = p2 + _v16
                    } else {
                        let _v17 = p2;
                        let _v18 = p0;
                        let _v19 = _v7 - p1;
                        let _v20 = 3u256 * _v18;
                        let _v21 = _v17 * _v17;
                        let _v22 = _v20 * _v21;
                        let _v23 = _v18 * _v18 * _v18;
                        let _v24 = _v22 + _v23;
                        let _v25 = _v19 / _v24;
                        p2 = p2 - _v25
                    };
                    loop {
                        if (p2 > _v1) {
                            if (!(p2 - _v1 <= 1u256)) break;
                            break 'l1
                        };
                        if (!(_v1 - p2 <= 1u256)) break;
                        break 'l2
                    };
                    _v0 = _v0 + 1;
                    continue
                };
                return p2
            };
            return p2
        };
        p2
    }
    public entry fun initialize() {
        if (is_initialized()) return ();
        coin_wrapper::initialize();
        let _v0 = package_manager::get_signer();
        let _v1 = &_v0;
        let _v2 = LiquidityPoolConfigs{all_pools: smart_vector::new<object::Object<LiquidityPool>>(), is_paused: false, fee_manager: @0xf2b948595bd7e12856942016544da14aca954dd182b3987466205a61843fb17c, pauser: @0xf2b948595bd7e12856942016544da14aca954dd182b3987466205a61843fb17c, pending_fee_manager: @0x0, pending_pauser: @0x0, stable_fee_bps: 4, volatile_fee_bps: 10};
        move_to<LiquidityPoolConfigs>(_v1, _v2);
    }
    public fun is_initialized(): bool {
        exists<LiquidityPoolConfigs>(@0x4bf51972879e3b95c4781a5cdcb9e1ee24ef483e7d22f2d903626f126df62bd1)
    }
    public fun is_sorted(p0: object::Object<fungible_asset::Metadata>, p1: object::Object<fungible_asset::Metadata>): bool {
        assert!(p0 != p1, 9);
        let _v0 = object::object_address<fungible_asset::Metadata>(&p0);
        let _v1 = object::object_address<fungible_asset::Metadata>(&p1);
        let _v2 = &_v0;
        let _v3 = &_v1;
        let _v4 = comparator::compare<address>(_v2, _v3);
        comparator::is_smaller_than(&_v4)
    }
    public fun liquidity_amounts(p0: object::Object<LiquidityPool>, p1: u64): (u64, u64)
        acquires LiquidityPool
    {
        let _v0 = option::destroy_some<u128>(fungible_asset::supply<LiquidityPool>(p0));
        let _v1 = object::object_address<LiquidityPool>(&p0);
        let _v2 = borrow_global<LiquidityPool>(_v1);
        let _v3 = *&_v2.token_store_1;
        let _v4 = *&_v2.token_store_2;
        let _v5 = fungible_asset::balance<fungible_asset::FungibleStore>(_v3);
        let _v6 = fungible_asset::balance<fungible_asset::FungibleStore>(_v4);
        let _v7 = p1 as u128;
        let _v8 = _v5 as u128;
        let _v9 = _v0;
        if (!(_v9 != 0u128)) {
            let _v10 = error::invalid_argument(4);
            abort _v10
        };
        let _v11 = _v7 as u256;
        let _v12 = _v8 as u256;
        let _v13 = _v11 * _v12;
        let _v14 = _v9 as u256;
        let _v15 = ((_v13 / _v14) as u128) as u64;
        let _v16 = p1 as u128;
        let _v17 = _v6 as u128;
        let _v18 = _v0;
        if (!(_v18 != 0u128)) {
            let _v19 = error::invalid_argument(4);
            abort _v19
        };
        let _v20 = _v16 as u256;
        let _v21 = _v17 as u256;
        let _v22 = _v20 * _v21;
        let _v23 = _v18 as u256;
        let _v24 = ((_v22 / _v23) as u128) as u64;
        (_v15, _v24)
    }
    public fun liquidity_out(p0: object::Object<fungible_asset::Metadata>, p1: object::Object<fungible_asset::Metadata>, p2: bool, p3: u64, p4: u64): u64
        acquires LiquidityPool
    {
        let _v0;
        let _v1 = !is_sorted(p0, p1);
        loop {
            if (!_v1) {
                let _v2 = liquidity_pool(p0, p1, p2);
                let _v3 = object::object_address<LiquidityPool>(&_v2);
                let _v4 = borrow_global<LiquidityPool>(_v3);
                let _v5 = *&_v4.token_store_1;
                let _v6 = *&_v4.token_store_2;
                let _v7 = fungible_asset::balance<fungible_asset::FungibleStore>(_v5);
                let _v8 = fungible_asset::balance<fungible_asset::FungibleStore>(_v6);
                let _v9 = option::destroy_some<u128>(fungible_asset::supply<LiquidityPool>(_v2));
                if (_v9 == 0u128) {
                    let _v10 = p3 as u128;
                    let _v11 = p4 as u128;
                    _v0 = (math128::sqrt(_v10 * _v11) as u64) - 1000;
                    break
                };
                let _v12 = _v9 as u64;
                let _v13 = _v7;
                if (!(_v13 != 0)) {
                    let _v14 = error::invalid_argument(4);
                    abort _v14
                };
                let _v15 = p3 as u128;
                let _v16 = _v12 as u128;
                let _v17 = _v15 * _v16;
                let _v18 = _v13 as u128;
                let _v19 = (_v17 / _v18) as u64;
                let _v20 = _v9 as u64;
                let _v21 = _v8;
                if (!(_v21 != 0)) {
                    let _v22 = error::invalid_argument(4);
                    abort _v22
                };
                let _v23 = p4 as u128;
                let _v24 = _v20 as u128;
                let _v25 = _v23 * _v24;
                let _v26 = _v21 as u128;
                let _v27 = (_v25 / _v26) as u64;
                _v0 = math64::min(_v19, _v27);
                break
            };
            return liquidity_out(p1, p0, p2, p4, p3)
        };
        _v0
    }
    public fun liquidity_pool_address(p0: object::Object<fungible_asset::Metadata>, p1: object::Object<fungible_asset::Metadata>, p2: bool): address {
        if (!is_sorted(p0, p1)) return liquidity_pool_address(p1, p0, p2);
        let _v0 = @0x4bf51972879e3b95c4781a5cdcb9e1ee24ef483e7d22f2d903626f126df62bd1;
        let _v1 = &_v0;
        let _v2 = p2;
        let _v3 = p1;
        let _v4 = p0;
        let _v5 = vector[];
        let _v6 = &mut _v5;
        let _v7 = object::object_address<fungible_asset::Metadata>(&_v4);
        let _v8 = bcs::to_bytes<address>(&_v7);
        vector::append<u8>(_v6, _v8);
        let _v9 = &mut _v5;
        let _v10 = object::object_address<fungible_asset::Metadata>(&_v3);
        let _v11 = bcs::to_bytes<address>(&_v10);
        vector::append<u8>(_v9, _v11);
        let _v12 = &mut _v5;
        let _v13 = bcs::to_bytes<bool>(&_v2);
        vector::append<u8>(_v12, _v13);
        object::create_object_address(_v1, _v5)
    }
    fun lp_token_name(p0: object::Object<fungible_asset::Metadata>, p1: object::Object<fungible_asset::Metadata>): string::String {
        let _v0 = string::utf8(vector[76u8, 80u8, 45u8]);
        let _v1 = &mut _v0;
        let _v2 = fungible_asset::symbol<fungible_asset::Metadata>(p0);
        string::append(_v1, _v2);
        string::append_utf8(&mut _v0, vector[45u8]);
        let _v3 = &mut _v0;
        let _v4 = fungible_asset::symbol<fungible_asset::Metadata>(p1);
        string::append(_v3, _v4);
        _v0
    }
    public fun lp_token_supply<T0: key>(p0: object::Object<T0>): u128 {
        option::destroy_some<u128>(fungible_asset::supply<T0>(p0))
    }
    public fun min_liquidity(): u64 {
        1000
    }
    public fun mint(p0: &signer, p1: fungible_asset::FungibleAsset, p2: fungible_asset::FungibleAsset, p3: bool) {
        abort 0
    }
    friend fun mint_lp(p0: &signer, p1: fungible_asset::FungibleAsset, p2: fungible_asset::FungibleAsset, p3: bool): u64
        acquires LiquidityPool
    {
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
        let _v10 = fungible_asset::metadata_from_asset(&p1);
        let _v11 = fungible_asset::metadata_from_asset(&p2);
        let _v12 = !is_sorted(_v10, _v11);
        loop {
            if (!_v12) {
                let _v13;
                let _v14;
                _v3 = liquidity_pool(_v10, _v11, p3);
                _v0 = signer::address_of(p0);
                _v8 = ensure_lp_token_store<LiquidityPool>(_v0, _v3);
                _v7 = fungible_asset::amount(&p1);
                _v5 = fungible_asset::amount(&p2);
                if (_v7 > 0) _v14 = _v5 > 0 else _v14 = false;
                assert!(_v14, 1);
                let _v15 = object::object_address<LiquidityPool>(&_v3);
                _v2 = borrow_global<LiquidityPool>(_v15);
                _v1 = *&_v2.token_store_1;
                _v9 = *&_v2.token_store_2;
                let _v16 = fungible_asset::balance<fungible_asset::FungibleStore>(_v1);
                let _v17 = fungible_asset::balance<fungible_asset::FungibleStore>(_v9);
                let _v18 = option::destroy_some<u128>(fungible_asset::supply<LiquidityPool>(_v3));
                _v4 = &(&_v2.lp_token_refs).mint_ref;
                if (_v18 == 0u128) {
                    let _v19 = _v7 as u128;
                    let _v20 = _v5 as u128;
                    let _v21 = math128::sqrt(_v19 * _v20) as u64;
                    fungible_asset::mint_to<LiquidityPool>(_v4, _v3, 1000);
                    _v13 = _v21 - 1000
                } else {
                    let _v22 = _v18 as u64;
                    let _v23 = _v16;
                    if (_v23 != 0) {
                        let _v24 = _v7 as u128;
                        let _v25 = _v22 as u128;
                        let _v26 = _v24 * _v25;
                        let _v27 = _v23 as u128;
                        let _v28 = (_v26 / _v27) as u64;
                        let _v29 = _v18 as u64;
                        let _v30 = _v17;
                        if (_v30 != 0) {
                            let _v31 = _v5 as u128;
                            let _v32 = _v29 as u128;
                            let _v33 = _v31 * _v32;
                            let _v34 = _v30 as u128;
                            let _v35 = (_v33 / _v34) as u64;
                            _v13 = math64::min(_v28, _v35)
                        } else {
                            let _v36 = error::invalid_argument(4);
                            abort _v36
                        }
                    } else {
                        let _v37 = error::invalid_argument(4);
                        abort _v37
                    }
                };
                _v6 = _v13;
                if (_v6 > 0) break;
                abort 2
            };
            return mint_lp(p0, p2, p1, p3)
        };
        dispatchable_exact_deposit<fungible_asset::FungibleStore>(_v1, p1);
        dispatchable_exact_deposit<fungible_asset::FungibleStore>(_v9, p2);
        let _v38 = fungible_asset::mint(_v4, _v6);
        let _v39 = fungible_asset::amount(&_v38);
        fungible_asset::deposit_with_ref<fungible_asset::FungibleStore>(&(&_v2.lp_token_refs).transfer_ref, _v8, _v38);
        let _v40 = object::object_address<LiquidityPool>(&_v3);
        event::emit<AddLiquidityEvent>(AddLiquidityEvent{lp: _v0, pool: _v40, amount_1: _v7, amount_2: _v5});
        let _v41 = object::object_address<LiquidityPool>(&_v3);
        let _v42 = fungible_asset::balance<fungible_asset::FungibleStore>(*&_v2.token_store_1) as u128;
        let _v43 = fungible_asset::balance<fungible_asset::FungibleStore>(*&_v2.token_store_2) as u128;
        event::emit<SyncEvent>(SyncEvent{pool: _v41, reserves_1: _v42, reserves_2: _v43});
        _v39
    }
    public fun pool_metadata(p0: object::Object<LiquidityPool>): (object::Object<fungible_asset::Metadata>, object::Object<fungible_asset::Metadata>, u64, u64, u8, u8)
        acquires LiquidityPool
    {
        let _v0 = object::object_address<LiquidityPool>(&p0);
        let _v1 = borrow_global<LiquidityPool>(_v0);
        let _v2 = fungible_asset::store_metadata<fungible_asset::FungibleStore>(*&_v1.token_store_1);
        let _v3 = fungible_asset::store_metadata<fungible_asset::FungibleStore>(*&_v1.token_store_2);
        let _v4 = fungible_asset::balance<fungible_asset::FungibleStore>(*&_v1.token_store_1);
        let _v5 = fungible_asset::balance<fungible_asset::FungibleStore>(*&_v1.token_store_2);
        let _v6 = fungible_asset::decimals<fungible_asset::Metadata>(_v2);
        let _v7 = fungible_asset::decimals<fungible_asset::Metadata>(_v3);
        (_v2, _v3, _v4, _v5, _v6, _v7)
    }
    public fun pool_reserve(p0: &LiquidityPool): (u64, u64, u8, u8) {
        let _v0 = fungible_asset::store_metadata<fungible_asset::FungibleStore>(*&p0.token_store_1);
        let _v1 = fungible_asset::store_metadata<fungible_asset::FungibleStore>(*&p0.token_store_2);
        let _v2 = fungible_asset::balance<fungible_asset::FungibleStore>(*&p0.token_store_1);
        let _v3 = fungible_asset::balance<fungible_asset::FungibleStore>(*&p0.token_store_2);
        let _v4 = fungible_asset::decimals<fungible_asset::Metadata>(_v0);
        let _v5 = fungible_asset::decimals<fungible_asset::Metadata>(_v1);
        (_v2, _v3, _v4, _v5)
    }
    public fun pool_reserves<T0: key>(p0: object::Object<T0>): (u64, u64)
        acquires LiquidityPool
    {
        let _v0 = object::object_address<T0>(&p0);
        let _v1 = borrow_global<LiquidityPool>(_v0);
        let _v2 = fungible_asset::balance<fungible_asset::FungibleStore>(*&_v1.token_store_1);
        let _v3 = fungible_asset::balance<fungible_asset::FungibleStore>(*&_v1.token_store_2);
        (_v2, _v3)
    }
    public entry fun set_fee_manager(p0: &signer, p1: address)
        acquires LiquidityPoolConfigs
    {
        let _v0 = borrow_global_mut<LiquidityPoolConfigs>(@0x4bf51972879e3b95c4781a5cdcb9e1ee24ef483e7d22f2d903626f126df62bd1);
        let _v1 = signer::address_of(p0);
        let _v2 = *&_v0.fee_manager;
        assert!(_v1 == _v2, 4);
        let _v3 = &mut _v0.pending_fee_manager;
        *_v3 = p1;
    }
    public entry fun set_pause(p0: &signer, p1: bool)
        acquires LiquidityPoolConfigs
    {
        let _v0 = borrow_global_mut<LiquidityPoolConfigs>(@0x4bf51972879e3b95c4781a5cdcb9e1ee24ef483e7d22f2d903626f126df62bd1);
        let _v1 = signer::address_of(p0);
        let _v2 = *&_v0.pauser;
        assert!(_v1 == _v2, 4);
        let _v3 = &mut _v0.is_paused;
        *_v3 = p1;
    }
    public entry fun set_pauser(p0: &signer, p1: address)
        acquires LiquidityPoolConfigs
    {
        let _v0 = borrow_global_mut<LiquidityPoolConfigs>(@0x4bf51972879e3b95c4781a5cdcb9e1ee24ef483e7d22f2d903626f126df62bd1);
        let _v1 = signer::address_of(p0);
        let _v2 = *&_v0.pauser;
        assert!(_v1 == _v2, 4);
        let _v3 = &mut _v0.pending_pauser;
        *_v3 = p1;
    }
    public entry fun set_pool_swap_fee(p0: &signer, p1: object::Object<LiquidityPool>, p2: u64)
        acquires LiquidityPool, LiquidityPoolConfigs
    {
        assert!(p2 <= 30, 8);
        let _v0 = borrow_global_mut<LiquidityPoolConfigs>(@0x4bf51972879e3b95c4781a5cdcb9e1ee24ef483e7d22f2d903626f126df62bd1);
        let _v1 = signer::address_of(p0);
        let _v2 = *&_v0.fee_manager;
        assert!(_v1 == _v2, 4);
        let _v3 = object::object_address<LiquidityPool>(&p1);
        let _v4 = &mut borrow_global_mut<LiquidityPool>(_v3).swap_fee_bps;
        *_v4 = p2;
    }
    public entry fun set_stable_fee(p0: &signer, p1: u64)
        acquires LiquidityPoolConfigs
    {
        assert!(p1 <= 30, 8);
        let _v0 = borrow_global_mut<LiquidityPoolConfigs>(@0x4bf51972879e3b95c4781a5cdcb9e1ee24ef483e7d22f2d903626f126df62bd1);
        let _v1 = signer::address_of(p0);
        let _v2 = *&_v0.fee_manager;
        assert!(_v1 == _v2, 4);
        let _v3 = &mut _v0.stable_fee_bps;
        *_v3 = p1;
    }
    public entry fun set_volatile_fee(p0: &signer, p1: u64)
        acquires LiquidityPoolConfigs
    {
        assert!(p1 <= 30, 8);
        let _v0 = borrow_global_mut<LiquidityPoolConfigs>(@0x4bf51972879e3b95c4781a5cdcb9e1ee24ef483e7d22f2d903626f126df62bd1);
        let _v1 = signer::address_of(p0);
        let _v2 = *&_v0.fee_manager;
        assert!(_v1 == _v2, 4);
        let _v3 = &mut _v0.volatile_fee_bps;
        *_v3 = p1;
    }
    fun standardize_reserve(p0: u256, p1: u256, p2: u8, p3: u8): (u256, u256) {
        let _v0 = p2 as u128;
        let _v1 = math128::pow(10u128, _v0);
        let _v2 = p3 as u128;
        let _v3 = math128::pow(10u128, _v2);
        let _v4 = p0 as u128;
        let _v5 = _v1;
        if (!(_v5 != 0u128)) {
            let _v6 = error::invalid_argument(4);
            abort _v6
        };
        let _v7 = _v4 as u256;
        let _v8 = (100000000 as u128) as u256;
        let _v9 = _v7 * _v8;
        let _v10 = _v5 as u256;
        p0 = ((_v9 / _v10) as u128) as u256;
        let _v11 = p1 as u128;
        let _v12 = _v3;
        if (!(_v12 != 0u128)) {
            let _v13 = error::invalid_argument(4);
            abort _v13
        };
        let _v14 = _v11 as u256;
        let _v15 = (100000000 as u128) as u256;
        let _v16 = _v14 * _v15;
        let _v17 = _v12 as u256;
        p1 = ((_v16 / _v17) as u128) as u256;
        (p0, p1)
    }
    public fun supported_inner_assets(p0: object::Object<LiquidityPool>): vector<object::Object<fungible_asset::Metadata>>
        acquires LiquidityPool
    {
        let _v0 = object::object_address<LiquidityPool>(&p0);
        let _v1 = borrow_global<LiquidityPool>(_v0);
        let _v2 = fungible_asset::store_metadata<fungible_asset::FungibleStore>(*&_v1.token_store_1);
        let _v3 = fungible_asset::store_metadata<fungible_asset::FungibleStore>(*&_v1.token_store_2);
        let _v4 = vector::empty<object::Object<fungible_asset::Metadata>>();
        let _v5 = &mut _v4;
        vector::push_back<object::Object<fungible_asset::Metadata>>(_v5, _v2);
        vector::push_back<object::Object<fungible_asset::Metadata>>(_v5, _v3);
        _v4
    }
    public fun supported_native_fungible_assets(p0: object::Object<LiquidityPool>): vector<object::Object<fungible_asset::Metadata>>
        acquires LiquidityPool
    {
        let _v0 = supported_inner_assets(p0);
        let _v1 = vector::empty<object::Object<fungible_asset::Metadata>>();
        let _v2 = _v0;
        vector::reverse<object::Object<fungible_asset::Metadata>>(&mut _v2);
        let _v3 = _v2;
        let _v4 = vector::length<object::Object<fungible_asset::Metadata>>(&_v3);
        while (_v4 > 0) {
            let _v5 = vector::pop_back<object::Object<fungible_asset::Metadata>>(&mut _v3);
            if (!coin_wrapper::is_wrapper(*&_v5)) vector::push_back<object::Object<fungible_asset::Metadata>>(&mut _v1, _v5);
            _v4 = _v4 - 1;
            continue
        };
        vector::destroy_empty<object::Object<fungible_asset::Metadata>>(_v3);
        _v1
    }
    public fun supported_token_strings(p0: object::Object<LiquidityPool>): vector<string::String>
        acquires LiquidityPool
    {
        let _v0 = supported_inner_assets(p0);
        let _v1 = vector::empty<string::String>();
        let _v2 = _v0;
        vector::reverse<object::Object<fungible_asset::Metadata>>(&mut _v2);
        let _v3 = _v2;
        let _v4 = vector::length<object::Object<fungible_asset::Metadata>>(&_v3);
        while (_v4 > 0) {
            let _v5 = vector::pop_back<object::Object<fungible_asset::Metadata>>(&mut _v3);
            let _v6 = &mut _v1;
            let _v7 = coin_wrapper::get_original(_v5);
            vector::push_back<string::String>(_v6, _v7);
            _v4 = _v4 - 1;
            continue
        };
        vector::destroy_empty<object::Object<fungible_asset::Metadata>>(_v3);
        _v1
    }
    public entry fun transfer(p0: &signer, p1: object::Object<LiquidityPool>, p2: address, p3: u64)
        acquires LiquidityPool
    {
        assert!(p3 > 0, 1);
        let _v0 = signer::address_of(p0);
        let _v1 = ensure_lp_token_store<LiquidityPool>(_v0, p1);
        let _v2 = ensure_lp_token_store<LiquidityPool>(p2, p1);
        let _v3 = object::object_address<LiquidityPool>(&p1);
        fungible_asset::transfer_with_ref<fungible_asset::FungibleStore>(&(&borrow_global<LiquidityPool>(_v3).lp_token_refs).transfer_ref, _v1, _v2, p3);
        event::emit<TransferEvent>(TransferEvent{pool: object::object_address<LiquidityPool>(&p1), amount: p3, from: _v0, to: p2});
    }
    public entry fun update_claimable_fees(p0: address, p1: object::Object<LiquidityPool>) {
        abort 0
    }
}
