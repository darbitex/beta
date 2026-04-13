module 0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c::bit_math {
    public fun least_significant_bit(p0: u256): u8 {
        let _v0 = MAX_U8;
        if (p0 & 340282366920938463463374607431768211455u256 > 0u256) _v0 = _v0 - 128u8 else p0 = p0 >> 128u8;
        if (p0 & 18446744073709551615u256 > 0u256) _v0 = _v0 - 64u8 else p0 = p0 >> 64u8;
        if (p0 & 4294967295u256 > 0u256) _v0 = _v0 - 32u8 else p0 = p0 >> 32u8;
        if (p0 & 65535u256 > 0u256) _v0 = _v0 - 16u8 else p0 = p0 >> 16u8;
        if (p0 & 255u256 > 0u256) _v0 = _v0 - 8u8 else p0 = p0 >> 8u8;
        if (p0 & 15u256 > 0u256) _v0 = _v0 - 4u8 else p0 = p0 >> 4u8;
        if (p0 & 3u256 > 0u256) _v0 = _v0 - 2u8 else p0 = p0 >> 2u8;
        if (p0 & 1u256 > 0u256) _v0 = _v0 - 1u8;
        _v0
    }
    public fun most_significant_bit(p0: u256): u8 {
        let _v0 = 0u8;
        if (p0 >= 340282366920938463463374607431768211456u256) {
            p0 = p0 >> 128u8;
            _v0 = _v0 + 128u8
        };
        if (p0 >= 18446744073709551616u256) {
            p0 = p0 >> 64u8;
            _v0 = _v0 + 64u8
        };
        if (p0 >= 4294967296u256) {
            p0 = p0 >> 32u8;
            _v0 = _v0 + 32u8
        };
        if (p0 >= 65536u256) {
            p0 = p0 >> 16u8;
            _v0 = _v0 + 16u8
        };
        if (p0 >= 256u256) {
            p0 = p0 >> 8u8;
            _v0 = _v0 + 8u8
        };
        if (p0 >= 16u256) {
            p0 = p0 >> 4u8;
            _v0 = _v0 + 4u8
        };
        if (p0 >= 4u256) {
            p0 = p0 >> 2u8;
            _v0 = _v0 + 2u8
        };
        if (p0 >= 2u256) _v0 = _v0 + 1u8;
        _v0
    }
}
