module 0xd6e31e55a750d442bcfb60bbf842d152b102ffa5ac3ae3f2c8b43748c36a3e6f::permission_control {
    use 0x1::string;
    use 0x1::smart_table;
    use 0xd6e31e55a750d442bcfb60bbf842d152b102ffa5ac3ae3f2c8b43748c36a3e6f::package_manager;
    use 0x1::signer;
    use 0x1::error;
    use 0x1::vector;
    use 0xd6e31e55a750d442bcfb60bbf842d152b102ffa5ac3ae3f2c8b43748c36a3e6f::send_event;
    friend 0xd6e31e55a750d442bcfb60bbf842d152b102ffa5ac3ae3f2c8b43748c36a3e6f::xrion;
    friend 0xd6e31e55a750d442bcfb60bbf842d152b102ffa5ac3ae3f2c8b43748c36a3e6f::reward;
    struct FunctionInfo has copy, drop, store {
        function_name: string::String,
        module_name: string::String,
    }
    enum Level has copy, drop, store {
        User,
        Manager,
        Bot,
        Urgent,
    }
    struct Permission has store, key {
        fun_list: smart_table::SmartTable<FunctionInfo, Level>,
        level_list: smart_table::SmartTable<Level, vector<address>>,
    }
    fun init_module(p0: &signer) {
        let _v0 = package_manager::get_rion_signer();
        p0 = &_v0;
        let _v1 = smart_table::new<FunctionInfo, Level>();
        let _v2 = smart_table::new<Level, vector<address>>();
        let _v3 = Permission{fun_list: _v1, level_list: _v2};
        move_to<Permission>(p0, _v3);
    }
    public entry fun adjustment_permission(p0: &signer, p1: string::String, p2: string::String, p3: u8)
        acquires Permission
    {
        package_manager::ensure_admin(signer::address_of(p0));
        let _v0 = package_manager::get_rion_address();
        let _v1 = borrow_global_mut<Permission>(_v0);
        let _v2 = get_function_info(p1, p2);
        if (!smart_table::contains<FunctionInfo, Level>(&_v1.fun_list, _v2)) {
            let _v3 = error::aborted(1);
            abort _v3
        };
        if (!(p3 <= 3u8)) {
            let _v4 = error::aborted(2);
            abort _v4
        };
        let _v5 = smart_table::borrow<FunctionInfo, Level>(&_v1.fun_list, _v2);
        let _v6 = get_level(p3);
        let _v7 = &_v6;
        if (!(_v5 != _v7)) {
            let _v8 = error::aborted(3);
            abort _v8
        };
        let _v9 = get_level(p3);
        let _v10 = smart_table::borrow_mut<FunctionInfo, Level>(&mut _v1.fun_list, _v2);
        *_v10 = _v9;
    }
    public fun get_function_info(p0: string::String, p1: string::String): FunctionInfo {
        FunctionInfo{function_name: p0, module_name: p1}
    }
    fun get_level(p0: u8): Level {
        let _v0;
        if (p0 == 0u8) _v0 = Level::Bot{} else if (p0 == 1u8) _v0 = Level::Manager{} else if (p0 == 2u8) _v0 = Level::User{} else if (p0 == 3u8) _v0 = Level::Urgent{} else abort 2;
        _v0
    }
    friend fun assignment_function_level(p0: &signer, p1: FunctionInfo, p2: u8)
        acquires Permission
    {
        package_manager::ensure_admin(signer::address_of(p0));
        let _v0 = package_manager::get_rion_address();
        let _v1 = borrow_global_mut<Permission>(_v0);
        if (smart_table::contains<FunctionInfo, Level>(&_v1.fun_list, p1)) {
            let _v2 = error::aborted(6);
            abort _v2
        };
        let _v3 = &mut _v1.fun_list;
        let _v4 = get_level(p2);
        smart_table::add<FunctionInfo, Level>(_v3, p1, _v4);
        let _v5 = &_v1.level_list;
        let _v6 = get_level(p2);
        if (!smart_table::contains<Level, vector<address>>(_v5, _v6)) {
            let _v7 = &mut _v1.level_list;
            let _v8 = get_level(p2);
            let _v9 = vector::empty<address>();
            smart_table::add<Level, vector<address>>(_v7, _v8, _v9)
        };
    }
    public entry fun assignment_level(p0: &signer, p1: string::String, p2: string::String, p3: u8)
        acquires Permission
    {
        package_manager::ensure_admin(signer::address_of(p0));
        if (!(p3 <= 3u8)) {
            let _v0 = error::aborted(2);
            abort _v0
        };
        let _v1 = package_manager::get_rion_address();
        let _v2 = borrow_global_mut<Permission>(_v1);
        let _v3 = get_function_info(p1, p2);
        if (smart_table::contains<FunctionInfo, Level>(&_v2.fun_list, _v3)) {
            let _v4 = error::aborted(6);
            abort _v4
        };
        let _v5 = &mut _v2.fun_list;
        let _v6 = get_level(p3);
        smart_table::add<FunctionInfo, Level>(_v5, _v3, _v6);
    }
    public entry fun assignment_manager(p0: &signer, p1: u8, p2: address)
        acquires Permission
    {
        package_manager::ensure_admin(signer::address_of(p0));
        if (!(p1 <= 3u8)) {
            let _v0 = error::aborted(2);
            abort _v0
        };
        let _v1 = package_manager::get_rion_address();
        let _v2 = borrow_global_mut<Permission>(_v1);
        let _v3 = &_v2.level_list;
        let _v4 = get_level(p1);
        if (!smart_table::contains<Level, vector<address>>(_v3, _v4)) {
            let _v5 = error::aborted(2);
            abort _v5
        };
        let _v6 = &_v2.level_list;
        let _v7 = get_level(p1);
        let _v8 = smart_table::borrow<Level, vector<address>>(_v6, _v7);
        let _v9 = &p2;
        if (vector::contains<address>(_v8, _v9)) {
            let _v10 = error::aborted(7);
            abort _v10
        };
        let _v11 = &mut _v2.level_list;
        let _v12 = get_level(p1);
        vector::push_back<address>(smart_table::borrow_mut<Level, vector<address>>(_v11, _v12), p2);
    }
    public fun check_permission(p0: &signer, p1: FunctionInfo)
        acquires Permission
    {
        let _v0 = package_manager::get_rion_address();
        let _v1 = borrow_global<Permission>(_v0);
        let _v2 = signer::address_of(p0);
        let _v3 = *&(&p1).function_name;
        let _v4 = *&(&p1).module_name;
        send_event::send_permission_event(_v2, _v3, _v4);
        let _v5 = package_manager::is_admin(p0);
        loop {
            if (_v5) () else if (smart_table::contains<FunctionInfo, Level>(&_v1.fun_list, p1)) {
                let _v6 = smart_table::borrow<FunctionInfo, Level>(&_v1.fun_list, p1);
                if (_v6 is Bot) ensure_caller_has_level(p0, 0u8, _v1) else if (_v6 is Manager) ensure_caller_has_level(p0, 1u8, _v1) else if (_v6 is User) break else if (_v6 is Urgent) ensure_caller_has_level(p0, 3u8, _v1) else abort 14566554180833181697
            } else {
                let _v7 = error::aborted(1);
                abort _v7
            };
            return ()
        };
    }
    fun ensure_caller_has_level(p0: &signer, p1: u8, p2: &Permission) {
        let _v0 = &p2.level_list;
        let _v1 = get_level(p1);
        if (!smart_table::contains<Level, vector<address>>(_v0, _v1)) {
            let _v2 = error::aborted(2);
            abort _v2
        };
        let _v3 = &p2.level_list;
        let _v4 = get_level(p1);
        let _v5 = smart_table::borrow<Level, vector<address>>(_v3, _v4);
        let _v6 = false;
        let _v7 = 0;
        let _v8 = vector::length<address>(_v5);
        'l0: loop {
            loop {
                if (!(_v7 < _v8)) break 'l0;
                let _v9 = *vector::borrow<address>(_v5, _v7);
                let _v10 = signer::address_of(p0);
                if (_v9 == _v10) break;
                _v7 = _v7 + 1;
                continue
            };
            _v6 = true;
            break
        };
        let _v11 = _v6;
        loop {
            if (p1 == 0u8) {
                if (_v11) break;
                let _v12 = error::aborted(4);
                abort _v12
            };
            if (p1 == 1u8) {
                if (_v11) break;
                let _v13 = error::aborted(5);
                abort _v13
            };
            assert!(p1 == 3u8, 2);
            if (_v11) break;
            let _v14 = error::aborted(9);
            abort _v14
        };
    }
    public entry fun confiscate_level(p0: &signer, p1: string::String, p2: string::String)
        acquires Permission
    {
        package_manager::ensure_admin(signer::address_of(p0));
        let _v0 = package_manager::get_rion_address();
        let _v1 = borrow_global_mut<Permission>(_v0);
        let _v2 = get_function_info(p1, p2);
        if (!smart_table::contains<FunctionInfo, Level>(&_v1.fun_list, _v2)) {
            let _v3 = error::aborted(1);
            abort _v3
        };
        let _v4 = smart_table::remove<FunctionInfo, Level>(&mut _v1.fun_list, _v2);
    }
    public entry fun confiscate_manager(p0: &signer, p1: u8, p2: address)
        acquires Permission
    {
        package_manager::ensure_admin(signer::address_of(p0));
        let _v0 = package_manager::get_rion_address();
        let _v1 = borrow_global_mut<Permission>(_v0);
        let _v2 = &_v1.level_list;
        let _v3 = get_level(p1);
        if (!smart_table::contains<Level, vector<address>>(_v2, _v3)) {
            let _v4 = error::aborted(2);
            abort _v4
        };
        let _v5 = &mut _v1.level_list;
        let _v6 = get_level(p1);
        let _v7 = freeze(smart_table::borrow_mut<Level, vector<address>>(_v5, _v6));
        let _v8 = false;
        let _v9 = 0;
        let _v10 = 0;
        let _v11 = vector::length<address>(_v7);
        'l0: loop {
            loop {
                if (!(_v10 < _v11)) break 'l0;
                let _v12 = vector::borrow<address>(_v7, _v10);
                let _v13 = &p2;
                if (_v12 == _v13) break;
                _v10 = _v10 + 1;
                continue
            };
            _v8 = true;
            _v9 = _v10;
            break
        };
        if (!_v8) {
            let _v14 = error::aborted(8);
            abort _v14
        };
        let _v15 = &mut _v1.level_list;
        let _v16 = get_level(p1);
        let _v17 = vector::remove<address>(smart_table::borrow_mut<Level, vector<address>>(_v15, _v16), _v9);
    }
}
