module 0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387::price_feed {
    use 0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387::price;
    use 0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387::price_identifier;
    struct PriceFeed has copy, drop, store {
        price_identifier: price_identifier::PriceIdentifier,
        price: price::Price,
        ema_price: price::Price,
    }
    public fun get_ema_price(p0: &PriceFeed): price::Price {
        *&p0.ema_price
    }
    public fun get_price(p0: &PriceFeed): price::Price {
        *&p0.price
    }
    public fun get_price_identifier(p0: &PriceFeed): &price_identifier::PriceIdentifier {
        &p0.price_identifier
    }
    public fun new(p0: price_identifier::PriceIdentifier, p1: price::Price, p2: price::Price): PriceFeed {
        PriceFeed{price_identifier: p0, price: p1, ema_price: p2}
    }
}
