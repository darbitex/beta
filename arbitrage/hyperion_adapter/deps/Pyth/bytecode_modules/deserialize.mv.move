module 0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387::deserialize {
    use 0x5bc11445584a763c1fa7ed39081f1b920954da14e04b32440cba863d03e19625::cursor;
    use 0x5bc11445584a763c1fa7ed39081f1b920954da14e04b32440cba863d03e19625::deserialize;
    use 0x5bc11445584a763c1fa7ed39081f1b920954da14e04b32440cba863d03e19625::u16;
    use 0x5bc11445584a763c1fa7ed39081f1b920954da14e04b32440cba863d03e19625::u32;
    use 0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387::i64;
    public fun deserialize_i32(p0: &mut cursor::Cursor<u8>): i64::I64 {
        let _v0;
        let _v1 = deserialize_u32(p0);
        if (_v1 >> 31u8 == 1) _v0 = i64::from_u64(18446744069414584320 + _v1) else _v0 = i64::from_u64(_v1);
        _v0
    }
    public fun deserialize_i64(p0: &mut cursor::Cursor<u8>): i64::I64 {
        i64::from_u64(deserialize_u64(p0))
    }
    public fun deserialize_u16(p0: &mut cursor::Cursor<u8>): u64 {
        u16::to_u64(deserialize::deserialize_u16(p0))
    }
    public fun deserialize_u32(p0: &mut cursor::Cursor<u8>): u64 {
        u32::to_u64(deserialize::deserialize_u32(p0))
    }
    public fun deserialize_u64(p0: &mut cursor::Cursor<u8>): u64 {
        deserialize::deserialize_u64(p0)
    }
    public fun deserialize_u8(p0: &mut cursor::Cursor<u8>): u8 {
        deserialize::deserialize_u8(p0)
    }
    public fun deserialize_vector(p0: &mut cursor::Cursor<u8>, p1: u64): vector<u8> {
        deserialize::deserialize_vector(p0, p1)
    }
}
