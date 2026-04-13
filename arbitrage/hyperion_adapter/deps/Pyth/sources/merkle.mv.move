module 0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387::merkle {
    use 0x1::vector;
    use 0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387::keccak160;
    public fun check(p0: &vector<keccak160::Hash>, p1: &keccak160::Hash, p2: vector<u8>): bool {
        let _v0 = 0;
        let _v1 = hash_leaf(p2);
        loop {
            let _v2 = vector::length<keccak160::Hash>(p0);
            if (!(_v0 < _v2)) break;
            let _v3 = &_v1;
            let _v4 = vector::borrow<keccak160::Hash>(p0, _v0);
            _v1 = hash_node(_v3, _v4);
            _v0 = _v0 + 1;
            continue
        };
        &_v1 == p1
    }
    fun hash_leaf(p0: vector<u8>): keccak160::Hash {
        let _v0 = vector::empty<u8>();
        vector::push_back<u8>(&mut _v0, 0u8);
        let _v1 = _v0;
        vector::append<u8>(&mut _v1, p0);
        keccak160::from_data(_v1)
    }
    fun hash_node(p0: &keccak160::Hash, p1: &keccak160::Hash): keccak160::Hash {
        let _v0 = vector::empty<u8>();
        vector::push_back<u8>(&mut _v0, 1u8);
        let _v1 = _v0;
        if (keccak160::is_smaller(p1, p0)) {
            let _v2 = &mut _v1;
            let _v3 = keccak160::get_data(p1);
            vector::append<u8>(_v2, _v3);
            let _v4 = &mut _v1;
            let _v5 = keccak160::get_data(p0);
            vector::append<u8>(_v4, _v5)
        } else {
            let _v6 = &mut _v1;
            let _v7 = keccak160::get_data(p0);
            vector::append<u8>(_v6, _v7);
            let _v8 = &mut _v1;
            let _v9 = keccak160::get_data(p1);
            vector::append<u8>(_v8, _v9)
        };
        keccak160::from_data(_v1)
    }
}
