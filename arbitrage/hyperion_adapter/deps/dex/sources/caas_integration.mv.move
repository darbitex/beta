module 0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c::caas_integration {
    use 0x1::string;
    use 0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c::package_manager;
    use 0x1::type_info;
    use 0x92af222254470faeda82d447067ce14b38ceafedb4c7ea462bf6b1e98cecf1f8::authorization;
    use 0x1::option;
    use 0x92af222254470faeda82d447067ce14b38ceafedb4c7ea462bf6b1e98cecf1f8::namespace;
    use 0x1::object;
    use 0x1::signer;
    use 0x92af222254470faeda82d447067ce14b38ceafedb4c7ea462bf6b1e98cecf1f8::context;
    friend 0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c::user_label;
    friend 0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c::router_v3;
    struct Witness has drop {
    }
    struct NamespaceRecord has key {
        namespace_list: vector<address>,
    }
    entry fun revoke_authorization<T0: drop>(p0: &signer) {
        let _v0 = string::utf8(vector[114u8, 101u8, 118u8, 111u8, 107u8, 101u8, 95u8, 97u8, 117u8, 116u8, 104u8, 111u8, 114u8, 105u8, 122u8, 97u8, 116u8, 105u8, 111u8, 110u8]);
        package_manager::assert_admin(p0, _v0);
        let _v1 = get_witness();
        let _v2 = type_info::type_of<T0>();
        let _v3 = type_info::account_address(&_v2);
        let _v4 = string::utf8(type_info::module_name(&_v2));
        authorization::revoke_authorization<Witness>(_v1, _v3, _v4);
    }
    friend fun get_witness(): Witness {
        Witness{}
    }
    public entry fun create_namespace(p0: &signer, p1: option::Option<address>)
        acquires NamespaceRecord
    {
        let _v0;
        let _v1 = string::utf8(vector[99u8, 114u8, 101u8, 97u8, 116u8, 101u8, 95u8, 110u8, 97u8, 109u8, 101u8, 115u8, 112u8, 97u8, 99u8, 101u8]);
        package_manager::assert_admin(p0, _v1);
        let _v2 = Witness{};
        if (option::is_some<address>(&p1)) _v0 = option::some<object::Object<namespace::NamespaceCore>>(object::address_to_object<namespace::NamespaceCore>(option::destroy_some<address>(p1))) else _v0 = option::none<object::Object<namespace::NamespaceCore>>();
        let _v3 = namespace::create_namespace<Witness>(_v2, _v0);
        let _v4 = object::object_address<namespace::NamespaceCore>(&_v3);
        let _v5 = package_manager::get_signer();
        let _v6 = signer::address_of(&_v5);
        if (!exists<NamespaceRecord>(_v6)) {
            let _v7 = &_v5;
            let _v8 = NamespaceRecord{namespace_list: 0x1::vector::empty<address>()};
            move_to<NamespaceRecord>(_v7, _v8)
        };
        let _v9 = signer::address_of(&_v5);
        0x1::vector::push_back<address>(&mut borrow_global_mut<NamespaceRecord>(_v9).namespace_list, _v4);
    }
    public entry fun create_context(p0: &signer, p1: address) {
        let _v0 = string::utf8(vector[99u8, 114u8, 101u8, 97u8, 116u8, 101u8, 95u8, 99u8, 111u8, 110u8, 116u8, 101u8, 120u8, 116u8]);
        package_manager::assert_admin(p0, _v0);
        let _v1 = object::address_to_object<namespace::NamespaceCore>(p1);
        let _v2 = Witness{};
        context::create<Witness>(_v1, _v2);
    }
    entry fun grant_authorization<T0: drop>(p0: &signer) {
        let _v0 = string::utf8(vector[103u8, 114u8, 97u8, 110u8, 116u8, 95u8, 97u8, 117u8, 116u8, 104u8, 111u8, 114u8, 105u8, 122u8, 97u8, 116u8, 105u8, 111u8, 110u8]);
        package_manager::assert_admin(p0, _v0);
        let _v1 = get_witness();
        let _v2 = type_info::type_of<Witness>();
        let _v3 = type_info::account_address(&_v2);
        let _v4 = type_info::type_of<T0>();
        let _v5 = type_info::account_address(&_v4);
        let _v6 = string::utf8(type_info::module_name(&_v4));
        authorization::grant_read_authorization<Witness>(_v1, _v3, _v5, _v5, _v6, 0, 0u8);
    }
    public fun primary_namespace_address(): address
        acquires NamespaceRecord
    {
        let _v0 = package_manager::get_resource_address();
        *0x1::vector::borrow<address>(&borrow_global<NamespaceRecord>(_v0).namespace_list, 0)
    }
    friend fun verify_authorization<T0: drop>(p0: T0) {
        let _v0 = type_info::type_of<Witness>();
        assert!(authorization::use_authorization<T0>(type_info::account_address(&_v0), p0), 2100001);
    }
}
