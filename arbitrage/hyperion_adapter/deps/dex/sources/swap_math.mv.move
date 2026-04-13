module 0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c::swap_math {
    use 0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c::full_math_u64;
    use 0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c::i32;
    use 0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c::tick_math;
    use 0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c::full_math_u128;
    use 0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c::math_u256;
    use 0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c::math_u128;
    public fun compute_swap_step(p0: u128, p1: u128, p2: u128, p3: u64, p4: u64, p5: bool, p6: bool): (u64, u64, u128, u64) {
        let _v0 = p1;
        let _v1 = 0;
        let _v2 = 0;
        let _v3 = 0;
        loop {
            if (!(p2 == 0u128)) {
                let _v4;
                loop {
                    if (p5) {
                        if (p0 >= p1) break;
                        abort 4
                    };
                    if (p0 < p1) break;
                    abort 4
                };
                if (p6) {
                    let _v5 = 1000000 - p4;
                    let _v6 = full_math_u64::mul_div_floor(p3, _v5, 1000000);
                    _v4 = get_delta_up_from_input(p0, p1, p2, p5);
                    let _v7 = _v6 as u256;
                    if (_v4 > _v7) {
                        _v1 = _v6;
                        _v3 = p3 - _v6;
                        _v0 = get_next_sqrt_price_from_input(p0, p2, _v6, p5)
                    } else {
                        _v1 = _v4 as u64;
                        let _v8 = 1000000 - p4;
                        _v3 = full_math_u64::mul_div_ceil(_v1, p4, _v8);
                        _v0 = p1
                    };
                    _v2 = get_delta_down_from_output(p0, _v0, p2, p5) as u64;
                    break
                };
                _v4 = get_delta_down_from_output(p0, p1, p2, p5);
                let _v9 = p3 as u256;
                if (_v4 > _v9) {
                    _v2 = p3;
                    _v0 = get_next_sqrt_price_from_output(p0, p2, p3, p5)
                } else {
                    _v2 = _v4 as u64;
                    _v0 = p1
                };
                _v1 = get_delta_up_from_input(p0, _v0, p2, p5) as u64;
                let _v10 = 1000000 - p4;
                _v3 = full_math_u64::mul_div_ceil(_v1, p4, _v10);
                break
            };
            return (_v1, _v2, _v0, _v3)
        };
        (_v1, _v2, _v0, _v3)
    }
    public fun get_delta_up_from_input(p0: u128, p1: u128, p2: u128, p3: bool): u256 {
        let _v0;
        let _v1;
        let _v2;
        if (p0 > p1) _v1 = p0 - p1 else _v1 = p1 - p0;
        if (_v1 == 0u128) _v0 = true else _v0 = p2 == 0u128;
        'l0: loop {
            'l1: loop {
                loop {
                    if (!_v0) {
                        if (p3) {
                            let (_v3,_v4) = math_u256::checked_shlw(full_math_u128::full_mul(p2, _v1));
                            _v2 = _v3;
                            if (!_v4) break;
                            abort 2
                        };
                        _v2 = full_math_u128::full_mul(p2, _v1);
                        if (!(_v2 & 18446744073709551615u256 > 0u256)) break 'l0;
                        break 'l1
                    };
                    return 0u256
                };
                let _v5 = full_math_u128::full_mul(p0, p1);
                return math_u256::div_round(_v2, _v5, true)
            };
            return (_v2 >> 64u8) + 1u256
        };
        _v2 >> 64u8
    }
    public fun get_next_sqrt_price_from_input(p0: u128, p1: u128, p2: u64, p3: bool): u128 {
        if (p3) return get_next_sqrt_price_a_up(p0, p1, p2, true);
        get_next_sqrt_price_b_down(p0, p1, p2, true)
    }
    public fun get_delta_down_from_output(p0: u128, p1: u128, p2: u128, p3: bool): u256 {
        let _v0;
        let _v1;
        let _v2;
        if (p0 > p1) _v1 = p0 - p1 else _v1 = p1 - p0;
        if (_v1 == 0u128) _v0 = true else _v0 = p2 == 0u128;
        'l0: loop {
            loop {
                if (!_v0) {
                    if (p3) break;
                    let (_v3,_v4) = math_u256::checked_shlw(full_math_u128::full_mul(p2, _v1));
                    _v2 = _v3;
                    if (!_v4) break 'l0;
                    abort 2
                };
                return 0u256
            };
            return full_math_u128::full_mul(p2, _v1) >> 64u8
        };
        let _v5 = full_math_u128::full_mul(p0, p1);
        math_u256::div_round(_v2, _v5, false)
    }
    public fun get_next_sqrt_price_from_output(p0: u128, p1: u128, p2: u64, p3: bool): u128 {
        if (p3) return get_next_sqrt_price_b_down(p0, p1, p2, false);
        get_next_sqrt_price_a_up(p0, p1, p2, false)
    }
    public fun fee_rate_denominator(): u64 {
        1000000
    }
    public fun get_amount_by_liquidity(p0: i32::I32, p1: i32::I32, p2: i32::I32, p3: u128, p4: u128, p5: bool): (u64, u64) {
        let _v0;
        let _v1;
        loop {
            if (!(p4 == 0u128)) {
                let _v2 = tick_math::get_sqrt_price_at_tick(p0);
                let _v3 = tick_math::get_sqrt_price_at_tick(p1);
                if (i32::lt(p2, p0)) {
                    _v1 = get_delta_a(_v2, _v3, p4, p5);
                    _v0 = 0;
                    break
                };
                if (i32::lt(p2, p1)) {
                    _v1 = get_delta_a(p3, _v3, p4, p5);
                    _v0 = get_delta_b(_v2, p3, p4, p5);
                    break
                };
                _v1 = 0;
                _v0 = get_delta_b(_v2, _v3, p4, p5);
                break
            };
            return (0, 0)
        };
        (_v1, _v0)
    }
    public fun get_delta_a(p0: u128, p1: u128, p2: u128, p3: bool): u64 {
        let _v0;
        let _v1;
        let _v2;
        if (p0 > p1) _v1 = p0 - p1 else _v1 = p1 - p0;
        if (_v1 == 0u128) _v0 = true else _v0 = p2 == 0u128;
        loop {
            if (!_v0) {
                let (_v3,_v4) = math_u256::checked_shlw(full_math_u128::full_mul(p2, _v1));
                _v2 = _v3;
                if (!_v4) break;
                abort 2
            };
            return 0
        };
        let _v5 = full_math_u128::full_mul(p0, p1);
        math_u256::div_round(_v2, _v5, p3) as u64
    }
    public fun get_delta_b(p0: u128, p1: u128, p2: u128, p3: bool): u64 {
        let _v0;
        let _v1;
        let _v2;
        if (p0 > p1) _v2 = p0 - p1 else _v2 = p1 - p0;
        if (_v2 == 0u128) _v1 = true else _v1 = p2 == 0u128;
        loop {
            if (_v1) return 0 else {
                let _v3;
                _v0 = full_math_u128::full_mul(p2, _v2);
                if (p3) _v3 = _v0 & 18446744073709551615u256 > 0u256 else _v3 = false;
                if (!_v3) break
            };
            return ((_v0 >> 64u8) + 1u256) as u64
        };
        (_v0 >> 64u8) as u64
    }
    public fun get_liquidity_by_amount(p0: i32::I32, p1: i32::I32, p2: i32::I32, p3: u128, p4: u64, p5: bool): (u128, u64, u64) {
        let _v0;
        let _v1 = tick_math::get_sqrt_price_at_tick(p0);
        let _v2 = tick_math::get_sqrt_price_at_tick(p1);
        let _v3 = 0;
        let _v4 = 0;
        loop {
            if (p5) {
                _v3 = p4;
                if (i32::lt(p2, p0)) {
                    _v0 = get_liquidity_from_a(_v1, _v2, p4, false);
                    break
                };
                assert!(i32::lt(p2, p1), 3018);
                _v0 = get_liquidity_from_a(p3, _v2, p4, false);
                _v4 = get_delta_b(p3, _v1, _v0, true);
                break
            };
            _v4 = p4;
            if (i32::gte(p2, p1)) {
                _v0 = get_liquidity_from_b(_v1, _v2, p4, false);
                break
            };
            assert!(i32::gte(p2, p0), 3018);
            _v0 = get_liquidity_from_b(_v1, p3, p4, false);
            _v3 = get_delta_a(p3, _v2, _v0, true);
            break
        };
        (_v0, _v3, _v4)
    }
    public fun get_liquidity_from_a(p0: u128, p1: u128, p2: u64, p3: bool): u128 {
        let _v0;
        if (p0 > p1) _v0 = p0 - p1 else _v0 = p1 - p0;
        let _v1 = full_math_u128::full_mul(p0, p1) >> 64u8;
        let _v2 = p2 as u256;
        let _v3 = _v1 * _v2;
        let _v4 = _v0 as u256;
        math_u256::div_round(_v3, _v4, p3) as u128
    }
    public fun get_liquidity_from_b(p0: u128, p1: u128, p2: u64, p3: bool): u128 {
        let _v0;
        if (p0 > p1) _v0 = p0 - p1 else _v0 = p1 - p0;
        let _v1 = (p2 as u256) << 64u8;
        let _v2 = _v0 as u256;
        math_u256::div_round(_v1, _v2, p3) as u128
    }
    public fun get_next_sqrt_price_a_up(p0: u128, p1: u128, p2: u64, p3: bool): u128 {
        loop {
            if (!(p2 == 0)) {
                let (_v0,_v1) = math_u256::checked_shlw(full_math_u128::full_mul(p0, p1));
                let _v2 = _v0;
                if (_v1) abort 2;
                let _v3 = (p1 as u256) << 64u8;
                let _v4 = p2 as u128;
                let _v5 = full_math_u128::full_mul(p0, _v4);
                if (p3) {
                    let _v6 = _v3 + _v5;
                    p0 = math_u256::div_round(_v2, _v6, true) as u128
                } else {
                    let _v7 = _v3 - _v5;
                    p0 = math_u256::div_round(_v2, _v7, true) as u128
                };
                let _v8 = tick_math::max_sqrt_price();
                if (p0 > _v8) abort 0;
                let _v9 = tick_math::min_sqrt_price();
                if (!(p0 < _v9)) break;
                abort 1
            };
            return p0
        };
        p0
    }
    public fun get_next_sqrt_price_b_down(p0: u128, p1: u128, p2: u64, p3: bool): u128 {
        let _v0;
        p1 = math_u128::checked_div_round((p2 as u128) << 64u8, p1, !p3);
        if (p3) _v0 = p0 + p1 else _v0 = p0 - p1;
        let _v1 = tick_math::max_sqrt_price();
        if (_v0 > _v1) abort 0;
        let _v2 = tick_math::min_sqrt_price();
        if (_v0 < _v2) abort 1;
        _v0
    }
}
