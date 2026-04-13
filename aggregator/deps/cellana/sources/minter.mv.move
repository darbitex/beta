module 0x4bf51972879e3b95c4781a5cdcb9e1ee24ef483e7d22f2d903626f126df62bd1::minter {
    use 0x1::error;
    use 0x1::fungible_asset;
    use 0x1::math64;
    use 0x1::object;
    use 0x1::primary_fungible_store;
    use 0x1::signer;
    use 0x1::string;
    use 0x4bf51972879e3b95c4781a5cdcb9e1ee24ef483e7d22f2d903626f126df62bd1::cellana_token;
    use 0x4bf51972879e3b95c4781a5cdcb9e1ee24ef483e7d22f2d903626f126df62bd1::epoch;
    use 0x4bf51972879e3b95c4781a5cdcb9e1ee24ef483e7d22f2d903626f126df62bd1::package_manager;
    use 0x4bf51972879e3b95c4781a5cdcb9e1ee24ef483e7d22f2d903626f126df62bd1::voting_escrow;
    friend 0x4bf51972879e3b95c4781a5cdcb9e1ee24ef483e7d22f2d903626f126df62bd1::vote_manager;
    struct MinterConfig has key {
        team_account: address,
        pending_team_account: address,
        team_emission_rate_bps: u64,
        weekly_emission_amount: u64,
        last_emission_update_epoch: u64,
    }
    public fun team_emission_rate_bps(): u64
        acquires MinterConfig
    {
        let _v0 = minter_address();
        *&borrow_global<MinterConfig>(_v0).team_emission_rate_bps
    }
    public entry fun confirm_new_team_account(p0: &signer)
        acquires MinterConfig
    {
        let _v0 = minter_address();
        let _v1 = borrow_global_mut<MinterConfig>(_v0);
        let _v2 = *&_v1.pending_team_account;
        let _v3 = signer::address_of(p0);
        assert!(_v2 == _v3, 2);
        let _v4 = *&_v1.pending_team_account;
        let _v5 = &mut _v1.team_account;
        *_v5 = _v4;
        let _v6 = &mut _v1.pending_team_account;
        *_v6 = @0x0;
    }
    public fun current_rebase(): u128
        acquires MinterConfig
    {
        let _v0 = current_weekly_emission();
        let _v1 = voting_escrow::total_voting_power();
        let _v2 = cellana_token::total_supply();
        let _v3 = _v0 as u128;
        let _v4 = _v2;
        if (!(_v4 != 0u128)) {
            let _v5 = error::invalid_argument(4);
            abort _v5
        };
        let _v6 = _v3 as u256;
        let _v7 = _v1 as u256;
        let _v8 = _v6 * _v7;
        let _v9 = _v4 as u256;
        let _v10 = (_v8 / _v9) as u128;
        let _v11 = _v2;
        if (!(_v11 != 0u128)) {
            let _v12 = error::invalid_argument(4);
            abort _v12
        };
        let _v13 = _v10 as u256;
        let _v14 = _v1 as u256;
        let _v15 = _v13 * _v14;
        let _v16 = _v11 as u256;
        let _v17 = (_v15 / _v16) as u128;
        let _v18 = _v2;
        if (!(_v18 != 0u128)) {
            let _v19 = error::invalid_argument(4);
            abort _v19
        };
        let _v20 = _v17 as u256;
        let _v21 = _v1 as u256;
        let _v22 = _v20 * _v21;
        let _v23 = _v18 as u256;
        ((_v22 / _v23) as u128) / 2u128
    }
    public fun current_weekly_emission(): u64
        acquires MinterConfig
    {
        let _v0 = minter_address();
        *&borrow_global<MinterConfig>(_v0).weekly_emission_amount
    }
    public fun gauge_emission(): u64
        acquires MinterConfig
    {
        let _v0 = minter_address();
        let _v1 = borrow_global<MinterConfig>(_v0);
        let _v2 = *&_v1.weekly_emission_amount;
        let _v3 = *&_v1.team_emission_rate_bps;
        let _v4 = 10000 - _v3;
        let _v5 = 10000;
        if (!(_v5 != 0)) {
            let _v6 = error::invalid_argument(4);
            abort _v6
        };
        let _v7 = _v2 as u128;
        let _v8 = _v4 as u128;
        let _v9 = _v7 * _v8;
        let _v10 = _v5 as u128;
        (_v9 / _v10) as u64
    }
    public fun get_init_locked_account(): u64 {
        let _v0 = 5;
        if (!(_v0 != 0)) {
            let _v1 = error::invalid_argument(4);
            abort _v1
        };
        let _v2 = (100000000000000000 as u128) * 4u128;
        let _v3 = _v0 as u128;
        (_v2 / _v3) as u64
    }
    public fun initial_weekly_emission(): u64 {
        150000000000000
    }
    public entry fun initialize() {
        if (is_initialized()) return ();
        cellana_token::initialize();
        let _v0 = package_manager::get_signer();
        let _v1 = object::create_object_from_account(&_v0);
        let _v2 = object::generate_signer(&_v1);
        let _v3 = &_v2;
        let _v4 = epoch::now();
        let _v5 = MinterConfig{team_account: @0xf2b948595bd7e12856942016544da14aca954dd182b3987466205a61843fb17c, pending_team_account: @0x0, team_emission_rate_bps: 30, weekly_emission_amount: 150000000000000, last_emission_update_epoch: _v4};
        move_to<MinterConfig>(_v3, _v5);
        let _v6 = cellana_token::mint(100000000000000000);
        let _v7 = &mut _v6;
        let _v8 = 100000000000000000 / 5;
        let _v9 = fungible_asset::extract(_v7, _v8);
        primary_fungible_store::deposit(@0x79cf8d0de14ee21f84c6a4d4deda0e045a6811685608df7de7f7e0230069cf12, _v9);
        let _v10 = voting_escrow::max_lockup_epochs();
        let _v11 = voting_escrow::create_lock_with(_v6, _v10, @0x79cf8d0de14ee21f84c6a4d4deda0e045a6811685608df7de7f7e0230069cf12);
        let _v12 = signer::address_of(_v3);
        package_manager::add_address(string::utf8(vector[109u8, 105u8, 110u8, 116u8, 101u8, 114u8]), _v12);
    }
    public fun is_initialized(): bool {
        package_manager::address_exists(string::utf8(vector[109u8, 105u8, 110u8, 116u8, 101u8, 114u8]))
    }
    public fun min_weekly_emission(): u64 {
        let _v0 = cellana_token::total_supply();
        let _v1 = 2 as u128;
        (_v0 * _v1 / 10000u128) as u64
    }
    friend fun mint(): (fungible_asset::FungibleAsset, fungible_asset::FungibleAsset)
        acquires MinterConfig
    {
        let _v0;
        let _v1 = current_rebase();
        let _v2 = minter_address();
        let _v3 = borrow_global_mut<MinterConfig>(_v2);
        let _v4 = epoch::now();
        let _v5 = *&_v3.last_emission_update_epoch + 1;
        assert!(_v4 >= _v5, 3);
        let _v6 = *&_v3.weekly_emission_amount;
        let _v7 = *&_v3.team_emission_rate_bps;
        let _v8 = 10000;
        if (!(_v8 != 0)) {
            let _v9 = error::invalid_argument(4);
            abort _v9
        };
        let _v10 = _v6 as u128;
        let _v11 = _v7 as u128;
        let _v12 = _v10 * _v11;
        let _v13 = _v8 as u128;
        let _v14 = (_v12 / _v13) as u64;
        let _v15 = cellana_token::mint(_v6);
        let _v16 = fungible_asset::extract(&mut _v15, _v14);
        primary_fungible_store::deposit(*&_v3.team_account, _v16);
        if (_v1 == 0u128) _v0 = fungible_asset::zero<cellana_token::CellanaToken>(cellana_token::token()) else _v0 = cellana_token::mint(_v1 as u64);
        let _v17 = 10000 - 100;
        let _v18 = 10000;
        if (!(_v18 != 0)) {
            let _v19 = error::invalid_argument(4);
            abort _v19
        };
        let _v20 = _v6 as u128;
        let _v21 = _v17 as u128;
        let _v22 = _v20 * _v21;
        let _v23 = _v18 as u128;
        let _v24 = (_v22 / _v23) as u64;
        let _v25 = min_weekly_emission();
        let _v26 = math64::max(_v24, _v25);
        let _v27 = &mut _v3.weekly_emission_amount;
        *_v27 = _v26;
        let _v28 = &mut _v3.last_emission_update_epoch;
        *_v28 = _v4;
        (_v15, _v0)
    }
    public fun minter_address(): address {
        package_manager::get_address(string::utf8(vector[109u8, 105u8, 110u8, 116u8, 101u8, 114u8]))
    }
    public entry fun set_team_rate(p0: &signer, p1: u64)
        acquires MinterConfig
    {
        assert!(p1 <= 50, 1);
        let _v0 = minter_address();
        let _v1 = borrow_global_mut<MinterConfig>(_v0);
        let _v2 = signer::address_of(p0);
        let _v3 = *&_v1.team_account;
        assert!(_v2 == _v3, 2);
        let _v4 = &mut _v1.team_emission_rate_bps;
        *_v4 = p1;
    }
    public fun team(): address
        acquires MinterConfig
    {
        let _v0 = minter_address();
        *&borrow_global<MinterConfig>(_v0).team_account
    }
    public entry fun update_team_account(p0: &signer, p1: address)
        acquires MinterConfig
    {
        let _v0 = minter_address();
        let _v1 = borrow_global_mut<MinterConfig>(_v0);
        let _v2 = signer::address_of(p0);
        let _v3 = *&_v1.team_account;
        assert!(_v2 == _v3, 2);
        let _v4 = &mut _v1.pending_team_account;
        *_v4 = p1;
    }
    public fun weekly_emission_reduction_rate_bps(): u64 {
        100
    }
}
