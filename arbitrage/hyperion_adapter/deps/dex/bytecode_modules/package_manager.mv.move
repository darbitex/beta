module 0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c::package_manager {
    use 0x1::acl;
    use 0x1::smart_vector;
    use 0x1::string;
    use 0x1::account;
    use 0x1::smart_table;
    use 0x1::signer;
    use 0x1::object;
    use 0x1::event;
    friend 0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c::caas_integration;
    friend 0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c::fridge;
    friend 0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c::lp;
    friend 0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c::user_label;
    friend 0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c::position_blacklist_v2;
    friend 0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c::pool_v3;
    friend 0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c::price_hub;
    friend 0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c::rate_limiter_check;
    friend 0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c::router_adapter;
    struct AdminConfig has key {
        acl: acl::ACL,
    }
    struct AdminConfigV2 has key {
        super_admin: address,
        emergency_admin: acl::ACL,
        ordinary_admin: acl::ACL,
        op_admin: acl::ACL,
        super_admin_functions: smart_vector::SmartVector<string::String>,
        ordinary_admin_functions: smart_vector::SmartVector<string::String>,
        op_admin_functions: smart_vector::SmartVector<string::String>,
        emergency_admin_functions: smart_vector::SmartVector<string::String>,
    }
    struct AdminOperationEvent has copy, drop, store {
        admin: address,
        function: string::String,
        role: string::String,
    }
    struct PermissionConfig has key {
        signer_cap: account::SignerCapability,
        addresses: smart_table::SmartTable<string::String, address>,
    }
    public entry fun initialize(p0: &signer)
        acquires PermissionConfig
    {
        let _v0 = is_initialized();
        'l0: loop {
            loop {
                if (!_v0) {
                    assert!(signer::address_of(p0) == @0xb31e712b26fd295357355f6845e77c888298636609e93bc9b05f0f604049f434, 190003);
                    let _v1 = get_resource_address();
                    if (!exists<PermissionConfig>(_v1)) {
                        let (_v2,_v3) = account::create_resource_account(p0, vector[80u8, 65u8, 67u8, 75u8, 65u8, 71u8, 69u8, 95u8, 77u8, 65u8, 78u8, 65u8, 71u8, 69u8, 82u8]);
                        let _v4 = _v2;
                        let _v5 = &_v4;
                        let _v6 = smart_table::new<string::String, address>();
                        let _v7 = PermissionConfig{signer_cap: _v3, addresses: _v6};
                        move_to<PermissionConfig>(_v5, _v7)
                    };
                    let _v8 = get_resource_address();
                    if (!exists<AdminConfig>(_v8)) {
                        let _v9 = acl::empty();
                        acl::add(&mut _v9, @0xb31e712b26fd295357355f6845e77c888298636609e93bc9b05f0f604049f434);
                        let _v10 = get_signer();
                        let _v11 = &_v10;
                        let _v12 = AdminConfig{acl: _v9};
                        move_to<AdminConfig>(_v11, _v12)
                    };
                    let _v13 = get_resource_address();
                    if (!exists<AdminConfigV2>(_v13)) break;
                    break 'l0
                };
                return ()
            };
            let _v14 = acl::empty();
            acl::add(&mut _v14, @0x2ca474374306b35932c1390b9df747b6da555ad9b15f1557fb79a7bc97472c8);
            let _v15 = acl::empty();
            acl::add(&mut _v15, @0x6c0fffa42a28b46edcbc573905ee6ffe85362c4fee9173293488a318579304d6);
            let _v16 = acl::empty();
            acl::add(&mut _v16, @0x6957eb45bd801ae98caabeebf2f058dc0e2fdb21d8dba9769c383244198d009e);
            let _v17 = smart_vector::empty<string::String>();
            let _v18 = &mut _v17;
            let _v19 = string::utf8(vector[115u8, 101u8, 116u8, 95u8, 112u8, 114u8, 111u8, 116u8, 111u8, 99u8, 111u8, 108u8, 95u8, 102u8, 101u8, 101u8, 95u8, 114u8, 101u8, 99u8, 101u8, 105u8, 118u8, 101u8, 114u8]);
            let _v20 = string::utf8(vector[115u8, 116u8, 97u8, 114u8, 116u8, 95u8, 112u8, 114u8, 111u8, 116u8, 111u8, 99u8, 111u8, 108u8]);
            let _v21 = string::utf8(vector[117u8, 112u8, 100u8, 97u8, 116u8, 101u8, 95u8, 112u8, 114u8, 111u8, 116u8, 111u8, 99u8, 111u8, 108u8, 95u8, 102u8, 101u8, 101u8, 95u8, 114u8, 97u8, 116u8, 101u8]);
            let _v22 = string::utf8(vector[99u8, 108u8, 97u8, 105u8, 109u8, 95u8, 112u8, 114u8, 111u8, 116u8, 111u8, 99u8, 111u8, 108u8, 95u8, 102u8, 101u8, 101u8, 115u8, 95u8, 97u8, 108u8, 108u8]);
            let _v23 = 0x1::vector::empty<string::String>();
            let _v24 = &mut _v23;
            0x1::vector::push_back<string::String>(_v24, _v19);
            0x1::vector::push_back<string::String>(_v24, _v20);
            0x1::vector::push_back<string::String>(_v24, _v21);
            0x1::vector::push_back<string::String>(_v24, _v22);
            smart_vector::add_all<string::String>(_v18, _v23);
            let _v25 = smart_vector::empty<string::String>();
            let _v26 = &mut _v25;
            let _v27 = string::utf8(vector[97u8, 100u8, 100u8, 95u8, 114u8, 101u8, 119u8, 97u8, 114u8, 100u8, 101u8, 114u8]);
            let _v28 = string::utf8(vector[97u8, 100u8, 100u8, 95u8, 114u8, 101u8, 119u8, 97u8, 114u8, 100u8, 101u8, 114u8, 95u8, 99u8, 111u8, 105u8, 110u8]);
            let _v29 = string::utf8(vector[97u8, 100u8, 100u8, 95u8, 98u8, 108u8, 111u8, 99u8, 107u8, 101u8, 100u8, 95u8, 97u8, 100u8, 100u8, 114u8, 101u8, 115u8, 115u8]);
            let _v30 = string::utf8(vector[119u8, 105u8, 116u8, 104u8, 100u8, 114u8, 97u8, 119u8, 95u8, 116u8, 101u8, 109u8, 112u8, 111u8, 114u8, 97u8, 114u8, 121u8, 95u8, 99u8, 111u8, 105u8, 110u8]);
            let _v31 = string::utf8(vector[119u8, 105u8, 116u8, 104u8, 100u8, 114u8, 97u8, 119u8, 95u8, 116u8, 101u8, 109u8, 112u8, 111u8, 114u8, 97u8, 114u8, 121u8, 95u8, 116u8, 111u8, 107u8, 101u8, 110u8]);
            let _v32 = string::utf8(vector[114u8, 101u8, 109u8, 111u8, 118u8, 101u8, 95u8, 105u8, 110u8, 99u8, 101u8, 110u8, 116u8, 105u8, 118u8, 101u8]);
            let _v33 = string::utf8(vector[114u8, 101u8, 109u8, 111u8, 118u8, 101u8, 95u8, 105u8, 110u8, 99u8, 101u8, 110u8, 116u8, 105u8, 118u8, 101u8, 95u8, 116u8, 111u8, 95u8, 112u8, 97u8, 117u8, 115u8, 101u8]);
            let _v34 = string::utf8(vector[112u8, 97u8, 117u8, 115u8, 101u8, 95u8, 114u8, 101u8, 119u8, 97u8, 114u8, 100u8, 101u8, 114u8, 95u8, 109u8, 97u8, 110u8, 97u8, 103u8, 101u8, 114u8]);
            let _v35 = string::utf8(vector[114u8, 101u8, 115u8, 116u8, 97u8, 114u8, 116u8, 95u8, 114u8, 101u8, 119u8, 97u8, 114u8, 100u8, 101u8, 114u8, 95u8, 109u8, 97u8, 110u8, 97u8, 103u8, 101u8, 114u8]);
            let _v36 = string::utf8(vector[117u8, 112u8, 100u8, 97u8, 116u8, 101u8, 95u8, 101u8, 109u8, 105u8, 115u8, 115u8, 105u8, 111u8, 110u8, 115u8, 95u8, 114u8, 97u8, 116u8, 101u8, 95u8, 109u8, 97u8, 120u8]);
            let _v37 = string::utf8(vector[117u8, 112u8, 100u8, 97u8, 116u8, 101u8, 95u8, 114u8, 101u8, 99u8, 101u8, 105u8, 118u8, 101u8, 114u8]);
            let _v38 = 0x1::vector::empty<string::String>();
            let _v39 = &mut _v38;
            0x1::vector::push_back<string::String>(_v39, _v27);
            0x1::vector::push_back<string::String>(_v39, _v28);
            0x1::vector::push_back<string::String>(_v39, _v29);
            0x1::vector::push_back<string::String>(_v39, _v30);
            0x1::vector::push_back<string::String>(_v39, _v31);
            0x1::vector::push_back<string::String>(_v39, _v32);
            0x1::vector::push_back<string::String>(_v39, _v33);
            0x1::vector::push_back<string::String>(_v39, _v34);
            0x1::vector::push_back<string::String>(_v39, _v35);
            0x1::vector::push_back<string::String>(_v39, _v36);
            0x1::vector::push_back<string::String>(_v39, _v37);
            smart_vector::add_all<string::String>(_v26, _v38);
            let _v40 = smart_vector::empty<string::String>();
            let _v41 = &mut _v40;
            let _v42 = string::utf8(vector[117u8, 112u8, 100u8, 97u8, 116u8, 101u8, 95u8, 101u8, 109u8, 105u8, 115u8, 115u8, 105u8, 111u8, 110u8, 115u8, 95u8, 114u8, 97u8, 116u8, 101u8]);
            let _v43 = string::utf8(vector[97u8, 100u8, 100u8, 95u8, 105u8, 110u8, 99u8, 101u8, 110u8, 116u8, 105u8, 118u8, 101u8]);
            let _v44 = string::utf8(vector[97u8, 100u8, 100u8, 95u8, 99u8, 111u8, 105u8, 110u8, 95u8, 105u8, 110u8, 99u8, 101u8, 110u8, 116u8, 105u8, 118u8, 101u8]);
            let _v45 = string::utf8(vector[97u8, 100u8, 100u8, 95u8, 105u8, 110u8, 99u8, 101u8, 110u8, 116u8, 105u8, 118u8, 101u8, 95u8, 118u8, 50u8]);
            let _v46 = string::utf8(vector[97u8, 100u8, 100u8, 95u8, 99u8, 111u8, 105u8, 110u8, 95u8, 105u8, 110u8, 99u8, 101u8, 110u8, 116u8, 105u8, 118u8, 101u8, 95u8, 118u8, 50u8]);
            let _v47 = string::utf8(vector[97u8, 100u8, 100u8, 95u8, 98u8, 108u8, 111u8, 99u8, 107u8, 101u8, 100u8, 95u8, 112u8, 111u8, 115u8, 105u8, 116u8, 105u8, 111u8, 110u8]);
            let _v48 = 0x1::vector::empty<string::String>();
            let _v49 = &mut _v48;
            0x1::vector::push_back<string::String>(_v49, _v42);
            0x1::vector::push_back<string::String>(_v49, _v43);
            0x1::vector::push_back<string::String>(_v49, _v44);
            0x1::vector::push_back<string::String>(_v49, _v45);
            0x1::vector::push_back<string::String>(_v49, _v46);
            0x1::vector::push_back<string::String>(_v49, _v47);
            smart_vector::add_all<string::String>(_v41, _v48);
            let _v50 = smart_vector::empty<string::String>();
            let _v51 = &mut _v50;
            let _v52 = string::utf8(vector[112u8, 97u8, 117u8, 115u8, 101u8, 95u8, 112u8, 114u8, 111u8, 116u8, 111u8, 99u8, 111u8, 108u8]);
            let _v53 = 0x1::vector::empty<string::String>();
            0x1::vector::push_back<string::String>(&mut _v53, _v52);
            smart_vector::add_all<string::String>(_v51, _v53);
            let _v54 = get_signer();
            let _v55 = &_v54;
            let _v56 = AdminConfigV2{super_admin: @0xb31e712b26fd295357355f6845e77c888298636609e93bc9b05f0f604049f434, emergency_admin: _v15, ordinary_admin: _v14, op_admin: _v16, super_admin_functions: _v17, ordinary_admin_functions: _v25, op_admin_functions: _v40, emergency_admin_functions: _v50};
            move_to<AdminConfigV2>(_v55, _v56);
            return ()
        };
    }
    public fun is_initialized(): bool {
        let _v0;
        let _v1 = get_resource_address();
        if (exists<PermissionConfig>(_v1)) _v0 = exists<AdminConfig>(_v1) else _v0 = false;
        if (_v0) return exists<AdminConfigV2>(_v1);
        false
    }
    public fun get_resource_address(): address {
        let _v0 = @0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c;
        account::create_resource_address(&_v0, vector[80u8, 65u8, 67u8, 75u8, 65u8, 71u8, 69u8, 95u8, 77u8, 65u8, 78u8, 65u8, 71u8, 69u8, 82u8])
    }
    friend fun get_signer(): signer
        acquires PermissionConfig
    {
        let _v0 = get_resource_address();
        account::create_signer_with_capability(&borrow_global<PermissionConfig>(_v0).signer_cap)
    }
    public fun owner(): address {
        object::owner<object::ObjectCore>(object::address_to_object<object::ObjectCore>(@0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c))
    }
    public fun is_owner(p0: address): bool {
        object::is_owner<object::ObjectCore>(object::address_to_object<object::ObjectCore>(@0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c), p0)
    }
    public fun get_address(p0: string::String): address
        acquires PermissionConfig
    {
        let _v0 = get_resource_address();
        *smart_table::borrow<string::String, address>(&borrow_global<PermissionConfig>(_v0).addresses, p0)
    }
    fun init_module(p0: &signer)
        acquires PermissionConfig
    {
        initialize(p0);
    }
    public fun is_admin(p0: address): bool
        acquires AdminConfig
    {
        let _v0 = get_resource_address();
        acl::contains(&borrow_global<AdminConfig>(_v0).acl, p0)
    }
    friend fun add_address(p0: string::String, p1: address)
        acquires PermissionConfig
    {
        let _v0 = get_resource_address();
        smart_table::add<string::String, address>(&mut borrow_global_mut<PermissionConfig>(_v0).addresses, p0, p1);
    }
    public fun address_exists(p0: string::String): bool
        acquires PermissionConfig
    {
        let _v0 = get_resource_address();
        smart_table::contains<string::String, address>(&borrow_global<PermissionConfig>(_v0).addresses, p0)
    }
    friend fun assert_admin(p0: &signer, p1: string::String)
        acquires AdminConfigV2
    {
        let _v0;
        let _v1 = signer::address_of(p0);
        let _v2 = get_resource_address();
        let _v3 = borrow_global<AdminConfigV2>(_v2);
        let _v4 = 0x1::vector::empty<u8>();
        if (*&_v3.super_admin == _v1) {
            let _v5 = &_v3.super_admin_functions;
            let _v6 = &p1;
            assert!(smart_vector::contains<string::String>(_v5, _v6), 190004);
            _v0 = vector[115u8, 117u8, 112u8, 101u8, 114u8, 95u8, 97u8, 100u8, 109u8, 105u8, 110u8]
        } else if (acl::contains(&_v3.emergency_admin, _v1)) {
            let _v7 = &_v3.emergency_admin_functions;
            let _v8 = &p1;
            assert!(smart_vector::contains<string::String>(_v7, _v8), 190006);
            _v0 = vector[101u8, 109u8, 101u8, 114u8, 103u8, 101u8, 110u8, 99u8, 121u8, 95u8, 97u8, 100u8, 109u8, 105u8, 110u8]
        } else if (acl::contains(&_v3.ordinary_admin, _v1)) {
            let _v9 = &_v3.ordinary_admin_functions;
            let _v10 = &p1;
            assert!(smart_vector::contains<string::String>(_v9, _v10), 190005);
            _v0 = vector[111u8, 114u8, 100u8, 105u8, 110u8, 97u8, 114u8, 121u8, 95u8, 97u8, 100u8, 109u8, 105u8, 110u8]
        } else if (acl::contains(&_v3.op_admin, _v1)) {
            let _v11 = &_v3.op_admin_functions;
            let _v12 = &p1;
            if (smart_vector::contains<string::String>(_v11, _v12)) _v0 = vector[111u8, 112u8, 95u8, 97u8, 100u8, 109u8, 105u8, 110u8] else abort 190007
        } else abort 190003;
        let _v13 = string::utf8(_v0);
        event::emit<AdminOperationEvent>(AdminOperationEvent{admin: _v1, function: p1, role: _v13});
    }
    public fun check_owner(p0: address) {
        assert!(is_owner(p0), 190001);
    }
    public fun is_emergency_admin(p0: address): bool
        acquires AdminConfigV2
    {
        let _v0 = get_resource_address();
        acl::contains(&borrow_global<AdminConfigV2>(_v0).emergency_admin, p0)
    }
    public fun is_op_admin(p0: address): bool
        acquires AdminConfigV2
    {
        let _v0 = get_resource_address();
        acl::contains(&borrow_global<AdminConfigV2>(_v0).op_admin, p0)
    }
    public fun is_ordinary_admin(p0: address): bool
        acquires AdminConfigV2
    {
        if (is_super_admin(p0)) return true;
        let _v0 = get_resource_address();
        acl::contains(&borrow_global<AdminConfigV2>(_v0).ordinary_admin, p0)
    }
    public fun is_super_admin(p0: address): bool
        acquires AdminConfigV2
    {
        let _v0 = get_resource_address();
        *&borrow_global<AdminConfigV2>(_v0).super_admin == p0
    }
    entry fun remove_emergency_admin(p0: &signer, p1: address)
        acquires AdminConfigV2
    {
        let _v0;
        let _v1;
        let _v2 = signer::address_of(p0);
        if (object::is_object(@0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c)) _v1 = object::is_owner<object::ObjectCore>(object::address_to_object<object::ObjectCore>(@0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c), _v2) else _v1 = false;
        if (_v1) _v0 = true else {
            let _v3 = get_resource_address();
            _v0 = *&borrow_global<AdminConfigV2>(_v3).super_admin == _v2
        };
        assert!(_v0, 190001);
        let _v4 = get_resource_address();
        let _v5 = &mut borrow_global_mut<AdminConfigV2>(_v4).emergency_admin;
        if (acl::contains(freeze(_v5), p1)) {
            acl::remove(_v5, p1);
            return ()
        };
    }
    entry fun remove_emergency_admin_functions(p0: &signer, p1: vector<string::String>)
        acquires AdminConfigV2
    {
        let _v0;
        let _v1;
        let _v2 = signer::address_of(p0);
        if (object::is_object(@0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c)) _v1 = object::is_owner<object::ObjectCore>(object::address_to_object<object::ObjectCore>(@0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c), _v2) else _v1 = false;
        if (_v1) _v0 = true else {
            let _v3 = get_resource_address();
            _v0 = *&borrow_global<AdminConfigV2>(_v3).super_admin == _v2
        };
        assert!(_v0, 190001);
        let _v4 = get_resource_address();
        let _v5 = &mut borrow_global_mut<AdminConfigV2>(_v4).emergency_admin_functions;
        let _v6 = &p1;
        let _v7 = 0;
        let _v8 = 0x1::vector::length<string::String>(_v6);
        loop {
            let _v9;
            if (!(_v7 < _v8)) break;
            let _v10 = 0x1::vector::borrow<string::String>(_v6, _v7);
            let (_v11,_v12) = smart_vector::index_of<string::String>(freeze(_v5), _v10);
            if (_v11) _v9 = smart_vector::remove<string::String>(_v5, _v12);
            _v7 = _v7 + 1;
            continue
        };
    }
    entry fun remove_op_admin(p0: &signer, p1: address)
        acquires AdminConfigV2
    {
        let _v0;
        let _v1;
        let _v2 = signer::address_of(p0);
        if (object::is_object(@0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c)) _v1 = object::is_owner<object::ObjectCore>(object::address_to_object<object::ObjectCore>(@0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c), _v2) else _v1 = false;
        if (_v1) _v0 = true else {
            let _v3 = get_resource_address();
            _v0 = *&borrow_global<AdminConfigV2>(_v3).super_admin == _v2
        };
        assert!(_v0, 190001);
        let _v4 = get_resource_address();
        let _v5 = &mut borrow_global_mut<AdminConfigV2>(_v4).op_admin;
        if (acl::contains(freeze(_v5), p1)) {
            acl::remove(_v5, p1);
            return ()
        };
    }
    entry fun remove_op_admin_functions(p0: &signer, p1: vector<string::String>)
        acquires AdminConfigV2
    {
        let _v0;
        let _v1;
        let _v2 = signer::address_of(p0);
        if (object::is_object(@0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c)) _v1 = object::is_owner<object::ObjectCore>(object::address_to_object<object::ObjectCore>(@0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c), _v2) else _v1 = false;
        if (_v1) _v0 = true else {
            let _v3 = get_resource_address();
            _v0 = *&borrow_global<AdminConfigV2>(_v3).super_admin == _v2
        };
        assert!(_v0, 190001);
        let _v4 = get_resource_address();
        let _v5 = &mut borrow_global_mut<AdminConfigV2>(_v4).op_admin_functions;
        let _v6 = &p1;
        let _v7 = 0;
        let _v8 = 0x1::vector::length<string::String>(_v6);
        loop {
            let _v9;
            if (!(_v7 < _v8)) break;
            let _v10 = 0x1::vector::borrow<string::String>(_v6, _v7);
            let (_v11,_v12) = smart_vector::index_of<string::String>(freeze(_v5), _v10);
            if (_v11) _v9 = smart_vector::remove<string::String>(_v5, _v12);
            _v7 = _v7 + 1;
            continue
        };
    }
    entry fun remove_ordinary_admin(p0: &signer, p1: address)
        acquires AdminConfigV2
    {
        let _v0;
        let _v1;
        let _v2 = signer::address_of(p0);
        if (object::is_object(@0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c)) _v1 = object::is_owner<object::ObjectCore>(object::address_to_object<object::ObjectCore>(@0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c), _v2) else _v1 = false;
        if (_v1) _v0 = true else {
            let _v3 = get_resource_address();
            _v0 = *&borrow_global<AdminConfigV2>(_v3).super_admin == _v2
        };
        assert!(_v0, 190001);
        let _v4 = get_resource_address();
        let _v5 = &mut borrow_global_mut<AdminConfigV2>(_v4).ordinary_admin;
        if (acl::contains(freeze(_v5), p1)) {
            acl::remove(_v5, p1);
            return ()
        };
    }
    entry fun remove_ordinary_admin_functions(p0: &signer, p1: vector<string::String>)
        acquires AdminConfigV2
    {
        let _v0;
        let _v1;
        let _v2 = signer::address_of(p0);
        if (object::is_object(@0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c)) _v1 = object::is_owner<object::ObjectCore>(object::address_to_object<object::ObjectCore>(@0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c), _v2) else _v1 = false;
        if (_v1) _v0 = true else {
            let _v3 = get_resource_address();
            _v0 = *&borrow_global<AdminConfigV2>(_v3).super_admin == _v2
        };
        assert!(_v0, 190001);
        let _v4 = get_resource_address();
        let _v5 = &mut borrow_global_mut<AdminConfigV2>(_v4).ordinary_admin_functions;
        let _v6 = &p1;
        let _v7 = 0;
        let _v8 = 0x1::vector::length<string::String>(_v6);
        loop {
            let _v9;
            if (!(_v7 < _v8)) break;
            let _v10 = 0x1::vector::borrow<string::String>(_v6, _v7);
            let (_v11,_v12) = smart_vector::index_of<string::String>(freeze(_v5), _v10);
            if (_v11) _v9 = smart_vector::remove<string::String>(_v5, _v12);
            _v7 = _v7 + 1;
            continue
        };
    }
    entry fun remove_super_admin_functions(p0: &signer, p1: vector<string::String>)
        acquires AdminConfigV2
    {
        let _v0;
        let _v1;
        let _v2 = signer::address_of(p0);
        if (object::is_object(@0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c)) _v1 = object::is_owner<object::ObjectCore>(object::address_to_object<object::ObjectCore>(@0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c), _v2) else _v1 = false;
        if (_v1) _v0 = true else {
            let _v3 = get_resource_address();
            _v0 = *&borrow_global<AdminConfigV2>(_v3).super_admin == _v2
        };
        assert!(_v0, 190001);
        let _v4 = get_resource_address();
        let _v5 = &mut borrow_global_mut<AdminConfigV2>(_v4).super_admin_functions;
        let _v6 = &p1;
        let _v7 = 0;
        let _v8 = 0x1::vector::length<string::String>(_v6);
        loop {
            let _v9;
            if (!(_v7 < _v8)) break;
            let _v10 = 0x1::vector::borrow<string::String>(_v6, _v7);
            let (_v11,_v12) = smart_vector::index_of<string::String>(freeze(_v5), _v10);
            if (_v11) _v9 = smart_vector::remove<string::String>(_v5, _v12);
            _v7 = _v7 + 1;
            continue
        };
    }
    public entry fun set_admin(p0: &signer, p1: address)
        acquires AdminConfig
    {
        let _v0;
        let _v1;
        if (object::is_object(@0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c)) {
            let _v2 = object::address_to_object<object::ObjectCore>(@0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c);
            let _v3 = signer::address_of(p0);
            _v1 = object::is_owner<object::ObjectCore>(_v2, _v3)
        } else _v1 = false;
        if (_v1) _v0 = true else {
            let _v4 = get_resource_address();
            let _v5 = &borrow_global<AdminConfig>(_v4).acl;
            let _v6 = signer::address_of(p0);
            _v0 = acl::contains(_v5, _v6)
        };
        assert!(_v0, 190001);
        assert!(p1 != @0x0, 190002);
        let _v7 = get_resource_address();
        let _v8 = &mut borrow_global_mut<AdminConfig>(_v7).acl;
        let _v9 = freeze(_v8);
        let _v10 = signer::address_of(p0);
        if (acl::contains(_v9, _v10)) {
            acl::add(_v8, p1);
            return ()
        };
        acl::add(_v8, p1);
    }
    entry fun set_emergency_admin(p0: &signer, p1: address)
        acquires AdminConfigV2
    {
        let _v0;
        let _v1;
        let _v2 = signer::address_of(p0);
        if (object::is_object(@0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c)) _v1 = object::is_owner<object::ObjectCore>(object::address_to_object<object::ObjectCore>(@0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c), _v2) else _v1 = false;
        if (_v1) _v0 = true else {
            let _v3 = get_resource_address();
            _v0 = *&borrow_global<AdminConfigV2>(_v3).super_admin == _v2
        };
        assert!(_v0, 190001);
        assert!(p1 != @0x0, 190002);
        let _v4 = get_resource_address();
        let _v5 = &mut borrow_global_mut<AdminConfigV2>(_v4).emergency_admin;
        if (!acl::contains(freeze(_v5), p1)) {
            acl::add(_v5, p1);
            return ()
        };
    }
    entry fun set_emergency_admin_functions(p0: &signer, p1: vector<string::String>)
        acquires AdminConfigV2
    {
        let _v0;
        let _v1;
        let _v2 = signer::address_of(p0);
        if (object::is_object(@0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c)) _v1 = object::is_owner<object::ObjectCore>(object::address_to_object<object::ObjectCore>(@0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c), _v2) else _v1 = false;
        if (_v1) _v0 = true else {
            let _v3 = get_resource_address();
            _v0 = *&borrow_global<AdminConfigV2>(_v3).super_admin == _v2
        };
        assert!(_v0, 190001);
        let _v4 = get_resource_address();
        let _v5 = &mut borrow_global_mut<AdminConfigV2>(_v4).emergency_admin_functions;
        let _v6 = &p1;
        let _v7 = 0;
        let _v8 = 0x1::vector::length<string::String>(_v6);
        while (_v7 < _v8) {
            let _v9 = 0x1::vector::borrow<string::String>(_v6, _v7);
            if (!smart_vector::contains<string::String>(freeze(_v5), _v9)) {
                let _v10 = *_v9;
                smart_vector::push_back<string::String>(_v5, _v10)
            };
            _v7 = _v7 + 1;
            continue
        };
    }
    entry fun set_op_admin(p0: &signer, p1: address)
        acquires AdminConfigV2
    {
        let _v0;
        let _v1;
        let _v2 = signer::address_of(p0);
        if (object::is_object(@0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c)) _v1 = object::is_owner<object::ObjectCore>(object::address_to_object<object::ObjectCore>(@0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c), _v2) else _v1 = false;
        if (_v1) _v0 = true else {
            let _v3 = get_resource_address();
            _v0 = *&borrow_global<AdminConfigV2>(_v3).super_admin == _v2
        };
        assert!(_v0, 190001);
        assert!(p1 != @0x0, 190002);
        let _v4 = get_resource_address();
        let _v5 = &mut borrow_global_mut<AdminConfigV2>(_v4).op_admin;
        if (!acl::contains(freeze(_v5), p1)) {
            acl::add(_v5, p1);
            return ()
        };
    }
    entry fun set_op_admin_functions(p0: &signer, p1: vector<string::String>)
        acquires AdminConfigV2
    {
        let _v0;
        let _v1;
        let _v2 = signer::address_of(p0);
        if (object::is_object(@0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c)) _v1 = object::is_owner<object::ObjectCore>(object::address_to_object<object::ObjectCore>(@0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c), _v2) else _v1 = false;
        if (_v1) _v0 = true else {
            let _v3 = get_resource_address();
            _v0 = *&borrow_global<AdminConfigV2>(_v3).super_admin == _v2
        };
        assert!(_v0, 190001);
        let _v4 = get_resource_address();
        let _v5 = &mut borrow_global_mut<AdminConfigV2>(_v4).op_admin_functions;
        let _v6 = &p1;
        let _v7 = 0;
        let _v8 = 0x1::vector::length<string::String>(_v6);
        while (_v7 < _v8) {
            let _v9 = 0x1::vector::borrow<string::String>(_v6, _v7);
            if (!smart_vector::contains<string::String>(freeze(_v5), _v9)) {
                let _v10 = *_v9;
                smart_vector::push_back<string::String>(_v5, _v10)
            };
            _v7 = _v7 + 1;
            continue
        };
    }
    entry fun set_ordinary_admin(p0: &signer, p1: address)
        acquires AdminConfigV2
    {
        let _v0;
        let _v1;
        let _v2 = signer::address_of(p0);
        if (object::is_object(@0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c)) _v1 = object::is_owner<object::ObjectCore>(object::address_to_object<object::ObjectCore>(@0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c), _v2) else _v1 = false;
        if (_v1) _v0 = true else {
            let _v3 = get_resource_address();
            _v0 = *&borrow_global<AdminConfigV2>(_v3).super_admin == _v2
        };
        assert!(_v0, 190001);
        assert!(p1 != @0x0, 190002);
        let _v4 = get_resource_address();
        let _v5 = &mut borrow_global_mut<AdminConfigV2>(_v4).ordinary_admin;
        if (!acl::contains(freeze(_v5), p1)) {
            acl::add(_v5, p1);
            return ()
        };
    }
    entry fun set_ordinary_admin_functions(p0: &signer, p1: vector<string::String>)
        acquires AdminConfigV2
    {
        let _v0;
        let _v1;
        let _v2 = signer::address_of(p0);
        if (object::is_object(@0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c)) _v1 = object::is_owner<object::ObjectCore>(object::address_to_object<object::ObjectCore>(@0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c), _v2) else _v1 = false;
        if (_v1) _v0 = true else {
            let _v3 = get_resource_address();
            _v0 = *&borrow_global<AdminConfigV2>(_v3).super_admin == _v2
        };
        assert!(_v0, 190001);
        let _v4 = get_resource_address();
        let _v5 = &mut borrow_global_mut<AdminConfigV2>(_v4).ordinary_admin_functions;
        let _v6 = &p1;
        let _v7 = 0;
        let _v8 = 0x1::vector::length<string::String>(_v6);
        while (_v7 < _v8) {
            let _v9 = 0x1::vector::borrow<string::String>(_v6, _v7);
            if (!smart_vector::contains<string::String>(freeze(_v5), _v9)) {
                let _v10 = *_v9;
                smart_vector::push_back<string::String>(_v5, _v10)
            };
            _v7 = _v7 + 1;
            continue
        };
    }
    entry fun set_super_admin_functions(p0: &signer, p1: vector<string::String>)
        acquires AdminConfigV2
    {
        let _v0;
        let _v1;
        let _v2 = signer::address_of(p0);
        if (object::is_object(@0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c)) _v1 = object::is_owner<object::ObjectCore>(object::address_to_object<object::ObjectCore>(@0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c), _v2) else _v1 = false;
        if (_v1) _v0 = true else {
            let _v3 = get_resource_address();
            _v0 = *&borrow_global<AdminConfigV2>(_v3).super_admin == _v2
        };
        assert!(_v0, 190001);
        let _v4 = get_resource_address();
        let _v5 = &mut borrow_global_mut<AdminConfigV2>(_v4).super_admin_functions;
        let _v6 = &p1;
        let _v7 = 0;
        let _v8 = 0x1::vector::length<string::String>(_v6);
        while (_v7 < _v8) {
            let _v9 = 0x1::vector::borrow<string::String>(_v6, _v7);
            if (!smart_vector::contains<string::String>(freeze(_v5), _v9)) {
                let _v10 = *_v9;
                smart_vector::push_back<string::String>(_v5, _v10)
            };
            _v7 = _v7 + 1;
            continue
        };
    }
}
