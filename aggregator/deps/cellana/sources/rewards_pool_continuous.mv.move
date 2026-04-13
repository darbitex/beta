module 0x4bf51972879e3b95c4781a5cdcb9e1ee24ef483e7d22f2d903626f126df62bd1::rewards_pool_continuous {
    use 0x1::dispatchable_fungible_asset;
    use 0x1::error;
    use 0x1::fungible_asset;
    use 0x1::math64;
    use 0x1::object;
    use 0x1::smart_table;
    use 0x1::timestamp;
    use 0x4bf51972879e3b95c4781a5cdcb9e1ee24ef483e7d22f2d903626f126df62bd1::package_manager;
    friend 0x4bf51972879e3b95c4781a5cdcb9e1ee24ef483e7d22f2d903626f126df62bd1::gauge;
    friend 0x4bf51972879e3b95c4781a5cdcb9e1ee24ef483e7d22f2d903626f126df62bd1::voting_escrow;
    struct RewardsPool has key {
        extend_ref: object::ExtendRef,
        reward_per_token_stored: u128,
        user_reward_per_token_paid: smart_table::SmartTable<address, u128>,
        last_update_time: u64,
        reward_rate: u128,
        reward_duration: u64,
        reward_period_finish: u64,
        rewards: smart_table::SmartTable<address, u64>,
        total_stake: u128,
        stakes: smart_table::SmartTable<address, u64>,
    }
    public fun reward_rate(p0: object::Object<RewardsPool>): u128
        acquires RewardsPool
    {
        let _v0 = object::object_address<RewardsPool>(&p0);
        *&borrow_global<RewardsPool>(_v0).reward_rate / 100000000u128
    }
    public fun total_stake(p0: object::Object<RewardsPool>): u128
        acquires RewardsPool
    {
        let _v0 = object::object_address<RewardsPool>(&p0);
        *&borrow_global<RewardsPool>(_v0).total_stake
    }
    friend fun add_rewards(p0: object::Object<RewardsPool>, p1: fungible_asset::FungibleAsset)
        acquires RewardsPool
    {
        let _v0;
        update_reward(@0x0, p0);
        let _v1 = fungible_asset::amount(&p1);
        dispatchable_fungible_asset::deposit<RewardsPool>(p0, p1);
        let _v2 = timestamp::now_seconds();
        let _v3 = object::object_address<RewardsPool>(&p0);
        let _v4 = borrow_global_mut<RewardsPool>(_v3);
        if (*&_v4.reward_period_finish > _v2) {
            let _v5 = *&_v4.reward_rate;
            let _v6 = (*&_v4.reward_period_finish - _v2) as u128;
            _v0 = _v5 * _v6
        } else _v0 = 0u128;
        let _v7 = (_v1 as u128) * 100000000u128;
        let _v8 = _v0 + _v7;
        let _v9 = (*&_v4.reward_duration) as u128;
        let _v10 = _v8 / _v9;
        let _v11 = &mut _v4.reward_rate;
        *_v11 = _v10;
        let _v12 = *&_v4.reward_duration;
        let _v13 = _v2 + _v12;
        let _v14 = &mut _v4.reward_period_finish;
        *_v14 = _v13;
        let _v15 = &mut _v4.last_update_time;
        *_v15 = _v2;
    }
    friend fun claim_rewards(p0: address, p1: object::Object<RewardsPool>): fungible_asset::FungibleAsset
        acquires RewardsPool
    {
        update_reward(p0, p1);
        let _v0 = object::object_address<RewardsPool>(&p1);
        let _v1 = borrow_global_mut<RewardsPool>(_v0);
        let _v2 = &mut _v1.rewards;
        let _v3 = 0;
        let _v4 = &_v3;
        let _v5 = *smart_table::borrow_with_default<address, u64>(freeze(_v2), p0, _v4);
        assert!(_v5 > 0, 3);
        smart_table::upsert<address, u64>(&mut _v1.rewards, p0, 0);
        let _v6 = package_manager::get_signer();
        dispatchable_fungible_asset::withdraw<RewardsPool>(&_v6, p1, _v5)
    }
    fun claimable_internal(p0: address, p1: &RewardsPool): u64 {
        let _v0 = reward_per_token_internal(p1);
        let _v1 = &p1.user_reward_per_token_paid;
        let _v2 = 0u128;
        let _v3 = &_v2;
        let _v4 = *smart_table::borrow_with_default<address, u128>(_v1, p0, _v3);
        let _v5 = _v0 - _v4;
        let _v6 = &p1.stakes;
        let _v7 = 0;
        let _v8 = &_v7;
        let _v9 = (*smart_table::borrow_with_default<address, u64>(_v6, p0, _v8)) as u128;
        let _v10 = 100000000u128;
        if (!(_v10 != 0u128)) {
            let _v11 = error::invalid_argument(4);
            abort _v11
        };
        let _v12 = _v9 as u256;
        let _v13 = _v5 as u256;
        let _v14 = _v12 * _v13;
        let _v15 = _v10 as u256;
        let _v16 = (_v14 / _v15) as u128;
        let _v17 = &p1.rewards;
        let _v18 = 0;
        let _v19 = &_v18;
        let _v20 = *smart_table::borrow_with_default<address, u64>(_v17, p0, _v19);
        (_v16 as u64) + _v20
    }
    public fun claimable_rewards(p0: address, p1: object::Object<RewardsPool>): u64
        acquires RewardsPool
    {
        let _v0 = object::object_address<RewardsPool>(&p1);
        let _v1 = borrow_global<RewardsPool>(_v0);
        claimable_internal(p0, _v1)
    }
    friend fun create(p0: object::Object<fungible_asset::Metadata>, p1: u64): object::Object<RewardsPool> {
        assert!(p1 > 0, 4);
        let _v0 = package_manager::get_signer();
        let _v1 = object::create_object_from_account(&_v0);
        let _v2 = &_v1;
        let _v3 = fungible_asset::create_store<fungible_asset::Metadata>(_v2, p0);
        let _v4 = object::generate_signer(_v2);
        let _v5 = &_v4;
        let _v6 = object::generate_extend_ref(_v2);
        let _v7 = smart_table::new<address, u128>();
        let _v8 = smart_table::new<address, u64>();
        let _v9 = smart_table::new<address, u64>();
        let _v10 = RewardsPool{extend_ref: _v6, reward_per_token_stored: 0u128, user_reward_per_token_paid: _v7, last_update_time: 0, reward_rate: 0u128, reward_duration: p1, reward_period_finish: 0, rewards: _v8, total_stake: 0u128, stakes: _v9};
        move_to<RewardsPool>(_v5, _v10);
        object::object_from_constructor_ref<RewardsPool>(_v2)
    }
    public fun current_reward_period_finish(p0: object::Object<RewardsPool>): u64
        acquires RewardsPool
    {
        let _v0 = object::object_address<RewardsPool>(&p0);
        *&borrow_global<RewardsPool>(_v0).reward_period_finish
    }
    public fun reward_per_token(p0: object::Object<RewardsPool>): u128
        acquires RewardsPool
    {
        let _v0 = object::object_address<RewardsPool>(&p0);
        reward_per_token_internal(borrow_global<RewardsPool>(_v0))
    }
    fun reward_per_token_internal(p0: &RewardsPool): u128 {
        let _v0 = *&p0.reward_per_token_stored;
        let _v1 = *&p0.total_stake;
        if (_v1 > 0u128) {
            let _v2 = *&p0.reward_rate;
            let _v3 = timestamp::now_seconds();
            let _v4 = *&p0.reward_period_finish;
            let _v5 = math64::min(_v3, _v4);
            let _v6 = *&p0.last_update_time;
            let _v7 = (_v5 - _v6) as u128;
            let _v8 = _v1;
            if (!(_v8 != 0u128)) {
                let _v9 = error::invalid_argument(4);
                abort _v9
            };
            let _v10 = _v7 as u256;
            let _v11 = _v2 as u256;
            let _v12 = _v10 * _v11;
            let _v13 = _v8 as u256;
            let _v14 = (_v12 / _v13) as u128;
            _v0 = _v0 + _v14
        };
        _v0
    }
    friend fun stake(p0: address, p1: object::Object<RewardsPool>, p2: u64)
        acquires RewardsPool
    {
        update_reward(p0, p1);
        let _v0 = object::object_address<RewardsPool>(&p1);
        let _v1 = borrow_global_mut<RewardsPool>(_v0);
        let _v2 = smart_table::borrow_mut_with_default<address, u64>(&mut _v1.stakes, p0, 0);
        *_v2 = *_v2 + p2;
        let _v3 = *&_v1.total_stake;
        let _v4 = p2 as u128;
        let _v5 = _v3 + _v4;
        let _v6 = &mut _v1.total_stake;
        *_v6 = _v5;
    }
    public fun stake_balance(p0: address, p1: object::Object<RewardsPool>): u64
        acquires RewardsPool
    {
        let _v0 = object::object_address<RewardsPool>(&p1);
        let _v1 = &borrow_global<RewardsPool>(_v0).stakes;
        let _v2 = 0;
        let _v3 = &_v2;
        *smart_table::borrow_with_default<address, u64>(_v1, p0, _v3)
    }
    public fun total_unclaimed_rewards(p0: object::Object<RewardsPool>): u64 {
        fungible_asset::balance<RewardsPool>(p0)
    }
    friend fun unstake(p0: address, p1: object::Object<RewardsPool>, p2: u64)
        acquires RewardsPool
    {
        let _v0;
        update_reward(p0, p1);
        let _v1 = object::object_address<RewardsPool>(&p1);
        let _v2 = borrow_global_mut<RewardsPool>(_v1);
        assert!(smart_table::contains<address, u64>(&_v2.stakes, p0), 2);
        let _v3 = smart_table::borrow_mut_with_default<address, u64>(&mut _v2.stakes, p0, 0);
        if (p2 > 0) {
            let _v4 = *_v3;
            _v0 = p2 <= _v4
        } else _v0 = false;
        assert!(_v0, 1);
        *_v3 = *_v3 - p2;
        let _v5 = *&_v2.total_stake;
        let _v6 = p2 as u128;
        let _v7 = _v5 - _v6;
        let _v8 = &mut _v2.total_stake;
        *_v8 = _v7;
        if (*_v3 == 0) {
            let _v9 = smart_table::remove<address, u64>(&mut _v2.stakes, p0);
            let _v10 = smart_table::remove<address, u128>(&mut _v2.user_reward_per_token_paid, p0);
        };
    }
    fun update_reward(p0: address, p1: object::Object<RewardsPool>)
        acquires RewardsPool
    {
        let _v0 = object::object_address<RewardsPool>(&p1);
        let _v1 = borrow_global_mut<RewardsPool>(_v0);
        let _v2 = reward_per_token_internal(freeze(_v1));
        let _v3 = &mut _v1.reward_per_token_stored;
        *_v3 = _v2;
        let _v4 = freeze(_v1);
        let _v5 = timestamp::now_seconds();
        let _v6 = *&_v4.reward_period_finish;
        let _v7 = math64::min(_v5, _v6);
        let _v8 = &mut _v1.last_update_time;
        *_v8 = _v7;
        if (p0 != @0x0) {
            let _v9 = freeze(_v1);
            let _v10 = claimable_internal(p0, _v9);
            smart_table::upsert<address, u64>(&mut _v1.rewards, p0, _v10);
            let _v11 = &mut _v1.user_reward_per_token_paid;
            let _v12 = *&_v1.reward_per_token_stored;
            smart_table::upsert<address, u128>(_v11, p0, _v12)
        };
    }
}
