module 0x5bc11445584a763c1fa7ed39081f1b920954da14e04b32440cba863d03e19625::u256 {
    struct DU256 has copy, drop, store {
        v0: u64,
        v1: u64,
        v2: u64,
        v3: u64,
        v4: u64,
        v5: u64,
        v6: u64,
        v7: u64,
    }
    struct U256 has copy, drop, store {
        v0: u64,
        v1: u64,
        v2: u64,
        v3: u64,
    }
    public fun add(p0: U256, p1: U256): U256 {
        let _v0 = zero();
        let _v1 = 0;
        let _v2 = 0;
        while (_v2 < 4) {
            let _v3 = get(&p0, _v2);
            let _v4 = get(&p1, _v2);
            let _v5 = _v1 != 0;
            loop {
                if (_v5) {
                    let (_v6,_v7) = overflowing_add(_v3, _v4);
                    let (_v8,_v9) = overflowing_add(_v6, _v1);
                    put(&mut _v0, _v2, _v8);
                    _v1 = 0;
                    if (_v7) _v1 = _v1 + 1;
                    if (!_v9) break;
                    _v1 = _v1 + 1;
                    break
                };
                let (_v10,_v11) = overflowing_add(_v3, _v4);
                put(&mut _v0, _v2, _v10);
                _v1 = 0;
                if (!_v11) break;
                _v1 = 1;
                break
            };
            _v2 = _v2 + 1;
            continue
        };
        assert!(_v1 == 0, 2);
        _v0
    }
    public fun as_u128(p0: U256): u128 {
        let _v0;
        if (*&(&p0).v2 == 0) _v0 = *&(&p0).v3 == 0 else _v0 = false;
        assert!(_v0, 0);
        let _v1 = ((*&(&p0).v1) as u128) << 64u8;
        let _v2 = (*&(&p0).v0) as u128;
        _v1 + _v2
    }
    public fun as_u64(p0: U256): u64 {
        let _v0;
        let _v1;
        if (*&(&p0).v1 == 0) _v0 = *&(&p0).v2 == 0 else _v0 = false;
        if (_v0) _v1 = *&(&p0).v3 == 0 else _v1 = false;
        assert!(_v1, 0);
        *&(&p0).v0
    }
    public fun compare(p0: &U256, p1: &U256): u8 {
        let _v0 = 4;
        'l0: loop {
            let _v1;
            let _v2;
            loop {
                if (!(_v0 > 0)) break 'l0;
                _v0 = _v0 - 1;
                _v2 = get(p0, _v0);
                _v1 = get(p1, _v0);
                if (!(_v2 != _v1)) continue;
                break
            };
            if (_v2 < _v1) return 1u8;
            return 2u8
        };
        0u8
    }
    public fun div(p0: U256, p1: U256): U256 {
        abort 4
    }
    fun du256_to_u256(p0: DU256): (U256, bool) {
        let _v0;
        let _v1;
        let _v2;
        let _v3 = *&(&p0).v0;
        let _v4 = *&(&p0).v1;
        let _v5 = *&(&p0).v2;
        let _v6 = *&(&p0).v3;
        let _v7 = U256{v0: _v3, v1: _v4, v2: _v5, v3: _v6};
        let _v8 = false;
        if (*&(&p0).v4 != 0) _v0 = true else _v0 = *&(&p0).v5 != 0;
        if (_v0) _v2 = true else _v2 = *&(&p0).v6 != 0;
        if (_v2) _v1 = true else _v1 = *&(&p0).v7 != 0;
        if (_v1) _v8 = true;
        (_v7, _v8)
    }
    public fun from_u128(p0: u128): U256 {
        let (_v0,_v1) = split_u128(p0);
        U256{v0: _v1, v1: _v0, v2: 0, v3: 0}
    }
    public fun from_u64(p0: u64): U256 {
        from_u128(p0 as u128)
    }
    public fun get(p0: &U256, p1: u64): u64 {
        let _v0;
        if (p1 == 0) _v0 = *&p0.v0 else {
            let _v1;
            if (p1 == 1) _v1 = *&p0.v1 else {
                let _v2;
                if (p1 == 2) _v2 = *&p0.v2 else if (p1 == 3) _v2 = *&p0.v3 else abort 1;
                _v1 = _v2
            };
            _v0 = _v1
        };
        _v0
    }
    fun get_d(p0: &DU256, p1: u64): u64 {
        let _v0;
        if (p1 == 0) _v0 = *&p0.v0 else {
            let _v1;
            if (p1 == 1) _v1 = *&p0.v1 else {
                let _v2;
                if (p1 == 2) _v2 = *&p0.v2 else {
                    let _v3;
                    if (p1 == 3) _v3 = *&p0.v3 else {
                        let _v4;
                        if (p1 == 4) _v4 = *&p0.v4 else {
                            let _v5;
                            if (p1 == 5) _v5 = *&p0.v5 else {
                                let _v6;
                                if (p1 == 6) _v6 = *&p0.v6 else if (p1 == 7) _v6 = *&p0.v7 else abort 1;
                                _v5 = _v6
                            };
                            _v4 = _v5
                        };
                        _v3 = _v4
                    };
                    _v2 = _v3
                };
                _v1 = _v2
            };
            _v0 = _v1
        };
        _v0
    }
    public fun mul(p0: U256, p1: U256): U256 {
        let _v0 = DU256{v0: 0, v1: 0, v2: 0, v3: 0, v4: 0, v5: 0, v6: 0, v7: 0};
        let _v1 = 0;
        while (_v1 < 4) {
            let _v2 = 0;
            let _v3 = get(&p1, _v1);
            let _v4 = 0;
            loop {
                let _v5;
                if (!(_v4 < 4)) break;
                let _v6 = get(&p0, _v4);
                if (_v6 != 0) _v5 = true else _v5 = _v2 != 0;
                if (_v5) {
                    let _v7;
                    let _v8;
                    let _v9 = _v6 as u128;
                    let _v10 = _v3 as u128;
                    let (_v11,_v12) = split_u128(_v9 * _v10);
                    let _v13 = &_v0;
                    let _v14 = _v1 + _v4;
                    let _v15 = get_d(_v13, _v14);
                    let (_v16,_v17) = overflowing_add(_v12, _v15);
                    let _v18 = &mut _v0;
                    let _v19 = _v1 + _v4;
                    put_d(_v18, _v19, _v16);
                    if (_v17) _v7 = 1 else _v7 = 0;
                    let _v20 = &_v0;
                    let _v21 = _v1 + _v4 + 1;
                    let _v22 = get_d(_v20, _v21);
                    let (_v23,_v24) = overflowing_add(_v11 + _v7, _v2);
                    let (_v25,_v26) = overflowing_add(_v23, _v22);
                    let _v27 = &mut _v0;
                    let _v28 = _v1 + _v4 + 1;
                    put_d(_v27, _v28, _v25);
                    if (_v24 || _v26) _v8 = 1 else _v8 = 0;
                    _v2 = _v8
                };
                _v4 = _v4 + 1;
                continue
            };
            _v1 = _v1 + 1;
            continue
        };
        let (_v29,_v30) = du256_to_u256(_v0);
        if (_v30) abort 2;
        _v29
    }
    fun overflowing_add(p0: u64, p1: u64): (u64, bool) {
        let _v0;
        let _v1;
        let _v2 = p0 as u128;
        let _v3 = p1 as u128;
        let _v4 = _v2 + _v3;
        if (_v4 > 18446744073709551615u128) {
            let _v5 = (_v4 - 18446744073709551615u128 - 1u128) as u64;
            _v0 = true;
            _v1 = _v5
        } else {
            let _v6 = (_v2 + _v3) as u64;
            _v0 = false;
            _v1 = _v6
        };
        (_v1, _v0)
    }
    fun overflowing_sub(p0: u64, p1: u64): (u64, bool) {
        let _v0;
        let _v1;
        if (p0 < p1) {
            let _v2 = p1 - p0;
            let _v3 = (18446744073709551615u128 as u64) - _v2 + 1;
            _v0 = true;
            _v1 = _v3
        } else {
            let _v4 = p0 - p1;
            _v0 = false;
            _v1 = _v4
        };
        (_v1, _v0)
    }
    fun put(p0: &mut U256, p1: u64, p2: u64) {
        if (p1 == 0) {
            let _v0 = &mut p0.v0;
            *_v0 = p2
        } else if (p1 == 1) {
            let _v1 = &mut p0.v1;
            *_v1 = p2
        } else if (p1 == 2) {
            let _v2 = &mut p0.v2;
            *_v2 = p2
        } else if (p1 == 3) {
            let _v3 = &mut p0.v3;
            *_v3 = p2
        } else abort 1;
    }
    fun put_d(p0: &mut DU256, p1: u64, p2: u64) {
        if (p1 == 0) {
            let _v0 = &mut p0.v0;
            *_v0 = p2
        } else if (p1 == 1) {
            let _v1 = &mut p0.v1;
            *_v1 = p2
        } else if (p1 == 2) {
            let _v2 = &mut p0.v2;
            *_v2 = p2
        } else if (p1 == 3) {
            let _v3 = &mut p0.v3;
            *_v3 = p2
        } else if (p1 == 4) {
            let _v4 = &mut p0.v4;
            *_v4 = p2
        } else if (p1 == 5) {
            let _v5 = &mut p0.v5;
            *_v5 = p2
        } else if (p1 == 6) {
            let _v6 = &mut p0.v6;
            *_v6 = p2
        } else if (p1 == 7) {
            let _v7 = &mut p0.v7;
            *_v7 = p2
        } else abort 1;
    }
    public fun shl(p0: U256, p1: u8): U256 {
        let _v0 = zero();
        let _v1 = (p1 as u64) / 64;
        let _v2 = (p1 as u64) % 64;
        let _v3 = _v1;
        while (_v3 < 4) {
            let _v4 = &p0;
            let _v5 = _v3 - _v1;
            let _v6 = get(_v4, _v5);
            let _v7 = _v2 as u8;
            let _v8 = _v6 << _v7;
            put(&mut _v0, _v3, _v8);
            _v3 = _v3 + 1;
            continue
        };
        'l0: while (_v2 > 0) {
            let _v9 = _v1 + 1;
            loop {
                if (!(_v9 < 4)) break 'l0;
                let _v10 = get(&_v0, _v9);
                let _v11 = &p0;
                let _v12 = _v9 - 1 - _v1;
                let _v13 = get(_v11, _v12);
                let _v14 = _v2 as u8;
                let _v15 = 64u8 - _v14;
                let _v16 = _v13 >> _v15;
                let _v17 = _v10 + _v16;
                put(&mut _v0, _v9, _v17);
                _v9 = _v9 + 1;
                continue
            };
            break
        };
        _v0
    }
    public fun shr(p0: U256, p1: u8): U256 {
        let _v0 = zero();
        let _v1 = (p1 as u64) / 64;
        let _v2 = (p1 as u64) % 64;
        let _v3 = _v1;
        while (_v3 < 4) {
            let _v4 = get(&p0, _v3);
            let _v5 = _v2 as u8;
            let _v6 = _v4 >> _v5;
            let _v7 = &mut _v0;
            let _v8 = _v3 - _v1;
            put(_v7, _v8, _v6);
            _v3 = _v3 + 1;
            continue
        };
        'l0: while (_v2 > 0) {
            let _v9 = _v1 + 1;
            loop {
                if (!(_v9 < 4)) break 'l0;
                let _v10 = &_v0;
                let _v11 = _v9 - _v1 - 1;
                let _v12 = get(_v10, _v11);
                let _v13 = get(&p0, _v9);
                let _v14 = _v2 as u8;
                let _v15 = 64u8 - _v14;
                let _v16 = _v13 << _v15;
                let _v17 = _v12 + _v16;
                let _v18 = &mut _v0;
                let _v19 = _v9 - _v1 - 1;
                put(_v18, _v19, _v17);
                _v9 = _v9 + 1;
                continue
            };
            break
        };
        _v0
    }
    fun split_u128(p0: u128): (u64, u64) {
        let _v0 = (p0 >> 64u8) as u64;
        let _v1 = (p0 % 18446744073709551616u128) as u64;
        (_v0, _v1)
    }
    public fun sub(p0: U256, p1: U256): U256 {
        let _v0 = zero();
        let _v1 = 0;
        let _v2 = 0;
        while (_v2 < 4) {
            let _v3 = get(&p0, _v2);
            let _v4 = get(&p1, _v2);
            let _v5 = _v1 != 0;
            loop {
                if (_v5) {
                    let (_v6,_v7) = overflowing_sub(_v3, _v4);
                    let (_v8,_v9) = overflowing_sub(_v6, _v1);
                    put(&mut _v0, _v2, _v8);
                    _v1 = 0;
                    if (_v7) _v1 = _v1 + 1;
                    if (!_v9) break;
                    _v1 = _v1 + 1;
                    break
                };
                let (_v10,_v11) = overflowing_sub(_v3, _v4);
                put(&mut _v0, _v2, _v10);
                _v1 = 0;
                if (!_v11) break;
                _v1 = 1;
                break
            };
            _v2 = _v2 + 1;
            continue
        };
        assert!(_v1 == 0, 2);
        _v0
    }
    public fun zero(): U256 {
        U256{v0: 0, v1: 0, v2: 0, v3: 0}
    }
}
