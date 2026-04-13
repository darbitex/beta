module 0x4bf51972879e3b95c4781a5cdcb9e1ee24ef483e7d22f2d903626f126df62bd1::voting_escrow {
    use 0x1::dispatchable_fungible_asset;
    use 0x1::error;
    use 0x1::event;
    use 0x1::fungible_asset;
    use 0x1::math64;
    use 0x1::object;
    use 0x1::option;
    use 0x1::primary_fungible_store;
    use 0x1::signer;
    use 0x1::smart_table;
    use 0x1::smart_vector;
    use 0x1::string;
    use 0x1::string_utils;
    use 0x1::vector;
    use 0x4::collection;
    use 0x4::royalty;
    use 0x4::token;
    use 0x4bf51972879e3b95c4781a5cdcb9e1ee24ef483e7d22f2d903626f126df62bd1::cellana_token;
    use 0x4bf51972879e3b95c4781a5cdcb9e1ee24ef483e7d22f2d903626f126df62bd1::epoch;
    use 0x4bf51972879e3b95c4781a5cdcb9e1ee24ef483e7d22f2d903626f126df62bd1::package_manager;
    friend 0x4bf51972879e3b95c4781a5cdcb9e1ee24ef483e7d22f2d903626f126df62bd1::vote_manager;
    struct CreateLockEvent has drop, store {
        owner: address,
        amount: u64,
        lockup_end_epoch: u64,
        ve_token: object::Object<VeCellanaToken>,
    }
    struct VeCellanaToken has key {
        locked_amount: u64,
        end_epoch: u64,
        snapshots: smart_vector::SmartVector<TokenSnapshot>,
        next_rebase_epoch: u64,
    }
    struct ExtendLockupEvent has drop, store {
        owner: address,
        old_lockup_end_epoch: u64,
        new_lockup_end_epoch: u64,
        ve_token: object::Object<VeCellanaToken>,
    }
    struct IncreaseAmountEvent has drop, store {
        owner: address,
        old_amount: u64,
        new_amount: u64,
        ve_token: object::Object<VeCellanaToken>,
    }
    struct TokenSnapshot has drop, store {
        epoch: u64,
        locked_amount: u64,
        end_epoch: u64,
    }
    struct VeCellanaCollection has key {
        unscaled_total_voting_power_per_epoch: smart_table::SmartTable<u64, u128>,
        rebases: smart_table::SmartTable<u64, u64>,
    }
    struct VeCellanaDeleteRef has key {
        delete_ref: object::DeleteRef,
    }
    struct VeCellanaTokenRefs has key {
        burn_ref: token::BurnRef,
        transfer_ref: object::TransferRef,
    }
    struct WithdrawEvent has drop, store {
        owner: address,
        amount: u64,
        ve_token: object::Object<VeCellanaToken>,
    }
    public fun locked_amount(p0: object::Object<VeCellanaToken>): u64
        acquires VeCellanaToken
    {
        let _v0 = object::object_address<VeCellanaToken>(&p0);
        *&borrow_global<VeCellanaToken>(_v0).locked_amount
    }
    friend fun add_rebase(p0: fungible_asset::FungibleAsset, p1: u64)
        acquires VeCellanaCollection
    {
        let _v0 = epoch::now();
        assert!(p1 < _v0, 11);
        let _v1 = fungible_asset::amount(&p0);
        assert!(_v1 > 0, 8);
        let _v2 = voting_escrow_collection();
        smart_table::add<u64, u64>(&mut borrow_global_mut<VeCellanaCollection>(_v2).rebases, p1, _v1);
        dispatchable_fungible_asset::deposit<fungible_asset::FungibleStore>(object::address_to_object<fungible_asset::FungibleStore>(voting_escrow_collection()), p0);
    }
    public entry fun claim_rebase(p0: &signer, p1: object::Object<VeCellanaToken>)
        acquires VeCellanaCollection, VeCellanaToken
    {
        let _v0 = signer::address_of(p0);
        assert!(object::is_owner<VeCellanaToken>(p1, _v0), 4);
        let _v1 = object::address_to_object<fungible_asset::FungibleStore>(voting_escrow_collection());
        let _v2 = claimable_rebase_internal(p1);
        if (_v2 > 0) {
            let _v3 = cellana_token::withdraw<fungible_asset::FungibleStore>(_v1, _v2);
            increase_amount_rebase(p1, _v3);
            let _v4 = &p1;
            let _v5 = epoch::now();
            let _v6 = object::object_address<VeCellanaToken>(_v4);
            let _v7 = &mut borrow_global_mut<VeCellanaToken>(_v6).next_rebase_epoch;
            *_v7 = _v5
        };
    }
    public fun claimable_rebase(p0: object::Object<VeCellanaToken>): u64
        acquires VeCellanaCollection, VeCellanaToken
    {
        claimable_rebase_internal(p0)
    }
    fun claimable_rebase_internal(p0: object::Object<VeCellanaToken>): u64
        acquires VeCellanaCollection, VeCellanaToken
    {
        let _v0 = voting_escrow_collection();
        let _v1 = borrow_global<VeCellanaCollection>(_v0);
        let _v2 = object::object_address<VeCellanaToken>(&p0);
        let _v3 = *&borrow_global<VeCellanaToken>(_v2).next_rebase_epoch;
        let _v4 = 0u128;
        'l0: loop {
            loop {
                let _v5 = epoch::now();
                if (!(_v3 < _v5)) break 'l0;
                let _v6 = &_v1.rebases;
                let _v7 = 0;
                let _v8 = &_v7;
                let _v9 = (*smart_table::borrow_with_default<u64, u64>(_v6, _v3, _v8)) as u128;
                if (_v9 > 0u128) {
                    let _v10;
                    let _v11 = get_voting_power_at_epoch(p0, _v3) as u128;
                    let _v12 = &_v1.unscaled_total_voting_power_per_epoch;
                    let _v13 = _v3;
                    let _v14 = _v12;
                    if (!smart_table::contains<u64, u128>(_v14, _v13)) _v10 = 0u128 else {
                        let _v15 = *smart_table::borrow<u64, u128>(_v14, _v13);
                        let _v16 = 104 as u128;
                        _v10 = _v15 / _v16
                    };
                    let _v17 = _v10;
                    if (!(_v17 != 0u128)) break;
                    let _v18 = _v11 as u256;
                    let _v19 = _v9 as u256;
                    let _v20 = _v18 * _v19;
                    let _v21 = _v17 as u256;
                    let _v22 = (_v20 / _v21) as u128;
                    _v4 = _v4 + _v22
                };
                _v3 = _v3 + 1;
                continue
            };
            let _v23 = error::invalid_argument(4);
            abort _v23
        };
        _v4 as u64
    }
    public fun create_lock(p0: &signer, p1: u64, p2: u64): object::Object<VeCellanaToken>
        acquires VeCellanaCollection
    {
        let _v0 = cellana_token::token();
        let _v1 = primary_fungible_store::withdraw<cellana_token::CellanaToken>(p0, _v0, p1);
        let _v2 = signer::address_of(p0);
        create_lock_with(_v1, p2, _v2)
    }
    public entry fun create_lock_entry(p0: &signer, p1: u64, p2: u64)
        acquires VeCellanaCollection
    {
        let _v0 = create_lock(p0, p1, p2);
    }
    public entry fun create_lock_for(p0: &signer, p1: u64, p2: u64, p3: address)
        acquires VeCellanaCollection
    {
        let _v0 = cellana_token::token();
        let _v1 = create_lock_with(primary_fungible_store::withdraw<cellana_token::CellanaToken>(p0, _v0, p1), p2, p3);
    }
    public fun create_lock_with(p0: fungible_asset::FungibleAsset, p1: u64, p2: address): object::Object<VeCellanaToken>
        acquires VeCellanaCollection
    {
        let _v0 = fungible_asset::amount(&p0);
        assert!(_v0 > 0, 8);
        let _v1 = p1;
        assert!(_v1 >= 2, 2);
        assert!(_v1 <= 104, 3);
        let _v2 = cellana_token::token();
        let _v3 = fungible_asset::asset_metadata(&p0);
        let _v4 = object::convert<cellana_token::CellanaToken, fungible_asset::Metadata>(_v2);
        assert!(_v3 == _v4, 1);
        let _v5 = package_manager::get_signer();
        let _v6 = &_v5;
        let _v7 = string::utf8(vector[67u8, 101u8, 108u8, 108u8, 97u8, 110u8, 97u8, 32u8, 86u8, 111u8, 116u8, 105u8, 110u8, 103u8, 32u8, 84u8, 111u8, 107u8, 101u8, 110u8, 115u8]);
        let _v8 = string::utf8(vector[78u8, 70u8, 84u8, 32u8, 114u8, 101u8, 112u8, 114u8, 101u8, 115u8, 101u8, 110u8, 116u8, 105u8, 110u8, 103u8, 32u8, 118u8, 111u8, 116u8, 105u8, 110u8, 103u8, 32u8, 112u8, 111u8, 119u8, 101u8, 114u8, 32u8, 105u8, 110u8, 32u8, 67u8, 101u8, 108u8, 108u8, 97u8, 110u8, 97u8, 32u8, 99u8, 111u8, 114u8, 114u8, 101u8, 115u8, 112u8, 111u8, 110u8, 100u8, 105u8, 110u8, 103u8, 32u8, 116u8, 111u8, 32u8, 36u8, 67u8, 69u8, 76u8, 76u8, 32u8, 108u8, 111u8, 99u8, 107u8, 101u8, 100u8, 32u8, 117u8, 112u8]);
        let _v9 = string::utf8(vector[118u8, 101u8, 67u8, 69u8, 76u8, 76u8]);
        let _v10 = option::none<royalty::Royalty>();
        let _v11 = string::utf8(vector[104u8, 116u8, 116u8, 112u8, 115u8, 58u8, 47u8, 47u8, 97u8, 112u8, 105u8, 46u8, 99u8, 101u8, 108u8, 108u8, 97u8, 110u8, 97u8, 46u8, 102u8, 105u8, 110u8, 97u8, 110u8, 99u8, 101u8, 47u8, 97u8, 112u8, 105u8, 47u8, 118u8, 49u8, 47u8, 118u8, 101u8, 45u8, 110u8, 102u8, 116u8, 47u8, 117u8, 114u8, 105u8, 47u8]);
        let _v12 = token::create_from_account(_v6, _v7, _v8, _v9, _v10, _v11);
        let _v13 = &_v12;
        let _v14 = object::generate_signer(_v13);
        let _v15 = &_v14;
        let _v16 = epoch::now() + p1;
        let _v17 = smart_vector::new<TokenSnapshot>();
        let _v18 = epoch::now();
        let _v19 = VeCellanaToken{locked_amount: _v0, end_epoch: _v16, snapshots: _v17, next_rebase_epoch: _v18};
        update_snapshots(&mut _v19, _v0, _v16);
        move_to<VeCellanaToken>(_v15, _v19);
        let _v20 = token::generate_burn_ref(_v13);
        let _v21 = object::generate_transfer_ref(_v13);
        let _v22 = VeCellanaTokenRefs{burn_ref: _v20, transfer_ref: _v21};
        move_to<VeCellanaTokenRefs>(_v15, _v22);
        let _v23 = VeCellanaDeleteRef{delete_ref: object::generate_delete_ref(_v13)};
        move_to<VeCellanaDeleteRef>(_v15, _v23);
        let _v24 = fungible_asset::create_store<cellana_token::CellanaToken>(_v13, _v2);
        dispatchable_fungible_asset::deposit<fungible_asset::FungibleStore>(_v24, p0);
        cellana_token::disable_transfer<fungible_asset::FungibleStore>(_v24);
        object::transfer<fungible_asset::FungibleStore>(_v6, _v24, p2);
        let _v25 = token::generate_mutator_ref(_v13);
        let _v26 = object::object_from_constructor_ref<VeCellanaToken>(_v13);
        let _v27 = string::utf8(vector[104u8, 116u8, 116u8, 112u8, 115u8, 58u8, 47u8, 47u8, 97u8, 112u8, 105u8, 46u8, 99u8, 101u8, 108u8, 108u8, 97u8, 110u8, 97u8, 46u8, 102u8, 105u8, 110u8, 97u8, 110u8, 99u8, 101u8, 47u8, 97u8, 112u8, 105u8, 47u8, 118u8, 49u8, 47u8, 118u8, 101u8, 45u8, 110u8, 102u8, 116u8, 47u8, 117u8, 114u8, 105u8, 47u8]);
        let _v28 = &mut _v27;
        let _v29 = object::object_address<VeCellanaToken>(&_v26);
        let _v30 = string_utils::to_string<address>(&_v29);
        string::append(_v28, _v30);
        token::set_uri(&_v25, _v27);
        event::emit<CreateLockEvent>(CreateLockEvent{owner: p2, amount: _v0, lockup_end_epoch: _v16, ve_token: _v26});
        update_manifested_total_supply(0, 0, _v0, _v16);
        _v26
    }
    fun destroy_snapshots(p0: smart_vector::SmartVector<TokenSnapshot>) {
        let _v0 = 0;
        let _v1 = smart_vector::length<TokenSnapshot>(&p0);
        while (_v0 < _v1) {
            let _v2 = smart_vector::pop_back<TokenSnapshot>(&mut p0);
            _v0 = _v0 + 1;
            continue
        };
        smart_vector::destroy_empty<TokenSnapshot>(p0);
    }
    public entry fun extend_lockup(p0: &signer, p1: object::Object<VeCellanaToken>, p2: u64)
        acquires VeCellanaCollection, VeCellanaToken
    {
        let _v0 = p2;
        assert!(_v0 >= 2, 2);
        assert!(_v0 <= 104, 3);
        let _v1 = p1;
        let _v2 = signer::address_of(p0);
        assert!(object::is_owner<VeCellanaToken>(_v1, _v2), 4);
        let _v3 = object::object_address<VeCellanaToken>(&_v1);
        let _v4 = borrow_global_mut<VeCellanaToken>(_v3);
        let _v5 = *&_v4.end_epoch;
        let _v6 = epoch::now() + p2;
        assert!(_v6 > _v5, 7);
        let _v7 = &mut _v4.end_epoch;
        *_v7 = _v6;
        let _v8 = *&_v4.locked_amount;
        event::emit<ExtendLockupEvent>(ExtendLockupEvent{owner: signer::address_of(p0), old_lockup_end_epoch: _v5, new_lockup_end_epoch: _v6, ve_token: p1});
        update_snapshots(_v4, _v8, _v6);
        update_manifested_total_supply(_v8, _v5, _v8, _v6);
    }
    friend fun freeze_token(p0: object::Object<VeCellanaToken>)
        acquires VeCellanaTokenRefs
    {
        let _v0 = object::object_address<VeCellanaToken>(&p0);
        object::disable_ungated_transfer(&borrow_global<VeCellanaTokenRefs>(_v0).transfer_ref);
    }
    public fun get_lockup_expiration_epoch(p0: object::Object<VeCellanaToken>): u64
        acquires VeCellanaToken
    {
        let _v0 = object::object_address<VeCellanaToken>(&p0);
        *&borrow_global<VeCellanaToken>(_v0).end_epoch
    }
    public fun get_lockup_expiration_time(p0: object::Object<VeCellanaToken>): u64
        acquires VeCellanaToken
    {
        get_lockup_expiration_epoch(p0) * 604800
    }
    public fun get_voting_power(p0: object::Object<VeCellanaToken>): u64
        acquires VeCellanaToken
    {
        let _v0 = epoch::now();
        get_voting_power_at_epoch(p0, _v0)
    }
    public fun get_voting_power_at_epoch(p0: object::Object<VeCellanaToken>, p1: u64): u64
        acquires VeCellanaToken
    {
        let _v0;
        let _v1;
        let _v2;
        let _v3 = object::object_address<VeCellanaToken>(&p0);
        let _v4 = borrow_global<VeCellanaToken>(_v3);
        let _v5 = epoch::now();
        if (p1 == _v5) {
            let _v6 = *&_v4.locked_amount;
            _v1 = *&_v4.end_epoch;
            _v2 = _v6
        } else {
            let _v7 = &_v4.snapshots;
            let _v8 = smart_vector::length<TokenSnapshot>(_v7);
            loop {
                let _v9;
                if (_v8 > 0) {
                    let _v10 = _v8 - 1;
                    _v9 = *&smart_vector::borrow<TokenSnapshot>(_v7, _v10).epoch > p1
                } else _v9 = false;
                if (!_v9) break;
                _v8 = _v8 - 1;
                continue
            };
            if (_v8 > 0) {
                let _v11 = _v8 - 1;
                let _v12 = smart_vector::borrow<TokenSnapshot>(_v7, _v11);
                let _v13 = *&_v12.locked_amount;
                _v1 = *&_v12.end_epoch;
                _v2 = _v13
            } else abort 9
        };
        let _v14 = _v1;
        if (_v14 <= p1) _v0 = 0 else {
            let _v15 = _v14 - p1;
            _v0 = _v2 * _v15 / 104
        };
        _v0
    }
    public fun increase_amount(p0: &signer, p1: object::Object<VeCellanaToken>, p2: fungible_asset::FungibleAsset)
        acquires VeCellanaCollection, VeCellanaToken
    {
        let _v0 = signer::address_of(p0);
        assert!(object::is_owner<VeCellanaToken>(p1, _v0), 4);
        increase_amount_internal(p1, p2);
    }
    public entry fun increase_amount_entry(p0: &signer, p1: object::Object<VeCellanaToken>, p2: u64)
        acquires VeCellanaCollection, VeCellanaToken
    {
        let _v0 = cellana_token::token();
        let _v1 = primary_fungible_store::withdraw<cellana_token::CellanaToken>(p0, _v0, p2);
        increase_amount(p0, p1, _v1);
    }
    fun increase_amount_internal(p0: object::Object<VeCellanaToken>, p1: fungible_asset::FungibleAsset)
        acquires VeCellanaCollection, VeCellanaToken
    {
        let _v0 = object::object_address<VeCellanaToken>(&p0);
        let _v1 = borrow_global_mut<VeCellanaToken>(_v0);
        let _v2 = *&_v1.end_epoch;
        let _v3 = epoch::now();
        assert!(_v2 > _v3, 10);
        let _v4 = fungible_asset::amount(&p1);
        assert!(_v4 > 0, 8);
        let _v5 = *&_v1.locked_amount;
        let _v6 = _v5 + _v4;
        let _v7 = &mut _v1.locked_amount;
        *_v7 = _v6;
        cellana_token::deposit<VeCellanaToken>(p0, p1);
        event::emit<IncreaseAmountEvent>(IncreaseAmountEvent{owner: object::owner<VeCellanaToken>(p0), old_amount: _v5, new_amount: _v6, ve_token: p0});
        let _v8 = *&_v1.end_epoch;
        update_snapshots(_v1, _v6, _v8);
        update_manifested_total_supply(_v5, _v8, _v6, _v8);
    }
    fun increase_amount_rebase(p0: object::Object<VeCellanaToken>, p1: fungible_asset::FungibleAsset)
        acquires VeCellanaCollection, VeCellanaToken
    {
        let _v0 = object::object_address<VeCellanaToken>(&p0);
        let _v1 = borrow_global_mut<VeCellanaToken>(_v0);
        let _v2 = fungible_asset::amount(&p1);
        assert!(_v2 > 0, 8);
        let _v3 = *&_v1.locked_amount;
        let _v4 = _v3 + _v2;
        let _v5 = &mut _v1.locked_amount;
        *_v5 = _v4;
        cellana_token::deposit<VeCellanaToken>(p0, p1);
        event::emit<IncreaseAmountEvent>(IncreaseAmountEvent{owner: object::owner<VeCellanaToken>(p0), old_amount: _v3, new_amount: _v4, ve_token: p0});
        let _v6 = *&_v1.end_epoch;
        update_snapshots(_v1, _v4, _v6);
        update_manifested_total_supply(_v3, _v6, _v4, _v6);
    }
    public entry fun initialize() {
        if (is_initialized()) return ();
        cellana_token::initialize();
        let _v0 = smart_table::new<u64, u128>();
        let _v1 = smart_table::new<u64, u64>();
        let _v2 = VeCellanaCollection{unscaled_total_voting_power_per_epoch: _v0, rebases: _v1};
        let _v3 = package_manager::get_signer();
        let _v4 = &_v3;
        let _v5 = string::utf8(vector[67u8, 101u8, 108u8, 108u8, 97u8, 110u8, 97u8, 32u8, 86u8, 111u8, 116u8, 105u8, 110u8, 103u8, 32u8, 84u8, 111u8, 107u8, 101u8, 110u8, 115u8]);
        let _v6 = string::utf8(vector[67u8, 101u8, 108u8, 108u8, 97u8, 110u8, 97u8, 32u8, 86u8, 111u8, 116u8, 105u8, 110u8, 103u8, 32u8, 84u8, 111u8, 107u8, 101u8, 110u8, 115u8]);
        let _v7 = option::none<royalty::Royalty>();
        let _v8 = string::utf8(vector[104u8, 116u8, 116u8, 112u8, 115u8, 58u8, 47u8, 47u8, 97u8, 112u8, 105u8, 46u8, 99u8, 101u8, 108u8, 108u8, 97u8, 110u8, 97u8, 46u8, 102u8, 105u8, 110u8, 97u8, 110u8, 99u8, 101u8, 47u8, 97u8, 112u8, 105u8, 47u8, 118u8, 49u8, 47u8, 118u8, 101u8, 45u8, 110u8, 102u8, 116u8, 47u8, 117u8, 114u8, 105u8, 47u8]);
        let _v9 = collection::create_unlimited_collection(_v4, _v5, _v6, _v7, _v8);
        let _v10 = &_v9;
        let _v11 = cellana_token::token();
        let _v12 = fungible_asset::create_store<cellana_token::CellanaToken>(_v10, _v11);
        let _v13 = object::generate_signer(_v10);
        let _v14 = &_v13;
        move_to<VeCellanaCollection>(_v14, _v2);
        let _v15 = string::utf8(vector[67u8, 101u8, 108u8, 108u8, 97u8, 110u8, 97u8, 32u8, 86u8, 111u8, 116u8, 105u8, 110u8, 103u8, 32u8, 84u8, 111u8, 107u8, 101u8, 110u8, 115u8]);
        let _v16 = signer::address_of(_v14);
        package_manager::add_address(_v15, _v16);
    }
    public fun is_initialized(): bool {
        package_manager::address_exists(string::utf8(vector[67u8, 101u8, 108u8, 108u8, 97u8, 110u8, 97u8, 32u8, 86u8, 111u8, 116u8, 105u8, 110u8, 103u8, 32u8, 84u8, 111u8, 107u8, 101u8, 110u8, 115u8]))
    }
    public fun max_lockup_epochs(): u64 {
        104
    }
    public entry fun merge(p0: &signer, p1: object::Object<VeCellanaToken>, p2: object::Object<VeCellanaToken>) {
        abort 0
    }
    friend fun merge_ve_nft(p0: &signer, p1: object::Object<VeCellanaToken>, p2: object::Object<VeCellanaToken>)
        acquires VeCellanaCollection, VeCellanaDeleteRef, VeCellanaToken, VeCellanaTokenRefs
    {
        let _v0;
        if (claimable_rebase(p1) == 0) _v0 = claimable_rebase(p2) == 0 else _v0 = false;
        assert!(_v0, 13);
        let _v1 = fungible_asset::balance<VeCellanaToken>(p1);
        let _v2 = object::convert<VeCellanaToken, fungible_asset::FungibleStore>(p2);
        cellana_token::transfer<VeCellanaToken>(p1, _v2, _v1);
        let _v3 = p1;
        let _v4 = signer::address_of(p0);
        assert!(object::is_owner<VeCellanaToken>(_v3, _v4), 4);
        let _v5 = object::object_address<VeCellanaToken>(&_v3);
        let _v6 = move_from<VeCellanaToken>(_v5);
        if (exists<VeCellanaDeleteRef>(_v5)) {
            let VeCellanaDeleteRef{delete_ref: _v7} = move_from<VeCellanaDeleteRef>(_v5);
            let _v8 = _v7;
            fungible_asset::remove_store(&_v8)
        };
        let VeCellanaTokenRefs{burn_ref: _v9, transfer_ref: _v10} = move_from<VeCellanaTokenRefs>(_v5);
        token::burn(_v9);
        let VeCellanaToken{locked_amount: _v11, end_epoch: _v12, snapshots: _v13, next_rebase_epoch: _v14} = _v6;
        let _v15 = _v12;
        destroy_snapshots(_v13);
        let _v16 = p2;
        let _v17 = signer::address_of(p0);
        assert!(object::is_owner<VeCellanaToken>(_v16, _v17), 4);
        let _v18 = object::object_address<VeCellanaToken>(&_v16);
        let _v19 = borrow_global_mut<VeCellanaToken>(_v18);
        let _v20 = *&_v19.locked_amount;
        let _v21 = _v1 + _v20;
        let _v22 = &mut _v19.locked_amount;
        *_v22 = _v21;
        event::emit<IncreaseAmountEvent>(IncreaseAmountEvent{owner: signer::address_of(p0), old_amount: _v20, new_amount: _v21, ve_token: p2});
        let _v23 = *&_v19.end_epoch;
        if (_v15 > _v23) {
            let _v24 = &mut _v19.end_epoch;
            *_v24 = _v15;
            update_snapshots(_v19, _v21, _v15);
            update_manifested_total_supply(_v20, _v23, _v20, _v15)
        } else {
            update_snapshots(_v19, _v21, _v23);
            if (_v15 != _v23) update_manifested_total_supply(_v1, _v15, _v1, _v23)
        };
    }
    public fun nft_exists(p0: address): bool {
        exists<VeCellanaToken>(p0)
    }
    public fun remaining_lockup_epochs(p0: object::Object<VeCellanaToken>): u64
        acquires VeCellanaToken
    {
        let _v0;
        let _v1 = get_lockup_expiration_epoch(p0);
        let _v2 = epoch::now();
        if (_v1 <= _v2) _v0 = 0 else _v0 = _v1 - _v2;
        _v0
    }
    public fun split(p0: &signer, p1: object::Object<VeCellanaToken>, p2: vector<u64>): vector<object::Object<VeCellanaToken>> {
        abort 0
    }
    public entry fun split_entry(p0: &signer, p1: object::Object<VeCellanaToken>, p2: vector<u64>) {
        abort 0
    }
    friend fun split_ve_nft(p0: &signer, p1: object::Object<VeCellanaToken>, p2: vector<u64>): vector<object::Object<VeCellanaToken>>
        acquires VeCellanaCollection, VeCellanaDeleteRef, VeCellanaToken, VeCellanaTokenRefs
    {
        let _v0 = signer::address_of(p0);
        assert!(object::is_owner<VeCellanaToken>(p1, _v0), 4);
        assert!(claimable_rebase(p1) == 0, 13);
        let _v1 = 0;
        let _v2 = p2;
        vector::reverse<u64>(&mut _v2);
        let _v3 = _v2;
        let _v4 = vector::length<u64>(&_v3);
        while (_v4 > 0) {
            let _v5 = vector::pop_back<u64>(&mut _v3);
            _v1 = _v1 + _v5;
            _v4 = _v4 - 1;
            continue
        };
        vector::destroy_empty<u64>(_v3);
        let _v6 = fungible_asset::balance<VeCellanaToken>(p1);
        assert!(_v1 == _v6, 12);
        let _v7 = fungible_asset::balance<VeCellanaToken>(p1);
        let _v8 = cellana_token::withdraw<VeCellanaToken>(p1, _v7);
        let _v9 = p1;
        let _v10 = signer::address_of(p0);
        assert!(object::is_owner<VeCellanaToken>(_v9, _v10), 4);
        let _v11 = object::object_address<VeCellanaToken>(&_v9);
        let _v12 = move_from<VeCellanaToken>(_v11);
        if (exists<VeCellanaDeleteRef>(_v11)) {
            let VeCellanaDeleteRef{delete_ref: _v13} = move_from<VeCellanaDeleteRef>(_v11);
            let _v14 = _v13;
            fungible_asset::remove_store(&_v14)
        };
        let VeCellanaTokenRefs{burn_ref: _v15, transfer_ref: _v16} = move_from<VeCellanaTokenRefs>(_v11);
        token::burn(_v15);
        let VeCellanaToken{locked_amount: _v17, end_epoch: _v18, snapshots: _v19, next_rebase_epoch: _v20} = _v12;
        let _v21 = _v18;
        let _v22 = _v21;
        let _v23 = epoch::now();
        'l0: loop {
            loop {
                if (!(_v23 < _v22)) break 'l0;
                let _v24 = voting_escrow_collection();
                let _v25 = &mut borrow_global_mut<VeCellanaCollection>(_v24).unscaled_total_voting_power_per_epoch;
                let _v26 = math64::min(_v23, _v22);
                let _v27 = _v22 - _v26;
                let _v28 = (_v17 * _v27) as u128;
                if (!smart_table::contains<u64, u128>(freeze(_v25), _v23)) break;
                let _v29 = smart_table::borrow_mut<u64, u128>(_v25, _v23);
                *_v29 = *_v29 - _v28;
                _v23 = _v23 + 1;
                continue
            };
            abort 0
        };
        destroy_snapshots(_v19);
        let _v30 = epoch::now();
        let _v31 = _v21 - _v30;
        let _v32 = vector::empty<object::Object<VeCellanaToken>>();
        let _v33 = p2;
        vector::reverse<u64>(&mut _v33);
        let _v34 = _v33;
        let _v35 = vector::length<u64>(&_v34);
        while (_v35 > 0) {
            let _v36 = vector::pop_back<u64>(&mut _v34);
            if (fungible_asset::amount(&_v8) > _v36) {
                let _v37 = fungible_asset::extract(&mut _v8, _v36);
                let _v38 = signer::address_of(p0);
                let _v39 = create_lock_with(_v37, _v31, _v38);
                let _v40 = object::object_address<VeCellanaToken>(&_v39);
                update_snapshots(borrow_global_mut<VeCellanaToken>(_v40), _v36, _v21);
                vector::push_back<object::Object<VeCellanaToken>>(&mut _v32, _v39)
            };
            _v35 = _v35 - 1;
            continue
        };
        vector::destroy_empty<u64>(_v34);
        let _v41 = &mut _v32;
        let _v42 = signer::address_of(p0);
        let _v43 = create_lock_with(_v8, _v31, _v42);
        vector::push_back<object::Object<VeCellanaToken>>(_v41, _v43);
        _v32
    }
    public fun total_voting_power(): u128
        acquires VeCellanaCollection
    {
        total_voting_power_at(epoch::now())
    }
    public fun total_voting_power_at(p0: u64): u128
        acquires VeCellanaCollection
    {
        let _v0;
        let _v1 = voting_escrow_collection();
        let _v2 = &borrow_global<VeCellanaCollection>(_v1).unscaled_total_voting_power_per_epoch;
        let _v3 = p0;
        let _v4 = _v2;
        if (!smart_table::contains<u64, u128>(_v4, _v3)) _v0 = 0u128 else {
            let _v5 = *smart_table::borrow<u64, u128>(_v4, _v3);
            let _v6 = 104 as u128;
            _v0 = _v5 / _v6
        };
        _v0
    }
    friend fun unfreeze_token(p0: object::Object<VeCellanaToken>)
        acquires VeCellanaTokenRefs
    {
        let _v0 = object::object_address<VeCellanaToken>(&p0);
        object::enable_ungated_transfer(&borrow_global<VeCellanaTokenRefs>(_v0).transfer_ref);
    }
    fun update_manifested_total_supply(p0: u64, p1: u64, p2: u64, p3: u64)
        acquires VeCellanaCollection
    {
        let _v0;
        if (p2 > p0) _v0 = true else _v0 = p3 > p1;
        assert!(_v0, 6);
        let _v1 = epoch::now();
        let _v2 = voting_escrow_collection();
        let _v3 = &mut borrow_global_mut<VeCellanaCollection>(_v2).unscaled_total_voting_power_per_epoch;
        loop {
            let _v4;
            let _v5;
            if (!(_v1 < p3)) break;
            if (p0 == 0) _v5 = true else _v5 = p1 <= _v1;
            if (_v5) _v4 = 0 else {
                let _v6 = p1 - _v1;
                _v4 = p0 * _v6
            };
            let _v7 = p3 - _v1;
            let _v8 = (p2 * _v7 - _v4) as u128;
            if (smart_table::contains<u64, u128>(freeze(_v3), _v1)) {
                let _v9 = smart_table::borrow_mut<u64, u128>(_v3, _v1);
                *_v9 = *_v9 + _v8
            } else smart_table::add<u64, u128>(_v3, _v1, _v8);
            _v1 = _v1 + 1;
            continue
        };
    }
    fun update_snapshots(p0: &mut VeCellanaToken, p1: u64, p2: u64) {
        let _v0;
        let _v1 = &mut p0.snapshots;
        let _v2 = epoch::now();
        let _v3 = smart_vector::length<TokenSnapshot>(freeze(_v1));
        if (_v3 == 0) _v0 = true else {
            let _v4 = _v3 - 1;
            _v0 = *&smart_vector::borrow<TokenSnapshot>(freeze(_v1), _v4).epoch < _v2
        };
        if (_v0) {
            let _v5 = TokenSnapshot{epoch: _v2, locked_amount: p1, end_epoch: p2};
            smart_vector::push_back<TokenSnapshot>(_v1, _v5)
        } else {
            let _v6 = _v3 - 1;
            let _v7 = smart_vector::borrow_mut<TokenSnapshot>(_v1, _v6);
            let _v8 = &mut _v7.locked_amount;
            *_v8 = p1;
            let _v9 = &mut _v7.end_epoch;
            *_v9 = p2
        };
    }
    public fun voting_escrow_collection(): address {
        package_manager::get_address(string::utf8(vector[67u8, 101u8, 108u8, 108u8, 97u8, 110u8, 97u8, 32u8, 86u8, 111u8, 116u8, 105u8, 110u8, 103u8, 32u8, 84u8, 111u8, 107u8, 101u8, 110u8, 115u8]))
    }
    public fun withdraw(p0: &signer, p1: object::Object<VeCellanaToken>): fungible_asset::FungibleAsset
        acquires VeCellanaCollection, VeCellanaDeleteRef, VeCellanaToken, VeCellanaTokenRefs
    {
        assert!(claimable_rebase(p1) == 0, 13);
        let _v0 = fungible_asset::balance<VeCellanaToken>(p1);
        let _v1 = cellana_token::withdraw<VeCellanaToken>(p1, _v0);
        let _v2 = p1;
        let _v3 = signer::address_of(p0);
        assert!(object::is_owner<VeCellanaToken>(_v2, _v3), 4);
        let _v4 = object::object_address<VeCellanaToken>(&_v2);
        let _v5 = move_from<VeCellanaToken>(_v4);
        if (exists<VeCellanaDeleteRef>(_v4)) {
            let VeCellanaDeleteRef{delete_ref: _v6} = move_from<VeCellanaDeleteRef>(_v4);
            let _v7 = _v6;
            fungible_asset::remove_store(&_v7)
        };
        let VeCellanaTokenRefs{burn_ref: _v8, transfer_ref: _v9} = move_from<VeCellanaTokenRefs>(_v4);
        token::burn(_v8);
        let VeCellanaToken{locked_amount: _v10, end_epoch: _v11, snapshots: _v12, next_rebase_epoch: _v13} = _v5;
        destroy_snapshots(_v12);
        let _v14 = signer::address_of(p0);
        let _v15 = fungible_asset::amount(&_v1);
        event::emit<WithdrawEvent>(WithdrawEvent{owner: _v14, amount: _v15, ve_token: p1});
        let _v16 = epoch::now();
        assert!(_v11 <= _v16, 5);
        _v1
    }
    public entry fun withdraw_entry(p0: &signer, p1: object::Object<VeCellanaToken>)
        acquires VeCellanaCollection, VeCellanaDeleteRef, VeCellanaToken, VeCellanaTokenRefs
    {
        let _v0 = withdraw(p0, p1);
        primary_fungible_store::deposit(signer::address_of(p0), _v0);
    }
}
