module 0xd6e31e55a750d442bcfb60bbf842d152b102ffa5ac3ae3f2c8b43748c36a3e6f::package_manager {
    use 0x1::object;
    use 0x1::signer;
    use 0x1::error;
    use 0x1::vector;
    friend 0xd6e31e55a750d442bcfb60bbf842d152b102ffa5ac3ae3f2c8b43748c36a3e6f::permission_control;
    friend 0xd6e31e55a750d442bcfb60bbf842d152b102ffa5ac3ae3f2c8b43748c36a3e6f::xrion;
    friend 0xd6e31e55a750d442bcfb60bbf842d152b102ffa5ac3ae3f2c8b43748c36a3e6f::reward;
    struct Manager has store, key {
        ext: object::ExtendRef,
        admin: vector<address>,
    }
    public entry fun add_admin(p0: &signer, p1: address)
        acquires Manager
    {
        ensure_admin(signer::address_of(p0));
        let _v0 = get_rion_address();
        let _v1 = borrow_global_mut<Manager>(_v0);
        let _v2 = &_v1.admin;
        let _v3 = false;
        let _v4 = 0;
        let _v5 = vector::length<address>(_v2);
        'l0: loop {
            loop {
                if (!(_v4 < _v5)) break 'l0;
                if (*vector::borrow<address>(_v2, _v4) == p1) break;
                _v4 = _v4 + 1
            };
            _v3 = true;
            break
        };
        if (_v3) {
            let _v6 = error::aborted(2);
            abort _v6
        };
        vector::push_back<address>(&mut _v1.admin, p1);
    }
    public fun ensure_admin(p0: address)
        acquires Manager
    {
        let _v0 = get_rion_address();
        let _v1 = &borrow_global<Manager>(_v0).admin;
        let _v2 = false;
        let _v3 = 0;
        let _v4 = vector::length<address>(_v1);
        'l0: loop {
            loop {
                if (!(_v3 < _v4)) break 'l0;
                if (*vector::borrow<address>(_v1, _v3) == p0) break;
                _v3 = _v3 + 1
            };
            _v2 = true;
            break
        };
        if (!_v2) {
            let _v5 = error::aborted(1);
            abort _v5
        };
    }
    friend fun get_rion_address(): address {
        let _v0 = @0xd6e31e55a750d442bcfb60bbf842d152b102ffa5ac3ae3f2c8b43748c36a3e6f;
        object::create_object_address(&_v0, vector[115u8, 101u8, 101u8, 100u8])
    }
    friend fun get_rion_signer(): signer
        acquires Manager
    {
        let _v0 = get_rion_address();
        object::generate_signer_for_extending(&borrow_global<Manager>(_v0).ext)
    }
    fun init_module(p0: &signer) {
        let _v0 = object::create_named_object(p0, vector[115u8, 101u8, 101u8, 100u8]);
        let _v1 = &_v0;
        let _v2 = object::generate_signer(_v1);
        let _v3 = &_v2;
        let _v4 = Manager{ext: object::generate_extend_ref(_v1), admin: vector[@0xd6e31e55a750d442bcfb60bbf842d152b102ffa5ac3ae3f2c8b43748c36a3e6f, @0xd548f6e8ef91c57e7983b1051df686a3753f3d453d37ef781782450e61079fe9]};
        move_to<Manager>(_v3, _v4);
    }
    friend fun is_admin(p0: &signer): bool
        acquires Manager
    {
        let _v0 = get_rion_address();
        let _v1 = &borrow_global<Manager>(_v0).admin;
        let _v2 = false;
        let _v3 = 0;
        let _v4 = vector::length<address>(_v1);
        'l0: loop {
            loop {
                if (!(_v3 < _v4)) break 'l0;
                let _v5 = *vector::borrow<address>(_v1, _v3);
                let _v6 = signer::address_of(p0);
                if (_v5 == _v6) break;
                _v3 = _v3 + 1;
                continue
            };
            _v2 = true;
            break
        };
        _v2
    }
    public entry fun remove_admin(p0: &signer, p1: address)
        acquires Manager
    {
        ensure_admin(signer::address_of(p0));
        let _v0 = get_rion_address();
        let _v1 = borrow_global_mut<Manager>(_v0);
        let _v2 = &_v1.admin;
        let _v3 = false;
        let _v4 = 0;
        let _v5 = 0;
        let _v6 = vector::length<address>(_v2);
        'l0: loop {
            loop {
                if (!(_v5 < _v6)) break 'l0;
                if (*vector::borrow<address>(_v2, _v5) == p1) break;
                _v5 = _v5 + 1
            };
            _v3 = true;
            _v4 = _v5;
            break
        };
        if (!(vector::length<address>(&_v1.admin) > 2)) {
            let _v7 = error::aborted(4);
            abort _v7
        };
        if (!_v3) {
            let _v8 = error::aborted(3);
            abort _v8
        };
        let _v9 = vector::remove<address>(&mut _v1.admin, _v4);
    }
}
