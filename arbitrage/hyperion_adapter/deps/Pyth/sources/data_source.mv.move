module 0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387::data_source {
    use 0x5bc11445584a763c1fa7ed39081f1b920954da14e04b32440cba863d03e19625::external_address;
    struct DataSource has copy, drop, store {
        emitter_chain: u64,
        emitter_address: external_address::ExternalAddress,
    }
    public fun new(p0: u64, p1: external_address::ExternalAddress): DataSource {
        DataSource{emitter_chain: p0, emitter_address: p1}
    }
}
