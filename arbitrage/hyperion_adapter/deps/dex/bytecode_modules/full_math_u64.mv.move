module 0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c::full_math_u64 {
    use 0x1::error;
    public fun full_mul(p0: u64, p1: u64): u128 {
        let _v0 = p0 as u128;
        let _v1 = p1 as u128;
        _v0 * _v1
    }
    public fun mul_div_ceil(p0: u64, p1: u64, p2: u64): u64 {
        let _v0 = full_mul(p0, p1);
        let _v1 = (p2 as u128) - 1u128;
        let _v2 = _v0 + _v1;
        let _v3 = p2 as u128;
        (_v2 / _v3) as u64
    }
    public fun mul_div_floor(p0: u64, p1: u64, p2: u64): u64 {
        let _v0 = full_mul(p0, p1);
        let _v1 = p2 as u128;
        (_v0 / _v1) as u64
    }
    public fun mul_div_round(p0: u64, p1: u64, p2: u64): u64 {
        let _v0 = error::unavailable(1111111);
        abort _v0
    }
    public fun mul_shl(p0: u64, p1: u64, p2: u8): u64 {
        let _v0 = error::unavailable(1111111);
        abort _v0
    }
    public fun mul_shr(p0: u64, p1: u64, p2: u8): u64 {
        let _v0 = error::unavailable(1111111);
        abort _v0
    }
}
