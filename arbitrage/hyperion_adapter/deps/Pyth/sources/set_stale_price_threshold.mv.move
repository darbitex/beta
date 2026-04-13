module 0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387::set_stale_price_threshold {
    use 0x5bc11445584a763c1fa7ed39081f1b920954da14e04b32440cba863d03e19625::cursor;
    use 0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387::deserialize;
    use 0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387::state;
    friend 0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387::governance;
    struct SetStalePriceThreshold {
        threshold: u64,
    }
    friend fun execute(p0: vector<u8>) {
        let SetStalePriceThreshold{threshold: _v0} = from_byte_vec(p0);
        state::set_stale_price_threshold_secs(_v0);
    }
    fun from_byte_vec(p0: vector<u8>): SetStalePriceThreshold {
        let _v0 = cursor::init<u8>(p0);
        let _v1 = deserialize::deserialize_u64(&mut _v0);
        cursor::destroy_empty<u8>(_v0);
        SetStalePriceThreshold{threshold: _v1}
    }
}
