module 0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387::contract_upgrade_hash {
    use 0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387::error;
    struct Hash has drop, store {
        hash: vector<u8>,
    }
    public fun destroy(p0: Hash): vector<u8> {
        let Hash{hash: _v0} = p0;
        _v0
    }
    public fun from_byte_vec(p0: vector<u8>): Hash {
        if (!(0x1::vector::length<u8>(&p0) == 32)) {
            let _v0 = error::invalid_hash_length();
            abort _v0
        };
        Hash{hash: p0}
    }
}
