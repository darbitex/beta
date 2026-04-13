module 0x5bc11445584a763c1fa7ed39081f1b920954da14e04b32440cba863d03e19625::guardian_set_upgrade {
    use 0x5bc11445584a763c1fa7ed39081f1b920954da14e04b32440cba863d03e19625::cursor;
    use 0x5bc11445584a763c1fa7ed39081f1b920954da14e04b32440cba863d03e19625::deserialize;
    use 0x5bc11445584a763c1fa7ed39081f1b920954da14e04b32440cba863d03e19625::state;
    use 0x5bc11445584a763c1fa7ed39081f1b920954da14e04b32440cba863d03e19625::structs;
    use 0x5bc11445584a763c1fa7ed39081f1b920954da14e04b32440cba863d03e19625::u16;
    use 0x5bc11445584a763c1fa7ed39081f1b920954da14e04b32440cba863d03e19625::u32;
    use 0x5bc11445584a763c1fa7ed39081f1b920954da14e04b32440cba863d03e19625::vaa;
    struct GuardianSetUpgrade has drop {
        new_index: u32::U32,
        guardians: vector<structs::Guardian>,
    }
    fun do_upgrade(p0: &GuardianSetUpgrade) {
        let _v0 = state::get_current_guardian_set_index();
        let _v1 = u32::to_u64(*&p0.new_index);
        let _v2 = u32::to_u64(_v0) + 1;
        assert!(_v1 == _v2, 5);
        state::update_guardian_set_index(*&p0.new_index);
        let _v3 = *&p0.new_index;
        let _v4 = *&p0.guardians;
        state::store_guardian_set(structs::create_guardian_set(_v3, _v4));
        state::expire_guardian_set(_v0);
    }
    public fun get_guardians(p0: &GuardianSetUpgrade): vector<structs::Guardian> {
        *&p0.guardians
    }
    public fun get_new_index(p0: &GuardianSetUpgrade): u32::U32 {
        *&p0.new_index
    }
    public fun parse_payload(p0: vector<u8>): GuardianSetUpgrade {
        let _v0 = cursor::init<u8>(p0);
        let _v1 = 0x1::vector::empty<structs::Guardian>();
        assert!(deserialize::deserialize_vector(&mut _v0, 32) == vector[0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 67u8, 111u8, 114u8, 101u8], 2);
        assert!(deserialize::deserialize_u8(&mut _v0) == 2u8, 3);
        let _v2 = deserialize::deserialize_u16(&mut _v0);
        let _v3 = u16::from_u64(0);
        assert!(_v2 == _v3, 4);
        let _v4 = deserialize::deserialize_u32(&mut _v0);
        let _v5 = deserialize::deserialize_u8(&mut _v0);
        while (_v5 > 0u8) {
            let _v6 = deserialize::deserialize_vector(&mut _v0, 20);
            let _v7 = &mut _v1;
            let _v8 = structs::create_guardian(_v6);
            0x1::vector::push_back<structs::Guardian>(_v7, _v8);
            _v5 = _v5 - 1u8;
            continue
        };
        cursor::destroy_empty<u8>(_v0);
        GuardianSetUpgrade{new_index: _v4, guardians: _v1}
    }
    public fun submit_vaa(p0: vector<u8>): GuardianSetUpgrade {
        let _v0 = vaa::parse_and_verify(p0);
        vaa::assert_governance(&_v0);
        vaa::replay_protect(&_v0);
        let _v1 = parse_payload(vaa::destroy(_v0));
        do_upgrade(&_v1);
        _v1
    }
    public entry fun submit_vaa_entry(p0: vector<u8>) {
        let _v0 = submit_vaa(p0);
    }
}
