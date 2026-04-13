module 0x5bc11445584a763c1fa7ed39081f1b920954da14e04b32440cba863d03e19625::state {
    use 0x1::account;
    use 0x1::event;
    use 0x1::table;
    use 0x1::timestamp;
    use 0x5bc11445584a763c1fa7ed39081f1b920954da14e04b32440cba863d03e19625::emitter;
    use 0x5bc11445584a763c1fa7ed39081f1b920954da14e04b32440cba863d03e19625::external_address;
    use 0x5bc11445584a763c1fa7ed39081f1b920954da14e04b32440cba863d03e19625::set;
    use 0x5bc11445584a763c1fa7ed39081f1b920954da14e04b32440cba863d03e19625::structs;
    use 0x5bc11445584a763c1fa7ed39081f1b920954da14e04b32440cba863d03e19625::u16;
    use 0x5bc11445584a763c1fa7ed39081f1b920954da14e04b32440cba863d03e19625::u32;
    friend 0x5bc11445584a763c1fa7ed39081f1b920954da14e04b32440cba863d03e19625::contract_upgrade;
    friend 0x5bc11445584a763c1fa7ed39081f1b920954da14e04b32440cba863d03e19625::guardian_set_upgrade;
    friend 0x5bc11445584a763c1fa7ed39081f1b920954da14e04b32440cba863d03e19625::vaa;
    friend 0x5bc11445584a763c1fa7ed39081f1b920954da14e04b32440cba863d03e19625::wormhole;
    struct GuardianSetChanged has drop, store {
        oldGuardianIndex: u32::U32,
        newGuardianIndex: u32::U32,
    }
    struct GuardianSetChangedHandle has store, key {
        event: event::EventHandle<GuardianSetChanged>,
    }
    struct WormholeMessage has drop, store {
        sender: u64,
        sequence: u64,
        nonce: u64,
        payload: vector<u8>,
        consistency_level: u8,
        timestamp: u64,
    }
    struct WormholeMessageHandle has store, key {
        event: event::EventHandle<WormholeMessage>,
    }
    struct WormholeState has key {
        chain_id: u16::U16,
        governance_chain_id: u16::U16,
        governance_contract: external_address::ExternalAddress,
        guardian_sets: table::Table<u64, structs::GuardianSet>,
        guardian_set_index: u32::U32,
        guardian_set_expiry: u32::U32,
        consumed_governance_actions: set::Set<vector<u8>>,
        message_fee: u64,
        signer_cap: account::SignerCapability,
        emitter_registry: emitter::EmitterRegistry,
    }
    public fun create_guardian_set_changed_handle(p0: event::EventHandle<GuardianSetChanged>): GuardianSetChangedHandle {
        GuardianSetChangedHandle{event: p0}
    }
    public fun create_wormhole_message_handle(p0: event::EventHandle<WormholeMessage>): WormholeMessageHandle {
        WormholeMessageHandle{event: p0}
    }
    friend fun expire_guardian_set(p0: u32::U32)
        acquires WormholeState
    {
        let _v0 = borrow_global_mut<WormholeState>(@0x5bc11445584a763c1fa7ed39081f1b920954da14e04b32440cba863d03e19625);
        let _v1 = &mut _v0.guardian_sets;
        let _v2 = u32::to_u64(p0);
        let _v3 = table::borrow_mut<u64, structs::GuardianSet>(_v1, _v2);
        let _v4 = *&_v0.guardian_set_expiry;
        structs::expire_guardian_set(_v3, _v4);
    }
    public fun get_chain_id(): u16::U16
        acquires WormholeState
    {
        *&borrow_global<WormholeState>(@0x5bc11445584a763c1fa7ed39081f1b920954da14e04b32440cba863d03e19625).chain_id
    }
    public fun get_current_guardian_set(): structs::GuardianSet
        acquires WormholeState
    {
        let _v0 = borrow_global<WormholeState>(@0x5bc11445584a763c1fa7ed39081f1b920954da14e04b32440cba863d03e19625);
        let _v1 = u32::to_u64(*&_v0.guardian_set_index);
        *table::borrow<u64, structs::GuardianSet>(&_v0.guardian_sets, _v1)
    }
    public fun get_current_guardian_set_index(): u32::U32
        acquires WormholeState
    {
        *&borrow_global<WormholeState>(@0x5bc11445584a763c1fa7ed39081f1b920954da14e04b32440cba863d03e19625).guardian_set_index
    }
    public fun get_governance_chain(): u16::U16
        acquires WormholeState
    {
        *&borrow_global<WormholeState>(@0x5bc11445584a763c1fa7ed39081f1b920954da14e04b32440cba863d03e19625).governance_chain_id
    }
    public fun get_governance_contract(): external_address::ExternalAddress
        acquires WormholeState
    {
        *&borrow_global<WormholeState>(@0x5bc11445584a763c1fa7ed39081f1b920954da14e04b32440cba863d03e19625).governance_contract
    }
    public fun get_guardian_set(p0: u32::U32): structs::GuardianSet
        acquires WormholeState
    {
        let _v0 = &mut borrow_global_mut<WormholeState>(@0x5bc11445584a763c1fa7ed39081f1b920954da14e04b32440cba863d03e19625).guardian_sets;
        let _v1 = u32::to_u64(p0);
        *table::borrow<u64, structs::GuardianSet>(freeze(_v0), _v1)
    }
    public fun get_message_fee(): u64
        acquires WormholeState
    {
        *&borrow_global<WormholeState>(@0x5bc11445584a763c1fa7ed39081f1b920954da14e04b32440cba863d03e19625).message_fee
    }
    public fun guardian_set_is_active(p0: &structs::GuardianSet): bool
        acquires WormholeState
    {
        let _v0;
        let _v1 = structs::get_guardian_set_index(p0);
        let _v2 = get_current_guardian_set_index();
        let _v3 = timestamp::now_seconds();
        if (_v1 == _v2) _v0 = true else _v0 = u32::to_u64(structs::get_guardian_set_expiry(p0)) > _v3;
        _v0
    }
    friend fun init_message_handles(p0: &signer) {
        let _v0 = create_wormhole_message_handle(account::new_event_handle<WormholeMessage>(p0));
        move_to<WormholeMessageHandle>(p0, _v0);
        let _v1 = create_guardian_set_changed_handle(account::new_event_handle<GuardianSetChanged>(p0));
        move_to<GuardianSetChangedHandle>(p0, _v1);
    }
    friend fun init_wormhole_state(p0: &signer, p1: u16::U16, p2: u16::U16, p3: external_address::ExternalAddress, p4: u32::U32, p5: u64, p6: account::SignerCapability) {
        let _v0 = table::new<u64, structs::GuardianSet>();
        let _v1 = u32::from_u64(0);
        let _v2 = set::new<vector<u8>>();
        let _v3 = emitter::init_emitter_registry();
        let _v4 = WormholeState{chain_id: p1, governance_chain_id: p2, governance_contract: p3, guardian_sets: _v0, guardian_set_index: _v1, guardian_set_expiry: p4, consumed_governance_actions: _v2, message_fee: p5, signer_cap: p6, emitter_registry: _v3};
        move_to<WormholeState>(p0, _v4);
    }
    friend fun new_emitter(): emitter::EmitterCapability
        acquires WormholeState
    {
        emitter::new_emitter(&mut borrow_global_mut<WormholeState>(@0x5bc11445584a763c1fa7ed39081f1b920954da14e04b32440cba863d03e19625).emitter_registry)
    }
    friend fun publish_event(p0: u64, p1: u64, p2: u64, p3: vector<u8>)
        acquires WormholeMessageHandle
    {
        let _v0 = borrow_global_mut<WormholeMessageHandle>(@0x5bc11445584a763c1fa7ed39081f1b920954da14e04b32440cba863d03e19625);
        let _v1 = timestamp::now_seconds();
        let _v2 = &mut _v0.event;
        let _v3 = WormholeMessage{sender: p0, sequence: p1, nonce: p2, payload: p3, consistency_level: 0u8, timestamp: _v1};
        event::emit_event<WormholeMessage>(_v2, _v3);
    }
    friend fun set_chain_id(p0: u16::U16)
        acquires WormholeState
    {
        let _v0 = &mut borrow_global_mut<WormholeState>(@0x5bc11445584a763c1fa7ed39081f1b920954da14e04b32440cba863d03e19625).chain_id;
        *_v0 = p0;
    }
    friend fun set_governance_action_consumed(p0: vector<u8>)
        acquires WormholeState
    {
        set::add<vector<u8>>(&mut borrow_global_mut<WormholeState>(@0x5bc11445584a763c1fa7ed39081f1b920954da14e04b32440cba863d03e19625).consumed_governance_actions, p0);
    }
    friend fun set_governance_chain_id(p0: u16::U16)
        acquires WormholeState
    {
        let _v0 = &mut borrow_global_mut<WormholeState>(@0x5bc11445584a763c1fa7ed39081f1b920954da14e04b32440cba863d03e19625).governance_chain_id;
        *_v0 = p0;
    }
    friend fun set_governance_contract(p0: external_address::ExternalAddress)
        acquires WormholeState
    {
        let _v0 = &mut borrow_global_mut<WormholeState>(@0x5bc11445584a763c1fa7ed39081f1b920954da14e04b32440cba863d03e19625).governance_contract;
        *_v0 = p0;
    }
    friend fun set_message_fee(p0: u64)
        acquires WormholeState
    {
        let _v0 = &mut borrow_global_mut<WormholeState>(@0x5bc11445584a763c1fa7ed39081f1b920954da14e04b32440cba863d03e19625).message_fee;
        *_v0 = p0;
    }
    friend fun store_guardian_set(p0: structs::GuardianSet)
        acquires WormholeState
    {
        let _v0 = borrow_global_mut<WormholeState>(@0x5bc11445584a763c1fa7ed39081f1b920954da14e04b32440cba863d03e19625);
        let _v1 = u32::to_u64(structs::get_guardian_set_index(&p0));
        table::add<u64, structs::GuardianSet>(&mut _v0.guardian_sets, _v1, p0);
    }
    friend fun update_guardian_set_index(p0: u32::U32)
        acquires WormholeState
    {
        let _v0 = &mut borrow_global_mut<WormholeState>(@0x5bc11445584a763c1fa7ed39081f1b920954da14e04b32440cba863d03e19625).guardian_set_index;
        *_v0 = p0;
    }
    friend fun wormhole_signer(): signer
        acquires WormholeState
    {
        account::create_signer_with_capability(&borrow_global<WormholeState>(@0x5bc11445584a763c1fa7ed39081f1b920954da14e04b32440cba863d03e19625).signer_cap)
    }
}
