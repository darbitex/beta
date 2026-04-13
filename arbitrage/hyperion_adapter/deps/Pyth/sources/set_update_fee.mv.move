module 0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387::set_update_fee {
    use 0x1::math64;
    use 0x5bc11445584a763c1fa7ed39081f1b920954da14e04b32440cba863d03e19625::cursor;
    use 0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387::deserialize;
    use 0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387::state;
    friend 0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387::governance;
    struct SetUpdateFee {
        mantissa: u64,
        exponent: u64,
    }
    fun apply_exponent(p0: u64, p1: u64): u64 {
        let _v0 = math64::pow(10, p1);
        p0 * _v0
    }
    friend fun execute(p0: vector<u8>) {
        let SetUpdateFee{mantissa: _v0, exponent: _v1} = from_byte_vec(p0);
        state::set_base_update_fee(apply_exponent(_v0, _v1));
    }
    fun from_byte_vec(p0: vector<u8>): SetUpdateFee {
        let _v0 = cursor::init<u8>(p0);
        let _v1 = deserialize::deserialize_u64(&mut _v0);
        let _v2 = deserialize::deserialize_u64(&mut _v0);
        cursor::destroy_empty<u8>(_v0);
        SetUpdateFee{mantissa: _v1, exponent: _v2}
    }
}
