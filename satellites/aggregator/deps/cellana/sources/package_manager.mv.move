module 0x4bf51972879e3b95c4781a5cdcb9e1ee24ef483e7d22f2d903626f126df62bd1::package_manager {
    use 0x1::account;
    use 0x1::resource_account;
    use 0x1::smart_table;
    use 0x1::string;
    friend 0x4bf51972879e3b95c4781a5cdcb9e1ee24ef483e7d22f2d903626f126df62bd1::cellana_token;
    friend 0x4bf51972879e3b95c4781a5cdcb9e1ee24ef483e7d22f2d903626f126df62bd1::coin_wrapper;
    friend 0x4bf51972879e3b95c4781a5cdcb9e1ee24ef483e7d22f2d903626f126df62bd1::gauge;
    friend 0x4bf51972879e3b95c4781a5cdcb9e1ee24ef483e7d22f2d903626f126df62bd1::liquidity_pool;
    friend 0x4bf51972879e3b95c4781a5cdcb9e1ee24ef483e7d22f2d903626f126df62bd1::minter;
    friend 0x4bf51972879e3b95c4781a5cdcb9e1ee24ef483e7d22f2d903626f126df62bd1::rewards_pool;
    friend 0x4bf51972879e3b95c4781a5cdcb9e1ee24ef483e7d22f2d903626f126df62bd1::rewards_pool_continuous;
    friend 0x4bf51972879e3b95c4781a5cdcb9e1ee24ef483e7d22f2d903626f126df62bd1::router;
    friend 0x4bf51972879e3b95c4781a5cdcb9e1ee24ef483e7d22f2d903626f126df62bd1::token_whitelist;
    friend 0x4bf51972879e3b95c4781a5cdcb9e1ee24ef483e7d22f2d903626f126df62bd1::vote_manager;
    friend 0x4bf51972879e3b95c4781a5cdcb9e1ee24ef483e7d22f2d903626f126df62bd1::voting_escrow;
    struct PermissionConfig has key {
        signer_cap: account::SignerCapability,
        addresses: smart_table::SmartTable<string::String, address>,
    }
    friend fun add_address(p0: string::String, p1: address)
        acquires PermissionConfig
    {
        smart_table::add<string::String, address>(&mut borrow_global_mut<PermissionConfig>(@0x4bf51972879e3b95c4781a5cdcb9e1ee24ef483e7d22f2d903626f126df62bd1).addresses, p0, p1);
    }
    public fun address_exists(p0: string::String): bool
        acquires PermissionConfig
    {
        smart_table::contains<string::String, address>(&borrow_global<PermissionConfig>(@0x4bf51972879e3b95c4781a5cdcb9e1ee24ef483e7d22f2d903626f126df62bd1).addresses, p0)
    }
    public fun get_address(p0: string::String): address
        acquires PermissionConfig
    {
        *smart_table::borrow<string::String, address>(&borrow_global<PermissionConfig>(@0x4bf51972879e3b95c4781a5cdcb9e1ee24ef483e7d22f2d903626f126df62bd1).addresses, p0)
    }
    friend fun get_signer(): signer
        acquires PermissionConfig
    {
        account::create_signer_with_capability(&borrow_global<PermissionConfig>(@0x4bf51972879e3b95c4781a5cdcb9e1ee24ef483e7d22f2d903626f126df62bd1).signer_cap)
    }
    fun init_module(p0: &signer) {
        let _v0 = resource_account::retrieve_resource_account_cap(p0, @0xf2b948595bd7e12856942016544da14aca954dd182b3987466205a61843fb17c);
        let _v1 = smart_table::new<string::String, address>();
        let _v2 = PermissionConfig{signer_cap: _v0, addresses: _v1};
        move_to<PermissionConfig>(p0, _v2);
    }
}
