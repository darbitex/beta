/// Darbitex Beta — pool factory.
///
/// Creates canonical pools (one per pair, enforced by deterministic
/// named-object addresses). Every pool creation is atomic: pool + 2
/// HookNFTs + initial LpPosition + escrow listing. The factory also
/// holds hook NFT #2 in escrow and serves `buy_hook` at a fixed admin-
/// configurable price, routing the APT payment to the operational
/// revenue address. No marketplace satellite needed.

module darbitex::pool_factory {
    use std::signer;
    use std::vector;
    use std::bcs;
    use aptos_std::table::{Self, Table};
    use aptos_framework::account::{Self, SignerCapability};
    use aptos_framework::object::{Self, Object};
    use aptos_framework::fungible_asset::Metadata;
    use aptos_framework::primary_fungible_store;
    use aptos_framework::aptos_account;
    use aptos_framework::event;
    use aptos_framework::timestamp;

    use darbitex::pool::{Self, HookNFT};

    // ===== Constants =====

    const FACTORY_SEED: vector<u8> = b"darbitex_factory";
    const POOL_SEED_PREFIX: vector<u8> = b"darbitex_pool";
    const DEFAULT_HOOK_PRICE: u64 = 10_000_000_000; // 100 APT in octas

    /// Treasury multisig (2-of-3, reused from V1). Receives HookNFT #1
    /// (soulbound slot) at every pool creation, earning a permanent hook
    /// fee stream across all Darbitex pools.
    const TREASURY_ADDR: address = @0xdbce89113a975826028236f910668c3ff99c8db8981be6a448caa2f8836f9576;

    /// Admin multisig (3-of-5, reused from V1). Can call `set_hook_price`
    /// to update the default listing price for future pools. Same address
    /// also receives `buy_hook` revenue (operational income).
    const ADMIN_ADDR: address = @0xf1b522effb90aef79395f97b9c39d6acbd8fdf84ec046361359a48de2e196566;

    /// buy_hook payment destination. Same as ADMIN_ADDR by design —
    /// operational multisig collects hook sale revenue.
    const REVENUE_ADDR: address = @0xf1b522effb90aef79395f97b9c39d6acbd8fdf84ec046361359a48de2e196566;

    // ===== Errors =====

    const E_NOT_ADMIN: u64 = 1;
    const E_ALREADY_INIT: u64 = 2;
    const E_NOT_INIT: u64 = 3;
    const E_WRONG_ORDER: u64 = 4;
    const E_ZERO: u64 = 5;
    const E_NOT_LISTED: u64 = 6;
    const E_SAME_TOKEN: u64 = 7;

    // ===== Resources =====

    /// Singleton at @darbitex. Owns the resource account SignerCap under
    /// which all pool objects live, tracks the pool registry, and holds
    /// the HookNFT #2 escrow table.
    struct Factory has key {
        signer_cap: SignerCapability,
        factory_addr: address,
        pool_count: u64,
        pool_addresses: vector<address>,
        /// pool_addr → APT octas price locked at listing time. Entry is
        /// removed on successful `buy_hook`.
        hook_listings: Table<address, u64>,
        /// Default price for new listings, admin-configurable via
        /// `set_hook_price`. Existing entries in `hook_listings` are
        /// NOT retroactively updated when this changes.
        current_hook_price: u64,
        schema_version: u8,
        _reserved: vector<u8>,
    }

    // ===== Events =====

    #[event]
    struct FactoryInitialized has drop, store {
        factory_addr: address,
        initial_hook_price: u64,
        timestamp: u64,
    }

    #[event]
    struct CanonicalPoolCreated has drop, store {
        pool_addr: address,
        metadata_a: address,
        metadata_b: address,
        creator: address,
        amount: u64,
        hook_nft_1: address,
        hook_nft_2: address,
        list_price: u64,
        timestamp: u64,
    }

    #[event]
    struct HookPurchased has drop, store {
        pool_addr: address,
        nft_addr: address,
        buyer: address,
        price: u64,
        timestamp: u64,
    }

    #[event]
    struct HookPriceUpdated has drop, store {
        old_price: u64,
        new_price: u64,
        timestamp: u64,
    }

    // ===== Internal helpers =====

    /// Require the pair to be in canonical sorted order (BCS byte order).
    /// This avoids ambiguity where (A, B) and (B, A) could produce different
    /// canonical addresses. Callers must pre-sort off-chain; the factory
    /// does not reorder for them (explicitness over convenience).
    fun assert_sorted(metadata_a: Object<Metadata>, metadata_b: Object<Metadata>) {
        let ba = bcs::to_bytes(&object::object_address(&metadata_a));
        let bb = bcs::to_bytes(&object::object_address(&metadata_b));
        assert!(ba < bb, E_WRONG_ORDER);
    }

