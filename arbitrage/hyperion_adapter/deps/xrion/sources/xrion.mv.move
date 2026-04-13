module 0xd6e31e55a750d442bcfb60bbf842d152b102ffa5ac3ae3f2c8b43748c36a3e6f::xrion {
    use 0x1::object;
    use 0x1::fungible_asset;
    use 0x1::smart_table;
    use 0x1::smart_vector;
    use 0xd6e31e55a750d442bcfb60bbf842d152b102ffa5ac3ae3f2c8b43748c36a3e6f::blacklist;
    use 0x1::string;
    use 0xd6e31e55a750d442bcfb60bbf842d152b102ffa5ac3ae3f2c8b43748c36a3e6f::package_manager;
    use 0x1::table_with_length;
    use 0x1::timestamp;
    use 0x1::error;
    use 0x1::primary_fungible_store;
    use 0x1::vector;
    use 0x1::signer;
    use 0xd6e31e55a750d442bcfb60bbf842d152b102ffa5ac3ae3f2c8b43748c36a3e6f::send_event;
    use 0xd6e31e55a750d442bcfb60bbf842d152b102ffa5ac3ae3f2c8b43748c36a3e6f::permission_control;
    use 0x1::dispatchable_fungible_asset;
    friend 0xd6e31e55a750d442bcfb60bbf842d152b102ffa5ac3ae3f2c8b43748c36a3e6f::reward;
    struct ClaimRecord has store {
        owner: address,
        meta: object::Object<fungible_asset::Metadata>,
        amount: u64,
    }
    struct Epoch has store {
        can_claim: bool,
        epoch_time: u64,
        epoch_total_xrion_amount: u64,
        epoch_store: vector<object::Object<fungible_asset::FungibleStore>>,
        store_del: vector<object::DeleteRef>,
        claimed: smart_table::SmartTable<address, vector<ClaimRecord>>,
        reward: vector<Reward>,
    }
    struct Reward has store {
        total_amount: u64,
        del: object::DeleteRef,
        meta: object::Object<fungible_asset::Metadata>,
        store: object::Object<fungible_asset::FungibleStore>,
    }
    struct HyperionStake has store, key {
        meta: object::Object<fungible_asset::Metadata>,
        total_stake_amount: u64,
        user_stake_list: smart_table::SmartTable<address, vector<object::Object<StakeDetails>>>,
        epoch_list: smart_table::SmartTable<u64, Epoch>,
        stake: smart_vector::SmartVector<address>,
        period: u64,
        last_update_time: u64,
        start_time: u64,
        blacklist_amount: u64,
        blacklist_xrion: u64,
        pause: bool,
        maximum_stake_capability: u64,
        maximum_epoch_time: u64,
    }
    struct StakeDetails has store, key {
        status: blacklist::Status,
        store_del: object::DeleteRef,
        rion_store: object::Object<fungible_asset::FungibleStore>,
        reward: vector<UserReward>,
        list: vector<PersonalEpoch>,
        stake_time: u64,
        unlock_time: u64,
        claimed_epoch_cursor: u64,
        last_update_time: u64,
        object: address,
        object_ext: object::ExtendRef,
        object_del: object::DeleteRef,
    }
    struct UserReward has store, key {
        claimed_amount: u64,
        meta: object::Object<fungible_asset::Metadata>,
    }
    struct PersonalEpoch has copy, drop, store {
        claimed: bool,
        epoch_time: u64,
        epoch_current_xrion_amount: u64,
    }
    struct PreviewEpoch has copy, drop, store {
        epoch_time: u64,
        epoch_current_xrion_amount: u64,
    }
    public entry fun stake(p0: &signer, p1: u64, p2: u64)
        acquires HyperionStake
    {
        let _v0;
        ensure_not_paused();
        ensure_not_zero_period(p2);
        let _v1 = string::utf8(vector[115u8, 116u8, 97u8, 107u8, 101u8]);
        check_function_permission(p0, _v1);
        assert!(p1 <= 5000000000000, 46);
        if (!(p1 >= 1000000)) {
            let _v2 = error::aborted(15);
            abort _v2
        };
        let _v3 = package_manager::get_rion_address();
        let _v4 = borrow_global_mut<HyperionStake>(_v3);
        let _v5 = *&_v4.total_stake_amount + p1;
        let _v6 = *&_v4.maximum_stake_capability;
        if (!(_v5 <= _v6)) {
            let _v7 = error::aborted(34);
            abort _v7
        };
        if (!(p2 <= 52)) {
            let _v8 = error::aborted(16);
            abort _v8
        };
        let _v9 = *&_v4.meta;
        let _v10 = primary_fungible_store::withdraw<fungible_asset::Metadata>(p0, _v9, p1);
        let (_v11,_v12,_v13) = create_new_personal_epoch(_v4, p1, p2);
        let _v14 = _v11;
        if (!is_personal_epoch_list_sorted(&_v14)) heap_sort_personal_epoch(&mut _v14);
        if (!(vector::length<PersonalEpoch>(&_v14) > 0)) {
            let _v15 = error::aborted(20);
            abort _v15
        };
        let _v16 = *&vector::borrow<PersonalEpoch>(&_v14, 0).epoch_current_xrion_amount;
        let _v17 = vector::empty<PersonalEpoch>();
        let _v18 = &mut _v17;
        let _v19 = (*&_v4.start_time) as u256;
        let _v20 = (*&_v4.period) as u256;
        let _v21 = get_epoch_time(0u256, _v19, _v20, false) as u64;
        let _v22 = PersonalEpoch{claimed: false, epoch_time: _v21, epoch_current_xrion_amount: 0};
        vector::push_back<PersonalEpoch>(_v18, _v22);
        vector::append<PersonalEpoch>(&mut _v17, _v14);
        let _v23 = vector::empty<u64>();
        let _v24 = vector::empty<u64>();
        let _v25 = &mut _v23;
        let _v26 = *&vector::borrow<PersonalEpoch>(&_v17, 0).epoch_time;
        vector::push_back<u64>(_v25, _v26);
        vector::push_back<u64>(&mut _v24, 0);
        vector::append<u64>(&mut _v23, _v12);
        vector::append<u64>(&mut _v24, _v13);
        let _v27 = *&_v4.meta;
        let _v28 = *&_v4.period;
        let _v29 = *&_v4.start_time;
        let _v30 = create_stakedetails(_v27, _v10, p2, _v28, _v29, _v17);
        let _v31 = p1;
        let _v32 = &mut _v4.total_stake_amount;
        *_v32 = *_v32 + _v31;
        let _v33 = p2 as u256;
        let _v34 = (*&_v4.start_time) as u256;
        let _v35 = (*&_v4.period) as u256;
        let _v36 = get_epoch_time(_v33, _v34, _v35, true);
        let _v37 = (*&_v4.start_time) as u256;
        let _v38 = (*&_v4.period) as u256;
        _v31 = get_epoch_time(0u256, _v37, _v38, false) as u64;
        if (smart_table::contains<u64, Epoch>(&_v4.epoch_list, _v31)) _v0 = *&smart_table::borrow<u64, Epoch>(&_v4.epoch_list, _v31).epoch_total_xrion_amount else {
            let _v39 = create_new_global_epoch(_v31);
            smart_table::add<u64, Epoch>(&mut _v4.epoch_list, _v31, _v39);
            _v0 = 0
        };
        let _v40 = _v36 as u64;
        let _v41 = *&_v4.maximum_epoch_time;
        if (!(_v40 <= _v41)) {
            let _v42 = error::aborted(39);
            abort _v42
        };
        let _v43 = signer::address_of(p0);
        let _v44 = _v36 as u64;
        let _v45 = object::object_address<StakeDetails>(&_v30);
        let _v46 = *&_v4.total_stake_amount;
        send_event::send_stake_v2_event(_v43, p1, _v44, _v16, _v23, _v24, _v45, _v46, _v31, _v0, p2);
        let _v47 = &_v4.user_stake_list;
        let _v48 = signer::address_of(p0);
        if (smart_table::contains<address, vector<object::Object<StakeDetails>>>(_v47, _v48)) {
            let _v49 = &mut _v4.user_stake_list;
            let _v50 = signer::address_of(p0);
            vector::push_back<object::Object<StakeDetails>>(smart_table::borrow_mut<address, vector<object::Object<StakeDetails>>>(_v49, _v50), _v30)
        } else {
            let _v51 = &mut _v4.user_stake_list;
            let _v52 = signer::address_of(p0);
            let _v53 = vector::empty<object::Object<StakeDetails>>();
            vector::push_back<object::Object<StakeDetails>>(&mut _v53, _v30);
            smart_table::add<address, vector<object::Object<StakeDetails>>>(_v51, _v52, _v53);
            let _v54 = &mut _v4.stake;
            let _v55 = signer::address_of(p0);
            smart_vector::push_back<address>(_v54, _v55)
        };
    }
    public entry fun start(p0: &signer)
        acquires HyperionStake
    {
        let _v0 = string::utf8(vector[115u8, 116u8, 97u8, 114u8, 116u8]);
        check_function_permission(p0, _v0);
        let _v1 = package_manager::get_rion_address();
        let _v2 = &mut borrow_global_mut<HyperionStake>(_v1).pause;
        *_v2 = false;
    }
    fun check_function_permission(p0: &signer, p1: string::String) {
        let _v0 = string::utf8(vector[120u8, 114u8, 105u8, 111u8, 110u8]);
        let _v1 = permission_control::get_function_info(p1, _v0);
        permission_control::check_permission(p0, _v1);
    }
    fun key<T0: copy, T1>(p0: &smart_table::SmartTable<T0, T1>): vector<T0> {
        let _v0 = vector::empty<T0>();
        let _v1 = 0;
        let _v2 = false;
        let _v3 = smart_table::num_buckets<T0, T1>(p0);
        loop {
            if (_v2) _v1 = _v1 + 1 else _v2 = true;
            if (!(_v1 < _v3)) break;
            let _v4 = table_with_length::borrow<u64, vector<smart_table::Entry<T0, T1>>>(smart_table::borrow_buckets<T0, T1>(p0), _v1);
            let _v5 = 0;
            let _v6 = vector::length<smart_table::Entry<T0, T1>>(_v4);
            while (_v5 < _v6) {
                let (_v7,_v8) = smart_table::borrow_kv<T0, T1>(vector::borrow<smart_table::Entry<T0, T1>>(_v4, _v5));
                let _v9 = &mut _v0;
                let _v10 = *_v7;
                vector::push_back<T0>(_v9, _v10);
                _v5 = _v5 + 1;
                continue
            };
            continue
        };
        _v0
    }
    public entry fun initialize(p0: &signer, p1: object::Object<fungible_asset::Metadata>, p2: u64, p3: u64, p4: u64) {
        let _v0 = string::utf8(vector[105u8, 110u8, 105u8, 116u8, 105u8, 97u8, 108u8, 105u8, 122u8, 101u8]);
        check_function_permission(p0, _v0);
        if (!(p3 != 0)) {
            let _v1 = error::aborted(40);
            abort _v1
        };
        if (!(p2 != 0)) {
            let _v2 = error::aborted(40);
            abort _v2
        };
        let _v3 = package_manager::get_rion_signer();
        let _v4 = &_v3;
        let _v5 = timestamp::now_seconds() as u256;
        let _v6 = p2 as u256;
        let _v7 = get_epoch_time(52u256, _v5, _v6, false) as u64;
        let _v8 = smart_vector::new<address>();
        let _v9 = smart_table::new<address, vector<object::Object<StakeDetails>>>();
        let _v10 = smart_table::new<u64, Epoch>();
        let _v11 = timestamp::now_seconds();
        let _v12 = HyperionStake{meta: p1, total_stake_amount: 0, user_stake_list: _v9, epoch_list: _v10, stake: _v8, period: p2, last_update_time: _v11, start_time: p4, blacklist_amount: 0, blacklist_xrion: 0, pause: false, maximum_stake_capability: p3, maximum_epoch_time: _v7};
        move_to<HyperionStake>(_v4, _v12);
    }
    fun get_epoch_time(p0: u256, p1: u256, p2: u256, p3: bool): u256 {
        let _v0;
        if (p3) _v0 = ((timestamp::now_seconds() as u256) - p1) / p2 + 1u256 else _v0 = ((timestamp::now_seconds() as u256) - p1) / p2;
        (p0 + _v0) * p2 + p1
    }
    fun ensure_not_paused()
        acquires HyperionStake
    {
        let _v0 = package_manager::get_rion_address();
        if (*&borrow_global<HyperionStake>(_v0).pause) {
            let _v1 = error::aborted(13);
            abort _v1
        };
    }
    fun ensure_not_zero_period(p0: u64) {
        if (!(p0 != 0)) {
            let _v0 = error::aborted(30);
            abort _v0
        };
    }
    fun create_new_personal_epoch(p0: &mut HyperionStake, p1: u64, p2: u64): (vector<PersonalEpoch>, vector<u64>, vector<u64>) {
        let _v0 = (*&p0.start_time) as u256;
        let _v1 = (*&p0.period) as u256;
        let _v2 = vector::empty<PersonalEpoch>();
        let _v3 = vector::empty<u64>();
        let _v4 = vector::empty<u64>();
        let _v5 = 0;
        let _v6 = false;
        let _v7 = p2 + 1;
        loop {
            if (_v6) _v5 = _v5 + 1 else _v6 = true;
            if (!(_v5 < _v7)) break;
            let _v8 = get_epoch_time(_v5 as u256, _v0, _v1, true) as u64;
            let _v9 = create_single_personal_epoch(p1, _v5, _v8, p2);
            let _v10 = &mut _v3;
            let _v11 = *&(&_v9).epoch_time;
            vector::push_back<u64>(_v10, _v11);
            let _v12 = &mut _v4;
            let _v13 = *&(&_v9).epoch_current_xrion_amount;
            vector::push_back<u64>(_v12, _v13);
            vector::push_back<PersonalEpoch>(&mut _v2, _v9);
            continue
        };
        let _v14 = 0;
        let _v15 = false;
        let _v16 = vector::length<PersonalEpoch>(&_v2);
        loop {
            let _v17;
            let _v18;
            if (_v15) _v14 = _v14 + 1 else _v15 = true;
            if (!(_v14 < _v16)) break;
            let _v19 = vector::borrow<PersonalEpoch>(&_v2, _v14);
            let _v20 = &p0.epoch_list;
            let _v21 = *&_v19.epoch_time;
            if (smart_table::contains<u64, Epoch>(_v20, _v21)) {
                let _v22 = &mut p0.epoch_list;
                let _v23 = *&_v19.epoch_time;
                let _v24 = smart_table::borrow_mut<u64, Epoch>(_v22, _v23);
                _v17 = *&_v19.epoch_current_xrion_amount;
                _v18 = &mut _v24.epoch_total_xrion_amount;
                *_v18 = *_v18 + _v17;
                continue
            };
            let _v25 = create_new_global_epoch(*&_v19.epoch_time);
            _v17 = *&_v19.epoch_current_xrion_amount;
            _v18 = &mut (&mut _v25).epoch_total_xrion_amount;
            *_v18 = *_v18 + _v17;
            let _v26 = &mut p0.epoch_list;
            let _v27 = *&_v19.epoch_time;
            smart_table::add<u64, Epoch>(_v26, _v27, _v25);
            continue
        };
        (_v2, _v3, _v4)
    }
    fun is_personal_epoch_list_sorted(p0: &vector<PersonalEpoch>): bool {
        let _v0 = vector::length<PersonalEpoch>(p0);
        'l0: loop {
            'l1: loop {
                if (!(_v0 <= 1)) {
                    let _v1 = 0;
                    loop {
                        let _v2 = _v0 - 1;
                        if (!(_v1 < _v2)) break 'l0;
                        let _v3 = *&vector::borrow<PersonalEpoch>(p0, _v1).epoch_time;
                        let _v4 = _v1 + 1;
                        let _v5 = *&vector::borrow<PersonalEpoch>(p0, _v4).epoch_time;
                        if (_v3 > _v5) break 'l1;
                        _v1 = _v1 + 1;
                        continue
                    }
                };
                return true
            };
            return false
        };
        true
    }
    fun heap_sort_personal_epoch(p0: &mut vector<PersonalEpoch>) {
        let _v0 = is_personal_epoch_list_sorted(freeze(p0));
        'l0: loop {
            loop {
                if (!_v0) {
                    let _v1 = vector::length<PersonalEpoch>(freeze(p0));
                    if (_v1 <= 1) break;
                    let _v2 = _v1 / 2;
                    while (!(_v2 == 0)) {
                        _v2 = _v2 - 1;
                        heapify_personal_epoch(p0, _v1, _v2)
                    };
                    let _v3 = _v1;
                    loop {
                        if (!(_v3 > 1)) break 'l0;
                        _v3 = _v3 - 1;
                        vector::swap<PersonalEpoch>(p0, 0, _v3);
                        heapify_personal_epoch(p0, _v3, 0)
                    }
                };
                return ()
            };
            return ()
        };
    }
    fun create_stakedetails(p0: object::Object<fungible_asset::Metadata>, p1: fungible_asset::FungibleAsset, p2: u64, p3: u64, p4: u64, p5: vector<PersonalEpoch>): object::Object<StakeDetails> {
        let _v0 = object::create_object(package_manager::get_rion_address());
        let _v1 = &_v0;
        let _v2 = fungible_asset::create_store<fungible_asset::Metadata>(_v1, p0);
        dispatchable_fungible_asset::deposit<fungible_asset::FungibleStore>(_v2, p1);
        let _v3 = timestamp::now_seconds();
        let _v4 = timestamp::now_seconds() as u256;
        let _v5 = p4 as u256;
        let _v6 = _v4 - _v5;
        let _v7 = p3 as u256;
        let _v8 = (_v6 / _v7) as u64;
        let _v9 = p4 as u256;
        let _v10 = (p2 + _v8 + 1) as u256;
        let _v11 = p3 as u256;
        let _v12 = _v10 * _v11;
        let _v13 = _v9 + _v12;
        if (!((_v13 as u64) > _v3)) {
            let _v14 = error::aborted(3);
            abort _v14
        };
        let _v15 = object::create_object(package_manager::get_rion_address());
        let _v16 = &_v15;
        let _v17 = object::generate_signer(_v16);
        let _v18 = &_v17;
        let _v19 = blacklist::create_pending(*&vector::borrow<PersonalEpoch>(&p5, 1).epoch_current_xrion_amount);
        let _v20 = object::generate_delete_ref(_v1);
        let _v21 = vector::empty<UserReward>();
        let _v22 = _v13 as u64;
        let _v23 = object::address_from_constructor_ref(_v16);
        let _v24 = object::generate_extend_ref(_v16);
        let _v25 = object::generate_delete_ref(_v16);
        let _v26 = StakeDetails{status: _v19, store_del: _v20, rion_store: _v2, reward: _v21, list: p5, stake_time: _v3, unlock_time: _v22, claimed_epoch_cursor: 0, last_update_time: _v3, object: _v23, object_ext: _v24, object_del: _v25};
        move_to<StakeDetails>(_v18, _v26);
        object::object_from_constructor_ref<StakeDetails>(_v16)
    }
    fun create_new_global_epoch(p0: u64): Epoch {
        let _v0 = vector::empty<object::Object<fungible_asset::FungibleStore>>();
        let _v1 = vector::empty<object::DeleteRef>();
        let _v2 = smart_table::new<address, vector<ClaimRecord>>();
        let _v3 = vector::empty<Reward>();
        Epoch{can_claim: false, epoch_time: p0, epoch_total_xrion_amount: 0, epoch_store: _v0, store_del: _v1, claimed: _v2, reward: _v3}
    }
    fun init_module(p0: &signer) {
        let _v0 = string::utf8(vector[120u8, 114u8, 105u8, 111u8, 110u8]);
        let _v1 = permission_control::get_function_info(string::utf8(vector[115u8, 116u8, 111u8, 112u8]), _v0);
        permission_control::assignment_function_level(p0, _v1, 3u8);
        _v1 = permission_control::get_function_info(string::utf8(vector[115u8, 119u8, 97u8, 112u8, 95u8, 114u8, 101u8, 119u8, 97u8, 114u8, 100u8, 95u8, 116u8, 111u8, 95u8, 99u8, 117u8, 114u8, 114u8, 101u8, 110u8, 116u8, 95u8, 101u8, 112u8, 111u8, 99u8, 104u8]), _v0);
        let _v2 = permission_control::get_function_info(string::utf8(vector[115u8, 101u8, 116u8, 95u8, 99u8, 97u8, 110u8, 95u8, 99u8, 108u8, 97u8, 105u8, 109u8]), _v0);
        permission_control::assignment_function_level(p0, _v1, 0u8);
        permission_control::assignment_function_level(p0, _v2, 0u8);
        _v1 = permission_control::get_function_info(string::utf8(vector[115u8, 116u8, 97u8, 114u8, 116u8]), _v0);
        _v2 = permission_control::get_function_info(string::utf8(vector[97u8, 100u8, 100u8, 95u8, 114u8, 101u8, 119u8, 97u8, 114u8, 100u8]), _v0);
        let _v3 = permission_control::get_function_info(string::utf8(vector[105u8, 110u8, 105u8, 116u8, 105u8, 97u8, 108u8, 105u8, 122u8, 101u8]), _v0);
        let _v4 = permission_control::get_function_info(string::utf8(vector[97u8, 100u8, 100u8, 95u8, 98u8, 108u8, 97u8, 99u8, 107u8, 108u8, 105u8, 115u8, 116u8]), _v0);
        let _v5 = permission_control::get_function_info(string::utf8(vector[97u8, 100u8, 106u8, 117u8, 115u8, 116u8, 109u8, 101u8, 110u8, 116u8, 95u8, 112u8, 101u8, 114u8, 105u8, 111u8, 100u8]), _v0);
        let _v6 = permission_control::get_function_info(string::utf8(vector[114u8, 101u8, 108u8, 101u8, 97u8, 115u8, 101u8, 95u8, 98u8, 108u8, 97u8, 99u8, 107u8, 108u8, 105u8, 115u8, 116u8]), _v0);
        let _v7 = permission_control::get_function_info(string::utf8(vector[97u8, 100u8, 106u8, 117u8, 115u8, 116u8, 109u8, 101u8, 110u8, 116u8, 95u8, 109u8, 97u8, 120u8, 105u8, 109u8, 117u8, 109u8, 95u8, 101u8, 112u8, 111u8, 99u8, 104u8, 95u8, 116u8, 105u8, 109u8, 101u8]), _v0);
        let _v8 = permission_control::get_function_info(string::utf8(vector[97u8, 100u8, 106u8, 117u8, 115u8, 116u8, 109u8, 101u8, 110u8, 116u8, 95u8, 109u8, 97u8, 120u8, 105u8, 109u8, 117u8, 109u8, 95u8, 115u8, 116u8, 97u8, 107u8, 101u8, 95u8, 99u8, 97u8, 112u8, 97u8, 98u8, 105u8, 108u8, 105u8, 116u8, 121u8]), _v0);
        permission_control::assignment_function_level(p0, _v1, 1u8);
        permission_control::assignment_function_level(p0, _v2, 1u8);
        permission_control::assignment_function_level(p0, _v3, 1u8);
        permission_control::assignment_function_level(p0, _v4, 1u8);
        permission_control::assignment_function_level(p0, _v6, 1u8);
        permission_control::assignment_function_level(p0, _v5, 1u8);
        permission_control::assignment_function_level(p0, _v7, 1u8);
        permission_control::assignment_function_level(p0, _v8, 1u8);
        _v1 = permission_control::get_function_info(string::utf8(vector[117u8, 110u8, 115u8, 116u8, 97u8, 107u8, 101u8, 95u8, 111u8, 110u8, 108u8, 121u8, 95u8, 112u8, 114u8, 105u8, 110u8, 99u8, 105u8, 112u8, 97u8, 108u8]), _v0);
        _v2 = permission_control::get_function_info(string::utf8(vector[99u8, 108u8, 97u8, 105u8, 109u8, 95u8, 114u8, 101u8, 119u8, 97u8, 114u8, 100u8, 95u8, 98u8, 121u8, 95u8, 114u8, 97u8, 110u8, 103u8, 101u8]), _v0);
        _v3 = permission_control::get_function_info(string::utf8(vector[99u8, 108u8, 97u8, 105u8, 109u8, 95u8, 97u8, 108u8, 108u8, 95u8, 114u8, 101u8, 119u8, 97u8, 114u8, 100u8]), _v0);
        _v4 = permission_control::get_function_info(string::utf8(vector[117u8, 110u8, 115u8, 116u8, 97u8, 107u8, 101u8]), _v0);
        _v5 = permission_control::get_function_info(string::utf8(vector[101u8, 120u8, 116u8, 101u8, 110u8, 100u8]), _v0);
        _v6 = permission_control::get_function_info(string::utf8(vector[115u8, 116u8, 97u8, 107u8, 101u8]), _v0);
        _v7 = permission_control::get_function_info(string::utf8(vector[99u8, 108u8, 97u8, 105u8, 109u8, 95u8, 97u8, 108u8, 108u8, 95u8, 115u8, 116u8, 97u8, 107u8, 101u8, 100u8, 101u8, 116u8, 97u8, 105u8, 108u8, 115u8]), _v0);
        _v8 = permission_control::get_function_info(string::utf8(vector[100u8, 101u8, 112u8, 111u8, 115u8, 105u8, 116u8, 95u8, 116u8, 111u8, 95u8, 99u8, 117u8, 114u8, 114u8, 101u8, 110u8, 116u8, 95u8, 101u8, 112u8, 111u8, 99u8, 104u8]), _v0);
        permission_control::assignment_function_level(p0, _v8, 2u8);
        permission_control::assignment_function_level(p0, _v7, 2u8);
        permission_control::assignment_function_level(p0, _v2, 2u8);
        permission_control::assignment_function_level(p0, _v3, 2u8);
        permission_control::assignment_function_level(p0, _v4, 2u8);
        permission_control::assignment_function_level(p0, _v5, 2u8);
        permission_control::assignment_function_level(p0, _v6, 2u8);
        permission_control::assignment_function_level(p0, _v1, 2u8);
    }
    public entry fun add_blacklist(p0: &signer, p1: address, p2: object::Object<StakeDetails>)
        acquires HyperionStake, StakeDetails
    {
        let _v0 = string::utf8(vector[97u8, 100u8, 100u8, 95u8, 98u8, 108u8, 97u8, 99u8, 107u8, 108u8, 105u8, 115u8, 116u8]);
        check_function_permission(p0, _v0);
        let _v1 = package_manager::get_rion_address();
        let _v2 = borrow_global_mut<HyperionStake>(_v1);
        if (!smart_table::contains<address, vector<object::Object<StakeDetails>>>(&_v2.user_stake_list, p1)) {
            let _v3 = error::aborted(17);
            abort _v3
        };
        let _v4 = smart_table::borrow_mut<address, vector<object::Object<StakeDetails>>>(&mut _v2.user_stake_list, p1);
        let _v5 = freeze(_v4);
        let _v6 = false;
        let _v7 = 0;
        let _v8 = 0;
        let _v9 = vector::length<object::Object<StakeDetails>>(_v5);
        'l0: loop {
            loop {
                if (!(_v8 < _v9)) break 'l0;
                let _v10 = vector::borrow<object::Object<StakeDetails>>(_v5, _v8);
                let _v11 = &p2;
                if (_v10 == _v11) break;
                _v8 = _v8 + 1;
                continue
            };
            _v6 = true;
            _v7 = _v8;
            break
        };
        if (!_v6) {
            let _v12 = error::aborted(10);
            abort _v12
        };
        let _v13 = object::object_address<StakeDetails>(freeze(vector::borrow_mut<object::Object<StakeDetails>>(_v4, _v7)));
        let _v14 = borrow_global_mut<StakeDetails>(_v13);
        if (blacklist::is_blacklist(&_v14.status)) {
            let _v15 = error::aborted(36);
            abort _v15
        };
        let _v16 = blacklist::create_blacklist();
        let _v17 = &mut _v14.status;
        *_v17 = _v16;
        let _v18 = *&vector::borrow<PersonalEpoch>(&_v14.list, 1).epoch_current_xrion_amount;
        let _v19 = &mut _v2.blacklist_xrion;
        *_v19 = *_v19 + _v18;
        _v18 = fungible_asset::balance<fungible_asset::FungibleStore>(*&_v14.rion_store);
        _v19 = &mut _v2.blacklist_amount;
        *_v19 = *_v19 + _v18;
        let _v20 = &mut _v14.list;
        let _v21 = &mut _v2.epoch_list;
        blacklist_reduce_xrion_to_each_epoch(_v20, _v21);
    }
    fun blacklist_reduce_xrion_to_each_epoch(p0: &mut vector<PersonalEpoch>, p1: &mut smart_table::SmartTable<u64, Epoch>) {
        let _v0 = 0;
        let _v1 = false;
        let _v2 = vector::length<PersonalEpoch>(freeze(p0));
        'l0: loop {
            loop {
                if (_v1) _v0 = _v0 + 1 else _v1 = true;
                if (!(_v0 < _v2)) break 'l0;
                let _v3 = vector::borrow_mut<PersonalEpoch>(p0, _v0);
                let _v4 = freeze(p1);
                let _v5 = *&_v3.epoch_time;
                if (!smart_table::contains<u64, Epoch>(_v4, _v5)) break;
                let _v6 = *&_v3.epoch_time;
                let _v7 = smart_table::borrow_mut<u64, Epoch>(p1, _v6);
                let _v8 = *&_v7.epoch_total_xrion_amount;
                let _v9 = *&_v3.epoch_current_xrion_amount;
                if (_v8 >= _v9) {
                    let _v10 = *&_v3.epoch_current_xrion_amount;
                    let _v11 = &mut _v7.epoch_total_xrion_amount;
                    *_v11 = *_v11 - _v10;
                    continue
                };
                continue
            };
            let _v12 = error::aborted(23);
            abort _v12
        };
    }
    public entry fun add_reward(p0: &signer, p1: object::Object<fungible_asset::Metadata>, p2: u64, p3: u64)
        acquires HyperionStake
    {
        let _v0;
        let _v1 = string::utf8(vector[97u8, 100u8, 100u8, 95u8, 114u8, 101u8, 119u8, 97u8, 114u8, 100u8]);
        check_function_permission(p0, _v1);
        if (!(p2 > 0)) {
            let _v2 = error::aborted(33);
            abort _v2
        };
        let _v3 = package_manager::get_rion_address();
        let _v4 = borrow_global_mut<HyperionStake>(_v3);
        let _v5 = *&_v4.start_time;
        let _v6 = p3 - _v5;
        let _v7 = *&_v4.period;
        if (!(_v6 % _v7 == 0)) {
            let _v8 = error::aborted(26);
            abort _v8
        };
        let _v9 = smart_table::contains<u64, Epoch>(&_v4.epoch_list, p3);
        let _v10 = primary_fungible_store::withdraw<fungible_asset::Metadata>(p0, p1, p2);
        if (_v9) {
            let _v11 = smart_table::borrow_mut<u64, Epoch>(&mut _v4.epoch_list, p3);
            let _v12 = &_v11.reward;
            let _v13 = false;
            let _v14 = 0;
            let _v15 = 0;
            let _v16 = vector::length<Reward>(_v12);
            'l0: loop {
                loop {
                    if (!(_v15 < _v16)) break 'l0;
                    if (*&vector::borrow<Reward>(_v12, _v15).meta == p1) break;
                    _v15 = _v15 + 1
                };
                _v13 = true;
                _v14 = _v15;
                break
            };
            if (_v13) {
                let _v17 = vector::borrow_mut<Reward>(&mut _v11.reward, _v14);
                dispatchable_fungible_asset::deposit<fungible_asset::FungibleStore>(*&_v17.store, _v10);
                let _v18 = &mut _v17.total_amount;
                *_v18 = *_v18 + p2
            } else {
                _v0 = create_reward(_v10);
                vector::push_back<Reward>(&mut _v11.reward, _v0)
            }
        } else {
            let _v19 = create_new_global_epoch(p3);
            _v0 = create_reward(_v10);
            vector::push_back<Reward>(&mut (&mut _v19).reward, _v0);
            smart_table::add<u64, Epoch>(&mut _v4.epoch_list, p3, _v19)
        };
        send_event::send_allocation_to_epoch_event(signer::address_of(p0), p1, p2, p3);
    }
    fun create_reward(p0: fungible_asset::FungibleAsset): Reward {
        let _v0 = fungible_asset::amount(&p0);
        let _v1 = fungible_asset::metadata_from_asset(&p0);
        let _v2 = object::create_object(package_manager::get_rion_address());
        let _v3 = &_v2;
        let _v4 = fungible_asset::create_store<fungible_asset::Metadata>(_v3, _v1);
        dispatchable_fungible_asset::deposit<fungible_asset::FungibleStore>(_v4, p0);
        let _v5 = object::generate_delete_ref(_v3);
        Reward{total_amount: _v0, del: _v5, meta: _v1, store: _v4}
    }
    public entry fun adjustment_maximum_epoch_time(p0: &signer, p1: u64)
        acquires HyperionStake
    {
        let _v0 = string::utf8(vector[97u8, 100u8, 106u8, 117u8, 115u8, 116u8, 109u8, 101u8, 110u8, 116u8, 95u8, 109u8, 97u8, 120u8, 105u8, 109u8, 117u8, 109u8, 95u8, 101u8, 112u8, 111u8, 99u8, 104u8, 95u8, 116u8, 105u8, 109u8, 101u8]);
        check_function_permission(p0, _v0);
        if (!(p1 != 0)) {
            let _v1 = error::aborted(40);
            abort _v1
        };
        let _v2 = package_manager::get_rion_address();
        let _v3 = &mut borrow_global_mut<HyperionStake>(_v2).maximum_epoch_time;
        *_v3 = p1;
    }
    public entry fun adjustment_maximum_stake_capability(p0: &signer, p1: u64)
        acquires HyperionStake
    {
        let _v0 = string::utf8(vector[97u8, 100u8, 106u8, 117u8, 115u8, 116u8, 109u8, 101u8, 110u8, 116u8, 95u8, 109u8, 97u8, 120u8, 105u8, 109u8, 117u8, 109u8, 95u8, 115u8, 116u8, 97u8, 107u8, 101u8, 95u8, 99u8, 97u8, 112u8, 97u8, 98u8, 105u8, 108u8, 105u8, 116u8, 121u8]);
        check_function_permission(p0, _v0);
        if (!(p1 != 0)) {
            let _v1 = error::aborted(40);
            abort _v1
        };
        let _v2 = package_manager::get_rion_address();
        let _v3 = &mut borrow_global_mut<HyperionStake>(_v2).maximum_stake_capability;
        *_v3 = p1;
    }
    public entry fun adjustment_period(p0: &signer, p1: u64)
        acquires HyperionStake
    {
        let _v0 = string::utf8(vector[97u8, 100u8, 106u8, 117u8, 115u8, 116u8, 109u8, 101u8, 110u8, 116u8, 95u8, 112u8, 101u8, 114u8, 105u8, 111u8, 100u8]);
        check_function_permission(p0, _v0);
        if (!(p1 != 0)) {
            let _v1 = error::aborted(40);
            abort _v1
        };
        let _v2 = package_manager::get_rion_address();
        let _v3 = &mut borrow_global_mut<HyperionStake>(_v2).period;
        *_v3 = p1;
    }
    public entry fun batch_extend(p0: &signer, p1: vector<object::Object<StakeDetails>>, p2: vector<u64>)
        acquires HyperionStake, StakeDetails
    {
        let _v0 = vector::length<object::Object<StakeDetails>>(&p1);
        let _v1 = vector::length<u64>(&p2);
        if (!(_v0 == _v1)) {
            let _v2 = error::aborted(50);
            abort _v2
        };
        let _v3 = 0;
        let _v4 = false;
        let _v5 = vector::length<object::Object<StakeDetails>>(&p1);
        loop {
            if (_v4) _v3 = _v3 + 1 else _v4 = true;
            if (!(_v3 < _v5)) break;
            let _v6 = *vector::borrow<object::Object<StakeDetails>>(&p1, _v3);
            let _v7 = *vector::borrow<u64>(&p2, _v3);
            extend(p0, _v6, _v7);
            continue
        };
    }
    public entry fun extend(p0: &signer, p1: object::Object<StakeDetails>, p2: u64)
        acquires HyperionStake, StakeDetails
    {
        ensure_not_paused();
        let _v0 = string::utf8(vector[101u8, 120u8, 116u8, 101u8, 110u8, 100u8]);
        check_function_permission(p0, _v0);
        if (!(p2 != 0)) {
            let _v1 = error::aborted(37);
            abort _v1
        };
        let _v2 = ensure_position(p0, p1);
        if (!(p2 <= 52)) {
            let _v3 = error::aborted(16);
            abort _v3
        };
        let _v4 = package_manager::get_rion_address();
        let _v5 = borrow_global_mut<HyperionStake>(_v4);
        let _v6 = &_v5.user_stake_list;
        let _v7 = signer::address_of(p0);
        if (!smart_table::contains<address, vector<object::Object<StakeDetails>>>(_v6, _v7)) {
            let _v8 = error::aborted(7);
            abort _v8
        };
        let _v9 = &_v5.user_stake_list;
        let _v10 = signer::address_of(p0);
        let _v11 = object::object_address<StakeDetails>(vector::borrow<object::Object<StakeDetails>>(smart_table::borrow<address, vector<object::Object<StakeDetails>>>(_v9, _v10), _v2));
        let _v12 = borrow_global_mut<StakeDetails>(_v11);
        if (!is_personal_epoch_list_sorted(&_v12.list)) heap_sort_personal_epoch(&mut _v12.list);
        token_extend_time_and_amount(p0, _v12, _v5, p2);
    }
    public entry fun batch_extend_by_address(p0: &signer, p1: vector<address>, p2: vector<u64>)
        acquires HyperionStake, StakeDetails
    {
        let _v0 = vector::length<address>(&p1);
        let _v1 = vector::length<u64>(&p2);
        if (!(_v0 == _v1)) {
            let _v2 = error::aborted(50);
            abort _v2
        };
        loop {
            let _v3;
            if (vector::is_empty<address>(&p1)) _v3 = false else _v3 = !vector::is_empty<u64>(&p2);
            if (!_v3) break;
            let _v4 = vector::pop_back<address>(&mut p1);
            let _v5 = vector::pop_back<u64>(&mut p2);
            extend_by_address(p0, _v4, _v5);
            continue
        };
    }
    public entry fun extend_by_address(p0: &signer, p1: address, p2: u64)
        acquires HyperionStake, StakeDetails
    {
        ensure_not_paused();
        let _v0 = string::utf8(vector[101u8, 120u8, 116u8, 101u8, 110u8, 100u8]);
        check_function_permission(p0, _v0);
        if (!(p2 != 0)) {
            let _v1 = error::aborted(37);
            abort _v1
        };
        let _v2 = object::address_to_object<StakeDetails>(p1);
        let _v3 = ensure_position(p0, _v2);
        if (!(p2 <= 52)) {
            let _v4 = error::aborted(16);
            abort _v4
        };
        let _v5 = package_manager::get_rion_address();
        let _v6 = borrow_global_mut<HyperionStake>(_v5);
        let _v7 = &_v6.user_stake_list;
        let _v8 = signer::address_of(p0);
        if (!smart_table::contains<address, vector<object::Object<StakeDetails>>>(_v7, _v8)) {
            let _v9 = error::aborted(7);
            abort _v9
        };
        let _v10 = object::address_to_object<StakeDetails>(p1);
        let _v11 = object::object_address<StakeDetails>(&_v10);
        let _v12 = borrow_global_mut<StakeDetails>(_v11);
        if (!is_personal_epoch_list_sorted(&_v12.list)) heap_sort_personal_epoch(&mut _v12.list);
        token_extend_time_and_amount(p0, _v12, _v6, p2);
    }
    fun blacklist_increase_xrion_to_each_epoch(p0: &mut vector<PersonalEpoch>, p1: &mut smart_table::SmartTable<u64, Epoch>) {
        let _v0 = 0;
        let _v1 = false;
        let _v2 = vector::length<PersonalEpoch>(freeze(p0));
        'l0: loop {
            loop {
                if (_v1) _v0 = _v0 + 1 else _v1 = true;
                if (!(_v0 < _v2)) break 'l0;
                let _v3 = vector::borrow_mut<PersonalEpoch>(p0, _v0);
                let _v4 = freeze(p1);
                let _v5 = *&_v3.epoch_time;
                if (!smart_table::contains<u64, Epoch>(_v4, _v5)) break;
                let _v6 = *&_v3.epoch_time;
                let _v7 = smart_table::borrow_mut<u64, Epoch>(p1, _v6);
                let _v8 = *&_v3.epoch_current_xrion_amount;
                let _v9 = &mut _v7.epoch_total_xrion_amount;
                *_v9 = *_v9 + _v8;
                continue
            };
            let _v10 = error::aborted(23);
            abort _v10
        };
    }
    fun break_down_personal_epoch_for_event(p0: vector<PersonalEpoch>): (vector<u64>, vector<u64>) {
        let _v0 = vector::empty<u64>();
        let _v1 = vector::empty<u64>();
        let _v2 = 0;
        let _v3 = false;
        let _v4 = vector::length<PersonalEpoch>(&p0);
        loop {
            if (_v3) _v2 = _v2 + 1 else _v3 = true;
            if (!(_v2 < _v4)) break;
            let _v5 = &mut _v0;
            let _v6 = *&vector::borrow<PersonalEpoch>(&p0, _v2).epoch_time;
            vector::push_back<u64>(_v5, _v6);
            let _v7 = &mut _v1;
            let _v8 = *&vector::borrow<PersonalEpoch>(&p0, _v2).epoch_current_xrion_amount;
            vector::push_back<u64>(_v7, _v8);
            continue
        };
        (_v0, _v1)
    }
    public fun cal_last_reward(p0: u64, p1: object::Object<StakeDetails>): (vector<object::Object<fungible_asset::Metadata>>, vector<u64>)
        acquires HyperionStake, StakeDetails
    {
        let _v0 = package_manager::get_rion_address();
        let _v1 = borrow_global<HyperionStake>(_v0);
        let _v2 = object::object_address<StakeDetails>(&p1);
        let _v3 = borrow_global<StakeDetails>(_v2);
        if (!smart_table::contains<u64, Epoch>(&_v1.epoch_list, p0)) {
            let _v4 = error::aborted(23);
            abort _v4
        };
        let _v5 = &_v3.list;
        let _v6 = false;
        let _v7 = 0;
        let _v8 = 0;
        let _v9 = vector::length<PersonalEpoch>(_v5);
        'l0: loop {
            loop {
                if (!(_v8 < _v9)) break 'l0;
                if (*&vector::borrow<PersonalEpoch>(_v5, _v8).epoch_time == p0) break;
                _v8 = _v8 + 1
            };
            _v6 = true;
            _v7 = _v8;
            break
        };
        if (!_v6) {
            let _v10 = error::aborted(22);
            abort _v10
        };
        let _v11 = smart_table::borrow<u64, Epoch>(&_v1.epoch_list, p0);
        let _v12 = (*&vector::borrow<PersonalEpoch>(&_v3.list, _v7).epoch_current_xrion_amount) as u256;
        let _v13 = (*&_v11.epoch_total_xrion_amount) as u256;
        let _v14 = vector::empty<object::Object<fungible_asset::Metadata>>();
        let _v15 = vector::empty<u64>();
        let _v16 = 0;
        let _v17 = false;
        let _v18 = vector::length<Reward>(&_v11.reward);
        loop {
            if (_v17) _v16 = _v16 + 1 else _v17 = true;
            if (!(_v16 < _v18)) break;
            let _v19 = vector::borrow<Reward>(&_v11.reward, _v16);
            let _v20 = cal_pending_reward((*&_v19.total_amount) as u256, _v12, _v13) as u64;
            let _v21 = &mut _v14;
            let _v22 = *&_v19.meta;
            vector::push_back<object::Object<fungible_asset::Metadata>>(_v21, _v22);
            vector::push_back<u64>(&mut _v15, _v20);
            continue
        };
        (_v14, _v15)
    }
    fun cal_pending_reward(p0: u256, p1: u256, p2: u256): u256 {
        p0 * p1 * 10000000000u256 / p2 / 10000000000u256
    }
    public fun check_epoch_reward(p0: u64): (u64, vector<object::Object<fungible_asset::Metadata>>, vector<u64>, bool)
        acquires HyperionStake
    {
        let _v0 = package_manager::get_rion_address();
        let _v1 = smart_table::borrow<u64, Epoch>(&borrow_global<HyperionStake>(_v0).epoch_list, p0);
        p0 = vector::length<Reward>(&_v1.reward);
        let _v2 = vector::empty<object::Object<fungible_asset::Metadata>>();
        let _v3 = vector::empty<u64>();
        let _v4 = &_v1.reward;
        let _v5 = 0;
        let _v6 = vector::length<Reward>(_v4);
        while (_v5 < _v6) {
            let _v7 = vector::borrow<Reward>(_v4, _v5);
            let _v8 = &mut _v3;
            let _v9 = *&_v7.total_amount;
            vector::push_back<u64>(_v8, _v9);
            let _v10 = &mut _v2;
            let _v11 = fungible_asset::store_metadata<fungible_asset::FungibleStore>(*&_v7.store);
            vector::push_back<object::Object<fungible_asset::Metadata>>(_v10, _v11);
            _v5 = _v5 + 1;
            continue
        };
        let _v12 = *&_v1.can_claim;
        (p0, _v2, _v3, _v12)
    }
    public entry fun claim_all_reward(p0: &signer, p1: object::Object<StakeDetails>)
        acquires HyperionStake, StakeDetails
    {
        let _v0;
        let _v1;
        ensure_not_paused();
        let _v2 = string::utf8(vector[99u8, 108u8, 97u8, 105u8, 109u8, 95u8, 97u8, 108u8, 108u8, 95u8, 114u8, 101u8, 119u8, 97u8, 114u8, 100u8]);
        check_function_permission(p0, _v2);
        let _v3 = get_current_time() as u64;
        let _v4 = ensure_position(p0, p1);
        let _v5 = package_manager::get_rion_address();
        let _v6 = borrow_global_mut<HyperionStake>(_v5);
        let _v7 = object::object_address<StakeDetails>(&p1);
        let _v8 = borrow_global_mut<StakeDetails>(_v7);
        let _v9 = blacklist::is_blacklist(&_v8.status);
        loop {
            if (!_v9) {
                let _v10;
                let _v11;
                let _v12;
                let _v13;
                if (!is_personal_epoch_list_sorted(&_v8.list)) heap_sort_personal_epoch(&mut _v8.list);
                if (smart_table::contains<u64, Epoch>(&_v6.epoch_list, _v3)) _v1 = *&smart_table::borrow<u64, Epoch>(&_v6.epoch_list, _v3).epoch_total_xrion_amount else {
                    let _v14 = create_new_global_epoch(_v3);
                    smart_table::add<u64, Epoch>(&mut _v6.epoch_list, _v3, _v14);
                    _v1 = 0
                };
                let _v15 = *&_v8.claimed_epoch_cursor;
                if (_v15 != 0) {
                    _v13 = &_v8.list;
                    _v12 = 0;
                    _v11 = 0;
                    _v10 = vector::length<PersonalEpoch>(_v13)
                } else {
                    _v0 = 0;
                    break
                };
                'l0: loop {
                    loop {
                        if (!(_v11 < _v10)) break 'l0;
                        if (*&vector::borrow<PersonalEpoch>(_v13, _v11).epoch_time == _v15) break;
                        _v11 = _v11 + 1
                    };
                    _v12 = _v11;
                    break
                };
                _v0 = _v12;
                break
            };
            return ()
        };
        let _v16 = vector::length<PersonalEpoch>(&_v8.list);
        claim_reward_loop(p0, _v8, _v0, _v16, _v3, _v6, p1, _v1);
        let _v17 = timestamp::now_seconds();
        let _v18 = &mut _v8.last_update_time;
        *_v18 = _v17;
    }
    public fun get_current_time(): u256
        acquires HyperionStake
    {
        let _v0 = package_manager::get_rion_address();
        let _v1 = borrow_global<HyperionStake>(_v0);
        let _v2 = (*&_v1.start_time) as u256;
        let _v3 = (*&_v1.period) as u256;
        get_epoch_time(0u256, _v2, _v3, false)
    }
    fun ensure_position(p0: &signer, p1: object::Object<StakeDetails>): u64
        acquires HyperionStake
    {
        let _v0 = package_manager::get_rion_address();
        let _v1 = borrow_global<HyperionStake>(_v0);
        let _v2 = &_v1.user_stake_list;
        let _v3 = signer::address_of(p0);
        if (!smart_table::contains<address, vector<object::Object<StakeDetails>>>(_v2, _v3)) {
            let _v4 = error::aborted(17);
            abort _v4
        };
        let _v5 = &_v1.user_stake_list;
        let _v6 = signer::address_of(p0);
        let _v7 = smart_table::borrow<address, vector<object::Object<StakeDetails>>>(_v5, _v6);
        let _v8 = false;
        let _v9 = 0;
        let _v10 = 0;
        let _v11 = vector::length<object::Object<StakeDetails>>(_v7);
        'l0: loop {
            loop {
                if (!(_v10 < _v11)) break 'l0;
                if (*vector::borrow<object::Object<StakeDetails>>(_v7, _v10) == p1) break;
                _v10 = _v10 + 1
            };
            _v8 = true;
            _v9 = _v10;
            break
        };
        if (!_v8) {
            let _v12 = error::aborted(10);
            abort _v12
        };
        _v9
    }
    fun claim_reward_loop(p0: &signer, p1: &mut StakeDetails, p2: u64, p3: u64, p4: u64, p5: &mut HyperionStake, p6: object::Object<StakeDetails>, p7: u64) {
        if (vector::is_empty<PersonalEpoch>(&p1.list)) {
            let _v0 = error::aborted(21);
            abort _v0
        };
        let _v1 = p2;
        let _v2 = false;
        'l0: loop {
            'l1: loop {
                loop {
                    let _v3;
                    if (_v2) _v1 = _v1 + 1 else _v2 = true;
                    if (!(_v1 < p3)) break 'l0;
                    let _v4 = vector::borrow_mut<PersonalEpoch>(&mut p1.list, _v1);
                    if (*&_v4.claimed) continue;
                    if (*&_v4.epoch_time >= p4) break 'l0;
                    if (_v1 == 0) _v3 = blacklist::is_pending(&p1.status) else _v3 = false;
                    if (_v3) {
                        if (!(*&_v4.epoch_current_xrion_amount == 0)) break;
                        let _v5 = blacklist::create_normal();
                        let _v6 = &mut p1.status;
                        *_v6 = _v5;
                        let _v7 = &mut _v4.claimed;
                        *_v7 = true;
                        let _v8 = *&_v4.epoch_time;
                        let _v9 = &mut p1.claimed_epoch_cursor;
                        *_v9 = _v8;
                        continue
                    };
                    let _v10 = &p5.epoch_list;
                    let _v11 = *&_v4.epoch_time;
                    if (!smart_table::contains<u64, Epoch>(_v10, _v11)) break 'l1;
                    let _v12 = &mut p5.epoch_list;
                    let _v13 = *&_v4.epoch_time;
                    let _v14 = smart_table::borrow_mut<u64, Epoch>(_v12, _v13);
                    if (*&_v14.can_claim) {
                        let _v15 = object::object_address<StakeDetails>(&p6);
                        let _v16 = claim_reward_from_global_epoch(p0, _v14, _v4, _v15);
                        let _v17 = object::object_address<StakeDetails>(&p6);
                        let _v18 = *&_v4.epoch_time;
                        let _v19 = *&p5.total_stake_amount;
                        deposit_fa_to_user(p0, _v16, _v17, _v18, _v19, p4, p7);
                        let _v20 = &mut _v4.claimed;
                        *_v20 = true;
                        let _v21 = *&_v4.epoch_time;
                        let _v22 = &mut p1.claimed_epoch_cursor;
                        *_v22 = _v21;
                        continue
                    };
                    continue
                };
                let _v23 = error::aborted(29);
                abort _v23
            };
            let _v24 = error::aborted(28);
            abort _v24
        };
    }
    public entry fun claim_all_stakedetails(p0: &signer)
        acquires HyperionStake, StakeDetails
    {
        let _v0 = string::utf8(vector[99u8, 108u8, 97u8, 105u8, 109u8, 95u8, 97u8, 108u8, 108u8, 95u8, 115u8, 116u8, 97u8, 107u8, 101u8, 100u8, 101u8, 116u8, 97u8, 105u8, 108u8, 115u8]);
        check_function_permission(p0, _v0);
        let _v1 = get_token_data(signer::address_of(p0));
        let _v2 = 0;
        let _v3 = false;
        let _v4 = vector::length<object::Object<StakeDetails>>(&_v1);
        loop {
            if (_v3) _v2 = _v2 + 1 else _v3 = true;
            if (!(_v2 < _v4)) break;
            let _v5 = *vector::borrow<object::Object<StakeDetails>>(&_v1, _v2);
            claim_all_reward(p0, _v5);
            continue
        };
    }
    public fun get_token_data(p0: address): vector<object::Object<StakeDetails>>
        acquires HyperionStake
    {
        let _v0 = package_manager::get_rion_address();
        let _v1 = borrow_global<HyperionStake>(_v0);
        if (!smart_table::contains<address, vector<object::Object<StakeDetails>>>(&_v1.user_stake_list, p0)) {
            let _v2 = error::aborted(17);
            abort _v2
        };
        *smart_table::borrow<address, vector<object::Object<StakeDetails>>>(&_v1.user_stake_list, p0)
    }
    public entry fun claim_reward_by_range(p0: &signer, p1: object::Object<StakeDetails>, p2: u64, p3: u64)
        acquires HyperionStake, StakeDetails
    {
        let _v0;
        ensure_not_paused();
        let _v1 = string::utf8(vector[99u8, 108u8, 97u8, 105u8, 109u8, 95u8, 114u8, 101u8, 119u8, 97u8, 114u8, 100u8, 95u8, 98u8, 121u8, 95u8, 114u8, 97u8, 110u8, 103u8, 101u8]);
        check_function_permission(p0, _v1);
        let _v2 = get_current_time() as u64;
        let _v3 = ensure_position(p0, p1);
        let _v4 = package_manager::get_rion_address();
        let _v5 = borrow_global_mut<HyperionStake>(_v4);
        let _v6 = object::object_address<StakeDetails>(&p1);
        let _v7 = borrow_global_mut<StakeDetails>(_v6);
        let _v8 = blacklist::is_blacklist(&_v7.status);
        loop {
            if (!_v8) {
                if (!is_personal_epoch_list_sorted(&_v7.list)) heap_sort_personal_epoch(&mut _v7.list);
                _v0 = *&smart_table::borrow<u64, Epoch>(&_v5.epoch_list, _v2).epoch_total_xrion_amount;
                let _v9 = timestamp::now_seconds();
                let _v10 = &mut _v7.last_update_time;
                *_v10 = _v9;
                if (!(p2 < p3)) {
                    let _v11 = error::aborted(49);
                    abort _v11
                };
                let _v12 = vector::length<PersonalEpoch>(&_v7.list);
                if (p3 <= _v12) break;
                let _v13 = error::aborted(38);
                abort _v13
            };
            return ()
        };
        claim_reward_loop(p0, _v7, p2, p3, _v2, _v5, p1, _v0);
    }
    fun claim_reward_from_global_epoch(p0: &signer, p1: &mut Epoch, p2: &mut PersonalEpoch, p3: address): vector<fungible_asset::FungibleAsset> {
        let _v0;
        let _v1 = *&p1.epoch_time;
        let _v2 = *&p2.epoch_time;
        if (!(_v1 == _v2)) {
            let _v3 = error::aborted(27);
            abort _v3
        };
        let _v4 = timestamp::now_seconds();
        let _v5 = *&p1.epoch_time;
        if (!(_v4 >= _v5)) {
            let _v6 = error::aborted(26);
            abort _v6
        };
        let _v7 = (*&p2.epoch_current_xrion_amount) as u256;
        let _v8 = (*&p1.epoch_total_xrion_amount) as u256;
        let _v9 = vector::empty<fungible_asset::FungibleAsset>();
        if (*&p2.epoch_current_xrion_amount == 0) return _v9 else {
            _v0 = vector::empty<ClaimRecord>();
            let _v10 = 0;
            let _v11 = false;
            let _v12 = vector::length<Reward>(&p1.reward);
            'l0: loop {
                'l1: loop {
                    'l2: loop {
                        'l3: loop {
                            loop {
                                if (_v11) _v10 = _v10 + 1 else _v11 = true;
                                if (!(_v10 < _v12)) break 'l0;
                                let _v13 = vector::borrow<Reward>(&p1.reward, _v10);
                                if (!(_v8 != 0u256)) break 'l1;
                                if (!(_v7 != 0u256)) break 'l2;
                                if (!(*&_v13.total_amount != 0)) break 'l3;
                                let _v14 = cal_pending_reward((*&_v13.total_amount) as u256, _v7, _v8);
                                if (!(_v14 != 0u256)) continue;
                                let _v15 = fungible_asset::balance<fungible_asset::FungibleStore>(*&vector::borrow<Reward>(&p1.reward, _v10).store);
                                let _v16 = _v14 as u64;
                                if (!(_v15 >= _v16)) break;
                                let _v17 = package_manager::get_rion_signer();
                                let _v18 = &_v17;
                                let _v19 = *&_v13.store;
                                let _v20 = _v14 as u64;
                                let _v21 = dispatchable_fungible_asset::withdraw<fungible_asset::FungibleStore>(_v18, _v19, _v20);
                                let _v22 = signer::address_of(p0);
                                let _v23 = fungible_asset::metadata_from_asset(&_v21);
                                let _v24 = fungible_asset::amount(&_v21);
                                let _v25 = *&p1.epoch_time;
                                let _v26 = *&_v13.total_amount;
                                let _v27 = fungible_asset::balance<fungible_asset::FungibleStore>(*&vector::borrow<Reward>(&p1.reward, _v10).store);
                                send_event::send_claim_fee_from_epoch_event(_v22, p3, _v23, _v24, _v25, _v26, _v27);
                                vector::push_back<fungible_asset::FungibleAsset>(&mut _v9, _v21);
                                let _v28 = &mut _v0;
                                let _v29 = signer::address_of(p0);
                                let _v30 = fungible_asset::store_metadata<fungible_asset::FungibleStore>(*&_v13.store);
                                let _v31 = _v14 as u64;
                                let _v32 = ClaimRecord{owner: _v29, meta: _v30, amount: _v31};
                                vector::push_back<ClaimRecord>(_v28, _v32);
                                continue
                            };
                            let _v33 = error::aborted(1);
                            abort _v33
                        };
                        let _v34 = error::aborted(33);
                        abort _v34
                    };
                    let _v35 = error::aborted(32);
                    abort _v35
                };
                let _v36 = error::aborted(31);
                abort _v36
            }
        };
        let _v37 = &mut p2.claimed;
        *_v37 = true;
        smart_table::add<address, vector<ClaimRecord>>(&mut p1.claimed, p3, _v0);
        _v9
    }
    fun deposit_fa_to_user(p0: &signer, p1: vector<fungible_asset::FungibleAsset>, p2: address, p3: u64, p4: u64, p5: u64, p6: u64) {
        while (!vector::is_empty<fungible_asset::FungibleAsset>(&p1)) {
            let _v0 = vector::pop_back<fungible_asset::FungibleAsset>(&mut p1);
            let _v1 = fungible_asset::metadata_from_asset(&_v0);
            let _v2 = fungible_asset::amount(&_v0);
            send_event::send_claim_reward_event(signer::address_of(p0), p2, _v1, _v2, p3, p4, p5, p6);
            primary_fungible_store::deposit(signer::address_of(p0), _v0);
            continue
        };
        vector::destroy_empty<fungible_asset::FungibleAsset>(p1);
    }
    fun clean_hyperion_user_stakedetails(p0: address)
        acquires HyperionStake
    {
        let _v0 = package_manager::get_rion_address();
        let _v1 = borrow_global_mut<HyperionStake>(_v0);
        let _v2 = smart_table::remove<address, vector<object::Object<StakeDetails>>>(&mut _v1.user_stake_list, p0);
        let _v3 = &_v1.stake;
        let _v4 = &p0;
        let (_v5,_v6) = smart_vector::index_of<address>(_v3, _v4);
        if (!_v5) {
            let _v7 = error::aborted(11);
            abort _v7
        };
        let _v8 = smart_vector::remove<address>(&mut _v1.stake, _v6);
        vector::destroy_empty<object::Object<StakeDetails>>(_v2);
    }
    fun clean_person_epoch(p0: vector<PersonalEpoch>) {
        while (!vector::is_empty<PersonalEpoch>(&p0)) {
            let PersonalEpoch{claimed: _v0, epoch_time: _v1, epoch_current_xrion_amount: _v2} = vector::pop_back<PersonalEpoch>(&mut p0);
            continue
        };
        vector::destroy_empty<PersonalEpoch>(p0);
    }
    fun clean_user_reward(p0: vector<UserReward>) {
        while (!vector::is_empty<UserReward>(&p0)) {
            let UserReward{claimed_amount: _v0, meta: _v1} = vector::pop_back<UserReward>(&mut p0);
            continue
        };
        if (!vector::is_empty<UserReward>(&p0)) {
            let _v2 = error::aborted(5);
            abort _v2
        };
        vector::destroy_empty<UserReward>(p0);
    }
    public fun contain_epoch(p0: u64): bool
        acquires HyperionStake
    {
        let _v0 = package_manager::get_rion_address();
        smart_table::contains<u64, Epoch>(&borrow_global<HyperionStake>(_v0).epoch_list, p0)
    }
    fun create_single_personal_epoch(p0: u64, p1: u64, p2: u64, p3: u64): PersonalEpoch {
        let _v0 = p3 as u256;
        let _v1 = p1 as u256;
        let _v2 = _v0 - _v1;
        let _v3 = p0 as u256;
        let _v4 = (_v2 * _v3) as u64;
        PersonalEpoch{claimed: false, epoch_time: p2, epoch_current_xrion_amount: _v4}
    }
    friend fun deposit_to_current_epoch(p0: &signer, p1: fungible_asset::FungibleAsset)
        acquires HyperionStake
    {
        let _v0;
        let _v1 = string::utf8(vector[100u8, 101u8, 112u8, 111u8, 115u8, 105u8, 116u8, 95u8, 116u8, 111u8, 95u8, 99u8, 117u8, 114u8, 114u8, 101u8, 110u8, 116u8, 95u8, 101u8, 112u8, 111u8, 99u8, 104u8]);
        check_function_permission(p0, _v1);
        let _v2 = get_current_time() as u64;
        let _v3 = package_manager::get_rion_address();
        let _v4 = borrow_global_mut<HyperionStake>(_v3);
        let _v5 = fungible_asset::metadata_from_asset(&p1);
        let _v6 = fungible_asset::amount(&p1);
        if (smart_table::contains<u64, Epoch>(&_v4.epoch_list, _v2)) {
            let _v7 = smart_table::borrow_mut<u64, Epoch>(&mut _v4.epoch_list, _v2);
            let _v8 = &_v7.epoch_store;
            let _v9 = false;
            let _v10 = 0;
            let _v11 = 0;
            let _v12 = vector::length<object::Object<fungible_asset::FungibleStore>>(_v8);
            'l0: loop {
                loop {
                    if (!(_v11 < _v12)) break 'l0;
                    if (fungible_asset::store_metadata<fungible_asset::FungibleStore>(*vector::borrow<object::Object<fungible_asset::FungibleStore>>(_v8, _v11)) == _v5) break;
                    _v11 = _v11 + 1
                };
                _v9 = true;
                _v10 = _v11;
                break
            };
            if (_v9) dispatchable_fungible_asset::deposit<fungible_asset::FungibleStore>(*vector::borrow<object::Object<fungible_asset::FungibleStore>>(&_v7.epoch_store, _v10), p1) else {
                let _v13 = object::create_object(package_manager::get_rion_address());
                let _v14 = &_v13;
                _v0 = fungible_asset::create_store<fungible_asset::Metadata>(_v14, _v5);
                dispatchable_fungible_asset::deposit<fungible_asset::FungibleStore>(_v0, p1);
                let _v15 = &mut _v7.store_del;
                let _v16 = object::generate_delete_ref(_v14);
                vector::push_back<object::DeleteRef>(_v15, _v16);
                vector::push_back<object::Object<fungible_asset::FungibleStore>>(&mut _v7.epoch_store, _v0)
            }
        } else {
            let _v17 = create_new_global_epoch(_v2);
            let _v18 = object::create_object(package_manager::get_rion_address());
            _v0 = fungible_asset::create_store<fungible_asset::Metadata>(&_v18, _v5);
            dispatchable_fungible_asset::deposit<fungible_asset::FungibleStore>(_v0, p1);
            vector::push_back<object::Object<fungible_asset::FungibleStore>>(&mut (&mut _v17).epoch_store, _v0);
            smart_table::add<u64, Epoch>(&mut _v4.epoch_list, _v2, _v17)
        };
        send_event::send_fee_to_epoch_event(_v5, _v6, _v2);
    }
    friend fun deposit_to_current_epoch_without_limit(p0: fungible_asset::FungibleAsset)
        acquires HyperionStake
    {
        let _v0;
        let _v1 = get_current_time() as u64;
        let _v2 = package_manager::get_rion_address();
        let _v3 = borrow_global_mut<HyperionStake>(_v2);
        let _v4 = fungible_asset::metadata_from_asset(&p0);
        let _v5 = fungible_asset::amount(&p0);
        if (smart_table::contains<u64, Epoch>(&_v3.epoch_list, _v1)) {
            let _v6 = smart_table::borrow_mut<u64, Epoch>(&mut _v3.epoch_list, _v1);
            let _v7 = &_v6.epoch_store;
            let _v8 = false;
            let _v9 = 0;
            let _v10 = 0;
            let _v11 = vector::length<object::Object<fungible_asset::FungibleStore>>(_v7);
            'l0: loop {
                loop {
                    if (!(_v10 < _v11)) break 'l0;
                    if (fungible_asset::store_metadata<fungible_asset::FungibleStore>(*vector::borrow<object::Object<fungible_asset::FungibleStore>>(_v7, _v10)) == _v4) break;
                    _v10 = _v10 + 1
                };
                _v8 = true;
                _v9 = _v10;
                break
            };
            if (_v8) dispatchable_fungible_asset::deposit<fungible_asset::FungibleStore>(*vector::borrow<object::Object<fungible_asset::FungibleStore>>(&_v6.epoch_store, _v9), p0) else {
                let _v12 = object::create_object(package_manager::get_rion_address());
                let _v13 = &_v12;
                _v0 = fungible_asset::create_store<fungible_asset::Metadata>(_v13, _v4);
                dispatchable_fungible_asset::deposit<fungible_asset::FungibleStore>(_v0, p0);
                let _v14 = &mut _v6.store_del;
                let _v15 = object::generate_delete_ref(_v13);
                vector::push_back<object::DeleteRef>(_v14, _v15);
                vector::push_back<object::Object<fungible_asset::FungibleStore>>(&mut _v6.epoch_store, _v0)
            }
        } else {
            let _v16 = create_new_global_epoch(_v1);
            let _v17 = object::create_object(package_manager::get_rion_address());
            _v0 = fungible_asset::create_store<fungible_asset::Metadata>(&_v17, _v4);
            dispatchable_fungible_asset::deposit<fungible_asset::FungibleStore>(_v0, p0);
            vector::push_back<object::Object<fungible_asset::FungibleStore>>(&mut (&mut _v16).epoch_store, _v0);
            smart_table::add<u64, Epoch>(&mut _v3.epoch_list, _v1, _v16)
        };
        send_event::send_fee_to_epoch_event(_v4, _v5, _v1);
    }
    fun ensure_reward_can_claim(p0: object::Object<StakeDetails>)
        acquires HyperionStake, StakeDetails
    {
        let _v0 = package_manager::get_rion_address();
        let _v1 = borrow_global<HyperionStake>(_v0);
        let _v2 = object::object_address<StakeDetails>(&p0);
        let _v3 = &borrow_global<StakeDetails>(_v2).list;
        let _v4 = 0;
        let _v5 = vector::length<PersonalEpoch>(_v3);
        'l0: loop {
            loop {
                if (!(_v4 < _v5)) break 'l0;
                let _v6 = vector::borrow<PersonalEpoch>(_v3, _v4);
                if (*&_v6.epoch_current_xrion_amount != 0) {
                    let _v7 = &_v1.epoch_list;
                    let _v8 = *&_v6.epoch_time;
                    if (!*&smart_table::borrow<u64, Epoch>(_v7, _v8).can_claim) break
                };
                _v4 = _v4 + 1;
                continue
            };
            let _v9 = error::aborted(42);
            abort _v9
        };
    }
    public fun epoch_key_list(): vector<u64>
        acquires HyperionStake
    {
        let _v0 = package_manager::get_rion_address();
        let _v1 = borrow_global<HyperionStake>(_v0);
        let _v2 = vector::empty<u64>();
        let _v3 = &_v1.epoch_list;
        let _v4 = 0;
        let _v5 = false;
        let _v6 = smart_table::num_buckets<u64, Epoch>(_v3);
        loop {
            if (_v5) _v4 = _v4 + 1 else _v5 = true;
            if (!(_v4 < _v6)) break;
            let _v7 = table_with_length::borrow<u64, vector<smart_table::Entry<u64, Epoch>>>(smart_table::borrow_buckets<u64, Epoch>(_v3), _v4);
            let _v8 = 0;
            let _v9 = vector::length<smart_table::Entry<u64, Epoch>>(_v7);
            while (_v8 < _v9) {
                let (_v10,_v11) = smart_table::borrow_kv<u64, Epoch>(vector::borrow<smart_table::Entry<u64, Epoch>>(_v7, _v8));
                let _v12 = &mut _v2;
                let _v13 = *_v10;
                vector::push_back<u64>(_v12, _v13);
                _v8 = _v8 + 1;
                continue
            };
            continue
        };
        _v2
    }
    fun token_extend_time_and_amount(p0: &signer, p1: &mut StakeDetails, p2: &mut HyperionStake, p3: u64) {
        let _v0;
        let _v1;
        if (blacklist::is_blacklist(&p1.status)) abort 47;
        let _v2 = fungible_asset::balance<fungible_asset::FungibleStore>(*&p1.rion_store);
        let _v3 = *&p1.unlock_time;
        let _v4 = fungible_asset::balance<fungible_asset::FungibleStore>(*&p1.rion_store);
        let _v5 = *&p1.list;
        let (_v6,_v7) = break_down_personal_epoch_for_event(_v5);
        let _v8 = (*&p2.start_time) as u256;
        let _v9 = (*&p2.period) as u256;
        let _v10 = get_epoch_time(0u256, _v8, _v9, false);
        let _v11 = &_v5;
        let _v12 = false;
        let _v13 = 0;
        let _v14 = 0;
        let _v15 = vector::length<PersonalEpoch>(_v11);
        'l0: loop {
            loop {
                if (!(_v14 < _v15)) break 'l0;
                let _v16 = *&vector::borrow<PersonalEpoch>(_v11, _v14).epoch_time;
                let _v17 = _v10 as u64;
                if (_v16 == _v17) break;
                _v14 = _v14 + 1;
                continue
            };
            _v12 = true;
            _v13 = _v14;
            break
        };
        let _v18 = _v13;
        let _v19 = vector::length<PersonalEpoch>(&p1.list) - _v18;
        if (!(p3 + _v19 <= 54)) {
            let _v20 = error::aborted(48);
            abort _v20
        };
        if (!_v12) {
            let _v21 = error::aborted(22);
            abort _v21
        };
        let _v22 = vector::empty<PersonalEpoch>();
        let _v23 = 0;
        let _v24 = false;
        let _v25 = _v18 + 1;
        loop {
            if (_v24) _v23 = _v23 + 1 else _v24 = true;
            if (!(_v23 < _v25)) break;
            let _v26 = &mut _v22;
            let _v27 = *vector::borrow<PersonalEpoch>(&_v5, _v23);
            vector::push_back<PersonalEpoch>(_v26, _v27);
            continue
        };
        let _v28 = _v18 + 1;
        let _v29 = false;
        let _v30 = vector::length<PersonalEpoch>(&_v5);
        'l1: loop {
            loop {
                if (_v29) _v28 = _v28 + 1 else _v29 = true;
                if (!(_v28 < _v30)) break 'l1;
                let _v31 = *vector::borrow<PersonalEpoch>(&_v5, _v28);
                let _v32 = &p2.epoch_list;
                let _v33 = *&(&_v31).epoch_time;
                if (!smart_table::contains<u64, Epoch>(_v32, _v33)) break;
                let _v34 = &mut p2.epoch_list;
                let _v35 = *&(&_v31).epoch_time;
                let _v36 = smart_table::borrow_mut<u64, Epoch>(_v34, _v35);
                let _v37 = *&_v36.epoch_total_xrion_amount;
                let _v38 = *&(&_v31).epoch_current_xrion_amount;
                if (_v37 >= _v38) {
                    _v1 = *&(&_v31).epoch_current_xrion_amount;
                    _v0 = &mut _v36.epoch_total_xrion_amount;
                    *_v0 = *_v0 - _v1;
                    continue
                };
                let _v39 = &mut _v36.epoch_total_xrion_amount;
                *_v39 = 0;
                continue
            };
            let _v40 = error::aborted(23);
            abort _v40
        };
        let _v41 = &p2.epoch_list;
        let _v42 = _v10 as u64;
        if (smart_table::contains<u64, Epoch>(_v41, _v42)) {
            let _v43 = &p2.epoch_list;
            let _v44 = _v10 as u64;
            _v1 = *&smart_table::borrow<u64, Epoch>(_v43, _v44).epoch_total_xrion_amount
        } else {
            let _v45 = create_new_global_epoch(_v10 as u64);
            let _v46 = &mut p2.epoch_list;
            let _v47 = _v10 as u64;
            smart_table::add<u64, Epoch>(_v46, _v47, _v45);
            _v1 = 0
        };
        if (!(vector::length<PersonalEpoch>(&_v5) - _v18 >= 2)) {
            let _v48 = error::aborted(41);
            abort _v48
        };
        let _v49 = vector::length<PersonalEpoch>(&_v5) - _v18 - 2 + p3;
        let (_v50,_v51,_v52) = create_new_personal_epoch(p2, _v4, _v49);
        let _v53 = _v50;
        let _v54 = &_v53;
        let _v55 = vector::length<PersonalEpoch>(&_v53) - 1;
        let _v56 = *&vector::borrow<PersonalEpoch>(_v54, _v55).epoch_time;
        let _v57 = *&p2.maximum_epoch_time;
        if (!(_v56 <= _v57)) {
            let _v58 = error::aborted(39);
            abort _v58
        };
        let _v59 = timestamp::now_seconds();
        if (!(_v56 > _v59)) {
            let _v60 = error::aborted(19);
            abort _v60
        };
        vector::append<PersonalEpoch>(&mut _v22, _v53);
        let (_v61,_v62) = break_down_personal_epoch_for_event(_v22);
        let _v63 = signer::address_of(p0);
        let _v64 = *&p1.object;
        let _v65 = *&p2.total_stake_amount;
        let _v66 = _v10 as u64;
        send_event::send_extend_v2_event(_v63, _v3, _v2, _v4, _v56, _v61, _v62, _v6, _v7, _v64, _v65, _v66, _v1, p3);
        _v0 = &mut p1.unlock_time;
        *_v0 = _v56;
        let _v67 = &mut p1.list;
        *_v67 = _v22;
    }
    fun get_current_epoch_index(): u64
        acquires HyperionStake
    {
        let _v0 = package_manager::get_rion_address();
        let _v1 = borrow_global<HyperionStake>(_v0);
        let _v2 = timestamp::now_seconds();
        let _v3 = *&_v1.start_time;
        let _v4 = _v2 - _v3;
        let _v5 = *&_v1.period;
        _v4 / _v5 + 1
    }
    public fun get_epoch_xrion(p0: u64): u64
        acquires HyperionStake
    {
        let _v0;
        let _v1 = package_manager::get_rion_address();
        let _v2 = borrow_global<HyperionStake>(_v1);
        if (smart_table::contains<u64, Epoch>(&_v2.epoch_list, p0)) _v0 = *&smart_table::borrow<u64, Epoch>(&_v2.epoch_list, p0).epoch_total_xrion_amount else _v0 = 0;
        _v0
    }
    friend fun get_fee_from_epoch(p0: u64, p1: u64, p2: object::Object<fungible_asset::Metadata>): fungible_asset::FungibleAsset
        acquires HyperionStake
    {
        let _v0 = package_manager::get_rion_address();
        let _v1 = borrow_global<HyperionStake>(_v0);
        if (!smart_table::contains<u64, Epoch>(&_v1.epoch_list, p0)) {
            let _v2 = error::aborted(23);
            abort _v2
        };
        let _v3 = smart_table::borrow<u64, Epoch>(&_v1.epoch_list, p0);
        if (!(vector::length<object::Object<fungible_asset::FungibleStore>>(&_v3.epoch_store) > p1)) {
            let _v4 = error::aborted(44);
            abort _v4
        };
        let _v5 = vector::borrow<object::Object<fungible_asset::FungibleStore>>(&_v3.epoch_store, p1);
        let _v6 = fungible_asset::store_metadata<fungible_asset::FungibleStore>(*_v5);
        if (!(p2 == _v6)) {
            let _v7 = error::aborted(43);
            abort _v7
        };
        let _v8 = fungible_asset::balance<fungible_asset::FungibleStore>(*_v5);
        let _v9 = package_manager::get_rion_signer();
        let _v10 = &_v9;
        let _v11 = *_v5;
        dispatchable_fungible_asset::withdraw<fungible_asset::FungibleStore>(_v10, _v11, _v8)
    }
    public fun get_last_epoch_can_claim(): bool
        acquires HyperionStake
    {
        let _v0;
        let _v1 = get_current_time() as u64;
        let _v2 = package_manager::get_rion_address();
        let _v3 = borrow_global<HyperionStake>(_v2);
        let _v4 = *&_v3.period;
        let _v5 = _v1 - _v4;
        if (smart_table::contains<u64, Epoch>(&_v3.epoch_list, _v5)) _v0 = *&smart_table::borrow<u64, Epoch>(&_v3.epoch_list, _v5).can_claim else _v0 = false;
        _v0
    }
    public fun get_left_period(p0: object::Object<StakeDetails>): u64
        acquires HyperionStake, StakeDetails
    {
        let _v0;
        let _v1 = get_current_time() as u64;
        let _v2 = object::object_address<StakeDetails>(&p0);
        let _v3 = borrow_global<StakeDetails>(_v2);
        let _v4 = &_v3.list;
        let _v5 = false;
        let _v6 = 0;
        let _v7 = 0;
        let _v8 = vector::length<PersonalEpoch>(_v4);
        'l0: loop {
            loop {
                if (!(_v7 < _v8)) break 'l0;
                if (*&vector::borrow<PersonalEpoch>(_v4, _v7).epoch_time == _v1) break;
                _v7 = _v7 + 1
            };
            _v5 = true;
            _v6 = _v7;
            break
        };
        if (_v5) {
            let _v9 = 54 + _v6;
            let _v10 = vector::length<PersonalEpoch>(&_v3.list);
            _v0 = _v9 - _v10
        } else _v0 = 0;
        _v0
    }
    public fun get_meta(): object::Object<fungible_asset::Metadata>
        acquires HyperionStake
    {
        let _v0 = package_manager::get_rion_address();
        *&borrow_global<HyperionStake>(_v0).meta
    }
    public fun get_pending_reward(p0: address, p1: object::Object<StakeDetails>): (vector<u64>, vector<vector<u64>>, vector<vector<object::Object<fungible_asset::Metadata>>>, vector<bool>)
        acquires HyperionStake, StakeDetails
    {
        let _v0 = vector::empty<vector<object::Object<fungible_asset::Metadata>>>();
        let _v1 = vector::empty<u64>();
        let _v2 = vector::empty<vector<u64>>();
        let _v3 = vector::empty<bool>();
        let _v4 = package_manager::get_rion_address();
        let _v5 = borrow_global<HyperionStake>(_v4);
        if (!smart_table::contains<address, vector<object::Object<StakeDetails>>>(&_v5.user_stake_list, p0)) {
            let _v6 = error::aborted(17);
            abort _v6
        };
        let _v7 = smart_table::borrow<address, vector<object::Object<StakeDetails>>>(&_v5.user_stake_list, p0);
        let _v8 = false;
        let _v9 = 0;
        let _v10 = vector::length<object::Object<StakeDetails>>(_v7);
        'l0: loop {
            loop {
                if (!(_v9 < _v10)) break 'l0;
                let _v11 = vector::borrow<object::Object<StakeDetails>>(_v7, _v9);
                let _v12 = &p1;
                if (_v11 == _v12) break;
                _v9 = _v9 + 1;
                continue
            };
            _v8 = true;
            break
        };
        if (!_v8) {
            let _v13 = error::aborted(10);
            abort _v13
        };
        let _v14 = object::object_address<StakeDetails>(&p1);
        let _v15 = borrow_global<StakeDetails>(_v14);
        let _v16 = (*&_v5.start_time) as u256;
        let _v17 = (*&_v5.period) as u256;
        let _v18 = get_epoch_time(0u256, _v16, _v17, false) as u64;
        let _v19 = 0;
        let _v20 = false;
        let _v21 = vector::length<PersonalEpoch>(&_v15.list);
        loop {
            let _v22;
            let _v23;
            let _v24;
            let _v25;
            let _v26;
            if (_v20) _v19 = _v19 + 1 else _v20 = true;
            if (!(_v19 < _v21)) break;
            let _v27 = vector::borrow<PersonalEpoch>(&_v15.list, _v19);
            let _v28 = &_v5.epoch_list;
            let _v29 = *&_v27.epoch_time;
            let _v30 = smart_table::borrow<u64, Epoch>(_v28, _v29);
            if (*&_v27.epoch_time >= _v18) break;
            if (*&_v30.can_claim) {
                let _v31 = &mut _v1;
                let _v32 = *&_v27.epoch_time;
                vector::push_back<u64>(_v31, _v32);
                let _v33 = &mut _v3;
                let _v34 = *&_v27.claimed;
                vector::push_back<bool>(_v33, _v34);
                _v26 = vector::empty<object::Object<fungible_asset::Metadata>>();
                _v25 = vector::empty<u64>();
                _v24 = 0;
                _v23 = false;
                _v22 = vector::length<Reward>(&_v30.reward)
            } else continue;
            loop {
                if (_v23) _v24 = _v24 + 1 else _v23 = true;
                if (!(_v24 < _v22)) break;
                let _v35 = vector::borrow<Reward>(&_v30.reward, _v24);
                let _v36 = *&_v35.meta;
                if (*&_v30.epoch_total_xrion_amount != 0) {
                    let _v37 = (*&_v35.total_amount) as u256;
                    let _v38 = (*&_v27.epoch_current_xrion_amount) as u256;
                    let _v39 = (*&_v30.epoch_total_xrion_amount) as u256;
                    let _v40 = cal_pending_reward(_v37, _v38, _v39) as u64;
                    vector::push_back<u64>(&mut _v25, _v40);
                    vector::push_back<object::Object<fungible_asset::Metadata>>(&mut _v26, _v36);
                    continue
                };
                vector::push_back<u64>(&mut _v25, 0);
                vector::push_back<object::Object<fungible_asset::Metadata>>(&mut _v26, _v36);
                continue
            };
            vector::push_back<vector<object::Object<fungible_asset::Metadata>>>(&mut _v0, _v26);
            vector::push_back<vector<u64>>(&mut _v2, _v25);
            continue
        };
        (_v1, _v2, _v0, _v3)
    }
    public fun get_pending_reward_without_limit(p0: address, p1: object::Object<StakeDetails>): (vector<u64>, vector<vector<u64>>, vector<vector<object::Object<fungible_asset::Metadata>>>, vector<bool>)
        acquires HyperionStake, StakeDetails
    {
        let _v0 = vector::empty<vector<object::Object<fungible_asset::Metadata>>>();
        let _v1 = vector::empty<u64>();
        let _v2 = vector::empty<vector<u64>>();
        let _v3 = vector::empty<bool>();
        let _v4 = package_manager::get_rion_address();
        let _v5 = borrow_global<HyperionStake>(_v4);
        if (!smart_table::contains<address, vector<object::Object<StakeDetails>>>(&_v5.user_stake_list, p0)) {
            let _v6 = error::aborted(17);
            abort _v6
        };
        let _v7 = smart_table::borrow<address, vector<object::Object<StakeDetails>>>(&_v5.user_stake_list, p0);
        let _v8 = false;
        let _v9 = 0;
        let _v10 = vector::length<object::Object<StakeDetails>>(_v7);
        'l0: loop {
            loop {
                if (!(_v9 < _v10)) break 'l0;
                let _v11 = vector::borrow<object::Object<StakeDetails>>(_v7, _v9);
                let _v12 = &p1;
                if (_v11 == _v12) break;
                _v9 = _v9 + 1;
                continue
            };
            _v8 = true;
            break
        };
        if (!_v8) {
            let _v13 = error::aborted(10);
            abort _v13
        };
        let _v14 = object::object_address<StakeDetails>(&p1);
        let _v15 = borrow_global<StakeDetails>(_v14);
        let _v16 = (*&_v5.start_time) as u256;
        let _v17 = (*&_v5.period) as u256;
        let _v18 = get_epoch_time(0u256, _v16, _v17, false) as u64;
        let _v19 = 0;
        let _v20 = false;
        let _v21 = vector::length<PersonalEpoch>(&_v15.list);
        loop {
            if (_v20) _v19 = _v19 + 1 else _v20 = true;
            if (!(_v19 < _v21)) break;
            let _v22 = vector::borrow<PersonalEpoch>(&_v15.list, _v19);
            let _v23 = &_v5.epoch_list;
            let _v24 = *&_v22.epoch_time;
            let _v25 = smart_table::borrow<u64, Epoch>(_v23, _v24);
            if (*&_v22.epoch_time >= _v18) break;
            let _v26 = &mut _v1;
            let _v27 = *&_v22.epoch_time;
            vector::push_back<u64>(_v26, _v27);
            let _v28 = &mut _v3;
            let _v29 = *&_v22.claimed;
            vector::push_back<bool>(_v28, _v29);
            let _v30 = vector::empty<object::Object<fungible_asset::Metadata>>();
            let _v31 = vector::empty<u64>();
            let _v32 = 0;
            let _v33 = false;
            let _v34 = vector::length<Reward>(&_v25.reward);
            loop {
                if (_v33) _v32 = _v32 + 1 else _v33 = true;
                if (!(_v32 < _v34)) break;
                let _v35 = vector::borrow<Reward>(&_v25.reward, _v32);
                let _v36 = *&_v35.meta;
                if (*&_v25.epoch_total_xrion_amount != 0) {
                    let _v37 = (*&_v35.total_amount) as u256;
                    let _v38 = (*&_v22.epoch_current_xrion_amount) as u256;
                    let _v39 = (*&_v25.epoch_total_xrion_amount) as u256;
                    let _v40 = cal_pending_reward(_v37, _v38, _v39) as u64;
                    vector::push_back<u64>(&mut _v31, _v40);
                    vector::push_back<object::Object<fungible_asset::Metadata>>(&mut _v30, _v36);
                    continue
                };
                vector::push_back<u64>(&mut _v31, 0);
                vector::push_back<object::Object<fungible_asset::Metadata>>(&mut _v30, _v36);
                continue
            };
            vector::push_back<vector<object::Object<fungible_asset::Metadata>>>(&mut _v0, _v30);
            vector::push_back<vector<u64>>(&mut _v2, _v31);
            continue
        };
        (_v1, _v2, _v0, _v3)
    }
    public fun get_period(): u64
        acquires HyperionStake
    {
        let _v0 = package_manager::get_rion_address();
        *&borrow_global<HyperionStake>(_v0).period
    }
    public fun get_stake_and_xrion_amount(p0: address, p1: object::Object<StakeDetails>): (u64, u64, u64)
        acquires HyperionStake, StakeDetails
    {
        let _v0 = get_current_epoch_index();
        let _v1 = package_manager::get_rion_address();
        let _v2 = borrow_global<HyperionStake>(_v1);
        if (!smart_table::contains<address, vector<object::Object<StakeDetails>>>(&_v2.user_stake_list, p0)) {
            let _v3 = error::aborted(17);
            abort _v3
        };
        let _v4 = smart_table::borrow<address, vector<object::Object<StakeDetails>>>(&_v2.user_stake_list, p0);
        let _v5 = _v4;
        let _v6 = false;
        let _v7 = 0;
        let _v8 = 0;
        let _v9 = vector::length<object::Object<StakeDetails>>(_v5);
        'l0: loop {
            loop {
                if (!(_v8 < _v9)) break 'l0;
                let _v10 = vector::borrow<object::Object<StakeDetails>>(_v5, _v8);
                let _v11 = &p1;
                if (_v10 == _v11) break;
                _v8 = _v8 + 1;
                continue
            };
            _v6 = true;
            _v7 = _v8;
            break
        };
        if (!_v6) {
            let _v12 = error::aborted(10);
            abort _v12
        };
        let _v13 = object::object_address<StakeDetails>(vector::borrow<object::Object<StakeDetails>>(_v4, _v7));
        let _v14 = borrow_global<StakeDetails>(_v13);
        let _v15 = *&_v2.period;
        let _v16 = _v0 * _v15;
        let _v17 = *&_v2.start_time;
        let _v18 = _v16 + _v17;
        let _v19 = smart_table::borrow<u64, Epoch>(&_v2.epoch_list, _v18);
        let _v20 = &_v14.list;
        let _v21 = false;
        let _v22 = 0;
        let _v23 = 0;
        let _v24 = vector::length<PersonalEpoch>(_v20);
        'l1: loop {
            loop {
                if (!(_v23 < _v24)) break 'l1;
                if (*&vector::borrow<PersonalEpoch>(_v20, _v23).epoch_time == _v18) break;
                _v23 = _v23 + 1
            };
            _v21 = true;
            _v22 = _v23;
            break
        };
        if (!_v21) {
            let _v25 = error::aborted(22);
            abort _v25
        };
        let _v26 = vector::borrow<PersonalEpoch>(&_v14.list, _v22);
        let _v27 = fungible_asset::balance<fungible_asset::FungibleStore>(*&_v14.rion_store);
        let _v28 = *&_v26.epoch_current_xrion_amount;
        let _v29 = *&_v19.epoch_total_xrion_amount;
        (_v27, _v28, _v29)
    }
    public fun get_stake_data(p0: address, p1: object::Object<StakeDetails>): (vector<u64>, vector<u64>, u64, u64, u64)
        acquires HyperionStake, StakeDetails
    {
        let _v0 = package_manager::get_rion_address();
        let _v1 = borrow_global<HyperionStake>(_v0);
        if (!smart_table::contains<address, vector<object::Object<StakeDetails>>>(&_v1.user_stake_list, p0)) {
            let _v2 = error::aborted(17);
            abort _v2
        };
        let _v3 = smart_table::borrow<address, vector<object::Object<StakeDetails>>>(&_v1.user_stake_list, p0);
        let _v4 = _v3;
        let _v5 = false;
        let _v6 = 0;
        let _v7 = 0;
        let _v8 = vector::length<object::Object<StakeDetails>>(_v4);
        'l0: loop {
            loop {
                if (!(_v7 < _v8)) break 'l0;
                let _v9 = vector::borrow<object::Object<StakeDetails>>(_v4, _v7);
                let _v10 = &p1;
                if (_v9 == _v10) break;
                _v7 = _v7 + 1;
                continue
            };
            _v5 = true;
            _v6 = _v7;
            break
        };
        if (!_v5) {
            let _v11 = error::aborted(10);
            abort _v11
        };
        let _v12 = object::object_address<StakeDetails>(vector::borrow<object::Object<StakeDetails>>(_v3, _v6));
        let _v13 = borrow_global<StakeDetails>(_v12);
        let _v14 = vector::empty<u64>();
        let _v15 = vector::empty<u64>();
        let _v16 = 0;
        let _v17 = false;
        let _v18 = vector::length<PersonalEpoch>(&_v13.list);
        loop {
            if (_v17) _v16 = _v16 + 1 else _v17 = true;
            if (!(_v16 < _v18)) break;
            let _v19 = vector::borrow<PersonalEpoch>(&_v13.list, _v16);
            let _v20 = &mut _v14;
            let _v21 = *&_v19.epoch_time;
            vector::push_back<u64>(_v20, _v21);
            let _v22 = &mut _v15;
            let _v23 = *&_v19.epoch_current_xrion_amount;
            vector::push_back<u64>(_v22, _v23);
            continue
        };
        let _v24 = fungible_asset::balance<fungible_asset::FungibleStore>(*&_v13.rion_store);
        let _v25 = *&_v13.stake_time;
        let _v26 = *&_v13.unlock_time;
        (_v14, _v15, _v24, _v25, _v26)
    }
    public fun get_store_of_current_epoch(): (vector<object::Object<fungible_asset::Metadata>>, vector<u64>)
        acquires HyperionStake
    {
        let _v0 = get_current_time() as u64;
        let _v1 = package_manager::get_rion_address();
        let _v2 = borrow_global<HyperionStake>(_v1);
        let _v3 = vector::empty<object::Object<fungible_asset::Metadata>>();
        let _v4 = vector::empty<u64>();
        if (smart_table::contains<u64, Epoch>(&_v2.epoch_list, _v0)) {
            let _v5 = &smart_table::borrow<u64, Epoch>(&_v2.epoch_list, _v0).epoch_store;
            let _v6 = 0;
            let _v7 = vector::length<object::Object<fungible_asset::FungibleStore>>(_v5);
            while (_v6 < _v7) {
                let _v8 = vector::borrow<object::Object<fungible_asset::FungibleStore>>(_v5, _v6);
                let _v9 = &mut _v3;
                let _v10 = fungible_asset::store_metadata<fungible_asset::FungibleStore>(*_v8);
                vector::push_back<object::Object<fungible_asset::Metadata>>(_v9, _v10);
                let _v11 = &mut _v4;
                let _v12 = fungible_asset::balance<fungible_asset::FungibleStore>(*_v8);
                vector::push_back<u64>(_v11, _v12);
                _v6 = _v6 + 1;
                continue
            }
        };
        (_v3, _v4)
    }
    public fun get_store_of_epoch(p0: u64): (vector<object::Object<fungible_asset::Metadata>>, vector<u64>)
        acquires HyperionStake
    {
        let _v0 = package_manager::get_rion_address();
        let _v1 = borrow_global<HyperionStake>(_v0);
        let _v2 = vector::empty<object::Object<fungible_asset::Metadata>>();
        let _v3 = vector::empty<u64>();
        if (smart_table::contains<u64, Epoch>(&_v1.epoch_list, p0)) {
            let _v4 = &smart_table::borrow<u64, Epoch>(&_v1.epoch_list, p0).epoch_store;
            let _v5 = 0;
            let _v6 = vector::length<object::Object<fungible_asset::FungibleStore>>(_v4);
            while (_v5 < _v6) {
                let _v7 = vector::borrow<object::Object<fungible_asset::FungibleStore>>(_v4, _v5);
                let _v8 = &mut _v2;
                let _v9 = fungible_asset::store_metadata<fungible_asset::FungibleStore>(*_v7);
                vector::push_back<object::Object<fungible_asset::Metadata>>(_v8, _v9);
                let _v10 = &mut _v3;
                let _v11 = fungible_asset::balance<fungible_asset::FungibleStore>(*_v7);
                vector::push_back<u64>(_v10, _v11);
                _v5 = _v5 + 1;
                continue
            }
        };
        (_v2, _v3)
    }
    public fun get_total_stake_amount_maximum_time(): (u64, u64, u64, u64, object::Object<fungible_asset::Metadata>)
        acquires HyperionStake
    {
        let _v0 = package_manager::get_rion_address();
        let _v1 = borrow_global<HyperionStake>(_v0);
        let _v2 = *&_v1.total_stake_amount;
        let _v3 = *&_v1.maximum_stake_capability;
        let _v4 = *&_v1.start_time;
        let _v5 = *&_v1.maximum_epoch_time;
        let _v6 = *&_v1.meta;
        (_v2, _v3, _v4, _v5, _v6)
    }
    fun heapify_personal_epoch(p0: &mut vector<PersonalEpoch>, p1: u64, p2: u64) {
        loop {
            let _v0;
            let _v1;
            let _v2 = p2;
            let _v3 = 2 * p2 + 1;
            let _v4 = 2 * p2 + 2;
            if (_v3 < p1) {
                let _v5 = *&vector::borrow<PersonalEpoch>(freeze(p0), _v3).epoch_time;
                let _v6 = *&vector::borrow<PersonalEpoch>(freeze(p0), _v2).epoch_time;
                _v1 = _v5 > _v6
            } else _v1 = false;
            if (_v1) _v2 = _v3;
            if (_v4 < p1) {
                let _v7 = *&vector::borrow<PersonalEpoch>(freeze(p0), _v4).epoch_time;
                let _v8 = *&vector::borrow<PersonalEpoch>(freeze(p0), _v2).epoch_time;
                _v0 = _v7 > _v8
            } else _v0 = false;
            if (_v0) _v2 = _v4;
            if (_v2 == p2) break;
            vector::swap<PersonalEpoch>(p0, p2, _v2);
            p2 = _v2;
            continue
        };
    }
    public fun preview_epoch(p0: u64, p1: u64): vector<PreviewEpoch>
        acquires HyperionStake
    {
        let _v0 = package_manager::get_rion_address();
        let _v1 = borrow_global<HyperionStake>(_v0);
        let _v2 = vector::empty<PreviewEpoch>();
        let _v3 = &mut _v2;
        let _v4 = (*&_v1.start_time) as u256;
        let _v5 = (*&_v1.period) as u256;
        let _v6 = PreviewEpoch{epoch_time: get_epoch_time(0u256, _v4, _v5, false) as u64, epoch_current_xrion_amount: 0};
        vector::push_back<PreviewEpoch>(_v3, _v6);
        let _v7 = 0;
        let _v8 = false;
        let _v9 = p1 + 1;
        loop {
            if (_v8) _v7 = _v7 + 1 else _v8 = true;
            if (!(_v7 < _v9)) break;
            let _v10 = _v7 as u256;
            let _v11 = (*&_v1.start_time) as u256;
            let _v12 = (*&_v1.period) as u256;
            let _v13 = get_epoch_time(_v10, _v11, _v12, true) as u64;
            let _v14 = create_single_personal_epoch(p0, _v7, _v13, p1);
            let _v15 = &mut _v2;
            let _v16 = *&(&_v14).epoch_time;
            let _v17 = *&(&_v14).epoch_current_xrion_amount;
            let _v18 = PreviewEpoch{epoch_time: _v16, epoch_current_xrion_amount: _v17};
            vector::push_back<PreviewEpoch>(_v15, _v18);
            continue
        };
        _v2
    }
    public entry fun release_blacklist(p0: &signer, p1: address, p2: object::Object<StakeDetails>)
        acquires HyperionStake, StakeDetails
    {
        let _v0 = string::utf8(vector[114u8, 101u8, 108u8, 101u8, 97u8, 115u8, 101u8, 95u8, 98u8, 108u8, 97u8, 99u8, 107u8, 108u8, 105u8, 115u8, 116u8]);
        check_function_permission(p0, _v0);
        let _v1 = package_manager::get_rion_address();
        let _v2 = borrow_global_mut<HyperionStake>(_v1);
        if (!smart_table::contains<address, vector<object::Object<StakeDetails>>>(&_v2.user_stake_list, p1)) {
            let _v3 = error::aborted(17);
            abort _v3
        };
        let _v4 = smart_table::borrow_mut<address, vector<object::Object<StakeDetails>>>(&mut _v2.user_stake_list, p1);
        let _v5 = freeze(_v4);
        let _v6 = false;
        let _v7 = 0;
        let _v8 = 0;
        let _v9 = vector::length<object::Object<StakeDetails>>(_v5);
        'l0: loop {
            loop {
                if (!(_v8 < _v9)) break 'l0;
                let _v10 = vector::borrow<object::Object<StakeDetails>>(_v5, _v8);
                let _v11 = &p2;
                if (_v10 == _v11) break;
                _v8 = _v8 + 1;
                continue
            };
            _v6 = true;
            _v7 = _v8;
            break
        };
        if (!_v6) {
            let _v12 = error::aborted(10);
            abort _v12
        };
        let _v13 = object::object_address<StakeDetails>(freeze(vector::borrow_mut<object::Object<StakeDetails>>(_v4, _v7)));
        let _v14 = borrow_global_mut<StakeDetails>(_v13);
        if (!blacklist::is_blacklist(&_v14.status)) {
            let _v15 = error::aborted(35);
            abort _v15
        };
        let _v16 = blacklist::create_normal();
        let _v17 = &mut _v14.status;
        *_v17 = _v16;
        let _v18 = *&vector::borrow<PersonalEpoch>(&_v14.list, 1).epoch_current_xrion_amount;
        let _v19 = &mut _v2.blacklist_xrion;
        *_v19 = *_v19 - _v18;
        _v18 = fungible_asset::balance<fungible_asset::FungibleStore>(*&_v14.rion_store);
        _v19 = &mut _v2.blacklist_amount;
        *_v19 = *_v19 - _v18;
        let _v20 = &mut _v14.list;
        let _v21 = &mut _v2.epoch_list;
        blacklist_increase_xrion_to_each_epoch(_v20, _v21);
    }
    public fun reward_remain(p0: u64): (vector<object::Object<fungible_asset::Metadata>>, vector<u64>)
        acquires HyperionStake
    {
        let _v0 = package_manager::get_rion_address();
        let _v1 = smart_table::borrow<u64, Epoch>(&borrow_global<HyperionStake>(_v0).epoch_list, p0);
        let _v2 = vector::empty<object::Object<fungible_asset::Metadata>>();
        let _v3 = vector::empty<u64>();
        let _v4 = &_v1.reward;
        p0 = 0;
        let _v5 = vector::length<Reward>(_v4);
        while (p0 < _v5) {
            let _v6 = vector::borrow<Reward>(_v4, p0);
            let _v7 = &mut _v3;
            let _v8 = fungible_asset::balance<fungible_asset::FungibleStore>(*&_v6.store);
            vector::push_back<u64>(_v7, _v8);
            let _v9 = &mut _v2;
            let _v10 = fungible_asset::store_metadata<fungible_asset::FungibleStore>(*&_v6.store);
            vector::push_back<object::Object<fungible_asset::Metadata>>(_v9, _v10);
            p0 = p0 + 1;
            continue
        };
        (_v2, _v3)
    }
    friend fun set_can_claim(p0: &signer, p1: u64)
        acquires HyperionStake
    {
        let _v0 = string::utf8(vector[115u8, 101u8, 116u8, 95u8, 99u8, 97u8, 110u8, 95u8, 99u8, 108u8, 97u8, 105u8, 109u8]);
        check_function_permission(p0, _v0);
        let _v1 = get_current_time() as u64;
        let _v2 = package_manager::get_rion_address();
        let _v3 = borrow_global_mut<HyperionStake>(_v2);
        if (!smart_table::contains<u64, Epoch>(&_v3.epoch_list, p1)) {
            let _v4 = error::aborted(23);
            abort _v4
        };
        let _v5 = smart_table::borrow_mut<u64, Epoch>(&mut _v3.epoch_list, p1);
        if (!(_v1 > p1)) {
            let _v6 = error::aborted(45);
            abort _v6
        };
        let _v7 = &mut _v5.can_claim;
        *_v7 = true;
        send_event::send_can_claim_event(signer::address_of(p0), p1);
    }
    public entry fun stop(p0: &signer)
        acquires HyperionStake
    {
        let _v0 = string::utf8(vector[115u8, 116u8, 111u8, 112u8]);
        check_function_permission(p0, _v0);
        let _v1 = package_manager::get_rion_address();
        let _v2 = &mut borrow_global_mut<HyperionStake>(_v1).pause;
        *_v2 = true;
    }
    friend fun swap_reward_to_current_epoch(p0: &signer, p1: u64, p2: fungible_asset::FungibleAsset)
        acquires HyperionStake
    {
        let _v0 = string::utf8(vector[115u8, 119u8, 97u8, 112u8, 95u8, 114u8, 101u8, 119u8, 97u8, 114u8, 100u8, 95u8, 116u8, 111u8, 95u8, 99u8, 117u8, 114u8, 114u8, 101u8, 110u8, 116u8, 95u8, 101u8, 112u8, 111u8, 99u8, 104u8]);
        check_function_permission(p0, _v0);
        let _v1 = package_manager::get_rion_address();
        let _v2 = borrow_global_mut<HyperionStake>(_v1);
        if (!smart_table::contains<u64, Epoch>(&_v2.epoch_list, p1)) {
            let _v3 = error::aborted(23);
            abort _v3
        };
        let _v4 = smart_table::borrow_mut<u64, Epoch>(&mut _v2.epoch_list, p1);
        let _v5 = fungible_asset::metadata_from_asset(&p2);
        let _v6 = fungible_asset::amount(&p2);
        let _v7 = &_v4.reward;
        let _v8 = false;
        let _v9 = 0;
        let _v10 = 0;
        let _v11 = vector::length<Reward>(_v7);
        'l0: loop {
            loop {
                if (!(_v10 < _v11)) break 'l0;
                if (*&vector::borrow<Reward>(_v7, _v10).meta == _v5) break;
                _v10 = _v10 + 1
            };
            _v8 = true;
            _v9 = _v10;
            break
        };
        if (_v8) {
            let _v12 = vector::borrow_mut<Reward>(&mut _v4.reward, _v9);
            let _v13 = &mut _v12.total_amount;
            *_v13 = *_v13 + _v6;
            dispatchable_fungible_asset::deposit<fungible_asset::FungibleStore>(*&_v12.store, p2)
        } else {
            let _v14 = create_reward(p2);
            vector::push_back<Reward>(&mut _v4.reward, _v14)
        };
        send_event::send_allocation_to_epoch_event(signer::address_of(p0), _v5, _v6, p1);
    }
    public entry fun unstake(p0: &signer, p1: object::Object<StakeDetails>)
        acquires HyperionStake, StakeDetails
    {
        let _v0;
        let _v1;
        let _v2;
        ensure_not_paused();
        let _v3 = p0;
        let _v4 = string::utf8(vector[117u8, 110u8, 115u8, 116u8, 97u8, 107u8, 101u8]);
        check_function_permission(_v3, _v4);
        let _v5 = package_manager::get_rion_signer();
        _v3 = &_v5;
        ensure_reward_can_claim(p1);
        claim_all_reward(p0, p1);
        let _v6 = package_manager::get_rion_address();
        let _v7 = borrow_global_mut<HyperionStake>(_v6);
        let _v8 = &_v7.user_stake_list;
        let _v9 = signer::address_of(p0);
        if (!smart_table::contains<address, vector<object::Object<StakeDetails>>>(_v8, _v9)) {
            let _v10 = error::aborted(9);
            abort _v10
        };
        let _v11 = &mut _v7.user_stake_list;
        let _v12 = signer::address_of(p0);
        let _v13 = smart_table::borrow_mut<address, vector<object::Object<StakeDetails>>>(_v11, _v12);
        let _v14 = freeze(_v13);
        let _v15 = false;
        let _v16 = 0;
        let _v17 = 0;
        let _v18 = vector::length<object::Object<StakeDetails>>(_v14);
        'l0: loop {
            loop {
                if (!(_v17 < _v18)) break 'l0;
                let _v19 = vector::borrow<object::Object<StakeDetails>>(_v14, _v17);
                let _v20 = &p1;
                if (_v19 == _v20) break;
                _v17 = _v17 + 1;
                continue
            };
            _v15 = true;
            _v16 = _v17;
            break
        };
        if (!_v15) {
            let _v21 = error::aborted(10);
            abort _v21
        };
        let _v22 = vector::remove<object::Object<StakeDetails>>(_v13, _v16);
        let _v23 = object::object_address<StakeDetails>(&_v22);
        let StakeDetails{status: _v24, store_del: _v25, rion_store: _v26, reward: _v27, list: _v28, stake_time: _v29, unlock_time: _v30, claimed_epoch_cursor: _v31, last_update_time: _v32, object: _v33, object_ext: _v34, object_del: _v35} = move_from<StakeDetails>(_v23);
        let _v36 = _v30;
        let _v37 = _v28;
        let _v38 = _v26;
        let _v39 = _v24;
        if (!(timestamp::now_seconds() >= _v36)) {
            let _v40 = error::aborted(4);
            abort _v40
        };
        if (!(object::object_address<StakeDetails>(&p1) == _v33)) {
            let _v41 = error::aborted(8);
            abort _v41
        };
        let _v42 = (*&_v7.start_time) as u256;
        let _v43 = (*&_v7.period) as u256;
        let _v44 = get_epoch_time(0u256, _v42, _v43, false) as u64;
        if (!(vector::length<PersonalEpoch>(&_v37) >= 1)) {
            let _v45 = error::aborted(22);
            abort _v45
        };
        let _v46 = &_v37;
        let _v47 = vector::length<PersonalEpoch>(&_v37) - 1;
        if (!(*&vector::borrow<PersonalEpoch>(_v46, _v47).epoch_current_xrion_amount == 0)) {
            let _v48 = error::aborted(6);
            abort _v48
        };
        if (smart_table::contains<u64, Epoch>(&_v7.epoch_list, _v44)) _v2 = *&smart_table::borrow<u64, Epoch>(&_v7.epoch_list, _v44).epoch_total_xrion_amount else {
            let _v49 = create_new_global_epoch(_v44);
            smart_table::add<u64, Epoch>(&mut _v7.epoch_list, _v44, _v49);
            _v2 = 0
        };
        let _v50 = signer::address_of(p0);
        let _v51 = fungible_asset::balance<fungible_asset::FungibleStore>(_v38);
        let _v52 = object::object_address<StakeDetails>(&_v22);
        let _v53 = *&_v7.total_stake_amount;
        let _v54 = fungible_asset::balance<fungible_asset::FungibleStore>(_v38);
        let _v55 = _v53 - _v54;
        send_event::send_unstake_event(_v50, _v51, _v36, _v52, _v55, _v44, _v2);
        if (blacklist::is_blacklist(&_v39)) {
            _v1 = fungible_asset::balance<fungible_asset::FungibleStore>(_v38);
            _v0 = &mut _v7.blacklist_amount;
            *_v0 = *_v0 - _v1;
            _v1 = *&vector::borrow<PersonalEpoch>(&_v37, 1).epoch_current_xrion_amount;
            _v0 = &mut _v7.blacklist_xrion;
            *_v0 = *_v0 - _v1
        };
        clean_person_epoch(_v37);
        clean_user_reward(_v27);
        _v1 = fungible_asset::balance<fungible_asset::FungibleStore>(_v38);
        let _v56 = dispatchable_fungible_asset::withdraw<fungible_asset::FungibleStore>(_v3, _v38, _v1);
        primary_fungible_store::deposit(signer::address_of(p0), _v56);
        _v0 = &mut _v7.total_stake_amount;
        *_v0 = *_v0 - _v1;
        object::delete(_v25);
        object::delete(_v35);
        if (vector::is_empty<object::Object<StakeDetails>>(freeze(_v13))) {
            clean_hyperion_user_stakedetails(signer::address_of(p0));
            return ()
        };
    }
    public entry fun unstake_only_principal(p0: &signer, p1: object::Object<StakeDetails>)
        acquires HyperionStake, StakeDetails
    {
        let _v0;
        ensure_not_paused();
        let _v1 = p0;
        let _v2 = string::utf8(vector[117u8, 110u8, 115u8, 116u8, 97u8, 107u8, 101u8, 95u8, 111u8, 110u8, 108u8, 121u8, 95u8, 112u8, 114u8, 105u8, 110u8, 99u8, 105u8, 112u8, 97u8, 108u8]);
        check_function_permission(_v1, _v2);
        let _v3 = package_manager::get_rion_signer();
        _v1 = &_v3;
        let _v4 = package_manager::get_rion_address();
        let _v5 = borrow_global_mut<HyperionStake>(_v4);
        let _v6 = &_v5.user_stake_list;
        let _v7 = signer::address_of(p0);
        if (!smart_table::contains<address, vector<object::Object<StakeDetails>>>(_v6, _v7)) {
            let _v8 = error::aborted(9);
            abort _v8
        };
        let _v9 = &mut _v5.user_stake_list;
        let _v10 = signer::address_of(p0);
        let _v11 = freeze(smart_table::borrow_mut<address, vector<object::Object<StakeDetails>>>(_v9, _v10));
        let _v12 = false;
        let _v13 = 0;
        let _v14 = vector::length<object::Object<StakeDetails>>(_v11);
        'l0: loop {
            loop {
                if (!(_v13 < _v14)) break 'l0;
                let _v15 = vector::borrow<object::Object<StakeDetails>>(_v11, _v13);
                let _v16 = &p1;
                if (_v15 == _v16) break;
                _v13 = _v13 + 1;
                continue
            };
            _v12 = true;
            break
        };
        if (!_v12) {
            let _v17 = error::aborted(10);
            abort _v17
        };
        let _v18 = object::object_address<StakeDetails>(&p1);
        let _v19 = borrow_global<StakeDetails>(_v18);
        let _v20 = timestamp::now_seconds();
        let _v21 = *&_v19.unlock_time;
        if (!(_v20 >= _v21)) {
            let _v22 = error::aborted(4);
            abort _v22
        };
        let _v23 = (*&_v5.start_time) as u256;
        let _v24 = (*&_v5.period) as u256;
        let _v25 = get_epoch_time(0u256, _v23, _v24, false) as u64;
        let _v26 = fungible_asset::balance<fungible_asset::FungibleStore>(*&_v19.rion_store);
        let _v27 = *&_v19.rion_store;
        let _v28 = dispatchable_fungible_asset::withdraw<fungible_asset::FungibleStore>(_v1, _v27, _v26);
        let _v29 = signer::address_of(p0);
        let _v30 = object::object_address<StakeDetails>(&p1);
        let _v31 = *&_v19.unlock_time;
        send_event::send_unstake_principal_event(_v29, _v30, _v26, _v31, _v25);
        if (blacklist::is_blacklist(&_v19.status)) {
            _v0 = &mut _v5.blacklist_amount;
            *_v0 = *_v0 - _v26
        };
        _v0 = &mut _v5.total_stake_amount;
        *_v0 = *_v0 - _v26;
        primary_fungible_store::deposit(signer::address_of(p0), _v28);
    }
    public fun user_epoch_xrion(p0: u64, p1: object::Object<StakeDetails>): u64
        acquires StakeDetails
    {
        let _v0;
        let _v1 = object::object_address<StakeDetails>(&p1);
        let _v2 = borrow_global<StakeDetails>(_v1);
        let _v3 = &_v2.list;
        let _v4 = false;
        let _v5 = 0;
        let _v6 = 0;
        let _v7 = vector::length<PersonalEpoch>(_v3);
        'l0: loop {
            loop {
                if (!(_v6 < _v7)) break 'l0;
                if (*&vector::borrow<PersonalEpoch>(_v3, _v6).epoch_time == p0) break;
                _v6 = _v6 + 1
            };
            _v4 = true;
            _v5 = _v6;
            break
        };
        if (_v4) _v0 = *&vector::borrow<PersonalEpoch>(&_v2.list, _v5).epoch_current_xrion_amount else _v0 = 0;
        _v0
    }
    public fun view_reward(p0: u256, p1: u256, p2: u256): u64 {
        cal_pending_reward(p0, p1, p2) as u64
    }
}
