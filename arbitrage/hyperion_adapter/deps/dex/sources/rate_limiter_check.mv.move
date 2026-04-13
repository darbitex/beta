module 0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c::rate_limiter_check {
    use 0x1::object;
    use 0x1::fungible_asset;
    use 0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c::pool_v3;
    use 0x1::smart_table;
    use 0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c::rate_limiter;
    use 0x1::option;
    use 0x1::smart_vector;
    use 0x1::string;
    use 0x1::error;
    use 0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c::package_manager;
    use 0x1::signer;
    use 0x1::event;
    use 0x1::vector;
    use 0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c::price_hub;
    use 0x1::transaction_context;
    use 0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c::user_label;
    friend 0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c::router_v3;
    struct AddGlobalUPriceAsset has copy, drop, store {
        token: object::Object<fungible_asset::Metadata>,
    }
    struct AddPoolUPriceRateLimiter has copy, drop, store {
        pool: object::Object<pool_v3::LiquidityPoolV3>,
        capacity: u64,
        interval: u64,
    }
    struct AssetRateLimiterHub has key {
        asset_limiter: smart_table::SmartTable<address, rate_limiter::RateLimiter>,
        user_limiter_configs: smart_table::SmartTable<address, UserConfig>,
    }
    struct UserConfig has copy, drop, store {
        capacity: u64,
        interval: u64,
    }
    struct LimiterNumber has copy, drop, store {
        asset: object::Object<fungible_asset::Metadata>,
        remain: u64,
        capacity: u64,
        interval: u64,
    }
    struct PoolUPriceLimiterHub has key {
        pool_limiter: smart_table::SmartTable<address, rate_limiter::RateLimiter>,
    }
    struct PoolUPriceLimiterNumber has copy, drop, store {
        exist: bool,
        remain: u64,
        capacity: u64,
        interval: u64,
    }
    struct ProtocolUPriceLimiterHub has key {
        limiter: option::Option<rate_limiter::RateLimiter>,
        assets_included: smart_vector::SmartVector<address>,
    }
    struct RateLimiterEvent has copy, drop, store {
        admin: address,
        operate_type: string::String,
        limiter_oriented: string::String,
        capacity: u64,
        interval: u64,
    }
    struct RemoveGlobalUPriceAsset has copy, drop, store {
        token: object::Object<fungible_asset::Metadata>,
    }
    struct RemovePoolUPriceAsset has copy, drop, store {
        pool: object::Object<pool_v3::LiquidityPoolV3>,
    }
    struct ResetGlobalUPriceRateLimiter has copy, drop, store {
        capacity: u64,
        interval: u64,
    }
    struct ResetPoolUPriceRateLimiter has copy, drop, store {
        pool: object::Object<pool_v3::LiquidityPoolV3>,
        capacity: u64,
        interval: u64,
    }
    struct UpdateGlobalUPriceRateLimiter has copy, drop, store {
        capacity: u64,
        interval: u64,
    }
    struct UpdatePoolUPriceRateLimiter has copy, drop, store {
        pool: object::Object<pool_v3::LiquidityPoolV3>,
        capacity: u64,
        interval: u64,
    }
    struct UserRateLimiterHub has key {
        user_asset_limiter: smart_table::SmartTable<address, rate_limiter::RateLimiter>,
    }
    entry fun add_asset_rate_limiter(p0: &signer, p1: object::Object<fungible_asset::Metadata>, p2: u64, p3: u64) {
        let _v0 = error::unavailable(11111111);
        abort _v0
    }
    entry fun add_global_asset_rate_limiter(p0: &signer, p1: object::Object<fungible_asset::Metadata>, p2: u64, p3: u64)
        acquires AssetRateLimiterHub
    {
        let _v0 = string::utf8(vector[97u8, 100u8, 100u8, 95u8, 103u8, 108u8, 111u8, 98u8, 97u8, 108u8, 95u8, 97u8, 115u8, 115u8, 101u8, 116u8, 95u8, 114u8, 97u8, 116u8, 101u8, 95u8, 108u8, 105u8, 109u8, 105u8, 116u8, 101u8, 114u8]);
        package_manager::assert_admin(p0, _v0);
        let _v1 = object::object_address<fungible_asset::Metadata>(&p1);
        let _v2 = package_manager::get_resource_address();
        let _v3 = borrow_global_mut<AssetRateLimiterHub>(_v2);
        if (smart_table::contains<address, rate_limiter::RateLimiter>(&_v3.asset_limiter, _v1)) abort 180002;
        let _v4 = &mut _v3.asset_limiter;
        let _v5 = rate_limiter::initialize(p2, p3);
        smart_table::add<address, rate_limiter::RateLimiter>(_v4, _v1, _v5);
        let _v6 = signer::address_of(p0);
        let _v7 = string::utf8(vector[99u8, 114u8, 101u8, 97u8, 116u8, 101u8]);
        let _v8 = string::utf8(vector[103u8, 108u8, 111u8, 98u8, 97u8, 108u8]);
        event::emit<RateLimiterEvent>(RateLimiterEvent{admin: _v6, operate_type: _v7, limiter_oriented: _v8, capacity: p2, interval: p3});
    }
    entry fun add_global_u_price_asset_batch(p0: &signer, p1: vector<object::Object<fungible_asset::Metadata>>)
        acquires ProtocolUPriceLimiterHub
    {
        let _v0 = string::utf8(vector[97u8, 100u8, 100u8, 95u8, 103u8, 108u8, 111u8, 98u8, 97u8, 108u8, 95u8, 117u8, 95u8, 112u8, 114u8, 105u8, 99u8, 101u8, 95u8, 97u8, 115u8, 115u8, 101u8, 116u8, 95u8, 98u8, 97u8, 116u8, 99u8, 104u8]);
        package_manager::assert_admin(p0, _v0);
        let _v1 = package_manager::get_resource_address();
        let _v2 = borrow_global_mut<ProtocolUPriceLimiterHub>(_v1);
        let _v3 = p1;
        vector::reverse<object::Object<fungible_asset::Metadata>>(&mut _v3);
        let _v4 = _v3;
        let _v5 = vector::length<object::Object<fungible_asset::Metadata>>(&_v4);
        'l0: loop {
            'l1: loop {
                loop {
                    if (!(_v5 > 0)) break 'l0;
                    let _v6 = vector::pop_back<object::Object<fungible_asset::Metadata>>(&mut _v4);
                    let _v7 = object::object_address<fungible_asset::Metadata>(&_v6);
                    let _v8 = &_v2.assets_included;
                    let _v9 = &_v7;
                    if (smart_vector::contains<address>(_v8, _v9)) break 'l1;
                    if (!price_hub::is_token_in_hub(_v6)) break;
                    smart_vector::push_back<address>(&mut _v2.assets_included, _v7);
                    event::emit<AddGlobalUPriceAsset>(AddGlobalUPriceAsset{token: _v6});
                    _v5 = _v5 - 1;
                    continue
                };
                abort 180007
            };
            abort 180002
        };
        vector::destroy_empty<object::Object<fungible_asset::Metadata>>(_v4);
    }
    entry fun add_pool_u_price_rate_limiter(p0: &signer, p1: object::Object<pool_v3::LiquidityPoolV3>, p2: u64, p3: u64)
        acquires PoolUPriceLimiterHub
    {
        let _v0 = string::utf8(vector[97u8, 100u8, 100u8, 95u8, 112u8, 111u8, 111u8, 108u8, 95u8, 117u8, 95u8, 112u8, 114u8, 105u8, 99u8, 101u8, 95u8, 114u8, 97u8, 116u8, 101u8, 95u8, 108u8, 105u8, 109u8, 105u8, 116u8, 101u8, 114u8]);
        package_manager::assert_admin(p0, _v0);
        let _v1 = pool_v3::supported_inner_assets(p1);
        vector::reverse<object::Object<fungible_asset::Metadata>>(&mut _v1);
        let _v2 = _v1;
        let _v3 = vector::length<object::Object<fungible_asset::Metadata>>(&_v2);
        'l0: loop {
            loop {
                if (!(_v3 > 0)) break 'l0;
                if (!price_hub::is_token_in_hub(vector::pop_back<object::Object<fungible_asset::Metadata>>(&mut _v2))) break;
                _v3 = _v3 - 1
            };
            abort 180007
        };
        vector::destroy_empty<object::Object<fungible_asset::Metadata>>(_v2);
        let _v4 = package_manager::get_resource_address();
        let _v5 = borrow_global_mut<PoolUPriceLimiterHub>(_v4);
        let _v6 = object::object_address<pool_v3::LiquidityPoolV3>(&p1);
        if (smart_table::contains<address, rate_limiter::RateLimiter>(&_v5.pool_limiter, _v6)) abort 180002;
        let _v7 = rate_limiter::initialize(p2, p3);
        smart_table::add<address, rate_limiter::RateLimiter>(&mut _v5.pool_limiter, _v6, _v7);
        event::emit<AddPoolUPriceRateLimiter>(AddPoolUPriceRateLimiter{pool: p1, capacity: p2, interval: p3});
    }
    entry fun add_user_asset_rate_limiter(p0: &signer, p1: object::Object<fungible_asset::Metadata>, p2: u64, p3: u64)
        acquires AssetRateLimiterHub
    {
        let _v0 = string::utf8(vector[97u8, 100u8, 100u8, 95u8, 117u8, 115u8, 101u8, 114u8, 95u8, 97u8, 115u8, 115u8, 101u8, 116u8, 95u8, 114u8, 97u8, 116u8, 101u8, 95u8, 108u8, 105u8, 109u8, 105u8, 116u8, 101u8, 114u8]);
        package_manager::assert_admin(p0, _v0);
        let _v1 = object::object_address<fungible_asset::Metadata>(&p1);
        let _v2 = package_manager::get_resource_address();
        let _v3 = borrow_global_mut<AssetRateLimiterHub>(_v2);
        if (smart_table::contains<address, UserConfig>(&_v3.user_limiter_configs, _v1)) abort 180002;
        let _v4 = &mut _v3.user_limiter_configs;
        let _v5 = UserConfig{capacity: p2, interval: p3};
        smart_table::add<address, UserConfig>(_v4, _v1, _v5);
        let _v6 = signer::address_of(p0);
        let _v7 = string::utf8(vector[99u8, 114u8, 101u8, 97u8, 116u8, 101u8]);
        let _v8 = string::utf8(vector[117u8, 115u8, 101u8, 114u8]);
        event::emit<RateLimiterEvent>(RateLimiterEvent{admin: _v6, operate_type: _v7, limiter_oriented: _v8, capacity: p2, interval: p3});
    }
    friend fun check_asset_request(p0: address, p1: u64): bool {
        let _v0 = error::unavailable(11111111);
        abort _v0
    }
    friend fun check_user_asset_request(p0: &signer, p1: address, p2: u64): bool {
        let _v0 = error::unavailable(11111111);
        abort _v0
    }
    public fun global_asset_rate_limiter(p0: object::Object<fungible_asset::Metadata>): (u64, u64, u64)
        acquires AssetRateLimiterHub
    {
        let (_v0,_v1,_v2,_v3) = global_asset_rate_limiter_inner(p0);
        assert!(_v0, 180006);
        (_v1, _v2, _v3)
    }
    fun global_asset_rate_limiter_inner(p0: object::Object<fungible_asset::Metadata>): (bool, u64, u64, u64)
        acquires AssetRateLimiterHub
    {
        let _v0 = package_manager::get_resource_address();
        let _v1 = borrow_global<AssetRateLimiterHub>(_v0);
        let _v2 = object::object_address<fungible_asset::Metadata>(&p0);
        if (smart_table::contains<address, rate_limiter::RateLimiter>(&_v1.asset_limiter, _v2)) {
            let _v3 = &_v1.asset_limiter;
            let _v4 = object::object_address<fungible_asset::Metadata>(&p0);
            let (_v5,_v6,_v7) = rate_limiter::rate_limiter_info_real_time(smart_table::borrow<address, rate_limiter::RateLimiter>(_v3, _v4));
            return (true, _v5, _v6, _v7)
        };
        (false, 0, 0, 0)
    }
    public fun global_asset_rate_limiter_batch(p0: vector<object::Object<fungible_asset::Metadata>>): vector<LimiterNumber>
        acquires AssetRateLimiterHub
    {
        let _v0 = vector::empty<LimiterNumber>();
        let _v1 = p0;
        vector::reverse<object::Object<fungible_asset::Metadata>>(&mut _v1);
        let _v2 = _v1;
        let _v3 = vector::length<object::Object<fungible_asset::Metadata>>(&_v2);
        while (_v3 > 0) {
            let _v4 = vector::pop_back<object::Object<fungible_asset::Metadata>>(&mut _v2);
            let (_v5,_v6,_v7,_v8) = global_asset_rate_limiter_inner(_v4);
            if (_v5) {
                let _v9 = &mut _v0;
                let _v10 = LimiterNumber{asset: _v4, remain: _v6, capacity: _v7, interval: _v8};
                vector::push_back<LimiterNumber>(_v9, _v10)
            };
            _v3 = _v3 - 1;
            continue
        };
        vector::destroy_empty<object::Object<fungible_asset::Metadata>>(_v2);
        _v0
    }
    public fun global_u_price_limiter(): (bool, u64, u64, u64, vector<address>)
        acquires ProtocolUPriceLimiterHub
    {
        let _v0 = package_manager::get_resource_address();
        let _v1 = borrow_global<ProtocolUPriceLimiterHub>(_v0);
        if (option::is_some<rate_limiter::RateLimiter>(&_v1.limiter)) {
            let (_v2,_v3,_v4) = rate_limiter::rate_limiter_info_real_time(option::borrow<rate_limiter::RateLimiter>(&_v1.limiter));
            let _v5 = smart_vector::to_vector<address>(&_v1.assets_included);
            return (true, _v2, _v3, _v4, _v5)
        };
        let _v6 = vector::empty<address>();
        (false, 0, 0, 0, _v6)
    }
    entry fun init_asset_ratelimiter_hub(p0: &signer) {
        assert!(package_manager::is_super_admin(signer::address_of(p0)), 180001);
        let _v0 = package_manager::get_signer();
        let _v1 = signer::address_of(&_v0);
        if (!exists<AssetRateLimiterHub>(_v1)) {
            let _v2 = &_v0;
            let _v3 = smart_table::new<address, rate_limiter::RateLimiter>();
            let _v4 = smart_table::new<address, UserConfig>();
            let _v5 = AssetRateLimiterHub{asset_limiter: _v3, user_limiter_configs: _v4};
            move_to<AssetRateLimiterHub>(_v2, _v5)
        };
        if (!exists<PoolUPriceLimiterHub>(_v1)) {
            let _v6 = &_v0;
            let _v7 = PoolUPriceLimiterHub{pool_limiter: smart_table::new<address, rate_limiter::RateLimiter>()};
            move_to<PoolUPriceLimiterHub>(_v6, _v7)
        };
        if (!exists<ProtocolUPriceLimiterHub>(_v1)) {
            let _v8 = &_v0;
            let _v9 = option::none<rate_limiter::RateLimiter>();
            let _v10 = smart_vector::new<address>();
            let _v11 = ProtocolUPriceLimiterHub{limiter: _v9, assets_included: _v10};
            move_to<ProtocolUPriceLimiterHub>(_v8, _v11);
            return ()
        };
    }
    fun initialize_user_asset_rate_limiter(p0: &signer, p1: address)
        acquires AssetRateLimiterHub, UserRateLimiterHub
    {
        let _v0 = signer::address_of(p0);
        if (!exists<UserRateLimiterHub>(_v0)) {
            let _v1 = UserRateLimiterHub{user_asset_limiter: smart_table::new<address, rate_limiter::RateLimiter>()};
            move_to<UserRateLimiterHub>(p0, _v1)
        };
        let _v2 = package_manager::get_resource_address();
        if (exists<AssetRateLimiterHub>(_v2)) {
            let _v3 = package_manager::get_resource_address();
            let _v4 = borrow_global<AssetRateLimiterHub>(_v3);
            let _v5 = borrow_global_mut<UserRateLimiterHub>(_v0);
            if (smart_table::contains<address, UserConfig>(&_v4.user_limiter_configs, p1)) {
                let _v6 = smart_table::borrow<address, UserConfig>(&_v4.user_limiter_configs, p1);
                if (smart_table::contains<address, rate_limiter::RateLimiter>(&_v5.user_asset_limiter, p1)) {
                    let _v7;
                    let _v8 = smart_table::borrow_mut<address, rate_limiter::RateLimiter>(&mut _v5.user_asset_limiter, p1);
                    let _v9 = rate_limiter::capacity(_v8);
                    let _v10 = *&_v6.capacity;
                    if (_v9 != _v10) _v7 = true else {
                        let _v11 = rate_limiter::refill_interval(_v8);
                        let _v12 = *&_v6.interval;
                        _v7 = _v11 != _v12
                    };
                    if (_v7) {
                        let _v13 = *&_v6.capacity;
                        let _v14 = *&_v6.interval;
                        *_v8 = rate_limiter::initialize(_v13, _v14);
                        return ()
                    };
                    return ()
                };
                let _v15 = &mut _v5.user_asset_limiter;
                let _v16 = *&_v6.capacity;
                let _v17 = *&_v6.interval;
                let _v18 = rate_limiter::initialize(_v16, _v17);
                smart_table::add<address, rate_limiter::RateLimiter>(_v15, p1, _v18);
                return ()
            };
            return ()
        };
    }
    friend fun is_global_limiter_passed(p0: address, p1: u64): bool {
        abort 11111111
    }
    fun is_global_limiter_passed_internal(p0: address, p1: u64): bool
        acquires AssetRateLimiterHub
    {
        let _v0;
        let _v1 = package_manager::get_resource_address();
        if (exists<AssetRateLimiterHub>(_v1)) {
            let _v2;
            let _v3;
            let _v4;
            let _v5 = p0;
            let _v6 = package_manager::get_resource_address();
            let _v7 = borrow_global_mut<AssetRateLimiterHub>(_v6);
            if (smart_table::contains<address, rate_limiter::RateLimiter>(&_v7.asset_limiter, _v5)) {
                _v4 = smart_table::borrow_mut<address, rate_limiter::RateLimiter>(&mut _v7.asset_limiter, _v5);
                _v3 = true
            } else {
                let _v8 = rate_limiter::initialize(0, 0);
                _v4 = &mut _v8;
                _v3 = false
            };
            if (_v3) _v2 = rate_limiter::request(_v4, p1) else _v2 = true;
            _v0 = _v2
        } else _v0 = true;
        _v0
    }
    fun is_global_u_price_limiter_passed_internal(p0: address, p1: u64): bool
        acquires ProtocolUPriceLimiterHub
    {
        let _v0;
        let _v1 = package_manager::get_resource_address();
        if (exists<ProtocolUPriceLimiterHub>(_v1)) {
            let _v2;
            let _v3 = package_manager::get_resource_address();
            let _v4 = borrow_global_mut<ProtocolUPriceLimiterHub>(_v3);
            if (option::is_none<rate_limiter::RateLimiter>(&_v4.limiter)) _v2 = true else {
                let _v5 = &_v4.assets_included;
                let _v6 = &p0;
                if (smart_vector::contains<address>(_v5, _v6)) {
                    let _v7 = price_hub::get_asset_u_value(object::address_to_object<fungible_asset::Metadata>(p0), p1);
                    _v2 = rate_limiter::request(option::borrow_mut<rate_limiter::RateLimiter>(&mut _v4.limiter), _v7)
                } else _v2 = true
            };
            _v0 = _v2
        } else _v0 = true;
        _v0
    }
    fun is_pool_u_price_limiter_passed_internal(p0: address, p1: address, p2: u64): bool
        acquires PoolUPriceLimiterHub
    {
        let _v0;
        let _v1 = package_manager::get_resource_address();
        if (exists<PoolUPriceLimiterHub>(_v1)) {
            let _v2;
            let _v3 = package_manager::get_resource_address();
            let _v4 = borrow_global_mut<PoolUPriceLimiterHub>(_v3);
            if (smart_table::contains<address, rate_limiter::RateLimiter>(&_v4.pool_limiter, p0)) {
                let _v5 = price_hub::get_asset_u_value(object::address_to_object<fungible_asset::Metadata>(p1), p2);
                _v2 = rate_limiter::request(smart_table::borrow_mut<address, rate_limiter::RateLimiter>(&mut _v4.pool_limiter, p0), _v5)
            } else _v2 = true;
            _v0 = _v2
        } else _v0 = true;
        _v0
    }
    friend fun is_rate_limiter_passed(p0: &signer, p1: address, p2: u64): bool
        acquires AssetRateLimiterHub, UserRateLimiterHub
    {
        let _v0;
        let _v1 = is_rate_limiter_whitelist(p0);
        loop {
            if (!_v1) {
                let _v2 = is_global_limiter_passed_internal(p1, p2);
                let _v3 = is_user_limiter_passed_internal(p0, p1, p2);
                if (_v2) {
                    _v0 = _v3;
                    break
                };
                _v0 = false;
                break
            };
            return true
        };
        _v0
    }
    fun is_rate_limiter_whitelist(p0: &signer): bool {
        let _v0;
        let _v1;
        let _v2 = signer::address_of(p0);
        let _v3 = transaction_context::multisig_payload();
        if (option::is_some<transaction_context::MultisigPayload>(&_v3)) {
            let _v4 = option::destroy_some<transaction_context::MultisigPayload>(_v3);
            _v1 = transaction_context::multisig_address(&_v4)
        } else {
            option::destroy_none<transaction_context::MultisigPayload>(_v3);
            _v1 = transaction_context::sender()
        };
        let _v5 = string::utf8(vector[86u8, 65u8, 85u8, 76u8, 84u8, 95u8, 80u8, 79u8, 79u8, 76u8]);
        if (user_label::has_label(_v2, _v5)) {
            let _v6 = string::utf8(vector[86u8, 65u8, 85u8, 76u8, 84u8, 95u8, 66u8, 79u8, 84u8, 95u8, 65u8, 68u8, 68u8, 82u8, 69u8, 83u8, 83u8]);
            _v0 = user_label::has_label(_v1, _v6)
        } else _v0 = false;
        let _v7 = string::utf8(vector[82u8, 65u8, 84u8, 69u8, 95u8, 76u8, 73u8, 77u8, 73u8, 84u8, 69u8, 82u8, 95u8, 87u8, 72u8, 73u8, 84u8, 69u8, 76u8, 73u8, 83u8, 84u8]);
        let _v8 = user_label::has_label(_v2, _v7);
        if (_v0) return true;
        _v8
    }
    fun is_user_limiter_passed_internal(p0: &signer, p1: address, p2: u64): bool
        acquires AssetRateLimiterHub, UserRateLimiterHub
    {
        let _v0;
        let _v1;
        let _v2;
        initialize_user_asset_rate_limiter(p0, p1);
        let _v3 = signer::address_of(p0);
        let _v4 = borrow_global_mut<UserRateLimiterHub>(_v3);
        if (smart_table::contains<address, rate_limiter::RateLimiter>(&_v4.user_asset_limiter, p1)) {
            _v2 = smart_table::borrow_mut<address, rate_limiter::RateLimiter>(&mut _v4.user_asset_limiter, p1);
            _v1 = true
        } else {
            let _v5 = rate_limiter::initialize(0, 0);
            _v2 = &mut _v5;
            _v1 = false
        };
        if (_v1) _v0 = rate_limiter::request(_v2, p2) else _v0 = true;
        _v0
    }
    friend fun is_rate_limiter_passed_v2(p0: &signer, p1: address, p2: address, p3: u64): bool
        acquires PoolUPriceLimiterHub, ProtocolUPriceLimiterHub
    {
        let _v0;
        let _v1 = is_rate_limiter_whitelist(p0);
        loop {
            if (!_v1) {
                let _v2 = is_global_u_price_limiter_passed_internal(p2, p3);
                let _v3 = is_pool_u_price_limiter_passed_internal(p1, p2, p3);
                if (_v2) {
                    _v0 = _v3;
                    break
                };
                _v0 = false;
                break
            };
            return true
        };
        _v0
    }
    friend fun is_user_limiter_passed(p0: &signer, p1: address, p2: u64): bool {
        abort 11111111
    }
    public fun pool_u_price_limiter(p0: address): (bool, u64, u64, u64)
        acquires PoolUPriceLimiterHub
    {
        let _v0 = package_manager::get_resource_address();
        let _v1 = borrow_global<PoolUPriceLimiterHub>(_v0);
        if (smart_table::contains<address, rate_limiter::RateLimiter>(&_v1.pool_limiter, p0)) {
            let (_v2,_v3,_v4) = rate_limiter::rate_limiter_info_real_time(smart_table::borrow<address, rate_limiter::RateLimiter>(&_v1.pool_limiter, p0));
            return (true, _v2, _v3, _v4)
        };
        (false, 0, 0, 0)
    }
    public fun pool_u_price_limiter_batch(p0: vector<address>): vector<PoolUPriceLimiterNumber>
        acquires PoolUPriceLimiterHub
    {
        let _v0 = vector::empty<PoolUPriceLimiterNumber>();
        let _v1 = p0;
        vector::reverse<address>(&mut _v1);
        let _v2 = _v1;
        let _v3 = vector::length<address>(&_v2);
        while (_v3 > 0) {
            let (_v4,_v5,_v6,_v7) = pool_u_price_limiter(vector::pop_back<address>(&mut _v2));
            let _v8 = &mut _v0;
            let _v9 = PoolUPriceLimiterNumber{exist: _v4, remain: _v5, capacity: _v6, interval: _v7};
            vector::push_back<PoolUPriceLimiterNumber>(_v8, _v9);
            _v3 = _v3 - 1;
            continue
        };
        vector::destroy_empty<address>(_v2);
        _v0
    }
    fun recover_global_limiter(p0: address, p1: u64)
        acquires AssetRateLimiterHub
    {
        let _v0 = package_manager::get_resource_address();
        if (exists<AssetRateLimiterHub>(_v0)) {
            let _v1;
            let _v2;
            let _v3 = p0;
            let _v4 = package_manager::get_resource_address();
            let _v5 = borrow_global_mut<AssetRateLimiterHub>(_v4);
            if (smart_table::contains<address, rate_limiter::RateLimiter>(&_v5.asset_limiter, _v3)) {
                _v2 = smart_table::borrow_mut<address, rate_limiter::RateLimiter>(&mut _v5.asset_limiter, _v3);
                _v1 = true
            } else {
                let _v6 = rate_limiter::initialize(0, 0);
                _v2 = &mut _v6;
                _v1 = false
            };
            if (_v1) {
                rate_limiter::recover(_v2, p1);
                return ()
            };
            return ()
        };
    }
    fun recover_global_u_price_limiter(p0: address, p1: u64)
        acquires ProtocolUPriceLimiterHub
    {
        let _v0 = package_manager::get_resource_address();
        if (exists<ProtocolUPriceLimiterHub>(_v0)) {
            let _v1 = package_manager::get_resource_address();
            let _v2 = borrow_global_mut<ProtocolUPriceLimiterHub>(_v1);
            let _v3 = option::is_none<rate_limiter::RateLimiter>(&_v2.limiter);
            loop {
                if (_v3) return () else {
                    let _v4 = &_v2.assets_included;
                    let _v5 = &p0;
                    if (!smart_vector::contains<address>(_v4, _v5)) break
                };
                let _v6 = price_hub::get_asset_u_value(object::address_to_object<fungible_asset::Metadata>(p0), p1);
                rate_limiter::recover(option::borrow_mut<rate_limiter::RateLimiter>(&mut _v2.limiter), _v6);
                return ()
            };
            return ()
        };
    }
    fun recover_pool_u_price_limiter(p0: address, p1: address, p2: u64)
        acquires PoolUPriceLimiterHub
    {
        let _v0 = package_manager::get_resource_address();
        if (exists<PoolUPriceLimiterHub>(_v0)) {
            let _v1 = package_manager::get_resource_address();
            let _v2 = borrow_global_mut<PoolUPriceLimiterHub>(_v1);
            if (smart_table::contains<address, rate_limiter::RateLimiter>(&_v2.pool_limiter, p0)) {
                let _v3 = price_hub::get_asset_u_value(object::address_to_object<fungible_asset::Metadata>(p1), p2);
                rate_limiter::recover(smart_table::borrow_mut<address, rate_limiter::RateLimiter>(&mut _v2.pool_limiter, p0), _v3);
                return ()
            };
            return ()
        };
    }
    friend fun recover_rate_limiter(p0: &signer, p1: address, p2: u64) {
        let _v0 = error::unavailable(11111111);
        abort _v0
    }
    friend fun recover_rate_limiter_v2(p0: &signer, p1: address, p2: address, p3: u64)
        acquires PoolUPriceLimiterHub, ProtocolUPriceLimiterHub
    {
        if (is_rate_limiter_whitelist(p0)) return ();
        recover_global_u_price_limiter(p2, p3);
        recover_pool_u_price_limiter(p1, p2, p3);
    }
    fun recover_user_limiter(p0: &signer, p1: address, p2: u64)
        acquires AssetRateLimiterHub, UserRateLimiterHub
    {
        let _v0;
        let _v1;
        initialize_user_asset_rate_limiter(p0, p1);
        let _v2 = signer::address_of(p0);
        let _v3 = borrow_global_mut<UserRateLimiterHub>(_v2);
        if (smart_table::contains<address, rate_limiter::RateLimiter>(&_v3.user_asset_limiter, p1)) {
            _v1 = smart_table::borrow_mut<address, rate_limiter::RateLimiter>(&mut _v3.user_asset_limiter, p1);
            _v0 = true
        } else {
            let _v4 = rate_limiter::initialize(0, 0);
            _v1 = &mut _v4;
            _v0 = false
        };
        if (_v0) {
            rate_limiter::recover(_v1, p2);
            return ()
        };
    }
    entry fun remove_global_u_price_asset_batch(p0: &signer, p1: vector<object::Object<fungible_asset::Metadata>>)
        acquires ProtocolUPriceLimiterHub
    {
        let _v0 = string::utf8(vector[114u8, 101u8, 109u8, 111u8, 118u8, 101u8, 95u8, 103u8, 108u8, 111u8, 98u8, 97u8, 108u8, 95u8, 117u8, 95u8, 112u8, 114u8, 105u8, 99u8, 101u8, 95u8, 97u8, 115u8, 115u8, 101u8, 116u8, 95u8, 98u8, 97u8, 116u8, 99u8, 104u8]);
        package_manager::assert_admin(p0, _v0);
        let _v1 = package_manager::get_resource_address();
        let _v2 = borrow_global_mut<ProtocolUPriceLimiterHub>(_v1);
        let _v3 = p1;
        vector::reverse<object::Object<fungible_asset::Metadata>>(&mut _v3);
        let _v4 = _v3;
        let _v5 = vector::length<object::Object<fungible_asset::Metadata>>(&_v4);
        'l0: loop {
            loop {
                if (!(_v5 > 0)) break 'l0;
                let _v6 = vector::pop_back<object::Object<fungible_asset::Metadata>>(&mut _v4);
                let _v7 = object::object_address<fungible_asset::Metadata>(&_v6);
                let _v8 = &_v2.assets_included;
                let _v9 = &_v7;
                if (!smart_vector::contains<address>(_v8, _v9)) break;
                let _v10 = &_v2.assets_included;
                let _v11 = &_v7;
                let (_v12,_v13) = smart_vector::index_of<address>(_v10, _v11);
                let _v14 = smart_vector::remove<address>(&mut _v2.assets_included, _v13);
                event::emit<RemoveGlobalUPriceAsset>(RemoveGlobalUPriceAsset{token: _v6});
                _v5 = _v5 - 1;
                continue
            };
            abort 180003
        };
        vector::destroy_empty<object::Object<fungible_asset::Metadata>>(_v4);
    }
    entry fun remove_pool_u_price_asset_batch(p0: &signer, p1: vector<object::Object<pool_v3::LiquidityPoolV3>>)
        acquires PoolUPriceLimiterHub
    {
        let _v0 = string::utf8(vector[114u8, 101u8, 109u8, 111u8, 118u8, 101u8, 95u8, 112u8, 111u8, 111u8, 108u8, 95u8, 117u8, 95u8, 112u8, 114u8, 105u8, 99u8, 101u8, 95u8, 97u8, 115u8, 115u8, 101u8, 116u8, 95u8, 98u8, 97u8, 116u8, 99u8, 104u8]);
        package_manager::assert_admin(p0, _v0);
        let _v1 = package_manager::get_resource_address();
        let _v2 = borrow_global_mut<PoolUPriceLimiterHub>(_v1);
        let _v3 = p1;
        vector::reverse<object::Object<pool_v3::LiquidityPoolV3>>(&mut _v3);
        let _v4 = _v3;
        let _v5 = vector::length<object::Object<pool_v3::LiquidityPoolV3>>(&_v4);
        'l0: loop {
            loop {
                if (!(_v5 > 0)) break 'l0;
                let _v6 = vector::pop_back<object::Object<pool_v3::LiquidityPoolV3>>(&mut _v4);
                let _v7 = object::object_address<pool_v3::LiquidityPoolV3>(&_v6);
                if (!smart_table::contains<address, rate_limiter::RateLimiter>(&_v2.pool_limiter, _v7)) break;
                let _v8 = smart_table::remove<address, rate_limiter::RateLimiter>(&mut _v2.pool_limiter, _v7);
                event::emit<RemovePoolUPriceAsset>(RemovePoolUPriceAsset{pool: _v6});
                _v5 = _v5 - 1;
                continue
            };
            abort 180003
        };
        vector::destroy_empty<object::Object<pool_v3::LiquidityPoolV3>>(_v4);
    }
    entry fun reset_global_asset_rate_limiter(p0: &signer, p1: object::Object<fungible_asset::Metadata>)
        acquires AssetRateLimiterHub
    {
        let _v0 = string::utf8(vector[114u8, 101u8, 115u8, 101u8, 116u8, 95u8, 103u8, 108u8, 111u8, 98u8, 97u8, 108u8, 95u8, 97u8, 115u8, 115u8, 101u8, 116u8, 95u8, 114u8, 97u8, 116u8, 101u8, 95u8, 108u8, 105u8, 109u8, 105u8, 116u8, 101u8, 114u8]);
        package_manager::assert_admin(p0, _v0);
        let _v1 = object::object_address<fungible_asset::Metadata>(&p1);
        let _v2 = package_manager::get_resource_address();
        let _v3 = borrow_global_mut<AssetRateLimiterHub>(_v2);
        assert!(smart_table::contains<address, rate_limiter::RateLimiter>(&_v3.asset_limiter, _v1), 180003);
        let _v4 = smart_table::borrow_mut<address, rate_limiter::RateLimiter>(&mut _v3.asset_limiter, _v1);
        let _v5 = rate_limiter::refill_interval(_v4);
        let _v6 = rate_limiter::capacity(_v4);
        rate_limiter::recover(_v4, _v6);
        let _v7 = signer::address_of(p0);
        let _v8 = string::utf8(vector[114u8, 101u8, 115u8, 101u8, 116u8]);
        let _v9 = string::utf8(vector[103u8, 108u8, 111u8, 98u8, 97u8, 108u8]);
        event::emit<RateLimiterEvent>(RateLimiterEvent{admin: _v7, operate_type: _v8, limiter_oriented: _v9, capacity: _v6, interval: _v5});
    }
    entry fun reset_global_u_price_rate_limiter(p0: &signer)
        acquires ProtocolUPriceLimiterHub
    {
        let _v0 = string::utf8(vector[114u8, 101u8, 115u8, 101u8, 116u8, 95u8, 103u8, 108u8, 111u8, 98u8, 97u8, 108u8, 95u8, 117u8, 95u8, 112u8, 114u8, 105u8, 99u8, 101u8, 95u8, 114u8, 97u8, 116u8, 101u8, 95u8, 108u8, 105u8, 109u8, 105u8, 116u8, 101u8, 114u8]);
        package_manager::assert_admin(p0, _v0);
        let _v1 = package_manager::get_resource_address();
        let _v2 = borrow_global_mut<ProtocolUPriceLimiterHub>(_v1);
        assert!(option::is_some<rate_limiter::RateLimiter>(&_v2.limiter), 180008);
        let _v3 = option::borrow_mut<rate_limiter::RateLimiter>(&mut _v2.limiter);
        let _v4 = rate_limiter::refill_interval(_v3);
        let _v5 = rate_limiter::capacity(_v3);
        rate_limiter::recover(_v3, _v5);
        event::emit<ResetGlobalUPriceRateLimiter>(ResetGlobalUPriceRateLimiter{capacity: _v5, interval: _v4});
    }
    entry fun reset_pool_u_price_rate_limiter(p0: &signer, p1: object::Object<pool_v3::LiquidityPoolV3>)
        acquires PoolUPriceLimiterHub
    {
        let _v0 = string::utf8(vector[114u8, 101u8, 115u8, 101u8, 116u8, 95u8, 112u8, 111u8, 111u8, 108u8, 95u8, 117u8, 95u8, 112u8, 114u8, 105u8, 99u8, 101u8, 95u8, 114u8, 97u8, 116u8, 101u8, 95u8, 108u8, 105u8, 109u8, 105u8, 116u8, 101u8, 114u8]);
        package_manager::assert_admin(p0, _v0);
        let _v1 = object::object_address<pool_v3::LiquidityPoolV3>(&p1);
        let _v2 = package_manager::get_resource_address();
        let _v3 = borrow_global_mut<PoolUPriceLimiterHub>(_v2);
        assert!(smart_table::contains<address, rate_limiter::RateLimiter>(&_v3.pool_limiter, _v1), 180003);
        let _v4 = smart_table::borrow_mut<address, rate_limiter::RateLimiter>(&mut _v3.pool_limiter, _v1);
        let _v5 = rate_limiter::refill_interval(_v4);
        let _v6 = rate_limiter::capacity(_v4);
        rate_limiter::recover(_v4, _v6);
        event::emit<ResetPoolUPriceRateLimiter>(ResetPoolUPriceRateLimiter{pool: p1, capacity: _v6, interval: _v5});
    }
    entry fun update_asset_rate_limiter(p0: &signer, p1: object::Object<fungible_asset::Metadata>, p2: u64, p3: u64) {
        let _v0 = error::unavailable(11111111);
        abort _v0
    }
    entry fun update_global_asset_rate_limiter(p0: &signer, p1: object::Object<fungible_asset::Metadata>, p2: u64, p3: u64)
        acquires AssetRateLimiterHub
    {
        let _v0 = string::utf8(vector[117u8, 112u8, 100u8, 97u8, 116u8, 101u8, 95u8, 103u8, 108u8, 111u8, 98u8, 97u8, 108u8, 95u8, 97u8, 115u8, 115u8, 101u8, 116u8, 95u8, 114u8, 97u8, 116u8, 101u8, 95u8, 108u8, 105u8, 109u8, 105u8, 116u8, 101u8, 114u8]);
        package_manager::assert_admin(p0, _v0);
        let _v1 = object::object_address<fungible_asset::Metadata>(&p1);
        let _v2 = package_manager::get_resource_address();
        let _v3 = borrow_global_mut<AssetRateLimiterHub>(_v2);
        assert!(smart_table::contains<address, rate_limiter::RateLimiter>(&_v3.asset_limiter, _v1), 180003);
        let _v4 = smart_table::borrow_mut<address, rate_limiter::RateLimiter>(&mut _v3.asset_limiter, _v1);
        *_v4 = rate_limiter::initialize(p2, p3);
        let _v5 = signer::address_of(p0);
        let _v6 = string::utf8(vector[117u8, 112u8, 100u8, 97u8, 116u8, 101u8]);
        let _v7 = string::utf8(vector[103u8, 108u8, 111u8, 98u8, 97u8, 108u8]);
        event::emit<RateLimiterEvent>(RateLimiterEvent{admin: _v5, operate_type: _v6, limiter_oriented: _v7, capacity: p2, interval: p3});
    }
    entry fun update_global_u_price_rate_limiter(p0: &signer, p1: u64, p2: u64)
        acquires ProtocolUPriceLimiterHub
    {
        let _v0 = string::utf8(vector[117u8, 112u8, 100u8, 97u8, 116u8, 101u8, 95u8, 103u8, 108u8, 111u8, 98u8, 97u8, 108u8, 95u8, 117u8, 95u8, 112u8, 114u8, 105u8, 99u8, 101u8, 95u8, 114u8, 97u8, 116u8, 101u8, 95u8, 108u8, 105u8, 109u8, 105u8, 116u8, 101u8, 114u8]);
        package_manager::assert_admin(p0, _v0);
        let _v1 = package_manager::get_resource_address();
        let _v2 = &mut borrow_global_mut<ProtocolUPriceLimiterHub>(_v1).limiter;
        let _v3 = rate_limiter::initialize(p1, p2);
        let _v4 = option::swap_or_fill<rate_limiter::RateLimiter>(_v2, _v3);
        event::emit<UpdateGlobalUPriceRateLimiter>(UpdateGlobalUPriceRateLimiter{capacity: p1, interval: p2});
    }
    entry fun update_pool_u_price_rate_limiter(p0: &signer, p1: object::Object<pool_v3::LiquidityPoolV3>, p2: u64, p3: u64)
        acquires PoolUPriceLimiterHub
    {
        let _v0 = string::utf8(vector[117u8, 112u8, 100u8, 97u8, 116u8, 101u8, 95u8, 112u8, 111u8, 111u8, 108u8, 95u8, 117u8, 95u8, 112u8, 114u8, 105u8, 99u8, 101u8, 95u8, 114u8, 97u8, 116u8, 101u8, 95u8, 108u8, 105u8, 109u8, 105u8, 116u8, 101u8, 114u8]);
        package_manager::assert_admin(p0, _v0);
        let _v1 = package_manager::get_resource_address();
        let _v2 = borrow_global_mut<PoolUPriceLimiterHub>(_v1);
        let _v3 = object::object_address<pool_v3::LiquidityPoolV3>(&p1);
        assert!(smart_table::contains<address, rate_limiter::RateLimiter>(&_v2.pool_limiter, _v3), 180003);
        let _v4 = smart_table::borrow_mut<address, rate_limiter::RateLimiter>(&mut _v2.pool_limiter, _v3);
        *_v4 = rate_limiter::initialize(p2, p3);
        event::emit<UpdatePoolUPriceRateLimiter>(UpdatePoolUPriceRateLimiter{pool: p1, capacity: p2, interval: p3});
    }
    entry fun update_user_asset_rate_limiter(p0: &signer, p1: object::Object<fungible_asset::Metadata>, p2: u64, p3: u64)
        acquires AssetRateLimiterHub
    {
        let _v0 = string::utf8(vector[117u8, 112u8, 100u8, 97u8, 116u8, 101u8, 95u8, 117u8, 115u8, 101u8, 114u8, 95u8, 97u8, 115u8, 115u8, 101u8, 116u8, 95u8, 114u8, 97u8, 116u8, 101u8, 95u8, 108u8, 105u8, 109u8, 105u8, 116u8, 101u8, 114u8]);
        package_manager::assert_admin(p0, _v0);
        let _v1 = object::object_address<fungible_asset::Metadata>(&p1);
        let _v2 = package_manager::get_resource_address();
        let _v3 = borrow_global_mut<AssetRateLimiterHub>(_v2);
        assert!(smart_table::contains<address, UserConfig>(&_v3.user_limiter_configs, _v1), 180003);
        let _v4 = smart_table::borrow_mut<address, UserConfig>(&mut _v3.user_limiter_configs, _v1);
        *_v4 = UserConfig{capacity: p2, interval: p3};
        let _v5 = signer::address_of(p0);
        let _v6 = string::utf8(vector[117u8, 112u8, 100u8, 97u8, 116u8, 101u8]);
        let _v7 = string::utf8(vector[117u8, 115u8, 101u8, 114u8]);
        event::emit<RateLimiterEvent>(RateLimiterEvent{admin: _v5, operate_type: _v6, limiter_oriented: _v7, capacity: p2, interval: p3});
    }
    public fun user_asset_rate_limiter(p0: address, p1: object::Object<fungible_asset::Metadata>): (u64, u64, u64)
        acquires AssetRateLimiterHub, UserRateLimiterHub
    {
        let (_v0,_v1,_v2,_v3) = user_asset_rate_limiter_inner(p0, p1);
        assert!(_v0, 180006);
        (_v1, _v2, _v3)
    }
    fun user_asset_rate_limiter_inner(p0: address, p1: object::Object<fungible_asset::Metadata>): (bool, u64, u64, u64)
        acquires AssetRateLimiterHub, UserRateLimiterHub
    {
        let _v0 = object::object_address<fungible_asset::Metadata>(&p1);
        let _v1 = package_manager::get_resource_address();
        let _v2 = borrow_global<AssetRateLimiterHub>(_v1);
        if (smart_table::contains<address, UserConfig>(&_v2.user_limiter_configs, _v0)) {
            let _v3;
            let _v4;
            let _v5;
            let _v6;
            let _v7 = smart_table::borrow<address, UserConfig>(&_v2.user_limiter_configs, _v0);
            if (exists<UserRateLimiterHub>(p0)) {
                let _v8 = borrow_global<UserRateLimiterHub>(p0);
                if (smart_table::contains<address, rate_limiter::RateLimiter>(&_v8.user_asset_limiter, _v0)) {
                    let (_v9,_v10,_v11) = rate_limiter::rate_limiter_info_real_time(smart_table::borrow<address, rate_limiter::RateLimiter>(&_v8.user_asset_limiter, _v0));
                    _v6 = _v11;
                    _v5 = true;
                    _v4 = _v10;
                    _v3 = _v9
                } else {
                    _v5 = true;
                    _v3 = *&_v7.capacity;
                    _v4 = *&_v7.capacity;
                    _v6 = *&_v7.interval
                }
            } else {
                _v5 = true;
                _v3 = *&_v7.capacity;
                _v4 = *&_v7.capacity;
                _v6 = *&_v7.interval
            };
            return (_v5, _v3, _v4, _v6)
        };
        (false, 0, 0, 0)
    }
    public fun user_asset_rate_limiter_batch(p0: address, p1: vector<object::Object<fungible_asset::Metadata>>): vector<LimiterNumber>
        acquires AssetRateLimiterHub, UserRateLimiterHub
    {
        let _v0 = vector::empty<LimiterNumber>();
        let _v1 = p1;
        vector::reverse<object::Object<fungible_asset::Metadata>>(&mut _v1);
        let _v2 = _v1;
        let _v3 = vector::length<object::Object<fungible_asset::Metadata>>(&_v2);
        while (_v3 > 0) {
            let _v4 = vector::pop_back<object::Object<fungible_asset::Metadata>>(&mut _v2);
            let (_v5,_v6,_v7,_v8) = user_asset_rate_limiter_inner(p0, _v4);
            if (_v5) {
                let _v9 = &mut _v0;
                let _v10 = LimiterNumber{asset: _v4, remain: _v6, capacity: _v7, interval: _v8};
                vector::push_back<LimiterNumber>(_v9, _v10)
            };
            _v3 = _v3 - 1;
            continue
        };
        vector::destroy_empty<object::Object<fungible_asset::Metadata>>(_v2);
        _v0
    }
    public fun user_asset_rate_limiter_config(p0: object::Object<fungible_asset::Metadata>): (u64, u64)
        acquires AssetRateLimiterHub
    {
        let _v0 = object::object_address<fungible_asset::Metadata>(&p0);
        let _v1 = package_manager::get_resource_address();
        let _v2 = borrow_global<AssetRateLimiterHub>(_v1);
        assert!(smart_table::contains<address, UserConfig>(&_v2.user_limiter_configs, _v0), 180006);
        let _v3 = smart_table::borrow<address, UserConfig>(&_v2.user_limiter_configs, _v0);
        let _v4 = *&_v3.capacity;
        let _v5 = *&_v3.interval;
        (_v4, _v5)
    }
}
