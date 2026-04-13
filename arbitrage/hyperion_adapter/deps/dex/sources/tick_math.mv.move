module 0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c::tick_math {
    use 0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c::i32;
    use 0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c::full_math_u128;
    use 0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c::i128;
    fun as_u8(p0: bool): u8 {
        if (p0) return 1u8;
        0u8
    }
    public fun check_tick(p0: i32::I32, p1: i32::I32) {
        assert!(i32::lt(p0, p1), 500001);
        let _v0 = min_tick();
        assert!(i32::gte(p0, _v0), 500002);
        let _v1 = max_tick();
        assert!(i32::lte(p1, _v1), 500003);
    }
    public fun min_tick(): i32::I32 {
        i32::neg_from(443636u32)
    }
    public fun max_tick(): i32::I32 {
        i32::from(443636u32)
    }
    public fun check_tick_spacing(p0: i32::I32, p1: u32) {
        let _v0 = i32::from(p1);
        let _v1 = i32::mod(p0, _v0);
        let _v2 = i32::zero();
        assert!(i32::eq(_v1, _v2), 500006);
    }
    fun get_sqrt_price_at_negative_tick(p0: i32::I32): u128 {
        let _v0;
        let _v1 = i32::as_u32(i32::abs(p0));
        if (_v1 & 1u32 != 0u32) _v0 = 18445821805675392311u128 else _v0 = 18446744073709551616u128;
        if (_v1 & 2u32 != 0u32) _v0 = full_math_u128::mul_shr(_v0, 18444899583751176498u128, 64u8);
        if (_v1 & 4u32 != 0u32) _v0 = full_math_u128::mul_shr(_v0, 18443055278223354162u128, 64u8);
        if (_v1 & 8u32 != 0u32) _v0 = full_math_u128::mul_shr(_v0, 18439367220385604838u128, 64u8);
        if (_v1 & 16u32 != 0u32) _v0 = full_math_u128::mul_shr(_v0, 18431993317065449817u128, 64u8);
        if (_v1 & 32u32 != 0u32) _v0 = full_math_u128::mul_shr(_v0, 18417254355718160513u128, 64u8);
        if (_v1 & 64u32 != 0u32) _v0 = full_math_u128::mul_shr(_v0, 18387811781193591352u128, 64u8);
        if (_v1 & 128u32 != 0u32) _v0 = full_math_u128::mul_shr(_v0, 18329067761203520168u128, 64u8);
        if (_v1 & 256u32 != 0u32) _v0 = full_math_u128::mul_shr(_v0, 18212142134806087854u128, 64u8);
        if (_v1 & 512u32 != 0u32) _v0 = full_math_u128::mul_shr(_v0, 17980523815641551639u128, 64u8);
        if (_v1 & 1024u32 != 0u32) _v0 = full_math_u128::mul_shr(_v0, 17526086738831147013u128, 64u8);
        if (_v1 & 2048u32 != 0u32) _v0 = full_math_u128::mul_shr(_v0, 16651378430235024244u128, 64u8);
        if (_v1 & 4096u32 != 0u32) _v0 = full_math_u128::mul_shr(_v0, 15030750278693429944u128, 64u8);
        if (_v1 & 8192u32 != 0u32) _v0 = full_math_u128::mul_shr(_v0, 12247334978882834399u128, 64u8);
        if (_v1 & 16384u32 != 0u32) _v0 = full_math_u128::mul_shr(_v0, 8131365268884726200u128, 64u8);
        if (_v1 & 32768u32 != 0u32) _v0 = full_math_u128::mul_shr(_v0, 3584323654723342297u128, 64u8);
        if (_v1 & 65536u32 != 0u32) _v0 = full_math_u128::mul_shr(_v0, 696457651847595233u128, 64u8);
        if (_v1 & 131072u32 != 0u32) _v0 = full_math_u128::mul_shr(_v0, 26294789957452057u128, 64u8);
        if (_v1 & 262144u32 != 0u32) _v0 = full_math_u128::mul_shr(_v0, 37481735321082u128, 64u8);
        _v0
    }
    fun get_sqrt_price_at_positive_tick(p0: i32::I32): u128 {
        let _v0;
        let _v1 = i32::as_u32(i32::abs(p0));
        if (_v1 & 1u32 != 0u32) _v0 = 79232123823359799118286999567u128 else _v0 = 79228162514264337593543950336u128;
        if (_v1 & 2u32 != 0u32) _v0 = full_math_u128::mul_shr(_v0, 79236085330515764027303304731u128, 96u8);
        if (_v1 & 4u32 != 0u32) _v0 = full_math_u128::mul_shr(_v0, 79244008939048815603706035061u128, 96u8);
        if (_v1 & 8u32 != 0u32) _v0 = full_math_u128::mul_shr(_v0, 79259858533276714757314932305u128, 96u8);
        if (_v1 & 16u32 != 0u32) _v0 = full_math_u128::mul_shr(_v0, 79291567232598584799939703904u128, 96u8);
        if (_v1 & 32u32 != 0u32) _v0 = full_math_u128::mul_shr(_v0, 79355022692464371645785046466u128, 96u8);
        if (_v1 & 64u32 != 0u32) _v0 = full_math_u128::mul_shr(_v0, 79482085999252804386437311141u128, 96u8);
        if (_v1 & 128u32 != 0u32) _v0 = full_math_u128::mul_shr(_v0, 79736823300114093921829183326u128, 96u8);
        if (_v1 & 256u32 != 0u32) _v0 = full_math_u128::mul_shr(_v0, 80248749790819932309965073892u128, 96u8);
        if (_v1 & 512u32 != 0u32) _v0 = full_math_u128::mul_shr(_v0, 81282483887344747381513967011u128, 96u8);
        if (_v1 & 1024u32 != 0u32) _v0 = full_math_u128::mul_shr(_v0, 83390072131320151908154831281u128, 96u8);
        if (_v1 & 2048u32 != 0u32) _v0 = full_math_u128::mul_shr(_v0, 87770609709833776024991924138u128, 96u8);
        if (_v1 & 4096u32 != 0u32) _v0 = full_math_u128::mul_shr(_v0, 97234110755111693312479820773u128, 96u8);
        if (_v1 & 8192u32 != 0u32) _v0 = full_math_u128::mul_shr(_v0, 119332217159966728226237229890u128, 96u8);
        if (_v1 & 16384u32 != 0u32) _v0 = full_math_u128::mul_shr(_v0, 179736315981702064433883588727u128, 96u8);
        if (_v1 & 32768u32 != 0u32) _v0 = full_math_u128::mul_shr(_v0, 407748233172238350107850275304u128, 96u8);
        if (_v1 & 65536u32 != 0u32) _v0 = full_math_u128::mul_shr(_v0, 2098478828474011932436660412517u128, 96u8);
        if (_v1 & 131072u32 != 0u32) _v0 = full_math_u128::mul_shr(_v0, 55581415166113811149459800483533u128, 96u8);
        if (_v1 & 262144u32 != 0u32) _v0 = full_math_u128::mul_shr(_v0, 38992368544603139932233054999993551u128, 96u8);
        _v0 >> 32u8
    }
    public fun get_sqrt_price_at_tick(p0: i32::I32): u128 {
        let _v0;
        let _v1 = min_tick();
        if (i32::gte(p0, _v1)) {
            let _v2 = max_tick();
            _v0 = i32::lte(p0, _v2)
        } else _v0 = false;
        assert!(_v0, 500004);
        if (i32::is_neg(p0)) return get_sqrt_price_at_negative_tick(p0);
        get_sqrt_price_at_positive_tick(p0)
    }
    public fun get_sqrt_price_at_tick_u32(p0: u32): u128 {
        get_sqrt_price_at_tick(i32::from_u32(p0))
    }
    public fun get_tick_at_sqrt_price(p0: u128): i32::I32 {
        let _v0;
        let _v1;
        if (p0 >= 4295048016u128) _v1 = p0 <= 79226673515401279992447579055u128 else _v1 = false;
        assert!(_v1, 500005);
        let _v2 = p0;
        let _v3 = as_u8(_v2 >= 18446744073709551616u128) << 6u8;
        let _v4 = 0u8 | _v3;
        _v2 = _v2 >> _v3;
        _v3 = as_u8(_v2 >= 4294967296u128) << 5u8;
        let _v5 = _v4 | _v3;
        _v2 = _v2 >> _v3;
        _v3 = as_u8(_v2 >= 65536u128) << 4u8;
        let _v6 = _v5 | _v3;
        _v2 = _v2 >> _v3;
        _v3 = as_u8(_v2 >= 256u128) << 3u8;
        let _v7 = _v6 | _v3;
        _v2 = _v2 >> _v3;
        _v3 = as_u8(_v2 >= 16u128) << 2u8;
        let _v8 = _v7 | _v3;
        _v2 = _v2 >> _v3;
        _v3 = as_u8(_v2 >= 4u128) << 1u8;
        let _v9 = as_u8(_v2 >> _v3 >= 2u128) << 0u8;
        let _v10 = _v8 | _v3 | _v9;
        let _v11 = i128::from(_v10 as u128);
        let _v12 = i128::from(64u128);
        let _v13 = i128::shl(i128::sub(_v11, _v12), 32u8);
        if (_v10 >= 64u8) {
            let _v14 = _v10 - 63u8;
            _v0 = p0 >> _v14
        } else {
            let _v15 = 63u8 - _v10;
            _v0 = p0 << _v15
        };
        _v2 = _v0;
        let _v16 = 31u8;
        while (_v16 >= 18u8) {
            _v2 = _v2 * _v2 >> 63u8;
            _v3 = (_v2 >> 64u8) as u8;
            let _v17 = i128::shl(i128::from(_v3 as u128), _v16);
            _v13 = i128::or(_v13, _v17);
            _v2 = _v2 >> _v3;
            _v16 = _v16 - 1u8;
            continue
        };
        let _v18 = i128::from(59543866431366u128);
        let _v19 = i128::mul(_v13, _v18);
        let _v20 = i128::from(184467440737095516u128);
        let _v21 = i128::as_i32(i128::shr(i128::sub(_v19, _v20), 64u8));
        let _v22 = i128::from(15793534762490258745u128);
        let _v23 = i128::as_i32(i128::shr(i128::add(_v19, _v22), 64u8));
        let _v24 = i32::eq(_v21, _v23);
        loop {
            if (_v24) return _v21 else if (!(get_sqrt_price_at_tick(_v23) <= p0)) break;
            return _v23
        };
        _v21
    }
    public fun is_valid_index(p0: i32::I32, p1: u32): bool {
        let _v0;
        let _v1 = min_tick();
        if (i32::gte(p0, _v1)) {
            let _v2 = max_tick();
            _v0 = i32::lte(p0, _v2)
        } else _v0 = false;
        if (_v0) {
            let _v3 = i32::from(p1);
            let _v4 = i32::mod(p0, _v3);
            let _v5 = i32::from(0u32);
            return _v4 == _v5
        };
        false
    }
    public fun max_sqrt_price(): u128 {
        79226673515401279992447579055u128
    }
    public fun min_sqrt_price(): u128 {
        4295048016u128
    }
    public fun tick_bound(): u32 {
        443636u32
    }
}
