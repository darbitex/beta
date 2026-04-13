module 0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c::lp {
    use 0x1::object;
    use 0x1::fungible_asset;
    use 0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c::utils;
    use 0x1::string;
    use 0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c::package_manager;
    use 0x1::option;
    use 0x1::primary_fungible_store;
    use 0x1::bcs;
    use 0x1::vector;
    friend 0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c::pool_v3;
    struct LPObjectRef has drop, key {
        token_a: object::Object<fungible_asset::Metadata>,
        token_b: object::Object<fungible_asset::Metadata>,
        fee_tier: u8,
        lp_amount: u64,
        transfer_ref: object::TransferRef,
        delete_ref: object::DeleteRef,
        extend_ref: object::ExtendRef,
    }
    struct LPTokenRefs has store, key {
        burn_ref: fungible_asset::BurnRef,
        mint_ref: fungible_asset::MintRef,
        transfer_ref: fungible_asset::TransferRef,
        extend_ref: object::ExtendRef,
    }
    friend fun destroy(p0: &LPTokenRefs, p1: object::Object<fungible_asset::Metadata>, p2: address)
        acquires LPObjectRef
    {
        assert!(fungible_asset::balance<fungible_asset::FungibleStore>(ensure_lp_token_store<fungible_asset::Metadata>(p0, p2, p1)) == 0, 1300001);
        let LPObjectRef{token_a: _v0, token_b: _v1, fee_tier: _v2, lp_amount: _v3, transfer_ref: _v4, delete_ref: _v5, extend_ref: _v6} = move_from<LPObjectRef>(p2);
        object::delete(_v5);
    }
    fun ensure_lp_token_store<T0: key>(p0: &LPTokenRefs, p1: address, p2: object::Object<T0>): object::Object<fungible_asset::FungibleStore> {
        let _v0 = primary_fungible_store::ensure_primary_store_exists<T0>(p1, p2);
        let _v1 = primary_fungible_store::primary_store<T0>(p1, p2);
        if (!fungible_asset::is_frozen<fungible_asset::FungibleStore>(_v1)) fungible_asset::set_frozen_flag<fungible_asset::FungibleStore>(&p0.transfer_ref, _v1, true);
        _v1
    }
    friend fun burn_from(p0: &LPTokenRefs, p1: object::Object<fungible_asset::Metadata>, p2: u128, p3: address)
        acquires LPObjectRef
    {
        let _v0 = borrow_global_mut<LPObjectRef>(p3);
        let _v1 = p2 as u64;
        let _v2 = ensure_lp_token_store<fungible_asset::Metadata>(p0, p3, p1);
        fungible_asset::burn_from<fungible_asset::FungibleStore>(&p0.burn_ref, _v2, _v1);
        let _v3 = *&_v0.lp_amount - _v1;
        let _v4 = &mut _v0.lp_amount;
        *_v4 = _v3;
    }
    friend fun mint_to(p0: &LPTokenRefs, p1: object::Object<fungible_asset::Metadata>, p2: u128, p3: address)
        acquires LPObjectRef
    {
        let _v0 = borrow_global_mut<LPObjectRef>(p3);
        let _v1 = p2 as u64;
        let _v2 = ensure_lp_token_store<fungible_asset::Metadata>(p0, p3, p1);
        let _v3 = fungible_asset::mint(&p0.mint_ref, _v1);
        fungible_asset::deposit_with_ref<fungible_asset::FungibleStore>(&p0.transfer_ref, _v2, _v3);
        let _v4 = *&_v0.lp_amount + _v1;
        let _v5 = &mut _v0.lp_amount;
        *_v5 = _v4;
    }
    friend fun get_signer(p0: &LPTokenRefs): signer {
        object::generate_signer_for_extending(&p0.extend_ref)
    }
    friend fun create_lp_token(p0: object::Object<fungible_asset::Metadata>, p1: object::Object<fungible_asset::Metadata>, p2: u8): (LPTokenRefs, signer, object::Object<fungible_asset::Metadata>) {
        let _v0 = utils::lp_token_name(p0, p1);
        let _v1 = get_pool_seeds(p0, p1, p2);
        let _v2 = package_manager::get_signer();
        let _v3 = object::create_named_object(&_v2, _v1);
        let _v4 = &_v3;
        let _v5 = option::none<u128>();
        let _v6 = string::utf8(vector[76u8, 80u8]);
        let _v7 = string::utf8(vector[]);
        let _v8 = string::utf8(vector[]);
        primary_fungible_store::create_primary_store_enabled_fungible_asset(_v4, _v5, _v0, _v6, 8u8, _v7, _v8);
        let _v9 = fungible_asset::generate_burn_ref(_v4);
        let _v10 = fungible_asset::generate_mint_ref(_v4);
        let _v11 = fungible_asset::generate_transfer_ref(_v4);
        let _v12 = object::generate_extend_ref(_v4);
        let _v13 = LPTokenRefs{burn_ref: _v9, mint_ref: _v10, transfer_ref: _v11, extend_ref: _v12};
        let _v14 = object::generate_signer(_v4);
        let _v15 = object::object_from_constructor_ref<fungible_asset::Metadata>(_v4);
        (_v13, _v14, _v15)
    }
    public fun get_pool_seeds(p0: object::Object<fungible_asset::Metadata>, p1: object::Object<fungible_asset::Metadata>, p2: u8): vector<u8> {
        let _v0 = vector::empty<u8>();
        let _v1 = &mut _v0;
        let _v2 = object::object_address<fungible_asset::Metadata>(&p0);
        let _v3 = bcs::to_bytes<address>(&_v2);
        vector::append<u8>(_v1, _v3);
        let _v4 = &mut _v0;
        let _v5 = object::object_address<fungible_asset::Metadata>(&p1);
        let _v6 = bcs::to_bytes<address>(&_v5);
        vector::append<u8>(_v4, _v6);
        let _v7 = &mut _v0;
        let _v8 = bcs::to_bytes<u8>(&p2);
        vector::append<u8>(_v7, _v8);
        _v0
    }
    friend fun new_lp_object(p0: &object::ConstructorRef, p1: object::Object<fungible_asset::Metadata>, p2: object::Object<fungible_asset::Metadata>, p3: u8) {
        let _v0 = object::generate_signer(p0);
        let _v1 = &_v0;
        let _v2 = object::generate_transfer_ref(p0);
        let _v3 = object::generate_delete_ref(p0);
        let _v4 = object::generate_extend_ref(p0);
        let _v5 = LPObjectRef{token_a: p1, token_b: p2, fee_tier: p3, lp_amount: 0, transfer_ref: _v2, delete_ref: _v3, extend_ref: _v4};
        move_to<LPObjectRef>(_v1, _v5);
    }
}
