module 0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387::price_status {
    use 0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387::error;
    struct PriceStatus has copy, drop, store {
        status: u64,
    }
    public fun from_u64(p0: u64): PriceStatus {
        if (!(p0 <= 1)) {
            let _v0 = error::invalid_price_status();
            abort _v0
        };
        PriceStatus{status: p0}
    }
    public fun get_status(p0: &PriceStatus): u64 {
        *&p0.status
    }
    public fun new_trading(): PriceStatus {
        PriceStatus{status: 1}
    }
    public fun new_unknown(): PriceStatus {
        PriceStatus{status: 0}
    }
}
