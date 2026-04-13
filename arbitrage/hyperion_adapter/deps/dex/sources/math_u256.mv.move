module 0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c::math_u256 {
    use 0x1::error;
    public fun add_check(p0: u256, p1: u256): bool {
        let _v0 = error::unavailable(11111111);
        abort _v0
    }
    public fun checked_shlw(p0: u256): (u256, bool) {
        if (p0 >= 6277101735386680763835789423207666416102355444464034512896u256) return (0u256, true);
        (p0 << 64u8, false)
    }
    public fun div_mod(p0: u256, p1: u256): (u256, u256) {
        let _v0 = error::unavailable(11111111);
        abort _v0
    }
    public fun div_round(p0: u256, p1: u256, p2: bool): u256 {
        let _v0 = p0 / p1;
        if (p2) p2 = _v0 * p1 != p0 else p2 = false;
        if (p2) return _v0 + 1u256;
        _v0
    }
    public fun shlw(p0: u256): u256 {
        let _v0 = error::unavailable(11111111);
        abort _v0
    }
    public fun shrw(p0: u256): u256 {
        let _v0 = error::unavailable(11111111);
        abort _v0
    }
}
