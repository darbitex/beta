module 0x661799897c0d2e94c1de976cb3f0e344672c71871e50188622d1b9192723b44c::commission {
    use 0x1::string;
    use 0x1::object;
    use 0x1::fungible_asset;
    use 0x5dd39b261199f6f9232b67c4662248333707328adbc750ba921a8df1599dc31f::context;
    use 0x1::option;
    use 0x1::from_bcs;
    use 0x661799897c0d2e94c1de976cb3f0e344672c71871e50188622d1b9192723b44c::math;
    use 0x1::event;
    use 0x1::primary_fungible_store;
    use 0xcd21066689eb2b346b7cc9f61dd8836693435ef7663725da41075f7a02bae3ae::fee_sharer;
    struct CommissionEvent has copy, drop, store {
        identifier: string::String,
        amount: u64,
        metadata: object::Object<fungible_asset::Metadata>,
        commission_address: address,
    }
    public fun distribute(p0: fungible_asset::FungibleAsset) {
        let _v0 = fungible_asset::amount(&p0);
        let _v1 = context::get_data_value(string::utf8(vector[112u8, 97u8, 114u8, 116u8, 110u8, 101u8, 114u8, 115u8, 104u8, 105u8, 112u8]));
        if (option::is_some<vector<u8>>(&_v1)) {
            let _v2;
            let _v3;
            let _v4 = from_bcs::to_string(option::destroy_some<vector<u8>>(_v1));
            let _v5 = string::utf8(vector[80u8, 97u8, 110u8, 111u8, 114u8, 97u8]);
            if (_v4 == _v5) _v3 = true else {
                let _v6 = string::utf8(vector[116u8, 97u8, 111u8, 108u8, 105u8, 95u8, 116u8, 111u8, 111u8, 108u8, 115u8]);
                _v3 = _v4 == _v6
            };
            if (_v3) _v2 = true else {
                let _v7 = string::utf8(vector[99u8, 97u8, 97u8, 115u8]);
                _v2 = _v4 == _v7
            };
            if (_v2) {
                let _v8;
                let _v9 = string::utf8(vector[80u8, 97u8, 110u8, 111u8, 114u8, 97u8]);
                if (_v4 == _v9) _v8 = @0xd0b17bea776bb87b70b2fb2ca631014f0ca94fc1acde4b8ff1a763f4172aa6c4 else {
                    let _v10 = string::utf8(vector[116u8, 97u8, 111u8, 108u8, 105u8, 95u8, 116u8, 111u8, 111u8, 108u8, 115u8]);
                    if (_v4 == _v10) _v8 = @0x363d407cd04029ee80761ff78a16051c725faa5109ad0be1af95a56923f791ea else _v8 = @0xcd320268d1a8dfb91b9292fa6a32a64e8c5521474dfaeffd60867f893da0f561
                };
                let _v11 = math::safe_mul_div_u64(_v0, 5000, 10000);
                let _v12 = fungible_asset::extract(&mut p0, _v11);
                let _v13 = fungible_asset::amount(&_v12);
                let _v14 = fungible_asset::metadata_from_asset(&_v12);
                event::emit<CommissionEvent>(CommissionEvent{identifier: _v4, amount: _v13, metadata: _v14, commission_address: _v8});
                primary_fungible_store::deposit(_v8, _v12)
            }
        };
        fee_sharer::distribute(p0);
    }
}
