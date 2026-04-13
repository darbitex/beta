module 0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c::position_blacklist {
    use 0x1::smart_vector;
    use 0x1::object;
    use 0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c::position_v3;
    use 0x1::error;
    use 0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c::i32;
    friend 0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c::pool_v3;
    struct PositionBlackList has store {
        addresses: smart_vector::SmartVector<address>,
    }
    friend fun new(): PositionBlackList {
        PositionBlackList{addresses: smart_vector::empty<address>()}
    }
    friend fun remove(p0: &mut PositionBlackList, p1: &object::Object<position_v3::Info>) {
        let _v0 = error::unavailable(11111111);
        abort _v0
    }
    friend fun add(p0: &mut PositionBlackList, p1: &object::Object<position_v3::Info>) {
        let _v0 = error::unavailable(11111111);
        abort _v0
    }
    friend fun blocked_out_liquidity_amount(p0: &PositionBlackList, p1: i32::I32): u128 {
        let _v0 = error::unavailable(11111111);
        abort _v0
    }
    friend fun view_list(p0: &PositionBlackList): vector<address> {
        let _v0 = error::unavailable(11111111);
        abort _v0
    }
    friend fun does_blocked(p0: &PositionBlackList, p1: &object::Object<position_v3::Info>): bool {
        let _v0 = error::unavailable(11111111);
        abort _v0
    }
}
