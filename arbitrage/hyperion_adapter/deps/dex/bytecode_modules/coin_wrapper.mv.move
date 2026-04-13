module 0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c::coin_wrapper {
    use 0x1::fungible_asset;
    use 0x1::coin;
    use 0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c::package_manager;
    use 0x1::object;
    use 0x1::primary_fungible_store;
    use 0x1::string;
    use 0x1::string_utils;
    use 0x1::option;
    use 0x1::type_info;
    use 0x1::bcs;
    public fun unwrap<T0>(p0: fungible_asset::FungibleAsset): coin::Coin<T0> {
        let _v0 = object::create_object(package_manager::get_resource_address());
        let _v1 = &_v0;
        let _v2 = object::generate_signer(_v1);
        let _v3 = &_v2;
        let _v4 = object::generate_delete_ref(_v1);
        let _v5 = fungible_asset::amount(&p0);
        primary_fungible_store::deposit(object::address_from_constructor_ref(_v1), p0);
        let _v6 = coin::withdraw<T0>(_v3, _v5);
        object::delete(_v4);
        _v6
    }
    public fun format_fungible_asset(p0: object::Object<fungible_asset::Metadata>): string::String {
        let _v0 = object::object_address<fungible_asset::Metadata>(&p0);
        let _v1 = string_utils::to_string<address>(&_v0);
        let _v2 = &_v1;
        let _v3 = string::length(&_v1);
        string::sub_string(_v2, 1, _v3)
    }
    public fun get_coin_type(p0: object::Object<fungible_asset::Metadata>): string::String {
        let _v0 = coin::paired_coin(p0);
        let _v1 = option::extract<type_info::TypeInfo>(&mut _v0);
        let _v2 = type_info::account_address(&_v1);
        let _v3 = bcs::to_bytes<address>(&_v2);
        let _v4 = string::utf8(type_info::module_name(&_v1));
        let _v5 = string::utf8(type_info::struct_name(&_v1));
        let _v6 = vector[123u8, 125u8, 58u8, 58u8];
        let _v7 = string_utils::format1<vector<u8>>(&_v6, _v3);
        string::append(&mut _v7, _v4);
        string::append_utf8(&mut _v7, vector[58u8, 58u8]);
        string::append(&mut _v7, _v5);
        _v7
    }
    public fun get_original(p0: object::Object<fungible_asset::Metadata>): string::String {
        if (is_wrapper(p0)) return get_coin_type(p0);
        format_fungible_asset(p0)
    }
    public fun is_wrapper(p0: object::Object<fungible_asset::Metadata>): bool {
        let _v0 = coin::paired_coin(p0);
        option::is_some<type_info::TypeInfo>(&_v0)
    }
    public fun get_wrapper<T0>(): object::Object<fungible_asset::Metadata> {
        let _v0 = coin::paired_metadata<T0>();
        if (option::is_none<object::Object<fungible_asset::Metadata>>(&_v0)) fungible_asset::destroy_zero(coin::coin_to_fungible_asset<T0>(coin::zero<T0>()));
        let _v1 = coin::paired_metadata<T0>();
        option::extract<object::Object<fungible_asset::Metadata>>(&mut _v1)
    }
    public fun is_supported<T0>(): bool {
        let _v0 = coin::paired_metadata<T0>();
        option::is_some<object::Object<fungible_asset::Metadata>>(&_v0)
    }
    public fun wrap<T0>(p0: coin::Coin<T0>): fungible_asset::FungibleAsset {
        coin::coin_to_fungible_asset<T0>(p0)
    }
}
