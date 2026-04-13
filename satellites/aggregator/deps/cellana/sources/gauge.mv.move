module 0x4bf51972879e3b95c4781a5cdcb9e1ee24ef483e7d22f2d903626f126df62bd1::gauge {
    use 0x1::event;
    use 0x1::fungible_asset;
    use 0x1::object;
    use 0x1::signer;
    use 0x4bf51972879e3b95c4781a5cdcb9e1ee24ef483e7d22f2d903626f126df62bd1::cellana_token;
    use 0x4bf51972879e3b95c4781a5cdcb9e1ee24ef483e7d22f2d903626f126df62bd1::liquidity_pool;
    use 0x4bf51972879e3b95c4781a5cdcb9e1ee24ef483e7d22f2d903626f126df62bd1::package_manager;
    use 0x4bf51972879e3b95c4781a5cdcb9e1ee24ef483e7d22f2d903626f126df62bd1::rewards_pool_continuous;
    friend 0x4bf51972879e3b95c4781a5cdcb9e1ee24ef483e7d22f2d903626f126df62bd1::router;
    friend 0x4bf51972879e3b95c4781a5cdcb9e1ee24ef483e7d22f2d903626f126df62bd1::vote_manager;
    struct Gauge has key {
        rewards_pool: object::Object<rewards_pool_continuous::RewardsPool>,
        extend_ref: object::ExtendRef,
        liquidity_pool: object::Object<liquidity_pool::LiquidityPool>,
    }
    struct StakeEvent has drop, store {
        lp: address,
        gauge: object::Object<Gauge>,
        amount: u64,
    }
    struct UnstakeEvent has drop, store {
        lp: address,
        gauge: object::Object<Gauge>,
        amount: u64,
    }
    public fun liquidity_pool(p0: object::Object<Gauge>): object::Object<liquidity_pool::LiquidityPool>
        acquires Gauge
    {
        let _v0 = object::object_address<Gauge>(&p0);
        *&borrow_global<Gauge>(_v0).liquidity_pool
    }
    public fun rewards_pool(p0: object::Object<Gauge>): object::Object<rewards_pool_continuous::RewardsPool>
        acquires Gauge
    {
        let _v0 = object::object_address<Gauge>(&p0);
        *&borrow_global<Gauge>(_v0).rewards_pool
    }
    friend fun add_rewards(p0: object::Object<Gauge>, p1: fungible_asset::FungibleAsset)
        acquires Gauge
    {
        rewards_pool_continuous::add_rewards(rewards_pool(p0), p1);
    }
    friend fun claim_fees(p0: object::Object<Gauge>): (fungible_asset::FungibleAsset, fungible_asset::FungibleAsset)
        acquires Gauge
    {
        let _v0 = object::object_address<Gauge>(&p0);
        let _v1 = object::generate_signer_for_extending(&borrow_global<Gauge>(_v0).extend_ref);
        let _v2 = &_v1;
        let _v3 = liquidity_pool(p0);
        let (_v4,_v5) = liquidity_pool::claim_fees(_v2, _v3);
        (_v4, _v5)
    }
    friend fun claim_rewards(p0: &signer, p1: object::Object<Gauge>): fungible_asset::FungibleAsset
        acquires Gauge
    {
        let _v0 = signer::address_of(p0);
        let _v1 = rewards_pool(p1);
        rewards_pool_continuous::claim_rewards(_v0, _v1)
    }
    public fun claimable_rewards(p0: address, p1: object::Object<Gauge>): u64
        acquires Gauge
    {
        let _v0 = rewards_pool(p1);
        rewards_pool_continuous::claimable_rewards(p0, _v0)
    }
    friend fun create(p0: object::Object<liquidity_pool::LiquidityPool>): object::Object<Gauge> {
        let _v0 = package_manager::get_signer();
        let _v1 = object::create_object_from_account(&_v0);
        let _v2 = &_v1;
        let _v3 = fungible_asset::create_store<liquidity_pool::LiquidityPool>(_v2, p0);
        let _v4 = object::convert<cellana_token::CellanaToken, fungible_asset::Metadata>(cellana_token::token());
        let _v5 = rewards_duration();
        let _v6 = rewards_pool_continuous::create(_v4, _v5);
        let _v7 = object::generate_signer(_v2);
        let _v8 = &_v7;
        let _v9 = object::generate_extend_ref(_v2);
        let _v10 = Gauge{rewards_pool: _v6, extend_ref: _v9, liquidity_pool: p0};
        move_to<Gauge>(_v8, _v10);
        object::object_from_constructor_ref<Gauge>(_v2)
    }
    public fun rewards_duration(): u64 {
        604800
    }
    public entry fun stake(p0: &signer, p1: object::Object<Gauge>, p2: u64)
        acquires Gauge
    {
        let _v0 = object::convert<liquidity_pool::LiquidityPool, liquidity_pool::LiquidityPool>(liquidity_pool(p1));
        let _v1 = object::object_address<Gauge>(&p1);
        liquidity_pool::transfer(p0, _v0, _v1, p2);
        let _v2 = signer::address_of(p0);
        let _v3 = rewards_pool(p1);
        rewards_pool_continuous::stake(_v2, _v3, p2);
        event::emit<StakeEvent>(StakeEvent{lp: _v2, gauge: p1, amount: p2});
    }
    public fun stake_balance(p0: address, p1: object::Object<Gauge>): u64
        acquires Gauge
    {
        let _v0 = rewards_pool(p1);
        rewards_pool_continuous::stake_balance(p0, _v0)
    }
    public fun stake_token(p0: object::Object<Gauge>): object::Object<fungible_asset::Metadata>
        acquires Gauge
    {
        let _v0 = object::object_address<Gauge>(&p0);
        object::convert<liquidity_pool::LiquidityPool, fungible_asset::Metadata>(*&borrow_global<Gauge>(_v0).liquidity_pool)
    }
    public fun total_stake(p0: object::Object<Gauge>): u128
        acquires Gauge
    {
        rewards_pool_continuous::total_stake(rewards_pool(p0))
    }
    public entry fun unstake(p0: &signer, p1: object::Object<Gauge>, p2: u64) {
        abort 0
    }
    friend fun unstake_lp(p0: &signer, p1: object::Object<Gauge>, p2: u64)
        acquires Gauge
    {
        let _v0 = signer::address_of(p0);
        let _v1 = object::object_address<Gauge>(&p1);
        let _v2 = object::generate_signer_for_extending(&borrow_global<Gauge>(_v1).extend_ref);
        let _v3 = &_v2;
        let _v4 = liquidity_pool(p1);
        liquidity_pool::transfer(_v3, _v4, _v0, p2);
        let _v5 = rewards_pool(p1);
        assert!(rewards_pool_continuous::stake_balance(_v0, _v5) >= p2, 1);
        let _v6 = rewards_pool(p1);
        rewards_pool_continuous::unstake(_v0, _v6, p2);
        event::emit<UnstakeEvent>(UnstakeEvent{lp: _v0, gauge: p1, amount: p2});
    }
}
