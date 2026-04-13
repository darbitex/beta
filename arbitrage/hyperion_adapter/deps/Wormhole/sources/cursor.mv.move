module 0x5bc11445584a763c1fa7ed39081f1b920954da14e04b32440cba863d03e19625::cursor {
    use 0x1::vector;
    struct Cursor<T0> {
        data: vector<T0>,
    }
    public fun destroy_empty<T0>(p0: Cursor<T0>) {
        let Cursor<T0>{data: _v0} = p0;
        vector::destroy_empty<T0>(_v0);
    }
    public fun init<T0>(p0: vector<T0>): Cursor<T0> {
        vector::reverse<T0>(&mut p0);
        Cursor<T0>{data: p0}
    }
    public fun poke<T0>(p0: &mut Cursor<T0>): T0 {
        vector::pop_back<T0>(&mut p0.data)
    }
    public fun rest<T0>(p0: Cursor<T0>): vector<T0> {
        let Cursor<T0>{data: _v0} = p0;
        let _v1 = _v0;
        vector::reverse<T0>(&mut _v1);
        _v1
    }
}
