module 0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387::governance {
    use 0x5bc11445584a763c1fa7ed39081f1b920954da14e04b32440cba863d03e19625::external_address;
    use 0x5bc11445584a763c1fa7ed39081f1b920954da14e04b32440cba863d03e19625::u16;
    use 0x5bc11445584a763c1fa7ed39081f1b920954da14e04b32440cba863d03e19625::vaa;
    use 0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387::contract_upgrade;
    use 0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387::data_source;
    use 0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387::error;
    use 0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387::governance_action;
    use 0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387::governance_instruction;
    use 0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387::set_data_sources;
    use 0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387::set_governance_data_source;
    use 0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387::set_stale_price_threshold;
    use 0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387::set_update_fee;
    use 0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387::state;
    public entry fun execute_governance_instruction(p0: vector<u8>) {
        let _v0 = governance_instruction::from_byte_vec(vaa::destroy(parse_and_verify_governance_vaa(p0)));
        let _v1 = governance_instruction::get_action(&_v0);
        let _v2 = governance_action::new_contract_upgrade();
        if (_v1 == _v2) {
            if (!(governance_instruction::get_target_chain_id(&_v0) != 0)) {
                let _v3 = error::governance_contract_upgrade_chain_id_zero();
                abort _v3
            };
            contract_upgrade::execute(governance_instruction::destroy(_v0))
        } else {
            let _v4 = governance_action::new_set_governance_data_source();
            if (_v1 == _v4) set_governance_data_source::execute(governance_instruction::destroy(_v0)) else {
                let _v5 = governance_action::new_set_data_sources();
                if (_v1 == _v5) set_data_sources::execute(governance_instruction::destroy(_v0)) else {
                    let _v6 = governance_action::new_set_update_fee();
                    if (_v1 == _v6) set_update_fee::execute(governance_instruction::destroy(_v0)) else {
                        let _v7 = governance_action::new_set_stale_price_threshold();
                        if (_v1 == _v7) set_stale_price_threshold::execute(governance_instruction::destroy(_v0)) else {
                            let _v8 = governance_instruction::destroy(_v0);
                            let _v9 = error::invalid_governance_action();
                            abort _v9
                        }
                    }
                }
            }
        };
    }
    fun parse_and_verify_governance_vaa(p0: vector<u8>): vaa::VAA {
        let _v0 = vaa::parse_and_verify(p0);
        let _v1 = u16::to_u64(vaa::get_emitter_chain(&_v0));
        let _v2 = vaa::get_emitter_address(&_v0);
        if (!state::is_valid_governance_data_source(data_source::new(_v1, _v2))) {
            let _v3 = error::invalid_governance_data_source();
            abort _v3
        };
        let _v4 = vaa::get_sequence(&_v0);
        let _v5 = state::get_last_executed_governance_sequence();
        if (!(_v4 > _v5)) {
            let _v6 = error::invalid_governance_sequence_number();
            abort _v6
        };
        state::set_last_executed_governance_sequence(_v4);
        _v0
    }
}
