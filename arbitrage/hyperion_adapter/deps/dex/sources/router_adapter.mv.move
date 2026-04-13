module 0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c::router_adapter {
    use 0x1::table;
    use 0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c::package_manager;
    use 0x1::object;
    use 0x1::fungible_asset;
    use 0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c::coin_wrapper;
    use 0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c::pool_v3;
    use 0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c::router_v3;
    use 0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c::position_v3;
    use 0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c::lp;
    struct Version has key {
        migrated: table::Table<address, bool>,
    }
    public entry fun initialize() {
        if (is_initialized()) return ();
        let _v0 = package_manager::get_signer();
        let _v1 = &_v0;
        let _v2 = Version{migrated: table::new<address, bool>()};
        move_to<Version>(_v1, _v2);
    }
    public fun is_initialized(): bool {
        let _v0 = package_manager::get_resource_address();
        exists<Version>(_v0)
    }
    fun init_module(p0: &signer) {
        initialize();
    }
    public entry fun exact_input_asset_for_coin_entry<T0>(p0: &signer, p1: u8, p2: u64, p3: u64, p4: u128, p5: object::Object<fungible_asset::Metadata>, p6: bool, p7: address, p8: u64)
        acquires Version
    {
        let _v0 = pool_v3::liquidity_pool_address(coin_wrapper::get_wrapper<T0>(), p5, p1);
        let _v1 = package_manager::get_resource_address();
        let _v2 = borrow_global<Version>(_v1);
        if (table::contains<address, bool>(&_v2.migrated, _v0)) {
            let _v3 = *table::borrow<address, bool>(&_v2.migrated, _v0);
        };
        router_v3::exact_input_asset_for_coin_entry<T0>(p0, p1, p2, p3, p4, p5, p7, p8);
    }
    public entry fun exact_input_coin_for_asset_entry<T0>(p0: &signer, p1: u8, p2: u64, p3: u64, p4: u128, p5: object::Object<fungible_asset::Metadata>, p6: bool, p7: address, p8: u64)
        acquires Version
    {
        let _v0 = pool_v3::liquidity_pool_address(coin_wrapper::get_wrapper<T0>(), p5, p1);
        let _v1 = package_manager::get_resource_address();
        let _v2 = borrow_global<Version>(_v1);
        if (table::contains<address, bool>(&_v2.migrated, _v0)) {
            let _v3 = *table::borrow<address, bool>(&_v2.migrated, _v0);
        };
        router_v3::exact_input_coin_for_asset_entry<T0>(p0, p1, p2, p3, p4, p5, p7, p8);
    }
    public entry fun exact_input_coin_for_coin_entry<T0, T1>(p0: &signer, p1: u8, p2: u64, p3: u64, p4: u128, p5: bool, p6: address, p7: u64)
        acquires Version
    {
        let _v0 = coin_wrapper::get_wrapper<T0>();
        let _v1 = coin_wrapper::get_wrapper<T1>();
        let _v2 = pool_v3::liquidity_pool_address(_v0, _v1, p1);
        let _v3 = package_manager::get_resource_address();
        let _v4 = borrow_global<Version>(_v3);
        if (table::contains<address, bool>(&_v4.migrated, _v2)) {
            let _v5 = *table::borrow<address, bool>(&_v4.migrated, _v2);
        };
        router_v3::exact_input_coin_for_coin_entry<T0, T1>(p0, p1, p2, p3, p4, p6, p7);
    }
    public entry fun exact_input_swap_entry(p0: &signer, p1: u8, p2: u64, p3: u64, p4: u128, p5: object::Object<fungible_asset::Metadata>, p6: object::Object<fungible_asset::Metadata>, p7: bool, p8: address, p9: u64)
        acquires Version
    {
        let _v0 = pool_v3::liquidity_pool_address(p5, p6, p1);
        let _v1 = package_manager::get_resource_address();
        let _v2 = borrow_global<Version>(_v1);
        if (table::contains<address, bool>(&_v2.migrated, _v0)) {
            let _v3 = *table::borrow<address, bool>(&_v2.migrated, _v0);
        };
        router_v3::exact_input_swap_entry(p0, p1, p2, p3, p4, p5, p6, p8, p9);
    }
    public entry fun exact_output_asset_for_coin_entry<T0>(p0: &signer, p1: u8, p2: u64, p3: u64, p4: u128, p5: object::Object<fungible_asset::Metadata>, p6: bool, p7: address, p8: u64)
        acquires Version
    {
        let _v0 = pool_v3::liquidity_pool_address(coin_wrapper::get_wrapper<T0>(), p5, p1);
        let _v1 = package_manager::get_resource_address();
        let _v2 = borrow_global<Version>(_v1);
        if (table::contains<address, bool>(&_v2.migrated, _v0)) {
            let _v3 = *table::borrow<address, bool>(&_v2.migrated, _v0);
        };
        router_v3::exact_output_asset_for_coin_entry<T0>(p0, p1, p2, p3, p4, p5, p7, p8);
    }
    public entry fun exact_output_coin_for_asset_entry<T0>(p0: &signer, p1: u8, p2: u64, p3: u64, p4: u128, p5: object::Object<fungible_asset::Metadata>, p6: bool, p7: address, p8: u64)
        acquires Version
    {
        let _v0 = pool_v3::liquidity_pool_address(coin_wrapper::get_wrapper<T0>(), p5, p1);
        let _v1 = package_manager::get_resource_address();
        let _v2 = borrow_global<Version>(_v1);
        if (table::contains<address, bool>(&_v2.migrated, _v0)) {
            let _v3 = *table::borrow<address, bool>(&_v2.migrated, _v0);
        };
        router_v3::exact_output_coin_for_asset_entry<T0>(p0, p1, p2, p3, p4, p5, p7, p8);
    }
    public entry fun exact_output_coin_for_coin_entry<T0, T1>(p0: &signer, p1: u8, p2: u64, p3: u64, p4: u128, p5: bool, p6: address, p7: u64)
        acquires Version
    {
        let _v0 = coin_wrapper::get_wrapper<T0>();
        let _v1 = coin_wrapper::get_wrapper<T1>();
        let _v2 = pool_v3::liquidity_pool_address(_v0, _v1, p1);
        let _v3 = package_manager::get_resource_address();
        let _v4 = borrow_global<Version>(_v3);
        if (table::contains<address, bool>(&_v4.migrated, _v2)) {
            let _v5 = *table::borrow<address, bool>(&_v4.migrated, _v2);
        };
        router_v3::exact_output_coin_for_coin_entry<T0, T1>(p0, p1, p2, p3, p4, p6, p7);
    }
    public entry fun exact_output_swap_entry(p0: &signer, p1: u8, p2: u64, p3: u64, p4: u128, p5: object::Object<fungible_asset::Metadata>, p6: object::Object<fungible_asset::Metadata>, p7: bool, p8: address, p9: u64)
        acquires Version
    {
        let _v0 = pool_v3::liquidity_pool_address(p5, p6, p1);
        let _v1 = package_manager::get_resource_address();
        let _v2 = borrow_global<Version>(_v1);
        if (table::contains<address, bool>(&_v2.migrated, _v0)) {
            let _v3 = *table::borrow<address, bool>(&_v2.migrated, _v0);
        };
        router_v3::exact_output_swap_entry(p0, p1, p2, p3, p4, p5, p6, p8, p9);
    }
    public entry fun add_liquidity_both_coin_entry<T0, T1>(p0: &signer, p1: address, p2: u8, p3: bool, p4: u64, p5: u64, p6: u64, p7: u64, p8: u64)
        acquires Version
    {
        let _v0 = p1;
        let _v1 = package_manager::get_resource_address();
        let _v2 = borrow_global<Version>(_v1);
        if (table::contains<address, bool>(&_v2.migrated, _v0)) {
            let _v3 = *table::borrow<address, bool>(&_v2.migrated, _v0);
        };
        let _v4 = object::address_to_object<position_v3::Info>(p1);
        router_v3::add_liquidity_both_coins<T0, T1>(p0, _v4, p2, p4, p5, p6, p7, p8);
    }
    public entry fun add_liquidity_coin_entry<T0>(p0: &signer, p1: object::Object<lp::LPObjectRef>, p2: object::Object<fungible_asset::Metadata>, p3: u8, p4: bool, p5: u64, p6: u64, p7: u64, p8: u64, p9: u64)
        acquires Version
    {
        let _v0 = object::object_address<lp::LPObjectRef>(&p1);
        let _v1 = package_manager::get_resource_address();
        let _v2 = borrow_global<Version>(_v1);
        if (table::contains<address, bool>(&_v2.migrated, _v0)) {
            let _v3 = *table::borrow<address, bool>(&_v2.migrated, _v0);
        };
        let _v4 = object::convert<lp::LPObjectRef, position_v3::Info>(p1);
        router_v3::add_liquidity_coin<T0>(p0, _v4, p2, p3, p5, p6, p7, p8, p9);
    }
    public entry fun add_liquidity_entry(p0: &signer, p1: object::Object<lp::LPObjectRef>, p2: object::Object<fungible_asset::Metadata>, p3: object::Object<fungible_asset::Metadata>, p4: u8, p5: bool, p6: u64, p7: u64, p8: u64, p9: u64, p10: u64)
        acquires Version
    {
        let _v0 = pool_v3::liquidity_pool_address(p2, p3, p4);
        let _v1 = package_manager::get_resource_address();
        let _v2 = borrow_global<Version>(_v1);
        if (table::contains<address, bool>(&_v2.migrated, _v0)) {
            let _v3 = *table::borrow<address, bool>(&_v2.migrated, _v0);
        };
        let _v4 = object::convert<lp::LPObjectRef, position_v3::Info>(p1);
        router_v3::add_liquidity(p0, _v4, p2, p3, p4, p6, p7, p8, p9, p10);
    }
    public entry fun create_liquidity_both_coin_entry<T0, T1>(p0: &signer, p1: u8, p2: bool, p3: u32, p4: u32, p5: u32, p6: u64, p7: u64, p8: u64, p9: u64, p10: u64)
        acquires Version
    {
        let _v0 = coin_wrapper::get_wrapper<T0>();
        let _v1 = coin_wrapper::get_wrapper<T1>();
        let _v2 = pool_v3::liquidity_pool_address(_v0, _v1, p1);
        let _v3 = package_manager::get_resource_address();
        let _v4 = borrow_global<Version>(_v3);
        if (table::contains<address, bool>(&_v4.migrated, _v2)) {
            let _v5 = *table::borrow<address, bool>(&_v4.migrated, _v2);
        };
        router_v3::create_liquidity_both_coins<T0, T1>(p0, p1, p3, p4, p5, p6, p7, p8, p9, p10);
    }
    public entry fun create_liquidity_coin_entry<T0>(p0: &signer, p1: object::Object<fungible_asset::Metadata>, p2: u8, p3: bool, p4: u32, p5: u32, p6: u32, p7: u64, p8: u64, p9: u64, p10: u64, p11: u64)
        acquires Version
    {
        let _v0 = pool_v3::liquidity_pool_address(coin_wrapper::get_wrapper<T0>(), p1, p2);
        let _v1 = package_manager::get_resource_address();
        let _v2 = borrow_global<Version>(_v1);
        if (table::contains<address, bool>(&_v2.migrated, _v0)) {
            let _v3 = *table::borrow<address, bool>(&_v2.migrated, _v0);
        };
        router_v3::create_liquidity_coin<T0>(p0, p1, p2, p4, p5, p6, p7, p8, p9, p10, p11);
    }
    public entry fun create_liquidity_entry(p0: &signer, p1: object::Object<fungible_asset::Metadata>, p2: object::Object<fungible_asset::Metadata>, p3: u8, p4: bool, p5: u32, p6: u32, p7: u32, p8: u64, p9: u64, p10: u64, p11: u64, p12: u64)
        acquires Version
    {
        let _v0 = pool_v3::liquidity_pool_address(p1, p2, p3);
        let _v1 = package_manager::get_resource_address();
        let _v2 = borrow_global<Version>(_v1);
        if (table::contains<address, bool>(&_v2.migrated, _v0)) {
            let _v3 = *table::borrow<address, bool>(&_v2.migrated, _v0);
        };
        router_v3::create_liquidity(p0, p1, p2, p3, p5, p6, p7, p8, p9, p10, p11, p12);
    }
    public entry fun create_pool_both_coins_v2<T0, T1>(p0: u8, p1: u32, p2: bool)
        acquires Version
    {
        let _v0 = coin_wrapper::get_wrapper<T0>();
        let _v1 = coin_wrapper::get_wrapper<T1>();
        let _v2 = pool_v3::liquidity_pool_address(_v0, _v1, p0);
        let _v3 = package_manager::get_resource_address();
        let _v4 = borrow_global<Version>(_v3);
        if (table::contains<address, bool>(&_v4.migrated, _v2)) {
            let _v5 = *table::borrow<address, bool>(&_v4.migrated, _v2);
        };
        router_v3::create_pool_both_coins<T0, T1>(p0, p1);
    }
    public entry fun create_pool_coin_v2<T0>(p0: object::Object<fungible_asset::Metadata>, p1: u8, p2: u32, p3: bool)
        acquires Version
    {
        let _v0 = pool_v3::liquidity_pool_address(coin_wrapper::get_wrapper<T0>(), p0, p1);
        let _v1 = package_manager::get_resource_address();
        let _v2 = borrow_global<Version>(_v1);
        if (table::contains<address, bool>(&_v2.migrated, _v0)) {
            let _v3 = *table::borrow<address, bool>(&_v2.migrated, _v0);
        };
        router_v3::create_pool_coin<T0>(p0, p1, p2);
    }
    public entry fun create_pool_v2(p0: object::Object<fungible_asset::Metadata>, p1: object::Object<fungible_asset::Metadata>, p2: u8, p3: u32, p4: bool)
        acquires Version
    {
        let _v0 = pool_v3::liquidity_pool_address(p0, p1, p2);
        let _v1 = package_manager::get_resource_address();
        let _v2 = borrow_global<Version>(_v1);
        if (table::contains<address, bool>(&_v2.migrated, _v0)) {
            let _v3 = *table::borrow<address, bool>(&_v2.migrated, _v0);
        };
        router_v3::create_pool(p0, p1, p2, p3);
    }
    public entry fun remove_liquidity_both_coins_entry_v2<T0, T1>(p0: &signer, p1: object::Object<lp::LPObjectRef>, p2: u128, p3: u64, p4: u64, p5: address, p6: u64)
        acquires Version
    {
        let _v0 = object::object_address<lp::LPObjectRef>(&p1);
        let _v1 = package_manager::get_resource_address();
        let _v2 = borrow_global<Version>(_v1);
        if (table::contains<address, bool>(&_v2.migrated, _v0)) {
            let _v3 = *table::borrow<address, bool>(&_v2.migrated, _v0);
        };
        let _v4 = object::address_to_object<position_v3::Info>(object::object_address<lp::LPObjectRef>(&p1));
        router_v3::remove_liquidity(p0, _v4, p2, p3, p4, p5, p6);
    }
    public entry fun remove_liquidity_coin_entry_v2<T0>(p0: &signer, p1: object::Object<lp::LPObjectRef>, p2: u128, p3: u64, p4: u64, p5: address, p6: u64)
        acquires Version
    {
        let _v0 = object::object_address<lp::LPObjectRef>(&p1);
        let _v1 = package_manager::get_resource_address();
        let _v2 = borrow_global<Version>(_v1);
        if (table::contains<address, bool>(&_v2.migrated, _v0)) {
            let _v3 = *table::borrow<address, bool>(&_v2.migrated, _v0);
        };
        let _v4 = object::address_to_object<position_v3::Info>(object::object_address<lp::LPObjectRef>(&p1));
        router_v3::remove_liquidity(p0, _v4, p2, p3, p4, p5, p6);
    }
    public entry fun remove_liquidity_entry_v2(p0: &signer, p1: object::Object<lp::LPObjectRef>, p2: u128, p3: u64, p4: u64, p5: address, p6: u64)
        acquires Version
    {
        let _v0 = object::object_address<lp::LPObjectRef>(&p1);
        let _v1 = package_manager::get_resource_address();
        let _v2 = borrow_global<Version>(_v1);
        if (table::contains<address, bool>(&_v2.migrated, _v0)) {
            let _v3 = *table::borrow<address, bool>(&_v2.migrated, _v0);
        };
        let _v4 = object::address_to_object<position_v3::Info>(object::object_address<lp::LPObjectRef>(&p1));
        router_v3::remove_liquidity(p0, _v4, p2, p3, p4, p5, p6);
    }
}
