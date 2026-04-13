module 0x5bc11445584a763c1fa7ed39081f1b920954da14e04b32440cba863d03e19625::guardian_pubkey {
    use 0x1::error;
    use 0x1::option;
    use 0x1::secp256k1;
    use 0x1::vector;
    use 0x5bc11445584a763c1fa7ed39081f1b920954da14e04b32440cba863d03e19625::keccak256;
    struct Address has copy, drop, store, key {
        bytes: vector<u8>,
    }
    public fun from_bytes(p0: vector<u8>): Address {
        if (!(vector::length<u8>(&p0) == 20)) {
            let _v0 = error::invalid_argument(1);
            abort _v0
        };
        Address{bytes: p0}
    }
    public fun from_pubkey(p0: &secp256k1::ECDSARawPublicKey): Address {
        let _v0 = keccak256::keccak256(secp256k1::ecdsa_raw_public_key_to_bytes(p0));
        let _v1 = vector::empty<u8>();
        let _v2 = 0;
        while (_v2 < 20) {
            let _v3 = &mut _v1;
            let _v4 = vector::pop_back<u8>(&mut _v0);
            vector::push_back<u8>(_v3, _v4);
            _v2 = _v2 + 1;
            continue
        };
        vector::reverse<u8>(&mut _v1);
        Address{bytes: _v1}
    }
    public fun from_signature(p0: vector<u8>, p1: u8, p2: &secp256k1::ECDSASignature): Address {
        let _v0 = secp256k1::ecdsa_recover(p0, p1, p2);
        let _v1 = option::extract<secp256k1::ECDSARawPublicKey>(&mut _v0);
        from_pubkey(&_v1)
    }
}
