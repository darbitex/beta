module 0xcd21066689eb2b346b7cc9f61dd8836693435ef7663725da41075f7a02bae3ae::fee_sharer {
    use 0x1::object;
    use 0x1::fungible_asset;
    use 0xd6e31e55a750d442bcfb60bbf842d152b102ffa5ac3ae3f2c8b43748c36a3e6f::reward;
    use 0x1::primary_fungible_store;
    use 0x1::event;
    use 0x1::signer;
    struct DistributeEvent has copy, drop, store {
        share_asset_metadata: object::Object<fungible_asset::Metadata>,
        amount: u64,
    }
    struct AcceptAdminEvent has copy, drop, store {
        old_admin: address,
        new_admin: address,
    }
    struct Share has copy, drop, store {
        account: address,
        shares: u64,
    }
    struct ShareInfo has copy, key {
        admin: address,
        pending_admin: address,
        share_record: vector<Share>,
        total_shares: u64,
    }
    struct ShareInfoUpdatedEvent has copy, drop, store {
    }
    struct TransferAdminEvent has copy, drop, store {
        admin: address,
        pending_admin: address,
    }
    public fun distribute(p0: fungible_asset::FungibleAsset)
        acquires ShareInfo
    {
        let _v0 = info_address();
        let _v1 = borrow_global<ShareInfo>(_v0);
        let _v2 = fungible_asset::metadata_from_asset(&p0);
        let _v3 = fungible_asset::amount(&p0);
        let _v4 = 0x1::vector::length<Share>(&_v1.share_record);
        let _v5 = 0;
        'l0: loop {
            loop {
                let _v6;
                let _v7;
                let _v8;
                let _v9;
                let _v10;
                let _v11;
                if (!(_v5 < _v4)) break 'l0;
                let _v12 = *0x1::vector::borrow<Share>(&_v1.share_record, _v5);
                let _v13 = _v4 - 1;
                if (_v5 == _v13) {
                    let _v14 = *&0x1::vector::borrow<Share>(&_v1.share_record, _v5).shares;
                    _v11 = _v3;
                    _v10 = *&_v1.total_shares;
                    let _v15 = _v14 as u128;
                    let _v16 = _v11 as u128;
                    _v9 = _v15 * _v16;
                    let _v17 = _v10 as u128;
                    let _v18 = _v9 % _v17;
                    let _v19 = _v10 as u128;
                    _v8 = (_v9 / _v19) as u64;
                    if (_v18 > 0u128) _v7 = true else _v7 = false;
                    if (_v7) _v8 = _v8 + 1;
                    _v11 = _v8;
                    _v10 = fungible_asset::amount(&p0);
                    if (!(_v10 - _v11 < _v4)) break;
                    _v6 = fungible_asset::extract(&mut p0, _v10)
                } else {
                    let _v20 = *&0x1::vector::borrow<Share>(&_v1.share_record, _v5).shares;
                    _v11 = _v3;
                    _v10 = *&_v1.total_shares;
                    let _v21 = _v20 as u128;
                    let _v22 = _v11 as u128;
                    _v9 = _v21 * _v22;
                    let _v23 = _v10 as u128;
                    let _v24 = _v9 % _v23;
                    let _v25 = _v10 as u128;
                    _v8 = (_v9 / _v25) as u64;
                    if (_v24 > 0u128) _v7 = false else _v7 = false;
                    if (_v7) _v8 = _v8 + 1;
                    _v11 = _v8;
                    _v6 = fungible_asset::extract(&mut p0, _v11)
                };
                if (*&(&_v12).account == @0x1111) reward::deposit_fa(_v6) else primary_fungible_store::deposit(*&(&_v12).account, _v6);
                _v5 = _v5 + 1;
                continue
            };
            abort 2
        };
        fungible_asset::destroy_zero(p0);
        event::emit<DistributeEvent>(DistributeEvent{share_asset_metadata: _v2, amount: _v3});
    }
    public fun info_address(): address {
        let _v0 = @0xcd21066689eb2b346b7cc9f61dd8836693435ef7663725da41075f7a02bae3ae;
        object::create_object_address(&_v0, vector[83u8, 72u8, 65u8, 82u8, 69u8, 82u8])
    }
    fun init_module(p0: &signer) {
        let _v0 = object::create_named_object(p0, vector[83u8, 72u8, 65u8, 82u8, 69u8, 82u8]);
        let _v1 = object::generate_signer(&_v0);
        let _v2 = &_v1;
        let _v3 = Share{account: @0x53e2555324ecbcf9cc400ed61367d7eec98adb2257e5dc076049a5f9446454d8, shares: 100};
        let _v4 = Share{account: @0xb234295d75ac6cf0b4e07456a442fb0df83afc2f388ecf3e764865029f8e0d40, shares: 100};
        let _v5 = 0x1::vector::empty<Share>();
        let _v6 = &mut _v5;
        0x1::vector::push_back<Share>(_v6, _v3);
        0x1::vector::push_back<Share>(_v6, _v4);
        let _v7 = ShareInfo{admin: @0x2ca474374306b35932c1390b9df747b6da555ad9b15f1557fb79a7bc97472c8, pending_admin: @0x0, share_record: _v5, total_shares: 200};
        move_to<ShareInfo>(_v2, _v7);
    }
    entry fun accept_admin(p0: &signer)
        acquires ShareInfo
    {
        let _v0 = info_address();
        let _v1 = borrow_global_mut<ShareInfo>(_v0);
        let _v2 = signer::address_of(p0);
        let _v3 = *&_v1.pending_admin;
        assert!(_v2 == _v3, 3);
        let _v4 = *&_v1.admin;
        let _v5 = *&_v1.pending_admin;
        let _v6 = &mut _v1.admin;
        *_v6 = _v5;
        let _v7 = &mut _v1.pending_admin;
        *_v7 = @0x0;
        let _v8 = *&_v1.admin;
        event::emit<AcceptAdminEvent>(AcceptAdminEvent{old_admin: _v4, new_admin: _v8});
    }
    entry fun distribute_entry(p0: &signer, p1: object::Object<fungible_asset::Metadata>, p2: u64)
        acquires ShareInfo
    {
        distribute(primary_fungible_store::withdraw<fungible_asset::Metadata>(p0, p1, p2));
    }
    public fun share_info(): vector<Share>
        acquires ShareInfo
    {
        let _v0 = info_address();
        *&borrow_global<ShareInfo>(_v0).share_record
    }
    entry fun transfer_admin(p0: &signer, p1: address)
        acquires ShareInfo
    {
        let _v0 = info_address();
        let _v1 = borrow_global_mut<ShareInfo>(_v0);
        let _v2 = signer::address_of(p0);
        let _v3 = *&_v1.admin;
        assert!(_v2 == _v3, 1);
        let _v4 = &mut _v1.pending_admin;
        *_v4 = p1;
        let _v5 = *&_v1.admin;
        let _v6 = *&_v1.pending_admin;
        event::emit<TransferAdminEvent>(TransferAdminEvent{admin: _v5, pending_admin: _v6});
    }
    entry fun update_share_info(p0: &signer, p1: vector<address>, p2: vector<u64>)
        acquires ShareInfo
    {
        let _v0;
        let _v1 = info_address();
        let _v2 = borrow_global_mut<ShareInfo>(_v1);
        let _v3 = signer::address_of(p0);
        let _v4 = *&_v2.admin;
        assert!(_v3 == _v4, 1);
        let _v5 = 0x1::vector::empty<Share>();
        let _v6 = 0;
        let _v7 = &p1;
        let _v8 = 0;
        let _v9 = 0x1::vector::length<address>(_v7);
        while (_v8 < _v9) {
            let _v10 = _v8;
            let _v11 = *0x1::vector::borrow<address>(_v7, _v8);
            _v10 = *0x1::vector::borrow<u64>(&p2, _v10);
            _v0 = &mut _v5;
            let _v12 = Share{account: _v11, shares: _v10};
            0x1::vector::push_back<Share>(_v0, _v12);
            _v6 = _v6 + _v10;
            _v8 = _v8 + 1;
            continue
        };
        let _v13 = &mut _v2.total_shares;
        *_v13 = _v6;
        _v0 = &mut _v2.share_record;
        *_v0 = _v5;
    }
}
