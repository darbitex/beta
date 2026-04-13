module 0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c::tick_bitmap {
    use 0x1::table;
    use 0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c::i32;
    use 0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c::bit_math;
    friend 0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c::pool_v3;
    struct BitMap has store {
        map: table::Table<i32::I32, u256>,
    }
    public fun new(): BitMap {
        BitMap{map: table::new<i32::I32, u256>()}
    }
    fun position(p0: i32::I32): (i32::I32, u8) {
        let _v0 = i32::shr(p0, 8u8);
        let _v1 = i32::from_u32(256u32);
        let _v2 = i32::mul(_v0, _v1);
        p0 = i32::sub(p0, _v2);
        assert!(i32::sign(p0) == 0u8, 600002);
        let _v3 = i32::abs_u32(p0) as u8;
        (_v0, _v3)
    }
    friend fun flip_tick(p0: &mut BitMap, p1: i32::I32, p2: u32) {
        let _v0 = i32::from(p2);
        let _v1 = i32::mod(p1, _v0);
        let _v2 = i32::zero();
        assert!(i32::eq(_v1, _v2), 600001);
        let _v3 = i32::from_u32(p2);
        let (_v4,_v5) = position(i32::div(p1, _v3));
        let _v6 = _v4;
        let _v7 = 1u256 << _v5;
        if (!table::contains<i32::I32, u256>(&p0.map, _v6)) table::add<i32::I32, u256>(&mut p0.map, _v6, 0u256);
        let _v8 = table::borrow_mut<i32::I32, u256>(&mut p0.map, _v6);
        *_v8 = *_v8 ^ _v7;
    }
    friend fun next_initialized_tick_within_one_word(p0: &BitMap, p1: i32::I32, p2: u32, p3: bool): (i32::I32, bool) {
        let _v0;
        let _v1;
        let _v2;
        let _v3 = i32::from_u32(p2);
        let _v4 = i32::div(p1, _v3);
        if (i32::sign(p1) == 1u8) {
            let _v5 = i32::from_u32(p2);
            _v2 = i32::abs_u32(i32::mod(p1, _v5)) != 0u32
        } else _v2 = false;
        if (_v2) {
            let _v6 = i32::neg_from(1u32);
            _v4 = i32::add(_v4, _v6)
        };
        'l0: loop {
            loop {
                let _v7;
                let _v8;
                let _v9;
                let _v10;
                if (p3) {
                    let (_v11,_v12) = position(_v4);
                    _v10 = _v12;
                    _v9 = _v11;
                    let _v13 = (1u256 << _v10) - 1u256;
                    let _v14 = 1u256 << _v10;
                    let _v15 = _v13 + _v14;
                    if (table::contains<i32::I32, u256>(&p0.map, _v9)) _v8 = *table::borrow<i32::I32, u256>(&p0.map, _v9) else _v8 = 0u256;
                    _v7 = _v8 & _v15;
                    _v1 = _v7 != 0u256;
                    if (_v1) {
                        let _v16 = i32::from_u32(_v10 as u32);
                        let _v17 = i32::from_u32(bit_math::most_significant_bit(_v7) as u32);
                        let _v18 = i32::sub(_v16, _v17);
                        let _v19 = i32::sub(_v4, _v18);
                        let _v20 = i32::from_u32(p2);
                        _v0 = i32::mul(_v19, _v20);
                        break
                    };
                    let _v21 = i32::from_u32(_v10 as u32);
                    let _v22 = i32::sub(_v4, _v21);
                    let _v23 = i32::from_u32(p2);
                    _v0 = i32::mul(_v22, _v23);
                    break
                };
                let _v24 = i32::from_u32(1u32);
                let (_v25,_v26) = position(i32::add(_v4, _v24));
                _v10 = _v26;
                _v9 = _v25;
                let _v27 = (1u256 << _v10) - 1u256;
                if (table::contains<i32::I32, u256>(&p0.map, _v9)) _v8 = *table::borrow<i32::I32, u256>(&p0.map, _v9) else _v8 = 0u256;
                _v7 = _v8 & (MAX_U256 ^ _v27);
                _v1 = _v7 != 0u256;
                if (_v1) {
                    let _v28 = i32::from_u32(1u32);
                    let _v29 = i32::add(_v4, _v28);
                    let _v30 = i32::from_u32(bit_math::least_significant_bit(_v7) as u32);
                    let _v31 = i32::from_u32(_v10 as u32);
                    let _v32 = i32::sub(_v30, _v31);
                    let _v33 = i32::add(_v29, _v32);
                    let _v34 = i32::from_u32(p2);
                    _v0 = i32::mul(_v33, _v34);
                    break 'l0
                };
                let _v35 = i32::from_u32(1u32);
                let _v36 = i32::add(_v4, _v35);
                let _v37 = i32::from_u32(255u32);
                let _v38 = i32::from_u32(_v10 as u32);
                let _v39 = i32::sub(_v37, _v38);
                let _v40 = i32::add(_v36, _v39);
                let _v41 = i32::from_u32(p2);
                _v0 = i32::mul(_v40, _v41);
                break 'l0
            };
            return (_v0, _v1)
        };
        (_v0, _v1)
    }
}
