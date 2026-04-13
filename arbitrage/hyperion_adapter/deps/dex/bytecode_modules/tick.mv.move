module 0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c::tick {
    use 0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c::i128;
    use 0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c::i32;
    use 0x1::error;
    use 0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c::math_u128;
    use 0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c::tick_math;
    use 0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c::liquidity_math;
    use 0x1::event;
    friend 0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c::pool_v3;
    struct TickInfo has copy, drop, store {
        liquidity_gross: u128,
        liquidity_net: i128::I128,
        fee_growth_outside_a: u128,
        fee_growth_outside_b: u128,
        tick_cumulative_outside: u64,
        seconds_per_liquidity_oracle_outside: u128,
        seconds_per_liquidity_incentive_outside: u128,
        emissions_per_liquidity_incentive_outside: vector<u128>,
        seconds_outside: u64,
        initialized: bool,
    }
    struct TickNetGrossUpdate has drop, store {
        tick: i32::I32,
        liquidity_gross_before: u128,
        liquidity_gross_after: u128,
        liquidity_net_before: i128::I128,
        liquidity_net_after: i128::I128,
        flipped: bool,
    }
    struct TickUpdatedEvent has drop, store {
        tick: i32::I32,
        liquidity_gross_before: u128,
        liquidity_gross_after: u128,
        liquidity_net_before: i128::I128,
        liquidity_net_after: i128::I128,
        flipped: bool,
        fee_growth_updated: bool,
        fee_growth_outside_a_before: u128,
        fee_growth_outside_b_before: u128,
        emissions_per_liquidity_incentive_outside_before: vector<u128>,
    }
    struct TickUpdatedEventV2 has drop, store {
        pool_id: address,
        tick: i32::I32,
        liquidity_gross_before: u128,
        liquidity_gross_after: u128,
        liquidity_net_before: i128::I128,
        liquidity_net_after: i128::I128,
        flipped: bool,
        fee_growth_updated: bool,
        fee_growth_outside_a_before: u128,
        fee_growth_outside_b_before: u128,
        emissions_per_liquidity_incentive_outside_before: vector<u128>,
    }
    public fun empty(): TickInfo {
        let _v0 = i128::zero();
        let _v1 = 0x1::vector::empty<u128>();
        TickInfo{liquidity_gross: 0u128, liquidity_net: _v0, fee_growth_outside_a: 0u128, fee_growth_outside_b: 0u128, tick_cumulative_outside: 0, seconds_per_liquidity_oracle_outside: 0u128, seconds_per_liquidity_incentive_outside: 0u128, emissions_per_liquidity_incentive_outside: _v1, seconds_outside: 0, initialized: false}
    }
    friend fun update(p0: &mut TickInfo, p1: i32::I32, p2: u128, p3: u128, p4: u128, p5: u128, p6: vector<u128>, p7: bool, p8: u128, p9: i32::I32, p10: bool): bool {
        let _v0 = error::unavailable(1111111);
        abort _v0
    }
    friend fun cross(p0: &mut TickInfo, p1: u128, p2: u128, p3: u128, p4: u128, p5: u64, p6: vector<u128>, p7: u64): i128::I128 {
        let _v0 = *&p0.fee_growth_outside_a;
        let _v1 = p1 - _v0;
        let _v2 = &mut p0.fee_growth_outside_a;
        *_v2 = _v1;
        let _v3 = *&p0.fee_growth_outside_b;
        let _v4 = p2 - _v3;
        let _v5 = &mut p0.fee_growth_outside_b;
        *_v5 = _v4;
        let _v6 = *&p0.seconds_per_liquidity_oracle_outside;
        let _v7 = p3 - _v6;
        let _v8 = &mut p0.seconds_per_liquidity_oracle_outside;
        *_v8 = _v7;
        let _v9 = *&p0.seconds_per_liquidity_incentive_outside;
        let _v10 = p4 - _v9;
        let _v11 = &mut p0.seconds_per_liquidity_incentive_outside;
        *_v11 = _v10;
        let _v12 = *&p0.tick_cumulative_outside;
        let _v13 = p5 - _v12;
        let _v14 = &mut p0.tick_cumulative_outside;
        *_v14 = _v13;
        let _v15 = *&p0.seconds_outside;
        let _v16 = p7 - _v15;
        let _v17 = &mut p0.seconds_outside;
        *_v17 = _v16;
        p5 = 0x1::vector::length<u128>(&p6);
        let _v18 = 0x1::vector::empty<u128>();
        p7 = 0;
        while (p7 < p5) {
            if (0x1::vector::length<u128>(&p0.emissions_per_liquidity_incentive_outside) > p7) p1 = *0x1::vector::borrow<u128>(&p0.emissions_per_liquidity_incentive_outside, p7) else p1 = 0u128;
            let _v19 = &mut _v18;
            let _v20 = *0x1::vector::borrow<u128>(&p6, p7) - p1;
            0x1::vector::push_back<u128>(_v19, _v20);
            p7 = p7 + 1;
            continue
        };
        let _v21 = &mut p0.emissions_per_liquidity_incentive_outside;
        *_v21 = _v18;
        *&p0.liquidity_net
    }
    friend fun get_emissions_per_liquidity_incentive_inside(p0: TickInfo, p1: TickInfo, p2: i32::I32, p3: i32::I32, p4: i32::I32, p5: vector<u128>): vector<u128> {
        let _v0;
        let _v1;
        let _v2;
        if (i32::gte(p4, p2)) _v2 = *&(&p0).emissions_per_liquidity_incentive_outside else {
            let _v3 = 0x1::vector::empty<u128>();
            let _v4 = 0;
            _v0 = 0x1::vector::length<u128>(&p5);
            while (_v4 < _v0) {
                let _v5 = &mut _v3;
                let _v6 = *0x1::vector::borrow<u128>(&p5, _v4);
                let _v7 = *0x1::vector::borrow<u128>(&(&p0).emissions_per_liquidity_incentive_outside, _v4);
                let _v8 = _v6 - _v7;
                0x1::vector::push_back<u128>(_v5, _v8);
                _v4 = _v4 + 1;
                continue
            };
            _v2 = _v3
        };
        if (i32::lt(p4, p3)) _v1 = *&(&p1).emissions_per_liquidity_incentive_outside else {
            let _v9 = 0x1::vector::empty<u128>();
            _v0 = 0;
            let _v10 = 0x1::vector::length<u128>(&p5);
            while (_v0 < _v10) {
                let _v11 = &mut _v9;
                let _v12 = *0x1::vector::borrow<u128>(&p5, _v0);
                let _v13 = *0x1::vector::borrow<u128>(&(&p1).emissions_per_liquidity_incentive_outside, _v0);
                let _v14 = _v12 - _v13;
                0x1::vector::push_back<u128>(_v11, _v14);
                _v0 = _v0 + 1;
                continue
            };
            _v1 = _v9
        };
        let _v15 = 0x1::vector::empty<u128>();
        _v0 = 0;
        loop {
            let _v16 = 0x1::vector::length<u128>(&p5);
            if (!(_v0 < _v16)) break;
            let _v17 = *0x1::vector::borrow<u128>(&_v2, _v0);
            let _v18 = *0x1::vector::borrow<u128>(&_v1, _v0);
            let _v19 = _v17 + _v18;
            let (_v20,_v21) = math_u128::overflowing_sub(*0x1::vector::borrow<u128>(&p5, _v0), _v19);
            _v19 = _v20;
            0x1::vector::push_back<u128>(&mut _v15, _v19);
            _v0 = _v0 + 1;
            continue
        };
        _v15
    }
    friend fun get_emissions_per_liquidity_outside(p0: &TickInfo): vector<u128> {
        *&p0.emissions_per_liquidity_incentive_outside
    }
    friend fun get_fee_growth_inside(p0: TickInfo, p1: TickInfo, p2: i32::I32, p3: i32::I32, p4: i32::I32, p5: u128, p6: u128): (u128, u128) {
        let _v0;
        let _v1;
        let _v2;
        let _v3;
        if (i32::gte(p4, p2)) {
            _v3 = *&(&p0).fee_growth_outside_a;
            _v2 = *&(&p0).fee_growth_outside_b
        } else {
            let _v4 = *&(&p0).fee_growth_outside_a;
            _v3 = p5 - _v4;
            let _v5 = *&(&p0).fee_growth_outside_b;
            _v2 = p6 - _v5
        };
        if (i32::lt(p4, p3)) {
            _v1 = *&(&p1).fee_growth_outside_a;
            _v0 = *&(&p1).fee_growth_outside_b
        } else {
            let _v6 = *&(&p1).fee_growth_outside_a;
            _v1 = p5 - _v6;
            let _v7 = *&(&p1).fee_growth_outside_b;
            _v0 = p6 - _v7
        };
        let _v8 = _v3 + _v1;
        let _v9 = _v2 + _v0;
        let (_v10,_v11) = math_u128::overflowing_sub(p5, _v8);
        let (_v12,_v13) = math_u128::overflowing_sub(p6, _v9);
        (_v10, _v12)
    }
    friend fun get_liquidity_net(p0: &TickInfo): i128::I128 {
        *&p0.liquidity_net
    }
    friend fun get_seconds_per_liquidity_incentive_inside(p0: TickInfo, p1: TickInfo, p2: i32::I32, p3: i32::I32, p4: i32::I32, p5: u128): u128 {
        let _v0;
        let _v1;
        if (i32::gte(p4, p2)) _v1 = *&(&p0).seconds_per_liquidity_incentive_outside else {
            let _v2 = *&(&p0).seconds_per_liquidity_incentive_outside;
            _v1 = p5 - _v2
        };
        if (i32::lt(p4, p3)) _v0 = *&(&p1).seconds_per_liquidity_incentive_outside else {
            let _v3 = *&(&p1).seconds_per_liquidity_incentive_outside;
            _v0 = p5 - _v3
        };
        let _v4 = _v1 + _v0;
        let (_v5,_v6) = math_u128::overflowing_sub(p5, _v4);
        _v5
    }
    friend fun get_seconds_per_liquidity_oracle_inside(p0: TickInfo, p1: TickInfo, p2: i32::I32, p3: i32::I32, p4: i32::I32, p5: u128): u128 {
        let _v0;
        let _v1;
        if (i32::gte(p4, p2)) _v1 = *&(&p0).seconds_per_liquidity_oracle_outside else {
            let _v2 = *&(&p0).seconds_per_liquidity_oracle_outside;
            _v1 = p5 - _v2
        };
        if (i32::lt(p4, p3)) _v0 = *&(&p1).seconds_per_liquidity_oracle_outside else {
            let _v3 = *&(&p1).seconds_per_liquidity_oracle_outside;
            _v0 = p5 - _v3
        };
        let _v4 = _v1 + _v0;
        let (_v5,_v6) = math_u128::overflowing_sub(p5, _v4);
        _v5
    }
    friend fun padding_emissions_list(p0: &mut TickInfo, p1: u64) {
        let _v0 = 0x1::vector::length<u128>(&p0.emissions_per_liquidity_incentive_outside);
        p1 = p1 - _v0;
        while (p1 != 0) {
            0x1::vector::push_back<u128>(&mut p0.emissions_per_liquidity_incentive_outside, 0u128);
            p1 = p1 - 1
        };
    }
    friend fun tick_spacing_to_max_liquidity_per_tick(p0: u32): u128 {
        let _v0 = tick_math::min_tick();
        let _v1 = i32::from_u32(p0);
        let _v2 = i32::div(_v0, _v1);
        let _v3 = i32::from_u32(p0);
        let _v4 = i32::mul(_v2, _v3);
        let _v5 = tick_math::max_tick();
        let _v6 = i32::from_u32(p0);
        let _v7 = i32::div(_v5, _v6);
        let _v8 = i32::from_u32(p0);
        let _v9 = i32::sub(i32::mul(_v7, _v8), _v4);
        let _v10 = i32::from_u32(p0);
        let _v11 = i32::div(_v9, _v10);
        let _v12 = i32::from(1u32);
        let _v13 = i32::abs_u32(i32::add(_v11, _v12)) as u128;
        MAX_U128 / _v13
    }
    friend fun update_net_and_gross(p0: &mut TickInfo, p1: i32::I32, p2: bool, p3: u128, p4: bool): bool {
        let _v0;
        let _v1 = *&p0.liquidity_gross;
        let _v2 = *&p0.liquidity_net;
        if (p2) {
            let _v3 = liquidity_math::add_delta(*&p0.liquidity_gross, p3);
            let _v4 = &mut p0.liquidity_gross;
            *_v4 = _v3
        } else {
            let _v5 = liquidity_math::sub_delta(*&p0.liquidity_gross, p3);
            let _v6 = &mut p0.liquidity_gross;
            *_v6 = _v5
        };
        loop {
            if (_v1 == 0u128) {
                if (*&p0.liquidity_gross != 0u128) {
                    _v0 = true;
                    break
                };
                _v0 = false;
                break
            };
            if (*&p0.liquidity_gross != 0u128) {
                _v0 = false;
                break
            };
            _v0 = true;
            break
        };
        loop {
            if (p4) {
                if (p2) {
                    let _v7 = *&p0.liquidity_net;
                    let _v8 = i128::from(p3);
                    let _v9 = i128::sub(_v7, _v8);
                    let _v10 = &mut p0.liquidity_net;
                    *_v10 = _v9;
                    break
                };
                let _v11 = *&p0.liquidity_net;
                let _v12 = i128::neg_from(p3);
                let _v13 = i128::sub(_v11, _v12);
                let _v14 = &mut p0.liquidity_net;
                *_v14 = _v13;
                break
            };
            if (p2) {
                let _v15 = *&p0.liquidity_net;
                let _v16 = i128::from(p3);
                let _v17 = i128::add(_v15, _v16);
                let _v18 = &mut p0.liquidity_net;
                *_v18 = _v17;
                break
            };
            let _v19 = *&p0.liquidity_net;
            let _v20 = i128::neg_from(p3);
            let _v21 = i128::add(_v19, _v20);
            let _v22 = &mut p0.liquidity_net;
            *_v22 = _v21;
            break
        };
        let _v23 = *&p0.liquidity_gross;
        let _v24 = *&p0.liquidity_net;
        event::emit<TickNetGrossUpdate>(TickNetGrossUpdate{tick: p1, liquidity_gross_before: _v1, liquidity_gross_after: _v23, liquidity_net_before: _v2, liquidity_net_after: _v24, flipped: _v0});
        _v0
    }
    friend fun update_net_only(p0: &mut TickInfo, p1: i32::I32, p2: bool, p3: u128, p4: bool) {
        let _v0 = *&p0.liquidity_gross;
        let _v1 = *&p0.liquidity_net;
        p3 = p3 * 2u128;
        loop {
            if (p4) {
                if (p2) {
                    let _v2 = *&p0.liquidity_net;
                    let _v3 = i128::from(p3);
                    let _v4 = i128::sub(_v2, _v3);
                    let _v5 = &mut p0.liquidity_net;
                    *_v5 = _v4;
                    break
                };
                let _v6 = *&p0.liquidity_net;
                let _v7 = i128::neg_from(p3);
                let _v8 = i128::sub(_v6, _v7);
                let _v9 = &mut p0.liquidity_net;
                *_v9 = _v8;
                break
            };
            if (p2) {
                let _v10 = *&p0.liquidity_net;
                let _v11 = i128::from(p3);
                let _v12 = i128::add(_v10, _v11);
                let _v13 = &mut p0.liquidity_net;
                *_v13 = _v12;
                break
            };
            let _v14 = *&p0.liquidity_net;
            let _v15 = i128::neg_from(p3);
            let _v16 = i128::add(_v14, _v15);
            let _v17 = &mut p0.liquidity_net;
            *_v17 = _v16;
            break
        };
        let _v18 = *&p0.liquidity_gross;
        let _v19 = *&p0.liquidity_net;
        event::emit<TickNetGrossUpdate>(TickNetGrossUpdate{tick: p1, liquidity_gross_before: _v0, liquidity_gross_after: _v18, liquidity_net_before: _v1, liquidity_net_after: _v19, flipped: false});
    }
    friend fun update_v2(p0: &mut TickInfo, p1: address, p2: i32::I32, p3: u128, p4: u128, p5: u128, p6: u128, p7: vector<u128>, p8: bool, p9: u128, p10: i32::I32, p11: bool): bool {
        let _v0;
        let _v1;
        let _v2 = *&p0.liquidity_gross;
        let _v3 = *&p0.liquidity_net;
        let _v4 = *&p0.fee_growth_outside_a;
        let _v5 = *&p0.fee_growth_outside_b;
        let _v6 = *&p0.emissions_per_liquidity_incentive_outside;
        if (p8) {
            let _v7 = liquidity_math::add_delta(*&p0.liquidity_gross, p9);
            let _v8 = &mut p0.liquidity_gross;
            *_v8 = _v7
        } else {
            let _v9 = liquidity_math::sub_delta(*&p0.liquidity_gross, p9);
            let _v10 = &mut p0.liquidity_gross;
            *_v10 = _v9
        };
        if (_v2 == 0u128) if (i32::lte(p2, p10)) {
            let _v11 = &mut p0.fee_growth_outside_a;
            *_v11 = p3;
            _v11 = &mut p0.fee_growth_outside_b;
            *_v11 = p4;
            _v11 = &mut p0.seconds_per_liquidity_oracle_outside;
            *_v11 = p5;
            _v11 = &mut p0.seconds_per_liquidity_incentive_outside;
            *_v11 = p6;
            let _v12 = &mut p0.emissions_per_liquidity_incentive_outside;
            *_v12 = p7;
            _v1 = true
        } else _v1 = false else _v1 = false;
        let _v13 = &mut p0.initialized;
        *_v13 = true;
        loop {
            if (p11) {
                if (p8) {
                    let _v14 = *&p0.liquidity_net;
                    let _v15 = i128::from(p9);
                    let _v16 = i128::sub(_v14, _v15);
                    let _v17 = &mut p0.liquidity_net;
                    *_v17 = _v16;
                    break
                };
                let _v18 = *&p0.liquidity_net;
                let _v19 = i128::neg_from(p9);
                let _v20 = i128::sub(_v18, _v19);
                let _v21 = &mut p0.liquidity_net;
                *_v21 = _v20;
                break
            };
            if (p8) {
                let _v22 = *&p0.liquidity_net;
                let _v23 = i128::from(p9);
                let _v24 = i128::add(_v22, _v23);
                let _v25 = &mut p0.liquidity_net;
                *_v25 = _v24;
                break
            };
            let _v26 = *&p0.liquidity_net;
            let _v27 = i128::neg_from(p9);
            let _v28 = i128::add(_v26, _v27);
            let _v29 = &mut p0.liquidity_net;
            *_v29 = _v28;
            break
        };
        loop {
            if (_v2 == 0u128) {
                if (*&p0.liquidity_gross != 0u128) {
                    _v0 = true;
                    break
                };
                _v0 = false;
                break
            };
            if (*&p0.liquidity_gross != 0u128) {
                _v0 = false;
                break
            };
            _v0 = true;
            break
        };
        let _v30 = *&p0.liquidity_gross;
        let _v31 = *&p0.liquidity_net;
        event::emit<TickUpdatedEventV2>(TickUpdatedEventV2{pool_id: p1, tick: p2, liquidity_gross_before: _v2, liquidity_gross_after: _v30, liquidity_net_before: _v3, liquidity_net_after: _v31, flipped: _v0, fee_growth_updated: _v1, fee_growth_outside_a_before: _v4, fee_growth_outside_b_before: _v5, emissions_per_liquidity_incentive_outside_before: _v6});
        _v0
    }
}
