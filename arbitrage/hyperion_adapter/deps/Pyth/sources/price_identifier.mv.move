module 0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387::price_identifier {
    use 0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387::error;
    struct PriceIdentifier has copy, drop, store {
        bytes: vector<u8>,
    }
    public fun from_byte_vec(p0: vector<u8>): PriceIdentifier {
        if (!(0x1::vector::length<u8>(&p0) == 32)) {
            let _v0 = error::incorrect_identifier_length();
            abort _v0
        };
        PriceIdentifier{bytes: p0}
    }
    public fun get_bytes(p0: &PriceIdentifier): vector<u8> {
        *&p0.bytes
    }
}
