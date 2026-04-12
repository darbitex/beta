/// Darbitex Beta — pool primitive.
///
/// One immutable pool per canonical pair. Every pool is created with two
/// HookNFT objects baked in (treasury slot 0 = soulbound, escrow slot 1 =
/// transferable). LP positions are Aptos objects (NFTs) with global fee
/// accumulator + per-position debt snapshot. Flash loans and TWAP oracle
/// at the pool level. Zero admin surface.

module darbitex::pool {
    use std::signer;
    use std::vector;
    use aptos_framework::event;
    use aptos_framework::object::{Self, Object, ConstructorRef, ExtendRef, DeleteRef};
    use aptos_framework::fungible_asset::{Self, FungibleAsset, Metadata};
    use aptos_framework::primary_fungible_store;
    use aptos_framework::timestamp;

    friend darbitex::pool_factory;

    // ===== Constants =====

    const SWAP_FEE_BPS: u64 = 1;
    const FLASH_FEE_BPS: u64 = 1;
    const BPS_DENOM: u64 = 10_000;
    const EXTRA_FEE_DENOM: u64 = 100_000;
    const HOOK_SPLIT_PCT: u64 = 50;
    const MINIMUM_LIQUIDITY: u64 = 1_000;
    const SCALE: u128 = 1_000_000_000_000;

    // ===== Errors =====

    const E_ZERO_AMOUNT: u64 = 1;
    const E_INSUFFICIENT_LIQUIDITY: u64 = 2;
    const E_SLIPPAGE: u64 = 3;
    const E_LOCKED: u64 = 4;
    const E_DISPROPORTIONAL: u64 = 5;
    const E_WRONG_POOL: u64 = 6;
    const E_INSUFFICIENT_LP: u64 = 7;
    const E_WRONG_TOKEN: u64 = 8;
    const E_RESERVED_9: u64 = 9;  // was E_SYMMETRIC_REQUIRED in early drafts, removed
    const E_K_VIOLATED: u64 = 10;
    const E_NOT_OWNER: u64 = 11;
    const E_NO_POSITION: u64 = 12;
    const E_NO_HOOK_NFT: u64 = 13;
    const E_NO_POOL: u64 = 14;
    const E_SAME_TOKEN: u64 = 15;

    // ===== Structs =====

    /// The pool itself. Config fields are immutable after create_pool returns.
    /// Operational state (reserves, lp_supply, accumulators, locked, twap,
    /// stats) mutates during normal swap / LP / flash operations.
    struct Pool has key {
        // Immutable config
        metadata_a: Object<Metadata>,
        metadata_b: Object<Metadata>,
        extend_ref: ExtendRef,
        hook_nft_1: address,           // treasury slot, soulbound
        hook_nft_2: address,           // escrow / marketplace slot, transferable
        schema_version: u8,

        // Reserves (principal only, LP fee accrues to lp_fee_per_share)
        reserve_a: u64,
        reserve_b: u64,
        lp_supply: u64,

        // LP fee global accumulator (cumulative per-share, scaled by SCALE)
        lp_fee_per_share_a: u128,
        lp_fee_per_share_b: u128,

        // Hook fee absolute accumulators (one pot per slot)
        hook_1_fee_a: u64,
        hook_1_fee_b: u64,
        hook_2_fee_a: u64,
        hook_2_fee_b: u64,

        // Reentrancy guard
        locked: bool,

        // TWAP (Uniswap V2 style cumulative)
        twap_cumulative_a: u128,
        twap_cumulative_b: u128,
        twap_last_ts: u64,

        // Stats
        total_swaps: u64,
        total_volume_a: u128,
        total_volume_b: u128,

        _reserved: vector<u8>,
    }

    /// LP position as an Aptos object. Each add_liquidity mints a new one.
    /// Transferable (can be sent to multisig, held by resource accounts, etc).
    /// Burned on remove_liquidity.
    struct LpPosition has key {
        pool_addr: address,
        shares: u64,
        fee_debt_a: u128,              // lp_fee_per_share_a snapshot at last sync
        fee_debt_b: u128,
        delete_ref: DeleteRef,
        schema_version: u8,
        _reserved: vector<u8>,
    }

    /// Hook NFT. Two are minted per pool at creation.
    /// Slot 0 = treasury (soulbound), slot 1 = escrow/marketplace (transferable).
    struct HookNFT has key {
        pool_addr: address,
        slot: u8,
        schema_version: u8,
        _reserved: vector<u8>,
    }

    /// Flash loan receipt. Hot-potato: no drop/store/key abilities.
    /// Must be consumed via flash_repay in the same TX.
    struct FlashReceipt {
        pool_addr: address,
        metadata: Object<Metadata>,
        amount: u64,
        fee: u64,
        k_before: u256,
    }

    // ===== Events =====

    #[event]
    struct PoolCreated has drop, store {
        pool_addr: address,
        metadata_a: address,
        metadata_b: address,
        creator: address,
        amount_a: u64,
        amount_b: u64,
        initial_lp: u64,
        hook_nft_1: address,
        hook_nft_2: address,
        timestamp: u64,
    }

    #[event]
    struct Swapped has drop, store {
        pool_addr: address,
        swapper: address,
        amount_in: u64,
        amount_out: u64,
        a_to_b: bool,
        lp_fee: u64,
        hook_1_fee: u64,
        hook_2_fee: u64,
        timestamp: u64,
    }

    #[event]
    struct LiquidityAdded has drop, store {
        pool_addr: address,
        provider: address,
        position_addr: address,
        amount_a: u64,
        amount_b: u64,
        shares_minted: u64,
        timestamp: u64,
    }

    #[event]
    struct LiquidityRemoved has drop, store {
        pool_addr: address,
        provider: address,
        position_addr: address,
        amount_a: u64,
        amount_b: u64,
        fees_a: u64,
        fees_b: u64,
        shares_burned: u64,
        timestamp: u64,
    }

