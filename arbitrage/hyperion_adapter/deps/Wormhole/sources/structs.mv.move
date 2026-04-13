module 0x5bc11445584a763c1fa7ed39081f1b920954da14e04b32440cba863d03e19625::structs {
    use 0x1::secp256k1;
    use 0x1::timestamp;
    use 0x5bc11445584a763c1fa7ed39081f1b920954da14e04b32440cba863d03e19625::guardian_pubkey;
    use 0x5bc11445584a763c1fa7ed39081f1b920954da14e04b32440cba863d03e19625::u32;
    friend 0x5bc11445584a763c1fa7ed39081f1b920954da14e04b32440cba863d03e19625::state;
    struct Guardian has copy, drop, store, key {
        address: guardian_pubkey::Address,
    }
    struct GuardianSet has copy, drop, store, key {
        index: u32::U32,
        guardians: vector<Guardian>,
        expiration_time: u32::U32,
    }
    struct Signature has copy, drop, store, key {
        sig: secp256k1::ECDSASignature,
        recovery_id: u8,
        guardian_index: u8,
    }
    public fun create_guardian(p0: vector<u8>): Guardian {
        Guardian{address: guardian_pubkey::from_bytes(p0)}
    }
    public fun create_guardian_set(p0: u32::U32, p1: vector<Guardian>): GuardianSet {
        let _v0 = u32::from_u64(0);
        GuardianSet{index: p0, guardians: p1, expiration_time: _v0}
    }
    public fun create_signature(p0: secp256k1::ECDSASignature, p1: u8, p2: u8): Signature {
        Signature{sig: p0, recovery_id: p1, guardian_index: p2}
    }
    friend fun expire_guardian_set(p0: &mut GuardianSet, p1: u32::U32) {
        let _v0 = timestamp::now_seconds();
        let _v1 = u32::to_u64(p1);
        let _v2 = u32::from_u64(_v0 + _v1);
        let _v3 = &mut p0.expiration_time;
        *_v3 = _v2;
    }
    public fun get_address(p0: &Guardian): guardian_pubkey::Address {
        *&p0.address
    }
    public fun get_guardian_set_expiry(p0: &GuardianSet): u32::U32 {
        *&p0.expiration_time
    }
    public fun get_guardian_set_index(p0: &GuardianSet): u32::U32 {
        *&p0.index
    }
    public fun get_guardians(p0: &GuardianSet): vector<Guardian> {
        *&p0.guardians
    }
    public fun unpack_signature(p0: &Signature): (secp256k1::ECDSASignature, u8, u8) {
        let _v0 = *&p0.sig;
        let _v1 = *&p0.recovery_id;
        let _v2 = *&p0.guardian_index;
        (_v0, _v1, _v2)
    }
}
