module 0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c::i128 {
    use 0x1::error;
    use 0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c::i32;
    use 0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c::i64;
    struct I128 has copy, drop, store {
        bits: u128,
    }
    public fun from(p0: u128): I128 {
        if (!(p0 <= 170141183460469231731687303715884105727u128)) {
            let _v0 = error::invalid_argument(0);
            abort _v0
        };
        I128{bits: p0}
    }
    public fun cmp(p0: I128, p1: I128): u8 {
        let _v0 = *&(&p0).bits;
        let _v1 = *&(&p1).bits;
        'l1: loop {
            'l2: loop {
                'l0: loop {
                    loop {
                        if (!(_v0 == _v1)) {
                            let _v2 = sign(p0);
                            let _v3 = sign(p1);
                            if (_v2 > _v3) break;
                            let _v4 = sign(p0);
                            let _v5 = sign(p1);
                            if (_v4 < _v5) break 'l0;
                            let _v6 = *&(&p0).bits;
                            let _v7 = *&(&p1).bits;
                            if (!(_v6 > _v7)) break 'l1;
                            break 'l2
                        };
                        return 1u8
                    };
                    return 0u8
                };
                return 2u8
            };
            return 2u8
        };
        0u8
    }
    public fun sign(p0: I128): u8 {
        (*&(&p0).bits >> 127u8) as u8
    }
    public fun add(p0: I128, p1: I128): I128 {
        let _v0 = wrapping_add(p0, p1);
        let _v1 = sign(p0);
        let _v2 = sign(p1);
        let _v3 = u8_neg(sign(_v0));
        let _v4 = u8_neg(sign(p0));
        let _v5 = u8_neg(sign(p1));
        let _v6 = sign(_v0);
        if (!((_v1 & _v2 & _v3) + (_v4 & _v5 & _v6) == 0u8)) {
            let _v7 = error::invalid_argument(0);
            abort _v7
        };
        _v0
    }
    public fun wrapping_add(p0: I128, p1: I128): I128 {
        let _v0 = *&(&p0).bits;
        let _v1 = *&(&p1).bits;
        let _v2 = _v0 ^ _v1;
        let _v3 = *&(&p0).bits;
        let _v4 = *&(&p1).bits;
        let _v5 = (_v3 & _v4) << 1u8;
        while (_v5 != 0u128) {
            let _v6 = _v2;
            let _v7 = _v5;
            _v2 = _v6 ^ _v7;
            _v5 = (_v6 & _v7) << 1u8;
            continue
        };
        I128{bits: _v2}
    }
    fun u8_neg(p0: u8): u8 {
        p0 ^ MAX_U8
    }
    public fun sub(p0: I128, p1: I128): I128 {
        let _v0;
        let _v1 = wrapping_sub(p0, p1);
        let _v2 = sign(p0);
        let _v3 = sign(p1);
        if (_v2 != _v3) {
            let _v4 = sign(p0);
            let _v5 = sign(_v1);
            _v0 = _v4 != _v5
        } else _v0 = false;
        if (_v0) abort 0;
        _v1
    }
    public fun wrapping_sub(p0: I128, p1: I128): I128 {
        let _v0 = I128{bits: u128_neg(*&(&p1).bits)};
        let _v1 = from(1u128);
        let _v2 = wrapping_add(_v0, _v1);
        wrapping_add(p0, _v2)
    }
    public fun zero(): I128 {
        I128{bits: 0u128}
    }
    public fun div(p0: I128, p1: I128): I128 {
        let _v0 = abs_u128(p0);
        let _v1 = abs_u128(p1);
        let _v2 = _v0 / _v1;
        let _v3 = sign(p0);
        let _v4 = sign(p1);
        if (_v3 != _v4) return neg_from(_v2);
        from(_v2)
    }
    public fun abs_u128(p0: I128): u128 {
        if (sign(p0) == 0u8) return *&(&p0).bits;
        u128_neg(*&(&p0).bits - 1u128)
    }
    public fun neg_from(p0: u128): I128 {
        if (!(p0 <= 170141183460469231731687303715884105728u128)) {
            let _v0 = error::invalid_argument(0);
            abort _v0
        };
        if (p0 == 0u128) return I128{bits: p0};
        I128{bits: u128_neg(p0) + 1u128 | 170141183460469231731687303715884105728u128}
    }
    public fun eq(p0: I128, p1: I128): bool {
        let _v0 = *&(&p0).bits;
        let _v1 = *&(&p1).bits;
        _v0 == _v1
    }
    public fun mul(p0: I128, p1: I128): I128 {
        let _v0 = abs_u128(p0);
        let _v1 = abs_u128(p1);
        let _v2 = _v0 * _v1;
        let _v3 = sign(p0);
        let _v4 = sign(p1);
        if (_v3 != _v4) return neg_from(_v2);
        from(_v2)
    }
    public fun neg(p0: I128): I128 {
        let _v0 = error::unavailable(1111111);
        abort _v0
    }
    public fun as_u128(p0: I128): u128 {
        *&(&p0).bits
    }
    public fun overflowing_add(p0: I128, p1: I128): (I128, bool) {
        let _v0 = wrapping_add(p0, p1);
        let _v1 = sign(p0);
        let _v2 = sign(p1);
        let _v3 = u8_neg(sign(_v0));
        let _v4 = u8_neg(sign(p0));
        let _v5 = u8_neg(sign(p1));
        let _v6 = sign(_v0);
        let _v7 = (_v1 & _v2 & _v3) + (_v4 & _v5 & _v6);
        (_v0, _v7 != 0u8)
    }
    public fun overflowing_sub(p0: I128, p1: I128): (I128, bool) {
        let _v0 = error::unavailable(1111111);
        abort _v0
    }
    public fun shl(p0: I128, p1: u8): I128 {
        I128{bits: *&(&p0).bits << p1}
    }
    public fun shr(p0: I128, p1: u8): I128 {
        loop {
            let _v0;
            if (p1 == 0u8) return p0 else {
                let _v1 = 128u8 - p1;
                _v0 = MAX_U128 << _v1;
                if (!(sign(p0) == 1u8)) break
            };
            return I128{bits: *&(&p0).bits >> p1 | _v0}
        };
        I128{bits: *&(&p0).bits >> p1}
    }
    public fun abs(p0: I128): I128 {
        let _v0 = sign(p0);
        loop {
            if (!(_v0 == 0u8)) {
                if (*&(&p0).bits > 170141183460469231731687303715884105728u128) break;
                let _v1 = error::invalid_argument(0);
                abort _v1
            };
            return p0
        };
        I128{bits: u128_neg(*&(&p0).bits - 1u128)}
    }
    fun u128_neg(p0: u128): u128 {
        p0 ^ MAX_U128
    }
    public fun and(p0: I128, p1: I128): I128 {
        let _v0 = error::unavailable(1111111);
        abort _v0
    }
    public fun gt(p0: I128, p1: I128): bool {
        cmp(p0, p1) == 2u8
    }
    public fun gte(p0: I128, p1: I128): bool {
        cmp(p0, p1) >= 1u8
    }
    public fun is_neg(p0: I128): bool {
        sign(p0) == 1u8
    }
    public fun lt(p0: I128, p1: I128): bool {
        cmp(p0, p1) == 0u8
    }
    public fun lte(p0: I128, p1: I128): bool {
        cmp(p0, p1) <= 1u8
    }
    public fun or(p0: I128, p1: I128): I128 {
        let _v0 = *&(&p0).bits;
        let _v1 = *&(&p1).bits;
        I128{bits: _v0 | _v1}
    }
    public fun as_i32(p0: I128): i32::I32 {
        if (is_neg(p0)) return i32::neg_from(abs_u128(p0) as u32);
        i32::from(abs_u128(p0) as u32)
    }
    public fun as_i64(p0: I128): i64::I64 {
        let _v0 = error::unavailable(1111111);
        abort _v0
    }
}
