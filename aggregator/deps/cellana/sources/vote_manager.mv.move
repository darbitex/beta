module 0x4bf51972879e3b95c4781a5cdcb9e1ee24ef483e7d22f2d903626f126df62bd1::vote_manager {
    use 0x1::aptos_account;
    use 0x1::code;
    use 0x1::coin;
    use 0x1::event;
    use 0x1::fungible_asset;
    use 0x1::object;
    use 0x1::primary_fungible_store;
    use 0x1::signer;
    use 0x1::simple_map;
    use 0x1::smart_table;
    use 0x1::smart_vector;
    use 0x1::string;
    use 0x1::vector;
    use 0x4bf51972879e3b95c4781a5cdcb9e1ee24ef483e7d22f2d903626f126df62bd1::cellana_token;
    use 0x4bf51972879e3b95c4781a5cdcb9e1ee24ef483e7d22f2d903626f126df62bd1::coin_wrapper;
    use 0x4bf51972879e3b95c4781a5cdcb9e1ee24ef483e7d22f2d903626f126df62bd1::epoch;
    use 0x4bf51972879e3b95c4781a5cdcb9e1ee24ef483e7d22f2d903626f126df62bd1::gauge;
    use 0x4bf51972879e3b95c4781a5cdcb9e1ee24ef483e7d22f2d903626f126df62bd1::liquidity_pool;
    use 0x4bf51972879e3b95c4781a5cdcb9e1ee24ef483e7d22f2d903626f126df62bd1::minter;
    use 0x4bf51972879e3b95c4781a5cdcb9e1ee24ef483e7d22f2d903626f126df62bd1::package_manager;
    use 0x4bf51972879e3b95c4781a5cdcb9e1ee24ef483e7d22f2d903626f126df62bd1::rewards_pool;
    use 0x4bf51972879e3b95c4781a5cdcb9e1ee24ef483e7d22f2d903626f126df62bd1::token_whitelist;
    use 0x4bf51972879e3b95c4781a5cdcb9e1ee24ef483e7d22f2d903626f126df62bd1::voting_escrow;
    friend 0x4bf51972879e3b95c4781a5cdcb9e1ee24ef483e7d22f2d903626f126df62bd1::router;
    struct AbstainEvent has drop, store {
        owner: address,
        ve_token: object::Object<voting_escrow::VeCellanaToken>,
    }
    struct AdministrativeData has key {
        active_gauges: smart_table::SmartTable<object::Object<gauge::Gauge>, bool>,
        active_gauges_list: smart_vector::SmartVector<object::Object<gauge::Gauge>>,
        pool_to_gauge: smart_table::SmartTable<object::Object<liquidity_pool::LiquidityPool>, object::Object<gauge::Gauge>>,
        gauge_to_fees_pool: smart_table::SmartTable<object::Object<gauge::Gauge>, object::Object<rewards_pool::RewardsPool>>,
        gauge_to_incentive_pool: smart_table::SmartTable<object::Object<gauge::Gauge>, object::Object<rewards_pool::RewardsPool>>,
        operator: address,
        governance: address,
        pending_distribution_epoch: u64,
    }
    struct AdvanceEpochEvent has drop, store {
        epoch: u64,
    }
    struct CreateGaugeEvent has drop, store {
        gauge: object::Object<gauge::Gauge>,
        creator: address,
        pool: object::Object<liquidity_pool::LiquidityPool>,
    }
    struct GaugeVoteAccounting has key {
        total_votes: u128,
        votes_for_gauges: simple_map::SimpleMap<object::Object<gauge::Gauge>, u128>,
    }
    struct NullCoin {
    }
    struct VeTokenVoteAccounting has key {
        votes_for_pools_by_ve_token: smart_table::SmartTable<object::Object<voting_escrow::VeCellanaToken>, simple_map::SimpleMap<object::Object<liquidity_pool::LiquidityPool>, u64>>,
        last_voted_epoch: smart_table::SmartTable<object::Object<voting_escrow::VeCellanaToken>, u64>,
    }
    struct VoteEvent has drop, store {
        owner: address,
        ve_token: object::Object<voting_escrow::VeCellanaToken>,
        pools: vector<object::Object<liquidity_pool::LiquidityPool>>,
        weights: vector<u64>,
    }
    struct WhitelistEvent has drop, store {
        tokens: vector<string::String>,
    }
    struct WhitelistRewardEvent has drop, store {
        tokens: vector<string::String>,
        is_wl: bool,
    }
    public fun operator(): address
        acquires AdministrativeData
    {
        let _v0 = vote_manager_address();
        *&borrow_global<AdministrativeData>(_v0).operator
    }
    public fun governance(): address
        acquires AdministrativeData
    {
        let _v0 = vote_manager_address();
        *&borrow_global<AdministrativeData>(_v0).governance
    }
    public fun pending_distribution_epoch(): u64
        acquires AdministrativeData
    {
        let _v0 = vote_manager_address();
        *&borrow_global<AdministrativeData>(_v0).pending_distribution_epoch
    }
    public fun last_voted_epoch(p0: object::Object<voting_escrow::VeCellanaToken>): u64
        acquires VeTokenVoteAccounting
    {
        let _v0 = vote_manager_address();
        let _v1 = &borrow_global<VeTokenVoteAccounting>(_v0).last_voted_epoch;
        let _v2 = 0;
        let _v3 = &_v2;
        *smart_table::borrow_with_default<object::Object<voting_escrow::VeCellanaToken>, u64>(_v1, p0, _v3)
    }
    fun add_valid_coin<T0>(p0: &mut vector<string::String>) {
        let _v0 = coin_wrapper::format_coin<T0>();
        let _v1 = coin_wrapper::format_coin<NullCoin>();
        if (_v0 != _v1) vector::push_back<string::String>(p0, _v0);
    }
    public entry fun advance_epoch()
        acquires AdministrativeData, GaugeVoteAccounting
    {
        let _v0;
        let _v1 = epoch::now();
        let _v2 = pending_distribution_epoch();
        loop {
            if (!(_v2 == _v1)) {
                let _v3 = vote_manager_address();
                let _v4 = &mut borrow_global_mut<AdministrativeData>(_v3).pending_distribution_epoch;
                *_v4 = _v1;
                let (_v5,_v6) = minter::mint();
                let _v7 = _v5;
                let _v8 = _v1 - 1;
                voting_escrow::add_rebase(_v6, _v8);
                let _v9 = fungible_asset::amount(&_v7) as u128;
                let _v10 = vote_manager_address();
                _v0 = borrow_global_mut<GaugeVoteAccounting>(_v10);
                let _v11 = *&_v0.total_votes;
                let _v12 = &mut _v0.votes_for_gauges;
                let _v13 = simple_map::keys<object::Object<gauge::Gauge>, u128>(freeze(_v12));
                let _v14 = vote_manager_address();
                let _v15 = borrow_global<AdministrativeData>(_v14);
                let _v16 = &_v15.gauge_to_fees_pool;
                let _v17 = _v13;
                let _v18 = vector::length<object::Object<gauge::Gauge>>(&_v17);
                while (_v18 > 0) {
                    let _v19 = vector::pop_back<object::Object<gauge::Gauge>>(&mut _v17);
                    let _v20 = &_v19;
                    let _v21 = *simple_map::borrow<object::Object<gauge::Gauge>, u128>(freeze(_v12), _v20);
                    let _v22 = (_v9 * _v21 / _v11) as u64;
                    let _v23 = fungible_asset::extract(&mut _v7, _v22);
                    gauge::add_rewards(_v19, _v23);
                    let _v24 = &_v19;
                    let (_v25,_v26) = simple_map::remove<object::Object<gauge::Gauge>, u128>(_v12, _v24);
                    _v18 = _v18 - 1;
                    continue
                };
                vector::destroy_empty<object::Object<gauge::Gauge>>(_v17);
                let _v27 = &_v15.active_gauges_list;
                let _v28 = smart_vector::length<object::Object<gauge::Gauge>>(_v27);
                let _v29 = 0;
                loop {
                    let _v30;
                    if (!(_v29 < _v28)) break;
                    let _v31 = *smart_vector::borrow<object::Object<gauge::Gauge>>(_v27, _v29);
                    let (_v32,_v33) = gauge::claim_fees(_v31);
                    let _v34 = _v33;
                    let _v35 = _v32;
                    if (fungible_asset::amount(&_v35) > 0) _v30 = true else _v30 = fungible_asset::amount(&_v34) > 0;
                    if (_v30) {
                        let _v36 = *smart_table::borrow<object::Object<gauge::Gauge>, object::Object<rewards_pool::RewardsPool>>(_v16, _v31);
                        let _v37 = vector::empty<fungible_asset::FungibleAsset>();
                        let _v38 = &mut _v37;
                        vector::push_back<fungible_asset::FungibleAsset>(_v38, _v35);
                        vector::push_back<fungible_asset::FungibleAsset>(_v38, _v34);
                        rewards_pool::add_rewards(_v36, _v37, _v1)
                    } else {
                        fungible_asset::destroy_zero(_v35);
                        fungible_asset::destroy_zero(_v34)
                    };
                    _v29 = _v29 + 1;
                    continue
                };
                if (fungible_asset::amount(&_v7) > 0) {
                    cellana_token::burn(_v7);
                    break
                };
                fungible_asset::destroy_zero(_v7);
                break
            };
            return ()
        };
        let _v39 = &mut _v0.total_votes;
        *_v39 = 0u128;
        event::emit<AdvanceEpochEvent>(AdvanceEpochEvent{epoch: _v1});
    }
    public fun all_claimable_rewards(p0: object::Object<voting_escrow::VeCellanaToken>, p1: object::Object<liquidity_pool::LiquidityPool>, p2: u64): simple_map::SimpleMap<u64, simple_map::SimpleMap<string::String, u64>>
        acquires AdministrativeData
    {
        let _v0 = simple_map::create<u64, simple_map::SimpleMap<string::String, u64>>();
        let _v1 = epoch::now();
        let _v2 = _v1 - p2;
        while (_v2 < _v1) {
            let _v3 = claimable_rewards(p0, p1, _v2);
            if (simple_map::length<string::String, u64>(&_v3) > 0) simple_map::add<u64, simple_map::SimpleMap<string::String, u64>>(&mut _v0, _v2, _v3);
            _v2 = _v2 + 1;
            continue
        };
        _v0
    }
    public fun all_current_votes(): (simple_map::SimpleMap<object::Object<liquidity_pool::LiquidityPool>, u128>, u128)
        acquires GaugeVoteAccounting
    {
        let _v0 = vote_manager_address();
        let _v1 = borrow_global<GaugeVoteAccounting>(_v0);
        let _v2 = &_v1.votes_for_gauges;
        let _v3 = simple_map::keys<object::Object<gauge::Gauge>, u128>(_v2);
        let _v4 = vector::empty<object::Object<liquidity_pool::LiquidityPool>>();
        let _v5 = _v3;
        vector::reverse<object::Object<gauge::Gauge>>(&mut _v5);
        let _v6 = _v5;
        let _v7 = vector::length<object::Object<gauge::Gauge>>(&_v6);
        while (_v7 > 0) {
            let _v8 = vector::pop_back<object::Object<gauge::Gauge>>(&mut _v6);
            let _v9 = &mut _v4;
            let _v10 = gauge::liquidity_pool(_v8);
            vector::push_back<object::Object<liquidity_pool::LiquidityPool>>(_v9, _v10);
            _v7 = _v7 - 1;
            continue
        };
        vector::destroy_empty<object::Object<gauge::Gauge>>(_v6);
        let _v11 = simple_map::values<object::Object<gauge::Gauge>, u128>(_v2);
        let _v12 = simple_map::new_from<object::Object<liquidity_pool::LiquidityPool>, u128>(_v4, _v11);
        let _v13 = *&_v1.total_votes;
        (_v12, _v13)
    }
    public entry fun batch_claim<T0, T1, T2, T3, T4, T5>(p0: &signer, p1: vector<object::Object<voting_escrow::VeCellanaToken>>, p2: vector<object::Object<liquidity_pool::LiquidityPool>>, p3: u64)
        acquires AdministrativeData
    {
        let _v0 = p1;
        vector::reverse<object::Object<voting_escrow::VeCellanaToken>>(&mut _v0);
        let _v1 = _v0;
        let _v2 = vector::length<object::Object<voting_escrow::VeCellanaToken>>(&_v1);
        while (_v2 > 0) {
            let _v3 = vector::pop_back<object::Object<voting_escrow::VeCellanaToken>>(&mut _v1);
            let _v4 = p2;
            vector::reverse<object::Object<liquidity_pool::LiquidityPool>>(&mut _v4);
            let _v5 = _v4;
            let _v6 = vector::length<object::Object<liquidity_pool::LiquidityPool>>(&_v5);
            while (_v6 > 0) {
                let _v7 = vector::pop_back<object::Object<liquidity_pool::LiquidityPool>>(&mut _v5);
                claim_rewards_all_6<T0, T1, T2, T3, T4, T5>(p0, _v3, _v7, p3);
                _v6 = _v6 - 1;
                continue
            };
            vector::destroy_empty<object::Object<liquidity_pool::LiquidityPool>>(_v5);
            _v2 = _v2 - 1;
            continue
        };
        vector::destroy_empty<object::Object<voting_escrow::VeCellanaToken>>(_v1);
    }
    public fun can_vote(p0: object::Object<voting_escrow::VeCellanaToken>): bool
        acquires VeTokenVoteAccounting
    {
        let _v0 = last_voted_epoch(p0);
        let _v1 = epoch::now();
        _v0 < _v1
    }
    public fun claim_emissions(p0: &signer, p1: object::Object<liquidity_pool::LiquidityPool>): fungible_asset::FungibleAsset
        acquires AdministrativeData
    {
        let _v0 = get_gauge(p1);
        assert!(is_gauge_active(_v0), 9);
        gauge::claim_rewards(p0, _v0)
    }
    public entry fun claim_emissions_entry(p0: &signer, p1: object::Object<liquidity_pool::LiquidityPool>)
        acquires AdministrativeData
    {
        let _v0 = signer::address_of(p0);
        let _v1 = claim_emissions(p0, p1);
        primary_fungible_store::deposit(_v0, _v1);
    }
    public entry fun claim_emissions_multiple(p0: &signer, p1: vector<object::Object<liquidity_pool::LiquidityPool>>)
        acquires AdministrativeData
    {
        let _v0 = p1;
        vector::reverse<object::Object<liquidity_pool::LiquidityPool>>(&mut _v0);
        let _v1 = _v0;
        let _v2 = vector::length<object::Object<liquidity_pool::LiquidityPool>>(&_v1);
        while (_v2 > 0) {
            let _v3 = vector::pop_back<object::Object<liquidity_pool::LiquidityPool>>(&mut _v1);
            claim_emissions_entry(p0, _v3);
            _v2 = _v2 - 1;
            continue
        };
        vector::destroy_empty<object::Object<liquidity_pool::LiquidityPool>>(_v1);
    }
    public entry fun claim_rebase(p0: &signer, p1: object::Object<voting_escrow::VeCellanaToken>) {
        voting_escrow::claim_rebase(p0, p1);
    }
    public entry fun claim_rewards<T0, T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11, T12, T13, T14>(p0: &signer, p1: object::Object<voting_escrow::VeCellanaToken>, p2: object::Object<liquidity_pool::LiquidityPool>, p3: u64)
        acquires AdministrativeData
    {
        assert!(is_gauge_active(get_gauge(p2)), 9);
        let _v0 = signer::address_of(p0);
        assert!(object::is_owner<voting_escrow::VeCellanaToken>(p1, _v0), 1);
        let _v1 = object::object_address<voting_escrow::VeCellanaToken>(&p1);
        let _v2 = fees_pool(p2);
        let _v3 = rewards_pool::claim_rewards(_v1, _v2, p3);
        let _v4 = incentive_pool(p2);
        let _v5 = rewards_pool::claim_rewards(_v1, _v4, p3);
        vector::append<fungible_asset::FungibleAsset>(&mut _v3, _v5);
        let _v6 = vector::empty<string::String>();
        add_valid_coin<T0>(&mut _v6);
        add_valid_coin<T1>(&mut _v6);
        add_valid_coin<T2>(&mut _v6);
        add_valid_coin<T3>(&mut _v6);
        add_valid_coin<T4>(&mut _v6);
        add_valid_coin<T5>(&mut _v6);
        add_valid_coin<T6>(&mut _v6);
        add_valid_coin<T7>(&mut _v6);
        add_valid_coin<T8>(&mut _v6);
        add_valid_coin<T9>(&mut _v6);
        add_valid_coin<T10>(&mut _v6);
        add_valid_coin<T11>(&mut _v6);
        add_valid_coin<T12>(&mut _v6);
        add_valid_coin<T13>(&mut _v6);
        add_valid_coin<T14>(&mut _v6);
        let _v7 = _v3;
        vector::reverse<fungible_asset::FungibleAsset>(&mut _v7);
        let _v8 = _v7;
        let _v9 = vector::length<fungible_asset::FungibleAsset>(&_v8);
        'l0: loop {
            'l1: loop {
                loop {
                    if (!(_v9 > 0)) break 'l0;
                    let _v10 = vector::pop_back<fungible_asset::FungibleAsset>(&mut _v8);
                    if (fungible_asset::amount(&_v10) == 0) fungible_asset::destroy_zero(_v10) else {
                        let _v11 = fungible_asset::asset_metadata(&_v10);
                        if (coin_wrapper::is_wrapper(_v11)) {
                            let _v12 = coin_wrapper::get_original(_v11);
                            let _v13 = &_v6;
                            let _v14 = &_v12;
                            let (_v15,_v16) = vector::index_of<string::String>(_v13, _v14);
                            let _v17 = _v16;
                            if (_v15) if (_v17 == 0) unwrap_and_deposit<T0>(_v0, _v10) else if (_v17 == 1) unwrap_and_deposit<T1>(_v0, _v10) else if (_v17 == 2) unwrap_and_deposit<T2>(_v0, _v10) else if (_v17 == 3) unwrap_and_deposit<T3>(_v0, _v10) else if (_v17 == 4) unwrap_and_deposit<T4>(_v0, _v10) else if (_v17 == 5) unwrap_and_deposit<T5>(_v0, _v10) else if (_v17 == 6) unwrap_and_deposit<T6>(_v0, _v10) else if (_v17 == 7) unwrap_and_deposit<T7>(_v0, _v10) else if (_v17 == 8) unwrap_and_deposit<T8>(_v0, _v10) else if (_v17 == 9) unwrap_and_deposit<T9>(_v0, _v10) else if (_v17 == 10) unwrap_and_deposit<T10>(_v0, _v10) else if (_v17 == 11) unwrap_and_deposit<T11>(_v0, _v10) else if (_v17 == 12) unwrap_and_deposit<T12>(_v0, _v10) else if (_v17 == 13) unwrap_and_deposit<T13>(_v0, _v10) else if (_v17 == 14) unwrap_and_deposit<T14>(_v0, _v10) else break else break 'l1
                        } else primary_fungible_store::deposit(_v0, _v10)
                    };
                    _v9 = _v9 - 1;
                    continue
                };
                abort 10
            };
            abort 10
        };
        vector::destroy_empty<fungible_asset::FungibleAsset>(_v8);
    }
    public entry fun claim_rewards_6<T0, T1, T2, T3, T4, T5>(p0: &signer, p1: object::Object<voting_escrow::VeCellanaToken>, p2: object::Object<liquidity_pool::LiquidityPool>, p3: u64)
        acquires AdministrativeData
    {
        assert!(is_gauge_active(get_gauge(p2)), 9);
        let _v0 = signer::address_of(p0);
        assert!(object::is_owner<voting_escrow::VeCellanaToken>(p1, _v0), 1);
        let _v1 = object::object_address<voting_escrow::VeCellanaToken>(&p1);
        let _v2 = fees_pool(p2);
        let _v3 = rewards_pool::claim_rewards(_v1, _v2, p3);
        let _v4 = incentive_pool(p2);
        let _v5 = rewards_pool::claim_rewards(_v1, _v4, p3);
        vector::append<fungible_asset::FungibleAsset>(&mut _v3, _v5);
        let _v6 = vector::empty<string::String>();
        add_valid_coin<T0>(&mut _v6);
        add_valid_coin<T1>(&mut _v6);
        add_valid_coin<T2>(&mut _v6);
        add_valid_coin<T3>(&mut _v6);
        add_valid_coin<T4>(&mut _v6);
        add_valid_coin<T5>(&mut _v6);
        let _v7 = _v3;
        vector::reverse<fungible_asset::FungibleAsset>(&mut _v7);
        let _v8 = _v7;
        let _v9 = vector::length<fungible_asset::FungibleAsset>(&_v8);
        'l0: loop {
            'l1: loop {
                loop {
                    if (!(_v9 > 0)) break 'l0;
                    let _v10 = vector::pop_back<fungible_asset::FungibleAsset>(&mut _v8);
                    if (fungible_asset::amount(&_v10) == 0) fungible_asset::destroy_zero(_v10) else {
                        let _v11 = fungible_asset::asset_metadata(&_v10);
                        if (coin_wrapper::is_wrapper(_v11)) {
                            let _v12 = coin_wrapper::get_original(_v11);
                            let _v13 = &_v6;
                            let _v14 = &_v12;
                            let (_v15,_v16) = vector::index_of<string::String>(_v13, _v14);
                            let _v17 = _v16;
                            if (_v15) if (_v17 == 0) unwrap_and_deposit<T0>(_v0, _v10) else if (_v17 == 1) unwrap_and_deposit<T1>(_v0, _v10) else if (_v17 == 2) unwrap_and_deposit<T2>(_v0, _v10) else if (_v17 == 3) unwrap_and_deposit<T3>(_v0, _v10) else if (_v17 == 4) unwrap_and_deposit<T4>(_v0, _v10) else if (_v17 == 5) unwrap_and_deposit<T5>(_v0, _v10) else break else break 'l1
                        } else primary_fungible_store::deposit(_v0, _v10)
                    };
                    _v9 = _v9 - 1;
                    continue
                };
                abort 10
            };
            abort 10
        };
        vector::destroy_empty<fungible_asset::FungibleAsset>(_v8);
    }
    public entry fun claim_rewards_all<T0, T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11, T12, T13, T14>(p0: &signer, p1: object::Object<voting_escrow::VeCellanaToken>, p2: object::Object<liquidity_pool::LiquidityPool>, p3: u64)
        acquires AdministrativeData
    {
        let _v0 = epoch::now();
        let _v1 = _v0 - p3;
        while (_v1 < _v0) {
            claim_rewards<T0, T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11, T12, T13, T14>(p0, p1, p2, _v1);
            _v1 = _v1 + 1
        };
    }
    public entry fun claim_rewards_all_6<T0, T1, T2, T3, T4, T5>(p0: &signer, p1: object::Object<voting_escrow::VeCellanaToken>, p2: object::Object<liquidity_pool::LiquidityPool>, p3: u64)
        acquires AdministrativeData
    {
        let _v0 = epoch::now();
        let _v1 = _v0 - p3;
        while (_v1 < _v0) {
            claim_rewards_6<T0, T1, T2, T3, T4, T5>(p0, p1, p2, _v1);
            _v1 = _v1 + 1
        };
    }
    public fun claimable_emissions(p0: address, p1: object::Object<liquidity_pool::LiquidityPool>): u64
        acquires AdministrativeData
    {
        let _v0 = get_gauge(p1);
        gauge::claimable_rewards(p0, _v0)
    }
    public fun claimable_emissions_multiple(p0: address, p1: vector<object::Object<liquidity_pool::LiquidityPool>>): vector<u64>
        acquires AdministrativeData
    {
        let _v0 = vector[];
        let _v1 = p1;
        vector::reverse<object::Object<liquidity_pool::LiquidityPool>>(&mut _v1);
        let _v2 = _v1;
        let _v3 = vector::length<object::Object<liquidity_pool::LiquidityPool>>(&_v2);
        while (_v3 > 0) {
            let _v4 = vector::pop_back<object::Object<liquidity_pool::LiquidityPool>>(&mut _v2);
            let _v5 = &mut _v0;
            let _v6 = get_gauge(_v4);
            let _v7 = gauge::claimable_rewards(p0, _v6);
            vector::push_back<u64>(_v5, _v7);
            _v3 = _v3 - 1;
            continue
        };
        vector::destroy_empty<object::Object<liquidity_pool::LiquidityPool>>(_v2);
        _v0
    }
    public fun claimable_rebase(p0: object::Object<voting_escrow::VeCellanaToken>): u64 {
        voting_escrow::claimable_rebase(p0)
    }
    public fun claimable_rewards(p0: object::Object<voting_escrow::VeCellanaToken>, p1: object::Object<liquidity_pool::LiquidityPool>, p2: u64): simple_map::SimpleMap<string::String, u64>
        acquires AdministrativeData
    {
        let _v0 = object::object_address<voting_escrow::VeCellanaToken>(&p0);
        let _v1 = fees_pool(p1);
        let (_v2,_v3) = simple_map::to_vec_pair<object::Object<fungible_asset::Metadata>, u64>(rewards_pool::claimable_rewards(_v0, _v1, p2));
        let _v4 = _v3;
        let _v5 = _v2;
        let _v6 = incentive_pool(p1);
        let (_v7,_v8) = simple_map::to_vec_pair<object::Object<fungible_asset::Metadata>, u64>(rewards_pool::claimable_rewards(_v0, _v6, p2));
        vector::append<object::Object<fungible_asset::Metadata>>(&mut _v5, _v7);
        vector::append<u64>(&mut _v4, _v8);
        let _v9 = simple_map::new<string::String, u64>();
        let _v10 = _v4;
        let _v11 = _v5;
        vector::reverse<object::Object<fungible_asset::Metadata>>(&mut _v11);
        vector::reverse<u64>(&mut _v10);
        let _v12 = _v10;
        let _v13 = _v11;
        let _v14 = vector::length<object::Object<fungible_asset::Metadata>>(&_v13);
        let _v15 = vector::length<u64>(&_v12);
        assert!(_v14 == _v15, 131074);
        while (_v14 > 0) {
            let _v16 = vector::pop_back<object::Object<fungible_asset::Metadata>>(&mut _v13);
            let _v17 = vector::pop_back<u64>(&mut _v12);
            if (_v17 > 0) {
                let _v18 = coin_wrapper::get_original(_v16);
                let _v19 = &_v9;
                let _v20 = &_v18;
                if (simple_map::contains_key<string::String, u64>(_v19, _v20)) {
                    let _v21 = &mut _v9;
                    let _v22 = &_v18;
                    let _v23 = simple_map::borrow_mut<string::String, u64>(_v21, _v22);
                    *_v23 = *_v23 + _v17
                } else simple_map::add<string::String, u64>(&mut _v9, _v18, _v17)
            };
            _v14 = _v14 - 1;
            continue
        };
        vector::destroy_empty<object::Object<fungible_asset::Metadata>>(_v13);
        vector::destroy_empty<u64>(_v12);
        _v9
    }
    public fun create_gauge(p0: &signer, p1: object::Object<liquidity_pool::LiquidityPool>): object::Object<gauge::Gauge>
        acquires AdministrativeData
    {
        let _v0 = vote_manager_address();
        let _v1 = *&borrow_global<AdministrativeData>(_v0).operator;
        let _v2 = signer::address_of(p0);
        assert!(_v1 == _v2, 2);
        let _v3 = vote_manager_address();
        let _v4 = borrow_global_mut<AdministrativeData>(_v3);
        let _v5 = gauge::create(p1);
        let _v6 = rewards_pool::create(liquidity_pool::supported_inner_assets(p1));
        let _v7 = rewards_pool::create(liquidity_pool::supported_inner_assets(p1));
        smart_vector::push_back<object::Object<gauge::Gauge>>(&mut _v4.active_gauges_list, _v5);
        smart_table::add<object::Object<gauge::Gauge>, bool>(&mut _v4.active_gauges, _v5, true);
        smart_table::add<object::Object<liquidity_pool::LiquidityPool>, object::Object<gauge::Gauge>>(&mut _v4.pool_to_gauge, p1, _v5);
        smart_table::add<object::Object<gauge::Gauge>, object::Object<rewards_pool::RewardsPool>>(&mut _v4.gauge_to_fees_pool, _v5, _v6);
        smart_table::add<object::Object<gauge::Gauge>, object::Object<rewards_pool::RewardsPool>>(&mut _v4.gauge_to_incentive_pool, _v5, _v7);
        let _v8 = signer::address_of(p0);
        event::emit<CreateGaugeEvent>(CreateGaugeEvent{gauge: _v5, creator: _v8, pool: p1});
        _v5
    }
    public entry fun create_gauge_entry(p0: &signer, p1: object::Object<liquidity_pool::LiquidityPool>)
        acquires AdministrativeData
    {
        let _v0 = create_gauge(p0, p1);
    }
    friend fun create_gauge_internal(p0: object::Object<liquidity_pool::LiquidityPool>)
        acquires AdministrativeData
    {
        let _v0 = vote_manager_address();
        let _v1 = borrow_global_mut<AdministrativeData>(_v0);
        let _v2 = gauge::create(p0);
        let _v3 = rewards_pool::create(liquidity_pool::supported_inner_assets(p0));
        let _v4 = rewards_pool::create(liquidity_pool::supported_inner_assets(p0));
        smart_table::add<object::Object<gauge::Gauge>, bool>(&mut _v1.active_gauges, _v2, false);
        smart_table::add<object::Object<liquidity_pool::LiquidityPool>, object::Object<gauge::Gauge>>(&mut _v1.pool_to_gauge, p0, _v2);
        smart_table::add<object::Object<gauge::Gauge>, object::Object<rewards_pool::RewardsPool>>(&mut _v1.gauge_to_fees_pool, _v2, _v3);
        smart_table::add<object::Object<gauge::Gauge>, object::Object<rewards_pool::RewardsPool>>(&mut _v1.gauge_to_incentive_pool, _v2, _v4);
        let _v5 = package_manager::get_signer();
        let _v6 = signer::address_of(&_v5);
        event::emit<CreateGaugeEvent>(CreateGaugeEvent{gauge: _v2, creator: _v6, pool: p0});
    }
    public fun current_votes(p0: object::Object<liquidity_pool::LiquidityPool>): (u128, u128)
        acquires AdministrativeData, GaugeVoteAccounting
    {
        let _v0 = vote_manager_address();
        let _v1 = borrow_global<GaugeVoteAccounting>(_v0);
        let _v2 = &_v1.votes_for_gauges;
        let _v3 = get_gauge(p0);
        let _v4 = &_v3;
        let _v5 = *simple_map::borrow<object::Object<gauge::Gauge>, u128>(_v2, _v4);
        let _v6 = *&_v1.total_votes;
        (_v5, _v6)
    }
    public entry fun disable_gauge(p0: &signer, p1: object::Object<gauge::Gauge>)
        acquires AdministrativeData, GaugeVoteAccounting
    {
        let _v0 = vote_manager_address();
        let _v1 = *&borrow_global<AdministrativeData>(_v0).operator;
        let _v2 = signer::address_of(p0);
        assert!(_v1 == _v2, 2);
        let _v3 = vote_manager_address();
        let _v4 = borrow_global_mut<AdministrativeData>(_v3);
        let _v5 = &_v4.active_gauges_list;
        let _v6 = &p1;
        let (_v7,_v8) = smart_vector::index_of<object::Object<gauge::Gauge>>(_v5, _v6);
        assert!(_v7, 3);
        let _v9 = smart_vector::remove<object::Object<gauge::Gauge>>(&mut _v4.active_gauges_list, _v8);
        smart_table::upsert<object::Object<gauge::Gauge>, bool>(&mut _v4.active_gauges, p1, false);
        let _v10 = vote_manager_address();
        let _v11 = borrow_global_mut<GaugeVoteAccounting>(_v10);
        let _v12 = &_v11.votes_for_gauges;
        let _v13 = &p1;
        if (simple_map::contains_key<object::Object<gauge::Gauge>, u128>(_v12, _v13)) {
            let _v14 = &mut _v11.votes_for_gauges;
            let _v15 = &p1;
            let (_v16,_v17) = simple_map::remove<object::Object<gauge::Gauge>, u128>(_v14, _v15);
            let _v18 = *&_v11.total_votes - _v17;
            let _v19 = &mut _v11.total_votes;
            *_v19 = _v18
        };
    }
    public entry fun enable_gauge(p0: &signer, p1: object::Object<gauge::Gauge>)
        acquires AdministrativeData
    {
        let _v0 = vote_manager_address();
        let _v1 = *&borrow_global<AdministrativeData>(_v0).operator;
        let _v2 = signer::address_of(p0);
        assert!(_v1 == _v2, 2);
        let _v3 = vote_manager_address();
        let _v4 = borrow_global_mut<AdministrativeData>(_v3);
        let _v5 = &_v4.active_gauges_list;
        let _v6 = &p1;
        assert!(!smart_vector::contains<object::Object<gauge::Gauge>>(_v5, _v6), 4);
        smart_vector::push_back<object::Object<gauge::Gauge>>(&mut _v4.active_gauges_list, p1);
        smart_table::upsert<object::Object<gauge::Gauge>, bool>(&mut _v4.active_gauges, p1, true);
    }
    public fun fees_pool(p0: object::Object<liquidity_pool::LiquidityPool>): object::Object<rewards_pool::RewardsPool>
        acquires AdministrativeData
    {
        let _v0 = get_gauge(p0);
        let _v1 = vote_manager_address();
        *smart_table::borrow<object::Object<gauge::Gauge>, object::Object<rewards_pool::RewardsPool>>(&borrow_global<AdministrativeData>(_v1).gauge_to_fees_pool, _v0)
    }
    public fun gauge_exists(p0: object::Object<liquidity_pool::LiquidityPool>): bool
        acquires AdministrativeData
    {
        let _v0 = vote_manager_address();
        smart_table::contains<object::Object<liquidity_pool::LiquidityPool>, object::Object<gauge::Gauge>>(&borrow_global<AdministrativeData>(_v0).pool_to_gauge, p0)
    }
    public fun get_gauge(p0: object::Object<liquidity_pool::LiquidityPool>): object::Object<gauge::Gauge>
        acquires AdministrativeData
    {
        let _v0 = vector::empty<object::Object<liquidity_pool::LiquidityPool>>();
        vector::push_back<object::Object<liquidity_pool::LiquidityPool>>(&mut _v0, p0);
        let _v1 = get_gauges(_v0);
        *vector::borrow<object::Object<gauge::Gauge>>(&_v1, 0)
    }
    public fun get_gauges(p0: vector<object::Object<liquidity_pool::LiquidityPool>>): vector<object::Object<gauge::Gauge>>
        acquires AdministrativeData
    {
        let _v0 = vote_manager_address();
        let _v1 = &borrow_global<AdministrativeData>(_v0).pool_to_gauge;
        let _v2 = vector::empty<object::Object<gauge::Gauge>>();
        let _v3 = p0;
        vector::reverse<object::Object<liquidity_pool::LiquidityPool>>(&mut _v3);
        let _v4 = _v3;
        let _v5 = vector::length<object::Object<liquidity_pool::LiquidityPool>>(&_v4);
        while (_v5 > 0) {
            let _v6 = vector::pop_back<object::Object<liquidity_pool::LiquidityPool>>(&mut _v4);
            let _v7 = &mut _v2;
            let _v8 = *smart_table::borrow<object::Object<liquidity_pool::LiquidityPool>, object::Object<gauge::Gauge>>(_v1, _v6);
            vector::push_back<object::Object<gauge::Gauge>>(_v7, _v8);
            _v5 = _v5 - 1;
            continue
        };
        vector::destroy_empty<object::Object<liquidity_pool::LiquidityPool>>(_v4);
        _v2
    }
    public fun incentive_pool(p0: object::Object<liquidity_pool::LiquidityPool>): object::Object<rewards_pool::RewardsPool>
        acquires AdministrativeData
    {
        let _v0 = get_gauge(p0);
        let _v1 = vote_manager_address();
        *smart_table::borrow<object::Object<gauge::Gauge>, object::Object<rewards_pool::RewardsPool>>(&borrow_global<AdministrativeData>(_v1).gauge_to_incentive_pool, _v0)
    }
    public fun incentivize(p0: object::Object<liquidity_pool::LiquidityPool>, p1: vector<fungible_asset::FungibleAsset>)
        acquires AdministrativeData, GaugeVoteAccounting
    {
        assert!(gauge_exists(p0), 11);
        let _v0 = object::object_address<liquidity_pool::LiquidityPool>(&p0);
        let _v1 = &p1;
        let _v2 = vector::empty<string::String>();
        let _v3 = _v1;
        let _v4 = 0;
        let _v5 = vector::length<fungible_asset::FungibleAsset>(_v3);
        'l0: loop {
            loop {
                if (!(_v4 < _v5)) break 'l0;
                let _v6 = vector::borrow<fungible_asset::FungibleAsset>(_v3, _v4);
                let _v7 = &mut _v2;
                let _v8 = coin_wrapper::get_original(fungible_asset::asset_metadata(_v6));
                if (!(token_whitelist::is_reward_token_whitelisted_on_pool(_v8, _v0) == true)) break;
                vector::push_back<string::String>(_v7, _v8);
                _v4 = _v4 + 1;
                continue
            };
            abort 8
        };
        advance_epoch();
        let _v9 = incentive_pool(p0);
        let _v10 = epoch::now() + 1;
        rewards_pool::add_rewards(_v9, p1, _v10);
    }
    public fun incentivize_coin<T0>(p0: object::Object<liquidity_pool::LiquidityPool>, p1: coin::Coin<T0>)
        acquires AdministrativeData, GaugeVoteAccounting
    {
        let _v0 = coin_wrapper::wrap<T0>(p1);
        let _v1 = vector::empty<fungible_asset::FungibleAsset>();
        vector::push_back<fungible_asset::FungibleAsset>(&mut _v1, _v0);
        incentivize(p0, _v1);
    }
    public entry fun incentivize_coin_entry<T0>(p0: &signer, p1: object::Object<liquidity_pool::LiquidityPool>, p2: u64)
        acquires AdministrativeData, GaugeVoteAccounting
    {
        let _v0 = coin::withdraw<T0>(p0, p2);
        incentivize_coin<T0>(p1, _v0);
    }
    public entry fun incentivize_entry(p0: &signer, p1: object::Object<liquidity_pool::LiquidityPool>, p2: vector<object::Object<fungible_asset::Metadata>>, p3: vector<u64>)
        acquires AdministrativeData, GaugeVoteAccounting
    {
        let _v0 = p3;
        let _v1 = p2;
        let _v2 = vector::length<object::Object<fungible_asset::Metadata>>(&_v1);
        let _v3 = vector::length<u64>(&_v0);
        assert!(_v2 == _v3, 131074);
        let _v4 = vector::empty<fungible_asset::FungibleAsset>();
        let _v5 = _v0;
        let _v6 = _v1;
        vector::reverse<object::Object<fungible_asset::Metadata>>(&mut _v6);
        vector::reverse<u64>(&mut _v5);
        let _v7 = _v5;
        let _v8 = _v6;
        let _v9 = vector::length<object::Object<fungible_asset::Metadata>>(&_v8);
        let _v10 = vector::length<u64>(&_v7);
        assert!(_v9 == _v10, 131074);
        while (_v9 > 0) {
            let _v11 = vector::pop_back<object::Object<fungible_asset::Metadata>>(&mut _v8);
            let _v12 = vector::pop_back<u64>(&mut _v7);
            let _v13 = &mut _v4;
            let _v14 = primary_fungible_store::withdraw<fungible_asset::Metadata>(p0, _v11, _v12);
            vector::push_back<fungible_asset::FungibleAsset>(_v13, _v14);
            _v9 = _v9 - 1;
            continue
        };
        vector::destroy_empty<object::Object<fungible_asset::Metadata>>(_v8);
        vector::destroy_empty<u64>(_v7);
        incentivize(p1, _v4);
    }
    public entry fun initialize() {
        if (is_initialized()) return ();
        cellana_token::initialize();
        coin_wrapper::initialize();
        liquidity_pool::initialize();
        voting_escrow::initialize();
        minter::initialize();
        token_whitelist::initialize();
        let _v0 = package_manager::get_signer();
        let _v1 = object::create_object_from_account(&_v0);
        let _v2 = object::generate_signer(&_v1);
        let _v3 = &_v2;
        let _v4 = string::utf8(vector[86u8, 79u8, 84u8, 69u8, 95u8, 77u8, 65u8, 78u8, 65u8, 71u8, 69u8, 82u8]);
        let _v5 = signer::address_of(_v3);
        package_manager::add_address(_v4, _v5);
        let _v6 = smart_table::new<object::Object<gauge::Gauge>, bool>();
        let _v7 = smart_vector::new<object::Object<gauge::Gauge>>();
        let _v8 = smart_table::new<object::Object<liquidity_pool::LiquidityPool>, object::Object<gauge::Gauge>>();
        let _v9 = smart_table::new<object::Object<gauge::Gauge>, object::Object<rewards_pool::RewardsPool>>();
        let _v10 = smart_table::new<object::Object<gauge::Gauge>, object::Object<rewards_pool::RewardsPool>>();
        let _v11 = epoch::now();
        let _v12 = AdministrativeData{active_gauges: _v6, active_gauges_list: _v7, pool_to_gauge: _v8, gauge_to_fees_pool: _v9, gauge_to_incentive_pool: _v10, operator: @0xf2b948595bd7e12856942016544da14aca954dd182b3987466205a61843fb17c, governance: @0xf2b948595bd7e12856942016544da14aca954dd182b3987466205a61843fb17c, pending_distribution_epoch: _v11};
        move_to<AdministrativeData>(_v3, _v12);
        let _v13 = simple_map::new<object::Object<gauge::Gauge>, u128>();
        let _v14 = GaugeVoteAccounting{total_votes: 0u128, votes_for_gauges: _v13};
        move_to<GaugeVoteAccounting>(_v3, _v14);
        let _v15 = smart_table::new<object::Object<voting_escrow::VeCellanaToken>, simple_map::SimpleMap<object::Object<liquidity_pool::LiquidityPool>, u64>>();
        let _v16 = smart_table::new<object::Object<voting_escrow::VeCellanaToken>, u64>();
        let _v17 = VeTokenVoteAccounting{votes_for_pools_by_ve_token: _v15, last_voted_epoch: _v16};
        move_to<VeTokenVoteAccounting>(_v3, _v17);
    }
    public fun is_gauge_active(p0: object::Object<gauge::Gauge>): bool
        acquires AdministrativeData
    {
        let _v0 = vote_manager_address();
        let _v1 = &borrow_global<AdministrativeData>(_v0).active_gauges;
        let _v2 = false;
        let _v3 = &_v2;
        *smart_table::borrow_with_default<object::Object<gauge::Gauge>, bool>(_v1, p0, _v3)
    }
    public fun is_initialized(): bool {
        package_manager::address_exists(string::utf8(vector[86u8, 79u8, 84u8, 69u8, 95u8, 77u8, 65u8, 78u8, 65u8, 71u8, 69u8, 82u8]))
    }
    public entry fun merge_ve_tokens(p0: &signer, p1: object::Object<voting_escrow::VeCellanaToken>, p2: object::Object<voting_escrow::VeCellanaToken>)
        acquires VeTokenVoteAccounting
    {
        let _v0;
        let _v1 = last_voted_epoch(p1);
        let _v2 = epoch::now();
        if (_v1 < _v2) {
            let _v3 = last_voted_epoch(p2);
            let _v4 = epoch::now();
            _v0 = _v3 < _v4
        } else _v0 = false;
        assert!(_v0, 12);
        voting_escrow::merge_ve_nft(p0, p1, p2);
    }
    public entry fun migrate_all_pools(p0: &signer)
        acquires AdministrativeData
    {
        let _v0 = vote_manager_address();
        let _v1 = *&borrow_global<AdministrativeData>(_v0).operator;
        let _v2 = signer::address_of(p0);
        assert!(_v1 == _v2, 2);
        let _v3 = liquidity_pool::all_pool_addresses();
        let _v4 = &_v3;
        let _v5 = 0;
        let _v6 = vector::length<object::Object<liquidity_pool::LiquidityPool>>(_v4);
        while (_v5 < _v6) {
            whitelist_default_reward_pool(*vector::borrow<object::Object<liquidity_pool::LiquidityPool>>(_v4, _v5));
            _v5 = _v5 + 1
        };
    }
    public entry fun poke(p0: &signer, p1: object::Object<voting_escrow::VeCellanaToken>)
        acquires AdministrativeData, GaugeVoteAccounting, VeTokenVoteAccounting
    {
        let _v0 = vote_manager_address();
        let _v1 = &borrow_global<VeTokenVoteAccounting>(_v0).votes_for_pools_by_ve_token;
        assert!(smart_table::contains<object::Object<voting_escrow::VeCellanaToken>, simple_map::SimpleMap<object::Object<liquidity_pool::LiquidityPool>, u64>>(_v1, p1), 7);
        let _v2 = smart_table::borrow<object::Object<voting_escrow::VeCellanaToken>, simple_map::SimpleMap<object::Object<liquidity_pool::LiquidityPool>, u64>>(_v1, p1);
        let _v3 = simple_map::keys<object::Object<liquidity_pool::LiquidityPool>, u64>(_v2);
        let _v4 = simple_map::values<object::Object<liquidity_pool::LiquidityPool>, u64>(_v2);
        vote(p0, p1, _v3, _v4);
    }
    fun remove_ve_token_vote_records(p0: &mut VeTokenVoteAccounting, p1: object::Object<voting_escrow::VeCellanaToken>) {
        if (smart_table::contains<object::Object<voting_escrow::VeCellanaToken>, simple_map::SimpleMap<object::Object<liquidity_pool::LiquidityPool>, u64>>(&p0.votes_for_pools_by_ve_token, p1)) {
            let _v0 = smart_table::remove<object::Object<voting_escrow::VeCellanaToken>, simple_map::SimpleMap<object::Object<liquidity_pool::LiquidityPool>, u64>>(&mut p0.votes_for_pools_by_ve_token, p1);
        };
        voting_escrow::unfreeze_token(p1);
    }
    public entry fun rescue_stuck_rewards(p0: address, p1: vector<object::Object<liquidity_pool::LiquidityPool>>, p2: u64)
        acquires AdministrativeData, GaugeVoteAccounting
    {
        assert!(!voting_escrow::nft_exists(p0), 13);
        let _v0 = epoch::now();
        let _v1 = p1;
        vector::reverse<object::Object<liquidity_pool::LiquidityPool>>(&mut _v1);
        let _v2 = _v1;
        let _v3 = vector::length<object::Object<liquidity_pool::LiquidityPool>>(&_v2);
        while (_v3 > 0) {
            let _v4 = vector::pop_back<object::Object<liquidity_pool::LiquidityPool>>(&mut _v2);
            let _v5 = _v0 - p2;
            let _v6 = vector::empty<fungible_asset::FungibleAsset>();
            while (_v5 < _v0) {
                let _v7 = fees_pool(_v4);
                let _v8 = rewards_pool::claim_rewards(p0, _v7, _v5);
                let _v9 = incentive_pool(_v4);
                let _v10 = rewards_pool::claim_rewards(p0, _v9, _v5);
                vector::append<fungible_asset::FungibleAsset>(&mut _v6, _v8);
                vector::append<fungible_asset::FungibleAsset>(&mut _v6, _v10);
                _v5 = _v5 + 1;
                continue
            };
            incentivize(_v4, _v6);
            _v3 = _v3 - 1;
            continue
        };
        vector::destroy_empty<object::Object<liquidity_pool::LiquidityPool>>(_v2);
    }
    public entry fun reset(p0: &signer, p1: object::Object<voting_escrow::VeCellanaToken>)
        acquires VeTokenVoteAccounting
    {
        let _v0 = p1;
        let _v1 = signer::address_of(p0);
        assert!(object::is_owner<voting_escrow::VeCellanaToken>(_v0, _v1), 6);
        let _v2 = vote_manager_address();
        let _v3 = borrow_global_mut<VeTokenVoteAccounting>(_v2);
        let _v4 = smart_table::borrow_mut_with_default<object::Object<voting_escrow::VeCellanaToken>, u64>(&mut _v3.last_voted_epoch, _v0, 0);
        let _v5 = epoch::now();
        let _v6 = *_v4;
        assert!(_v5 > _v6, 5);
        *_v4 = _v5;
        remove_ve_token_vote_records(_v3, p1);
        event::emit<AbstainEvent>(AbstainEvent{owner: signer::address_of(p0), ve_token: p1});
    }
    public entry fun split_ve_tokens(p0: &signer, p1: object::Object<voting_escrow::VeCellanaToken>, p2: vector<u64>)
        acquires VeTokenVoteAccounting
    {
        let _v0 = last_voted_epoch(p1);
        let _v1 = epoch::now();
        assert!(_v0 < _v1, 12);
        let _v2 = voting_escrow::split_ve_nft(p0, p1, p2);
    }
    public fun token_votes(p0: object::Object<voting_escrow::VeCellanaToken>): (simple_map::SimpleMap<object::Object<liquidity_pool::LiquidityPool>, u64>, u64)
        acquires VeTokenVoteAccounting
    {
        let _v0 = vote_manager_address();
        let _v1 = borrow_global<VeTokenVoteAccounting>(_v0);
        let _v2 = &_v1.last_voted_epoch;
        let _v3 = 0;
        let _v4 = &_v3;
        let _v5 = *smart_table::borrow_with_default<object::Object<voting_escrow::VeCellanaToken>, u64>(_v2, p0, _v4);
        let _v6 = &_v1.votes_for_pools_by_ve_token;
        let _v7 = simple_map::new<object::Object<liquidity_pool::LiquidityPool>, u64>();
        let _v8 = &_v7;
        (*smart_table::borrow_with_default<object::Object<voting_escrow::VeCellanaToken>, simple_map::SimpleMap<object::Object<liquidity_pool::LiquidityPool>, u64>>(_v6, p0, _v8), _v5)
    }
    fun unwrap_and_deposit<T0>(p0: address, p1: fungible_asset::FungibleAsset) {
        if (fungible_asset::amount(&p1) > 0) {
            let _v0 = coin_wrapper::unwrap<T0>(p1);
            aptos_account::deposit_coins<T0>(p0, _v0)
        } else fungible_asset::destroy_zero(p1);
    }
    public entry fun update_governance(p0: &signer, p1: address)
        acquires AdministrativeData
    {
        let _v0 = vote_manager_address();
        let _v1 = borrow_global_mut<AdministrativeData>(_v0);
        let _v2 = *&_v1.governance;
        let _v3 = signer::address_of(p0);
        assert!(_v2 == _v3, 2);
        let _v4 = &mut _v1.governance;
        *_v4 = p1;
    }
    public entry fun update_operator(p0: &signer, p1: address)
        acquires AdministrativeData
    {
        let _v0 = vote_manager_address();
        let _v1 = *&borrow_global<AdministrativeData>(_v0).operator;
        let _v2 = signer::address_of(p0);
        assert!(_v1 == _v2, 2);
        let _v3 = vote_manager_address();
        let _v4 = &mut borrow_global_mut<AdministrativeData>(_v3).operator;
        *_v4 = p1;
    }
    public entry fun upgrade(p0: &signer, p1: vector<u8>, p2: vector<vector<u8>>)
        acquires AdministrativeData
    {
        let _v0 = vote_manager_address();
        let _v1 = *&borrow_global<AdministrativeData>(_v0).governance;
        let _v2 = signer::address_of(p0);
        assert!(_v1 == _v2, 2);
        let _v3 = package_manager::get_signer();
        code::publish_package_txn(&_v3, p1, p2);
    }
    public entry fun vote(p0: &signer, p1: object::Object<voting_escrow::VeCellanaToken>, p2: vector<object::Object<liquidity_pool::LiquidityPool>>, p3: vector<u64>)
        acquires AdministrativeData, GaugeVoteAccounting, VeTokenVoteAccounting
    {
        let _v0 = 0;
        let _v1 = p3;
        vector::reverse<u64>(&mut _v1);
        let _v2 = _v1;
        let _v3 = vector::length<u64>(&_v2);
        while (_v3 > 0) {
            let _v4 = vector::pop_back<u64>(&mut _v2);
            _v0 = _v0 + _v4;
            _v3 = _v3 - 1;
            continue
        };
        vector::destroy_empty<u64>(_v2);
        let _v5 = _v0;
        assert!(_v5 > 0, 1);
        advance_epoch();
        let _v6 = p1;
        let _v7 = signer::address_of(p0);
        assert!(object::is_owner<voting_escrow::VeCellanaToken>(_v6, _v7), 6);
        let _v8 = vote_manager_address();
        let _v9 = borrow_global_mut<VeTokenVoteAccounting>(_v8);
        let _v10 = smart_table::borrow_mut_with_default<object::Object<voting_escrow::VeCellanaToken>, u64>(&mut _v9.last_voted_epoch, _v6, 0);
        let _v11 = epoch::now();
        let _v12 = *_v10;
        assert!(_v11 > _v12, 5);
        *_v10 = _v11;
        let _v13 = _v9;
        remove_ve_token_vote_records(_v13, p1);
        voting_escrow::freeze_token(p1);
        let _v14 = vote_manager_address();
        let _v15 = borrow_global_mut<GaugeVoteAccounting>(_v14);
        let _v16 = vote_manager_address();
        let _v17 = borrow_global<AdministrativeData>(_v16);
        let _v18 = p3;
        let _v19 = p2;
        vector::reverse<object::Object<liquidity_pool::LiquidityPool>>(&mut _v19);
        vector::reverse<u64>(&mut _v18);
        let _v20 = _v18;
        let _v21 = _v19;
        let _v22 = vector::length<object::Object<liquidity_pool::LiquidityPool>>(&_v21);
        let _v23 = vector::length<u64>(&_v20);
        assert!(_v22 == _v23, 131074);
        'l0: loop {
            loop {
                if (!(_v22 > 0)) break 'l0;
                let _v24 = vector::pop_back<object::Object<liquidity_pool::LiquidityPool>>(&mut _v21);
                let _v25 = vector::pop_back<u64>(&mut _v20);
                let _v26 = _v24;
                if (_v25 > 0) {
                    let _v27 = *smart_table::borrow<object::Object<liquidity_pool::LiquidityPool>, object::Object<gauge::Gauge>>(&_v17.pool_to_gauge, _v26);
                    if (!smart_table::contains<object::Object<gauge::Gauge>, bool>(&_v17.active_gauges, _v27)) break;
                    let _v28 = voting_escrow::get_voting_power(p1);
                    let _v29 = _v25 * _v28 / _v5;
                    let _v30 = *smart_table::borrow<object::Object<gauge::Gauge>, object::Object<rewards_pool::RewardsPool>>(&_v17.gauge_to_fees_pool, _v27);
                    let _v31 = object::object_address<voting_escrow::VeCellanaToken>(&p1);
                    rewards_pool::increase_allocation(_v31, _v30, _v29);
                    let _v32 = *smart_table::borrow<object::Object<gauge::Gauge>, object::Object<rewards_pool::RewardsPool>>(&_v17.gauge_to_incentive_pool, _v27);
                    rewards_pool::increase_allocation(_v31, _v32, _v29);
                    let _v33 = *&_v15.total_votes;
                    let _v34 = _v29 as u128;
                    let _v35 = _v33 + _v34;
                    let _v36 = &mut _v15.total_votes;
                    *_v36 = _v35;
                    let _v37 = &mut _v15.votes_for_gauges;
                    let _v38 = &_v27;
                    if (!simple_map::contains_key<object::Object<gauge::Gauge>, u128>(freeze(_v37), _v38)) {
                        let _v39 = _v29 as u128;
                        simple_map::add<object::Object<gauge::Gauge>, u128>(_v37, _v27, _v39)
                    } else {
                        let _v40 = &_v27;
                        let _v41 = simple_map::borrow_mut<object::Object<gauge::Gauge>, u128>(_v37, _v40);
                        let _v42 = *_v41;
                        let _v43 = _v29 as u128;
                        *_v41 = _v42 + _v43
                    };
                    let _v44 = &mut _v13.votes_for_pools_by_ve_token;
                    let _v45 = simple_map::new<object::Object<liquidity_pool::LiquidityPool>, u64>();
                    simple_map::add<object::Object<liquidity_pool::LiquidityPool>, u64>(smart_table::borrow_mut_with_default<object::Object<voting_escrow::VeCellanaToken>, simple_map::SimpleMap<object::Object<liquidity_pool::LiquidityPool>, u64>>(_v44, p1, _v45), _v26, _v29)
                };
                _v22 = _v22 - 1;
                continue
            };
            abort 9
        };
        vector::destroy_empty<object::Object<liquidity_pool::LiquidityPool>>(_v21);
        vector::destroy_empty<u64>(_v20);
        event::emit<VoteEvent>(VoteEvent{owner: signer::address_of(p0), ve_token: p1, pools: p2, weights: p3});
    }
    public entry fun vote_batch(p0: &signer, p1: vector<object::Object<voting_escrow::VeCellanaToken>>, p2: vector<object::Object<liquidity_pool::LiquidityPool>>, p3: vector<u64>)
        acquires AdministrativeData, GaugeVoteAccounting, VeTokenVoteAccounting
    {
        let _v0 = p1;
        vector::reverse<object::Object<voting_escrow::VeCellanaToken>>(&mut _v0);
        let _v1 = _v0;
        let _v2 = vector::length<object::Object<voting_escrow::VeCellanaToken>>(&_v1);
        while (_v2 > 0) {
            let _v3 = vector::pop_back<object::Object<voting_escrow::VeCellanaToken>>(&mut _v1);
            vote(p0, _v3, p2, p3);
            _v2 = _v2 - 1;
            continue
        };
        vector::destroy_empty<object::Object<voting_escrow::VeCellanaToken>>(_v1);
    }
    public fun vote_manager_address(): address {
        package_manager::get_address(string::utf8(vector[86u8, 79u8, 84u8, 69u8, 95u8, 77u8, 65u8, 78u8, 65u8, 71u8, 69u8, 82u8]))
    }
    public entry fun whitelist_coin<T0>(p0: &signer)
        acquires AdministrativeData
    {
        let _v0 = vote_manager_address();
        let _v1 = *&borrow_global<AdministrativeData>(_v0).operator;
        let _v2 = signer::address_of(p0);
        assert!(_v1 == _v2, 2);
        token_whitelist::whitelist_coin<T0>();
        let _v3 = coin_wrapper::create_fungible_asset<T0>();
        let _v4 = coin_wrapper::format_coin<T0>();
        let _v5 = vector::empty<string::String>();
        vector::push_back<string::String>(&mut _v5, _v4);
        event::emit<WhitelistEvent>(WhitelistEvent{tokens: _v5});
    }
    friend fun whitelist_default_reward_pool(p0: object::Object<liquidity_pool::LiquidityPool>) {
        let _v0 = vector::empty<string::String>();
        let _v1 = &mut _v0;
        let _v2 = string::utf8(vector[48u8, 120u8, 49u8, 58u8, 58u8, 97u8, 112u8, 116u8, 111u8, 115u8, 95u8, 99u8, 111u8, 105u8, 110u8, 58u8, 58u8, 65u8, 112u8, 116u8, 111u8, 115u8, 67u8, 111u8, 105u8, 110u8]);
        vector::push_back<string::String>(_v1, _v2);
        let _v3 = &mut _v0;
        let _v4 = string::utf8(vector[48u8, 120u8, 49u8, 49u8, 49u8, 97u8, 101u8, 51u8, 101u8, 53u8, 98u8, 99u8, 56u8, 49u8, 54u8, 97u8, 53u8, 101u8, 54u8, 51u8, 99u8, 50u8, 100u8, 97u8, 57u8, 55u8, 100u8, 48u8, 97u8, 97u8, 51u8, 56u8, 56u8, 54u8, 53u8, 49u8, 57u8, 101u8, 48u8, 99u8, 100u8, 53u8, 101u8, 52u8, 98u8, 48u8, 52u8, 54u8, 54u8, 53u8, 57u8, 102u8, 97u8, 51u8, 53u8, 55u8, 57u8, 54u8, 98u8, 100u8, 49u8, 49u8, 53u8, 52u8, 50u8, 97u8, 58u8, 58u8, 97u8, 109u8, 97u8, 112u8, 116u8, 95u8, 116u8, 111u8, 107u8, 101u8, 110u8, 58u8, 58u8, 65u8, 109u8, 110u8, 105u8, 115u8, 65u8, 112u8, 116u8]);
        vector::push_back<string::String>(_v3, _v4);
        let _v5 = liquidity_pool::supported_inner_assets(p0);
        let _v6 = &_v5;
        let _v7 = 0;
        let _v8 = vector::length<object::Object<fungible_asset::Metadata>>(_v6);
        while (_v7 < _v8) {
            let _v9 = vector::borrow<object::Object<fungible_asset::Metadata>>(_v6, _v7);
            let _v10 = &mut _v0;
            let _v11 = coin_wrapper::get_original(*_v9);
            vector::push_back<string::String>(_v10, _v11);
            _v7 = _v7 + 1;
            continue
        };
        let _v12 = true;
        let _v13 = _v0;
        let _v14 = p0;
        let _v15 = object::object_address<liquidity_pool::LiquidityPool>(&_v14);
        token_whitelist::set_whitelist_reward_tokens(_v13, _v15, _v12);
        event::emit<WhitelistRewardEvent>(WhitelistRewardEvent{tokens: _v13, is_wl: _v12});
    }
    public entry fun whitelist_native_fungible_assets(p0: &signer, p1: vector<object::Object<fungible_asset::Metadata>>)
        acquires AdministrativeData
    {
        let _v0 = vote_manager_address();
        let _v1 = *&borrow_global<AdministrativeData>(_v0).operator;
        let _v2 = signer::address_of(p0);
        assert!(_v1 == _v2, 2);
        token_whitelist::whitelist_native_fungible_assets(p1);
        let _v3 = vector::empty<string::String>();
        let _v4 = p1;
        vector::reverse<object::Object<fungible_asset::Metadata>>(&mut _v4);
        let _v5 = _v4;
        let _v6 = vector::length<object::Object<fungible_asset::Metadata>>(&_v5);
        while (_v6 > 0) {
            let _v7 = vector::pop_back<object::Object<fungible_asset::Metadata>>(&mut _v5);
            let _v8 = &mut _v3;
            let _v9 = coin_wrapper::format_fungible_asset(_v7);
            vector::push_back<string::String>(_v8, _v9);
            _v6 = _v6 - 1;
            continue
        };
        vector::destroy_empty<object::Object<fungible_asset::Metadata>>(_v5);
        event::emit<WhitelistEvent>(WhitelistEvent{tokens: _v3});
    }
    public entry fun whitelist_token_reward_pool_entry(p0: &signer, p1: object::Object<liquidity_pool::LiquidityPool>, p2: vector<string::String>, p3: bool)
        acquires AdministrativeData
    {
        let _v0 = vote_manager_address();
        let _v1 = *&borrow_global<AdministrativeData>(_v0).operator;
        let _v2 = signer::address_of(p0);
        assert!(_v1 == _v2, 2);
        let _v3 = p3;
        let _v4 = p2;
        let _v5 = p1;
        let _v6 = object::object_address<liquidity_pool::LiquidityPool>(&_v5);
        token_whitelist::set_whitelist_reward_tokens(_v4, _v6, _v3);
        event::emit<WhitelistRewardEvent>(WhitelistRewardEvent{tokens: _v4, is_wl: _v3});
    }
}
