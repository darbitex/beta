module 0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c::rewarder {
    use 0x1::object;
    use 0x1::fungible_asset;
    use 0x1::timestamp;
    use 0x1::event;
    use 0x1::dispatchable_fungible_asset;
    use 0x1::primary_fungible_store;
    use 0x1::signer;
    use 0x1::vector;
    use 0x1::string;
    use 0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c::user_label;
    use 0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c::math_u128;
    use 0x1::string_utils;
    friend 0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c::pool_v3;
    struct AddIncentiveEvent has drop, store {
        pool_id: address,
        reward_metadata: object::Object<fungible_asset::Metadata>,
        amount: u64,
        index: u64,
    }
    struct ClaimRewardsEvent has drop, store {
        pool_id: address,
        position_id: address,
        reward_fa: object::Object<fungible_asset::Metadata>,
        amount: u64,
        owner: address,
        index: u64,
    }
    struct CreateRewarderEvent has drop, store {
        pool_id: address,
        reward_fa: object::Object<fungible_asset::Metadata>,
        emissions_per_second: u64,
        emissions_per_second_max: u64,
        emissions_per_liquidity_start: u128,
        index: u64,
    }
    struct Numbers {
        reward_fa: object::Object<fungible_asset::Metadata>,
        pending: u64,
        balance: u64,
        remaining_emission: u64,
    }
    struct NumbersV1 {
        reward_fa: object::Object<fungible_asset::Metadata>,
        pending: u64,
        balance: u64,
        remaining_emission: u64,
        emission_per_second: u64,
        emission_per_second_max: u64,
    }
    struct PendingReward has copy, drop {
        reward_fa: object::Object<fungible_asset::Metadata>,
        amount_owed: u64,
    }
    struct PositionReward has copy, drop, store {
        emissions_per_liquidity_inside: u128,
        amount_owned: u64,
    }
    struct RemainingIncentive {
        reward_fa: object::Object<fungible_asset::Metadata>,
        remaining: u64,
    }
    struct RemoveIncentiveEvent has drop, store {
        pool_id: address,
        reward_metadata: object::Object<fungible_asset::Metadata>,
        amount: u64,
        index: u64,
    }
    struct RewardEmissionMaxUpdateEvent has drop, store {
        pool_id: address,
        reward_fa: object::Object<fungible_asset::Metadata>,
        old_emission_rate_max: u64,
        new_emission_rate_max: u64,
        index: u64,
    }
    struct RewardEmissionUpdateEvent has drop, store {
        pool_id: address,
        reward_fa: object::Object<fungible_asset::Metadata>,
        old_emission_rate: u64,
        new_emission_rate: u64,
        index: u64,
    }
    struct RewardRate {
        reward_fa: object::Object<fungible_asset::Metadata>,
        rate: u128,
    }
    struct Rewarder has copy, drop, store {
        reward_store: object::Object<fungible_asset::FungibleStore>,
        emissions_per_second: u64,
        emissions_per_second_max: u64,
        emissions_per_liquidity_start: u128,
        emissions_per_liquidity_latest: u128,
        user_owed: u64,
        pause: bool,
    }
    struct RewarderManager has store {
        rewarders: vector<Rewarder>,
        last_updated_time: u64,
        pause: bool,
    }
    struct RewarderOwedUpdate has drop, store {
        owed_before: u64,
        owed_after: u64,
    }
    friend fun init(): RewarderManager {
        let _v0 = vector::empty<Rewarder>();
        let _v1 = timestamp::now_seconds();
        RewarderManager{rewarders: _v0, last_updated_time: _v1, pause: false}
    }
    friend fun add_incentive(p0: &mut RewarderManager, p1: u128, p2: fungible_asset::FungibleAsset, p3: u64, p4: address) {
        flash(p0, p1);
        let _v0 = vector::borrow_mut<Rewarder>(&mut p0.rewarders, p3);
        let _v1 = fungible_asset::store_metadata<fungible_asset::FungibleStore>(*&_v0.reward_store);
        let _v2 = fungible_asset::amount(&p2);
        event::emit<AddIncentiveEvent>(AddIncentiveEvent{pool_id: p4, reward_metadata: _v1, amount: _v2, index: p3});
        dispatchable_fungible_asset::deposit<fungible_asset::FungibleStore>(*&_v0.reward_store, p2);
        if (*&_v0.pause) {
            let _v3 = &mut _v0.pause;
            *_v3 = false;
            return ()
        };
    }
    friend fun flash(p0: &mut RewarderManager, p1: u128) {
        let _v0 = timestamp::now_seconds();
        let _v1 = *&p0.last_updated_time;
        let _v2 = _v0 - _v1;
        'l0: loop {
            if (!(_v2 == 0)) {
                let _v3 = 0;
                let _v4 = vector::length<Rewarder>(&p0.rewarders);
                if (*&p0.pause) _v4 = 0;
                loop {
                    let _v5;
                    if (p1 != 0u128) _v5 = _v3 < _v4 else _v5 = false;
                    if (!_v5) break 'l0;
                    let _v6 = vector::borrow_mut<Rewarder>(&mut p0.rewarders, _v3);
                    if (!*&_v6.pause) {
                        let _v7;
                        let _v8 = *&_v6.emissions_per_second * _v2;
                        let _v9 = ((_v8 as u128) << 64u8) / p1;
                        let _v10 = fungible_asset::balance<fungible_asset::FungibleStore>(*&_v6.reward_store);
                        let _v11 = *&_v6.user_owed;
                        let _v12 = _v10 - _v11;
                        if (_v8 < _v12) {
                            let _v13 = *&_v6.emissions_per_liquidity_latest + _v9;
                            let _v14 = &mut _v6.emissions_per_liquidity_latest;
                            *_v14 = _v13;
                            _v7 = _v8
                        } else {
                            let _v15 = &mut _v6.pause;
                            *_v15 = true;
                            let _v16 = fungible_asset::balance<fungible_asset::FungibleStore>(*&_v6.reward_store);
                            let _v17 = *&_v6.user_owed;
                            _v8 = _v16 - _v17;
                            _v9 = ((_v8 as u128) << 64u8) / p1;
                            let _v18 = *&_v6.emissions_per_liquidity_latest + _v9;
                            let _v19 = &mut _v6.emissions_per_liquidity_latest;
                            *_v19 = _v18;
                            _v7 = _v8
                        };
                        let _v20 = *&_v6.user_owed;
                        let _v21 = _v7 + _v20;
                        let _v22 = &mut _v6.user_owed;
                        *_v22 = _v21
                    };
                    _v3 = _v3 + 1;
                    continue
                }
            };
            return ()
        };
        let _v23 = &mut p0.last_updated_time;
        *_v23 = _v0;
    }
    friend fun add_rewarder(p0: address, p1: &mut RewarderManager, p2: u64, p3: u64, p4: u128, p5: fungible_asset::FungibleAsset) {
        assert!(p2 <= p3, 14566554180833181696);
        let _v0 = fungible_asset::metadata_from_asset(&p5);
        let _v1 = primary_fungible_store::create_primary_store<fungible_asset::Metadata>(p0, _v0);
        flash(p1, p4);
        let _v2 = &mut p1.rewarders;
        let _v3 = Rewarder{reward_store: _v1, emissions_per_second: p2, emissions_per_second_max: p3, emissions_per_liquidity_start: 0u128, emissions_per_liquidity_latest: 0u128, user_owed: 0, pause: false};
        vector::push_back<Rewarder>(_v2, _v3);
        let _v4 = fungible_asset::metadata_from_asset(&p5);
        let _v5 = fungible_asset::amount(&p5);
        dispatchable_fungible_asset::deposit<fungible_asset::FungibleStore>(_v1, p5);
        let _v6 = vector::length<Rewarder>(&p1.rewarders) - 1;
        event::emit<CreateRewarderEvent>(CreateRewarderEvent{pool_id: p0, reward_fa: _v4, emissions_per_second: p2, emissions_per_second_max: p3, emissions_per_liquidity_start: 0u128, index: _v6});
        let _v7 = vector::length<Rewarder>(&p1.rewarders) - 1;
        event::emit<AddIncentiveEvent>(AddIncentiveEvent{pool_id: p0, reward_metadata: _v4, amount: _v5, index: _v7});
    }
    friend fun claim_rewards(p0: &signer, p1: address, p2: address, p3: &mut RewarderManager, p4: vector<PositionReward>, p5: vector<u128>, p6: u128, p7: u128): (vector<fungible_asset::FungibleAsset>, vector<PositionReward>) {
        if (*&p3.pause) abort 1100005;
        let _v0 = signer::address_of(p0);
        flash(p3, p6);
        let _v1 = vector::empty<fungible_asset::FungibleAsset>();
        let _v2 = vector::length<Rewarder>(&p3.rewarders);
        let _v3 = refresh_position_rewarder(p3, p4, p5, p7);
        let _v4 = 0;
        while (_v4 < _v2) {
            let _v5 = vector::borrow_mut<Rewarder>(&mut p3.rewarders, _v4);
            let _v6 = vector::borrow_mut<PositionReward>(&mut _v3, _v4);
            let _v7 = *&_v6.amount_owned;
            let _v8 = *&_v5.reward_store;
            let _v9 = dispatchable_fungible_asset::withdraw<fungible_asset::FungibleStore>(p0, _v8, _v7);
            let _v10 = &mut _v6.amount_owned;
            *_v10 = 0;
            let _v11 = *&_v5.user_owed - _v7;
            let _v12 = &mut _v5.user_owed;
            *_v12 = _v11;
            let _v13 = fungible_asset::store_metadata<fungible_asset::FungibleStore>(*&_v5.reward_store);
            event::emit<ClaimRewardsEvent>(ClaimRewardsEvent{pool_id: _v0, position_id: p2, reward_fa: _v13, amount: _v7, owner: p1, index: _v4});
            _v4 = _v4 + 1;
            vector::push_back<fungible_asset::FungibleAsset>(&mut _v1, _v9);
            continue
        };
        vector::reverse<fungible_asset::FungibleAsset>(&mut _v1);
        (_v1, _v3)
    }
    friend fun refresh_position_rewarder(p0: &mut RewarderManager, p1: vector<PositionReward>, p2: vector<u128>, p3: u128): vector<PositionReward> {
        let _v0 = vector::length<Rewarder>(&p0.rewarders);
        let _v1 = vector::length<PositionReward>(&p1);
        let _v2 = vector::empty<PositionReward>();
        assert!(_v0 >= _v1, 1100003);
        let _v3 = 0;
        loop {
            let _v4;
            if (!(_v0 != 0)) break;
            _v0 = _v0 - 1;
            let _v5 = vector::borrow_mut<u128>(&mut p2, _v0);
            let _v6 = _v0 + 1;
            if (_v1 < _v6) {
                let _v7 = &mut _v2;
                let _v8 = PositionReward{emissions_per_liquidity_inside: 0u128, amount_owned: 0};
                vector::push_back<PositionReward>(_v7, _v8);
                _v4 = vector::borrow_mut<PositionReward>(&mut _v2, _v3)
            } else _v4 = vector::borrow_mut<PositionReward>(&mut p1, _v0);
            let _v9 = *_v5;
            let _v10 = *&_v4.emissions_per_liquidity_inside;
            let (_v11,_v12) = math_u128::overflowing_sub(_v9, _v10);
            let _v13 = *&_v4.amount_owned;
            let _v14 = (_v11 * p3 >> 64u8) as u64;
            let _v15 = _v13 + _v14;
            let _v16 = &mut _v4.amount_owned;
            *_v16 = _v15;
            let _v17 = *_v5;
            let _v18 = &mut _v4.emissions_per_liquidity_inside;
            *_v18 = _v17;
            _v3 = _v3 + 1;
            continue
        };
        vector::reverse<PositionReward>(&mut _v2);
        vector::append<PositionReward>(&mut p1, _v2);
        p1
    }
    friend fun get_emissions_per_liquidity_list(p0: &RewarderManager): vector<u128> {
        let _v0 = vector::empty<u128>();
        let _v1 = &p0.rewarders;
        let _v2 = 0;
        let _v3 = vector::length<Rewarder>(_v1);
        while (_v2 < _v3) {
            let _v4 = vector::borrow<Rewarder>(_v1, _v2);
            let _v5 = &mut _v0;
            let _v6 = *&_v4.emissions_per_liquidity_latest;
            vector::push_back<u128>(_v5, _v6);
            _v2 = _v2 + 1;
            continue
        };
        _v0
    }
    friend fun get_emissions_per_liquidity_list_realtime(p0: &RewarderManager, p1: u128): vector<u128> {
        let _v0 = vector::empty<u128>();
        let _v1 = timestamp::now_seconds();
        let _v2 = *&p0.last_updated_time;
        let _v3 = _v1 - _v2;
        let _v4 = &p0.rewarders;
        let _v5 = 0;
        let _v6 = vector::length<Rewarder>(_v4);
        loop {
            let _v7;
            if (!(_v5 < _v6)) break;
            let _v8 = vector::borrow<Rewarder>(_v4, _v5);
            if (*&_v8.pause) _v7 = false else _v7 = p1 != 0u128;
            if (_v7) {
                let _v9;
                let _v10 = *&_v8.emissions_per_second * _v3;
                let _v11 = ((_v10 as u128) << 64u8) / p1;
                let _v12 = fungible_asset::balance<fungible_asset::FungibleStore>(*&_v8.reward_store);
                if (_v10 < _v12) _v9 = *&_v8.emissions_per_liquidity_latest + _v11 else {
                    _v11 = ((fungible_asset::balance<fungible_asset::FungibleStore>(*&_v8.reward_store) as u128) << 64u8) / p1;
                    _v9 = *&_v8.emissions_per_liquidity_latest + _v11
                };
                vector::push_back<u128>(&mut _v0, _v9)
            } else {
                let _v13 = &mut _v0;
                let _v14 = *&_v8.emissions_per_liquidity_latest;
                vector::push_back<u128>(_v13, _v14)
            };
            _v5 = _v5 + 1;
            continue
        };
        _v0
    }
    friend fun get_emissions_rate_list(p0: &RewarderManager): vector<u64> {
        let _v0 = vector::empty<u64>();
        let _v1 = &p0.rewarders;
        let _v2 = 0;
        let _v3 = vector::length<Rewarder>(_v1);
        loop {
            let _v4;
            if (!(_v2 < _v3)) break;
            let _v5 = vector::borrow<Rewarder>(_v1, _v2);
            if (*&p0.pause) _v4 = true else _v4 = *&_v5.pause;
            if (_v4) vector::push_back<u64>(&mut _v0, 0) else {
                let _v6 = &mut _v0;
                let _v7 = *&_v5.emissions_per_second;
                vector::push_back<u64>(_v6, _v7)
            };
            _v2 = _v2 + 1;
            continue
        };
        _v0
    }
    friend fun get_rewarder_list(p0: &RewarderManager): vector<Rewarder> {
        *&p0.rewarders
    }
    friend fun get_rewarder_list_length(p0: &RewarderManager): u64 {
        vector::length<Rewarder>(&p0.rewarders)
    }
    friend fun is_rewarder_op_admin(p0: address, p1: address, p2: u64): bool {
        let _v0 = rewarder_label(p1, p2);
        user_label::has_label(p0, _v0)
    }
    fun rewarder_label(p0: address, p1: u64): string::String {
        let _v0 = string_utils::to_string_with_canonical_addresses<address>(&p0);
        let _v1 = string_utils::to_string<u64>(&p1);
        let _v2 = string::utf8(vector[114u8, 101u8, 119u8, 97u8, 114u8, 100u8, 101u8, 114u8, 95u8]);
        string::append(&mut _v2, _v0);
        let _v3 = &mut _v2;
        let _v4 = string::utf8(vector[95u8]);
        string::append(_v3, _v4);
        string::append(&mut _v2, _v1);
        _v2
    }
    friend fun new_rewards_record(p0: &RewarderManager): vector<PositionReward> {
        let _v0 = vector::empty<PositionReward>();
        let _v1 = &p0.rewarders;
        let _v2 = 0;
        let _v3 = vector::length<Rewarder>(_v1);
        while (_v2 < _v3) {
            let _v4 = vector::borrow<Rewarder>(_v1, _v2);
            let _v5 = &mut _v0;
            let _v6 = PositionReward{emissions_per_liquidity_inside: 0u128, amount_owned: 0};
            vector::push_back<PositionReward>(_v5, _v6);
            _v2 = _v2 + 1;
            continue
        };
        _v0
    }
    friend fun numbers(p0: &RewarderManager): vector<Numbers> {
        let _v0 = timestamp::now_seconds();
        let _v1 = *&p0.last_updated_time;
        let _v2 = _v0 - _v1;
        let _v3 = vector::empty<Numbers>();
        let _v4 = 0;
        let _v5 = vector::length<Rewarder>(&p0.rewarders);
        loop {
            let _v6;
            if (!(_v4 < _v5)) break;
            let _v7 = vector::borrow<Rewarder>(&p0.rewarders, _v4);
            let _v8 = *&_v7.emissions_per_second * _v2;
            let _v9 = *&_v7.user_owed;
            let _v10 = _v8 + _v9;
            let _v11 = fungible_asset::balance<fungible_asset::FungibleStore>(*&_v7.reward_store);
            if (_v10 < _v11) _v6 = fungible_asset::balance<fungible_asset::FungibleStore>(*&_v7.reward_store) - _v10 else _v6 = 0;
            let _v12 = &mut _v3;
            let _v13 = fungible_asset::store_metadata<fungible_asset::FungibleStore>(*&_v7.reward_store);
            let _v14 = fungible_asset::balance<fungible_asset::FungibleStore>(*&_v7.reward_store);
            let _v15 = *&_v7.user_owed;
            let _v16 = Numbers{reward_fa: _v13, pending: _v15, balance: _v14, remaining_emission: _v6};
            vector::push_back<Numbers>(_v12, _v16);
            _v4 = _v4 + 1;
            continue
        };
        _v3
    }
    friend fun numbers_v1(p0: &RewarderManager): vector<NumbersV1> {
        let _v0 = timestamp::now_seconds();
        let _v1 = *&p0.last_updated_time;
        let _v2 = _v0 - _v1;
        let _v3 = vector::empty<NumbersV1>();
        let _v4 = 0;
        let _v5 = vector::length<Rewarder>(&p0.rewarders);
        loop {
            let _v6;
            if (!(_v4 < _v5)) break;
            let _v7 = vector::borrow<Rewarder>(&p0.rewarders, _v4);
            let _v8 = *&_v7.emissions_per_second * _v2;
            let _v9 = *&_v7.user_owed;
            let _v10 = _v8 + _v9;
            let _v11 = fungible_asset::balance<fungible_asset::FungibleStore>(*&_v7.reward_store);
            if (_v10 < _v11) _v6 = fungible_asset::balance<fungible_asset::FungibleStore>(*&_v7.reward_store) - _v10 else _v6 = 0;
            let _v12 = &mut _v3;
            let _v13 = fungible_asset::store_metadata<fungible_asset::FungibleStore>(*&_v7.reward_store);
            let _v14 = fungible_asset::balance<fungible_asset::FungibleStore>(*&_v7.reward_store);
            let _v15 = *&_v7.user_owed;
            let _v16 = *&_v7.emissions_per_second;
            let _v17 = *&_v7.emissions_per_second_max;
            let _v18 = NumbersV1{reward_fa: _v13, pending: _v15, balance: _v14, remaining_emission: _v6, emission_per_second: _v16, emission_per_second_max: _v17};
            vector::push_back<NumbersV1>(_v12, _v18);
            _v4 = _v4 + 1;
            continue
        };
        _v3
    }
    friend fun pending_rewards(p0: &RewarderManager, p1: vector<PositionReward>, p2: vector<u128>, p3: u128): vector<PendingReward> {
        let _v0 = vector::empty<PendingReward>();
        let _v1 = vector::length<Rewarder>(&p0.rewarders);
        let _v2 = vector::length<PositionReward>(&p1);
        let _v3 = vector::empty<PositionReward>();
        assert!(_v1 >= _v2, 1100003);
        let _v4 = 0;
        loop {
            let _v5;
            if (!(_v1 != 0)) break;
            _v1 = _v1 - 1;
            let _v6 = vector::borrow<Rewarder>(&p0.rewarders, _v1);
            let _v7 = vector::borrow_mut<u128>(&mut p2, _v1);
            let _v8 = _v1 + 1;
            if (_v2 < _v8) {
                let _v9 = &mut _v3;
                let _v10 = PositionReward{emissions_per_liquidity_inside: 0u128, amount_owned: 0};
                vector::push_back<PositionReward>(_v9, _v10);
                _v5 = vector::borrow_mut<PositionReward>(&mut _v3, _v4)
            } else _v5 = vector::borrow_mut<PositionReward>(&mut p1, _v1);
            let _v11 = *_v7;
            let _v12 = *&_v5.emissions_per_liquidity_inside;
            let (_v13,_v14) = math_u128::overflowing_sub(_v11, _v12);
            let _v15 = *&_v5.amount_owned;
            let _v16 = (_v13 * p3 >> 64u8) as u64;
            _v15 = _v15 + _v16;
            let _v17 = &mut _v5.amount_owned;
            *_v17 = _v15;
            let _v18 = *_v7;
            let _v19 = &mut _v5.emissions_per_liquidity_inside;
            *_v19 = _v18;
            let _v20 = &mut _v0;
            let _v21 = PendingReward{reward_fa: fungible_asset::store_metadata<fungible_asset::FungibleStore>(*&_v6.reward_store), amount_owed: _v15};
            vector::push_back<PendingReward>(_v20, _v21);
            _v4 = _v4 + 1;
            continue
        };
        let _v22 = p1;
        _v4 = vector::length<PositionReward>(&_v22);
        while (_v4 > 0) {
            let _v23 = vector::pop_back<PositionReward>(&mut _v22);
            _v4 = _v4 - 1;
            continue
        };
        vector::destroy_empty<PositionReward>(_v22);
        vector::reverse<PendingReward>(&mut _v0);
        _v0
    }
    public fun pending_rewards_unpack(p0: &PendingReward): (object::Object<fungible_asset::Metadata>, u64) {
        let _v0 = *&p0.reward_fa;
        let _v1 = *&p0.amount_owed;
        (_v0, _v1)
    }
    friend fun position_reward_rate(p0: &RewarderManager, p1: u128, p2: u128): vector<RewardRate> {
        let _v0 = vector::empty<RewardRate>();
        let _v1 = vector::length<Rewarder>(&p0.rewarders);
        while (_v1 != 0) {
            _v1 = _v1 - 1;
            let _v2 = vector::borrow<Rewarder>(&p0.rewarders, _v1);
            let _v3 = (((*&_v2.emissions_per_second) as u128) >> 64u8) / p1 * p2;
            let _v4 = &mut _v0;
            let _v5 = RewardRate{reward_fa: fungible_asset::store_metadata<fungible_asset::FungibleStore>(*&_v2.reward_store), rate: _v3};
            vector::push_back<RewardRate>(_v4, _v5);
            continue
        };
        vector::reverse<RewardRate>(&mut _v0);
        _v0
    }
    friend fun refresh_position_rewarder_to_zero(p0: &mut RewarderManager, p1: vector<PositionReward>, p2: vector<u128>): vector<PositionReward> {
        let _v0 = vector::length<Rewarder>(&p0.rewarders);
        let _v1 = vector::length<PositionReward>(&p1);
        let _v2 = vector::empty<PositionReward>();
        assert!(_v0 >= _v1, 1100003);
        let _v3 = 0;
        loop {
            let _v4;
            if (!(_v0 != 0)) break;
            _v0 = _v0 - 1;
            let _v5 = vector::borrow_mut<u128>(&mut p2, _v0);
            let _v6 = _v0 + 1;
            if (_v1 < _v6) {
                let _v7 = &mut _v2;
                let _v8 = PositionReward{emissions_per_liquidity_inside: 0u128, amount_owned: 0};
                vector::push_back<PositionReward>(_v7, _v8);
                _v4 = vector::borrow_mut<PositionReward>(&mut _v2, _v3)
            } else _v4 = vector::borrow_mut<PositionReward>(&mut p1, _v0);
            let _v9 = &mut _v4.amount_owned;
            *_v9 = 0;
            let _v10 = *_v5;
            let _v11 = &mut _v4.emissions_per_liquidity_inside;
            *_v11 = _v10;
            _v3 = _v3 + 1;
            continue
        };
        vector::reverse<PositionReward>(&mut _v2);
        vector::append<PositionReward>(&mut p1, _v2);
        p1
    }
    friend fun remaining_incentive(p0: &RewarderManager): vector<RemainingIncentive> {
        let _v0 = timestamp::now_seconds();
        let _v1 = *&p0.last_updated_time;
        let _v2 = _v0 - _v1;
        let _v3 = vector::empty<RemainingIncentive>();
        let _v4 = 0;
        let _v5 = vector::length<Rewarder>(&p0.rewarders);
        loop {
            let _v6;
            if (!(_v4 < _v5)) break;
            let _v7 = vector::borrow<Rewarder>(&p0.rewarders, _v4);
            let _v8 = *&_v7.emissions_per_second * _v2;
            let _v9 = *&_v7.user_owed;
            let _v10 = _v8 + _v9;
            let _v11 = fungible_asset::balance<fungible_asset::FungibleStore>(*&_v7.reward_store);
            if (_v10 < _v11) _v6 = fungible_asset::balance<fungible_asset::FungibleStore>(*&_v7.reward_store) - _v10 else _v6 = 0;
            let _v12 = &mut _v3;
            let _v13 = RemainingIncentive{reward_fa: fungible_asset::store_metadata<fungible_asset::FungibleStore>(*&_v7.reward_store), remaining: _v6};
            vector::push_back<RemainingIncentive>(_v12, _v13);
            _v4 = _v4 + 1;
            continue
        };
        _v3
    }
    friend fun remove_incentive(p0: &signer, p1: &mut RewarderManager, p2: u128, p3: u64, p4: u64): fungible_asset::FungibleAsset {
        flash(p1, p2);
        let _v0 = vector::borrow_mut<Rewarder>(&mut p1.rewarders, p3);
        if (*&_v0.pause) abort 1100004;
        let _v1 = fungible_asset::balance<fungible_asset::FungibleStore>(*&_v0.reward_store);
        let _v2 = *&_v0.user_owed;
        assert!(_v1 - _v2 >= p4, 1100001);
        let _v3 = signer::address_of(p0);
        let _v4 = fungible_asset::store_metadata<fungible_asset::FungibleStore>(*&_v0.reward_store);
        event::emit<RemoveIncentiveEvent>(RemoveIncentiveEvent{pool_id: _v3, reward_metadata: _v4, amount: p4, index: p3});
        let _v5 = _v1 - p4;
        let _v6 = *&_v0.user_owed;
        if (_v5 == _v6) {
            let _v7 = &mut _v0.pause;
            *_v7 = true
        };
        let _v8 = *&_v0.reward_store;
        dispatchable_fungible_asset::withdraw<fungible_asset::FungibleStore>(p0, _v8, p4)
    }
    friend fun remove_incentive_to_pause(p0: &signer, p1: &mut RewarderManager, p2: u128, p3: u64): fungible_asset::FungibleAsset {
        flash(p1, p2);
        let _v0 = vector::borrow_mut<Rewarder>(&mut p1.rewarders, p3);
        if (*&_v0.pause) abort 1100004;
        let _v1 = fungible_asset::balance<fungible_asset::FungibleStore>(*&_v0.reward_store);
        let _v2 = *&_v0.user_owed;
        let _v3 = _v1 - _v2;
        let _v4 = signer::address_of(p0);
        let _v5 = fungible_asset::store_metadata<fungible_asset::FungibleStore>(*&_v0.reward_store);
        event::emit<RemoveIncentiveEvent>(RemoveIncentiveEvent{pool_id: _v4, reward_metadata: _v5, amount: _v3, index: p3});
        let _v6 = &mut _v0.pause;
        *_v6 = true;
        let _v7 = *&_v0.reward_store;
        dispatchable_fungible_asset::withdraw<fungible_asset::FungibleStore>(p0, _v7, _v3)
    }
    friend fun set_pause(p0: &mut RewarderManager, p1: bool) {
        let _v0 = &mut p0.pause;
        *_v0 = p1;
    }
    friend fun set_rewarder_op_admin(p0: &signer, p1: address, p2: address, p3: u64) {
        let _v0 = rewarder_label(p2, p3);
        if (!user_label::is_label_legal(_v0)) user_label::add_label_enum_internal(_v0);
        user_label::set_user_label_internal(p1, _v0);
    }
    friend fun update_emissions_rate(p0: address, p1: &mut RewarderManager, p2: u128, p3: u64, p4: u64) {
        flash(p1, p2);
        let _v0 = vector::borrow_mut<Rewarder>(&mut p1.rewarders, p3);
        assert!(p4 != 0, 11000002);
        let _v1 = *&_v0.emissions_per_second_max;
        assert!(p4 <= _v1, 11000002);
        let _v2 = fungible_asset::store_metadata<fungible_asset::FungibleStore>(*&_v0.reward_store);
        let _v3 = *&_v0.emissions_per_second;
        event::emit<RewardEmissionUpdateEvent>(RewardEmissionUpdateEvent{pool_id: p0, reward_fa: _v2, old_emission_rate: _v3, new_emission_rate: p4, index: p3});
        let _v4 = &mut _v0.emissions_per_second;
        *_v4 = p4;
    }
    friend fun update_emissions_rate_max(p0: address, p1: &mut RewarderManager, p2: u128, p3: u64, p4: u64) {
        flash(p1, p2);
        let _v0 = vector::borrow_mut<Rewarder>(&mut p1.rewarders, p3);
        assert!(p4 != 0, 11000002);
        let _v1 = *&_v0.emissions_per_second;
        assert!(p4 >= _v1, 11000002);
        let _v2 = fungible_asset::store_metadata<fungible_asset::FungibleStore>(*&_v0.reward_store);
        let _v3 = *&_v0.emissions_per_second_max;
        event::emit<RewardEmissionMaxUpdateEvent>(RewardEmissionMaxUpdateEvent{pool_id: p0, reward_fa: _v2, old_emission_rate_max: _v3, new_emission_rate_max: p4, index: p3});
        let _v4 = &mut _v0.emissions_per_second_max;
        *_v4 = p4;
    }
    friend fun update_rewarder_owed(p0: &mut RewarderManager, p1: u64, p2: u64) {
        if (*&p0.pause) abort 1100005;
        let _v0 = vector::borrow_mut<Rewarder>(&mut p0.rewarders, p1);
        event::emit<RewarderOwedUpdate>(RewarderOwedUpdate{owed_before: *&_v0.user_owed, owed_after: p2});
        let _v1 = &mut _v0.user_owed;
        *_v1 = p2;
    }
    friend fun user_managed_rewarders(p0: address): vector<string::String> {
        let _v0 = user_label::get_user_labels(p0);
        let _v1 = string::utf8(vector[114u8, 101u8, 119u8, 97u8, 114u8, 100u8, 101u8, 114u8, 95u8]);
        let _v2 = vector::empty<string::String>();
        let _v3 = _v0;
        vector::reverse<string::String>(&mut _v3);
        let _v4 = _v3;
        let _v5 = vector::length<string::String>(&_v4);
        loop {
            let _v6;
            if (!(_v5 > 0)) break;
            let _v7 = vector::pop_back<string::String>(&mut _v4);
            let _v8 = &_v7;
            let _v9 = string::length(_v8);
            let _v10 = &_v1;
            if (string::index_of(_v8, _v10) != _v9) _v6 = true else _v6 = false;
            if (_v6) vector::push_back<string::String>(&mut _v2, _v7);
            _v5 = _v5 - 1;
            continue
        };
        vector::destroy_empty<string::String>(_v4);
        _v2
    }
}
