module 0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387::contract_upgrade {
    use 0x1::aptos_hash;
    use 0x1::code;
    use 0x1::vector;
    use 0x5bc11445584a763c1fa7ed39081f1b920954da14e04b32440cba863d03e19625::cursor;
    use 0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387::contract_upgrade_hash;
    use 0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387::deserialize;
    use 0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387::error;
    use 0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387::state;
    friend 0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387::governance;
    struct AuthorizeContractUpgrade {
        hash: contract_upgrade_hash::Hash,
    }
    public entry fun do_contract_upgrade(p0: vector<u8>, p1: vector<vector<u8>>) {
        let _v0 = state::get_contract_upgrade_authorized_hash();
        if (!matches_hash(p1, p0, _v0)) {
            let _v1 = error::invalid_upgrade_hash();
            abort _v1
        };
        let _v2 = state::pyth_signer();
        code::publish_package_txn(&_v2, p0, p1);
    }
    friend fun execute(p0: vector<u8>) {
        let AuthorizeContractUpgrade{hash: _v0} = from_byte_vec(p0);
        state::set_contract_upgrade_authorized_hash(_v0);
    }
    fun from_byte_vec(p0: vector<u8>): AuthorizeContractUpgrade {
        let _v0 = cursor::init<u8>(p0);
        let _v1 = contract_upgrade_hash::from_byte_vec(deserialize::deserialize_vector(&mut _v0, 32));
        cursor::destroy_empty<u8>(_v0);
        AuthorizeContractUpgrade{hash: _v1}
    }
    fun matches_hash(p0: vector<vector<u8>>, p1: vector<u8>, p2: contract_upgrade_hash::Hash): bool {
        let _v0 = p0;
        vector::reverse<vector<u8>>(&mut _v0);
        let _v1 = aptos_hash::keccak256(p1);
        while (!vector::is_empty<vector<u8>>(&_v0)) {
            let _v2 = &mut _v1;
            let _v3 = aptos_hash::keccak256(vector::pop_back<vector<u8>>(&mut _v0));
            vector::append<u8>(_v2, _v3);
            continue
        };
        let _v4 = aptos_hash::keccak256(_v1);
        let _v5 = contract_upgrade_hash::destroy(p2);
        _v4 == _v5
    }
}