    #[event]
    struct LpFeesClaimed has drop, store {
        pool_addr: address,
        position_addr: address,
        claimer: address,
        fees_a: u64,
        fees_b: u64,
        timestamp: u64,
    }

    #[event]
    struct HookFeesClaimed has drop, store {
        pool_addr: address,
        nft_addr: address,
        slot: u8,
        claimer: address,
        fees_a: u64,
        fees_b: u64,
        timestamp: u64,
    }

    #[event]
    struct FlashBorrowed has drop, store {
        pool_addr: address,
        metadata: address,
        amount: u64,
        fee: u64,
        timestamp: u64,
    }

    #[event]
    struct FlashRepaid has drop, store {
        pool_addr: address,
        metadata: address,
        amount: u64,
        fee: u64,
        timestamp: u64,
    }

    // ===== Internal helpers =====

    /// Babylonian integer sqrt for initial LP share computation.
    fun sqrt(x: u128): u128 {
        if (x == 0) return 0;
        let z = (x + 1) / 2;
        let y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        };
        y
    }

    /// Accumulate TWAP contribution for the elapsed time since last update.
    /// Must be called BEFORE reserves mutate so the contribution reflects
    /// the pre-mutation reserve ratio.
    fun update_twap(pool: &mut Pool) {
        let now = timestamp::now_seconds();
        let dt = now - pool.twap_last_ts;
        if (dt > 0) {
            pool.twap_cumulative_a = pool.twap_cumulative_a + (pool.reserve_a as u128) * (dt as u128);
            pool.twap_cumulative_b = pool.twap_cumulative_b + (pool.reserve_b as u128) * (dt as u128);
            pool.twap_last_ts = now;
        }
    }

    /// Split `extra_fee` across the three accumulators and return (lp_portion,
    /// hook_1_portion, hook_2_portion) for event attribution. `a_side=true`
    /// means the fee is collected in metadata_a reserves, otherwise metadata_b.
    fun accrue_fee(
        pool: &mut Pool,
        total_fee: u64,
        extra_fee: u64,
        a_side: bool,
    ): (u64, u64, u64) {
        // Hook pot = extra_fee, split HOOK_SPLIT_PCT / (100 - HOOK_SPLIT_PCT).
        let hook_1_portion = extra_fee * HOOK_SPLIT_PCT / 100;
        let hook_2_portion = extra_fee - hook_1_portion;

        // LP portion = total_fee - extra_fee (remainder stays in reserves as
        // growth per the x*y=k wedge). Saturate to 0 on underflow (dust swap
        // regime where total_fee floored below extra_fee).
        let lp_portion = if (total_fee > extra_fee) { total_fee - extra_fee } else { 0 };

        // Accumulate hook pots (absolute).
        if (a_side) {
            pool.hook_1_fee_a = pool.hook_1_fee_a + hook_1_portion;
            pool.hook_2_fee_a = pool.hook_2_fee_a + hook_2_portion;
        } else {
            pool.hook_1_fee_b = pool.hook_1_fee_b + hook_1_portion;
            pool.hook_2_fee_b = pool.hook_2_fee_b + hook_2_portion;
        };

        // Accumulate LP per-share global (scaled).
        if (lp_portion > 0 && pool.lp_supply > 0) {
            let add = (lp_portion as u128) * SCALE / (pool.lp_supply as u128);
            if (a_side) {
                pool.lp_fee_per_share_a = pool.lp_fee_per_share_a + add;
            } else {
                pool.lp_fee_per_share_b = pool.lp_fee_per_share_b + add;
            }
        };

        (lp_portion, hook_1_portion, hook_2_portion)
    }

    /// Compute `(per_share_current - per_share_debt) * shares / SCALE` in u256
    /// to avoid overflow, return u64.
    fun pending_from_accumulator(
        per_share_current: u128,
        per_share_debt: u128,
        shares: u64,
    ): u64 {
        if (per_share_current <= per_share_debt) return 0;
        let delta = per_share_current - per_share_debt;
        let product = (delta as u256) * (shares as u256);
        let scaled = product / (SCALE as u256);
        (scaled as u64)
    }

    /// Mint a HookNFT at a deterministic named-object address under the pool.
    /// `soulbound = true` disables ungated transfer after the initial move.
    /// Returns the NFT object address.
    fun mint_hook_nft(
        pool_signer: &signer,
        pool_addr: address,
        slot: u8,
        initial_owner: address,
        soulbound: bool,
        seed: vector<u8>,
    ): address {
        let ctor = object::create_named_object(pool_signer, seed);
        let nft_signer = object::generate_signer(&ctor);
        let nft_addr = signer::address_of(&nft_signer);
        let transfer_ref = object::generate_transfer_ref(&ctor);

        move_to(&nft_signer, HookNFT {
            pool_addr,
            slot,
            schema_version: 1,
            _reserved: vector::empty(),
        });

        // Transfer to initial owner via linear ref.
        let linear = object::generate_linear_transfer_ref(&transfer_ref);
        object::transfer_with_ref(linear, initial_owner);

        if (soulbound) {
            object::disable_ungated_transfer(&transfer_ref);
        };

        nft_addr
    }

    /// Mint a fresh LpPosition object for `owner_addr` with the given shares
    /// and debt snapshot. Returns the Object<LpPosition> handle.
    fun mint_lp_position(
        owner_addr: address,
        pool_addr: address,
        shares: u64,
        initial_debt_a: u128,
        initial_debt_b: u128,
    ): Object<LpPosition> {
        let ctor = object::create_object(owner_addr);
        let pos_signer = object::generate_signer(&ctor);
        let delete_ref = object::generate_delete_ref(&ctor);

        move_to(&pos_signer, LpPosition {
            pool_addr,
            shares,
            fee_debt_a: initial_debt_a,
            fee_debt_b: initial_debt_b,
            delete_ref,
            schema_version: 1,
            _reserved: vector::empty(),
        });

        object::object_from_constructor_ref<LpPosition>(&ctor)
    }

    // ===== Pool Creation (friend-only) =====

    /// Atomic pool + hook NFTs + initial LP position creation. Called only by
    /// pool_factory::create_canonical_pool. The factory supplies the
    /// constructor_ref for the canonical pool address and pulls seeding
    /// tokens from the creator into its own primary store before calling.
    ///
    /// Returns (pool_addr, hook_nft_1_addr, hook_nft_2_addr, lp_position_object).
    public(friend) fun create_pool(
        factory_signer: &signer,
        factory_addr: address,
        treasury_addr: address,
        creator_addr: address,
        constructor_ref: &ConstructorRef,
        metadata_a: Object<Metadata>,
        metadata_b: Object<Metadata>,
        amount_a: u64,
        amount_b: u64,
    ): (address, address, address, Object<LpPosition>) {
        // Creator sets the initial reserve ratio freely via (amount_a,
        // amount_b). There is no raw-unit equality constraint — that would
        // force mispricing for pairs with different decimals (e.g., APT
        // 8-decimal vs USDC 6-decimal). First-depositor ratio manipulation
        // is prevented structurally: subsequent LPs use `add_liquidity`
        // which applies optimal-amount computation + `min_shares_out`
        // slippage floor. A creator setting a mispriced initial ratio
        // only hurts themselves (via arb loss on their own deposit)
        // without harming later LPs.
        assert!(amount_a > 0 && amount_b > 0, E_ZERO_AMOUNT);
        assert!(
            object::object_address(&metadata_a) != object::object_address(&metadata_b),
            E_SAME_TOKEN,
        );

        let pool_signer = object::generate_signer(constructor_ref);
        let pool_addr = signer::address_of(&pool_signer);
        let extend_ref = object::generate_extend_ref(constructor_ref);

        // Lock pool object transfer (pool is not tradable).
        let pool_transfer_ref = object::generate_transfer_ref(constructor_ref);
        object::disable_ungated_transfer(&pool_transfer_ref);

        // Move seeding tokens from factory primary store into pool primary store.
        let fa_a = primary_fungible_store::withdraw(factory_signer, metadata_a, amount_a);
        let fa_b = primary_fungible_store::withdraw(factory_signer, metadata_b, amount_b);
        primary_fungible_store::deposit(pool_addr, fa_a);
        primary_fungible_store::deposit(pool_addr, fa_b);

        // Compute initial LP shares: sqrt(a*b). Dead MINIMUM_LIQUIDITY shares
        // locked in the pool to prevent first-depositor attacks.
        let initial_lp_u128 = sqrt((amount_a as u128) * (amount_b as u128));
        assert!(initial_lp_u128 > (MINIMUM_LIQUIDITY as u128), E_INSUFFICIENT_LIQUIDITY);
        let initial_lp = (initial_lp_u128 as u64);
        let creator_shares = initial_lp - MINIMUM_LIQUIDITY;

        // Mint HookNFT #1 → treasury, soulbound.
        let hook_1_addr = mint_hook_nft(
            &pool_signer,
            pool_addr,
            0,
            treasury_addr,
            true,
            b"darbitex_hook_1",
        );

        // Mint HookNFT #2 → factory escrow, transferable.
        let hook_2_addr = mint_hook_nft(
            &pool_signer,
            pool_addr,
            1,
            factory_addr,
            false,
            b"darbitex_hook_2",
        );

        let now = timestamp::now_seconds();

        move_to(&pool_signer, Pool {
            metadata_a,
            metadata_b,
            extend_ref,
            hook_nft_1: hook_1_addr,
            hook_nft_2: hook_2_addr,
            schema_version: 1,

            reserve_a: amount_a,
            reserve_b: amount_b,
            lp_supply: initial_lp,

            lp_fee_per_share_a: 0,
            lp_fee_per_share_b: 0,

            hook_1_fee_a: 0, hook_1_fee_b: 0,
            hook_2_fee_a: 0, hook_2_fee_b: 0,

            locked: false,

            twap_cumulative_a: 0,
            twap_cumulative_b: 0,
            twap_last_ts: now,

            total_swaps: 0,
            total_volume_a: 0,
            total_volume_b: 0,

            _reserved: vector::empty(),
        });

        // Mint the creator's LpPosition. Initial debt = 0 because lp_fee_per_share
        // is 0 at creation time (no prior swaps).
        let position = mint_lp_position(creator_addr, pool_addr, creator_shares, 0, 0);
        let position_addr = object::object_address(&position);

        event::emit(PoolCreated {
            pool_addr,
            metadata_a: object::object_address(&metadata_a),
            metadata_b: object::object_address(&metadata_b),
            creator: creator_addr,
            amount_a,
            amount_b,
            initial_lp,
            hook_nft_1: hook_1_addr,
            hook_nft_2: hook_2_addr,
            timestamp: now,
        });

        event::emit(LiquidityAdded {
            pool_addr,
            provider: creator_addr,
            position_addr,
            amount_a,
            amount_b,
            shares_minted: creator_shares,
            timestamp: now,
        });

        (pool_addr, hook_1_addr, hook_2_addr, position)
    }

    // ===== Swap =====

    /// Composable swap primitive. Takes FungibleAsset and returns FungibleAsset.
    /// No `&signer` — authorization happens at the caller's FA withdraw. The
    /// `swapper` address is recorded in the Swapped event for attribution only.
    public fun swap(
        pool_addr: address,
        swapper: address,
        fa_in: FungibleAsset,
        min_out: u64,
    ): FungibleAsset acquires Pool {
        assert!(exists<Pool>(pool_addr), E_NO_POOL);
        let pool = borrow_global_mut<Pool>(pool_addr);
        assert!(!pool.locked, E_LOCKED);
        pool.locked = true;

        update_twap(pool);

        let in_metadata = fungible_asset::asset_metadata(&fa_in);
        let amount_in = fungible_asset::amount(&fa_in);
        assert!(amount_in > 0, E_ZERO_AMOUNT);

        let a_to_b =
            if (object::object_address(&in_metadata) == object::object_address(&pool.metadata_a)) {
                true
            } else {
                assert!(
                    object::object_address(&in_metadata) == object::object_address(&pool.metadata_b),
                    E_WRONG_TOKEN,
                );
                false
            };

        let (reserve_in, reserve_out) = if (a_to_b) {
            (pool.reserve_a, pool.reserve_b)
        } else {
            (pool.reserve_b, pool.reserve_a)
        };

        // x*y=k swap math with SWAP_FEE_BPS wedge. All intermediate products
        // computed in u256 to avoid the u128 overflow risk flagged by audit
        // MEDIUM-1 (Claude + DeepSeek + Gemini): for pools with
        // reserve_out near u64::MAX and amount_in near u64::MAX, the u128
        // product `amount_in × 9999 × reserve_out` can exceed 2^128. The
        // final result is bounded by reserve_out ≤ u64::MAX so the cast
        // back to u64 is safe.
        let amount_in_after_fee = (amount_in as u256) * ((BPS_DENOM - SWAP_FEE_BPS) as u256);
        let numerator = amount_in_after_fee * (reserve_out as u256);
        let denominator = (reserve_in as u256) * (BPS_DENOM as u256) + amount_in_after_fee;
        let amount_out = ((numerator / denominator) as u64);

        assert!(amount_out >= min_out, E_SLIPPAGE);
        assert!(amount_out < reserve_out, E_INSUFFICIENT_LIQUIDITY);

        // Compute fees. total_fee = amount_in * SWAP_FEE_BPS / BPS_DENOM.
        // extra_fee = amount_in / EXTRA_FEE_DENOM (hook pot portion), floored
        // up to 1 so dust swaps still produce hook revenue.
        let total_fee = amount_in * SWAP_FEE_BPS / BPS_DENOM;
        let extra_fee_raw = amount_in / EXTRA_FEE_DENOM;
        let extra_fee = if (extra_fee_raw == 0 && amount_in > 0) { 1 } else { extra_fee_raw };

        let (lp_fee, hook_1_fee, hook_2_fee) = accrue_fee(pool, total_fee, extra_fee, a_to_b);

        // Total amount pulled out of reserves = what accrue_fee credited
        // to the hook buckets plus what it credited to the lp accumulator.
        // This equals max(total_fee, extra_fee) in effect: for normal swaps
        // it's total_fee, for dust swaps where total_fee floors to 0 it's
        // extra_fee (the floor-protected hook portion) with lp_fee == 0.
        // Keeping reserves and accumulators in lockstep fixes audit HIGH-1
        // (self-audit 2026-04-12) — reserves now track principal only.
        let reserve_fee = extra_fee + lp_fee;

        if (a_to_b) {
            pool.reserve_a = pool.reserve_a + amount_in - reserve_fee;
            pool.reserve_b = pool.reserve_b - amount_out;
        } else {
            pool.reserve_a = pool.reserve_a - amount_out;
            pool.reserve_b = pool.reserve_b + amount_in - reserve_fee;
        };

        pool.total_swaps = pool.total_swaps + 1;
        if (a_to_b) {
            pool.total_volume_a = pool.total_volume_a + (amount_in as u128);
        } else {
            pool.total_volume_b = pool.total_volume_b + (amount_in as u128);
        };

        // Settle FA: deposit incoming into pool store, withdraw outgoing.
        primary_fungible_store::deposit(pool_addr, fa_in);
        let pool_signer = object::generate_signer_for_extending(&pool.extend_ref);
        let out_metadata = if (a_to_b) { pool.metadata_b } else { pool.metadata_a };
        let fa_out = primary_fungible_store::withdraw(&pool_signer, out_metadata, amount_out);

        pool.locked = false;

        event::emit(Swapped {
            pool_addr,
            swapper,
            amount_in,
            amount_out,
            a_to_b,
            lp_fee,
            hook_1_fee,
            hook_2_fee,
            timestamp: timestamp::now_seconds(),
        });

        fa_out
    }

    // ===== Liquidity =====

    /// Add liquidity to an existing pool. Mints a new LpPosition NFT to
    /// the provider; each add_liquidity call mints a separate position
    /// (no merging).
    ///
    /// `amount_a_desired` and `amount_b_desired` are the MAXIMUM amounts
    /// the caller is willing to deposit on each side. The function picks
    /// the Uniswap V2-router-style optimal pair: the side whose desired
    /// amount more tightly matches the current reserve ratio is used in
    /// full, and the other side uses only the proportional amount. The
    /// unused buffer on the "loose" side stays in the caller's wallet.
    /// This prevents the silent buffer donation bug from round 2 audit
    /// HIGH-1 (Gemini).
    ///
    /// `min_shares_out` is the slippage floor on minted shares. Aborts
    /// with `E_SLIPPAGE` if fewer shares would be minted. Callers that
    /// do not care about exact share counts can pass 0.
    public fun add_liquidity(
        provider: &signer,
        pool_addr: address,
        amount_a_desired: u64,
        amount_b_desired: u64,
        min_shares_out: u64,
    ): Object<LpPosition> acquires Pool {
        assert!(exists<Pool>(pool_addr), E_NO_POOL);
        assert!(amount_a_desired > 0 && amount_b_desired > 0, E_ZERO_AMOUNT);

        let pool = borrow_global_mut<Pool>(pool_addr);
        assert!(!pool.locked, E_LOCKED);

        update_twap(pool);

        // Uniswap V2 router-style optimal amount computation. Given the
        // current reserve ratio (reserve_a : reserve_b), figure out which
        // of the two desired amounts is the tight side and use the other
        // side's proportional amount. The unused buffer stays in the
        // caller's wallet — we never withdraw more than the optimal pair.
        let amount_b_optimal = (
            ((amount_a_desired as u256) * (pool.reserve_b as u256)
                / (pool.reserve_a as u256)) as u64
        );
        let (amount_a, amount_b) = if (amount_b_optimal <= amount_b_desired) {
            // amount_a is the tight side: use it in full, use only
            // amount_b_optimal of the b-side, leaving
            // (amount_b_desired - amount_b_optimal) in the caller's wallet.
            (amount_a_desired, amount_b_optimal)
        } else {
            // amount_b is the tight side: compute the optimal a to match
            // amount_b_desired at the current ratio. This value is
            // guaranteed ≤ amount_a_desired by the ratio constraint.
            let amount_a_optimal = (
                ((amount_b_desired as u256) * (pool.reserve_a as u256)
                    / (pool.reserve_b as u256)) as u64
            );
            // Sanity assert — mathematically this MUST hold given the
            // if-branch condition (`amount_b_optimal > amount_b_desired`
            // implies `amount_a_optimal < amount_a_desired` via the x*y=k
            // invariant). Kimi K2 R3 audit correctly observed this is
            // unreachable under normal operation. We keep the check as
            // defense-in-depth against compiler/framework bugs,
            // catastrophic u256→u64 rounding cliff cases, or future
            // refactors that might violate the invariant. Zero cost.
            assert!(amount_a_optimal <= amount_a_desired, E_DISPROPORTIONAL);
            (amount_a_optimal, amount_b_desired)
        };

        assert!(amount_a > 0 && amount_b > 0, E_ZERO_AMOUNT);

        // Compute shares minted proportionally. With the optimal pair
        // computed above, lp_a and lp_b are equal within integer
        // rounding; we take min as a defensive measure.
        let lp_a = (
            ((amount_a as u256) * (pool.lp_supply as u256)
                / (pool.reserve_a as u256)) as u64
        );
        let lp_b = (
            ((amount_b as u256) * (pool.lp_supply as u256)
                / (pool.reserve_b as u256)) as u64
        );
        let shares = if (lp_a < lp_b) { lp_a } else { lp_b };
        assert!(shares > 0, E_ZERO_AMOUNT);
        assert!(shares >= min_shares_out, E_SLIPPAGE);

        let provider_addr = signer::address_of(provider);

        // Pull ONLY the optimal amounts from provider. The buffer stays
        // in their wallet.
        let fa_a = primary_fungible_store::withdraw(provider, pool.metadata_a, amount_a);
        let fa_b = primary_fungible_store::withdraw(provider, pool.metadata_b, amount_b);
        primary_fungible_store::deposit(pool_addr, fa_a);
        primary_fungible_store::deposit(pool_addr, fa_b);

        pool.reserve_a = pool.reserve_a + amount_a;
        pool.reserve_b = pool.reserve_b + amount_b;
        pool.lp_supply = pool.lp_supply + shares;

        // Snapshot the current per_share as this position's debt so the
        // holder only earns on swaps after the deposit moment.
        let debt_a = pool.lp_fee_per_share_a;
        let debt_b = pool.lp_fee_per_share_b;

        let position = mint_lp_position(provider_addr, pool_addr, shares, debt_a, debt_b);
        let position_addr = object::object_address(&position);

        event::emit(LiquidityAdded {
            pool_addr,
            provider: provider_addr,
            position_addr,
            amount_a,  // actual amount used, not desired
            amount_b,  // actual amount used, not desired
            shares_minted: shares,
            timestamp: timestamp::now_seconds(),
        });

        position
    }

    /// Composable remove_liquidity. Burns the LpPosition and returns the
    /// proportional reserves PLUS any accumulated LP fees in one shot.
    ///
    /// `min_amount_a` and `min_amount_b` are slippage floors on the
    /// proportional reserve payout (not including fee claims). A sandwich
    /// attacker can shift the reserve ratio between TX submission and
    /// execution, so LPs should specify a minimum they are willing to
    /// accept. Callers who do not care can pass 0. Added per audit
    /// round-2 MEDIUM-1 (fresh Claude Opus 4.6 audit).
    public fun remove_liquidity(
        provider: &signer,
        position: Object<LpPosition>,
        min_amount_a: u64,
        min_amount_b: u64,
    ): (FungibleAsset, FungibleAsset) acquires Pool, LpPosition {
        let provider_addr = signer::address_of(provider);
        assert!(object::owner(position) == provider_addr, E_NOT_OWNER);

        let position_addr = object::object_address(&position);
        assert!(exists<LpPosition>(position_addr), E_NO_POSITION);

        let LpPosition {
            pool_addr,
            shares,
            fee_debt_a,
            fee_debt_b,
            delete_ref,
            schema_version: _,
            _reserved: _,
        } = move_from<LpPosition>(position_addr);

        assert!(exists<Pool>(pool_addr), E_NO_POOL);
        let pool = borrow_global_mut<Pool>(pool_addr);
        assert!(!pool.locked, E_LOCKED);
        assert!(shares > 0, E_ZERO_AMOUNT);
        assert!(pool.lp_supply >= shares, E_INSUFFICIENT_LP);

        update_twap(pool);

        // Compute accumulated LP fees for this position.
        let claim_a = pending_from_accumulator(pool.lp_fee_per_share_a, fee_debt_a, shares);
        let claim_b = pending_from_accumulator(pool.lp_fee_per_share_b, fee_debt_b, shares);

        // Proportional reserve payout. u256 intermediate (audit MEDIUM-2).
        let amount_a = (
            ((shares as u256) * (pool.reserve_a as u256) / (pool.lp_supply as u256)) as u64
        );
        let amount_b = (
            ((shares as u256) * (pool.reserve_b as u256) / (pool.lp_supply as u256)) as u64
        );

        // Slippage protection on principal withdrawal (not fees). Sandwich
        // attacks on active pools can shift reserve ratios; this check
        // lets LPs bail if the ratio moved against them.
        assert!(amount_a >= min_amount_a, E_SLIPPAGE);
        assert!(amount_b >= min_amount_b, E_SLIPPAGE);

        pool.lp_supply = pool.lp_supply - shares;
        assert!(pool.lp_supply >= MINIMUM_LIQUIDITY, E_INSUFFICIENT_LIQUIDITY);
        pool.reserve_a = pool.reserve_a - amount_a;
        pool.reserve_b = pool.reserve_b - amount_b;

        // Withdraw reserves + fees from pool store.
        let pool_signer = object::generate_signer_for_extending(&pool.extend_ref);
        let total_a = amount_a + claim_a;
        let total_b = amount_b + claim_b;
        let fa_a = primary_fungible_store::withdraw(&pool_signer, pool.metadata_a, total_a);
        let fa_b = primary_fungible_store::withdraw(&pool_signer, pool.metadata_b, total_b);

        event::emit(LiquidityRemoved {
            pool_addr,
            provider: provider_addr,
            position_addr,
            amount_a,
            amount_b,
            fees_a: claim_a,
            fees_b: claim_b,
            shares_burned: shares,
            timestamp: timestamp::now_seconds(),
        });

        // Delete the position object.
        object::delete(delete_ref);

        (fa_a, fa_b)
    }

    // ===== Fee Claims =====

    /// Harvest accumulated LP fees without touching the position's shares.
    /// Resets the position's debt snapshot to current per_share so future
    /// accumulation starts from zero.
    ///
    /// Defense-in-depth: sets `pool.locked = true` during execution even
    /// though Aptos FA operations don't currently have callback hooks that
    /// could re-enter. If a future framework update adds FA dispatch
    /// hooks, this function is already safe. Per audit round-2 MEDIUM-2
    /// (fresh Claude Opus 4.6 audit).
    public fun claim_lp_fees(
        provider: &signer,
        position: Object<LpPosition>,
    ): (FungibleAsset, FungibleAsset) acquires Pool, LpPosition {
        let provider_addr = signer::address_of(provider);
        assert!(object::owner(position) == provider_addr, E_NOT_OWNER);

        let position_addr = object::object_address(&position);
        assert!(exists<LpPosition>(position_addr), E_NO_POSITION);

        let pos = borrow_global_mut<LpPosition>(position_addr);
        assert!(exists<Pool>(pos.pool_addr), E_NO_POOL);

        let pool = borrow_global_mut<Pool>(pos.pool_addr);
        assert!(!pool.locked, E_LOCKED);
        pool.locked = true;

        update_twap(pool);

        let claim_a = pending_from_accumulator(pool.lp_fee_per_share_a, pos.fee_debt_a, pos.shares);
        let claim_b = pending_from_accumulator(pool.lp_fee_per_share_b, pos.fee_debt_b, pos.shares);

        pos.fee_debt_a = pool.lp_fee_per_share_a;
        pos.fee_debt_b = pool.lp_fee_per_share_b;

        let pool_signer = object::generate_signer_for_extending(&pool.extend_ref);
        let fa_a = if (claim_a > 0) {
            primary_fungible_store::withdraw(&pool_signer, pool.metadata_a, claim_a)
        } else {
            fungible_asset::zero(pool.metadata_a)
        };
        let fa_b = if (claim_b > 0) {
            primary_fungible_store::withdraw(&pool_signer, pool.metadata_b, claim_b)
        } else {
            fungible_asset::zero(pool.metadata_b)
        };

        pool.locked = false;

        event::emit(LpFeesClaimed {
            pool_addr: pos.pool_addr,
            position_addr,
            claimer: provider_addr,
            fees_a: claim_a,
            fees_b: claim_b,
            timestamp: timestamp::now_seconds(),
        });

        (fa_a, fa_b)
    }

    /// Harvest hook fees for whichever slot the NFT owner holds. Resets the
    /// absolute bucket for that slot. Works for both treasury slot 0 and
    /// escrow/market slot 1.
    ///
    /// Defense-in-depth: sets `pool.locked = true` during execution. Per
    /// audit round-2 MEDIUM-2 (fresh Claude Opus 4.6 audit).
    public fun claim_hook_fees(
        caller: &signer,
        nft: Object<HookNFT>,
    ): (FungibleAsset, FungibleAsset) acquires Pool, HookNFT {
        let caller_addr = signer::address_of(caller);
        assert!(object::owner(nft) == caller_addr, E_NOT_OWNER);

        let nft_addr = object::object_address(&nft);
        assert!(exists<HookNFT>(nft_addr), E_NO_HOOK_NFT);

        let nft_ref = borrow_global<HookNFT>(nft_addr);
        let pool_addr = nft_ref.pool_addr;
        let slot = nft_ref.slot;

        assert!(exists<Pool>(pool_addr), E_NO_POOL);
        let pool = borrow_global_mut<Pool>(pool_addr);
        assert!(!pool.locked, E_LOCKED);
        pool.locked = true;

        let (fees_a, fees_b) = if (slot == 0) {
            let a = pool.hook_1_fee_a;
            let b = pool.hook_1_fee_b;
            pool.hook_1_fee_a = 0;
            pool.hook_1_fee_b = 0;
            (a, b)
        } else {
            let a = pool.hook_2_fee_a;
            let b = pool.hook_2_fee_b;
            pool.hook_2_fee_a = 0;
            pool.hook_2_fee_b = 0;
            (a, b)
        };

        let pool_signer = object::generate_signer_for_extending(&pool.extend_ref);
        let fa_a = if (fees_a > 0) {
            primary_fungible_store::withdraw(&pool_signer, pool.metadata_a, fees_a)
        } else {
            fungible_asset::zero(pool.metadata_a)
        };
        let fa_b = if (fees_b > 0) {
            primary_fungible_store::withdraw(&pool_signer, pool.metadata_b, fees_b)
        } else {
            fungible_asset::zero(pool.metadata_b)
        };

        pool.locked = false;

        event::emit(HookFeesClaimed {
            pool_addr,
            nft_addr,
            slot,
            claimer: caller_addr,
            fees_a,
            fees_b,
            timestamp: timestamp::now_seconds(),
        });

        (fa_a, fa_b)
    }

    // ===== Flash loan =====

    /// Flash borrow up to `amount` of `metadata` from the pool. Returns the
    /// borrowed FA and a FlashReceipt hot-potato that must be consumed via
    /// flash_repay in the same TX or the TX aborts. Pool is locked during
    /// the borrow span — swap/LP/flash ops abort until repay.
    public fun flash_borrow(
        pool_addr: address,
        metadata: Object<Metadata>,
        amount: u64,
    ): (FungibleAsset, FlashReceipt) acquires Pool {
        assert!(exists<Pool>(pool_addr), E_NO_POOL);
        assert!(amount > 0, E_ZERO_AMOUNT);

        let pool = borrow_global_mut<Pool>(pool_addr);
        assert!(!pool.locked, E_LOCKED);
        pool.locked = true;

        let metadata_addr = object::object_address(&metadata);
        let is_a = metadata_addr == object::object_address(&pool.metadata_a);
        assert!(is_a || metadata_addr == object::object_address(&pool.metadata_b), E_WRONG_TOKEN);

        let (reserve_in, reserve_out) = if (is_a) {
            (pool.reserve_a, pool.reserve_b)
        } else {
            (pool.reserve_b, pool.reserve_a)
        };
        assert!(amount < reserve_in, E_INSUFFICIENT_LIQUIDITY);

        // Record k_before in u256 to make repay-time invariant check safe.
        let k_before = (reserve_in as u256) * (reserve_out as u256);

        // Fee on borrowed amount, minimum 1 so dust borrows still pay.
        let fee_raw = amount * FLASH_FEE_BPS / BPS_DENOM;
        let fee = if (fee_raw == 0) { 1 } else { fee_raw };

        let pool_signer = object::generate_signer_for_extending(&pool.extend_ref);
        let fa_out = primary_fungible_store::withdraw(&pool_signer, metadata, amount);

        event::emit(FlashBorrowed {
            pool_addr,
            metadata: metadata_addr,
            amount,
            fee,
            timestamp: timestamp::now_seconds(),
        });

        let receipt = FlashReceipt {
            pool_addr,
            metadata,
            amount,
            fee,
            k_before,
        };

        (fa_out, receipt)
    }

    /// Repay the flash borrow with the original principal plus fee. Consumes
    /// the hot-potato receipt. Asserts the k-invariant holds (reserves × after
    /// repay must not fall below pre-borrow product). Releases the lock.
    ///
    /// Reserve accounting note: `flash_borrow` does NOT decrement `reserve_a`
    /// or `reserve_b` when the borrowed amount leaves the store, because the
    /// `locked` flag guarantees no one reads reserves during the borrow span.
    /// Therefore `flash_repay` must NOT add the principal back to reserves —
    /// doing so would inflate reserves by `amount`, breaking solvency. Only
    /// the fee is routed (to hook buckets via accrue_fee and implicitly to
    /// LP via the accumulator). Fixed per audit HIGH-1 (self-audit and
    /// external auditor 2026-04-12).
    public fun flash_repay(
        pool_addr: address,
        fa_in: FungibleAsset,
        receipt: FlashReceipt,
    ) acquires Pool {
        let FlashReceipt { pool_addr: r_pool, metadata, amount, fee, k_before } = receipt;
        assert!(pool_addr == r_pool, E_WRONG_POOL);

        let repay_total = amount + fee;
        // Strict equality prevents silent donation of excess. Per audit
        // LOW-2 (external 2026-04-12): a `>=` check would let clumsy
        // callers pass fa_in with more than repay_total; the excess would
        // be deposited into the store as untracked surplus ("trapped").
        // Forcing exact equality turns this footgun into an abort.
        assert!(fungible_asset::amount(&fa_in) == repay_total, E_INSUFFICIENT_LIQUIDITY);
        assert!(
            object::object_address(&fungible_asset::asset_metadata(&fa_in)) == object::object_address(&metadata),
            E_WRONG_TOKEN,
        );

        let pool = borrow_global_mut<Pool>(pool_addr);

        // Deposit repayment into pool store. Store now holds (pre_borrow + fee)
        // of the borrowed-side metadata, because the principal that was
        // withdrawn in flash_borrow comes back in fa_in alongside the fee.
        primary_fungible_store::deposit(pool_addr, fa_in);

        // Route fee through accrue_fee: hook portion to absolute buckets, LP
        // portion to lp_fee_per_share accumulator. Nothing is added to
        // reserves — they were never decremented during flash_borrow.
        let is_a = object::object_address(&metadata) == object::object_address(&pool.metadata_a);
        let extra_fee_raw = amount / EXTRA_FEE_DENOM;
        let extra_fee = if (extra_fee_raw == 0) { 1 } else { extra_fee_raw };
        // Cap extra_fee to the actual fee amount (in case fee < extra_fee_raw
        // for very small borrows).
        let extra_fee = if (extra_fee > fee) { fee } else { extra_fee };
        let (_lp, _h1, _h2) = accrue_fee(pool, fee, extra_fee, is_a);

        // k-invariant assertion: post-repay reserves product must be >= the
        // pre-borrow snapshot. With the reserve-unchanged fix above, equality
        // is the expected case (flash loan is economically neutral to k).
        // This check remains as a safety net in case a future refactor
        // reintroduces reserve mutations on the flash path.
        let k_after = (pool.reserve_a as u256) * (pool.reserve_b as u256);
        assert!(k_after >= k_before, E_K_VIOLATED);

        pool.locked = false;

        event::emit(FlashRepaid {
            pool_addr,
            metadata: object::object_address(&metadata),
            amount,
            fee,
            timestamp: timestamp::now_seconds(),
        });
    }

    // ===== Entry wrappers (user-facing convenience) =====

    /// Entry variant of add_liquidity. Position NFT is minted to provider
    /// address as part of create_object; no explicit transfer needed.
    /// `min_shares_out` is the slippage floor — pass 0 for no protection.
    public entry fun add_liquidity_entry(
        provider: &signer,
        pool_addr: address,
        amount_a: u64,
        amount_b: u64,
        min_shares_out: u64,
    ) acquires Pool {
        let _ = add_liquidity(provider, pool_addr, amount_a, amount_b, min_shares_out);
    }

    /// Entry variant of remove_liquidity. Deposits both returned FAs back to
    /// provider's primary store. `min_amount_a` / `min_amount_b` are
    /// slippage floors — pass 0 for no protection.
    public entry fun remove_liquidity_entry(
        provider: &signer,
        position: Object<LpPosition>,
        min_amount_a: u64,
        min_amount_b: u64,
    ) acquires Pool, LpPosition {
        let provider_addr = signer::address_of(provider);
        let (fa_a, fa_b) = remove_liquidity(provider, position, min_amount_a, min_amount_b);
        primary_fungible_store::deposit(provider_addr, fa_a);
        primary_fungible_store::deposit(provider_addr, fa_b);
    }

    /// Entry variant of claim_lp_fees.
    public entry fun claim_lp_fees_entry(
        provider: &signer,
        position: Object<LpPosition>,
    ) acquires Pool, LpPosition {
        let provider_addr = signer::address_of(provider);
        let (fa_a, fa_b) = claim_lp_fees(provider, position);
        primary_fungible_store::deposit(provider_addr, fa_a);
        primary_fungible_store::deposit(provider_addr, fa_b);
    }

    /// Entry variant of claim_hook_fees.
    public entry fun claim_hook_fees_entry(
        caller: &signer,
        nft: Object<HookNFT>,
    ) acquires Pool, HookNFT {
        let caller_addr = signer::address_of(caller);
        let (fa_a, fa_b) = claim_hook_fees(caller, nft);
        primary_fungible_store::deposit(caller_addr, fa_a);
        primary_fungible_store::deposit(caller_addr, fa_b);
    }

    // ===== Views =====

    #[view]
    public fun pool_exists(pool_addr: address): bool {
        exists<Pool>(pool_addr)
    }

    #[view]
    public fun reserves(pool_addr: address): (u64, u64) acquires Pool {
        let p = borrow_global<Pool>(pool_addr);
        (p.reserve_a, p.reserve_b)
    }

    #[view]
    public fun pool_tokens(pool_addr: address): (Object<Metadata>, Object<Metadata>) acquires Pool {
        let p = borrow_global<Pool>(pool_addr);
        (p.metadata_a, p.metadata_b)
    }

    #[view]
    public fun hook_nft_addresses(pool_addr: address): (address, address) acquires Pool {
        let p = borrow_global<Pool>(pool_addr);
        (p.hook_nft_1, p.hook_nft_2)
    }

    #[view]
    public fun lp_supply(pool_addr: address): u64 acquires Pool {
        borrow_global<Pool>(pool_addr).lp_supply
    }

    #[view]
    public fun lp_fee_per_share(pool_addr: address): (u128, u128) acquires Pool {
        let p = borrow_global<Pool>(pool_addr);
        (p.lp_fee_per_share_a, p.lp_fee_per_share_b)
    }

    #[view]
    public fun hook_fee_buckets(pool_addr: address): (u64, u64, u64, u64) acquires Pool {
        let p = borrow_global<Pool>(pool_addr);
        (p.hook_1_fee_a, p.hook_1_fee_b, p.hook_2_fee_a, p.hook_2_fee_b)
    }

    #[view]
    public fun twap_cumulative(pool_addr: address): (u128, u128, u64) acquires Pool {
        let p = borrow_global<Pool>(pool_addr);
        (p.twap_cumulative_a, p.twap_cumulative_b, p.twap_last_ts)
    }

    #[view]
    public fun total_stats(pool_addr: address): (u64, u128, u128) acquires Pool {
        let p = borrow_global<Pool>(pool_addr);
        (p.total_swaps, p.total_volume_a, p.total_volume_b)
    }

    #[view]
    public fun get_amount_out(
        pool_addr: address,
        amount_in: u64,
        a_to_b: bool,
    ): u64 acquires Pool {
        let p = borrow_global<Pool>(pool_addr);
        let (reserve_in, reserve_out) = if (a_to_b) {
            (p.reserve_a, p.reserve_b)
        } else {
            (p.reserve_b, p.reserve_a)
        };
        // u256 intermediate to match the swap path and avoid overflow on
        // adversarial reserves (audit MEDIUM-1).
        let amount_in_after_fee = (amount_in as u256) * ((BPS_DENOM - SWAP_FEE_BPS) as u256);
        let numerator = amount_in_after_fee * (reserve_out as u256);
        let denominator = (reserve_in as u256) * (BPS_DENOM as u256) + amount_in_after_fee;
        ((numerator / denominator) as u64)
    }

    #[view]
    public fun position_info(position_addr: address): (address, u64, u128, u128) acquires LpPosition {
        let p = borrow_global<LpPosition>(position_addr);
        (p.pool_addr, p.shares, p.fee_debt_a, p.fee_debt_b)
    }

    #[view]
    public fun pending_lp_fees(position_addr: address): (u64, u64) acquires LpPosition, Pool {
        let pos = borrow_global<LpPosition>(position_addr);
        let pool = borrow_global<Pool>(pos.pool_addr);
        let a = pending_from_accumulator(pool.lp_fee_per_share_a, pos.fee_debt_a, pos.shares);
        let b = pending_from_accumulator(pool.lp_fee_per_share_b, pos.fee_debt_b, pos.shares);
        (a, b)
    }

    #[view]
    public fun hook_nft_info(nft_addr: address): (address, u8) acquires HookNFT {
        let n = borrow_global<HookNFT>(nft_addr);
        (n.pool_addr, n.slot)
    }
}
