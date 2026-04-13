module 0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387::governance_instruction {
    use 0x5bc11445584a763c1fa7ed39081f1b920954da14e04b32440cba863d03e19625::cursor;
    use 0x5bc11445584a763c1fa7ed39081f1b920954da14e04b32440cba863d03e19625::state;
    use 0x5bc11445584a763c1fa7ed39081f1b920954da14e04b32440cba863d03e19625::u16;
    use 0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387::deserialize;
    use 0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387::error;
    use 0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387::governance_action;
    struct GovernanceInstruction {
        module_: u8,
        action: governance_action::GovernanceAction,
        target_chain_id: u64,
        payload: vector<u8>,
    }
    public fun destroy(p0: GovernanceInstruction): vector<u8> {
        let GovernanceInstruction{module_: _v0, action: _v1, target_chain_id: _v2, payload: _v3} = p0;
        _v3
    }
    public fun from_byte_vec(p0: vector<u8>): GovernanceInstruction {
        let _v0 = cursor::init<u8>(p0);
        if (!(deserialize::deserialize_vector(&mut _v0, 4) == vector[80u8, 84u8, 71u8, 77u8])) {
            let _v1 = error::invalid_governance_magic_value();
            abort _v1
        };
        let _v2 = deserialize::deserialize_u8(&mut _v0);
        let _v3 = governance_action::from_u8(deserialize::deserialize_u8(&mut _v0));
        let _v4 = deserialize::deserialize_u16(&mut _v0);
        let _v5 = cursor::rest<u8>(_v0);
        let _v6 = GovernanceInstruction{module_: _v2, action: _v3, target_chain_id: _v4, payload: _v5};
        validate(&_v6);
        _v6
    }
    public fun get_action(p0: &GovernanceInstruction): governance_action::GovernanceAction {
        *&p0.action
    }
    public fun get_module(p0: &GovernanceInstruction): u8 {
        *&p0.module_
    }
    public fun get_target_chain_id(p0: &GovernanceInstruction): u64 {
        *&p0.target_chain_id
    }
    fun validate(p0: &GovernanceInstruction) {
        let _v0;
        if (!(*&p0.module_ == 1u8)) {
            let _v1 = error::invalid_governance_module();
            abort _v1
        };
        let _v2 = *&p0.target_chain_id;
        let _v3 = u16::to_u64(state::get_chain_id());
        if (_v2 == _v3) _v0 = true else _v0 = _v2 == 0;
        if (!_v0) {
            let _v4 = error::invalid_governance_target_chain_id();
            abort _v4
        };
    }
}
