module 0x5bc11445584a763c1fa7ed39081f1b920954da14e04b32440cba863d03e19625::u16 {
    struct U16 has copy, drop, store, key {
        number: u64,
    }
    fun check_overflow(p0: &U16) {
        assert!(*&p0.number <= 65535, 0);
    }
    public fun from_u64(p0: u64): U16 {
        let _v0 = U16{number: p0};
        check_overflow(&_v0);
        _v0
    }
    public fun split_u8(p0: U16): (u8, u8) {
        let U16{number: _v0} = p0;
        let _v1 = _v0;
        let _v2 = ((_v1 >> 8u8) % 256) as u8;
        let _v3 = (_v1 % 256) as u8;
        (_v2, _v3)
    }
    public fun to_u64(p0: U16): u64 {
        *&(&p0).number
    }
}
