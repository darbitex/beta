module 0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387::set_governance_data_source {
    use 0x5bc11445584a763c1fa7ed39081f1b920954da14e04b32440cba863d03e19625::cursor;
    use 0x5bc11445584a763c1fa7ed39081f1b920954da14e04b32440cba863d03e19625::external_address;
    use 0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387::data_source;
    use 0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387::deserialize;
    use 0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387::state;
    friend 0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387::governance;
    struct SetGovernanceDataSource {
        emitter_chain_id: u64,
        emitter_address: external_address::ExternalAddress,
        initial_sequence: u64,
    }
    friend fun execute(p0: vector<u8>) {
        let SetGovernanceDataSource{emitter_chain_id: _v0, emitter_address: _v1, initial_sequence: _v2} = from_byte_vec(p0);
        state::set_governance_data_source(data_source::new(_v0, _v1));
        state::set_last_executed_governance_sequence(_v2);
    }
    fun from_byte_vec(p0: vector<u8>): SetGovernanceDataSource {
        let _v0 = cursor::init<u8>(p0);
        let _v1 = deserialize::deserialize_u16(&mut _v0);
        let _v2 = external_address::from_bytes(deserialize::deserialize_vector(&mut _v0, 32));
        let _v3 = deserialize::deserialize_u64(&mut _v0);
        cursor::destroy_empty<u8>(_v0);
        SetGovernanceDataSource{emitter_chain_id: _v1, emitter_address: _v2, initial_sequence: _v3}
    }
}
