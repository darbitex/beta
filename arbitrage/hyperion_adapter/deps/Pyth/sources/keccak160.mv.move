module 0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387::keccak160 {
    use 0x1::aptos_hash;
    use 0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387::error;
    struct Hash has drop {
        data: vector<u8>,
    }
    public fun from_data(p0: vector<u8>): Hash {
        let _v0 = aptos_hash::keccak256(p0);
        while (0x1::vector::length<u8>(&_v0) > 20) {
            let _v1 = 0x1::vector::pop_back<u8>(&mut _v0);
            continue
        };
        new(_v0)
    }
    public fun get_data(p0: &Hash): vector<u8> {
        *&p0.data
    }
    public fun get_hash_length(): u64 {
        20
    }
    public fun is_smaller(p0: &Hash, p1: &Hash): bool {
        let _v0 = 0;
        'l0: loop {
            let _v1;
            let _v2;
            loop {
                let _v3 = get_data(p0);
                let _v4 = 0x1::vector::length<u8>(&_v3);
                if (!(_v0 < _v4)) break 'l0;
                let _v5 = get_data(p0);
                _v2 = *0x1::vector::borrow<u8>(&_v5, _v0);
                let _v6 = get_data(p1);
                _v1 = *0x1::vector::borrow<u8>(&_v6, _v0);
                if (_v2 != _v1) break;
                _v0 = _v0 + 1;
                continue
            };
            return _v2 < _v1
        };
        false
    }
    public fun new(p0: vector<u8>): Hash {
        if (!(0x1::vector::length<u8>(&p0) == 20)) {
            let _v0 = error::invalid_keccak160_length();
            abort _v0
        };
        Hash{data: p0}
    }
}
