module 0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387::state {
    use 0x1::account;
    use 0x1::table;
    use 0x1::vector;
    use 0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387::contract_upgrade_hash;
    use 0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387::data_source;
    use 0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387::error;
    use 0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387::price_identifier;
    use 0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387::price_info;
    use 0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387::set;
    friend 0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387::contract_upgrade;
    friend 0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387::governance;
    friend 0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387::pyth;
    friend 0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387::set_data_sources;
    friend 0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387::set_governance_data_source;
    friend 0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387::set_stale_price_threshold;
    friend 0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387::set_update_fee;
    struct BaseUpdateFee has key {
        fee: u64,
    }
    struct ContractUpgradeAuthorized has key {
        hash: contract_upgrade_hash::Hash,
    }
    struct DataSources has key {
        sources: set::Set<data_source::DataSource>,
    }
    struct GovernanceDataSource has key {
        source: data_source::DataSource,
    }
    struct LastExecutedGovernanceSequence has key {
        sequence: u64,
    }
    struct LatestPriceInfo has key {
        info: table::Table<price_identifier::PriceIdentifier, price_info::PriceInfo>,
    }
    struct SignerCapability has key {
        signer_capability: account::SignerCapability,
    }
    struct StalePriceThreshold has key {
        threshold_secs: u64,
    }
    public fun get_base_update_fee(): u64
        acquires BaseUpdateFee
    {
        *&borrow_global<BaseUpdateFee>(@0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387).fee
    }
    public fun get_contract_upgrade_authorized_hash(): contract_upgrade_hash::Hash
        acquires ContractUpgradeAuthorized
    {
        if (!exists<ContractUpgradeAuthorized>(@0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387)) {
            let _v0 = error::unauthorized_upgrade();
            abort _v0
        };
        let ContractUpgradeAuthorized{hash: _v1} = move_from<ContractUpgradeAuthorized>(@0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387);
        _v1
    }
    public fun get_last_executed_governance_sequence(): u64
        acquires LastExecutedGovernanceSequence
    {
        *&borrow_global<LastExecutedGovernanceSequence>(@0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387).sequence
    }
    public fun get_latest_price_info(p0: price_identifier::PriceIdentifier): price_info::PriceInfo
        acquires LatestPriceInfo
    {
        if (!price_info_cached(p0)) {
            let _v0 = error::unknown_price_feed();
            abort _v0
        };
        *table::borrow<price_identifier::PriceIdentifier, price_info::PriceInfo>(&borrow_global<LatestPriceInfo>(@0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387).info, p0)
    }
    public fun get_stale_price_threshold_secs(): u64
        acquires StalePriceThreshold
    {
        *&borrow_global<StalePriceThreshold>(@0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387).threshold_secs
    }
    friend fun init(p0: &signer, p1: u64, p2: u64, p3: data_source::DataSource, p4: vector<data_source::DataSource>, p5: account::SignerCapability) {
        let _v0 = StalePriceThreshold{threshold_secs: p1};
        move_to<StalePriceThreshold>(p0, _v0);
        let _v1 = BaseUpdateFee{fee: p2};
        move_to<BaseUpdateFee>(p0, _v1);
        let _v2 = set::new<data_source::DataSource>();
        while (!vector::is_empty<data_source::DataSource>(&p4)) {
            let _v3 = &mut _v2;
            let _v4 = vector::pop_back<data_source::DataSource>(&mut p4);
            set::add<data_source::DataSource>(_v3, _v4);
            continue
        };
        let _v5 = DataSources{sources: _v2};
        move_to<DataSources>(p0, _v5);
        let _v6 = GovernanceDataSource{source: p3};
        move_to<GovernanceDataSource>(p0, _v6);
        let _v7 = LastExecutedGovernanceSequence{sequence: 0};
        move_to<LastExecutedGovernanceSequence>(p0, _v7);
        let _v8 = SignerCapability{signer_capability: p5};
        move_to<SignerCapability>(p0, _v8);
        let _v9 = LatestPriceInfo{info: table::new<price_identifier::PriceIdentifier, price_info::PriceInfo>()};
        move_to<LatestPriceInfo>(p0, _v9);
    }
    public fun is_valid_data_source(p0: data_source::DataSource): bool
        acquires DataSources
    {
        set::contains<data_source::DataSource>(&borrow_global<DataSources>(@0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387).sources, p0)
    }
    public fun is_valid_governance_data_source(p0: data_source::DataSource): bool
        acquires GovernanceDataSource
    {
        *&borrow_global<GovernanceDataSource>(@0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387).source == p0
    }
    public fun price_info_cached(p0: price_identifier::PriceIdentifier): bool
        acquires LatestPriceInfo
    {
        table::contains<price_identifier::PriceIdentifier, price_info::PriceInfo>(&borrow_global<LatestPriceInfo>(@0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387).info, p0)
    }
    friend fun pyth_signer(): signer
        acquires SignerCapability
    {
        account::create_signer_with_capability(&borrow_global<SignerCapability>(@0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387).signer_capability)
    }
    friend fun set_base_update_fee(p0: u64)
        acquires BaseUpdateFee
    {
        let _v0 = &mut borrow_global_mut<BaseUpdateFee>(@0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387).fee;
        *_v0 = p0;
    }
    friend fun set_contract_upgrade_authorized_hash(p0: contract_upgrade_hash::Hash)
        acquires ContractUpgradeAuthorized, SignerCapability
    {
        let _v0;
        if (exists<ContractUpgradeAuthorized>(@0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387)) ContractUpgradeAuthorized{hash: _v0} = move_from<ContractUpgradeAuthorized>(@0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387);
        let _v1 = pyth_signer();
        let _v2 = &_v1;
        let _v3 = ContractUpgradeAuthorized{hash: p0};
        move_to<ContractUpgradeAuthorized>(_v2, _v3);
    }
    friend fun set_data_sources(p0: vector<data_source::DataSource>)
        acquires DataSources
    {
        let _v0 = &mut borrow_global_mut<DataSources>(@0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387).sources;
        set::empty<data_source::DataSource>(_v0);
        while (!vector::is_empty<data_source::DataSource>(&p0)) {
            let _v1 = vector::pop_back<data_source::DataSource>(&mut p0);
            set::add<data_source::DataSource>(_v0, _v1);
            continue
        };
    }
    friend fun set_governance_data_source(p0: data_source::DataSource)
        acquires GovernanceDataSource
    {
        let _v0 = &mut borrow_global_mut<GovernanceDataSource>(@0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387).source;
        *_v0 = p0;
    }
    friend fun set_last_executed_governance_sequence(p0: u64)
        acquires LastExecutedGovernanceSequence
    {
        let _v0 = &mut borrow_global_mut<LastExecutedGovernanceSequence>(@0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387).sequence;
        *_v0 = p0;
    }
    friend fun set_latest_price_info(p0: price_identifier::PriceIdentifier, p1: price_info::PriceInfo)
        acquires LatestPriceInfo
    {
        table::upsert<price_identifier::PriceIdentifier, price_info::PriceInfo>(&mut borrow_global_mut<LatestPriceInfo>(@0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387).info, p0, p1);
    }
    friend fun set_stale_price_threshold_secs(p0: u64)
        acquires StalePriceThreshold
    {
        let _v0 = &mut borrow_global_mut<StalePriceThreshold>(@0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387).threshold_secs;
        *_v0 = p0;
    }
}
