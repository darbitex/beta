module 0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387::price {
    use 0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387::i64;
    struct Price has copy, drop, store {
        price: i64::I64,
        conf: u64,
        expo: i64::I64,
        timestamp: u64,
    }
    public fun get_conf(p0: &Price): u64 {
        *&p0.conf
    }
    public fun get_expo(p0: &Price): i64::I64 {
        *&p0.expo
    }
    public fun get_price(p0: &Price): i64::I64 {
        *&p0.price
    }
    public fun get_timestamp(p0: &Price): u64 {
        *&p0.timestamp
    }
    public fun new(p0: i64::I64, p1: u64, p2: i64::I64, p3: u64): Price {
        Price{price: p0, conf: p1, expo: p2, timestamp: p3}
    }
}
