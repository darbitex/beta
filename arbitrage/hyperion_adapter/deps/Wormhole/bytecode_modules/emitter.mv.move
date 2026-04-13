module 0x5bc11445584a763c1fa7ed39081f1b920954da14e04b32440cba863d03e19625::emitter {
    use 0x5bc11445584a763c1fa7ed39081f1b920954da14e04b32440cba863d03e19625::external_address;
    use 0x5bc11445584a763c1fa7ed39081f1b920954da14e04b32440cba863d03e19625::serialize;
    friend 0x5bc11445584a763c1fa7ed39081f1b920954da14e04b32440cba863d03e19625::state;
    friend 0x5bc11445584a763c1fa7ed39081f1b920954da14e04b32440cba863d03e19625::wormhole;
    struct EmitterCapability has store {
        emitter: u64,
        sequence: u64,
    }
    struct EmitterRegistry has store {
        next_id: u64,
    }
    public fun destroy_emitter_cap(p0: EmitterCapability) {
        let EmitterCapability{emitter: _v0, sequence: _v1} = p0;
    }
    public fun get_emitter(p0: &EmitterCapability): u64 {
        *&p0.emitter
    }
    public fun get_external_address(p0: &EmitterCapability): external_address::ExternalAddress {
        let _v0 = vector[];
        let _v1 = &mut _v0;
        let _v2 = *&p0.emitter;
        serialize::serialize_u64(_v1, _v2);
        external_address::from_bytes(_v0)
    }
    friend fun init_emitter_registry(): EmitterRegistry {
        EmitterRegistry{next_id: 1}
    }
    friend fun new_emitter(p0: &mut EmitterRegistry): EmitterCapability {
        let _v0 = *&p0.next_id;
        let _v1 = _v0 + 1;
        let _v2 = &mut p0.next_id;
        *_v2 = _v1;
        EmitterCapability{emitter: _v0, sequence: 0}
    }
    friend fun use_sequence(p0: &mut EmitterCapability): u64 {
        let _v0 = *&p0.sequence;
        let _v1 = _v0 + 1;
        let _v2 = &mut p0.sequence;
        *_v2 = _v1;
        _v0
    }
}
