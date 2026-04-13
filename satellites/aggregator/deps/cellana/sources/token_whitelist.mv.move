module 0x4bf51972879e3b95c4781a5cdcb9e1ee24ef483e7d22f2d903626f126df62bd1::token_whitelist {
    use 0x1::fungible_asset;
    use 0x1::object;
    use 0x1::smart_table;
    use 0x1::smart_vector;
    use 0x1::string;
    use 0x1::type_info;
    use 0x1::vector;
    use 0x4bf51972879e3b95c4781a5cdcb9e1ee24ef483e7d22f2d903626f126df62bd1::coin_wrapper;
    use 0x4bf51972879e3b95c4781a5cdcb9e1ee24ef483e7d22f2d903626f126df62bd1::package_manager;
    friend 0x4bf51972879e3b95c4781a5cdcb9e1ee24ef483e7d22f2d903626f126df62bd1::vote_manager;
    struct RewardTokenWhitelistPerPool has key {
        whitelist: smart_table::SmartTable<address, smart_vector::SmartVector<string::String>>,
    }
    struct TokenWhitelist has key {
        tokens: smart_vector::SmartVector<string::String>,
    }
    fun add_to_whitelist(p0: vector<string::String>)
        acquires TokenWhitelist
    {
        let _v0 = &mut borrow_global_mut<TokenWhitelist>(@0x4bf51972879e3b95c4781a5cdcb9e1ee24ef483e7d22f2d903626f126df62bd1).tokens;
        let _v1 = p0;
        vector::reverse<string::String>(&mut _v1);
        let _v2 = _v1;
        let _v3 = vector::length<string::String>(&_v2);
        while (_v3 > 0) {
            let _v4 = vector::pop_back<string::String>(&mut _v2);
            let _v5 = &_v4;
            if (!smart_vector::contains<string::String>(freeze(_v0), _v5)) smart_vector::push_back<string::String>(_v0, _v4);
            _v3 = _v3 - 1;
            continue
        };
        vector::destroy_empty<string::String>(_v2);
    }
    public fun are_whitelisted(p0: vector<string::String>): bool
        acquires TokenWhitelist
    {
        let _v0 = &borrow_global<TokenWhitelist>(@0x4bf51972879e3b95c4781a5cdcb9e1ee24ef483e7d22f2d903626f126df62bd1).tokens;
        let _v1 = &p0;
        let _v2 = true;
        let _v3 = 0;
        loop {
            let _v4 = vector::length<string::String>(_v1);
            if (!(_v3 < _v4)) break;
            let _v5 = vector::borrow<string::String>(_v1, _v3);
            _v2 = smart_vector::contains<string::String>(_v0, _v5);
            if (!_v2) break;
            _v3 = _v3 + 1;
            continue
        };
        _v2
    }
    public entry fun initialize() {
        if (is_initialized()) return ();
        let _v0 = package_manager::get_signer();
        let _v1 = &_v0;
        let _v2 = TokenWhitelist{tokens: smart_vector::new<string::String>()};
        move_to<TokenWhitelist>(_v1, _v2);
    }
    public fun is_initialized(): bool {
        exists<TokenWhitelist>(@0x4bf51972879e3b95c4781a5cdcb9e1ee24ef483e7d22f2d903626f126df62bd1)
    }
    public fun is_reward_token_whitelisted_on_pool(p0: string::String, p1: address): bool
        acquires RewardTokenWhitelistPerPool
    {
        if (!exists<RewardTokenWhitelistPerPool>(@0x4bf51972879e3b95c4781a5cdcb9e1ee24ef483e7d22f2d903626f126df62bd1)) {
            let _v0 = package_manager::get_signer();
            let _v1 = &_v0;
            let _v2 = RewardTokenWhitelistPerPool{whitelist: smart_table::new<address, smart_vector::SmartVector<string::String>>()};
            move_to<RewardTokenWhitelistPerPool>(_v1, _v2)
        };
        let _v3 = smart_table::borrow<address, smart_vector::SmartVector<string::String>>(&borrow_global_mut<RewardTokenWhitelistPerPool>(@0x4bf51972879e3b95c4781a5cdcb9e1ee24ef483e7d22f2d903626f126df62bd1).whitelist, p1);
        let _v4 = &p0;
        smart_vector::contains<string::String>(_v3, _v4)
    }
    friend fun set_whitelist_reward_token<T0>(p0: address, p1: bool)
        acquires RewardTokenWhitelistPerPool
    {
        let _v0 = type_info::type_name<T0>();
        let _v1 = vector::empty<string::String>();
        vector::push_back<string::String>(&mut _v1, _v0);
        set_whitelist_reward_tokens(_v1, p0, p1);
    }
    friend fun set_whitelist_reward_tokens(p0: vector<string::String>, p1: address, p2: bool)
        acquires RewardTokenWhitelistPerPool
    {
        assert!(whitelist_length(p1) <= 15, 1);
        if (!exists<RewardTokenWhitelistPerPool>(@0x4bf51972879e3b95c4781a5cdcb9e1ee24ef483e7d22f2d903626f126df62bd1)) {
            let _v0 = package_manager::get_signer();
            let _v1 = &_v0;
            let _v2 = RewardTokenWhitelistPerPool{whitelist: smart_table::new<address, smart_vector::SmartVector<string::String>>()};
            move_to<RewardTokenWhitelistPerPool>(_v1, _v2)
        };
        let _v3 = &mut borrow_global_mut<RewardTokenWhitelistPerPool>(@0x4bf51972879e3b95c4781a5cdcb9e1ee24ef483e7d22f2d903626f126df62bd1).whitelist;
        if (!smart_table::contains<address, smart_vector::SmartVector<string::String>>(freeze(_v3), p1)) {
            let _v4 = smart_vector::new<string::String>();
            smart_table::add<address, smart_vector::SmartVector<string::String>>(_v3, p1, _v4)
        };
        let _v5 = smart_table::borrow_mut<address, smart_vector::SmartVector<string::String>>(_v3, p1);
        let _v6 = &p0;
        let _v7 = 0;
        let _v8 = vector::length<string::String>(_v6);
        'l0: loop {
            'l1: loop {
                if (!(_v7 < _v8)) break 'l0;
                let _v9 = vector::borrow<string::String>(_v6, _v7);
                loop {
                    if (p2 == true) {
                        if (!!smart_vector::contains<string::String>(freeze(_v5), _v9)) break;
                        if (!(smart_vector::length<string::String>(freeze(_v5)) < 15)) break 'l1;
                        let _v10 = *_v9;
                        smart_vector::push_back<string::String>(_v5, _v10);
                        break
                    };
                    let (_v11,_v12) = smart_vector::index_of<string::String>(freeze(_v5), _v9);
                    if (!_v11) break;
                    let _v13 = smart_vector::remove<string::String>(_v5, _v12);
                    break
                };
                _v7 = _v7 + 1;
                continue
            };
            abort 1
        };
    }
    friend fun whitelist_coin<T0>()
        acquires TokenWhitelist
    {
        let _v0 = type_info::type_name<T0>();
        let _v1 = vector::empty<string::String>();
        vector::push_back<string::String>(&mut _v1, _v0);
        add_to_whitelist(_v1);
    }
    public fun whitelist_length(p0: address): u64
        acquires RewardTokenWhitelistPerPool
    {
        if (!exists<RewardTokenWhitelistPerPool>(@0x4bf51972879e3b95c4781a5cdcb9e1ee24ef483e7d22f2d903626f126df62bd1)) {
            let _v0 = package_manager::get_signer();
            let _v1 = &_v0;
            let _v2 = RewardTokenWhitelistPerPool{whitelist: smart_table::new<address, smart_vector::SmartVector<string::String>>()};
            move_to<RewardTokenWhitelistPerPool>(_v1, _v2)
        };
        let _v3 = &borrow_global_mut<RewardTokenWhitelistPerPool>(@0x4bf51972879e3b95c4781a5cdcb9e1ee24ef483e7d22f2d903626f126df62bd1).whitelist;
        if (smart_table::contains<address, smart_vector::SmartVector<string::String>>(_v3, p0) == false) return 0;
        smart_vector::length<string::String>(smart_table::borrow<address, smart_vector::SmartVector<string::String>>(_v3, p0))
    }
    friend fun whitelist_native_fungible_assets(p0: vector<object::Object<fungible_asset::Metadata>>)
        acquires TokenWhitelist
    {
        let _v0 = vector::empty<string::String>();
        let _v1 = p0;
        vector::reverse<object::Object<fungible_asset::Metadata>>(&mut _v1);
        let _v2 = _v1;
        let _v3 = vector::length<object::Object<fungible_asset::Metadata>>(&_v2);
        while (_v3 > 0) {
            let _v4 = vector::pop_back<object::Object<fungible_asset::Metadata>>(&mut _v2);
            let _v5 = &mut _v0;
            let _v6 = coin_wrapper::format_fungible_asset(_v4);
            vector::push_back<string::String>(_v5, _v6);
            _v3 = _v3 - 1;
            continue
        };
        vector::destroy_empty<object::Object<fungible_asset::Metadata>>(_v2);
        add_to_whitelist(_v0);
    }
    public fun whitelisted_reward_token_per_pool(p0: address): vector<string::String>
        acquires RewardTokenWhitelistPerPool
    {
        if (!exists<RewardTokenWhitelistPerPool>(@0x4bf51972879e3b95c4781a5cdcb9e1ee24ef483e7d22f2d903626f126df62bd1)) {
            let _v0 = package_manager::get_signer();
            let _v1 = &_v0;
            let _v2 = RewardTokenWhitelistPerPool{whitelist: smart_table::new<address, smart_vector::SmartVector<string::String>>()};
            move_to<RewardTokenWhitelistPerPool>(_v1, _v2)
        };
        smart_vector::to_vector<string::String>(smart_table::borrow<address, smart_vector::SmartVector<string::String>>(&borrow_global_mut<RewardTokenWhitelistPerPool>(@0x4bf51972879e3b95c4781a5cdcb9e1ee24ef483e7d22f2d903626f126df62bd1).whitelist, p0))
    }
    public fun whitelisted_tokens(): vector<string::String>
        acquires TokenWhitelist
    {
        let _v0 = &borrow_global<TokenWhitelist>(@0x4bf51972879e3b95c4781a5cdcb9e1ee24ef483e7d22f2d903626f126df62bd1).tokens;
        let _v1 = vector::empty<string::String>();
        let _v2 = smart_vector::length<string::String>(_v0);
        let _v3 = 0;
        while (_v3 < _v2) {
            let _v4 = &mut _v1;
            let _v5 = *smart_vector::borrow<string::String>(_v0, _v3);
            vector::push_back<string::String>(_v4, _v5);
            _v3 = _v3 + 1;
            continue
        };
        _v1
    }
}
