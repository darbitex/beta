module 0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c::rate_limiter {
    use 0x1::timestamp;
    friend 0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c::rate_limiter_check;
    enum RateLimiter has copy, drop, store, key {
        TokenBucket {
            capacity: u64,
            current_amount: u64,
            refill_interval: u64,
            last_refill_timestamp: u64,
            fractional_accumulated: u64,
        }
    }
    friend fun capacity(p0: &mut RateLimiter): u64 {
        *&p0.capacity
    }
    friend fun refill_interval(p0: &mut RateLimiter): u64 {
        *&p0.refill_interval
    }
    public fun initialize(p0: u64, p1: u64): RateLimiter {
        let _v0 = timestamp::now_seconds();
        RateLimiter::TokenBucket{capacity: p0, current_amount: p0, refill_interval: p1, last_refill_timestamp: _v0, fractional_accumulated: 0}
    }
    fun refill(p0: &mut RateLimiter) {
        let _v0 = timestamp::now_seconds();
        let _v1 = *&p0.last_refill_timestamp;
        let _v2 = _v0 - _v1;
        let _v3 = *&p0.capacity;
        let _v4 = _v2 * _v3;
        let _v5 = *&p0.fractional_accumulated;
        let _v6 = _v4 + _v5;
        let _v7 = *&p0.refill_interval;
        let _v8 = _v6 / _v7;
        let _v9 = *&p0.current_amount + _v8;
        let _v10 = *&p0.capacity;
        if (_v9 >= _v10) {
            let _v11 = *&p0.capacity;
            let _v12 = &mut p0.current_amount;
            *_v12 = _v11;
            let _v13 = &mut p0.fractional_accumulated;
            *_v13 = 0
        } else {
            let _v14 = *&p0.current_amount + _v8;
            let _v15 = &mut p0.current_amount;
            *_v15 = _v14;
            let _v16 = *&p0.refill_interval;
            let _v17 = _v6 % _v16;
            let _v18 = &mut p0.fractional_accumulated;
            *_v18 = _v17
        };
        let _v19 = &mut p0.last_refill_timestamp;
        *_v19 = _v0;
    }
    public fun request(p0: &mut RateLimiter, p1: u64): bool {
        refill(p0);
        if (*&p0.current_amount >= p1) {
            let _v0 = *&p0.current_amount - p1;
            let _v1 = &mut p0.current_amount;
            *_v1 = _v0;
            return true
        };
        false
    }
    friend fun rate_limiter_info_real_time(p0: &RateLimiter): (u64, u64, u64) {
        let _v0;
        let _v1 = timestamp::now_seconds();
        let _v2 = *&p0.last_refill_timestamp;
        let _v3 = _v1 - _v2;
        let _v4 = *&p0.capacity;
        let _v5 = _v3 * _v4;
        let _v6 = *&p0.fractional_accumulated;
        let _v7 = _v5 + _v6;
        let _v8 = *&p0.refill_interval;
        let _v9 = _v7 / _v8;
        let _v10 = *&p0.current_amount + _v9;
        let _v11 = *&p0.capacity;
        if (_v10 >= _v11) _v0 = *&p0.capacity else _v0 = *&p0.current_amount + _v9;
        let _v12 = *&p0.capacity;
        let _v13 = *&p0.refill_interval;
        (_v0, _v12, _v13)
    }
    public fun recover(p0: &mut RateLimiter, p1: u64) {
        refill(p0);
        let _v0 = *&p0.capacity;
        let _v1 = *&p0.current_amount;
        if (_v0 - _v1 >= p1) {
            let _v2 = &mut p0.current_amount;
            *_v2 = *_v2 + p1;
            return ()
        };
        let _v3 = *&p0.capacity;
        let _v4 = &mut p0.current_amount;
        *_v4 = _v3;
    }
}
