module 0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387::pyth {
    use 0x1::account;
    use 0x1::aptos_coin;
    use 0x1::coin;
    use 0x1::signer;
    use 0x1::timestamp;
    use 0x1::vector;
    use 0x5bc11445584a763c1fa7ed39081f1b920954da14e04b32440cba863d03e19625::cursor;
    use 0x5bc11445584a763c1fa7ed39081f1b920954da14e04b32440cba863d03e19625::external_address;
    use 0x5bc11445584a763c1fa7ed39081f1b920954da14e04b32440cba863d03e19625::u16;
    use 0x5bc11445584a763c1fa7ed39081f1b920954da14e04b32440cba863d03e19625::vaa;
    use 0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387::batch_price_attestation;
    use 0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387::data_source;
    use 0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387::deserialize;
    use 0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387::error;
    use 0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387::event;
    use 0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387::i64;
    use 0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387::keccak160;
    use 0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387::merkle;
    use 0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387::price;
    use 0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387::price_feed;
    use 0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387::price_identifier;
    use 0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387::price_info;
    use 0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387::state;
    use 0xb31e712b26fd295357355f6845e77c888298636609e93bc9b05f0f604049f434::deployer;
    fun abs_diff(p0: u64, p1: u64): u64 {
        if (p0 > p1) return p0 - p1;
        p1 - p0
    }
    fun check_price_is_fresh(p0: &price::Price, p1: u64) {
        let _v0 = timestamp::now_seconds();
        let _v1 = price::get_timestamp(p0);
        if (!(abs_diff(_v0, _v1) < p1)) {
            let _v2 = error::stale_price_update();
            abort _v2
        };
    }
    public fun get_ema_price(p0: price_identifier::PriceIdentifier): price::Price {
        let _v0 = state::get_stale_price_threshold_secs();
        get_ema_price_no_older_than(p0, _v0)
    }
    public fun get_ema_price_no_older_than(p0: price_identifier::PriceIdentifier, p1: u64): price::Price {
        let _v0 = get_ema_price_unsafe(p0);
        check_price_is_fresh(&_v0, p1);
        _v0
    }
    public fun get_ema_price_unsafe(p0: price_identifier::PriceIdentifier): price::Price {
        let _v0 = state::get_latest_price_info(p0);
        price_feed::get_ema_price(price_info::get_price_feed(&_v0))
    }
    public fun get_price(p0: price_identifier::PriceIdentifier): price::Price {
        let _v0 = state::get_stale_price_threshold_secs();
        get_price_no_older_than(p0, _v0)
    }
    public fun get_price_no_older_than(p0: price_identifier::PriceIdentifier, p1: u64): price::Price {
        let _v0 = get_price_unsafe(p0);
        check_price_is_fresh(&_v0, p1);
        _v0
    }
    public fun get_price_unsafe(p0: price_identifier::PriceIdentifier): price::Price {
        let _v0 = state::get_latest_price_info(p0);
        price_feed::get_price(price_info::get_price_feed(&_v0))
    }
    public fun get_stale_price_threshold_secs(): u64 {
        state::get_stale_price_threshold_secs()
    }
    public fun get_update_fee(p0: &vector<vector<u8>>): u64 {
        let _v0 = 0;
        let _v1 = 0;
        loop {
            let _v2 = vector::length<vector<u8>>(p0);
            if (!(_v0 < _v2)) break;
            let _v3 = cursor::init<u8>(*vector::borrow<vector<u8>>(p0, _v0));
            if (deserialize::deserialize_u32(&mut _v3) == 1347305813) {
                let _v4 = parse_and_verify_accumulator_message(&mut _v3);
                let _v5 = vector::length<price_info::PriceInfo>(&_v4);
                _v1 = _v1 + _v5
            } else _v1 = _v1 + 1;
            let _v6 = cursor::rest<u8>(_v3);
            _v0 = _v0 + 1;
            continue
        };
        state::get_base_update_fee() * _v1
    }
    public entry fun init(p0: &signer, p1: u64, p2: u64, p3: vector<u8>, p4: vector<u64>, p5: vector<vector<u8>>, p6: u64) {
        let _v0 = deployer::claim_signer_capability(p0, @0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387);
        let _v1 = parse_data_sources(p4, p5);
        init_internal(_v0, p1, p2, p3, _v1, p6);
    }
    fun init_internal(p0: account::SignerCapability, p1: u64, p2: u64, p3: vector<u8>, p4: vector<data_source::DataSource>, p5: u64) {
        let _v0 = account::create_signer_with_capability(&p0);
        let _v1 = &_v0;
        let _v2 = external_address::from_bytes(p3);
        let _v3 = data_source::new(p2, _v2);
        state::init(_v1, p1, p5, _v3, p4, p0);
        event::init(&_v0);
        if (!coin::is_account_registered<aptos_coin::AptosCoin>(signer::address_of(&_v0))) coin::register<aptos_coin::AptosCoin>(&_v0);
    }
    fun is_fresh_update(p0: &price_info::PriceInfo): bool {
        let _v0 = price_info::get_price_feed(p0);
        let _v1 = price_feed::get_price(_v0);
        let _v2 = price::get_timestamp(&_v1);
        let _v3 = price_feed::get_price_identifier(_v0);
        if (!price_feed_exists(*_v3)) return true;
        let _v4 = get_price_unsafe(*_v3);
        let _v5 = price::get_timestamp(&_v4);
        _v2 > _v5
    }
    fun parse_accumulator_merkle_root_from_vaa_payload(p0: vector<u8>): keccak160::Hash {
        let _v0 = cursor::init<u8>(p0);
        if (!(deserialize::deserialize_u32(&mut _v0) == 1096111958)) {
            let _v1 = error::invalid_wormhole_message();
            abort _v1
        };
        if (!(deserialize::deserialize_u8(&mut _v0) == 0u8)) {
            let _v2 = error::invalid_wormhole_message();
            abort _v2
        };
        let _v3 = deserialize::deserialize_u64(&mut _v0);
        let _v4 = deserialize::deserialize_u32(&mut _v0);
        let _v5 = deserialize::deserialize_vector(&mut _v0, 20);
        let _v6 = cursor::rest<u8>(_v0);
        keccak160::new(_v5)
    }
    fun parse_accumulator_update_message(p0: vector<u8>): price_info::PriceInfo {
        let _v0 = cursor::init<u8>(p0);
        if (!(deserialize::deserialize_u8(&mut _v0) == 0u8)) {
            let _v1 = error::invalid_accumulator_message();
            abort _v1
        };
        let _v2 = price_identifier::from_byte_vec(deserialize::deserialize_vector(&mut _v0, 32));
        let _v3 = deserialize::deserialize_i64(&mut _v0);
        let _v4 = deserialize::deserialize_u64(&mut _v0);
        let _v5 = deserialize::deserialize_i32(&mut _v0);
        let _v6 = deserialize::deserialize_u64(&mut _v0);
        let _v7 = deserialize::deserialize_i64(&mut _v0);
        let _v8 = deserialize::deserialize_i64(&mut _v0);
        let _v9 = deserialize::deserialize_u64(&mut _v0);
        let _v10 = timestamp::now_seconds();
        let _v11 = timestamp::now_seconds();
        let _v12 = price::new(_v3, _v4, _v5, _v6);
        let _v13 = price::new(_v8, _v9, _v5, _v6);
        let _v14 = price_feed::new(_v2, _v12, _v13);
        let _v15 = price_info::new(_v10, _v11, _v14);
        let _v16 = cursor::rest<u8>(_v0);
        _v15
    }
    fun parse_and_verify_accumulator_message(p0: &mut cursor::Cursor<u8>): vector<price_info::PriceInfo> {
        if (!(deserialize::deserialize_u8(p0) == 1u8)) {
            let _v0 = error::invalid_accumulator_payload();
            abort _v0
        };
        let _v1 = deserialize::deserialize_u8(p0);
        let _v2 = deserialize::deserialize_u8(p0) as u64;
        let _v3 = deserialize::deserialize_vector(p0, _v2);
        if (!(deserialize::deserialize_u8(p0) == 0u8)) {
            let _v4 = error::invalid_accumulator_payload();
            abort _v4
        };
        let _v5 = deserialize::deserialize_u16(p0);
        let _v6 = vaa::parse_and_verify(deserialize::deserialize_vector(p0, _v5));
        verify_data_source(&_v6);
        let _v7 = parse_accumulator_merkle_root_from_vaa_payload(vaa::get_payload(&_v6));
        let _v8 = vaa::destroy(_v6);
        let _v9 = &_v7;
        parse_and_verify_accumulator_updates(p0, _v9)
    }
    fun parse_and_verify_accumulator_updates(p0: &mut cursor::Cursor<u8>, p1: &keccak160::Hash): vector<price_info::PriceInfo> {
        let _v0 = deserialize::deserialize_u8(p0);
        let _v1 = vector::empty<price_info::PriceInfo>();
        'l0: loop {
            loop {
                if (!(_v0 > 0u8)) break 'l0;
                let _v2 = deserialize::deserialize_u16(p0);
                let _v3 = deserialize::deserialize_vector(p0, _v2);
                let _v4 = parse_accumulator_update_message(_v3);
                vector::push_back<price_info::PriceInfo>(&mut _v1, _v4);
                let _v5 = deserialize::deserialize_u8(p0);
                let _v6 = vector::empty<keccak160::Hash>();
                while (_v5 > 0u8) {
                    let _v7 = keccak160::get_hash_length();
                    let _v8 = deserialize::deserialize_vector(p0, _v7);
                    let _v9 = &mut _v6;
                    let _v10 = keccak160::new(_v8);
                    vector::push_back<keccak160::Hash>(_v9, _v10);
                    _v5 = _v5 - 1u8;
                    continue
                };
                if (!merkle::check(&_v6, p1, _v3)) break;
                _v0 = _v0 - 1u8;
                continue
            };
            let _v11 = error::invalid_proof();
            abort _v11
        };
        _v1
    }
    fun parse_data_sources(p0: vector<u64>, p1: vector<vector<u8>>): vector<data_source::DataSource> {
        let _v0 = vector::length<u64>(&p0);
        let _v1 = vector::length<vector<u8>>(&p1);
        if (!(_v0 == _v1)) {
            let _v2 = error::data_source_emitter_address_and_chain_ids_different_lengths();
            abort _v2
        };
        let _v3 = vector::empty<data_source::DataSource>();
        let _v4 = 0;
        loop {
            let _v5 = vector::length<u64>(&p0);
            if (!(_v4 < _v5)) break;
            let _v6 = &mut _v3;
            let _v7 = *vector::borrow<u64>(&p0, _v4);
            let _v8 = external_address::from_bytes(*vector::borrow<vector<u8>>(&p1, _v4));
            let _v9 = data_source::new(_v7, _v8);
            vector::push_back<data_source::DataSource>(_v6, _v9);
            _v4 = _v4 + 1;
            continue
        };
        _v3
    }
    public fun price_feed_exists(p0: price_identifier::PriceIdentifier): bool {
        state::price_info_cached(p0)
    }
    friend fun update_cache(p0: vector<price_info::PriceInfo>) {
        while (!vector::is_empty<price_info::PriceInfo>(&p0)) {
            let _v0 = vector::pop_back<price_info::PriceInfo>(&mut p0);
            if (!is_fresh_update(&_v0)) continue;
            let _v1 = *price_info::get_price_feed(&_v0);
            state::set_latest_price_info(*price_feed::get_price_identifier(&_v1), _v0);
            let _v2 = timestamp::now_microseconds();
            event::emit_price_feed_update(_v1, _v2);
            continue
        };
        vector::destroy_empty<price_info::PriceInfo>(p0);
    }
    fun update_price_feed_from_single_vaa(p0: vector<u8>): u64 {
        let _v0;
        let _v1;
        let _v2 = cursor::init<u8>(p0);
        if (deserialize::deserialize_u32(&mut _v2) == 1347305813) {
            let _v3 = parse_and_verify_accumulator_message(&mut _v2);
            _v1 = vector::length<price_info::PriceInfo>(&_v3);
            _v0 = _v3
        } else {
            let _v4 = vaa::parse_and_verify(p0);
            verify_data_source(&_v4);
            _v1 = 1;
            _v0 = batch_price_attestation::destroy(batch_price_attestation::deserialize(vaa::destroy(_v4)))
        };
        update_cache(_v0);
        let _v5 = cursor::rest<u8>(_v2);
        _v1
    }
    public fun update_price_feeds(p0: vector<vector<u8>>, p1: coin::Coin<aptos_coin::AptosCoin>) {
        let _v0 = 0;
        while (!vector::is_empty<vector<u8>>(&p0)) {
            let _v1 = update_price_feed_from_single_vaa(vector::pop_back<vector<u8>>(&mut p0));
            _v0 = _v0 + _v1;
            continue
        };
        let _v2 = state::get_base_update_fee() * _v0;
        let _v3 = coin::value<aptos_coin::AptosCoin>(&p1);
        if (!(_v2 <= _v3)) {
            let _v4 = error::insufficient_fee();
            abort _v4
        };
        coin::deposit<aptos_coin::AptosCoin>(@0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387, p1);
    }
    public entry fun update_price_feeds_if_fresh(p0: vector<vector<u8>>, p1: vector<vector<u8>>, p2: vector<u64>, p3: coin::Coin<aptos_coin::AptosCoin>) {
        let _v0 = vector::length<vector<u8>>(&p1);
        let _v1 = vector::length<u64>(&p2);
        if (!(_v0 == _v1)) {
            let _v2 = error::invalid_publish_times_length();
            abort _v2
        };
        let _v3 = false;
        let _v4 = 0;
        'l0: loop {
            'l1: loop {
                loop {
                    let _v5 = vector::length<u64>(&p2);
                    if (!(_v4 < _v5)) break 'l0;
                    let _v6 = price_identifier::from_byte_vec(*vector::borrow<vector<u8>>(&p1, _v4));
                    if (!state::price_info_cached(_v6)) break;
                    let _v7 = get_price_unsafe(_v6);
                    let _v8 = price::get_timestamp(&_v7);
                    let _v9 = *vector::borrow<u64>(&p2, _v4);
                    if (_v8 < _v9) break 'l1;
                    _v4 = _v4 + 1;
                    continue
                };
                _v3 = true;
                break 'l0
            };
            _v3 = true;
            break
        };
        if (!_v3) {
            let _v10 = error::no_fresh_data();
            abort _v10
        };
        update_price_feeds(p0, p3);
    }
    public entry fun update_price_feeds_if_fresh_with_funder(p0: &signer, p1: vector<vector<u8>>, p2: vector<vector<u8>>, p3: vector<u64>) {
        let _v0 = get_update_fee(&p1);
        let _v1 = coin::withdraw<aptos_coin::AptosCoin>(p0, _v0);
        update_price_feeds_if_fresh(p1, p2, p3, _v1);
    }
    public entry fun update_price_feeds_with_funder(p0: &signer, p1: vector<vector<u8>>) {
        let _v0 = 0;
        while (!vector::is_empty<vector<u8>>(&p1)) {
            let _v1 = update_price_feed_from_single_vaa(vector::pop_back<vector<u8>>(&mut p1));
            _v0 = _v0 + _v1;
            continue
        };
        let _v2 = state::get_base_update_fee() * _v0;
        let _v3 = coin::withdraw<aptos_coin::AptosCoin>(p0, _v2);
        coin::deposit<aptos_coin::AptosCoin>(@0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387, _v3);
    }
    fun verify_data_source(p0: &vaa::VAA) {
        let _v0 = u16::to_u64(vaa::get_emitter_chain(p0));
        let _v1 = vaa::get_emitter_address(p0);
        if (!state::is_valid_data_source(data_source::new(_v0, _v1))) {
            let _v2 = error::invalid_data_source();
            abort _v2
        };
    }
}
