module 0x5bc11445584a763c1fa7ed39081f1b920954da14e04b32440cba863d03e19625::set {
    use 0x1::table;
    struct Set<phantom T0: copy + drop> has store {
        elems: table::Table<T0, Unit>,
    }
    struct Unit has copy, drop, store {
    }
    public fun add<T0: copy + drop>(p0: &mut Set<T0>, p1: T0) {
        let _v0 = &mut p0.elems;
        let _v1 = Unit{};
        table::add<T0, Unit>(_v0, p1, _v1);
    }
    public fun contains<T0: copy + drop>(p0: &Set<T0>, p1: T0): bool {
        table::contains<T0, Unit>(&p0.elems, p1)
    }
    public fun new<T0: copy + drop>(): Set<T0> {
        Set<T0>{elems: table::new<T0, Unit>()}
    }
}
