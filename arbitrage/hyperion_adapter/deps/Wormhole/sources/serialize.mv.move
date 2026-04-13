module 0x5bc11445584a763c1fa7ed39081f1b920954da14e04b32440cba863d03e19625::serialize {
    use 0x1::bcs;
    use 0x1::vector;
    use 0x5bc11445584a763c1fa7ed39081f1b920954da14e04b32440cba863d03e19625::u16;
    use 0x5bc11445584a763c1fa7ed39081f1b920954da14e04b32440cba863d03e19625::u256;
    use 0x5bc11445584a763c1fa7ed39081f1b920954da14e04b32440cba863d03e19625::u32;
    public fun serialize_u128(p0: &mut vector<u8>, p1: u128) {
        let _v0 = bcs::to_bytes<u128>(&p1);
        vector::reverse<u8>(&mut _v0);
        vector::append<u8>(p0, _v0);
    }
    public fun serialize_u16(p0: &mut vector<u8>, p1: u16::U16) {
        let (_v0,_v1) = u16::split_u8(p1);
        serialize_u8(p0, _v0);
        serialize_u8(p0, _v1);
    }
    public fun serialize_u256(p0: &mut vector<u8>, p1: u256::U256) {
        let _v0 = bcs::to_bytes<u256::U256>(&p1);
        vector::reverse<u8>(&mut _v0);
        vector::append<u8>(p0, _v0);
    }
    public fun serialize_u32(p0: &mut vector<u8>, p1: u32::U32) {
        let (_v0,_v1,_v2,_v3) = u32::split_u8(p1);
        serialize_u8(p0, _v0);
        serialize_u8(p0, _v1);
        serialize_u8(p0, _v2);
        serialize_u8(p0, _v3);
    }
    public fun serialize_u64(p0: &mut vector<u8>, p1: u64) {
        let _v0 = bcs::to_bytes<u64>(&p1);
        vector::reverse<u8>(&mut _v0);
        vector::append<u8>(p0, _v0);
    }
    public fun serialize_u8(p0: &mut vector<u8>, p1: u8) {
        vector::push_back<u8>(p0, p1);
    }
    public fun serialize_vector(p0: &mut vector<u8>, p1: vector<u8>) {
        vector::append<u8>(p0, p1);
    }
}
