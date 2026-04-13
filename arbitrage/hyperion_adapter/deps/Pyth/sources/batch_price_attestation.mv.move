module 0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387::batch_price_attestation {
    use 0x1::timestamp;
    use 0x5bc11445584a763c1fa7ed39081f1b920954da14e04b32440cba863d03e19625::cursor;
    use 0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387::deserialize;
    use 0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387::error;
    use 0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387::i64;
    use 0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387::price;
    use 0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387::price_feed;
    use 0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387::price_identifier;
    use 0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387::price_info;
    use 0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387::price_status;
    struct BatchPriceAttestation {
        header: Header,
        attestation_size: u64,
        attestation_count: u64,
        price_infos: vector<price_info::PriceInfo>,
    }
    struct Header {
        magic: u64,
        version_major: u64,
        version_minor: u64,
        header_size: u64,
        payload_id: u8,
    }
    public fun deserialize(p0: vector<u8>): BatchPriceAttestation {
        let _v0 = cursor::init<u8>(p0);
        let _v1 = deserialize_header(&mut _v0);
        let _v2 = deserialize::deserialize_u16(&mut _v0);
        let _v3 = deserialize::deserialize_u16(&mut _v0);
        let _v4 = 0x1::vector::empty<price_info::PriceInfo>();
        let _v5 = 0;
        while (_v5 < _v2) {
            let _v6 = deserialize_price_info(&mut _v0);
            0x1::vector::push_back<price_info::PriceInfo>(&mut _v4, _v6);
            let _v7 = &mut _v0;
            let _v8 = _v3 - 149;
            let _v9 = deserialize::deserialize_vector(_v7, _v8);
            _v5 = _v5 + 1;
            continue
        };
        cursor::destroy_empty<u8>(_v0);
        BatchPriceAttestation{header: _v1, attestation_size: _v3, attestation_count: _v2, price_infos: _v4}
    }
    fun deserialize_header(p0: &mut cursor::Cursor<u8>): Header {
        let _v0 = deserialize::deserialize_u32(p0);
        if (!(_v0 == 1345476424)) {
            let _v1 = error::invalid_attestation_magic_value();
            abort _v1
        };
        let _v2 = deserialize::deserialize_u16(p0);
        let _v3 = deserialize::deserialize_u16(p0);
        let _v4 = deserialize::deserialize_u16(p0);
        let _v5 = deserialize::deserialize_u8(p0);
        if (!(_v4 >= 1)) {
            let _v6 = error::invalid_batch_attestation_header_size();
            abort _v6
        };
        let _v7 = _v4 - 1;
        let _v8 = deserialize::deserialize_vector(p0, _v7);
        Header{magic: _v0, version_major: _v2, version_minor: _v3, header_size: _v4, payload_id: _v5}
    }
    fun deserialize_price_info(p0: &mut cursor::Cursor<u8>): price_info::PriceInfo {
        let _v0 = deserialize::deserialize_vector(p0, 32);
        let _v1 = price_identifier::from_byte_vec(deserialize::deserialize_vector(p0, 32));
        let _v2 = deserialize::deserialize_i64(p0);
        let _v3 = deserialize::deserialize_u64(p0);
        let _v4 = deserialize::deserialize_i32(p0);
        let _v5 = deserialize::deserialize_i64(p0);
        let _v6 = deserialize::deserialize_u64(p0);
        let _v7 = price_status::from_u64(deserialize::deserialize_u8(p0) as u64);
        let _v8 = deserialize::deserialize_u32(p0);
        let _v9 = deserialize::deserialize_u32(p0);
        let _v10 = deserialize::deserialize_u64(p0);
        let _v11 = deserialize::deserialize_u64(p0);
        let _v12 = deserialize::deserialize_u64(p0);
        let _v13 = deserialize::deserialize_i64(p0);
        let _v14 = deserialize::deserialize_u64(p0);
        let _v15 = price::new(_v2, _v3, _v4, _v11);
        let _v16 = price_status::new_trading();
        if (_v7 != _v16) _v15 = price::new(_v13, _v14, _v4, _v12);
        let _v17 = _v11;
        let _v18 = price_status::new_trading();
        if (_v7 != _v18) _v17 = _v12;
        let _v19 = timestamp::now_seconds();
        let _v20 = price::new(_v5, _v6, _v4, _v17);
        let _v21 = price_feed::new(_v1, _v15, _v20);
        price_info::new(_v10, _v19, _v21)
    }
    public fun destroy(p0: BatchPriceAttestation): vector<price_info::PriceInfo> {
        let BatchPriceAttestation{header: _v0, attestation_size: _v1, attestation_count: _v2, price_infos: _v3} = p0;
        let Header{magic: _v4, version_major: _v5, version_minor: _v6, header_size: _v7, payload_id: _v8} = _v0;
        _v3
    }
    public fun get_attestation_count(p0: &BatchPriceAttestation): u64 {
        *&p0.attestation_count
    }
    public fun get_price_info(p0: &BatchPriceAttestation, p1: u64): &price_info::PriceInfo {
        0x1::vector::borrow<price_info::PriceInfo>(&p0.price_infos, p1)
    }
}
