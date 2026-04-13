module 0x661799897c0d2e94c1de976cb3f0e344672c71871e50188622d1b9192723b44c::math {
    public fun safe_mul_div_u64(p0: u64, p1: u64, p2: u64): u64 {
        let _v0 = p0 as u128;
        let _v1 = p1 as u128;
        let _v2 = _v0 * _v1;
        let _v3 = p2 as u128;
        (_v2 / _v3) as u64
    }
}