    /// Compute the deterministic seed used for canonical pool object
    /// creation: `POOL_SEED_PREFIX || bcs(meta_a) || bcs(meta_b)`.
    fun derive_pair_seed(
        metadata_a: Object<Metadata>,
        metadata_b: Object<Metadata>,
    ): vector<u8> {
        let seed = POOL_SEED_PREFIX;
        vector::append(&mut seed, bcs::to_bytes(&object::object_address(&metadata_a)));
        vector::append(&mut seed, bcs::to_bytes(&object::object_address(&metadata_b)));
        seed
    }

    // ===== Factory init =====

    /// One-shot initializer. Must be called by the package publisher
    /// (`@darbitex`) exactly once, immediately after publish. Creates the
    /// resource account that hosts all canonical pools, moves the Factory
    /// singleton to @darbitex, and sets the default hook price.
    public entry fun init_factory(deployer: &signer) {
        let addr = signer::address_of(deployer);
        assert!(addr == @darbitex, E_NOT_ADMIN);
        assert!(!exists<Factory>(@darbitex), E_ALREADY_INIT);

        let (factory_signer, signer_cap) = account::create_resource_account(deployer, FACTORY_SEED);
        let factory_addr = signer::address_of(&factory_signer);

        move_to(deployer, Factory {
            signer_cap,
            factory_addr,
            pool_count: 0,
            pool_addresses: vector::empty(),
            hook_listings: table::new(),
            current_hook_price: DEFAULT_HOOK_PRICE,
            schema_version: 1,
            _reserved: vector::empty(),
        });

        event::emit(FactoryInitialized {
            factory_addr,
            initial_hook_price: DEFAULT_HOOK_PRICE,
            timestamp: timestamp::now_seconds(),
        });
    }

    // ===== Pool creation =====

    /// Atomic canonical pool creation. The caller supplies seeding tokens
    /// (`amount` of each side — symmetric seeding enforced in pool.move),
    /// the factory pulls them into its resource account store and forwards
    /// to the fresh pool, mints both HookNFTs, mints the creator's
    /// LpPosition, and lists HookNFT #2 in the escrow table at the
    /// current price.
    ///
    /// Duplicate protection: `object::create_named_object` aborts with
    /// EOBJECT_EXISTS if the canonical address is already occupied — so
    /// a second create_canonical_pool call for the same (sorted) pair
    /// reverts at the Move framework level before any factory state
    /// mutation.
    public entry fun create_canonical_pool(
        creator: &signer,
        metadata_a: Object<Metadata>,
        metadata_b: Object<Metadata>,
        amount: u64,
    ) acquires Factory {
        assert!(exists<Factory>(@darbitex), E_NOT_INIT);
        assert!(amount > 0, E_ZERO);
        assert_sorted(metadata_a, metadata_b);
        assert!(
            object::object_address(&metadata_a) != object::object_address(&metadata_b),
            E_SAME_TOKEN,
        );

        let factory = borrow_global_mut<Factory>(@darbitex);
        let factory_signer = account::create_signer_with_capability(&factory.signer_cap);
        let factory_addr = factory.factory_addr;
        let creator_addr = signer::address_of(creator);

        // Pull seeding tokens from creator into factory's resource account store.
        // pool::create_pool will re-withdraw from factory into the new pool.
        let fa_a = primary_fungible_store::withdraw(creator, metadata_a, amount);
        let fa_b = primary_fungible_store::withdraw(creator, metadata_b, amount);
        primary_fungible_store::deposit(factory_addr, fa_a);
        primary_fungible_store::deposit(factory_addr, fa_b);

        // Create the canonical pool object at the deterministic address.
        // Aborts if an object already exists there — duplicate guard.
        let seed = derive_pair_seed(metadata_a, metadata_b);
        let ctor = object::create_named_object(&factory_signer, seed);

        // Hand off to pool module: creates Pool struct, mints 2 HookNFTs,
        // mints initial LpPosition for creator.
        let (pool_addr, hook_1_addr, hook_2_addr, _position) = pool::create_pool(
            &factory_signer,
            factory_addr,
            TREASURY_ADDR,
            creator_addr,
            &ctor,
            metadata_a,
            metadata_b,
            amount,
            amount,
        );

        // List HookNFT #2 in escrow at the currently-configured price.
        // Price is locked at listing — subsequent set_hook_price updates
        // do not retroactively change this pool's listing.
        let list_price = factory.current_hook_price;
        table::add(&mut factory.hook_listings, pool_addr, list_price);

        // Register pool in the enumeration vector.
        factory.pool_count = factory.pool_count + 1;
        vector::push_back(&mut factory.pool_addresses, pool_addr);

        event::emit(CanonicalPoolCreated {
            pool_addr,
            metadata_a: object::object_address(&metadata_a),
            metadata_b: object::object_address(&metadata_b),
            creator: creator_addr,
            amount,
            hook_nft_1: hook_1_addr,
            hook_nft_2: hook_2_addr,
            list_price,
            timestamp: timestamp::now_seconds(),
        });
    }

    // ===== Hook NFT escrow sale =====

