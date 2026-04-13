module 0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c::price_hub {
    use 0x1::option;
    use 0x1::smart_table;
    use 0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387::price_identifier;
    use 0x1::object;
    use 0x1::fungible_asset;
    use 0x1::string;
    use 0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c::package_manager;
    use 0x1::signer;
    use 0x1::math64;
    use 0x1::timestamp;
    use 0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387::pyth;
    use 0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387::price;
    use 0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387::i64;
    friend 0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c::rate_limiter_check;
    struct AggPrice has copy, drop, store {
        price: u256,
        precision: u64,
    }
    struct AggPriceConfig has copy, drop, store {
        precision: u64,
        primary_feeder: Feed,
        second_feeder: option::Option<Feed>,
        tolerance: u256,
    }
    enum Feed has copy, drop, store {
        Pyth {
            identifier: price_identifier::PriceIdentifier,
            max_interval: u64,
            max_confidence: u64,
        }
    }
    struct AggPriceHub has key {
        agg_price_hub: smart_table::SmartTable<address, AggPriceConfig>,
    }
    public entry fun add_agg_price_config_with_primary_feeder(p0: &signer, p1: object::Object<fungible_asset::Metadata>, p2: u64, p3: u64, p4: vector<u8>)
        acquires AggPriceHub
    {
        let _v0 = string::utf8(vector[97u8, 100u8, 100u8, 95u8, 97u8, 103u8, 103u8, 95u8, 112u8, 114u8, 105u8, 99u8, 101u8, 95u8, 99u8, 111u8, 110u8, 102u8, 105u8, 103u8, 95u8, 119u8, 105u8, 116u8, 104u8, 95u8, 112u8, 114u8, 105u8, 109u8, 97u8, 114u8, 121u8, 95u8, 102u8, 101u8, 101u8, 100u8, 101u8, 114u8]);
        package_manager::assert_admin(p0, _v0);
        let _v1 = package_manager::get_signer();
        let _v2 = signer::address_of(&_v1);
        let _v3 = object::object_address<fungible_asset::Metadata>(&p1);
        if (!exists<AggPriceHub>(_v2)) {
            let _v4 = &_v1;
            let _v5 = AggPriceHub{agg_price_hub: smart_table::new<address, AggPriceConfig>()};
            move_to<AggPriceHub>(_v4, _v5)
        };
        let _v6 = borrow_global_mut<AggPriceHub>(_v2);
        if (smart_table::contains<address, AggPriceConfig>(&_v6.agg_price_hub, _v3)) abort 2200004;
        let _v7 = Feed::Pyth{identifier: price_identifier::from_byte_vec(p4), max_interval: p2, max_confidence: p3};
        let _v8 = &mut _v6.agg_price_hub;
        let _v9 = fungible_asset::decimals<fungible_asset::Metadata>(p1) as u64;
        let _v10 = math64::pow(10, _v9);
        let _v11 = option::none<Feed>();
        let _v12 = AggPriceConfig{precision: _v10, primary_feeder: _v7, second_feeder: _v11, tolerance: 0u256};
        smart_table::add<address, AggPriceConfig>(_v8, _v3, _v12);
    }
    entry fun add_agg_price_config_with_primary_feeder_batch(p0: &signer, p1: vector<object::Object<fungible_asset::Metadata>>, p2: vector<u64>, p3: vector<u64>, p4: vector<vector<u8>>)
        acquires AggPriceHub
    {
        let _v0 = 0x1::vector::length<object::Object<fungible_asset::Metadata>>(&p1);
        assert!(0x1::vector::length<u64>(&p2) == _v0, 2200006);
        assert!(0x1::vector::length<u64>(&p3) == _v0, 2200006);
        assert!(0x1::vector::length<vector<u8>>(&p4) == _v0, 2200006);
        let _v1 = &p1;
        let _v2 = 0;
        let _v3 = 0x1::vector::length<object::Object<fungible_asset::Metadata>>(_v1);
        while (_v2 < _v3) {
            let _v4 = _v2;
            let _v5 = 0x1::vector::borrow<object::Object<fungible_asset::Metadata>>(_v1, _v2);
            let _v6 = *0x1::vector::borrow<u64>(&p2, _v4);
            let _v7 = *0x1::vector::borrow<u64>(&p3, _v4);
            let _v8 = *0x1::vector::borrow<vector<u8>>(&p4, _v4);
            let _v9 = *_v5;
            add_agg_price_config_with_primary_feeder(p0, _v9, _v6, _v7, _v8);
            _v2 = _v2 + 1;
            continue
        };
    }
    fun asset_to_value(p0: &AggPrice, p1: u64): u256 {
        let _v0 = mul_by_u64(*&p0.price, p1);
        let _v1 = *&p0.precision;
        div_by_u64(_v0, _v1)
    }
    fun mul_by_u64(p0: u256, p1: u64): u256 {
        let _v0 = p1 as u256;
        p0 * _v0
    }
    fun div_by_u64(p0: u256, p1: u64): u256 {
        let _v0 = p1 as u256;
        p0 / _v0
    }
    fun div_with_u64(p0: u64, p1: u64): u256 {
        let _v0 = (p0 as u256) * 1000000000000000000u256;
        let _v1 = p1 as u256;
        _v0 / _v1
    }
    friend fun get_asset_u_value(p0: object::Object<fungible_asset::Metadata>, p1: u64): u64
        acquires AggPriceHub
    {
        let _v0 = parse_config(p0);
        (asset_to_value(&_v0, p1) / 1000000000000000000u256) as u64
    }
    fun parse_config(p0: object::Object<fungible_asset::Metadata>): AggPrice
        acquires AggPriceHub
    {
        let _v0 = timestamp::now_seconds();
        parse_pyth_feeder(p0, _v0)
    }
    public fun is_token_in_hub(p0: object::Object<fungible_asset::Metadata>): bool
        acquires AggPriceHub
    {
        let _v0 = package_manager::get_resource_address();
        let _v1 = &borrow_global<AggPriceHub>(_v0).agg_price_hub;
        let _v2 = object::object_address<fungible_asset::Metadata>(&p0);
        smart_table::contains<address, AggPriceConfig>(_v1, _v2)
    }
    fun mul_with_u64(p0: u64, p1: u64): u256 {
        let _v0 = (p0 as u256) * 1000000000000000000u256;
        let _v1 = p1 as u256;
        _v0 * _v1
    }
    fun parse_pyth_feeder(p0: object::Object<fungible_asset::Metadata>, p1: u64): AggPrice
        acquires AggPriceHub
    {
        let _v0;
        let _v1;
        let _v2 = package_manager::get_resource_address();
        let _v3 = &borrow_global<AggPriceHub>(_v2).agg_price_hub;
        let _v4 = object::object_address<fungible_asset::Metadata>(&p0);
        let _v5 = smart_table::borrow<address, AggPriceConfig>(_v3, _v4);
        let _v6 = *&_v5.primary_feeder;
        let _v7 = pyth::get_price_unsafe(*&(&_v6).identifier);
        let _v8 = price::get_timestamp(&_v7);
        let _v9 = *&(&_v6).max_interval;
        assert!(_v8 + _v9 >= p1, 2200001);
        let _v10 = price::get_conf(&_v7);
        let _v11 = *&(&_v6).max_confidence;
        assert!(_v10 <= _v11, 2200002);
        let _v12 = price::get_price(&_v7);
        p1 = i64::get_magnitude_if_positive(&_v12);
        assert!(p1 > 0, 2200003);
        let _v13 = price::get_expo(&_v7);
        if (i64::get_is_negative(&_v13)) {
            _v1 = i64::get_magnitude_if_negative(&_v13);
            let _v14 = math64::pow(10, _v1);
            _v0 = div_with_u64(p1, _v14)
        } else {
            _v1 = i64::get_magnitude_if_positive(&_v13);
            let _v15 = math64::pow(10, _v1);
            _v0 = mul_with_u64(p1, _v15)
        };
        let _v16 = *&_v5.precision;
        AggPrice{price: _v0, precision: _v16}
    }
    fun precision_of(p0: &AggPrice): u64 {
        *&p0.precision
    }
    fun price_of(p0: &AggPrice): u256 {
        *&p0.price
    }
    fun token_in_hub_list(): vector<address>
        acquires AggPriceHub
    {
        let _v0 = package_manager::get_resource_address();
        smart_table::keys<address, AggPriceConfig>(&borrow_global<AggPriceHub>(_v0).agg_price_hub)
    }
    public entry fun update_agg_price_config_primary_feeder(p0: &signer, p1: object::Object<fungible_asset::Metadata>, p2: vector<u8>, p3: u64, p4: u64)
        acquires AggPriceHub
    {
        let _v0 = string::utf8(vector[117u8, 112u8, 100u8, 97u8, 116u8, 101u8, 95u8, 97u8, 103u8, 103u8, 95u8, 112u8, 114u8, 105u8, 99u8, 101u8, 95u8, 99u8, 111u8, 110u8, 102u8, 105u8, 103u8, 95u8, 112u8, 114u8, 105u8, 109u8, 97u8, 114u8, 121u8, 95u8, 102u8, 101u8, 101u8, 100u8, 101u8, 114u8]);
        package_manager::assert_admin(p0, _v0);
        let _v1 = package_manager::get_signer();
        let _v2 = signer::address_of(&_v1);
        let _v3 = object::object_address<fungible_asset::Metadata>(&p1);
        let _v4 = borrow_global_mut<AggPriceHub>(_v2);
        assert!(smart_table::contains<address, AggPriceConfig>(&_v4.agg_price_hub, _v3), 2200005);
        let _v5 = Feed::Pyth{identifier: price_identifier::from_byte_vec(p2), max_interval: p3, max_confidence: p4};
        let _v6 = &mut smart_table::borrow_mut<address, AggPriceConfig>(&mut _v4.agg_price_hub, _v3).primary_feeder;
        *_v6 = _v5;
    }
    entry fun update_agg_price_config_primary_feeder_batch(p0: &signer, p1: vector<object::Object<fungible_asset::Metadata>>, p2: vector<u64>, p3: vector<u64>, p4: vector<vector<u8>>)
        acquires AggPriceHub
    {
        let _v0 = 0x1::vector::length<object::Object<fungible_asset::Metadata>>(&p1);
        assert!(0x1::vector::length<u64>(&p2) == _v0, 2200006);
        assert!(0x1::vector::length<u64>(&p3) == _v0, 2200006);
        assert!(0x1::vector::length<vector<u8>>(&p4) == _v0, 2200006);
        let _v1 = &p1;
        let _v2 = 0;
        let _v3 = 0x1::vector::length<object::Object<fungible_asset::Metadata>>(_v1);
        while (_v2 < _v3) {
            let _v4 = _v2;
            let _v5 = 0x1::vector::borrow<object::Object<fungible_asset::Metadata>>(_v1, _v2);
            let _v6 = *0x1::vector::borrow<u64>(&p2, _v4);
            let _v7 = *0x1::vector::borrow<u64>(&p3, _v4);
            let _v8 = *0x1::vector::borrow<vector<u8>>(&p4, _v4);
            let _v9 = *_v5;
            update_agg_price_config_primary_feeder(p0, _v9, _v8, _v6, _v7);
            _v2 = _v2 + 1;
            continue
        };
    }
}
