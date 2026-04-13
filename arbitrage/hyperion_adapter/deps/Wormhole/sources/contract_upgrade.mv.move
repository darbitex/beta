module 0x5bc11445584a763c1fa7ed39081f1b920954da14e04b32440cba863d03e19625::contract_upgrade {
    use 0x1::code;
    use 0x1::vector;
    use 0x5bc11445584a763c1fa7ed39081f1b920954da14e04b32440cba863d03e19625::cursor;
    use 0x5bc11445584a763c1fa7ed39081f1b920954da14e04b32440cba863d03e19625::deserialize;
    use 0x5bc11445584a763c1fa7ed39081f1b920954da14e04b32440cba863d03e19625::keccak256;
    use 0x5bc11445584a763c1fa7ed39081f1b920954da14e04b32440cba863d03e19625::state;
    use 0x5bc11445584a763c1fa7ed39081f1b920954da14e04b32440cba863d03e19625::u16;
    use 0x5bc11445584a763c1fa7ed39081f1b920954da14e04b32440cba863d03e19625::vaa;
    struct Hash has drop {
        hash: vector<u8>,
    }
    struct Migrating has key {
    }
    struct UpgradeAuthorized has key {
        hash: vector<u8>,
    }
    fun authorize_upgrade(p0: &Hash)
        acquires UpgradeAuthorized
    {
        let _v0;
        let _v1 = state::wormhole_signer();
        if (exists<UpgradeAuthorized>(@0x5bc11445584a763c1fa7ed39081f1b920954da14e04b32440cba863d03e19625)) UpgradeAuthorized{hash: _v0} = move_from<UpgradeAuthorized>(@0x5bc11445584a763c1fa7ed39081f1b920954da14e04b32440cba863d03e19625);
        let _v2 = &_v1;
        let _v3 = UpgradeAuthorized{hash: *&p0.hash};
        move_to<UpgradeAuthorized>(_v2, _v3);
    }
    public fun get_hash(p0: &Hash): vector<u8> {
        *&p0.hash
    }
    public fun is_migrating(): bool {
        exists<Migrating>(@0x5bc11445584a763c1fa7ed39081f1b920954da14e04b32440cba863d03e19625)
    }
    public entry fun migrate()
        acquires Migrating
    {
        assert!(exists<Migrating>(@0x5bc11445584a763c1fa7ed39081f1b920954da14e04b32440cba863d03e19625), 5);
        let Migrating{} = move_from<Migrating>(@0x5bc11445584a763c1fa7ed39081f1b920954da14e04b32440cba863d03e19625);
    }
    fun parse_payload(p0: vector<u8>): Hash {
        let _v0 = cursor::init<u8>(p0);
        assert!(deserialize::deserialize_vector(&mut _v0, 32) == vector[0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 67u8, 111u8, 114u8, 101u8], 2);
        assert!(deserialize::deserialize_u8(&mut _v0) == 1u8, 3);
        let _v1 = deserialize::deserialize_u16(&mut _v0);
        let _v2 = state::get_chain_id();
        assert!(_v1 == _v2, 4);
        let _v3 = deserialize::deserialize_vector(&mut _v0, 32);
        cursor::destroy_empty<u8>(_v0);
        Hash{hash: _v3}
    }
    public fun submit_vaa(p0: vector<u8>): Hash
        acquires UpgradeAuthorized
    {
        let _v0 = vaa::parse_and_verify(p0);
        vaa::assert_governance(&_v0);
        vaa::replay_protect(&_v0);
        let _v1 = parse_payload(vaa::destroy(_v0));
        authorize_upgrade(&_v1);
        _v1
    }
    public entry fun submit_vaa_entry(p0: vector<u8>)
        acquires UpgradeAuthorized
    {
        let _v0 = submit_vaa(p0);
    }
    public entry fun upgrade(p0: vector<u8>, p1: vector<vector<u8>>)
        acquires UpgradeAuthorized
    {
        assert!(exists<UpgradeAuthorized>(@0x5bc11445584a763c1fa7ed39081f1b920954da14e04b32440cba863d03e19625), 0);
        let UpgradeAuthorized{hash: _v0} = move_from<UpgradeAuthorized>(@0x5bc11445584a763c1fa7ed39081f1b920954da14e04b32440cba863d03e19625);
        let _v1 = p1;
        vector::reverse<vector<u8>>(&mut _v1);
        let _v2 = keccak256::keccak256(p0);
        while (!vector::is_empty<vector<u8>>(&_v1)) {
            let _v3 = &mut _v2;
            let _v4 = keccak256::keccak256(vector::pop_back<vector<u8>>(&mut _v1));
            vector::append<u8>(_v3, _v4);
            continue
        };
        assert!(keccak256::keccak256(_v2) == _v0, 1);
        let _v5 = state::wormhole_signer();
        code::publish_package_txn(&_v5, p0, p1);
        if (!exists<Migrating>(@0x5bc11445584a763c1fa7ed39081f1b920954da14e04b32440cba863d03e19625)) {
            let _v6 = &_v5;
            let _v7 = Migrating{};
            move_to<Migrating>(_v6, _v7)
        };
    }
}
