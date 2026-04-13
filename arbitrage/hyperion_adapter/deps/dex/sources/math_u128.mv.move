module 0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c::math_u128 {
    use 0x1::error;
    public fun max(p0: u128, p1: u128): u128 {
        let _v0 = error::unavailable(11111111);
        abort _v0
    }
    public fun min(p0: u128, p1: u128): u128 {
        let _v0 = error::unavailable(11111111);
        abort _v0
    }
    public fun overflowing_add(p0: u128, p1: u128): (u128, bool) {
        let _v0 = p0 as u256;
        let _v1 = p1 as u256;
        let _v2 = _v0 + _v1;
        if (_v2 > 340282366920938463463374607431768211455u256) return ((_v2 & 340282366920938463463374607431768211455u256) as u128, true);
        (_v2 as u128, false)
    }
    public fun overflowing_sub(p0: u128, p1: u128): (u128, bool) {
        if (p0 >= p1) return (p0 - p1, false);
        (MAX_U128 - p1 + p0 + 1u128, true)
    }
    public fun hi(p0: u128): u64 {
        let _v0 = error::unavailable(11111111);
        abort _v0
    }
    public fun full_mul(p0: u128, p1: u128): (u128, u128) {
        let _v0 = p0 as u256;
        let _v1 = p1 as u256;
        let _v2 = _v0 * _v1;
        p0 = ((_v2 & 115792089237316195423570985008687907852929702298719625575994209400481361428480u256) >> 128u8) as u128;
        ((_v2 & 340282366920938463463374607431768211455u256) as u128, p0)
    }
    public fun wrapping_add(p0: u128, p1: u128): u128 {
        let _v0 = error::unavailable(11111111);
        abort _v0
    }
    public fun wrapping_sub(p0: u128, p1: u128): u128 {
        let _v0 = error::unavailable(11111111);
        abort _v0
    }
    public fun add_check(p0: u128, p1: u128): bool {
        let _v0 = error::unavailable(11111111);
        abort _v0
    }
    public fun checked_div_round(p0: u128, p1: u128, p2: bool): u128 {
        if (p1 == 0u128) abort 1;
        let _v0 = p0 / p1;
        p0 = p0 % p1;
        if (p2) p2 = p0 > 0u128 else p2 = false;
        if (p2) return _v0 + 1u128;
        _v0
    }
    public fun from_lo_hi(p0: u64, p1: u64): u128 {
        let _v0 = error::unavailable(11111111);
        abort _v0
    }
    public fun hi_u128(p0: u128): u128 {
        let _v0 = error::unavailable(11111111);
        abort _v0
    }
    public fun lo(p0: u128): u64 {
        let _v0 = error::unavailable(11111111);
        abort _v0
    }
    public fun lo_u128(p0: u128): u128 {
        let _v0 = error::unavailable(11111111);
        abort _v0
    }
    public fun overflowing_mul(p0: u128, p1: u128): (u128, bool) {
        let (_v0,_v1) = full_mul(p0, p1);
        p1 = _v0;
        if (_v1 > 0u128) return (p1, true);
        (p1, false)
    }
    public fun wrapping_mul(p0: u128, p1: u128): u128 {
        let (_v0,_v1) = overflowing_mul(p0, p1);
        _v0
    }
}
