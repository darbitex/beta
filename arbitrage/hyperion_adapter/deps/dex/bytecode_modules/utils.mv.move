module 0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c::utils {
    use 0x1::object;
    use 0x1::fungible_asset;
    use 0x1::comparator;
    use 0x1::string;
    public fun check_diff_tolerance(p0: u64, p1: u64, p2: u64) {
        'l0: loop {
            loop {
                if (p0 > p1) {
                    if (p0 - p1 <= p2) break;
                    abort 70002
                };
                if (p1 - p0 <= p2) break 'l0;
                abort 70002
            };
            return ()
        };
    }
    public fun is_sorted(p0: object::Object<fungible_asset::Metadata>, p1: object::Object<fungible_asset::Metadata>): bool {
        let _v0 = object::object_address<fungible_asset::Metadata>(&p0);
        let _v1 = object::object_address<fungible_asset::Metadata>(&p1);
        let _v2 = &_v0;
        let _v3 = &_v1;
        let _v4 = comparator::compare<address>(_v2, _v3);
        if (comparator::is_equal(&_v4)) abort 70001;
        let _v5 = &_v0;
        let _v6 = &_v1;
        let _v7 = comparator::compare<address>(_v5, _v6);
        comparator::is_smaller_than(&_v7)
    }
    public fun lp_token_name(p0: object::Object<fungible_asset::Metadata>, p1: object::Object<fungible_asset::Metadata>): string::String {
        let _v0 = string::utf8(vector[76u8, 80u8, 45u8]);
        let _v1 = &mut _v0;
        let _v2 = fungible_asset::symbol<fungible_asset::Metadata>(p0);
        string::append(_v1, _v2);
        string::append_utf8(&mut _v0, vector[45u8]);
        let _v3 = &mut _v0;
        let _v4 = fungible_asset::symbol<fungible_asset::Metadata>(p1);
        string::append(_v3, _v4);
        _v0
    }
    public fun u64_to_u64x64(p0: u64): u128 {
        (p0 as u128) << 64u8
    }
    public fun u64x64_to_u64(p0: u128): u64 {
        (p0 >> 64u8) as u64
    }
}
