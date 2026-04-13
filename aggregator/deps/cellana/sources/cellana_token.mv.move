module 0x4bf51972879e3b95c4781a5cdcb9e1ee24ef483e7d22f2d903626f126df62bd1::cellana_token {
    use 0x1::fungible_asset;
    use 0x1::object;
    use 0x1::option;
    use 0x1::primary_fungible_store;
    use 0x1::signer;
    use 0x1::string;
    use 0x4bf51972879e3b95c4781a5cdcb9e1ee24ef483e7d22f2d903626f126df62bd1::package_manager;
    friend 0x4bf51972879e3b95c4781a5cdcb9e1ee24ef483e7d22f2d903626f126df62bd1::minter;
    friend 0x4bf51972879e3b95c4781a5cdcb9e1ee24ef483e7d22f2d903626f126df62bd1::vote_manager;
    friend 0x4bf51972879e3b95c4781a5cdcb9e1ee24ef483e7d22f2d903626f126df62bd1::voting_escrow;
    struct CellanaToken has key {
        burn_ref: fungible_asset::BurnRef,
        mint_ref: fungible_asset::MintRef,
        transfer_ref: fungible_asset::TransferRef,
    }
    public fun balance(p0: address): u64 {
        let _v0 = token();
        primary_fungible_store::balance<CellanaToken>(p0, _v0)
    }
    friend fun burn(p0: fungible_asset::FungibleAsset)
        acquires CellanaToken
    {
        let _v0 = token_address();
        fungible_asset::burn(&borrow_global<CellanaToken>(_v0).burn_ref, p0);
    }
    friend fun deposit<T0: key>(p0: object::Object<T0>, p1: fungible_asset::FungibleAsset)
        acquires CellanaToken
    {
        let _v0 = token_address();
        fungible_asset::deposit_with_ref<T0>(&borrow_global<CellanaToken>(_v0).transfer_ref, p0, p1);
    }
    friend fun disable_transfer<T0: key>(p0: object::Object<T0>)
        acquires CellanaToken
    {
        let _v0 = token_address();
        fungible_asset::set_frozen_flag<T0>(&borrow_global<CellanaToken>(_v0).transfer_ref, p0, true);
    }
    public entry fun initialize() {
        if (is_initialized()) return ();
        let _v0 = package_manager::get_signer();
        let _v1 = object::create_named_object(&_v0, vector[67u8, 69u8, 76u8, 76u8, 65u8, 78u8, 65u8]);
        let _v2 = &_v1;
        let _v3 = option::none<u128>();
        let _v4 = string::utf8(vector[67u8, 69u8, 76u8, 76u8, 65u8, 78u8, 65u8]);
        let _v5 = string::utf8(vector[67u8, 69u8, 76u8, 76u8]);
        let _v6 = string::utf8(vector[67u8, 69u8, 76u8, 76u8, 65u8, 78u8, 65u8]);
        let _v7 = string::utf8(vector[104u8, 116u8, 116u8, 112u8, 115u8, 58u8, 47u8, 47u8, 99u8, 101u8, 108u8, 108u8, 97u8, 110u8, 97u8, 46u8, 102u8, 105u8, 110u8, 97u8, 110u8, 99u8, 101u8, 47u8]);
        primary_fungible_store::create_primary_store_enabled_fungible_asset(_v2, _v3, _v4, _v5, 8u8, _v6, _v7);
        let _v8 = object::generate_signer(_v2);
        let _v9 = &_v8;
        let _v10 = fungible_asset::generate_burn_ref(_v2);
        let _v11 = fungible_asset::generate_mint_ref(_v2);
        let _v12 = fungible_asset::generate_transfer_ref(_v2);
        let _v13 = CellanaToken{burn_ref: _v10, mint_ref: _v11, transfer_ref: _v12};
        move_to<CellanaToken>(_v9, _v13);
        let _v14 = string::utf8(vector[67u8, 69u8, 76u8, 76u8, 65u8, 78u8, 65u8]);
        let _v15 = signer::address_of(_v9);
        package_manager::add_address(_v14, _v15);
    }
    public fun is_initialized(): bool {
        package_manager::address_exists(string::utf8(vector[67u8, 69u8, 76u8, 76u8, 65u8, 78u8, 65u8]))
    }
    friend fun mint(p0: u64): fungible_asset::FungibleAsset
        acquires CellanaToken
    {
        let _v0 = token_address();
        fungible_asset::mint(&borrow_global<CellanaToken>(_v0).mint_ref, p0)
    }
    public fun token(): object::Object<CellanaToken> {
        object::address_to_object<CellanaToken>(token_address())
    }
    public fun token_address(): address {
        package_manager::get_address(string::utf8(vector[67u8, 69u8, 76u8, 76u8, 65u8, 78u8, 65u8]))
    }
    public fun total_supply(): u128 {
        let _v0 = fungible_asset::supply<CellanaToken>(token());
        option::get_with_default<u128>(&_v0, 0u128)
    }
    friend fun transfer<T0: key>(p0: object::Object<T0>, p1: object::Object<fungible_asset::FungibleStore>, p2: u64)
        acquires CellanaToken
    {
        let _v0 = object::convert<T0, fungible_asset::FungibleStore>(p0);
        let _v1 = token_address();
        fungible_asset::transfer_with_ref<fungible_asset::FungibleStore>(&borrow_global<CellanaToken>(_v1).transfer_ref, _v0, p1, p2);
    }
    friend fun withdraw<T0: key>(p0: object::Object<T0>, p1: u64): fungible_asset::FungibleAsset
        acquires CellanaToken
    {
        let _v0 = token_address();
        fungible_asset::withdraw_with_ref<T0>(&borrow_global<CellanaToken>(_v0).transfer_ref, p0, p1)
    }
}
