module 0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387::price_info {
    use 0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387::price_feed;
    struct PriceInfo has copy, drop, store {
        attestation_time: u64,
        arrival_time: u64,
        price_feed: price_feed::PriceFeed,
    }
    public fun get_arrival_time(p0: &PriceInfo): u64 {
        *&p0.arrival_time
    }
    public fun get_attestation_time(p0: &PriceInfo): u64 {
        *&p0.attestation_time
    }
    public fun get_price_feed(p0: &PriceInfo): &price_feed::PriceFeed {
        &p0.price_feed
    }
    public fun new(p0: u64, p1: u64, p2: price_feed::PriceFeed): PriceInfo {
        PriceInfo{attestation_time: p0, arrival_time: p1, price_feed: p2}
    }
}
