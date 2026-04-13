module 0x3bcacb561438c55ce2a9da479df6ab486af55b2fb7070b700df36c097da732b8::forwarder {
    use 0x1::ed25519;
    use 0x1::object;
    use 0x1::smart_table;
    use 0x1::vector;
    use 0x1::error;
    use 0x1::signer;
    use 0x1::event;
    use 0x3bcacb561438c55ce2a9da479df6ab486af55b2fb7070b700df36c097da732b8::storage;
    use 0x1::fungible_asset;
    use 0x1::dispatchable_fungible_asset;
    use 0x1::option;
    use 0x1::bcs;
    use 0x1::from_bcs;
    use 0x1::aptos_hash;
    use 0x1::bit_vector;
    struct Signature has drop {
        public_key: ed25519::UnvalidatedPublicKey,
        sig: ed25519::Signature,
    }
    struct State has key {
        owner_address: address,
        pending_owner_address: address,
        extend_ref: object::ExtendRef,
        transfer_ref: object::TransferRef,
        configs: smart_table::SmartTable<ConfigId, Config>,
        reports: smart_table::SmartTable<vector<u8>, address>,
    }
    struct ConfigId has copy, drop, store, key {
        don_id: u32,
        config_version: u32,
    }
    struct Config has copy, drop, store, key {
        f: u8,
        oracles: vector<ed25519::UnvalidatedPublicKey>,
    }
    struct ConfigSet has drop, store {
        don_id: u32,
        config_version: u32,
        f: u8,
        signers: vector<vector<u8>>,
    }
    struct OwnershipTransferRequested has drop, store {
        from: address,
        to: address,
    }
    struct OwnershipTransferred has drop, store {
        from: address,
        to: address,
    }
    struct ReportProcessed has drop, store {
        receiver: address,
        workflow_execution_id: vector<u8>,
        report_id: u16,
    }
    public fun signature_from_bytes(p0: vector<u8>): Signature {
        if (!(vector::length<u8>(&p0) == 96)) {
            let _v0 = error::invalid_argument(8);
            abort _v0
        };
        let _v1 = ed25519::new_unvalidated_public_key_from_bytes(vector::slice<u8>(&p0, 0, 32));
        let _v2 = ed25519::new_signature_from_bytes(vector::slice<u8>(&p0, 32, 96));
        Signature{public_key: _v1, sig: _v2}
    }
    public entry fun set_config(p0: &signer, p1: u32, p2: u32, p3: u8, p4: vector<vector<u8>>)
        acquires State
    {
        let _v0 = @0x3bcacb561438c55ce2a9da479df6ab486af55b2fb7070b700df36c097da732b8;
        let _v1 = object::create_object_address(&_v0, vector[70u8, 79u8, 82u8, 87u8, 65u8, 82u8, 68u8, 69u8, 82u8]);
        let _v2 = borrow_global_mut<State>(_v1);
        let _v3 = freeze(_v2);
        let _v4 = signer::address_of(p0);
        if (!(*&_v3.owner_address == _v4)) {
            let _v5 = error::permission_denied(7);
            abort _v5
        };
        if (!(p3 != 0u8)) {
            let _v6 = error::invalid_argument(9);
            abort _v6
        };
        if (!(vector::length<vector<u8>>(&p4) <= 31)) {
            let _v7 = error::invalid_argument(10);
            abort _v7
        };
        let _v8 = vector::length<vector<u8>>(&p4);
        let _v9 = p3 as u64;
        let _v10 = 3 * _v9 + 1;
        if (!(_v8 >= _v10)) {
            let _v11 = error::invalid_argument(11);
            abort _v11
        };
        let _v12 = &mut _v2.configs;
        let _v13 = ConfigId{don_id: p1, config_version: p2};
        let _v14 = vector::empty<ed25519::UnvalidatedPublicKey>();
        let _v15 = p4;
        vector::reverse<vector<u8>>(&mut _v15);
        let _v16 = _v15;
        let _v17 = vector::length<vector<u8>>(&_v16);
        while (_v17 > 0) {
            let _v18 = vector::pop_back<vector<u8>>(&mut _v16);
            let _v19 = &mut _v14;
            let _v20 = ed25519::new_unvalidated_public_key_from_bytes(_v18);
            vector::push_back<ed25519::UnvalidatedPublicKey>(_v19, _v20);
            _v17 = _v17 - 1;
            continue
        };
        vector::destroy_empty<vector<u8>>(_v16);
        let _v21 = Config{f: p3, oracles: _v14};
        smart_table::upsert<ConfigId, Config>(_v12, _v13, _v21);
        event::emit<ConfigSet>(ConfigSet{don_id: p1, config_version: p2, f: p3, signers: p4});
    }
    fun init_module(p0: &signer) {
        assert!(signer::address_of(p0) == @0x3bcacb561438c55ce2a9da479df6ab486af55b2fb7070b700df36c097da732b8, 1);
        let _v0 = object::create_named_object(p0, vector[70u8, 79u8, 82u8, 87u8, 65u8, 82u8, 68u8, 69u8, 82u8]);
        let _v1 = object::generate_extend_ref(&_v0);
        let _v2 = object::generate_transfer_ref(&_v0);
        let _v3 = object::generate_signer(&_v0);
        let _v4 = &_v3;
        let _v5 = smart_table::new<ConfigId, Config>();
        let _v6 = smart_table::new<vector<u8>, address>();
        let _v7 = State{owner_address: @0xc71bcbcaf97ee6d54d9a128078e214e9578ee5b165c6a1c047b5c0271c8aaff5, pending_owner_address: @0x0, extend_ref: _v1, transfer_ref: _v2, configs: _v5, reports: _v6};
        move_to<State>(_v4, _v7);
    }
    public entry fun accept_ownership(p0: &signer)
        acquires State
    {
        let _v0 = @0x3bcacb561438c55ce2a9da479df6ab486af55b2fb7070b700df36c097da732b8;
        let _v1 = object::create_object_address(&_v0, vector[70u8, 79u8, 82u8, 87u8, 65u8, 82u8, 68u8, 69u8, 82u8]);
        let _v2 = borrow_global_mut<State>(_v1);
        let _v3 = *&_v2.pending_owner_address;
        let _v4 = signer::address_of(p0);
        if (!(_v3 == _v4)) {
            let _v5 = error::permission_denied(14);
            abort _v5
        };
        let _v6 = *&_v2.owner_address;
        let _v7 = *&_v2.pending_owner_address;
        let _v8 = &mut _v2.owner_address;
        *_v8 = _v7;
        let _v9 = &mut _v2.pending_owner_address;
        *_v9 = @0x0;
        let _v10 = *&_v2.owner_address;
        event::emit<OwnershipTransferred>(OwnershipTransferred{from: _v6, to: _v10});
    }
    public entry fun clear_config(p0: &signer, p1: u32, p2: u32)
        acquires State
    {
        let _v0 = @0x3bcacb561438c55ce2a9da479df6ab486af55b2fb7070b700df36c097da732b8;
        let _v1 = object::create_object_address(&_v0, vector[70u8, 79u8, 82u8, 87u8, 65u8, 82u8, 68u8, 69u8, 82u8]);
        let _v2 = borrow_global_mut<State>(_v1);
        let _v3 = freeze(_v2);
        let _v4 = signer::address_of(p0);
        if (!(*&_v3.owner_address == _v4)) {
            let _v5 = error::permission_denied(7);
            abort _v5
        };
        let _v6 = &mut _v2.configs;
        let _v7 = ConfigId{don_id: p1, config_version: p2};
        let _v8 = smart_table::remove<ConfigId, Config>(_v6, _v7);
        let _v9 = vector::empty<vector<u8>>();
        event::emit<ConfigSet>(ConfigSet{don_id: p1, config_version: p2, f: 0u8, signers: _v9});
    }
    fun dispatch(p0: address, p1: vector<u8>, p2: vector<u8>) {
        let _v0 = storage::insert(p0, p1, p2);
        let _v1 = dispatchable_fungible_asset::derived_supply<fungible_asset::Metadata>(_v0);
        if (storage::storage_exists(object::object_address<fungible_asset::Metadata>(&_v0))) abort 12;
    }
    public fun get_config(p0: u32, p1: u32): Config
        acquires State
    {
        let _v0 = @0x3bcacb561438c55ce2a9da479df6ab486af55b2fb7070b700df36c097da732b8;
        let _v1 = object::create_object_address(&_v0, vector[70u8, 79u8, 82u8, 87u8, 65u8, 82u8, 68u8, 69u8, 82u8]);
        let _v2 = borrow_global<State>(_v1);
        let _v3 = ConfigId{don_id: p0, config_version: p1};
        *smart_table::borrow<ConfigId, Config>(&_v2.configs, _v3)
    }
    public fun get_owner(): address
        acquires State
    {
        let _v0 = @0x3bcacb561438c55ce2a9da479df6ab486af55b2fb7070b700df36c097da732b8;
        let _v1 = object::create_object_address(&_v0, vector[70u8, 79u8, 82u8, 87u8, 65u8, 82u8, 68u8, 69u8, 82u8]);
        *&borrow_global<State>(_v1).owner_address
    }
    public fun get_transmission_state(p0: address, p1: vector<u8>, p2: u16): bool
        acquires State
    {
        let _v0 = @0x3bcacb561438c55ce2a9da479df6ab486af55b2fb7070b700df36c097da732b8;
        let _v1 = object::create_object_address(&_v0, vector[70u8, 79u8, 82u8, 87u8, 65u8, 82u8, 68u8, 69u8, 82u8]);
        let _v2 = borrow_global<State>(_v1);
        let _v3 = p0;
        let _v4 = p2;
        let _v5 = bcs::to_bytes<address>(&_v3);
        vector::append<u8>(&mut _v5, p1);
        let _v6 = &mut _v5;
        let _v7 = bcs::to_bytes<u16>(&_v4);
        vector::append<u8>(_v6, _v7);
        smart_table::contains<vector<u8>, address>(&_v2.reports, _v5)
    }
    public fun get_transmitter(p0: address, p1: vector<u8>, p2: u16): option::Option<address>
        acquires State
    {
        let _v0 = @0x3bcacb561438c55ce2a9da479df6ab486af55b2fb7070b700df36c097da732b8;
        let _v1 = object::create_object_address(&_v0, vector[70u8, 79u8, 82u8, 87u8, 65u8, 82u8, 68u8, 69u8, 82u8]);
        let _v2 = borrow_global<State>(_v1);
        let _v3 = p0;
        let _v4 = p2;
        let _v5 = bcs::to_bytes<address>(&_v3);
        vector::append<u8>(&mut _v5, p1);
        let _v6 = &mut _v5;
        let _v7 = bcs::to_bytes<u16>(&_v4);
        vector::append<u8>(_v6, _v7);
        p1 = _v5;
        if (!smart_table::contains<vector<u8>, address>(&_v2.reports, p1)) return option::none<address>();
        option::some<address>(*smart_table::borrow<vector<u8>, address>(&_v2.reports, p1))
    }
    entry fun report(p0: &signer, p1: address, p2: vector<u8>, p3: vector<vector<u8>>)
        acquires State
    {
        let _v0 = vector::empty<Signature>();
        let _v1 = p3;
        vector::reverse<vector<u8>>(&mut _v1);
        let _v2 = _v1;
        let _v3 = vector::length<vector<u8>>(&_v2);
        while (_v3 > 0) {
            let _v4 = vector::pop_back<vector<u8>>(&mut _v2);
            let _v5 = &mut _v0;
            let _v6 = signature_from_bytes(_v4);
            vector::push_back<Signature>(_v5, _v6);
            _v3 = _v3 - 1;
            continue
        };
        vector::destroy_empty<vector<u8>>(_v2);
        let (_v7,_v8) = validate_and_process_report(p0, p1, p2, _v0);
        dispatch(p1, _v7, _v8);
    }
    fun validate_and_process_report(p0: &signer, p1: address, p2: vector<u8>, p3: vector<Signature>): (vector<u8>, vector<u8>)
        acquires State
    {
        let _v0 = @0x3bcacb561438c55ce2a9da479df6ab486af55b2fb7070b700df36c097da732b8;
        let _v1 = object::create_object_address(&_v0, vector[70u8, 79u8, 82u8, 87u8, 65u8, 82u8, 68u8, 69u8, 82u8]);
        let _v2 = borrow_global_mut<State>(_v1);
        let _v3 = &p2;
        let _v4 = vector::length<u8>(&p2);
        let _v5 = vector::slice<u8>(_v3, 96, _v4);
        assert!(*vector::borrow<u8>(&_v5, 0) == 1u8, 16);
        let _v6 = vector::slice<u8>(&_v5, 1, 33);
        let _v7 = vector::slice<u8>(&_v5, 37, 41);
        vector::reverse<u8>(&mut _v7);
        let _v8 = from_bcs::to_u32(_v7);
        let _v9 = vector::slice<u8>(&_v5, 41, 45);
        vector::reverse<u8>(&mut _v9);
        let _v10 = from_bcs::to_u32(_v9);
        let _v11 = vector::slice<u8>(&_v5, 107, 109);
        vector::reverse<u8>(&mut _v11);
        let _v12 = from_bcs::to_u16(_v11);
        let _v13 = vector::slice<u8>(&_v5, 45, 109);
        let _v14 = &_v5;
        let _v15 = vector::length<u8>(&_v5);
        let _v16 = vector::slice<u8>(_v14, 109, _v15);
        let _v17 = ConfigId{don_id: _v8, config_version: _v10};
        assert!(smart_table::contains<ConfigId, Config>(&_v2.configs, _v17), 15);
        let _v18 = smart_table::borrow<ConfigId, Config>(&_v2.configs, _v17);
        let _v19 = p1;
        let _v20 = _v6;
        let _v21 = _v12;
        let _v22 = bcs::to_bytes<address>(&_v19);
        vector::append<u8>(&mut _v22, _v20);
        let _v23 = &mut _v22;
        let _v24 = bcs::to_bytes<u16>(&_v21);
        vector::append<u8>(_v23, _v24);
        _v20 = _v22;
        if (smart_table::contains<vector<u8>, address>(&_v2.reports, _v20)) abort 6;
        let _v25 = ((*&_v18.f) as u64) + 1;
        if (!(vector::length<Signature>(&p3) == _v25)) {
            let _v26 = error::invalid_argument(4);
            abort _v26
        };
        let _v27 = aptos_hash::blake2b_256(p2);
        let _v28 = bit_vector::new(vector::length<ed25519::UnvalidatedPublicKey>(&_v18.oracles));
        let _v29 = &p3;
        _v25 = 0;
        let _v30 = vector::length<Signature>(_v29);
        'l0: loop {
            'l1: loop {
                'l2: loop {
                    loop {
                        if (!(_v25 < _v30)) break 'l0;
                        let _v31 = vector::borrow<Signature>(_v29, _v25);
                        let _v32 = &_v18.oracles;
                        let _v33 = &_v31.public_key;
                        let (_v34,_v35) = vector::index_of<ed25519::UnvalidatedPublicKey>(_v32, _v33);
                        let _v36 = _v35;
                        if (!_v34) break 'l1;
                        if (bit_vector::is_index_set(&_v28, _v36)) break 'l2;
                        bit_vector::set(&mut _v28, _v36);
                        let _v37 = &_v31.sig;
                        let _v38 = &_v31.public_key;
                        if (!ed25519::signature_verify_strict(_v37, _v38, _v27)) break;
                        _v25 = _v25 + 1;
                        continue
                    };
                    let _v39 = error::invalid_argument(5);
                    abort _v39
                };
                let _v40 = error::invalid_argument(3);
                abort _v40
            };
            let _v41 = error::invalid_argument(2);
            abort _v41
        };
        let _v42 = &mut _v2.reports;
        let _v43 = signer::address_of(p0);
        smart_table::add<vector<u8>, address>(_v42, _v20, _v43);
        event::emit<ReportProcessed>(ReportProcessed{receiver: p1, workflow_execution_id: _v6, report_id: _v12});
        (_v13, _v16)
    }
    public entry fun transfer_ownership(p0: &signer, p1: address)
        acquires State
    {
        let _v0 = @0x3bcacb561438c55ce2a9da479df6ab486af55b2fb7070b700df36c097da732b8;
        let _v1 = object::create_object_address(&_v0, vector[70u8, 79u8, 82u8, 87u8, 65u8, 82u8, 68u8, 69u8, 82u8]);
        let _v2 = borrow_global_mut<State>(_v1);
        let _v3 = freeze(_v2);
        let _v4 = signer::address_of(p0);
        if (!(*&_v3.owner_address == _v4)) {
            let _v5 = error::permission_denied(7);
            abort _v5
        };
        if (!(*&_v2.owner_address != p1)) {
            let _v6 = error::invalid_argument(13);
            abort _v6
        };
        let _v7 = &mut _v2.pending_owner_address;
        *_v7 = p1;
        event::emit<OwnershipTransferRequested>(OwnershipTransferRequested{from: *&_v2.owner_address, to: p1});
    }
}
