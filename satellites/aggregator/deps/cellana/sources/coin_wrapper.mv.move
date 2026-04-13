module 0x4bf51972879e3b95c4781a5cdcb9e1ee24ef483e7d22f2d903626f126df62bd1::coin_wrapper {
    use 0x1::account;
    use 0x1::aptos_account;
    use 0x1::coin;
    use 0x1::fungible_asset;
    use 0x1::object;
    use 0x1::option;
    use 0x1::primary_fungible_store;
    use 0x1::signer;
    use 0x1::smart_table;
    use 0x1::string;
    use 0x1::string_utils;
    use 0x1::type_info;
    use 0x4bf51972879e3b95c4781a5cdcb9e1ee24ef483e7d22f2d903626f126df62bd1::package_manager;
    friend 0x4bf51972879e3b95c4781a5cdcb9e1ee24ef483e7d22f2d903626f126df62bd1::router;
    friend 0x4bf51972879e3b95c4781a5cdcb9e1ee24ef483e7d22f2d903626f126df62bd1::vote_manager;
    struct FungibleAssetData has store {
        metadata: object::Object<fungible_asset::Metadata>,
        burn_ref: fungible_asset::BurnRef,
        mint_ref: fungible_asset::MintRef,
        transfer_ref: fungible_asset::TransferRef,
    }
    struct WrapperAccount has key {
        signer_cap: account::SignerCapability,
        coin_to_fungible_asset: smart_table::SmartTable<string::String, FungibleAssetData>,
        fungible_asset_to_coin: smart_table::SmartTable<object::Object<fungible_asset::Metadata>, string::String>,
    }
    friend fun create_fungible_asset<T0>(): object::Object<fungible_asset::Metadata>
        acquires WrapperAccount
    {
        let _v0 = wrapper_address();
        let _v1 = account::create_signer_with_capability(&borrow_global<WrapperAccount>(_v0).signer_cap);
        let _v2 = &_v1;
        let _v3 = format_coin<T0>();
        let _v4 = wrapper_address();
        let _v5 = borrow_global_mut<WrapperAccount>(_v4);
        let _v6 = &mut _v5.coin_to_fungible_asset;
        if (!smart_table::contains<string::String, FungibleAssetData>(freeze(_v6), _v3)) {
            let _v7 = *string::bytes(&_v3);
            let _v8 = object::create_named_object(_v2, _v7);
            let _v9 = &_v8;
            let _v10 = option::none<u128>();
            let _v11 = coin::name<T0>();
            let _v12 = coin::symbol<T0>();
            let _v13 = coin::decimals<T0>();
            let _v14 = string::utf8(vector[]);
            let _v15 = string::utf8(vector[]);
            primary_fungible_store::create_primary_store_enabled_fungible_asset(_v9, _v10, _v11, _v12, _v13, _v14, _v15);
            let _v16 = fungible_asset::generate_mint_ref(_v9);
            let _v17 = fungible_asset::generate_burn_ref(_v9);
            let _v18 = fungible_asset::generate_transfer_ref(_v9);
            let _v19 = object::object_from_constructor_ref<fungible_asset::Metadata>(_v9);
            let _v20 = FungibleAssetData{metadata: _v19, burn_ref: _v17, mint_ref: _v16, transfer_ref: _v18};
            smart_table::add<string::String, FungibleAssetData>(_v6, _v3, _v20);
            smart_table::add<object::Object<fungible_asset::Metadata>, string::String>(&mut _v5.fungible_asset_to_coin, _v19, _v3)
        };
        *&smart_table::borrow<string::String, FungibleAssetData>(freeze(_v6), _v3).metadata
    }
    public fun format_coin<T0>(): string::String {
        type_info::type_name<T0>()
    }
    public fun format_fungible_asset(p0: object::Object<fungible_asset::Metadata>): string::String {
        let _v0 = object::object_address<fungible_asset::Metadata>(&p0);
        let _v1 = string_utils::to_string<address>(&_v0);
        let _v2 = &_v1;
        let _v3 = string::length(&_v1);
        string::sub_string(_v2, 1, _v3)
    }
    public fun get_coin_type(p0: object::Object<fungible_asset::Metadata>): string::String
        acquires WrapperAccount
    {
        let _v0 = wrapper_address();
        *smart_table::borrow<object::Object<fungible_asset::Metadata>, string::String>(&borrow_global<WrapperAccount>(_v0).fungible_asset_to_coin, p0)
    }
    public fun get_original(p0: object::Object<fungible_asset::Metadata>): string::String
        acquires WrapperAccount
    {
        let _v0;
        if (is_wrapper(p0)) _v0 = get_coin_type(p0) else _v0 = format_fungible_asset(p0);
        _v0
    }
    public fun get_wrapper<T0>(): object::Object<fungible_asset::Metadata>
        acquires WrapperAccount
    {
        let _v0 = type_info::type_name<T0>();
        let _v1 = wrapper_address();
        *&smart_table::borrow<string::String, FungibleAssetData>(&borrow_global<WrapperAccount>(_v1).coin_to_fungible_asset, _v0).metadata
    }
    public entry fun initialize() {
        if (is_initialized()) return ();
        let _v0 = package_manager::get_signer();
        let (_v1,_v2) = account::create_resource_account(&_v0, vector[67u8, 79u8, 73u8, 78u8, 95u8, 87u8, 82u8, 65u8, 80u8, 80u8, 69u8, 82u8]);
        let _v3 = _v1;
        let _v4 = string::utf8(vector[67u8, 79u8, 73u8, 78u8, 95u8, 87u8, 82u8, 65u8, 80u8, 80u8, 69u8, 82u8]);
        let _v5 = signer::address_of(&_v3);
        package_manager::add_address(_v4, _v5);
        let _v6 = &_v3;
        let _v7 = smart_table::new<string::String, FungibleAssetData>();
        let _v8 = smart_table::new<object::Object<fungible_asset::Metadata>, string::String>();
        let _v9 = WrapperAccount{signer_cap: _v2, coin_to_fungible_asset: _v7, fungible_asset_to_coin: _v8};
        move_to<WrapperAccount>(_v6, _v9);
    }
    public fun is_initialized(): bool {
        package_manager::address_exists(string::utf8(vector[67u8, 79u8, 73u8, 78u8, 95u8, 87u8, 82u8, 65u8, 80u8, 80u8, 69u8, 82u8]))
    }
    public fun is_supported<T0>(): bool
        acquires WrapperAccount
    {
        let _v0 = type_info::type_name<T0>();
        let _v1 = wrapper_address();
        smart_table::contains<string::String, FungibleAssetData>(&borrow_global<WrapperAccount>(_v1).coin_to_fungible_asset, _v0)
    }
    public fun is_wrapper(p0: object::Object<fungible_asset::Metadata>): bool
        acquires WrapperAccount
    {
        let _v0 = wrapper_address();
        smart_table::contains<object::Object<fungible_asset::Metadata>, string::String>(&borrow_global<WrapperAccount>(_v0).fungible_asset_to_coin, p0)
    }
    friend fun unwrap<T0>(p0: fungible_asset::FungibleAsset): coin::Coin<T0>
        acquires WrapperAccount
    {
        let _v0 = fungible_asset::amount(&p0);
        let _v1 = type_info::type_name<T0>();
        let _v2 = wrapper_address();
        fungible_asset::burn(&smart_table::borrow<string::String, FungibleAssetData>(&borrow_global<WrapperAccount>(_v2).coin_to_fungible_asset, _v1).burn_ref, p0);
        let _v3 = wrapper_address();
        let _v4 = account::create_signer_with_capability(&borrow_global<WrapperAccount>(_v3).signer_cap);
        coin::withdraw<T0>(&_v4, _v0)
    }
    friend fun wrap<T0>(p0: coin::Coin<T0>): fungible_asset::FungibleAsset
        acquires WrapperAccount
    {
        let _v0 = create_fungible_asset<T0>();
        let _v1 = coin::value<T0>(&p0);
        aptos_account::deposit_coins<T0>(wrapper_address(), p0);
        let _v2 = type_info::type_name<T0>();
        let _v3 = wrapper_address();
        fungible_asset::mint(&smart_table::borrow<string::String, FungibleAssetData>(&borrow_global<WrapperAccount>(_v3).coin_to_fungible_asset, _v2).mint_ref, _v1)
    }
    public fun wrapper_address(): address {
        package_manager::get_address(string::utf8(vector[67u8, 79u8, 73u8, 78u8, 95u8, 87u8, 82u8, 65u8, 80u8, 80u8, 69u8, 82u8]))
    }
}
