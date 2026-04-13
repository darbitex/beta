module 0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c::fridge {
    use 0x1::option;
    use 0x1::object;
    use 0x1::fungible_asset;
    use 0x1::smart_table;
    use 0x1::smart_vector;
    use 0x1::signer;
    use 0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c::package_manager;
    use 0x1::simple_map;
    use 0x1::timestamp;
    use 0x1::table_with_length;
    use 0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c::caas_integration;
    use 0x92af222254470faeda82d447067ce14b38ceafedb4c7ea462bf6b1e98cecf1f8::passkey;
    use 0x1::dispatchable_fungible_asset;
    use 0x1::primary_fungible_store;
    use 0x1::event;
    use 0x1::string;
    use 0x1::bcs;
    use 0x1::vector;
    friend 0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c::router_v3;
    struct Box has store {
        pool_id: address,
        position_id: address,
        release_timestamp: u64,
        token_a_store: option::Option<object::Object<fungible_asset::FungibleStore>>,
        token_a_store_delete_ref: option::Option<object::DeleteRef>,
        token_b_store: option::Option<object::Object<fungible_asset::FungibleStore>>,
        token_b_store_delete_ref: option::Option<object::DeleteRef>,
        token_a_metadata: object::Object<fungible_asset::Metadata>,
        token_b_metadata: object::Object<fungible_asset::Metadata>,
        token_a_fee_store: option::Option<object::Object<fungible_asset::FungibleStore>>,
        token_b_fee_store: option::Option<object::Object<fungible_asset::FungibleStore>>,
        rewards: vector<option::Option<object::Object<fungible_asset::FungibleStore>>>,
    }
    struct BoxClaimedEvent has copy, drop, store {
        box_id: address,
        user: address,
        pool_id: address,
        position_id: address,
        token_a_metadata: object::Object<fungible_asset::Metadata>,
        token_a_amount: u64,
        token_b_metadata: object::Object<fungible_asset::Metadata>,
        token_b_amount: u64,
    }
    struct BoxSettedEvent has copy, drop, store {
        box_id: address,
        user: address,
        pool_id: address,
        position_id: address,
        token_a_metadata: object::Object<fungible_asset::Metadata>,
        token_a_amount: u64,
        token_b_metadata: object::Object<fungible_asset::Metadata>,
        token_b_amount: u64,
        release_timestamp: u64,
    }
    struct Fridge has key {
        boxes: smart_table::SmartTable<address, Box>,
    }
    struct FridgeBoxClaimedByAdminEvent has copy, drop, store {
        box_id: address,
        admin: address,
        user: address,
        receiver: address,
    }
    struct FridgeBoxReleaseTimeUpdatedEvent has copy, drop, store {
        box_id: address,
        admin: address,
        user: address,
        new_release_time: u64,
    }
    struct FridgeConfig has key {
        freeze_duration: u64,
        whiltelist: smart_vector::SmartVector<address>,
        asset_num_track: smart_table::SmartTable<address, u64>,
    }
    struct UserBox has copy, drop, store {
        box_id: address,
        release_timestamp: u64,
        token_a_metadata: object::Object<fungible_asset::Metadata>,
        token_b_metadata: object::Object<fungible_asset::Metadata>,
        token_a_amount: u64,
        token_b_amount: u64,
        position_id: address,
        pool_id: address,
    }
    entry fun initialize(p0: &signer) {
        assert!(package_manager::is_super_admin(signer::address_of(p0)), 2000001);
        let _v0 = package_manager::get_resource_address();
        if (!exists<FridgeConfig>(_v0)) {
            let _v1 = package_manager::get_signer();
            let _v2 = &_v1;
            let _v3 = smart_vector::empty<address>();
            let _v4 = smart_table::new<address, u64>();
            let _v5 = FridgeConfig{freeze_duration: 86400, whiltelist: _v3, asset_num_track: _v4};
            move_to<FridgeConfig>(_v2, _v5);
            return ()
        };
    }
    public fun asset_unclaimed(p0: object::Object<fungible_asset::Metadata>): u64
        acquires FridgeConfig
    {
        let _v0 = package_manager::get_resource_address();
        let _v1 = borrow_global<FridgeConfig>(_v0);
        let _v2 = object::object_address<fungible_asset::Metadata>(&p0);
        *smart_table::borrow<address, u64>(&_v1.asset_num_track, _v2)
    }
    public fun asset_unclaimed_all(): simple_map::SimpleMap<address, u64>
        acquires FridgeConfig
    {
        let _v0 = package_manager::get_resource_address();
        smart_table::to_simple_map<address, u64>(&borrow_global<FridgeConfig>(_v0).asset_num_track)
    }
    public fun box_can_be_released(p0: address, p1: address): bool
        acquires Fridge
    {
        let _v0 = smart_table::borrow<address, Box>(&borrow_global<Fridge>(p0).boxes, p1);
        let _v1 = timestamp::now_seconds();
        let _v2 = *&_v0.release_timestamp;
        _v1 >= _v2
    }
    public fun can_be_claimed_box_ids(p0: address): vector<address>
        acquires Fridge
    {
        let _v0 = vector::empty<address>();
        let _v1 = timestamp::now_seconds();
        let _v2 = &borrow_global_mut<Fridge>(p0).boxes;
        let _v3 = 0;
        let _v4 = false;
        let _v5 = smart_table::num_buckets<address, Box>(_v2);
        loop {
            if (_v4) _v3 = _v3 + 1 else _v4 = true;
            if (!(_v3 < _v5)) break;
            let _v6 = table_with_length::borrow<u64, vector<smart_table::Entry<address, Box>>>(smart_table::borrow_buckets<address, Box>(_v2), _v3);
            let _v7 = 0;
            let _v8 = vector::length<smart_table::Entry<address, Box>>(_v6);
            while (_v7 < _v8) {
                let (_v9,_v10) = smart_table::borrow_kv<address, Box>(vector::borrow<smart_table::Entry<address, Box>>(_v6, _v7));
                if (*&_v10.release_timestamp <= _v1) {
                    let _v11 = &mut _v0;
                    let _v12 = *_v9;
                    vector::push_back<address>(_v11, _v12)
                };
                _v7 = _v7 + 1;
                continue
            };
            continue
        };
        _v0
    }
    entry fun claim_box_all_released(p0: &signer)
        acquires Fridge, FridgeConfig
    {
        if (passkey::is_user_registered<caas_integration::Witness>(signer::address_of(p0))) abort 2000004;
        let _v0 = p0;
        let _v1 = signer::address_of(_v0);
        let _v2 = can_be_claimed_box_ids(_v1);
        let _v3 = signer::address_of(_v0);
        let _v4 = borrow_global_mut<Fridge>(_v3);
        let _v5 = vector::length<address>(&_v2);
        let _v6 = package_manager::get_signer();
        let _v7 = package_manager::get_resource_address();
        let _v8 = borrow_global_mut<FridgeConfig>(_v7);
        let _v9 = 0;
        loop {
            let _v10;
            let _v11;
            let _v12;
            let _v13;
            let _v14;
            let _v15;
            if (!(_v9 < _v5)) break;
            let _v16 = vector::pop_back<address>(&mut _v2);
            let _v17 = 0;
            let _v18 = 0;
            let Box{pool_id: _v19, position_id: _v20, release_timestamp: _v21, token_a_store: _v22, token_a_store_delete_ref: _v23, token_b_store: _v24, token_b_store_delete_ref: _v25, token_a_metadata: _v26, token_b_metadata: _v27, token_a_fee_store: _v28, token_b_fee_store: _v29, rewards: _v30} = smart_table::remove<address, Box>(&mut _v4.boxes, _v16);
            let _v31 = _v25;
            let _v32 = _v24;
            let _v33 = _v23;
            let _v34 = _v22;
            if (option::is_some<object::Object<fungible_asset::FungibleStore>>(&_v34)) {
                _v15 = option::extract<object::Object<fungible_asset::FungibleStore>>(&mut _v34);
                _v14 = dispatchable_fungible_asset::derived_balance<fungible_asset::FungibleStore>(_v15);
                let _v35 = fungible_asset::store_metadata<fungible_asset::FungibleStore>(_v15);
                _v13 = object::object_address<fungible_asset::Metadata>(&_v35);
                _v17 = _v14;
                _v12 = _v14;
                _v11 = smart_table::borrow_mut<address, u64>(&mut _v8.asset_num_track, _v13);
                *_v11 = *_v11 - _v12;
                _v10 = dispatchable_fungible_asset::withdraw<fungible_asset::FungibleStore>(&_v6, _v15, _v14);
                primary_fungible_store::deposit(_v1, _v10);
                let _v36 = option::extract<object::DeleteRef>(&mut _v33);
                fungible_asset::remove_store(&_v36)
            };
            if (option::is_some<object::Object<fungible_asset::FungibleStore>>(&_v32)) {
                _v15 = option::extract<object::Object<fungible_asset::FungibleStore>>(&mut _v32);
                _v14 = dispatchable_fungible_asset::derived_balance<fungible_asset::FungibleStore>(_v15);
                let _v37 = fungible_asset::store_metadata<fungible_asset::FungibleStore>(_v15);
                _v13 = object::object_address<fungible_asset::Metadata>(&_v37);
                _v18 = _v14;
                _v12 = _v14;
                _v11 = smart_table::borrow_mut<address, u64>(&mut _v8.asset_num_track, _v13);
                *_v11 = *_v11 - _v12;
                _v10 = dispatchable_fungible_asset::withdraw<fungible_asset::FungibleStore>(&_v6, _v15, _v14);
                primary_fungible_store::deposit(_v1, _v10);
                let _v38 = option::extract<object::DeleteRef>(&mut _v31);
                fungible_asset::remove_store(&_v38)
            };
            option::destroy_none<object::Object<fungible_asset::FungibleStore>>(_v34);
            option::destroy_none<object::Object<fungible_asset::FungibleStore>>(_v32);
            option::destroy_none<object::DeleteRef>(_v33);
            option::destroy_none<object::DeleteRef>(_v31);
            _v13 = _v1;
            event::emit<BoxClaimedEvent>(BoxClaimedEvent{box_id: _v16, user: _v13, pool_id: _v19, position_id: _v20, token_a_metadata: _v26, token_a_amount: _v17, token_b_metadata: _v27, token_b_amount: _v18});
            _v9 = _v9 + 1;
            continue
        };
    }
    entry fun claim_box_all_released_with_multiagent(p0: &signer, p1: &signer, p2: &signer)
        acquires Fridge, FridgeConfig
    {
        passkey::passkey_verify<caas_integration::Witness>(p0, p1, p2);
        let _v0 = signer::address_of(p0);
        let _v1 = can_be_claimed_box_ids(_v0);
        let _v2 = signer::address_of(p0);
        let _v3 = borrow_global_mut<Fridge>(_v2);
        let _v4 = vector::length<address>(&_v1);
        let _v5 = package_manager::get_signer();
        let _v6 = package_manager::get_resource_address();
        let _v7 = borrow_global_mut<FridgeConfig>(_v6);
        let _v8 = 0;
        loop {
            let _v9;
            let _v10;
            let _v11;
            let _v12;
            let _v13;
            let _v14;
            if (!(_v8 < _v4)) break;
            let _v15 = vector::pop_back<address>(&mut _v1);
            let _v16 = 0;
            let _v17 = 0;
            let Box{pool_id: _v18, position_id: _v19, release_timestamp: _v20, token_a_store: _v21, token_a_store_delete_ref: _v22, token_b_store: _v23, token_b_store_delete_ref: _v24, token_a_metadata: _v25, token_b_metadata: _v26, token_a_fee_store: _v27, token_b_fee_store: _v28, rewards: _v29} = smart_table::remove<address, Box>(&mut _v3.boxes, _v15);
            let _v30 = _v24;
            let _v31 = _v23;
            let _v32 = _v22;
            let _v33 = _v21;
            if (option::is_some<object::Object<fungible_asset::FungibleStore>>(&_v33)) {
                _v14 = option::extract<object::Object<fungible_asset::FungibleStore>>(&mut _v33);
                _v13 = dispatchable_fungible_asset::derived_balance<fungible_asset::FungibleStore>(_v14);
                let _v34 = fungible_asset::store_metadata<fungible_asset::FungibleStore>(_v14);
                _v12 = object::object_address<fungible_asset::Metadata>(&_v34);
                _v16 = _v13;
                _v11 = _v13;
                _v10 = smart_table::borrow_mut<address, u64>(&mut _v7.asset_num_track, _v12);
                *_v10 = *_v10 - _v11;
                _v9 = dispatchable_fungible_asset::withdraw<fungible_asset::FungibleStore>(&_v5, _v14, _v13);
                primary_fungible_store::deposit(_v0, _v9);
                let _v35 = option::extract<object::DeleteRef>(&mut _v32);
                fungible_asset::remove_store(&_v35)
            };
            if (option::is_some<object::Object<fungible_asset::FungibleStore>>(&_v31)) {
                _v14 = option::extract<object::Object<fungible_asset::FungibleStore>>(&mut _v31);
                _v13 = dispatchable_fungible_asset::derived_balance<fungible_asset::FungibleStore>(_v14);
                let _v36 = fungible_asset::store_metadata<fungible_asset::FungibleStore>(_v14);
                _v12 = object::object_address<fungible_asset::Metadata>(&_v36);
                _v17 = _v13;
                _v11 = _v13;
                _v10 = smart_table::borrow_mut<address, u64>(&mut _v7.asset_num_track, _v12);
                *_v10 = *_v10 - _v11;
                _v9 = dispatchable_fungible_asset::withdraw<fungible_asset::FungibleStore>(&_v5, _v14, _v13);
                primary_fungible_store::deposit(_v0, _v9);
                let _v37 = option::extract<object::DeleteRef>(&mut _v30);
                fungible_asset::remove_store(&_v37)
            };
            option::destroy_none<object::Object<fungible_asset::FungibleStore>>(_v33);
            option::destroy_none<object::Object<fungible_asset::FungibleStore>>(_v31);
            option::destroy_none<object::DeleteRef>(_v32);
            option::destroy_none<object::DeleteRef>(_v30);
            _v12 = _v0;
            event::emit<BoxClaimedEvent>(BoxClaimedEvent{box_id: _v15, user: _v12, pool_id: _v18, position_id: _v19, token_a_metadata: _v25, token_a_amount: _v16, token_b_metadata: _v26, token_b_amount: _v17});
            _v8 = _v8 + 1;
            continue
        };
    }
    entry fun claim_box_by_id(p0: &signer, p1: address)
        acquires Fridge, FridgeConfig
    {
        let _v0;
        let _v1;
        let _v2;
        let _v3;
        let _v4;
        if (passkey::is_user_registered<caas_integration::Witness>(signer::address_of(p0))) abort 2000004;
        let _v5 = p0;
        let _v6 = p1;
        let _v7 = signer::address_of(_v5);
        assert!(box_can_be_released(_v7, _v6), 2000002);
        let _v8 = package_manager::get_signer();
        let _v9 = signer::address_of(_v5);
        let _v10 = borrow_global_mut<Fridge>(_v9);
        let _v11 = package_manager::get_resource_address();
        let _v12 = borrow_global_mut<FridgeConfig>(_v11);
        let _v13 = 0;
        let _v14 = 0;
        let Box{pool_id: _v15, position_id: _v16, release_timestamp: _v17, token_a_store: _v18, token_a_store_delete_ref: _v19, token_b_store: _v20, token_b_store_delete_ref: _v21, token_a_metadata: _v22, token_b_metadata: _v23, token_a_fee_store: _v24, token_b_fee_store: _v25, rewards: _v26} = smart_table::remove<address, Box>(&mut _v10.boxes, _v6);
        let _v27 = _v21;
        let _v28 = _v20;
        let _v29 = _v19;
        let _v30 = _v18;
        if (option::is_some<object::Object<fungible_asset::FungibleStore>>(&_v30)) {
            _v4 = option::extract<object::Object<fungible_asset::FungibleStore>>(&mut _v30);
            let _v31 = fungible_asset::store_metadata<fungible_asset::FungibleStore>(_v4);
            _v3 = object::object_address<fungible_asset::Metadata>(&_v31);
            _v2 = dispatchable_fungible_asset::derived_balance<fungible_asset::FungibleStore>(_v4);
            _v13 = _v2;
            _v1 = smart_table::borrow_mut<address, u64>(&mut _v12.asset_num_track, _v3);
            *_v1 = *_v1 - _v2;
            _v0 = dispatchable_fungible_asset::withdraw<fungible_asset::FungibleStore>(&_v8, _v4, _v2);
            primary_fungible_store::deposit(_v7, _v0);
            let _v32 = option::extract<object::DeleteRef>(&mut _v29);
            fungible_asset::remove_store(&_v32)
        };
        if (option::is_some<object::Object<fungible_asset::FungibleStore>>(&_v28)) {
            _v4 = option::extract<object::Object<fungible_asset::FungibleStore>>(&mut _v28);
            let _v33 = fungible_asset::store_metadata<fungible_asset::FungibleStore>(_v4);
            _v3 = object::object_address<fungible_asset::Metadata>(&_v33);
            _v2 = dispatchable_fungible_asset::derived_balance<fungible_asset::FungibleStore>(_v4);
            _v14 = _v2;
            _v1 = smart_table::borrow_mut<address, u64>(&mut _v12.asset_num_track, _v3);
            *_v1 = *_v1 - _v2;
            _v0 = dispatchable_fungible_asset::withdraw<fungible_asset::FungibleStore>(&_v8, _v4, _v2);
            primary_fungible_store::deposit(_v7, _v0);
            let _v34 = option::extract<object::DeleteRef>(&mut _v27);
            fungible_asset::remove_store(&_v34)
        };
        option::destroy_none<object::Object<fungible_asset::FungibleStore>>(_v30);
        option::destroy_none<object::Object<fungible_asset::FungibleStore>>(_v28);
        option::destroy_none<object::DeleteRef>(_v29);
        option::destroy_none<object::DeleteRef>(_v27);
        event::emit<BoxClaimedEvent>(BoxClaimedEvent{box_id: _v6, user: _v7, pool_id: _v15, position_id: _v16, token_a_metadata: _v22, token_a_amount: _v13, token_b_metadata: _v23, token_b_amount: _v14});
    }
    entry fun claim_box_by_id_with_multiagent(p0: &signer, p1: &signer, p2: &signer, p3: address)
        acquires Fridge, FridgeConfig
    {
        let _v0;
        let _v1;
        let _v2;
        let _v3;
        let _v4;
        passkey::passkey_verify<caas_integration::Witness>(p0, p1, p2);
        let _v5 = signer::address_of(p0);
        assert!(box_can_be_released(_v5, p3), 2000002);
        let _v6 = package_manager::get_signer();
        let _v7 = signer::address_of(p0);
        let _v8 = borrow_global_mut<Fridge>(_v7);
        let _v9 = package_manager::get_resource_address();
        let _v10 = borrow_global_mut<FridgeConfig>(_v9);
        let _v11 = 0;
        let _v12 = 0;
        let Box{pool_id: _v13, position_id: _v14, release_timestamp: _v15, token_a_store: _v16, token_a_store_delete_ref: _v17, token_b_store: _v18, token_b_store_delete_ref: _v19, token_a_metadata: _v20, token_b_metadata: _v21, token_a_fee_store: _v22, token_b_fee_store: _v23, rewards: _v24} = smart_table::remove<address, Box>(&mut _v8.boxes, p3);
        let _v25 = _v19;
        let _v26 = _v18;
        let _v27 = _v17;
        let _v28 = _v16;
        if (option::is_some<object::Object<fungible_asset::FungibleStore>>(&_v28)) {
            _v4 = option::extract<object::Object<fungible_asset::FungibleStore>>(&mut _v28);
            let _v29 = fungible_asset::store_metadata<fungible_asset::FungibleStore>(_v4);
            _v3 = object::object_address<fungible_asset::Metadata>(&_v29);
            _v2 = dispatchable_fungible_asset::derived_balance<fungible_asset::FungibleStore>(_v4);
            _v11 = _v2;
            _v1 = smart_table::borrow_mut<address, u64>(&mut _v10.asset_num_track, _v3);
            *_v1 = *_v1 - _v2;
            _v0 = dispatchable_fungible_asset::withdraw<fungible_asset::FungibleStore>(&_v6, _v4, _v2);
            primary_fungible_store::deposit(_v5, _v0);
            let _v30 = option::extract<object::DeleteRef>(&mut _v27);
            fungible_asset::remove_store(&_v30)
        };
        if (option::is_some<object::Object<fungible_asset::FungibleStore>>(&_v26)) {
            _v4 = option::extract<object::Object<fungible_asset::FungibleStore>>(&mut _v26);
            let _v31 = fungible_asset::store_metadata<fungible_asset::FungibleStore>(_v4);
            _v3 = object::object_address<fungible_asset::Metadata>(&_v31);
            _v2 = dispatchable_fungible_asset::derived_balance<fungible_asset::FungibleStore>(_v4);
            _v12 = _v2;
            _v1 = smart_table::borrow_mut<address, u64>(&mut _v10.asset_num_track, _v3);
            *_v1 = *_v1 - _v2;
            _v0 = dispatchable_fungible_asset::withdraw<fungible_asset::FungibleStore>(&_v6, _v4, _v2);
            primary_fungible_store::deposit(_v5, _v0);
            let _v32 = option::extract<object::DeleteRef>(&mut _v25);
            fungible_asset::remove_store(&_v32)
        };
        option::destroy_none<object::Object<fungible_asset::FungibleStore>>(_v28);
        option::destroy_none<object::Object<fungible_asset::FungibleStore>>(_v26);
        option::destroy_none<object::DeleteRef>(_v27);
        option::destroy_none<object::DeleteRef>(_v25);
        event::emit<BoxClaimedEvent>(BoxClaimedEvent{box_id: p3, user: _v5, pool_id: _v13, position_id: _v14, token_a_metadata: _v20, token_a_amount: _v11, token_b_metadata: _v21, token_b_amount: _v12});
    }
    entry fun claim_fridge_box_all_by_admin(p0: &signer, p1: address, p2: address)
        acquires Fridge, FridgeConfig
    {
        let _v0;
        let _v1;
        let _v2 = string::utf8(vector[99u8, 108u8, 97u8, 105u8, 109u8, 95u8, 102u8, 114u8, 105u8, 100u8, 103u8, 101u8, 95u8, 98u8, 111u8, 120u8, 95u8, 98u8, 121u8, 95u8, 97u8, 100u8, 109u8, 105u8, 110u8]);
        package_manager::assert_admin(p0, _v2);
        let _v3 = borrow_global_mut<Fridge>(p1);
        let _v4 = vector::empty<address>();
        let _v5 = &_v3.boxes;
        let _v6 = 0;
        let _v7 = false;
        let _v8 = smart_table::num_buckets<address, Box>(_v5);
        loop {
            if (_v7) _v6 = _v6 + 1 else _v7 = true;
            if (!(_v6 < _v8)) break;
            let _v9 = table_with_length::borrow<u64, vector<smart_table::Entry<address, Box>>>(smart_table::borrow_buckets<address, Box>(_v5), _v6);
            _v1 = 0;
            _v0 = vector::length<smart_table::Entry<address, Box>>(_v9);
            while (_v1 < _v0) {
                let (_v10,_v11) = smart_table::borrow_kv<address, Box>(vector::borrow<smart_table::Entry<address, Box>>(_v9, _v1));
                let _v12 = &mut _v4;
                let _v13 = *_v10;
                vector::push_back<address>(_v12, _v13);
                _v1 = _v1 + 1;
                continue
            };
            continue
        };
        _v1 = smart_table::length<address, Box>(&_v3.boxes);
        _v0 = 0;
        let _v14 = package_manager::get_resource_address();
        let _v15 = borrow_global_mut<FridgeConfig>(_v14);
        let _v16 = package_manager::get_signer();
        loop {
            let _v17;
            let _v18;
            let _v19;
            let _v20;
            let _v21;
            let _v22;
            if (!(_v0 < _v1)) break;
            let _v23 = vector::pop_back<address>(&mut _v4);
            let Box{pool_id: _v24, position_id: _v25, release_timestamp: _v26, token_a_store: _v27, token_a_store_delete_ref: _v28, token_b_store: _v29, token_b_store_delete_ref: _v30, token_a_metadata: _v31, token_b_metadata: _v32, token_a_fee_store: _v33, token_b_fee_store: _v34, rewards: _v35} = smart_table::remove<address, Box>(&mut _v3.boxes, _v23);
            let _v36 = _v30;
            let _v37 = _v29;
            let _v38 = _v28;
            let _v39 = _v27;
            if (option::is_some<object::Object<fungible_asset::FungibleStore>>(&_v39)) {
                _v22 = option::extract<object::Object<fungible_asset::FungibleStore>>(&mut _v39);
                _v21 = dispatchable_fungible_asset::derived_balance<fungible_asset::FungibleStore>(_v22);
                let _v40 = fungible_asset::store_metadata<fungible_asset::FungibleStore>(_v22);
                _v20 = object::object_address<fungible_asset::Metadata>(&_v40);
                _v19 = _v21;
                _v18 = smart_table::borrow_mut<address, u64>(&mut _v15.asset_num_track, _v20);
                *_v18 = *_v18 - _v19;
                _v17 = dispatchable_fungible_asset::withdraw<fungible_asset::FungibleStore>(&_v16, _v22, _v21);
                primary_fungible_store::deposit(p2, _v17);
                let _v41 = option::extract<object::DeleteRef>(&mut _v38);
                fungible_asset::remove_store(&_v41)
            };
            if (option::is_some<object::Object<fungible_asset::FungibleStore>>(&_v37)) {
                _v22 = option::extract<object::Object<fungible_asset::FungibleStore>>(&mut _v37);
                _v21 = dispatchable_fungible_asset::derived_balance<fungible_asset::FungibleStore>(_v22);
                let _v42 = fungible_asset::store_metadata<fungible_asset::FungibleStore>(_v22);
                _v20 = object::object_address<fungible_asset::Metadata>(&_v42);
                _v19 = _v21;
                _v18 = smart_table::borrow_mut<address, u64>(&mut _v15.asset_num_track, _v20);
                *_v18 = *_v18 - _v19;
                _v17 = dispatchable_fungible_asset::withdraw<fungible_asset::FungibleStore>(&_v16, _v22, _v21);
                primary_fungible_store::deposit(p2, _v17);
                let _v43 = option::extract<object::DeleteRef>(&mut _v36);
                fungible_asset::remove_store(&_v43)
            };
            option::destroy_none<object::Object<fungible_asset::FungibleStore>>(_v39);
            option::destroy_none<object::Object<fungible_asset::FungibleStore>>(_v37);
            option::destroy_none<object::DeleteRef>(_v38);
            option::destroy_none<object::DeleteRef>(_v36);
            _v20 = signer::address_of(p0);
            event::emit<FridgeBoxClaimedByAdminEvent>(FridgeBoxClaimedByAdminEvent{box_id: _v23, admin: _v20, user: p1, receiver: p2});
            _v0 = _v0 + 1;
            continue
        };
    }
    entry fun claim_fridge_box_single_by_admin(p0: &signer, p1: address, p2: address, p3: address)
        acquires Fridge, FridgeConfig
    {
        let _v0;
        let _v1;
        let _v2;
        let _v3;
        let _v4;
        let _v5 = string::utf8(vector[99u8, 108u8, 97u8, 105u8, 109u8, 95u8, 102u8, 114u8, 105u8, 100u8, 103u8, 101u8, 95u8, 98u8, 111u8, 120u8, 95u8, 98u8, 121u8, 95u8, 97u8, 100u8, 109u8, 105u8, 110u8]);
        package_manager::assert_admin(p0, _v5);
        let _v6 = borrow_global_mut<Fridge>(p1);
        let _v7 = package_manager::get_resource_address();
        let _v8 = borrow_global_mut<FridgeConfig>(_v7);
        let Box{pool_id: _v9, position_id: _v10, release_timestamp: _v11, token_a_store: _v12, token_a_store_delete_ref: _v13, token_b_store: _v14, token_b_store_delete_ref: _v15, token_a_metadata: _v16, token_b_metadata: _v17, token_a_fee_store: _v18, token_b_fee_store: _v19, rewards: _v20} = smart_table::remove<address, Box>(&mut _v6.boxes, p2);
        let _v21 = _v15;
        let _v22 = _v14;
        let _v23 = _v13;
        let _v24 = _v12;
        let _v25 = package_manager::get_signer();
        if (option::is_some<object::Object<fungible_asset::FungibleStore>>(&_v24)) {
            _v3 = option::extract<object::Object<fungible_asset::FungibleStore>>(&mut _v24);
            _v2 = dispatchable_fungible_asset::derived_balance<fungible_asset::FungibleStore>(_v3);
            let _v26 = fungible_asset::store_metadata<fungible_asset::FungibleStore>(_v3);
            _v4 = object::object_address<fungible_asset::Metadata>(&_v26);
            _v1 = smart_table::borrow_mut<address, u64>(&mut _v8.asset_num_track, _v4);
            *_v1 = *_v1 - _v2;
            _v0 = dispatchable_fungible_asset::withdraw<fungible_asset::FungibleStore>(&_v25, _v3, _v2);
            primary_fungible_store::deposit(p3, _v0);
            let _v27 = option::extract<object::DeleteRef>(&mut _v23);
            fungible_asset::remove_store(&_v27)
        };
        if (option::is_some<object::Object<fungible_asset::FungibleStore>>(&_v22)) {
            _v3 = option::extract<object::Object<fungible_asset::FungibleStore>>(&mut _v22);
            _v2 = dispatchable_fungible_asset::derived_balance<fungible_asset::FungibleStore>(_v3);
            let _v28 = fungible_asset::store_metadata<fungible_asset::FungibleStore>(_v3);
            _v4 = object::object_address<fungible_asset::Metadata>(&_v28);
            _v1 = smart_table::borrow_mut<address, u64>(&mut _v8.asset_num_track, _v4);
            *_v1 = *_v1 - _v2;
            _v0 = dispatchable_fungible_asset::withdraw<fungible_asset::FungibleStore>(&_v25, _v3, _v2);
            primary_fungible_store::deposit(p3, _v0);
            let _v29 = option::extract<object::DeleteRef>(&mut _v21);
            fungible_asset::remove_store(&_v29)
        };
        option::destroy_none<object::Object<fungible_asset::FungibleStore>>(_v24);
        option::destroy_none<object::Object<fungible_asset::FungibleStore>>(_v22);
        option::destroy_none<object::DeleteRef>(_v23);
        option::destroy_none<object::DeleteRef>(_v21);
        _v4 = signer::address_of(p0);
        event::emit<FridgeBoxClaimedByAdminEvent>(FridgeBoxClaimedByAdminEvent{box_id: p2, admin: _v4, user: p1, receiver: p3});
    }
    fun generate_box_id(p0: address): address {
        let _v0 = timestamp::now_seconds();
        let _v1 = bcs::to_bytes<address>(&p0);
        let _v2 = &mut _v1;
        let _v3 = bcs::to_bytes<u64>(&_v0);
        vector::append<u8>(_v2, _v3);
        let _v4 = package_manager::get_resource_address();
        object::create_object_address(&_v4, _v1)
    }
    friend fun set_box(p0: &signer, p1: address, p2: address, p3: option::Option<fungible_asset::FungibleAsset>, p4: option::Option<fungible_asset::FungibleAsset>, p5: object::Object<fungible_asset::Metadata>, p6: object::Object<fungible_asset::Metadata>)
        acquires Fridge, FridgeConfig
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
        let _v10;
        let _v11;
        let _v12;
        let _v13;
        let _v14 = signer::address_of(p0);
        if (!exists<Fridge>(_v14)) {
            _v13 = p0;
            let _v15 = Fridge{boxes: smart_table::new<address, Box>()};
            move_to<Fridge>(_v13, _v15)
        };
        let _v16 = borrow_global_mut<Fridge>(_v14);
        let _v17 = package_manager::get_resource_address();
        let _v18 = borrow_global_mut<FridgeConfig>(_v17);
        let _v19 = timestamp::now_seconds();
        let _v20 = package_manager::get_signer();
        let _v21 = _v18;
        let _v22 = &p3;
        if (option::is_some<fungible_asset::FungibleAsset>(_v22)) {
            _v12 = option::borrow<fungible_asset::FungibleAsset>(_v22);
            _v11 = fungible_asset::amount(_v12);
            let _v23 = fungible_asset::metadata_from_asset(_v12);
            _v10 = object::object_address<fungible_asset::Metadata>(&_v23);
            if (!smart_table::contains<address, u64>(&_v21.asset_num_track, _v10)) smart_table::add<address, u64>(&mut _v21.asset_num_track, _v10, 0);
            _v9 = smart_table::borrow_mut<address, u64>(&mut _v21.asset_num_track, _v10);
            *_v9 = *_v9 + _v11
        } else _v11 = 0;
        let _v24 = _v18;
        let _v25 = &p4;
        if (option::is_some<fungible_asset::FungibleAsset>(_v25)) {
            _v12 = option::borrow<fungible_asset::FungibleAsset>(_v25);
            _v8 = fungible_asset::amount(_v12);
            let _v26 = fungible_asset::metadata_from_asset(_v12);
            _v10 = object::object_address<fungible_asset::Metadata>(&_v26);
            if (!smart_table::contains<address, u64>(&_v24.asset_num_track, _v10)) smart_table::add<address, u64>(&mut _v24.asset_num_track, _v10, 0);
            _v9 = smart_table::borrow_mut<address, u64>(&mut _v24.asset_num_track, _v10);
            *_v9 = *_v9 + _v8
        } else _v8 = 0;
        _v13 = &_v20;
        let _v27 = p3;
        if (option::is_some<fungible_asset::FungibleAsset>(&_v27)) {
            let _v28 = option::extract<fungible_asset::FungibleAsset>(&mut _v27);
            _v7 = _v13;
            _v6 = fungible_asset::metadata_from_asset(&_v28);
            let _v29 = object::create_object(signer::address_of(_v7));
            _v5 = &_v29;
            let _v30 = object::generate_delete_ref(_v5);
            _v4 = fungible_asset::create_store<fungible_asset::Metadata>(_v5, _v6);
            dispatchable_fungible_asset::deposit<fungible_asset::FungibleStore>(_v4, _v28);
            _v3 = option::some<object::Object<fungible_asset::FungibleStore>>(_v4);
            _v2 = option::some<object::DeleteRef>(_v30)
        } else {
            _v3 = option::none<object::Object<fungible_asset::FungibleStore>>();
            _v2 = option::none<object::DeleteRef>()
        };
        option::destroy_none<fungible_asset::FungibleAsset>(_v27);
        _v7 = &_v20;
        let _v31 = p4;
        if (option::is_some<fungible_asset::FungibleAsset>(&_v31)) {
            let _v32 = option::extract<fungible_asset::FungibleAsset>(&mut _v31);
            _v6 = fungible_asset::metadata_from_asset(&_v32);
            let _v33 = object::create_object(signer::address_of(_v7));
            _v5 = &_v33;
            let _v34 = object::generate_delete_ref(_v5);
            _v4 = fungible_asset::create_store<fungible_asset::Metadata>(_v5, _v6);
            dispatchable_fungible_asset::deposit<fungible_asset::FungibleStore>(_v4, _v32);
            _v1 = option::some<object::Object<fungible_asset::FungibleStore>>(_v4);
            _v0 = option::some<object::DeleteRef>(_v34)
        } else {
            _v1 = option::none<object::Object<fungible_asset::FungibleStore>>();
            _v0 = option::none<object::DeleteRef>()
        };
        option::destroy_none<fungible_asset::FungibleAsset>(_v31);
        let _v35 = *&_v18.freeze_duration;
        let _v36 = _v19 + _v35;
        _v10 = generate_box_id(p2);
        let _v37 = &mut _v16.boxes;
        let _v38 = option::none<object::Object<fungible_asset::FungibleStore>>();
        let _v39 = option::none<object::Object<fungible_asset::FungibleStore>>();
        let _v40 = vector::empty<option::Option<object::Object<fungible_asset::FungibleStore>>>();
        let _v41 = Box{pool_id: p1, position_id: p2, release_timestamp: _v36, token_a_store: _v3, token_a_store_delete_ref: _v2, token_b_store: _v1, token_b_store_delete_ref: _v0, token_a_metadata: p5, token_b_metadata: p6, token_a_fee_store: _v38, token_b_fee_store: _v39, rewards: _v40};
        smart_table::add<address, Box>(_v37, _v10, _v41);
        event::emit<BoxSettedEvent>(BoxSettedEvent{box_id: _v10, user: _v14, pool_id: p1, position_id: p2, token_a_metadata: p5, token_a_amount: _v11, token_b_metadata: p6, token_b_amount: _v8, release_timestamp: _v36});
    }
    public entry fun set_fridge_box_release_time(p0: &signer, p1: address, p2: address, p3: u64)
        acquires Fridge
    {
        let _v0 = string::utf8(vector[115u8, 101u8, 116u8, 95u8, 102u8, 114u8, 105u8, 100u8, 103u8, 101u8, 95u8, 98u8, 111u8, 120u8, 95u8, 114u8, 101u8, 108u8, 101u8, 97u8, 115u8, 101u8, 95u8, 116u8, 105u8, 109u8, 101u8]);
        package_manager::assert_admin(p0, _v0);
        let _v1 = smart_table::borrow_mut<address, Box>(&mut borrow_global_mut<Fridge>(p1).boxes, p2);
        let _v2 = timestamp::now_seconds();
        let _v3 = _v2 + p3;
        let _v4 = &mut _v1.release_timestamp;
        *_v4 = _v3;
        let _v5 = signer::address_of(p0);
        let _v6 = _v2 + p3;
        event::emit<FridgeBoxReleaseTimeUpdatedEvent>(FridgeBoxReleaseTimeUpdatedEvent{box_id: p2, admin: _v5, user: p1, new_release_time: _v6});
    }
    entry fun set_fridge_box_release_time_batch(p0: &signer, p1: vector<address>, p2: vector<address>, p3: u64)
        acquires Fridge
    {
        let _v0 = vector::length<address>(&p1);
        let _v1 = vector::length<address>(&p2);
        assert!(_v0 == _v1, 2000003);
        let _v2 = 0;
        while (_v2 < _v0) {
            let _v3 = *vector::borrow<address>(&p1, _v2);
            let _v4 = *vector::borrow<address>(&p2, _v2);
            set_fridge_box_release_time(p0, _v3, _v4, p3);
            _v2 = _v2 + 1;
            continue
        };
    }
    entry fun update_freeze_duration(p0: &signer, p1: u64)
        acquires FridgeConfig
    {
        let _v0 = string::utf8(vector[117u8, 112u8, 100u8, 97u8, 116u8, 101u8, 95u8, 102u8, 114u8, 101u8, 101u8, 122u8, 101u8, 95u8, 100u8, 117u8, 114u8, 97u8, 116u8, 105u8, 111u8, 110u8]);
        package_manager::assert_admin(p0, _v0);
        let _v1 = package_manager::get_resource_address();
        let _v2 = &mut borrow_global_mut<FridgeConfig>(_v1).freeze_duration;
        *_v2 = p1;
    }
    public fun user_boxes(p0: address): vector<UserBox>
        acquires Fridge
    {
        let _v0 = borrow_global<Fridge>(p0);
        let _v1 = vector::empty<UserBox>();
        let _v2 = &_v0.boxes;
        let _v3 = 0;
        let _v4 = false;
        let _v5 = smart_table::num_buckets<address, Box>(_v2);
        loop {
            if (_v4) _v3 = _v3 + 1 else _v4 = true;
            if (!(_v3 < _v5)) break;
            let _v6 = table_with_length::borrow<u64, vector<smart_table::Entry<address, Box>>>(smart_table::borrow_buckets<address, Box>(_v2), _v3);
            let _v7 = 0;
            let _v8 = vector::length<smart_table::Entry<address, Box>>(_v6);
            loop {
                let _v9;
                let _v10;
                if (!(_v7 < _v8)) break;
                let (_v11,_v12) = smart_table::borrow_kv<address, Box>(vector::borrow<smart_table::Entry<address, Box>>(_v6, _v7));
                let _v13 = _v12;
                if (option::is_some<object::Object<fungible_asset::FungibleStore>>(&_v13.token_a_store)) _v10 = dispatchable_fungible_asset::derived_balance<fungible_asset::FungibleStore>(*option::borrow<object::Object<fungible_asset::FungibleStore>>(&_v13.token_a_store)) else _v10 = 0;
                if (option::is_some<object::Object<fungible_asset::FungibleStore>>(&_v13.token_b_store)) _v9 = dispatchable_fungible_asset::derived_balance<fungible_asset::FungibleStore>(*option::borrow<object::Object<fungible_asset::FungibleStore>>(&_v13.token_b_store)) else _v9 = 0;
                let _v14 = &mut _v1;
                let _v15 = *_v11;
                let _v16 = *&_v13.release_timestamp;
                let _v17 = *&_v13.token_a_metadata;
                let _v18 = *&_v13.token_b_metadata;
                let _v19 = *&_v13.position_id;
                let _v20 = *&_v13.pool_id;
                let _v21 = UserBox{box_id: _v15, release_timestamp: _v16, token_a_metadata: _v17, token_b_metadata: _v18, token_a_amount: _v10, token_b_amount: _v9, position_id: _v19, pool_id: _v20};
                vector::push_back<UserBox>(_v14, _v21);
                _v7 = _v7 + 1;
                continue
            };
            continue
        };
        _v1
    }
}
