module 0x4bf51972879e3b95c4781a5cdcb9e1ee24ef483e7d22f2d903626f126df62bd1::rewards_pool {
    use 0x1::dispatchable_fungible_asset;
    use 0x1::fungible_asset;
    use 0x1::object;
    use 0x1::pool_u64_unbound;
    use 0x1::simple_map;
    use 0x1::smart_table;
    use 0x1::vector;
    use 0x4bf51972879e3b95c4781a5cdcb9e1ee24ef483e7d22f2d903626f126df62bd1::epoch;
    use 0x4bf51972879e3b95c4781a5cdcb9e1ee24ef483e7d22f2d903626f126df62bd1::liquidity_pool;
    use 0x4bf51972879e3b95c4781a5cdcb9e1ee24ef483e7d22f2d903626f126df62bd1::package_manager;
    friend 0x4bf51972879e3b95c4781a5cdcb9e1ee24ef483e7d22f2d903626f126df62bd1::vote_manager;
    struct EpochRewards has store {
        total_amounts: simple_map::SimpleMap<object::Object<fungible_asset::Metadata>, u64>,
        reward_tokens: vector<object::Object<fungible_asset::Metadata>>,
        non_default_reward_tokens_count: u64,
        claimer_pool: pool_u64_unbound::Pool,
    }
    struct RewardStore has store {
        store: object::Object<fungible_asset::FungibleStore>,
        store_extend_ref: object::ExtendRef,
    }
    struct RewardsPool has key {
        epoch_rewards: smart_table::SmartTable<u64, EpochRewards>,
        reward_stores: smart_table::SmartTable<object::Object<fungible_asset::Metadata>, RewardStore>,
        default_reward_tokens: vector<object::Object<fungible_asset::Metadata>>,
    }
    public fun reward_tokens(p0: object::Object<RewardsPool>, p1: u64): vector<object::Object<fungible_asset::Metadata>>
        acquires RewardsPool
    {
        let _v0 = object::object_address<RewardsPool>(&p0);
        let _v1 = borrow_global<RewardsPool>(_v0);
        if (!smart_table::contains<u64, EpochRewards>(&_v1.epoch_rewards, p1)) return vector::empty<object::Object<fungible_asset::Metadata>>();
        *&smart_table::borrow<u64, EpochRewards>(&_v1.epoch_rewards, p1).reward_tokens
    }
    public fun default_reward_tokens(p0: object::Object<RewardsPool>): vector<object::Object<fungible_asset::Metadata>>
        acquires RewardsPool
    {
        let _v0 = object::object_address<RewardsPool>(&p0);
        *&borrow_global<RewardsPool>(_v0).default_reward_tokens
    }
    friend fun add_rewards(p0: object::Object<RewardsPool>, p1: vector<fungible_asset::FungibleAsset>, p2: u64)
        acquires RewardsPool
    {
        let _v0 = default_reward_tokens(p0);
        let _v1 = &_v0;
        let _v2 = object::object_address<RewardsPool>(&p0);
        let _v3 = borrow_global_mut<RewardsPool>(_v2);
        let _v4 = &mut _v3.reward_stores;
        let _v5 = p1;
        vector::reverse<fungible_asset::FungibleAsset>(&mut _v5);
        let _v6 = _v5;
        let _v7 = vector::length<fungible_asset::FungibleAsset>(&_v6);
        'l0: loop {
            loop {
                if (!(_v7 > 0)) break 'l0;
                let _v8 = vector::pop_back<fungible_asset::FungibleAsset>(&mut _v6);
                let _v9 = fungible_asset::amount(&_v8);
                if (_v9 == 0) fungible_asset::destroy_zero(_v8) else {
                    let _v10 = fungible_asset::metadata_from_asset(&_v8);
                    let _v11 = &mut _v3.epoch_rewards;
                    let _v12 = p2;
                    let _v13 = _v11;
                    if (!smart_table::contains<u64, EpochRewards>(freeze(_v13), _v12)) {
                        let _v14 = pool_u64_unbound::create();
                        let _v15 = vector::empty<object::Object<fungible_asset::Metadata>>();
                        let _v16 = EpochRewards{total_amounts: simple_map::new<object::Object<fungible_asset::Metadata>, u64>(), reward_tokens: _v15, non_default_reward_tokens_count: 0, claimer_pool: _v14};
                        smart_table::add<u64, EpochRewards>(_v13, _v12, _v16)
                    };
                    let _v17 = smart_table::borrow_mut<u64, EpochRewards>(_v13, _v12);
                    let _v18 = &mut _v17.total_amounts;
                    let _v19 = &_v10;
                    if (!simple_map::contains_key<object::Object<fungible_asset::Metadata>, u64>(freeze(_v18), _v19)) {
                        let _v20 = &mut _v17.reward_tokens;
                        let _v21 = &_v10;
                        if (!vector::contains<object::Object<fungible_asset::Metadata>>(_v1, _v21)) {
                            if (!(*&_v17.non_default_reward_tokens_count < 15)) break;
                            let _v22 = *&_v17.non_default_reward_tokens_count + 1;
                            let _v23 = &mut _v17.non_default_reward_tokens_count;
                            *_v23 = _v22
                        };
                        simple_map::add<object::Object<fungible_asset::Metadata>, u64>(_v18, _v10, 0);
                        vector::push_back<object::Object<fungible_asset::Metadata>>(_v20, _v10)
                    };
                    if (!smart_table::contains<object::Object<fungible_asset::Metadata>, RewardStore>(freeze(_v4), _v10)) {
                        let _v24 = package_manager::get_signer();
                        let _v25 = object::create_object_from_account(&_v24);
                        let _v26 = &_v25;
                        let _v27 = fungible_asset::create_store<fungible_asset::Metadata>(_v26, _v10);
                        let _v28 = object::generate_extend_ref(_v26);
                        let _v29 = RewardStore{store: _v27, store_extend_ref: _v28};
                        smart_table::add<object::Object<fungible_asset::Metadata>, RewardStore>(_v4, _v10, _v29)
                    };
                    liquidity_pool::dispatchable_exact_deposit<fungible_asset::FungibleStore>(*&smart_table::borrow<object::Object<fungible_asset::Metadata>, RewardStore>(freeze(_v4), _v10).store, _v8);
                    let _v30 = &_v10;
                    let _v31 = simple_map::borrow_mut<object::Object<fungible_asset::Metadata>, u64>(_v18, _v30);
                    *_v31 = *_v31 + _v9
                };
                _v7 = _v7 - 1;
                continue
            };
            abort 2
        };
        vector::destroy_empty<fungible_asset::FungibleAsset>(_v6);
    }
    friend fun claim_rewards(p0: address, p1: object::Object<RewardsPool>, p2: u64): vector<fungible_asset::FungibleAsset>
        acquires RewardsPool
    {
        let _v0 = epoch::now();
        assert!(p2 < _v0, 1);
        let _v1 = reward_tokens(p1, p2);
        let _v2 = vector::empty<fungible_asset::FungibleAsset>();
        let _v3 = object::object_address<RewardsPool>(&p1);
        let _v4 = borrow_global_mut<RewardsPool>(_v3);
        let _v5 = _v1;
        vector::reverse<object::Object<fungible_asset::Metadata>>(&mut _v5);
        let _v6 = _v5;
        let _v7 = vector::length<object::Object<fungible_asset::Metadata>>(&_v6);
        while (_v7 > 0) {
            let _v8 = vector::pop_back<object::Object<fungible_asset::Metadata>>(&mut _v6);
            let _v9 = freeze(_v4);
            let _v10 = rewards(p0, _v9, _v8, p2);
            let _v11 = smart_table::borrow<object::Object<fungible_asset::Metadata>, RewardStore>(&_v4.reward_stores, _v8);
            if (_v10 == 0) {
                let _v12 = &mut _v2;
                let _v13 = fungible_asset::zero<fungible_asset::Metadata>(fungible_asset::store_metadata<fungible_asset::FungibleStore>(*&_v11.store));
                vector::push_back<fungible_asset::FungibleAsset>(_v12, _v13)
            } else {
                let _v14 = object::generate_signer_for_extending(&_v11.store_extend_ref);
                let _v15 = &_v14;
                let _v16 = &mut _v2;
                let _v17 = *&_v11.store;
                let _v18 = dispatchable_fungible_asset::withdraw<fungible_asset::FungibleStore>(_v15, _v17, _v10);
                vector::push_back<fungible_asset::FungibleAsset>(_v16, _v18);
                let _v19 = &mut smart_table::borrow_mut<u64, EpochRewards>(&mut _v4.epoch_rewards, p2).total_amounts;
                let _v20 = &_v8;
                let _v21 = simple_map::borrow_mut<object::Object<fungible_asset::Metadata>, u64>(_v19, _v20);
                *_v21 = *_v21 - _v10
            };
            _v7 = _v7 - 1;
            continue
        };
        vector::destroy_empty<object::Object<fungible_asset::Metadata>>(_v6);
        if (smart_table::contains<u64, EpochRewards>(&_v4.epoch_rewards, p2)) {
            let _v22 = smart_table::borrow_mut<u64, EpochRewards>(&mut _v4.epoch_rewards, p2);
            let _v23 = pool_u64_unbound::shares(&_v22.claimer_pool, p0);
            if (_v23 > 0u128) {
                let _v24 = pool_u64_unbound::redeem_shares(&mut _v22.claimer_pool, p0, _v23);
            }
        };
        _v2
    }
    public fun claimable_rewards(p0: address, p1: object::Object<RewardsPool>, p2: u64): simple_map::SimpleMap<object::Object<fungible_asset::Metadata>, u64>
        acquires RewardsPool
    {
        let _v0 = epoch::now();
        assert!(p2 < _v0, 1);
        let _v1 = reward_tokens(p1, p2);
        let _v2 = object::object_address<RewardsPool>(&p1);
        let _v3 = borrow_global<RewardsPool>(_v2);
        let _v4 = &_v1;
        let _v5 = vector[];
        let _v6 = _v4;
        let _v7 = 0;
        let _v8 = vector::length<object::Object<fungible_asset::Metadata>>(_v6);
        while (_v7 < _v8) {
            let _v9 = vector::borrow<object::Object<fungible_asset::Metadata>>(_v6, _v7);
            let _v10 = &mut _v5;
            let _v11 = *_v9;
            let _v12 = rewards(p0, _v3, _v11, p2);
            vector::push_back<u64>(_v10, _v12);
            _v7 = _v7 + 1;
            continue
        };
        simple_map::new_from<object::Object<fungible_asset::Metadata>, u64>(_v1, _v5)
    }
    public fun claimer_shares(p0: address, p1: object::Object<RewardsPool>, p2: u64): (u64, u64)
        acquires RewardsPool
    {
        let _v0 = object::object_address<RewardsPool>(&p1);
        let _v1 = smart_table::borrow<u64, EpochRewards>(&borrow_global<RewardsPool>(_v0).epoch_rewards, p2);
        let _v2 = pool_u64_unbound::shares(&_v1.claimer_pool, p0) as u64;
        let _v3 = pool_u64_unbound::total_shares(&_v1.claimer_pool) as u64;
        (_v2, _v3)
    }
    friend fun create(p0: vector<object::Object<fungible_asset::Metadata>>): object::Object<RewardsPool> {
        let _v0 = package_manager::get_signer();
        let _v1 = object::create_object_from_account(&_v0);
        let _v2 = &_v1;
        let _v3 = object::generate_signer(_v2);
        let _v4 = &_v3;
        let _v5 = smart_table::new<object::Object<fungible_asset::Metadata>, RewardStore>();
        let _v6 = p0;
        vector::reverse<object::Object<fungible_asset::Metadata>>(&mut _v6);
        let _v7 = _v6;
        let _v8 = vector::length<object::Object<fungible_asset::Metadata>>(&_v7);
        while (_v8 > 0) {
            let _v9 = vector::pop_back<object::Object<fungible_asset::Metadata>>(&mut _v7);
            let _v10 = &mut _v5;
            let _v11 = package_manager::get_signer();
            let _v12 = object::create_object_from_account(&_v11);
            let _v13 = &_v12;
            let _v14 = fungible_asset::create_store<fungible_asset::Metadata>(_v13, _v9);
            let _v15 = object::generate_extend_ref(_v13);
            let _v16 = RewardStore{store: _v14, store_extend_ref: _v15};
            smart_table::add<object::Object<fungible_asset::Metadata>, RewardStore>(_v10, _v9, _v16);
            _v8 = _v8 - 1;
            continue
        };
        vector::destroy_empty<object::Object<fungible_asset::Metadata>>(_v7);
        let _v17 = RewardsPool{epoch_rewards: smart_table::new<u64, EpochRewards>(), reward_stores: _v5, default_reward_tokens: p0};
        move_to<RewardsPool>(_v4, _v17);
        object::object_from_constructor_ref<RewardsPool>(_v2)
    }
    friend fun decrease_allocation(p0: address, p1: object::Object<RewardsPool>, p2: u64)
        acquires RewardsPool
    {
        let _v0 = object::object_address<RewardsPool>(&p1);
        let _v1 = &mut borrow_global_mut<RewardsPool>(_v0).epoch_rewards;
        let _v2 = epoch::now();
        let _v3 = _v1;
        if (!smart_table::contains<u64, EpochRewards>(freeze(_v3), _v2)) {
            let _v4 = pool_u64_unbound::create();
            let _v5 = vector::empty<object::Object<fungible_asset::Metadata>>();
            let _v6 = EpochRewards{total_amounts: simple_map::new<object::Object<fungible_asset::Metadata>, u64>(), reward_tokens: _v5, non_default_reward_tokens_count: 0, claimer_pool: _v4};
            smart_table::add<u64, EpochRewards>(_v3, _v2, _v6)
        };
        let _v7 = &mut smart_table::borrow_mut<u64, EpochRewards>(_v3, _v2).claimer_pool;
        let _v8 = p2 as u128;
        let _v9 = pool_u64_unbound::redeem_shares(_v7, p0, _v8);
    }
    friend fun increase_allocation(p0: address, p1: object::Object<RewardsPool>, p2: u64)
        acquires RewardsPool
    {
        let _v0 = object::object_address<RewardsPool>(&p1);
        let _v1 = &mut borrow_global_mut<RewardsPool>(_v0).epoch_rewards;
        let _v2 = epoch::now();
        let _v3 = _v1;
        if (!smart_table::contains<u64, EpochRewards>(freeze(_v3), _v2)) {
            let _v4 = pool_u64_unbound::create();
            let _v5 = vector::empty<object::Object<fungible_asset::Metadata>>();
            let _v6 = EpochRewards{total_amounts: simple_map::new<object::Object<fungible_asset::Metadata>, u64>(), reward_tokens: _v5, non_default_reward_tokens_count: 0, claimer_pool: _v4};
            smart_table::add<u64, EpochRewards>(_v3, _v2, _v6)
        };
        let _v7 = pool_u64_unbound::buy_in(&mut smart_table::borrow_mut<u64, EpochRewards>(_v3, _v2).claimer_pool, p0, p2);
    }
    fun rewards(p0: address, p1: &RewardsPool, p2: object::Object<fungible_asset::Metadata>, p3: u64): u64 {
        let _v0;
        let _v1;
        let _v2 = !smart_table::contains<u64, EpochRewards>(&p1.epoch_rewards, p3);
        loop {
            if (!_v2) {
                _v0 = smart_table::borrow<u64, EpochRewards>(&p1.epoch_rewards, p3);
                let _v3 = &_v0.total_amounts;
                let _v4 = &p2;
                if (simple_map::contains_key<object::Object<fungible_asset::Metadata>, u64>(_v3, _v4)) {
                    let _v5 = &_v0.total_amounts;
                    let _v6 = &p2;
                    _v1 = *simple_map::borrow<object::Object<fungible_asset::Metadata>, u64>(_v5, _v6);
                    break
                };
                _v1 = 0;
                break
            };
            return 0
        };
        let _v7 = pool_u64_unbound::shares(&_v0.claimer_pool, p0);
        pool_u64_unbound::shares_to_amount_with_total_coins(&_v0.claimer_pool, _v7, _v1)
    }
    public fun total_rewards(p0: object::Object<RewardsPool>, p1: u64): simple_map::SimpleMap<object::Object<fungible_asset::Metadata>, u64>
        acquires RewardsPool
    {
        let _v0 = object::object_address<RewardsPool>(&p0);
        let _v1 = borrow_global<RewardsPool>(_v0);
        if (!smart_table::contains<u64, EpochRewards>(&_v1.epoch_rewards, p1)) return simple_map::new<object::Object<fungible_asset::Metadata>, u64>();
        *&smart_table::borrow<u64, EpochRewards>(&_v1.epoch_rewards, p1).total_amounts
    }
}
