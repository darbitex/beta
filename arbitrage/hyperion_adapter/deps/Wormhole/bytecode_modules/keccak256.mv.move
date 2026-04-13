module 0x5bc11445584a763c1fa7ed39081f1b920954da14e04b32440cba863d03e19625::keccak256 {
    use 0x1::aptos_hash;
    public fun keccak256(p0: vector<u8>): vector<u8> {
        aptos_hash::keccak256(p0)
    }
}
