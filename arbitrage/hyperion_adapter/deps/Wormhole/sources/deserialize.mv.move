module 0x5bc11445584a763c1fa7ed39081f1b920954da14e04b32440cba863d03e19625::deserialize {
    use 0x5bc11445584a763c1fa7ed39081f1b920954da14e04b32440cba863d03e19625::cursor;
    use 0x5bc11445584a763c1fa7ed39081f1b920954da14e04b32440cba863d03e19625::u16;
    use 0x5bc11445584a763c1fa7ed39081f1b920954da14e04b32440cba863d03e19625::u256;
    use 0x5bc11445584a763c1fa7ed39081f1b920954da14e04b32440cba863d03e19625::u32;
    public fun deserialize_u128(p0: &mut cursor::Cursor<u8>): u128 {
        let _v0 = 0u128;
        let _v1 = 0;
        while (_v1 < 16) {
            let _v2 = cursor::poke<u8>(p0);
            let _v3 = _v0 << 8u8;
            let _v4 = _v2 as u128;
            _v0 = _v3 + _v4;
            _v1 = _v1 + 1;
            continue
        };
        _v0
    }
    public fun deserialize_u16(p0: &mut cursor::Cursor<u8>): u16::U16 {
        let _v0 = 0;
        let _v1 = 0;
        while (_v1 < 2) {
            let _v2 = cursor::poke<u8>(p0);
            let _v3 = _v0 << 8u8;
            let _v4 = _v2 as u64;
            _v0 = _v3 + _v4;
            _v1 = _v1 + 1;
            continue
        };
        u16::from_u64(_v0)
    }
    public fun deserialize_u256(p0: &mut cursor::Cursor<u8>): u256::U256 {
        let _v0 = deserialize_u128(p0);
        let _v1 = deserialize_u128(p0);
        let _v2 = u256::shl(u256::from_u128(_v0), 128u8);
        let _v3 = u256::from_u128(_v1);
        u256::add(_v2, _v3)
    }
    public fun deserialize_u32(p0: &mut cursor::Cursor<u8>): u32::U32 {
        let _v0 = 0;
        let _v1 = 0;
        while (_v1 < 4) {
            let _v2 = cursor::poke<u8>(p0);
            let _v3 = _v0 << 8u8;
            let _v4 = _v2 as u64;
            _v0 = _v3 + _v4;
            _v1 = _v1 + 1;
            continue
        };
        u32::from_u64(_v0)
    }
    public fun deserialize_u64(p0: &mut cursor::Cursor<u8>): u64 {
        let _v0 = 0;
        let _v1 = 0;
        while (_v1 < 8) {
            let _v2 = cursor::poke<u8>(p0);
            let _v3 = _v0 << 8u8;
            let _v4 = _v2 as u64;
            _v0 = _v3 + _v4;
            _v1 = _v1 + 1;
            continue
        };
        _v0
    }
    public fun deserialize_u8(p0: &mut cursor::Cursor<u8>): u8 {
        cursor::poke<u8>(p0)
    }
    public fun deserialize_vector(p0: &mut cursor::Cursor<u8>, p1: u64): vector<u8> {
        let _v0 = 0x1::vector::empty<u8>();
        while (p1 > 0) {
            let _v1 = &mut _v0;
            let _v2 = cursor::poke<u8>(p0);
            0x1::vector::push_back<u8>(_v1, _v2);
            p1 = p1 - 1;
            continue
        };
        _v0
    }
}
