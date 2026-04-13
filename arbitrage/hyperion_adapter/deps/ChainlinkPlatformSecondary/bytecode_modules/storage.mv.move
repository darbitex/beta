module 0x3bcacb561438c55ce2a9da479df6ab486af55b2fb7070b700df36c097da732b8::storage {
    use 0x1::object;
    use 0x1::fungible_asset;
    use 0x1::table;
    use 0x1::type_info;
    use 0x1::smart_table;
    use 0x1::function_info;
    use 0x1::string;
    use 0x1::option;
    use 0x1::dispatchable_fungible_asset;
    use 0x1::signer;
    use 0x1::vector;
    friend 0x3bcacb561438c55ce2a9da479df6ab486af55b2fb7070b700df36c097da732b8::forwarder;
    struct Entry has drop, store, key {
        metadata: object::Object<fungible_asset::Metadata>,
        extend_ref: object::ExtendRef,
    }
    struct Dispatcher has key {
        dispatcher: table::Table<type_info::TypeInfo, Entry>,
        address_to_typeinfo: table::Table<address, type_info::TypeInfo>,
        extend_ref: object::ExtendRef,
        transfer_ref: object::TransferRef,
    }
    struct DispatcherV2 has key {
        dispatcher: smart_table::SmartTable<type_info::TypeInfo, Entry>,
        address_to_typeinfo: smart_table::SmartTable<address, type_info::TypeInfo>,
    }
    struct ReportMetadata has drop, store, key {
        workflow_cid: vector<u8>,
        workflow_name: vector<u8>,
        workflow_owner: vector<u8>,
        report_id: vector<u8>,
    }
    struct Storage has drop, key {
        metadata: vector<u8>,
        data: vector<u8>,
    }
    friend fun insert(p0: address, p1: vector<u8>, p2: vector<u8>): object::Object<fungible_asset::Metadata>
        acquires Dispatcher, DispatcherV2
    {
        let _v0;
        let _v1;
        let _v2;
        let _v3 = @0x3bcacb561438c55ce2a9da479df6ab486af55b2fb7070b700df36c097da732b8;
        let _v4 = object::create_object_address(&_v3, vector[83u8, 84u8, 79u8, 82u8, 65u8, 71u8, 69u8]);
        let _v5 = exists<DispatcherV2>(_v4);
        'l0: loop {
            let _v6;
            loop {
                if (!_v5) {
                    let _v7 = @0x3bcacb561438c55ce2a9da479df6ab486af55b2fb7070b700df36c097da732b8;
                    let _v8 = object::create_object_address(&_v7, vector[83u8, 84u8, 79u8, 82u8, 65u8, 71u8, 69u8]);
                    _v6 = borrow_global<Dispatcher>(_v8);
                    _v2 = *table::borrow<address, type_info::TypeInfo>(&_v6.address_to_typeinfo, p0);
                    if (table::contains<type_info::TypeInfo, Entry>(&_v6.dispatcher, _v2)) break;
                    abort 1
                };
                let _v9 = @0x3bcacb561438c55ce2a9da479df6ab486af55b2fb7070b700df36c097da732b8;
                let _v10 = object::create_object_address(&_v9, vector[83u8, 84u8, 79u8, 82u8, 65u8, 71u8, 69u8]);
                _v1 = borrow_global<DispatcherV2>(_v10);
                _v2 = *smart_table::borrow<address, type_info::TypeInfo>(&_v1.address_to_typeinfo, p0);
                if (smart_table::contains<type_info::TypeInfo, Entry>(&_v1.dispatcher, _v2)) break 'l0;
                abort 1
            };
            _v0 = table::borrow<type_info::TypeInfo, Entry>(&_v6.dispatcher, _v2);
            let _v11 = &_v0.metadata;
            let _v12 = object::generate_signer_for_extending(&_v0.extend_ref);
            let _v13 = &_v12;
            let _v14 = Storage{metadata: p1, data: p2};
            move_to<Storage>(_v13, _v14);
            return *_v11
        };
        _v0 = smart_table::borrow<type_info::TypeInfo, Entry>(&_v1.dispatcher, _v2);
        let _v15 = &_v0.metadata;
        let _v16 = object::generate_signer_for_extending(&_v0.extend_ref);
        let _v17 = &_v16;
        let _v18 = Storage{metadata: p1, data: p2};
        move_to<Storage>(_v17, _v18);
        *_v15
    }
    public fun register<T0: drop>(p0: &signer, p1: function_info::FunctionInfo, p2: T0)
        acquires Dispatcher, DispatcherV2
    {
        let _v0 = type_info::type_name<T0>();
        let _v1 = @0x3bcacb561438c55ce2a9da479df6ab486af55b2fb7070b700df36c097da732b8;
        let _v2 = object::create_object_address(&_v1, vector[83u8, 84u8, 79u8, 82u8, 65u8, 71u8, 69u8]);
        let _v3 = object::generate_signer_for_extending(&borrow_global<Dispatcher>(_v2).extend_ref);
        let _v4 = &_v3;
        let _v5 = *string::bytes(&_v0);
        let _v6 = object::create_named_object(_v4, _v5);
        let _v7 = object::generate_extend_ref(&_v6);
        let _v8 = &_v6;
        let _v9 = option::none<u128>();
        let _v10 = string::utf8(vector[115u8, 116u8, 111u8, 114u8, 97u8, 103u8, 101u8]);
        let _v11 = string::utf8(vector[100u8, 105u8, 115u8]);
        let _v12 = string::utf8(vector[]);
        let _v13 = string::utf8(vector[]);
        let _v14 = fungible_asset::add_fungibility(_v8, _v9, _v10, _v11, 0u8, _v12, _v13);
        let _v15 = &_v6;
        let _v16 = option::some<function_info::FunctionInfo>(p1);
        dispatchable_fungible_asset::register_derive_supply_dispatch_function(_v15, _v16);
        let _v17 = @0x3bcacb561438c55ce2a9da479df6ab486af55b2fb7070b700df36c097da732b8;
        let _v18 = object::create_object_address(&_v17, vector[83u8, 84u8, 79u8, 82u8, 65u8, 71u8, 69u8]);
        let _v19 = borrow_global_mut<DispatcherV2>(_v18);
        let _v20 = &mut _v19.dispatcher;
        let _v21 = type_info::type_of<T0>();
        let _v22 = Entry{metadata: _v14, extend_ref: _v7};
        smart_table::add<type_info::TypeInfo, Entry>(_v20, _v21, _v22);
        let _v23 = &mut _v19.address_to_typeinfo;
        let _v24 = signer::address_of(p0);
        let _v25 = type_info::type_of<T0>();
        smart_table::add<address, type_info::TypeInfo>(_v23, _v24, _v25);
    }
    public fun get_report_metadata_report_id(p0: &ReportMetadata): vector<u8> {
        *&p0.report_id
    }
    public fun get_report_metadata_workflow_cid(p0: &ReportMetadata): vector<u8> {
        *&p0.workflow_cid
    }
    public fun get_report_metadata_workflow_name(p0: &ReportMetadata): vector<u8> {
        *&p0.workflow_name
    }
    public fun get_report_metadata_workflow_owner(p0: &ReportMetadata): vector<u8> {
        *&p0.workflow_owner
    }
    fun init_module(p0: &signer) {
        assert!(signer::address_of(p0) == @0x3bcacb561438c55ce2a9da479df6ab486af55b2fb7070b700df36c097da732b8, 1);
        let _v0 = object::create_named_object(p0, vector[83u8, 84u8, 79u8, 82u8, 65u8, 71u8, 69u8]);
        let _v1 = object::generate_extend_ref(&_v0);
        let _v2 = object::generate_transfer_ref(&_v0);
        let _v3 = object::generate_signer(&_v0);
        let _v4 = &_v3;
        let _v5 = table::new<type_info::TypeInfo, Entry>();
        let _v6 = table::new<address, type_info::TypeInfo>();
        let _v7 = Dispatcher{dispatcher: _v5, address_to_typeinfo: _v6, extend_ref: _v1, transfer_ref: _v2};
        move_to<Dispatcher>(_v4, _v7);
        let _v8 = &_v3;
        let _v9 = smart_table::new<type_info::TypeInfo, Entry>();
        let _v10 = smart_table::new<address, type_info::TypeInfo>();
        let _v11 = DispatcherV2{dispatcher: _v9, address_to_typeinfo: _v10};
        move_to<DispatcherV2>(_v8, _v11);
    }
    public entry fun migrate_to_v2(p0: vector<address>)
        acquires Dispatcher, DispatcherV2
    {
        let _v0 = @0x3bcacb561438c55ce2a9da479df6ab486af55b2fb7070b700df36c097da732b8;
        let _v1 = object::create_object_address(&_v0, vector[83u8, 84u8, 79u8, 82u8, 65u8, 71u8, 69u8]);
        if (!exists<DispatcherV2>(_v1)) {
            let _v2 = @0x3bcacb561438c55ce2a9da479df6ab486af55b2fb7070b700df36c097da732b8;
            let _v3 = object::create_object_address(&_v2, vector[83u8, 84u8, 79u8, 82u8, 65u8, 71u8, 69u8]);
            let _v4 = object::generate_signer_for_extending(&borrow_global<Dispatcher>(_v3).extend_ref);
            let _v5 = &_v4;
            let _v6 = smart_table::new<type_info::TypeInfo, Entry>();
            let _v7 = smart_table::new<address, type_info::TypeInfo>();
            let _v8 = DispatcherV2{dispatcher: _v6, address_to_typeinfo: _v7};
            move_to<DispatcherV2>(_v5, _v8)
        };
        let _v9 = borrow_global_mut<Dispatcher>(_v1);
        let _v10 = borrow_global_mut<DispatcherV2>(_v1);
        let _v11 = &p0;
        let _v12 = 0;
        let _v13 = vector::length<address>(_v11);
        while (_v12 < _v13) {
            let _v14 = vector::borrow<address>(_v11, _v12);
            let _v15 = &mut _v9.address_to_typeinfo;
            let _v16 = *_v14;
            let _v17 = table::remove<address, type_info::TypeInfo>(_v15, _v16);
            let _v18 = table::remove<type_info::TypeInfo, Entry>(&mut _v9.dispatcher, _v17);
            let _v19 = &mut _v10.address_to_typeinfo;
            let _v20 = *_v14;
            smart_table::add<address, type_info::TypeInfo>(_v19, _v20, _v17);
            smart_table::add<type_info::TypeInfo, Entry>(&mut _v10.dispatcher, _v17, _v18);
            _v12 = _v12 + 1;
            continue
        };
    }
    public fun parse_report_metadata(p0: vector<u8>): ReportMetadata {
        assert!(vector::length<u8>(&p0) == 64, 2);
        let _v0 = vector::slice<u8>(&p0, 0, 32);
        let _v1 = vector::slice<u8>(&p0, 32, 42);
        let _v2 = vector::slice<u8>(&p0, 42, 62);
        let _v3 = vector::slice<u8>(&p0, 62, 64);
        ReportMetadata{workflow_cid: _v0, workflow_name: _v1, workflow_owner: _v2, report_id: _v3}
    }
    public fun retrieve<T0: drop>(p0: T0): (vector<u8>, vector<u8>)
        acquires Dispatcher, DispatcherV2, Storage
    {
        let _v0;
        let _v1 = @0x3bcacb561438c55ce2a9da479df6ab486af55b2fb7070b700df36c097da732b8;
        let _v2 = object::create_object_address(&_v1, vector[83u8, 84u8, 79u8, 82u8, 65u8, 71u8, 69u8]);
        if (!exists<DispatcherV2>(_v2)) {
            let _v3 = @0x3bcacb561438c55ce2a9da479df6ab486af55b2fb7070b700df36c097da732b8;
            let _v4 = object::create_object_address(&_v3, vector[83u8, 84u8, 79u8, 82u8, 65u8, 71u8, 69u8]);
            let _v5 = borrow_global<Dispatcher>(_v4);
            _v0 = type_info::type_of<T0>();
            let _v6 = object::address_from_extend_ref(&table::borrow<type_info::TypeInfo, Entry>(&_v5.dispatcher, _v0).extend_ref);
            let _v7 = move_from<Storage>(_v6);
            let _v8 = *&(&_v7).metadata;
            let _v9 = *&(&_v7).data;
            return (_v8, _v9)
        };
        let _v10 = @0x3bcacb561438c55ce2a9da479df6ab486af55b2fb7070b700df36c097da732b8;
        let _v11 = object::create_object_address(&_v10, vector[83u8, 84u8, 79u8, 82u8, 65u8, 71u8, 69u8]);
        let _v12 = borrow_global<DispatcherV2>(_v11);
        _v0 = type_info::type_of<T0>();
        let _v13 = object::address_from_extend_ref(&smart_table::borrow<type_info::TypeInfo, Entry>(&_v12.dispatcher, _v0).extend_ref);
        let _v14 = move_from<Storage>(_v13);
        let _v15 = *&(&_v14).metadata;
        let _v16 = *&(&_v14).data;
        (_v15, _v16)
    }
    friend fun storage_exists(p0: address): bool {
        object::object_exists<Storage>(p0)
    }
}
