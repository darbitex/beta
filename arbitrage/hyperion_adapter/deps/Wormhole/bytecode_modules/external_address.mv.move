module 0x5bc11445584a763c1fa7ed39081f1b920954da14e04b32440cba863d03e19625::external_address {
    use 0x1::vector;
    use 0x5bc11445584a763c1fa7ed39081f1b920954da14e04b32440cba863d03e19625::cursor;
    use 0x5bc11445584a763c1fa7ed39081f1b920954da14e04b32440cba863d03e19625::deserialize;
    use 0x5bc11445584a763c1fa7ed39081f1b920954da14e04b32440cba863d03e19625::serialize;
    struct ExternalAddress has copy, drop, store {
        external_address: vector<u8>,
    }
    public fun deserialize(p0: &mut cursor::Cursor<u8>): ExternalAddress {
        from_bytes(deserialize::deserialize_vector(p0, 32))
    }
    public fun serialize(p0: &mut vector<u8>, p1: ExternalAddress) {
        let _v0 = *&(&p1).external_address;
        serialize::serialize_vector(p0, _v0);
    }
    public fun from_bytes(p0: vector<u8>): ExternalAddress {
        left_pad(&p0)
    }
    public fun get_bytes(p0: &ExternalAddress): vector<u8> {
        *&p0.external_address
    }
    public fun left_pad(p0: &vector<u8>): ExternalAddress {
        ExternalAddress{external_address: pad_left_32(p0)}
    }
    public fun pad_left_32(p0: &vector<u8>): vector<u8> {
        let _v0 = vector::length<u8>(p0);
        assert!(_v0 <= 32, 0);
        let _v1 = vector::empty<u8>();
        let _v2 = 32 - _v0;
        while (_v2 > 0) {
            vector::push_back<u8>(&mut _v1, 0u8);
            _v2 = _v2 - 1
        };
        let _v3 = &mut _v1;
        let _v4 = *p0;
        vector::append<u8>(_v3, _v4);
        _v1
    }
}
