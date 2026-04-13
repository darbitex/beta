module 0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387::set_data_sources {
    use 0x5bc11445584a763c1fa7ed39081f1b920954da14e04b32440cba863d03e19625::cursor;
    use 0x5bc11445584a763c1fa7ed39081f1b920954da14e04b32440cba863d03e19625::external_address;
    use 0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387::data_source;
    use 0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387::deserialize;
    use 0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387::state;
    friend 0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387::governance;
    struct SetDataSources {
        sources: vector<data_source::DataSource>,
    }
    friend fun execute(p0: vector<u8>) {
        let SetDataSources{sources: _v0} = from_byte_vec(p0);
        state::set_data_sources(_v0);
    }
    fun from_byte_vec(p0: vector<u8>): SetDataSources {
        let _v0 = cursor::init<u8>(p0);
        let _v1 = deserialize::deserialize_u8(&mut _v0);
        let _v2 = 0x1::vector::empty<data_source::DataSource>();
        let _v3 = 0u8;
        while (_v3 < _v1) {
            let _v4 = deserialize::deserialize_u16(&mut _v0);
            let _v5 = external_address::from_bytes(deserialize::deserialize_vector(&mut _v0, 32));
            let _v6 = &mut _v2;
            let _v7 = data_source::new(_v4, _v5);
            0x1::vector::push_back<data_source::DataSource>(_v6, _v7);
            _v3 = _v3 + 1u8;
            continue
        };
        cursor::destroy_empty<u8>(_v0);
        SetDataSources{sources: _v2}
    }
}
