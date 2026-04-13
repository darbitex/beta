module 0x5bc11445584a763c1fa7ed39081f1b920954da14e04b32440cba863d03e19625::vaa {
    use 0x1::secp256k1;
    use 0x5bc11445584a763c1fa7ed39081f1b920954da14e04b32440cba863d03e19625::cursor;
    use 0x5bc11445584a763c1fa7ed39081f1b920954da14e04b32440cba863d03e19625::deserialize;
    use 0x5bc11445584a763c1fa7ed39081f1b920954da14e04b32440cba863d03e19625::external_address;
    use 0x5bc11445584a763c1fa7ed39081f1b920954da14e04b32440cba863d03e19625::guardian_pubkey;
    use 0x5bc11445584a763c1fa7ed39081f1b920954da14e04b32440cba863d03e19625::keccak256;
    use 0x5bc11445584a763c1fa7ed39081f1b920954da14e04b32440cba863d03e19625::state;
    use 0x5bc11445584a763c1fa7ed39081f1b920954da14e04b32440cba863d03e19625::structs;
    use 0x5bc11445584a763c1fa7ed39081f1b920954da14e04b32440cba863d03e19625::u16;
    use 0x5bc11445584a763c1fa7ed39081f1b920954da14e04b32440cba863d03e19625::u32;
    friend 0x5bc11445584a763c1fa7ed39081f1b920954da14e04b32440cba863d03e19625::contract_upgrade;
    friend 0x5bc11445584a763c1fa7ed39081f1b920954da14e04b32440cba863d03e19625::guardian_set_upgrade;
    struct VAA {
        guardian_set_index: u32::U32,
        signatures: vector<structs::Signature>,
        timestamp: u32::U32,
        nonce: u32::U32,
        emitter_chain: u16::U16,
        emitter_address: external_address::ExternalAddress,
        sequence: u64,
        consistency_level: u8,
        hash: vector<u8>,
        payload: vector<u8>,
    }
    public fun assert_governance(p0: &VAA) {
        let _v0 = state::get_current_guardian_set_index();
        assert!(*&p0.guardian_set_index == _v0, 8);
        let _v1 = *&p0.emitter_chain;
        let _v2 = state::get_governance_chain();
        assert!(_v1 == _v2, 4);
        let _v3 = *&p0.emitter_address;
        let _v4 = state::get_governance_contract();
        assert!(_v3 == _v4, 5);
    }
    public fun destroy(p0: VAA): vector<u8> {
        let VAA{guardian_set_index: _v0, signatures: _v1, timestamp: _v2, nonce: _v3, emitter_chain: _v4, emitter_address: _v5, sequence: _v6, consistency_level: _v7, hash: _v8, payload: _v9} = p0;
        _v9
    }
    public fun get_consistency_level(p0: &VAA): u8 {
        *&p0.consistency_level
    }
    public fun get_emitter_address(p0: &VAA): external_address::ExternalAddress {
        *&p0.emitter_address
    }
    public fun get_emitter_chain(p0: &VAA): u16::U16 {
        *&p0.emitter_chain
    }
    public fun get_guardian_set_index(p0: &VAA): u32::U32 {
        *&p0.guardian_set_index
    }
    public fun get_hash(p0: &VAA): vector<u8> {
        *&p0.hash
    }
    public fun get_payload(p0: &VAA): vector<u8> {
        *&p0.payload
    }
    public fun get_sequence(p0: &VAA): u64 {
        *&p0.sequence
    }
    public fun get_timestamp(p0: &VAA): u32::U32 {
        *&p0.timestamp
    }
    fun parse(p0: vector<u8>): VAA {
        let _v0 = cursor::init<u8>(p0);
        assert!(deserialize::deserialize_u8(&mut _v0) == 1u8, 6);
        let _v1 = deserialize::deserialize_u32(&mut _v0);
        let _v2 = deserialize::deserialize_u8(&mut _v0);
        let _v3 = 0x1::vector::empty<structs::Signature>();
        while (_v2 > 0u8) {
            let _v4 = deserialize::deserialize_u8(&mut _v0);
            let _v5 = deserialize::deserialize_vector(&mut _v0, 64);
            let _v6 = deserialize::deserialize_u8(&mut _v0);
            let _v7 = secp256k1::ecdsa_signature_from_bytes(_v5);
            let _v8 = &mut _v3;
            let _v9 = structs::create_signature(_v7, _v6, _v4);
            0x1::vector::push_back<structs::Signature>(_v8, _v9);
            _v2 = _v2 - 1u8;
            continue
        };
        let _v10 = cursor::rest<u8>(_v0);
        let _v11 = keccak256::keccak256(keccak256::keccak256(_v10));
        let _v12 = cursor::init<u8>(_v10);
        let _v13 = deserialize::deserialize_u32(&mut _v12);
        let _v14 = deserialize::deserialize_u32(&mut _v12);
        let _v15 = deserialize::deserialize_u16(&mut _v12);
        let _v16 = external_address::deserialize(&mut _v12);
        let _v17 = deserialize::deserialize_u64(&mut _v12);
        let _v18 = deserialize::deserialize_u8(&mut _v12);
        let _v19 = cursor::rest<u8>(_v12);
        VAA{guardian_set_index: _v1, signatures: _v3, timestamp: _v13, nonce: _v14, emitter_chain: _v15, emitter_address: _v16, sequence: _v17, consistency_level: _v18, hash: _v11, payload: _v19}
    }
    public fun parse_and_verify(p0: vector<u8>): VAA {
        let _v0 = parse(p0);
        let _v1 = state::get_guardian_set(*&(&_v0).guardian_set_index);
        let _v2 = &_v0;
        let _v3 = &_v1;
        verify(_v2, _v3);
        _v0
    }
    public fun quorum(p0: u64): u64 {
        p0 * 2 / 3 + 1
    }
    friend fun replay_protect(p0: &VAA) {
        state::set_governance_action_consumed(*&p0.hash);
    }
    fun verify(p0: &VAA, p1: &structs::GuardianSet) {
        assert!(state::guardian_set_is_active(p1), 3);
        let _v0 = structs::get_guardians(p1);
        let _v1 = *&p0.hash;
        let _v2 = 0x1::vector::length<structs::Signature>(&p0.signatures);
        let _v3 = quorum(0x1::vector::length<structs::Guardian>(&_v0));
        assert!(_v2 >= _v3, 0);
        let _v4 = 0;
        let _v5 = 0u8;
        'l0: loop {
            'l1: loop {
                loop {
                    let _v6;
                    if (!(_v4 < _v2)) break 'l0;
                    let (_v7,_v8,_v9) = structs::unpack_signature(0x1::vector::borrow<structs::Signature>(&p0.signatures, _v4));
                    let _v10 = _v9;
                    let _v11 = _v7;
                    if (_v4 == 0) _v6 = true else _v6 = _v10 > _v5;
                    if (!_v6) break 'l1;
                    _v5 = _v10;
                    let _v12 = &_v11;
                    let _v13 = guardian_pubkey::from_signature(_v1, _v8, _v12);
                    let _v14 = &_v0;
                    let _v15 = _v10 as u64;
                    let _v16 = structs::get_address(0x1::vector::borrow<structs::Guardian>(_v14, _v15));
                    if (!(_v13 == _v16)) break;
                    _v4 = _v4 + 1;
                    continue
                };
                abort 2
            };
            abort 7
        };
    }
}
