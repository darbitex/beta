/// Darbitex Beta — multi-hop router.
///
/// Raw execution primitive on top of `pool::swap`. Exposes both a
/// composable layer (public fun, FungibleAsset in/out) that satellites
/// compose via cross-package import, and a user-facing entry layer with
/// deadline enforcement + primary_fungible_store integration.
///
/// No wrapped/plain distinction — every Beta pool is uniform, every swap
/// routes through `pool::swap`. No discovery logic here; meta_router is
/// a future satellite package that will delegate to this router.

module darbitex::router {
    use std::signer;
    use aptos_framework::object::Object;
    use aptos_framework::fungible_asset::{FungibleAsset, Metadata};
    use aptos_framework::primary_fungible_store;
    use aptos_framework::timestamp;

    use darbitex::pool;

    // ===== Errors =====

    const E_DEADLINE: u64 = 1;
    const E_SAME_POOL: u64 = 2;
    const E_ZERO_AMOUNT: u64 = 3;

    // ===== Internal =====

    fun assert_deadline(deadline: u64) {
        assert!(timestamp::now_seconds() < deadline, E_DEADLINE);
    }

    // =========================================================
    //                 COMPOSABLE PRIMITIVES
    //       (public fun, FungibleAsset in/out, no &signer)
    //
    // External satellites compose these directly. They never touch the
    // user's primary_fungible_store — that's the entry layer's job.
    // =========================================================

    /// Single-hop execution. Wraps `pool::swap` with no additional logic
    /// beyond the type. Exists so the composability contract stays
    /// symmetric with the multi-hop variants.
    public fun swap_composable(
        pool_addr: address,
        swapper: address,
        fa_in: FungibleAsset,
        min_out: u64,
    ): FungibleAsset {
        pool::swap(pool_addr, swapper, fa_in, min_out)
    }

    /// 2-hop chained swap. Intermediate hop has min_out = 0 (slippage
    /// only checked on the final hop). Pools must be distinct.
    public fun swap_2hop_composable(
        pool1: address,
        pool2: address,
        swapper: address,
        fa_in: FungibleAsset,
        min_out: u64,
    ): FungibleAsset {
        assert!(pool1 != pool2, E_SAME_POOL);
        let fa_mid = pool::swap(pool1, swapper, fa_in, 0);
        pool::swap(pool2, swapper, fa_mid, min_out)
    }

    /// 3-hop chained swap. All three pools must be distinct from each
    /// other. Only the final hop enforces slippage.
    public fun swap_3hop_composable(
        pool1: address,
        pool2: address,
        pool3: address,
        swapper: address,
        fa_in: FungibleAsset,
        min_out: u64,
    ): FungibleAsset {
        assert!(pool1 != pool2, E_SAME_POOL);
        assert!(pool2 != pool3, E_SAME_POOL);
        assert!(pool1 != pool3, E_SAME_POOL);
        let fa_1 = pool::swap(pool1, swapper, fa_in, 0);
        let fa_2 = pool::swap(pool2, swapper, fa_1, 0);
        pool::swap(pool3, swapper, fa_2, min_out)
    }

    // =========================================================
    //                 ENTRY WRAPPERS
    //      (public entry fun, &signer, deadline + store)
    //
    // User-facing convenience. Pulls FA from user's primary store,
    // routes through the composable primitive, deposits result back.
    // =========================================================

    /// Single-hop swap with deadline and store integration.
    public entry fun swap_with_deadline(
        swapper: &signer,
        pool_addr: address,
        metadata_in: Object<Metadata>,
        amount_in: u64,
        min_out: u64,
        deadline: u64,
    ) {
        assert_deadline(deadline);
        assert!(amount_in > 0, E_ZERO_AMOUNT);
        let addr = signer::address_of(swapper);
        let fa_in = primary_fungible_store::withdraw(swapper, metadata_in, amount_in);
        let fa_out = swap_composable(pool_addr, addr, fa_in, min_out);
        primary_fungible_store::deposit(addr, fa_out);
    }

    /// 2-hop swap with deadline and store integration.
    public entry fun swap_2hop(
        swapper: &signer,
        pool1: address,
        pool2: address,
        metadata_in: Object<Metadata>,
        amount_in: u64,
        min_out: u64,
        deadline: u64,
    ) {
        assert_deadline(deadline);
        assert!(amount_in > 0, E_ZERO_AMOUNT);
        let addr = signer::address_of(swapper);
        let fa_in = primary_fungible_store::withdraw(swapper, metadata_in, amount_in);
        let fa_out = swap_2hop_composable(pool1, pool2, addr, fa_in, min_out);
        primary_fungible_store::deposit(addr, fa_out);
    }

    /// 3-hop swap with deadline and store integration.
    public entry fun swap_3hop(
        swapper: &signer,
        pool1: address,
        pool2: address,
        pool3: address,
        metadata_in: Object<Metadata>,
        amount_in: u64,
        min_out: u64,
        deadline: u64,
    ) {
        assert_deadline(deadline);
        assert!(amount_in > 0, E_ZERO_AMOUNT);
        let addr = signer::address_of(swapper);
        let fa_in = primary_fungible_store::withdraw(swapper, metadata_in, amount_in);
        let fa_out = swap_3hop_composable(pool1, pool2, pool3, addr, fa_in, min_out);
        primary_fungible_store::deposit(addr, fa_out);
    }
}
