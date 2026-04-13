module 0xd6e31e55a750d442bcfb60bbf842d152b102ffa5ac3ae3f2c8b43748c36a3e6f::view {
    use 0x1::object;
    use 0x1::fungible_asset;
    use 0xd6e31e55a750d442bcfb60bbf842d152b102ffa5ac3ae3f2c8b43748c36a3e6f::xrion;
    use 0x1::vector;
    use 0x1::option;
    use 0x1::timestamp;
    struct EpochForView has copy, drop, store {
        time: u64,
        xrion: u64,
    }
    struct PendingReward has copy, drop, store {
        epoch_time: u64,
        reward: vector<RewardForView>,
        claimed: bool,
    }
    struct RewardForView has copy, drop, store {
        meta: object::Object<fungible_asset::Metadata>,
        reward_amount: u64,
    }
    struct StakeData has copy, drop, store {
        position: object::Object<xrion::StakeDetails>,
        xrion_amount: vector<EpochForView>,
        stake_amount: u64,
        stake_time: u64,
        unlock_time: u64,
        total_stake_amount: u64,
        maximum_capability: u64,
        hyperion_start_time: u64,
        maximum_time: u64,
    }
    public fun epoch_xrion(p0: u64): u64 {
        xrion::get_epoch_xrion(p0)
    }
    public fun get_stake_and_xrion_amount(p0: address, p1: object::Object<xrion::StakeDetails>): (u64, u64, u64) {
        let (_v0,_v1,_v2) = xrion::get_stake_and_xrion_amount(p0, p1);
        (_v0, _v1, _v2)
    }
    public fun batch_left_period(p0: vector<object::Object<xrion::StakeDetails>>): vector<u64> {
        let _v0 = vector::empty<u64>();
        let _v1 = p0;
        vector::reverse<object::Object<xrion::StakeDetails>>(&mut _v1);
        let _v2 = _v1;
        let _v3 = vector::length<object::Object<xrion::StakeDetails>>(&_v2);
        while (_v3 > 0) {
            let _v4 = left_period(vector::pop_back<object::Object<xrion::StakeDetails>>(&mut _v2));
            if (_v4 < 53) vector::push_back<u64>(&mut _v0, _v4) else vector::push_back<u64>(&mut _v0, 0);
            _v3 = _v3 - 1;
            continue
        };
        vector::destroy_empty<object::Object<xrion::StakeDetails>>(_v2);
        _v0
    }
    public fun left_period(p0: object::Object<xrion::StakeDetails>): u64 {
        xrion::get_left_period(p0)
    }
    public fun batch_left_period_by_address(p0: vector<address>): vector<u64> {
        let _v0 = vector::empty<u64>();
        let _v1 = p0;
        vector::reverse<address>(&mut _v1);
        let _v2 = _v1;
        let _v3 = vector::length<address>(&_v2);
        while (_v3 > 0) {
            let _v4 = left_period(object::address_to_object<xrion::StakeDetails>(vector::pop_back<address>(&mut _v2)));
            if (_v4 < 53) vector::push_back<u64>(&mut _v0, _v4) else vector::push_back<u64>(&mut _v0, 0);
            _v3 = _v3 - 1;
            continue
        };
        vector::destroy_empty<address>(_v2);
        _v0
    }
    fun create_epoch_for_view(p0: vector<u64>, p1: vector<u64>): vector<EpochForView> {
        let _v0 = vector::empty<EpochForView>();
        let _v1 = 0;
        let _v2 = false;
        let _v3 = vector::length<u64>(&p0);
        loop {
            if (_v2) _v1 = _v1 + 1 else _v2 = true;
            if (!(_v1 < _v3)) break;
            let _v4 = &mut _v0;
            let _v5 = *vector::borrow<u64>(&p0, _v1);
            let _v6 = *vector::borrow<u64>(&p1, _v1);
            let _v7 = EpochForView{time: _v5, xrion: _v6};
            vector::push_back<EpochForView>(_v4, _v7);
            continue
        };
        _v0
    }
    fun create_reward_v(p0: vector<object::Object<fungible_asset::Metadata>>, p1: vector<u64>): vector<RewardForView> {
        let _v0 = vector::length<object::Object<fungible_asset::Metadata>>(&p0);
        let _v1 = vector::length<u64>(&p1);
        assert!(_v0 == _v1, 1);
        let _v2 = vector::empty<RewardForView>();
        let _v3 = 0;
        let _v4 = false;
        let _v5 = vector::length<object::Object<fungible_asset::Metadata>>(&p0);
        loop {
            if (_v4) _v3 = _v3 + 1 else _v4 = true;
            if (!(_v3 < _v5)) break;
            let _v6 = &mut _v2;
            let _v7 = *vector::borrow<object::Object<fungible_asset::Metadata>>(&p0, _v3);
            let _v8 = *vector::borrow<u64>(&p1, _v3);
            let _v9 = RewardForView{meta: _v7, reward_amount: _v8};
            vector::push_back<RewardForView>(_v6, _v9);
            continue
        };
        _v2
    }
    public fun epoch_key(): vector<u64> {
        xrion::epoch_key_list()
    }
    public fun get_address_epoch_reward(p0: vector<object::Object<xrion::StakeDetails>>, p1: option::Option<u64>): vector<vector<RewardForView>> {
        let _v0;
        let _v1 = vector::empty<vector<RewardForView>>();
        if (option::is_some<u64>(&p1)) _v0 = option::destroy_some<u64>(p1) else _v0 = xrion::get_current_time() as u64;
        let _v2 = 0;
        let _v3 = false;
        let _v4 = vector::length<object::Object<xrion::StakeDetails>>(&p0);
        loop {
            if (_v3) _v2 = _v2 + 1 else _v3 = true;
            if (!(_v2 < _v4)) break;
            let _v5 = *vector::borrow<object::Object<xrion::StakeDetails>>(&p0, _v2);
            let (_v6,_v7) = xrion::cal_last_reward(_v0, _v5);
            let _v8 = &mut _v1;
            let _v9 = create_reward_v(_v6, _v7);
            vector::push_back<vector<RewardForView>>(_v8, _v9);
            continue
        };
        _v1
    }
    public fun get_address_epoch_reward_by_address(p0: vector<address>, p1: option::Option<u64>): vector<vector<RewardForView>> {
        let _v0;
        let _v1 = vector::empty<vector<RewardForView>>();
        if (option::is_some<u64>(&p1)) _v0 = option::destroy_some<u64>(p1) else _v0 = xrion::get_current_time() as u64;
        let _v2 = 0;
        let _v3 = false;
        let _v4 = vector::length<address>(&p0);
        loop {
            if (_v3) _v2 = _v2 + 1 else _v3 = true;
            if (!(_v2 < _v4)) break;
            let _v5 = object::address_to_object<xrion::StakeDetails>(*vector::borrow<address>(&p0, _v2));
            let (_v6,_v7) = xrion::cal_last_reward(_v0, _v5);
            let _v8 = &mut _v1;
            let _v9 = create_reward_v(_v6, _v7);
            vector::push_back<vector<RewardForView>>(_v8, _v9);
            continue
        };
        _v1
    }
    public fun get_all_reward(p0: address): vector<RewardForView> {
        let _v0 = get_own_token(p0);
        let _v1 = vector::empty<RewardForView>();
        let _v2 = 0;
        let _v3 = false;
        let _v4 = vector::length<object::Object<xrion::StakeDetails>>(&_v0);
        loop {
            if (_v3) _v2 = _v2 + 1 else _v3 = true;
            if (!(_v2 < _v4)) break;
            let _v5 = *vector::borrow<object::Object<xrion::StakeDetails>>(&_v0, _v2);
            let _v6 = pending_claim_reward(p0, _v5);
            let _v7 = &_v6;
            let _v8 = 0;
            let _v9 = vector::length<PendingReward>(_v7);
            while (_v8 < _v9) {
                let _v10 = vector::borrow<PendingReward>(_v7, _v8);
                if (!*&_v10.claimed) {
                    let _v11 = &_v10.reward;
                    let _v12 = 0;
                    let _v13 = vector::length<RewardForView>(_v11);
                    while (_v12 < _v13) {
                        let _v14 = vector::borrow<RewardForView>(_v11, _v12);
                        let _v15 = *&_v14.meta;
                        let _v16 = &_v1;
                        let _v17 = false;
                        let _v18 = 0;
                        let _v19 = 0;
                        let _v20 = vector::length<RewardForView>(_v16);
                        'l0: loop {
                            loop {
                                if (!(_v19 < _v20)) break 'l0;
                                let _v21 = &vector::borrow<RewardForView>(_v16, _v19).meta;
                                let _v22 = &_v15;
                                if (_v21 == _v22) break;
                                _v19 = _v19 + 1;
                                continue
                            };
                            _v17 = true;
                            _v18 = _v19;
                            break
                        };
                        if (_v17) {
                            let _v23 = *&_v14.reward_amount;
                            let _v24 = &mut vector::borrow_mut<RewardForView>(&mut _v1, _v18).reward_amount;
                            *_v24 = *_v24 + _v23
                        } else {
                            let _v25 = &mut _v1;
                            let _v26 = *&_v14.reward_amount;
                            let _v27 = RewardForView{meta: _v15, reward_amount: _v26};
                            vector::push_back<RewardForView>(_v25, _v27)
                        };
                        _v12 = _v12 + 1;
                        continue
                    }
                };
                _v8 = _v8 + 1;
                continue
            };
            continue
        };
        _v1
    }
    public fun get_own_token(p0: address): vector<object::Object<xrion::StakeDetails>> {
        xrion::get_token_data(p0)
    }
    public fun pending_claim_reward(p0: address, p1: object::Object<xrion::StakeDetails>): vector<PendingReward> {
        let (_v0,_v1,_v2,_v3) = xrion::get_pending_reward(p0, p1);
        let _v4 = _v3;
        let _v5 = _v2;
        let _v6 = _v1;
        let _v7 = _v0;
        let _v8 = vector::empty<PendingReward>();
        let _v9 = 0;
        let _v10 = false;
        let _v11 = vector::length<vector<object::Object<fungible_asset::Metadata>>>(&_v5);
        loop {
            if (_v10) _v9 = _v9 + 1 else _v10 = true;
            if (!(_v9 < _v11)) break;
            let _v12 = vector::empty<RewardForView>();
            let _v13 = vector::borrow<vector<object::Object<fungible_asset::Metadata>>>(&_v5, _v9);
            let _v14 = vector::borrow<vector<u64>>(&_v6, _v9);
            let _v15 = 0;
            let _v16 = false;
            let _v17 = vector::length<object::Object<fungible_asset::Metadata>>(_v13);
            loop {
                if (_v16) _v15 = _v15 + 1 else _v16 = true;
                if (!(_v15 < _v17)) break;
                let _v18 = &mut _v12;
                let _v19 = *vector::borrow<object::Object<fungible_asset::Metadata>>(_v13, _v15);
                let _v20 = *vector::borrow<u64>(_v14, _v15);
                let _v21 = RewardForView{meta: _v19, reward_amount: _v20};
                vector::push_back<RewardForView>(_v18, _v21);
                continue
            };
            let _v22 = &mut _v8;
            let _v23 = *vector::borrow<u64>(&_v7, _v9);
            let _v24 = *vector::borrow<bool>(&_v4, _v9);
            let _v25 = PendingReward{epoch_time: _v23, reward: _v12, claimed: _v24};
            vector::push_back<PendingReward>(_v22, _v25);
            continue
        };
        _v8
    }
    public fun get_all_reward_without_limit(p0: address): vector<RewardForView> {
        let _v0 = get_own_token(p0);
        let _v1 = vector::empty<RewardForView>();
        let _v2 = 0;
        let _v3 = false;
        let _v4 = vector::length<object::Object<xrion::StakeDetails>>(&_v0);
        loop {
            if (_v3) _v2 = _v2 + 1 else _v3 = true;
            if (!(_v2 < _v4)) break;
            let _v5 = *vector::borrow<object::Object<xrion::StakeDetails>>(&_v0, _v2);
            let _v6 = pending_claim_reward_without_limit(p0, _v5);
            let _v7 = &_v6;
            let _v8 = 0;
            let _v9 = vector::length<PendingReward>(_v7);
            while (_v8 < _v9) {
                let _v10 = vector::borrow<PendingReward>(_v7, _v8);
                if (!*&_v10.claimed) {
                    let _v11 = &_v10.reward;
                    let _v12 = 0;
                    let _v13 = vector::length<RewardForView>(_v11);
                    while (_v12 < _v13) {
                        let _v14 = vector::borrow<RewardForView>(_v11, _v12);
                        let _v15 = *&_v14.meta;
                        let _v16 = &_v1;
                        let _v17 = false;
                        let _v18 = 0;
                        let _v19 = 0;
                        let _v20 = vector::length<RewardForView>(_v16);
                        'l0: loop {
                            loop {
                                if (!(_v19 < _v20)) break 'l0;
                                let _v21 = &vector::borrow<RewardForView>(_v16, _v19).meta;
                                let _v22 = &_v15;
                                if (_v21 == _v22) break;
                                _v19 = _v19 + 1;
                                continue
                            };
                            _v17 = true;
                            _v18 = _v19;
                            break
                        };
                        if (_v17) {
                            let _v23 = *&_v14.reward_amount;
                            let _v24 = &mut vector::borrow_mut<RewardForView>(&mut _v1, _v18).reward_amount;
                            *_v24 = *_v24 + _v23
                        } else {
                            let _v25 = &mut _v1;
                            let _v26 = *&_v14.reward_amount;
                            let _v27 = RewardForView{meta: _v15, reward_amount: _v26};
                            vector::push_back<RewardForView>(_v25, _v27)
                        };
                        _v12 = _v12 + 1;
                        continue
                    }
                };
                _v8 = _v8 + 1;
                continue
            };
            continue
        };
        _v1
    }
    fun pending_claim_reward_without_limit(p0: address, p1: object::Object<xrion::StakeDetails>): vector<PendingReward> {
        let (_v0,_v1,_v2,_v3) = xrion::get_pending_reward_without_limit(p0, p1);
        let _v4 = _v3;
        let _v5 = _v2;
        let _v6 = _v1;
        let _v7 = _v0;
        let _v8 = vector::empty<PendingReward>();
        let _v9 = 0;
        let _v10 = false;
        let _v11 = vector::length<vector<object::Object<fungible_asset::Metadata>>>(&_v5);
        loop {
            if (_v10) _v9 = _v9 + 1 else _v10 = true;
            if (!(_v9 < _v11)) break;
            let _v12 = vector::empty<RewardForView>();
            let _v13 = vector::borrow<vector<object::Object<fungible_asset::Metadata>>>(&_v5, _v9);
            let _v14 = vector::borrow<vector<u64>>(&_v6, _v9);
            let _v15 = 0;
            let _v16 = false;
            let _v17 = vector::length<object::Object<fungible_asset::Metadata>>(_v13);
            loop {
                if (_v16) _v15 = _v15 + 1 else _v16 = true;
                if (!(_v15 < _v17)) break;
                let _v18 = &mut _v12;
                let _v19 = *vector::borrow<object::Object<fungible_asset::Metadata>>(_v13, _v15);
                let _v20 = *vector::borrow<u64>(_v14, _v15);
                let _v21 = RewardForView{meta: _v19, reward_amount: _v20};
                vector::push_back<RewardForView>(_v18, _v21);
                continue
            };
            let _v22 = &mut _v8;
            let _v23 = *vector::borrow<u64>(&_v7, _v9);
            let _v24 = *vector::borrow<bool>(&_v4, _v9);
            let _v25 = PendingReward{epoch_time: _v23, reward: _v12, claimed: _v24};
            vector::push_back<PendingReward>(_v22, _v25);
            continue
        };
        _v8
    }
    public fun get_all_stake_details(p0: address): vector<StakeData> {
        let _v0 = get_own_token(p0);
        let _v1 = vector::empty<StakeData>();
        let _v2 = 0;
        let _v3 = false;
        let _v4 = vector::length<object::Object<xrion::StakeDetails>>(&_v0);
        loop {
            if (_v3) _v2 = _v2 + 1 else _v3 = true;
            if (!(_v2 < _v4)) break;
            let _v5 = *vector::borrow<object::Object<xrion::StakeDetails>>(&_v0, _v2);
            let _v6 = get_stake_details(p0, _v5);
            vector::push_back<StakeData>(&mut _v1, _v6);
            continue
        };
        _v1
    }
    public fun get_stake_details(p0: address, p1: object::Object<xrion::StakeDetails>): StakeData {
        let (_v0,_v1,_v2,_v3,_v4) = xrion::get_stake_data(p0, p1);
        let (_v5,_v6,_v7,_v8,_v9) = xrion::get_total_stake_amount_maximum_time();
        let _v10 = create_epoch_for_view(_v0, _v1);
        StakeData{position: p1, xrion_amount: _v10, stake_amount: _v2, stake_time: _v3, unlock_time: _v4, total_stake_amount: _v5, maximum_capability: _v6, hyperion_start_time: _v7, maximum_time: _v8}
    }
    fun get_apt_meta(): object::Object<fungible_asset::Metadata> {
        object::address_to_object<fungible_asset::Metadata>(@0xa)
    }
    public fun get_current_reward(): (u64, vector<RewardForView>, bool) {
        let (_v0,_v1,_v2,_v3) = xrion::check_epoch_reward(xrion::get_current_time() as u64);
        let _v4 = _v2;
        let _v5 = _v1;
        let _v6 = vector::empty<RewardForView>();
        let _v7 = 0;
        let _v8 = false;
        let _v9 = vector::length<object::Object<fungible_asset::Metadata>>(&_v5);
        loop {
            if (_v8) _v7 = _v7 + 1 else _v8 = true;
            if (!(_v7 < _v9)) break;
            let _v10 = &mut _v6;
            let _v11 = *vector::borrow<object::Object<fungible_asset::Metadata>>(&_v5, _v7);
            let _v12 = *vector::borrow<u64>(&_v4, _v7);
            let _v13 = RewardForView{meta: _v11, reward_amount: _v12};
            vector::push_back<RewardForView>(_v10, _v13);
            continue
        };
        (_v0, _v6, _v3)
    }
    public fun get_current_total_xrion(p0: address): u64 {
        let _v0 = get_own_token(p0);
        let _v1 = xrion::get_current_time() as u64;
        let _v2 = 0;
        let _v3 = 0;
        let _v4 = false;
        let _v5 = vector::length<object::Object<xrion::StakeDetails>>(&_v0);
        loop {
            if (_v4) _v3 = _v3 + 1 else _v4 = true;
            if (!(_v3 < _v5)) break;
            let _v6 = *vector::borrow<object::Object<xrion::StakeDetails>>(&_v0, _v3);
            let _v7 = get_stake_details(p0, _v6);
            let _v8 = timestamp::now_seconds();
            let _v9 = *&(&_v7).unlock_time;
            if (!(_v8 <= _v9)) continue;
            let _v10 = &(&_v7).xrion_amount;
            let _v11 = false;
            let _v12 = 0;
            let _v13 = 0;
            let _v14 = vector::length<EpochForView>(_v10);
            'l0: loop {
                loop {
                    if (!(_v13 < _v14)) break 'l0;
                    if (*&vector::borrow<EpochForView>(_v10, _v13).time == _v1) break;
                    _v13 = _v13 + 1
                };
                _v11 = true;
                _v12 = _v13;
                break
            };
            let _v15 = _v12;
            if (!_v11) continue;
            _v15 = *&vector::borrow<EpochForView>(&(&_v7).xrion_amount, _v15).xrion;
            _v2 = _v2 + _v15;
            continue
        };
        _v2
    }
    public fun get_reward_remain_and_total(): (u64, u64) {
        let _v0 = epoch_key();
        let _v1 = 0;
        let _v2 = 0;
        let _v3 = get_apt_meta();
        let _v4 = &_v0;
        let _v5 = 0;
        let _v6 = vector::length<u64>(_v4);
        while (_v5 < _v6) {
            let _v7 = vector::borrow<u64>(_v4, _v5);
            let (_v8,_v9) = xrion::reward_remain(*_v7);
            let _v10 = _v9;
            let _v11 = _v8;
            let _v12 = 0;
            let _v13 = false;
            let _v14 = vector::length<object::Object<fungible_asset::Metadata>>(&_v11);
            loop {
                if (_v13) _v12 = _v12 + 1 else _v13 = true;
                if (!(_v12 < _v14)) break;
                if (!(*vector::borrow<object::Object<fungible_asset::Metadata>>(&_v11, _v12) == _v3)) continue;
                let _v15 = *vector::borrow<u64>(&_v10, _v12);
                _v1 = _v1 + _v15;
                continue
            };
            let (_v16,_v17,_v18,_v19) = xrion::check_epoch_reward(*_v7);
            let _v20 = _v18;
            let _v21 = _v17;
            let _v22 = 0;
            let _v23 = false;
            let _v24 = vector::length<object::Object<fungible_asset::Metadata>>(&_v21);
            loop {
                if (_v23) _v22 = _v22 + 1 else _v23 = true;
                if (!(_v22 < _v24)) break;
                if (!(*vector::borrow<object::Object<fungible_asset::Metadata>>(&_v11, _v22) == _v3)) continue;
                let _v25 = *vector::borrow<u64>(&_v20, _v22);
                _v2 = _v2 + _v25;
                continue
            };
            _v5 = _v5 + 1;
            continue
        };
        (_v1, _v2)
    }
    public fun get_reward_remain_and_total_multi_reward(): vector<RewardForView> {
        let _v0 = epoch_key();
        let _v1 = vector::empty<RewardForView>();
        let _v2 = &_v0;
        let _v3 = 0;
        let _v4 = vector::length<u64>(_v2);
        while (_v3 < _v4) {
            let (_v5,_v6,_v7,_v8) = xrion::check_epoch_reward(*vector::borrow<u64>(_v2, _v3));
            let _v9 = _v7;
            let _v10 = _v6;
            let _v11 = 0;
            let _v12 = false;
            let _v13 = vector::length<object::Object<fungible_asset::Metadata>>(&_v10);
            loop {
                if (_v12) _v11 = _v11 + 1 else _v12 = true;
                if (!(_v11 < _v13)) break;
                let _v14 = &_v1;
                let _v15 = false;
                let _v16 = 0;
                let _v17 = 0;
                let _v18 = vector::length<RewardForView>(_v14);
                'l0: loop {
                    loop {
                        if (!(_v17 < _v18)) break 'l0;
                        let _v19 = *&vector::borrow<RewardForView>(_v14, _v17).meta;
                        let _v20 = *vector::borrow<object::Object<fungible_asset::Metadata>>(&_v10, _v11);
                        if (_v19 == _v20) break;
                        _v17 = _v17 + 1;
                        continue
                    };
                    _v15 = true;
                    _v16 = _v17;
                    break
                };
                if (_v15) {
                    let _v21 = vector::borrow_mut<RewardForView>(&mut _v1, _v16);
                    let _v22 = *vector::borrow<u64>(&_v9, _v11);
                    let _v23 = &mut _v21.reward_amount;
                    *_v23 = *_v23 + _v22;
                    continue
                };
                let _v24 = &mut _v1;
                let _v25 = *vector::borrow<object::Object<fungible_asset::Metadata>>(&_v10, _v11);
                let _v26 = *vector::borrow<u64>(&_v9, _v11);
                let _v27 = RewardForView{meta: _v25, reward_amount: _v26};
                vector::push_back<RewardForView>(_v24, _v27);
                continue
            };
            _v3 = _v3 + 1;
            continue
        };
        _v1
    }
    public fun get_reward_remain_and_total_multi_reward_user(p0: address): vector<RewardForView> {
        let _v0 = vector::empty<RewardForView>();
        let _v1 = get_own_token(p0);
        let _v2 = xrion::get_current_time() as u64;
        let _v3 = vector::empty<RewardForView>();
        if (xrion::contain_epoch(_v2)) {
            let (_v4,_v5,_v6,_v7) = xrion::check_epoch_reward(_v2);
            let _v8 = _v6;
            let _v9 = _v5;
            let _v10 = 0;
            let _v11 = false;
            let _v12 = vector::length<object::Object<fungible_asset::Metadata>>(&_v9);
            loop {
                if (_v11) _v10 = _v10 + 1 else _v11 = true;
                if (!(_v10 < _v12)) break;
                let _v13 = &mut _v3;
                let _v14 = *vector::borrow<object::Object<fungible_asset::Metadata>>(&_v9, _v10);
                let _v15 = *vector::borrow<u64>(&_v8, _v10);
                let _v16 = RewardForView{meta: _v14, reward_amount: _v15};
                vector::push_back<RewardForView>(_v13, _v16);
                continue
            };
            let _v17 = epoch_xrion(_v2) as u256;
            let _v18 = _v1;
            vector::reverse<object::Object<xrion::StakeDetails>>(&mut _v18);
            let _v19 = _v18;
            let _v20 = vector::length<object::Object<xrion::StakeDetails>>(&_v19);
            while (_v20 > 0) {
                let _v21 = vector::pop_back<object::Object<xrion::StakeDetails>>(&mut _v19);
                let _v22 = xrion::user_epoch_xrion(_v2, _v21) as u256;
                let _v23 = 0;
                let _v24 = false;
                let _v25 = vector::length<RewardForView>(&_v3);
                loop {
                    if (_v24) _v23 = _v23 + 1 else _v24 = true;
                    if (!(_v23 < _v25)) break;
                    if (!(_v17 != 0u256)) continue;
                    let _v26 = xrion::view_reward((*&vector::borrow<RewardForView>(&_v3, _v23).reward_amount) as u256, _v22, _v17);
                    let _v27 = &_v0;
                    let _v28 = false;
                    let _v29 = 0;
                    let _v30 = 0;
                    let _v31 = vector::length<RewardForView>(_v27);
                    'l0: loop {
                        loop {
                            if (!(_v30 < _v31)) break 'l0;
                            let _v32 = *&vector::borrow<RewardForView>(_v27, _v30).meta;
                            let _v33 = *&vector::borrow<RewardForView>(&_v3, _v23).meta;
                            if (_v32 == _v33) break;
                            _v30 = _v30 + 1;
                            continue
                        };
                        _v28 = true;
                        _v29 = _v30;
                        break
                    };
                    if (_v28) {
                        let _v34 = &mut vector::borrow_mut<RewardForView>(&mut _v0, _v29).reward_amount;
                        *_v34 = *_v34 + _v26;
                        continue
                    };
                    let _v35 = &mut _v0;
                    let _v36 = RewardForView{meta: *&vector::borrow<RewardForView>(&_v3, _v23).meta, reward_amount: _v26};
                    vector::push_back<RewardForView>(_v35, _v36);
                    continue
                };
                _v20 = _v20 - 1;
                continue
            };
            vector::destroy_empty<object::Object<xrion::StakeDetails>>(_v19)
        };
        _v0
    }
    public fun get_reward_remain_and_total_user(p0: address): u64 {
        let _v0 = get_own_token(p0);
        let _v1 = 0;
        let _v2 = get_apt_meta();
        let _v3 = xrion::get_current_time() as u64;
        if (xrion::contain_epoch(_v3)) {
            let (_v4,_v5,_v6,_v7) = xrion::check_epoch_reward(_v3);
            let _v8 = _v6;
            let _v9 = _v5;
            let _v10 = 0;
            let _v11 = 0;
            let _v12 = false;
            let _v13 = vector::length<object::Object<fungible_asset::Metadata>>(&_v9);
            loop {
                if (_v12) _v11 = _v11 + 1 else _v12 = true;
                if (!(_v11 < _v13)) break;
                if (!(*vector::borrow<object::Object<fungible_asset::Metadata>>(&_v9, _v11) == _v2)) continue;
                _v10 = *vector::borrow<u64>(&_v8, _v11)
            };
            let _v14 = epoch_xrion(_v3) as u256;
            let _v15 = _v0;
            vector::reverse<object::Object<xrion::StakeDetails>>(&mut _v15);
            let _v16 = _v15;
            let _v17 = vector::length<object::Object<xrion::StakeDetails>>(&_v16);
            while (_v17 > 0) {
                let _v18 = vector::pop_back<object::Object<xrion::StakeDetails>>(&mut _v16);
                let _v19 = xrion::user_epoch_xrion(_v3, _v18) as u256;
                if (_v14 != 0u256) {
                    let _v20 = xrion::view_reward(_v10 as u256, _v19, _v14);
                    _v1 = _v1 + _v20
                };
                _v17 = _v17 - 1;
                continue
            };
            vector::destroy_empty<object::Object<xrion::StakeDetails>>(_v16)
        };
        _v1
    }
    fun get_rion_meta(): object::Object<fungible_asset::Metadata> {
        object::address_to_object<fungible_asset::Metadata>(@0x432c5ec8c21f9a6b73c4db11c311846be1a449037358218c4e8c610d9c05f398)
    }
    public fun get_store_fee_of_current_epoch(): (u64, u64, vector<RewardForView>) {
        let _v0 = xrion::get_current_time() as u64;
        let _v1 = vector::empty<RewardForView>();
        let (_v2,_v3) = xrion::get_store_of_current_epoch();
        let _v4 = _v3;
        let _v5 = _v2;
        let _v6 = 0;
        let _v7 = false;
        let _v8 = vector::length<object::Object<fungible_asset::Metadata>>(&_v5);
        loop {
            if (_v7) _v6 = _v6 + 1 else _v7 = true;
            if (!(_v6 < _v8)) break;
            let _v9 = &mut _v1;
            let _v10 = *vector::borrow<object::Object<fungible_asset::Metadata>>(&_v5, _v6);
            let _v11 = *vector::borrow<u64>(&_v4, _v6);
            let _v12 = RewardForView{meta: _v10, reward_amount: _v11};
            vector::push_back<RewardForView>(_v9, _v12);
            continue
        };
        let _v13 = vector::length<RewardForView>(&_v1);
        (_v0, _v13, _v1)
    }
    public fun get_store_fee_of_epoch(p0: u64): (u64, u64, vector<RewardForView>) {
        let _v0 = vector::empty<RewardForView>();
        let (_v1,_v2) = xrion::get_store_of_epoch(p0);
        let _v3 = _v2;
        let _v4 = _v1;
        let _v5 = 0;
        let _v6 = false;
        let _v7 = vector::length<object::Object<fungible_asset::Metadata>>(&_v4);
        loop {
            if (_v6) _v5 = _v5 + 1 else _v6 = true;
            if (!(_v5 < _v7)) break;
            let _v8 = &mut _v0;
            let _v9 = *vector::borrow<object::Object<fungible_asset::Metadata>>(&_v4, _v5);
            let _v10 = *vector::borrow<u64>(&_v3, _v5);
            let _v11 = RewardForView{meta: _v9, reward_amount: _v10};
            vector::push_back<RewardForView>(_v8, _v11);
            continue
        };
        let _v12 = vector::length<RewardForView>(&_v0);
        (p0, _v12, _v0)
    }
    public fun get_total_stake(): (u64, u64, u64, u64, object::Object<fungible_asset::Metadata>, u64) {
        let _v0 = xrion::get_period();
        let (_v1,_v2,_v3,_v4,_v5) = xrion::get_total_stake_amount_maximum_time();
        (_v1, _v2, _v3, _v4, _v5, _v0)
    }
    public fun last_epoch_can_claim(): bool {
        xrion::get_last_epoch_can_claim()
    }
    public fun preview(p0: u64, p1: u64): vector<xrion::PreviewEpoch> {
        xrion::preview_epoch(p0, p1)
    }
}
