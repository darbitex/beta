module 0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387::i64 {
    use 0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387::error;
    struct I64 has copy, drop, store {
        negative: bool,
        magnitude: u64,
    }
    public fun from_u64(p0: u64): I64 {
        let _v0 = p0 >> 63u8 == 1;
        new(parse_magnitude(p0, _v0), _v0)
    }
    public fun get_is_negative(p0: &I64): bool {
        *&p0.negative
    }
    public fun get_magnitude_if_negative(p0: &I64): u64 {
        if (!*&p0.negative) {
            let _v0 = error::positive_value();
            abort _v0
        };
        *&p0.magnitude
    }
    public fun get_magnitude_if_positive(p0: &I64): u64 {
        if (!!*&p0.negative) {
            let _v0 = error::negative_value();
            abort _v0
        };
        *&p0.magnitude
    }
    public fun new(p0: u64, p1: bool): I64 {
        let _v0 = 9223372036854775807;
        if (p1) _v0 = 9223372036854775808;
        if (!(p0 <= _v0)) {
            let _v1 = error::magnitude_too_large();
            abort _v1
        };
        if (p0 == 0) p1 = false;
        I64{negative: p1, magnitude: p0}
    }
    fun parse_magnitude(p0: u64, p1: bool): u64 {
        if (!p1) return p0;
        (p0 ^ MAX_U64) + 1
    }
}
