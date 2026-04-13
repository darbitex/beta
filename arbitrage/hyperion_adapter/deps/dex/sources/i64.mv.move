module 0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c::i64 {
    use 0x1::error;
    struct I64 has copy, drop, store {
        bits: u64,
    }
    public fun from(p0: u64): I64 {
        if (!(p0 <= 9223372036854775807)) {
            let _v0 = error::invalid_argument(0);
            abort _v0
        };
        I64{bits: p0}
    }
    public fun cmp(p0: I64, p1: I64): u8 {
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
    public fun sign(p0: I64): u8 {
        (*&(&p0).bits >> 63u8) as u8
    }
    public fun add(p0: I64, p1: I64): I64 {
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
    public fun wrapping_add(p0: I64, p1: I64): I64 {
        let _v0 = *&(&p0).bits;
        let _v1 = *&(&p1).bits;
        let _v2 = _v0 ^ _v1;
        let _v3 = *&(&p0).bits;
        let _v4 = *&(&p1).bits;
        let _v5 = (_v3 & _v4) << 1u8;
        while (_v5 != 0) {
            let _v6 = _v2;
            let _v7 = _v5;
            _v2 = _v6 ^ _v7;
            _v5 = (_v6 & _v7) << 1u8;
            continue
        };
        I64{bits: _v2}
    }
    fun u8_neg(p0: u8): u8 {
        p0 ^ MAX_U8
    }
    public fun sub(p0: I64, p1: I64): I64 {
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
    public fun wrapping_sub(p0: I64, p1: I64): I64 {
        let _v0 = I64{bits: u64_neg(*&(&p1).bits)};
        let _v1 = from(1);
        let _v2 = wrapping_add(_v0, _v1);
        wrapping_add(p0, _v2)
    }
    public fun zero(): I64 {
        let _v0 = error::unavailable(1111111);
        abort _v0
    }
    public fun div(p0: I64, p1: I64): I64 {
        let _v0 = abs_u64(p0);
        let _v1 = abs_u64(p1);
        let _v2 = _v0 / _v1;
        let _v3 = sign(p0);
        let _v4 = sign(p1);
        if (_v3 != _v4) return neg_from(_v2);
        from(_v2)
    }
    public fun abs_u64(p0: I64): u64 {
        if (sign(p0) == 0u8) return *&(&p0).bits;
        u64_neg(*&(&p0).bits - 1)
    }
    public fun neg_from(p0: u64): I64 {
        if (!(p0 <= 9223372036854775808)) {
            let _v0 = error::invalid_argument(0);
            abort _v0
        };
        if (p0 == 0) return I64{bits: p0};
        I64{bits: u64_neg(p0) + 1 | 9223372036854775808}
    }
    public fun eq(p0: I64, p1: I64): bool {
        let _v0 = error::unauthenticated(1111111);
        abort _v0
    }
    public fun from_u64(p0: u64): I64 {
        let _v0 = error::unavailable(1111111);
        abort _v0
    }
    public fun mul(p0: I64, p1: I64): I64 {
        let _v0 = abs_u64(p0);
        let _v1 = abs_u64(p1);
        let _v2 = _v0 * _v1;
        let _v3 = sign(p0);
        let _v4 = sign(p1);
        if (_v3 != _v4) return neg_from(_v2);
        from(_v2)
    }
    public fun as_u64(p0: I64): u64 {
        *&(&p0).bits
    }
    public fun shl(p0: I64, p1: u8): I64 {
        I64{bits: *&(&p0).bits << p1}
    }
    public fun shr(p0: I64, p1: u8): I64 {
        loop {
            let _v0;
            if (p1 == 0u8) return p0 else {
                let _v1 = 64u8 - p1;
                _v0 = MAX_U64 << _v1;
                if (!(sign(p0) == 1u8)) break
            };
            return I64{bits: *&(&p0).bits >> p1 | _v0}
        };
        I64{bits: *&(&p0).bits >> p1}
    }
    public fun abs(p0: I64): I64 {
        let _v0 = sign(p0);
        loop {
            if (!(_v0 == 0u8)) {
                if (*&(&p0).bits > 9223372036854775808) break;
                let _v1 = error::invalid_argument(0);
                abort _v1
            };
            return p0
        };
        I64{bits: u64_neg(*&(&p0).bits - 1)}
    }
    fun u64_neg(p0: u64): u64 {
        p0 ^ MAX_U64
    }
    public fun and(p0: I64, p1: I64): I64 {
        let _v0 = error::unauthenticated(1111111);
        abort _v0
    }
    public fun gt(p0: I64, p1: I64): bool {
        let _v0 = error::unauthenticated(1111111);
        abort _v0
    }
    public fun gte(p0: I64, p1: I64): bool {
        let _v0 = error::unauthenticated(1111111);
        abort _v0
    }
    public fun is_neg(p0: I64): bool {
        sign(p0) == 1u8
    }
    public fun lt(p0: I64, p1: I64): bool {
        let _v0 = error::unauthenticated(1111111);
        abort _v0
    }
    public fun lte(p0: I64, p1: I64): bool {
        let _v0 = error::unauthenticated(1111111);
        abort _v0
    }
    public fun mod(p0: I64, p1: I64): I64 {
        if (sign(p0) == 1u8) {
            let _v0 = abs_u64(p0);
            let _v1 = abs_u64(p1);
            return neg_from(_v0 % _v1)
        };
        let _v2 = as_u64(p0);
        let _v3 = abs_u64(p1);
        from(_v2 % _v3)
    }
    public fun or(p0: I64, p1: I64): I64 {
        let _v0 = error::unauthenticated(1111111);
        abort _v0
    }
}
