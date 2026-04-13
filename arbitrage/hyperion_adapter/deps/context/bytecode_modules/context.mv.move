module 0x5dd39b261199f6f9232b67c4662248333707328adbc750ba921a8df1599dc31f::context {
    use 0x1::smart_table;
    use 0x1::string;
    use 0x1::transaction_context;
    use 0x1::option;
    struct Data has copy, drop, store {
        type: DataType,
        value: vector<u8>,
    }
    enum DataType has copy, drop, store {
        U8_type,
        U32_type,
        U64_type,
        U128_type,
        String_type,
        Address_type,
    }
    struct Order {
        txn_id: vector<u8>,
    }
    struct Storage has key {
        data_list: smart_table::SmartTable<string::String, Data>,
        in_use: bool,
    }
    public fun clear(p0: Order)
        acquires Storage
    {
        let _v0 = transaction_context::get_transaction_hash();
        let Order{txn_id: _v1} = p0;
        assert!(_v1 == _v0, 1);
        let _v2 = borrow_global_mut<Storage>(@0x5dd39b261199f6f9232b67c4662248333707328adbc750ba921a8df1599dc31f);
        smart_table::clear<string::String, Data>(&mut _v2.data_list);
        let _v3 = &mut _v2.in_use;
        *_v3 = false;
    }
    public fun get_data_value(p0: string::String): option::Option<vector<u8>>
        acquires Storage
    {
        let _v0;
        let _v1 = borrow_global<Storage>(@0x5dd39b261199f6f9232b67c4662248333707328adbc750ba921a8df1599dc31f);
        if (*&_v1.in_use) if (smart_table::contains<string::String, Data>(&_v1.data_list, p0)) _v0 = option::some<vector<u8>>(*&smart_table::borrow<string::String, Data>(&_v1.data_list, p0).value) else _v0 = option::none<vector<u8>>() else _v0 = option::none<vector<u8>>();
        _v0
    }
    fun init_module(p0: &signer) {
        let _v0 = Storage{data_list: smart_table::new<string::String, Data>(), in_use: false};
        move_to<Storage>(p0, _v0);
    }
    public fun set_data(p0: string::String, p1: DataType, p2: vector<u8>): option::Option<Order>
        acquires Storage
    {
        let _v0;
        let _v1 = borrow_global_mut<Storage>(@0x5dd39b261199f6f9232b67c4662248333707328adbc750ba921a8df1599dc31f);
        let _v2 = &mut _v1.data_list;
        let _v3 = Data{type: p1, value: p2};
        smart_table::add<string::String, Data>(_v2, p0, _v3);
        if (*&_v1.in_use) _v0 = option::none<Order>() else {
            let _v4 = Order{txn_id: transaction_context::get_transaction_hash()};
            let _v5 = &mut _v1.in_use;
            *_v5 = true;
            _v0 = option::some<Order>(_v4)
        };
        _v0
    }
    public fun string_type(): DataType {
        DataType::String_type{}
    }
}
