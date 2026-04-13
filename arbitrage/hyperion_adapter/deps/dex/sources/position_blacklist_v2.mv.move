module 0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c::position_blacklist_v2 {
    use 0x1::smart_table;
    use 0x1::smart_vector;
    use 0x1::signer;
    use 0x1::string;
    use 0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c::package_manager;
    use 0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c::position_v3;
    use 0x1::object;
    use 0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c::i32;
    friend 0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c::pool_v3;
    struct PositionBlackListV2 has store, key {
        user_info: smart_table::SmartTable<address, smart_vector::SmartVector<address>>,
        position_info: smart_table::SmartTable<address, address>,
    }
    struct UserBlackList has key {
        info: smart_table::SmartTable<address, address>,
    }
    friend fun new_v2(p0: &signer) {
        let _v0 = signer::address_of(p0);
        if (!exists<PositionBlackListV2>(_v0)) {
            let _v1 = smart_table::new<address, smart_vector::SmartVector<address>>();
            let _v2 = smart_table::new<address, address>();
            let _v3 = PositionBlackListV2{user_info: _v1, position_info: _v2};
            move_to<PositionBlackListV2>(p0, _v3);
            return ()
        };
    }
    public entry fun add_blocked_address(p0: &signer, p1: address, p2: address)
        acquires UserBlackList
    {
        let _v0 = string::utf8(vector[97u8, 100u8, 100u8, 95u8, 98u8, 108u8, 111u8, 99u8, 107u8, 101u8, 100u8, 95u8, 97u8, 100u8, 100u8, 114u8, 101u8, 115u8, 115u8]);
        package_manager::assert_admin(p0, _v0);
        let _v1 = package_manager::get_resource_address();
        let _v2 = borrow_global_mut<UserBlackList>(_v1);
        if (smart_table::contains<address, address>(&_v2.info, p1)) abort 140001;
        smart_table::add<address, address>(&mut _v2.info, p1, p2);
    }
    public entry fun add_blocked_address_batch(p0: &signer, p1: vector<address>, p2: vector<address>)
        acquires UserBlackList
    {
        let _v0 = string::utf8(vector[97u8, 100u8, 100u8, 95u8, 98u8, 108u8, 111u8, 99u8, 107u8, 101u8, 100u8, 95u8, 97u8, 100u8, 100u8, 114u8, 101u8, 115u8, 115u8, 95u8, 98u8, 97u8, 116u8, 99u8, 104u8]);
        package_manager::assert_admin(p0, _v0);
        let _v1 = 0x1::vector::length<address>(&p1);
        let _v2 = 0x1::vector::length<address>(&p2);
        assert!(_v1 == _v2, 140005);
        let _v3 = 0x1::vector::length<address>(&p1);
        let _v4 = 0;
        let _v5 = false;
        loop {
            if (_v5) _v4 = _v4 + 1 else _v5 = true;
            if (!(_v4 < _v3)) break;
            let _v6 = *0x1::vector::borrow<address>(&p1, _v4);
            let _v7 = *0x1::vector::borrow<address>(&p2, _v4);
            add_blocked_address(p0, _v6, _v7);
            continue
        };
    }
    entry fun add_blocked_position(p0: &signer, p1: address, p2: address, p3: vector<address>)
        acquires PositionBlackListV2, UserBlackList
    {
        let _v0 = string::utf8(vector[97u8, 100u8, 100u8, 95u8, 98u8, 108u8, 111u8, 99u8, 107u8, 101u8, 100u8, 95u8, 112u8, 111u8, 115u8, 105u8, 116u8, 105u8, 111u8, 110u8]);
        package_manager::assert_admin(p0, _v0);
        let _v1 = 0;
        let _v2 = 0x1::vector::length<address>(&p3);
        while (_v1 < _v2) {
            let _v3 = *0x1::vector::borrow<address>(&p3, _v1);
            add_blocked_position_internal(p1, p2, _v3);
            _v1 = _v1 + 1;
            continue
        };
    }
    friend fun add_blocked_position_internal(p0: address, p1: address, p2: address)
        acquires PositionBlackListV2, UserBlackList
    {
        let _v0 = package_manager::get_resource_address();
        let _v1 = borrow_global_mut<UserBlackList>(_v0);
        let _v2 = borrow_global_mut<PositionBlackListV2>(p1);
        assert!(object::object_exists<position_v3::Info>(p2), 140006);
        assert!(smart_table::contains<address, address>(&_v1.info, p0), 140004);
        let _v3 = smart_table::borrow<address, address>(&_v1.info, p0);
        if (!smart_table::contains<address, address>(&_v2.position_info, p2)) {
            let _v4;
            if (smart_table::contains<address, smart_vector::SmartVector<address>>(&_v2.user_info, p0)) _v4 = smart_table::borrow_mut<address, smart_vector::SmartVector<address>>(&mut _v2.user_info, p0) else {
                let _v5 = &mut _v2.user_info;
                let _v6 = smart_vector::empty<address>();
                smart_table::add<address, smart_vector::SmartVector<address>>(_v5, p0, _v6);
                _v4 = smart_table::borrow_mut<address, smart_vector::SmartVector<address>>(&mut _v2.user_info, p0)
            };
            smart_vector::push_back<address>(_v4, p0);
            let _v7 = &mut _v2.position_info;
            let _v8 = *_v3;
            smart_table::add<address, address>(_v7, p2, _v8);
            return ()
        };
    }
    friend fun blocked_out_liquidity_amount(p0: address, p1: i32::I32): u128
        acquires PositionBlackListV2
    {
        let _v0 = smart_table::keys<address, address>(&borrow_global<PositionBlackListV2>(p0).position_info);
        let _v1 = 0u128;
        let _v2 = &_v0;
        let _v3 = 0;
        let _v4 = 0x1::vector::length<address>(_v2);
        loop {
            let _v5;
            if (!(_v3 < _v4)) break;
            let _v6 = 0x1::vector::borrow<address>(_v2, _v3);
            let (_v7,_v8) = position_v3::get_tick(object::address_to_object<position_v3::Info>(*_v6));
            if (i32::gte(p1, _v7)) _v5 = i32::lt(p1, _v8) else _v5 = false;
            if (_v5) {
                let _v9 = position_v3::get_liquidity(object::address_to_object<position_v3::Info>(*_v6));
                _v1 = _v1 + _v9
            };
            _v3 = _v3 + 1;
            continue
        };
        _v1
    }
    friend fun check_address_then_block_position(p0: address, p1: address, p2: address)
        acquires PositionBlackListV2, UserBlackList
    {
        let _v0 = package_manager::get_resource_address();
        let _v1 = borrow_global<UserBlackList>(_v0);
        if (smart_table::contains<address, address>(&_v1.info, p1)) {
            let _v2 = *smart_table::borrow<address, address>(&_v1.info, p1);
            let _v3 = borrow_global_mut<PositionBlackListV2>(p0);
            if (!smart_table::contains<address, smart_vector::SmartVector<address>>(&_v3.user_info, p1)) {
                let _v4 = &mut _v3.user_info;
                let _v5 = smart_vector::empty<address>();
                smart_table::add<address, smart_vector::SmartVector<address>>(_v4, p1, _v5)
            };
            let _v6 = smart_table::borrow_mut<address, smart_vector::SmartVector<address>>(&mut _v3.user_info, p1);
            assert!(smart_vector::length<address>(freeze(_v6)) < 10, 140007);
            let _v7 = freeze(_v6);
            let _v8 = &p2;
            if (!smart_vector::contains<address>(_v7, _v8)) smart_vector::push_back<address>(_v6, p2);
            if (!smart_table::contains<address, address>(&_v3.position_info, p2)) {
                smart_table::add<address, address>(&mut _v3.position_info, p2, _v2);
                return ()
            };
            return ()
        };
    }
    friend fun does_address_blocked(p0: address): bool
        acquires UserBlackList
    {
        let _v0 = package_manager::get_resource_address();
        smart_table::contains<address, address>(&borrow_global<UserBlackList>(_v0).info, p0)
    }
    friend fun does_position_blocked(p0: address, p1: address): bool
        acquires PositionBlackListV2
    {
        if (smart_table::contains<address, address>(&borrow_global<PositionBlackListV2>(p0).position_info, p1)) return true;
        false
    }
    friend fun get_position_receiver(p0: address, p1: address): address
        acquires PositionBlackListV2
    {
        *smart_table::borrow<address, address>(&borrow_global<PositionBlackListV2>(p0).position_info, p1)
    }
    entry fun init_user_blacklist(p0: &signer) {
        let _v0 = string::utf8(vector[105u8, 110u8, 105u8, 116u8, 95u8, 117u8, 115u8, 101u8, 114u8, 95u8, 98u8, 108u8, 97u8, 99u8, 107u8, 108u8, 105u8, 115u8, 116u8]);
        package_manager::assert_admin(p0, _v0);
        let _v1 = package_manager::get_signer();
        let _v2 = signer::address_of(&_v1);
        if (!exists<UserBlackList>(_v2)) {
            let _v3 = &_v1;
            let _v4 = UserBlackList{info: smart_table::new<address, address>()};
            move_to<UserBlackList>(_v3, _v4);
            return ()
        };
    }
    friend fun receiver_check(p0: address, p1: address, p2: address): bool
        acquires PositionBlackListV2
    {
        *smart_table::borrow<address, address>(&borrow_global<PositionBlackListV2>(p0).position_info, p1) == p2
    }
    friend fun remove_blocked_position(p0: address, p1: address, p2: address)
        acquires PositionBlackListV2, UserBlackList
    {
        let _v0 = package_manager::get_resource_address();
        let _v1 = borrow_global_mut<UserBlackList>(_v0);
        let _v2 = borrow_global_mut<PositionBlackListV2>(p1);
        if (smart_table::contains<address, address>(&_v1.info, p0)) {
            let _v3;
            let _v4 = smart_table::borrow_mut<address, smart_vector::SmartVector<address>>(&mut _v2.user_info, p0);
            let _v5 = freeze(_v4);
            let _v6 = &p2;
            let (_v7,_v8) = smart_vector::index_of<address>(_v5, _v6);
            if (_v7) _v3 = smart_vector::remove<address>(_v4, _v8)
        };
        if (smart_table::contains<address, address>(&_v2.position_info, p2)) {
            let _v9 = smart_table::remove<address, address>(&mut _v2.position_info, p2);
            return ()
        };
    }
    entry fun remove_blocked_position_by_admin(p0: &signer, p1: address, p2: address, p3: vector<address>)
        acquires PositionBlackListV2, UserBlackList
    {
        let _v0 = string::utf8(vector[114u8, 101u8, 109u8, 111u8, 118u8, 101u8, 95u8, 98u8, 108u8, 111u8, 99u8, 107u8, 101u8, 100u8, 95u8, 112u8, 111u8, 115u8, 105u8, 116u8, 105u8, 111u8, 110u8, 95u8, 98u8, 121u8, 95u8, 97u8, 100u8, 109u8, 105u8, 110u8]);
        package_manager::assert_admin(p0, _v0);
        let _v1 = 0;
        let _v2 = 0x1::vector::length<address>(&p3);
        while (_v1 < _v2) {
            let _v3 = *0x1::vector::borrow<address>(&p3, _v1);
            remove_blocked_position(p1, p2, _v3);
            _v1 = _v1 + 1;
            continue
        };
    }
    entry fun update_receiver(p0: &signer, p1: address, p2: address, p3: address)
        acquires PositionBlackListV2, UserBlackList
    {
        let _v0 = string::utf8(vector[117u8, 112u8, 100u8, 97u8, 116u8, 101u8, 95u8, 114u8, 101u8, 99u8, 101u8, 105u8, 118u8, 101u8, 114u8]);
        package_manager::assert_admin(p0, _v0);
        let _v1 = package_manager::get_resource_address();
        let _v2 = smart_table::borrow_mut<address, address>(&mut borrow_global_mut<UserBlackList>(_v1).info, p1);
        *_v2 = p3;
        let _v3 = borrow_global_mut<PositionBlackListV2>(p2);
        let _v4 = smart_table::borrow<address, smart_vector::SmartVector<address>>(&_v3.user_info, p1);
        let _v5 = smart_vector::length<address>(_v4);
        let _v6 = 0;
        let _v7 = false;
        loop {
            if (_v7) _v6 = _v6 + 1 else _v7 = true;
            if (!(_v6 < _v5)) break;
            let _v8 = smart_vector::borrow<address>(_v4, _v6);
            let _v9 = &mut _v3.position_info;
            let _v10 = *_v8;
            _v2 = smart_table::borrow_mut<address, address>(_v9, _v10);
            *_v2 = p3;
            continue
        };
    }
    friend fun view_list(p0: address): vector<address>
        acquires PositionBlackListV2
    {
        smart_table::keys<address, address>(&borrow_global<PositionBlackListV2>(p0).position_info)
    }
}
