module 0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387::event {
    use 0x1::account;
    use 0x1::event;
    use 0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387::price_feed;
    friend 0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387::pyth;
    struct PriceFeedUpdate has drop, store {
        price_feed: price_feed::PriceFeed,
        timestamp: u64,
    }
    struct PriceFeedUpdateHandle has store, key {
        event: event::EventHandle<PriceFeedUpdate>,
    }
    friend fun emit_price_feed_update(p0: price_feed::PriceFeed, p1: u64)
        acquires PriceFeedUpdateHandle
    {
        let _v0 = &mut borrow_global_mut<PriceFeedUpdateHandle>(@0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387).event;
        let _v1 = PriceFeedUpdate{price_feed: p0, timestamp: p1};
        event::emit_event<PriceFeedUpdate>(_v0, _v1);
    }
    friend fun init(p0: &signer) {
        let _v0 = PriceFeedUpdateHandle{event: account::new_event_handle<PriceFeedUpdate>(p0)};
        move_to<PriceFeedUpdateHandle>(p0, _v0);
    }
}