    /// Permissionless purchase of HookNFT #2 from the factory escrow at
    /// the listed price. Pays APT to REVENUE_ADDR, transfers the NFT
    /// object to the buyer, and removes the listing. After purchase the
    /// buyer holds the NFT in their own account and can freely transfer
    /// it on any generic Aptos NFT venue (Wapal, Topaz, etc.).
    public entry fun buy_hook(
        buyer: &signer,
        pool_addr: address,
    ) acquires Factory {
        assert!(exists<Factory>(@darbitex), E_NOT_INIT);

        let factory = borrow_global_mut<Factory>(@darbitex);
        assert!(table::contains(&factory.hook_listings, pool_addr), E_NOT_LISTED);
        let price = table::remove(&mut factory.hook_listings, pool_addr);

        // Defensive: verify the factory still owns HookNFT #2 before taking
        // payment. Under normal operation this is always true (the factory
        // holds the NFT in escrow from pool creation until sale), but an
        // explicit assert produces a clearer error than a mid-TX abort
        // deep inside object::transfer. Per audit round-2 LOW-2.
        let (_hook_1, hook_2_addr) = pool::hook_nft_addresses(pool_addr);
        let nft_obj = object::address_to_object<HookNFT>(hook_2_addr);
        assert!(object::owner(nft_obj) == factory.factory_addr, E_NOT_LISTED);

        // Payment: buyer → operational revenue address.
        aptos_account::transfer(buyer, REVENUE_ADDR, price);

        // Transfer NFT object from factory resource account to buyer.
        // Factory is the current owner (set at mint time); buyer becomes
        // new owner via standard object transfer. Ungated transfer is
        // still enabled on slot 1, so no ref manipulation needed here.
        let factory_signer = account::create_signer_with_capability(&factory.signer_cap);
        let buyer_addr = signer::address_of(buyer);
        object::transfer(&factory_signer, nft_obj, buyer_addr);

        event::emit(HookPurchased {
            pool_addr,
            nft_addr: hook_2_addr,
            buyer: buyer_addr,
            price,
            timestamp: timestamp::now_seconds(),
        });
    }

    /// Admin-only. Updates the default hook price applied to NEW pool
    /// listings. Pools already listed in the escrow table keep their
    /// original locked-in price — this call only affects future pools
    /// created after the update.
    public entry fun set_hook_price(
        admin: &signer,
        new_price: u64,
    ) acquires Factory {
        assert!(signer::address_of(admin) == ADMIN_ADDR, E_NOT_ADMIN);
        assert!(exists<Factory>(@darbitex), E_NOT_INIT);
        assert!(new_price > 0, E_ZERO);

        let factory = borrow_global_mut<Factory>(@darbitex);
        let old_price = factory.current_hook_price;
        factory.current_hook_price = new_price;

        event::emit(HookPriceUpdated {
            old_price,
            new_price,
            timestamp: timestamp::now_seconds(),
        });
    }

    // ===== Views =====

    #[view]
    public fun factory_address(): address acquires Factory {
        borrow_global<Factory>(@darbitex).factory_addr
    }

    #[view]
    public fun pool_count(): u64 acquires Factory {
        borrow_global<Factory>(@darbitex).pool_count
    }

    #[view]
    public fun get_all_pools(): vector<address> acquires Factory {
        borrow_global<Factory>(@darbitex).pool_addresses
    }

    #[view]
    public fun get_pools_paginated(offset: u64, limit: u64): vector<address> acquires Factory {
        let f = borrow_global<Factory>(@darbitex);
        let len = vector::length(&f.pool_addresses);
        let start = if (offset > len) { len } else { offset };
        let end = if (start + limit > len) { len } else { start + limit };
        let result = vector::empty<address>();
        let i = start;
        while (i < end) {
            vector::push_back(&mut result, *vector::borrow(&f.pool_addresses, i));
            i = i + 1;
        };
        result
    }

    #[view]
    /// Compute the canonical address for a sorted pair WITHOUT requiring
    /// the pool to exist. Useful for frontends pre-computing pool identity
    /// before creation. Aborts if pair is not sorted.
    public fun canonical_pool_address(
        metadata_a: Object<Metadata>,
        metadata_b: Object<Metadata>,
    ): address acquires Factory {
        assert_sorted(metadata_a, metadata_b);
        let f = borrow_global<Factory>(@darbitex);
        let seed = derive_pair_seed(metadata_a, metadata_b);
        object::create_object_address(&f.factory_addr, seed)
    }

    #[view]
    public fun is_hook_listed(pool_addr: address): bool acquires Factory {
        let f = borrow_global<Factory>(@darbitex);
        table::contains(&f.hook_listings, pool_addr)
    }

    #[view]
    public fun hook_listing_price(pool_addr: address): u64 acquires Factory {
        let f = borrow_global<Factory>(@darbitex);
        *table::borrow(&f.hook_listings, pool_addr)
    }

    #[view]
    public fun current_hook_price(): u64 acquires Factory {
        borrow_global<Factory>(@darbitex).current_hook_price
    }

    #[view]
    public fun treasury_address(): address {
        TREASURY_ADDR
    }

    #[view]
    public fun admin_address(): address {
        ADMIN_ADDR
    }

    #[view]
    public fun revenue_address(): address {
        REVENUE_ADDR
    }
}
