module 0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387::set {
    use 0x1::table;
    use 0x1::vector;
    struct Set<T0: copy + drop> has store {
        keys: vector<T0>,
        elems: table::Table<T0, Unit>,
    }
    struct Unit has copy, drop, store {
    }
    public fun empty<T0: copy + drop>(p0: &mut Set<T0>) {
        while (!vector::is_empty<T0>(&p0.keys)) {
            let _v0 = &mut p0.elems;
            let _v1 = vector::pop_back<T0>(&mut p0.keys);
            let _v2 = table::remove<T0, Unit>(_v0, _v1);
            continue
        };
    }
    public fun add<T0: copy + drop>(p0: &mut Set<T0>, p1: T0) {
        let _v0 = &mut p0.elems;
        let _v1 = Unit{};
        table::add<T0, Unit>(_v0, p1, _v1);
        vector::push_back<T0>(&mut p0.keys, p1);
    }
    public fun contains<T0: copy + drop>(p0: &Set<T0>, p1: T0): bool {
        table::contains<T0, Unit>(&p0.elems, p1)
    }
    public fun new<T0: copy + drop>(): Set<T0> {
        let _v0 = vector::empty<T0>();
        let _v1 = table::new<T0, Unit>();
        Set<T0>{keys: _v0, elems: _v1}
    }
}
