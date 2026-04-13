module 0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c::partnership {
    use 0x1::string;
    use 0x1::object;
    use 0x1::fungible_asset;
    use 0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c::pool_v3;
    use 0x5dd39b261199f6f9232b67c4662248333707328adbc750ba921a8df1599dc31f::context;
    use 0x1::bcs;
    use 0x1::option;
    use 0x1::event;
    use 0x1::coin;
    use 0x1::signer;
    use 0x1::primary_fungible_store;
    use 0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c::utils;
    use 0x1::dispatchable_fungible_asset;
    use 0x1::vector;
    use 0x1::comparator;
    use 0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c::tick_math;
    struct PartnerSwapEvent has copy, drop, store {
        pool_id: address,
        partner: string::String,
        amount_in: u64,
        token_in: object::Object<fungible_asset::Metadata>,
    }
    struct ThirdPartySwapEvent has copy, drop, store {
        pool_path: vector<address>,
        partner: string::String,
        amount_in: u64,
        token_in: object::Object<fungible_asset::Metadata>,
        token_out: object::Object<fungible_asset::Metadata>,
        third_party_fee: u64,
        third_party_receiver: address,
    }
    public fun swap(p0: object::Object<pool_v3::LiquidityPoolV3>, p1: bool, p2: bool, p3: u64, p4: fungible_asset::FungibleAsset, p5: u128, p6: string::String): (u64, fungible_asset::FungibleAsset, fungible_asset::FungibleAsset) {
        let _v0 = context::string_type();
        let _v1 = bcs::to_bytes<string::String>(&p6);
        let _v2 = context::set_data(string::utf8(vector[112u8, 97u8, 114u8, 116u8, 110u8, 101u8, 114u8, 115u8, 104u8, 105u8, 112u8]), _v0, _v1);
        let _v3 = fungible_asset::amount(&p4);
        let (_v4,_v5,_v6) = pool_v3::swap(p0, p1, p2, p3, p4, p5);
        let _v7 = _v5;
        let _v8 = object::object_address<pool_v3::LiquidityPoolV3>(&p0);
        let _v9 = fungible_asset::metadata_from_asset(&_v7);
        let _v10 = fungible_asset::amount(&_v7);
        let _v11 = _v3 - _v10;
        event::emit<PartnerSwapEvent>(PartnerSwapEvent{pool_id: _v8, partner: p6, amount_in: _v11, token_in: _v9});
        context::clear(option::destroy_some<context::Order>(_v2));
        (_v4, _v7, _v6)
    }
    fun check_third_party_fee_is_eligible(p0: u64, p1: u64): bool {
        let _v0 = p0 as u256;
        let _v1 = p1 as u256;
        let _v2 = _v0 * 30u256 / 100u256;
        _v1 <= _v2
    }
    public entry fun exact_input_asset_for_coin_entry<T0>(p0: &signer, p1: u8, p2: u64, p3: u64, p4: u128, p5: object::Object<fungible_asset::Metadata>, p6: address, p7: string::String, p8: u64) {
        let _v0 = coin::paired_metadata<T0>();
        let _v1 = option::extract<object::Object<fungible_asset::Metadata>>(&mut _v0);
        exact_input_swap_entry(p0, p1, p2, p3, p4, p5, _v1, p6, p7, p8);
    }
    public entry fun exact_input_swap_entry(p0: &signer, p1: u8, p2: u64, p3: u64, p4: u128, p5: object::Object<fungible_asset::Metadata>, p6: object::Object<fungible_asset::Metadata>, p7: address, p8: string::String, p9: u64) {
        let _v0 = pool_v3::liquidity_pool(p5, p6, p1);
        let _v1 = utils::is_sorted(p5, p6);
        if (!_v1) ();
        let _v2 = primary_fungible_store::primary_store<fungible_asset::Metadata>(signer::address_of(p0), p5);
        let _v3 = dispatchable_fungible_asset::withdraw<fungible_asset::FungibleStore>(p0, _v2, p2);
        let (_v4,_v5,_v6) = swap(_v0, _v1, true, p2, _v3, p4, p8);
        let _v7 = _v6;
        assert!(fungible_asset::amount(&_v7) >= p3, 1400003);
        primary_fungible_store::deposit(p7, _v7);
        primary_fungible_store::deposit(p7, _v5);
    }
    public entry fun exact_input_coin_for_asset_entry<T0>(p0: &signer, p1: u8, p2: u64, p3: u64, p4: u128, p5: object::Object<fungible_asset::Metadata>, p6: address, p7: string::String, p8: u64) {
        let _v0 = coin::balance<T0>(signer::address_of(p0));
        let _v1 = coin::coin_to_fungible_asset<T0>(coin::withdraw<T0>(p0, _v0));
        primary_fungible_store::deposit(signer::address_of(p0), _v1);
        let _v2 = coin::paired_metadata<T0>();
        let _v3 = option::extract<object::Object<fungible_asset::Metadata>>(&mut _v2);
        exact_input_swap_entry(p0, p1, p2, p3, p4, _v3, p5, p6, p7, p8);
    }
    public entry fun exact_input_coin_for_coin_entry<T0, T1>(p0: &signer, p1: u8, p2: u64, p3: u64, p4: u128, p5: address, p6: string::String, p7: u64) {
        let _v0 = coin::balance<T0>(signer::address_of(p0));
        let _v1 = coin::coin_to_fungible_asset<T0>(coin::withdraw<T0>(p0, _v0));
        primary_fungible_store::deposit(signer::address_of(p0), _v1);
        let _v2 = coin::paired_metadata<T0>();
        let _v3 = option::extract<object::Object<fungible_asset::Metadata>>(&mut _v2);
        let _v4 = coin::paired_metadata<T1>();
        let _v5 = option::extract<object::Object<fungible_asset::Metadata>>(&mut _v4);
        exact_input_swap_entry(p0, p1, p2, p3, p4, _v3, _v5, p5, p6, p7);
    }
    public entry fun exact_output_asset_for_coin_entry<T0>(p0: &signer, p1: u8, p2: u64, p3: u64, p4: u128, p5: object::Object<fungible_asset::Metadata>, p6: address, p7: string::String, p8: u64) {
        let _v0 = coin::paired_metadata<T0>();
        let _v1 = option::extract<object::Object<fungible_asset::Metadata>>(&mut _v0);
        exact_output_swap_entry(p0, p1, p2, p3, p4, p5, _v1, p6, p7, p8);
    }
    public entry fun exact_output_swap_entry(p0: &signer, p1: u8, p2: u64, p3: u64, p4: u128, p5: object::Object<fungible_asset::Metadata>, p6: object::Object<fungible_asset::Metadata>, p7: address, p8: string::String, p9: u64) {
        let _v0 = pool_v3::liquidity_pool(p5, p6, p1);
        let _v1 = utils::is_sorted(p5, p6);
        if (!_v1) ();
        let _v2 = primary_fungible_store::primary_store<fungible_asset::Metadata>(signer::address_of(p0), p5);
        let _v3 = dispatchable_fungible_asset::withdraw<fungible_asset::FungibleStore>(p0, _v2, p2);
        let (_v4,_v5,_v6) = swap(_v0, _v1, false, p3, _v3, p4, p8);
        let _v7 = _v6;
        let _v8 = fungible_asset::amount(&_v7);
        assert!(_v4 <= p2, 1400004);
        primary_fungible_store::deposit(p7, _v7);
        primary_fungible_store::deposit(p7, _v5);
    }
    public entry fun exact_output_coin_for_asset_entry<T0>(p0: &signer, p1: u8, p2: u64, p3: u64, p4: u128, p5: object::Object<fungible_asset::Metadata>, p6: address, p7: string::String, p8: u64) {
        let _v0 = coin::balance<T0>(signer::address_of(p0));
        let _v1 = coin::coin_to_fungible_asset<T0>(coin::withdraw<T0>(p0, _v0));
        primary_fungible_store::deposit(signer::address_of(p0), _v1);
        let _v2 = coin::paired_metadata<T0>();
        let _v3 = option::extract<object::Object<fungible_asset::Metadata>>(&mut _v2);
        exact_output_swap_entry(p0, p1, p2, p3, p4, _v3, p5, p6, p7, p8);
    }
    public entry fun exact_output_coin_for_coin_entry<T0, T1>(p0: &signer, p1: u8, p2: u64, p3: u64, p4: u128, p5: address, p6: string::String, p7: u64) {
        let _v0 = coin::paired_metadata<T0>();
        let _v1 = option::extract<object::Object<fungible_asset::Metadata>>(&mut _v0);
        let _v2 = coin::paired_metadata<T1>();
        let _v3 = option::extract<object::Object<fungible_asset::Metadata>>(&mut _v2);
        exact_output_swap_entry(p0, p1, p2, p3, p4, _v1, _v3, p5, p6, p7);
    }
    public entry fun partner_swap(p0: &signer, p1: vector<address>, p2: object::Object<fungible_asset::Metadata>, p3: object::Object<fungible_asset::Metadata>, p4: u64, p5: u64, p6: string::String, p7: u64, p8: address) {
        assert!(check_third_party_fee_is_eligible(p4, p7), 1400007);
        let _v0 = primary_fungible_store::withdraw<fungible_asset::Metadata>(p0, p2, p7);
        event::emit<ThirdPartySwapEvent>(ThirdPartySwapEvent{pool_path: p1, partner: p6, amount_in: p4, token_in: p2, token_out: p3, third_party_fee: p7, third_party_receiver: p8});
        primary_fungible_store::deposit(p8, _v0);
        let _v1 = p4 - p7;
        let _v2 = signer::address_of(p0);
        swap_batch(p0, p1, p2, p3, _v1, p5, _v2, p6);
    }
    public entry fun swap_batch(p0: &signer, p1: vector<address>, p2: object::Object<fungible_asset::Metadata>, p3: object::Object<fungible_asset::Metadata>, p4: u64, p5: u64, p6: address, p7: string::String) {
        let _v0 = p2;
        let _v1 = primary_fungible_store::withdraw<fungible_asset::Metadata>(p0, p2, p4);
        let _v2 = p1;
        vector::reverse<address>(&mut _v2);
        let _v3 = _v2;
        let _v4 = vector::length<address>(&_v3);
        'l0: loop {
            loop {
                let _v5;
                let _v6;
                let _v7;
                if (!(_v4 > 0)) break 'l0;
                let _v8 = object::address_to_object<pool_v3::LiquidityPoolV3>(vector::pop_back<address>(&mut _v3));
                let _v9 = pool_v3::supported_inner_assets(_v8);
                let _v10 = *vector::borrow<object::Object<fungible_asset::Metadata>>(&_v9, 0);
                let _v11 = *vector::borrow<object::Object<fungible_asset::Metadata>>(&_v9, 1);
                let _v12 = &_v10;
                let _v13 = &_v0;
                let _v14 = comparator::compare<object::Object<fungible_asset::Metadata>>(_v12, _v13);
                if (comparator::is_equal(&_v14)) _v7 = true else {
                    let _v15 = &_v11;
                    let _v16 = &_v0;
                    let _v17 = comparator::compare<object::Object<fungible_asset::Metadata>>(_v15, _v16);
                    _v7 = comparator::is_equal(&_v17)
                };
                if (!_v7) break;
                let _v18 = &_v10;
                let _v19 = &_v0;
                let _v20 = comparator::compare<object::Object<fungible_asset::Metadata>>(_v18, _v19);
                if (comparator::is_equal(&_v20)) {
                    p2 = _v11;
                    _v6 = true
                } else {
                    p2 = _v10;
                    _v6 = false
                };
                if (_v6) _v5 = tick_math::min_sqrt_price() else _v5 = tick_math::max_sqrt_price();
                let (_v21,_v22,_v23) = swap(_v8, _v6, true, p4, _v1, _v5, p7);
                let _v24 = _v23;
                primary_fungible_store::deposit(signer::address_of(p0), _v22);
                p4 = fungible_asset::amount(&_v24);
                _v1 = _v24;
                _v0 = p2;
                _v4 = _v4 - 1;
                continue
            };
            abort 1400005
        };
        vector::destroy_empty<address>(_v3);
        let _v25 = _v1;
        let _v26 = &_v0;
        let _v27 = &p3;
        let _v28 = comparator::compare<object::Object<fungible_asset::Metadata>>(_v26, _v27);
        assert!(comparator::is_equal(&_v28), 1400002);
        assert!(fungible_asset::amount(&_v25) >= p5, 1400006);
        primary_fungible_store::deposit(p6, _v25);
    }
    public entry fun swap_batch_coin_directly_deposit_entry<T0>(p0: &signer, p1: vector<address>, p2: object::Object<fungible_asset::Metadata>, p3: object::Object<fungible_asset::Metadata>, p4: u64, p5: u64, p6: string::String) {
        let _v0 = signer::address_of(p0);
        swap_batch_coin_entry<T0>(p0, p1, p2, p3, p4, p5, _v0, p6);
    }
    public entry fun swap_batch_coin_entry<T0>(p0: &signer, p1: vector<address>, p2: object::Object<fungible_asset::Metadata>, p3: object::Object<fungible_asset::Metadata>, p4: u64, p5: u64, p6: address, p7: string::String) {
        let _v0 = coin::balance<T0>(signer::address_of(p0));
        let _v1 = coin::coin_to_fungible_asset<T0>(coin::withdraw<T0>(p0, _v0));
        primary_fungible_store::deposit(signer::address_of(p0), _v1);
        swap_batch(p0, p1, p2, p3, p4, p5, p6, p7);
    }
    public entry fun swap_batch_directly_deposit(p0: &signer, p1: vector<address>, p2: object::Object<fungible_asset::Metadata>, p3: object::Object<fungible_asset::Metadata>, p4: u64, p5: u64, p6: string::String) {
        let _v0 = signer::address_of(p0);
        swap_batch(p0, p1, p2, p3, p4, p5, _v0, p6);
    }
}
