module 0x5bc11445584a763c1fa7ed39081f1b920954da14e04b32440cba863d03e19625::wormhole {
    use 0x1::account;
    use 0x1::aptos_coin;
    use 0x1::coin;
    use 0x1::signer;
    use 0x1::vector;
    use 0x108bc32f7de18a5f6e1e7d6ee7aff9f5fc858d0d87ac0da94dd8d2a5d267d6b::deployer;
    use 0x5bc11445584a763c1fa7ed39081f1b920954da14e04b32440cba863d03e19625::emitter;
    use 0x5bc11445584a763c1fa7ed39081f1b920954da14e04b32440cba863d03e19625::external_address;
    use 0x5bc11445584a763c1fa7ed39081f1b920954da14e04b32440cba863d03e19625::state;
    use 0x5bc11445584a763c1fa7ed39081f1b920954da14e04b32440cba863d03e19625::structs;
    use 0x5bc11445584a763c1fa7ed39081f1b920954da14e04b32440cba863d03e19625::u16;
    use 0x5bc11445584a763c1fa7ed39081f1b920954da14e04b32440cba863d03e19625::u32;
    public entry fun init(p0: &signer, p1: u64, p2: u64, p3: vector<u8>, p4: vector<vector<u8>>) {
        let _v0 = deployer::claim_signer_capability(p0, @0x5bc11445584a763c1fa7ed39081f1b920954da14e04b32440cba863d03e19625);
        let _v1 = vector::empty<structs::Guardian>();
        vector::reverse<vector<u8>>(&mut p4);
        while (!vector::is_empty<vector<u8>>(&p4)) {
            let _v2 = &mut _v1;
            let _v3 = structs::create_guardian(vector::pop_back<vector<u8>>(&mut p4));
            vector::push_back<structs::Guardian>(_v2, _v3);
            continue
        };
        let _v4 = u32::from_u64(86400);
        init_internal(_v0, p1, p2, p3, _v1, _v4, 0);
    }
    fun init_internal(p0: account::SignerCapability, p1: u64, p2: u64, p3: vector<u8>, p4: vector<structs::Guardian>, p5: u32::U32, p6: u64) {
        let _v0 = account::create_signer_with_capability(&p0);
        let _v1 = &_v0;
        let _v2 = u16::from_u64(p1);
        let _v3 = u16::from_u64(p2);
        let _v4 = external_address::from_bytes(p3);
        state::init_wormhole_state(_v1, _v2, _v3, _v4, p5, p6, p0);
        state::init_message_handles(&_v0);
        state::store_guardian_set(structs::create_guardian_set(u32::from_u64(0), p4));
        if (!coin::is_account_registered<aptos_coin::AptosCoin>(signer::address_of(&_v0))) coin::register<aptos_coin::AptosCoin>(&_v0);
    }
    public fun publish_message(p0: &mut emitter::EmitterCapability, p1: u64, p2: vector<u8>, p3: coin::Coin<aptos_coin::AptosCoin>): u64 {
        let _v0 = state::get_message_fee();
        let _v1 = coin::value<aptos_coin::AptosCoin>(&p3);
        assert!(_v0 <= _v1, 0);
        coin::deposit<aptos_coin::AptosCoin>(@0x5bc11445584a763c1fa7ed39081f1b920954da14e04b32440cba863d03e19625, p3);
        let _v2 = emitter::use_sequence(p0);
        state::publish_event(emitter::get_emitter(freeze(p0)), _v2, p1, p2);
        _v2
    }
    public fun register_emitter(): emitter::EmitterCapability {
        state::new_emitter()
    }
}
