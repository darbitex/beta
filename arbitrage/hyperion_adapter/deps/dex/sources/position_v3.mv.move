module 0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c::position_v3 {
    use 0x1::object;
    use 0x1::fungible_asset;
    use 0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c::i32;
    use 0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c::rewarder;
    use 0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c::math_u128;
    use 0x1::signer;
    use 0x1::event;
    friend 0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c::pool_v3;
    struct CreatePositionEvent has drop, store {
        object_id: address,
        pool_id: address,
        token_a: object::Object<fungible_asset::Metadata>,
        token_b: object::Object<fungible_asset::Metadata>,
        fee_tier: u8,
        tick_lower: i32::I32,
        tick_upper: i32::I32,
    }
    struct Info has key {
        initialized: bool,
        liquidity: u128,
        tick_lower: i32::I32,
        tick_upper: i32::I32,
        fee_growth_inside_a_last: u128,
        fee_growth_inside_b_last: u128,
        fee_owed_a: u64,
        fee_owed_b: u64,
        token_a: object::Object<fungible_asset::Metadata>,
        token_b: object::Object<fungible_asset::Metadata>,
        fee_tier: u8,
        rewards: vector<rewarder::PositionReward>,
    }
    friend fun add_liquidity(p0: object::Object<Info>, p1: u128, p2: u128, p3: u128): (u128, u128, bool)
        acquires Info
    {
        let _v0 = object::object_address<Info>(&p0);
        let _v1 = borrow_global_mut<Info>(_v0);
        let _v2 = *&_v1.fee_growth_inside_a_last;
        let (_v3,_v4) = math_u128::overflowing_sub(p2, _v2);
        let _v5 = *&_v1.fee_growth_inside_b_last;
        let (_v6,_v7) = math_u128::overflowing_sub(p3, _v5);
        let _v8 = *&_v1.liquidity;
        let _v9 = _v3 * _v8;
        let _v10 = *&_v1.liquidity;
        let _v11 = _v6 * _v10;
        let _v12 = *&_v1.fee_owed_a;
        let _v13 = (_v9 >> 64u8) as u64;
        let _v14 = _v12 + _v13;
        let _v15 = &mut _v1.fee_owed_a;
        *_v15 = _v14;
        let _v16 = *&_v1.fee_owed_b;
        let _v17 = (_v11 >> 64u8) as u64;
        let _v18 = _v16 + _v17;
        let _v19 = &mut _v1.fee_owed_b;
        *_v19 = _v18;
        let _v20 = *&_v1.liquidity;
        let _v21 = *&_v1.liquidity + p1;
        let _v22 = &mut _v1.liquidity;
        *_v22 = _v21;
        let _v23 = &mut _v1.fee_growth_inside_a_last;
        *_v23 = p2;
        _v23 = &mut _v1.fee_growth_inside_b_last;
        *_v23 = p3;
        (_v20, p1, false)
    }
    friend fun calc_fees(p0: object::Object<Info>, p1: u128, p2: u128): (u64, u64)
        acquires Info
    {
        let _v0 = object::object_address<Info>(&p0);
        let _v1 = borrow_global<Info>(_v0);
        let _v2 = *&_v1.fee_growth_inside_a_last;
        let (_v3,_v4) = math_u128::overflowing_sub(p1, _v2);
        let _v5 = *&_v1.fee_growth_inside_b_last;
        let (_v6,_v7) = math_u128::overflowing_sub(p2, _v5);
        p2 = _v6;
        let _v8 = *&_v1.liquidity;
        p1 = _v3 * _v8 >> 64u8;
        let _v9 = *&_v1.liquidity;
        p2 = p2 * _v9 >> 64u8;
        let _v10 = *&_v1.fee_owed_a;
        let _v11 = p1 as u64;
        let _v12 = _v10 + _v11;
        let _v13 = *&_v1.fee_owed_b;
        let _v14 = p2 as u64;
        let _v15 = _v13 + _v14;
        (_v12, _v15)
    }
    friend fun claim_fees(p0: object::Object<Info>, p1: u128, p2: u128): (u64, u64)
        acquires Info
    {
        let _v0 = object::object_address<Info>(&p0);
        let _v1 = borrow_global_mut<Info>(_v0);
        let _v2 = *&_v1.fee_growth_inside_a_last;
        let (_v3,_v4) = math_u128::overflowing_sub(p1, _v2);
        let _v5 = *&_v1.fee_growth_inside_b_last;
        let (_v6,_v7) = math_u128::overflowing_sub(p2, _v5);
        let _v8 = _v6;
        let _v9 = *&_v1.liquidity;
        let _v10 = _v3 * _v9 >> 64u8;
        let _v11 = *&_v1.liquidity;
        _v8 = _v8 * _v11 >> 64u8;
        let _v12 = *&_v1.fee_owed_a;
        let _v13 = _v10 as u64;
        let _v14 = _v12 + _v13;
        let _v15 = *&_v1.fee_owed_b;
        let _v16 = _v8 as u64;
        let _v17 = _v15 + _v16;
        let _v18 = &mut _v1.fee_owed_a;
        *_v18 = 0;
        let _v19 = &mut _v1.fee_owed_b;
        *_v19 = 0;
        let _v20 = &mut _v1.fee_growth_inside_a_last;
        *_v20 = p1;
        _v20 = &mut _v1.fee_growth_inside_b_last;
        *_v20 = p2;
        (_v14, _v17)
    }
    friend fun copy_position_rewards(p0: object::Object<Info>): vector<rewarder::PositionReward>
        acquires Info
    {
        let _v0 = object::object_address<Info>(&p0);
        *&borrow_global<Info>(_v0).rewards
    }
    fun delete_empty_position(p0: object::Object<Info>)
        acquires Info
    {
        let _v0 = object::object_address<Info>(&p0);
        let Info{initialized: _v1, liquidity: _v2, tick_lower: _v3, tick_upper: _v4, fee_growth_inside_a_last: _v5, fee_growth_inside_b_last: _v6, fee_owed_a: _v7, fee_owed_b: _v8, token_a: _v9, token_b: _v10, fee_tier: _v11, rewards: _v12} = move_from<Info>(_v0);
        assert!(_v1, 300002);
        assert!(_v2 == 0u128, 300003);
        assert!(_v7 == 0, 300003);
        assert!(_v8 == 0, 300003);
        let _v13 = _v12;
        let _v14 = 0x1::vector::length<rewarder::PositionReward>(&_v13);
        while (_v14 > 0) {
            let _v15 = 0x1::vector::pop_back<rewarder::PositionReward>(&mut _v13);
            _v14 = _v14 - 1;
            continue
        };
        0x1::vector::destroy_empty<rewarder::PositionReward>(_v13);
    }
    public fun get_liquidity(p0: object::Object<Info>): u128
        acquires Info
    {
        let _v0 = object::object_address<Info>(&p0);
        *&borrow_global<Info>(_v0).liquidity
    }
    public fun get_pool_info(p0: object::Object<Info>): (object::Object<fungible_asset::Metadata>, object::Object<fungible_asset::Metadata>, u8)
        acquires Info
    {
        let _v0 = object::object_address<Info>(&p0);
        let _v1 = borrow_global<Info>(_v0);
        let _v2 = *&_v1.token_a;
        let _v3 = *&_v1.token_b;
        let _v4 = *&_v1.fee_tier;
        (_v2, _v3, _v4)
    }
    friend fun get_position_rewards(p0: &signer, p1: object::Object<Info>): vector<rewarder::PositionReward>
        acquires Info
    {
        let _v0 = signer::address_of(p0);
        assert!(object::is_owner<Info>(p1, _v0), 300001);
        let _v1 = object::object_address<Info>(&p1);
        *&borrow_global<Info>(_v1).rewards
    }
    friend fun get_position_rewards_v2(p0: object::Object<Info>): vector<rewarder::PositionReward>
        acquires Info
    {
        let _v0 = object::object_address<Info>(&p0);
        *&borrow_global<Info>(_v0).rewards
    }
    public fun get_tick(p0: object::Object<Info>): (i32::I32, i32::I32)
        acquires Info
    {
        let _v0 = object::object_address<Info>(&p0);
        let _v1 = borrow_global<Info>(_v0);
        let _v2 = *&_v1.tick_lower;
        let _v3 = *&_v1.tick_upper;
        (_v2, _v3)
    }
    friend fun open_position(p0: &object::ConstructorRef, p1: i32::I32, p2: i32::I32, p3: object::Object<fungible_asset::Metadata>, p4: object::Object<fungible_asset::Metadata>, p5: u8, p6: address): object::Object<Info> {
        let _v0 = object::generate_signer(p0);
        let _v1 = &_v0;
        let _v2 = 0x1::vector::empty<rewarder::PositionReward>();
        let _v3 = Info{initialized: true, liquidity: 0u128, tick_lower: p1, tick_upper: p2, fee_growth_inside_a_last: 0u128, fee_growth_inside_b_last: 0u128, fee_owed_a: 0, fee_owed_b: 0, token_a: p3, token_b: p4, fee_tier: p5, rewards: _v2};
        move_to<Info>(_v1, _v3);
        event::emit<CreatePositionEvent>(CreatePositionEvent{object_id: object::address_from_constructor_ref(p0), pool_id: p6, token_a: p3, token_b: p4, fee_tier: p5, tick_lower: p1, tick_upper: p2});
        object::object_from_constructor_ref<Info>(p0)
    }
    friend fun refresh_position_owed_fee_to_zero(p0: object::Object<Info>)
        acquires Info
    {
        let _v0 = object::object_address<Info>(&p0);
        let _v1 = borrow_global_mut<Info>(_v0);
        let _v2 = &mut _v1.fee_owed_a;
        *_v2 = 0;
        let _v3 = &mut _v1.fee_owed_b;
        *_v3 = 0;
    }
    friend fun remove_liquidity(p0: object::Object<Info>, p1: u128, p2: u128, p3: u128): (u128, u128, bool) {
        (0u128, 0u128, false)
    }
    friend fun remove_liquidity_v2(p0: object::Object<Info>, p1: u128, p2: u128, p3: u128, p4: bool): (u128, u128, bool)
        acquires Info
    {
        let _v0;
        let _v1 = object::object_address<Info>(&p0);
        let _v2 = borrow_global_mut<Info>(_v1);
        let _v3 = *&_v2.fee_growth_inside_a_last;
        let (_v4,_v5) = math_u128::overflowing_sub(p2, _v3);
        let _v6 = *&_v2.fee_growth_inside_b_last;
        let (_v7,_v8) = math_u128::overflowing_sub(p3, _v6);
        let _v9 = *&_v2.liquidity;
        let _v10 = _v4 * _v9;
        let _v11 = *&_v2.liquidity;
        let _v12 = _v7 * _v11;
        let _v13 = *&_v2.fee_owed_a;
        let _v14 = (_v10 >> 64u8) as u64;
        let _v15 = _v13 + _v14;
        let _v16 = &mut _v2.fee_owed_a;
        *_v16 = _v15;
        let _v17 = *&_v2.fee_owed_b;
        let _v18 = (_v12 >> 64u8) as u64;
        let _v19 = _v17 + _v18;
        let _v20 = &mut _v2.fee_owed_b;
        *_v20 = _v19;
        let _v21 = *&_v2.liquidity;
        let _v22 = *&_v2.liquidity - p1;
        let _v23 = &mut _v2.liquidity;
        *_v23 = _v22;
        let _v24 = &mut _v2.fee_growth_inside_a_last;
        *_v24 = p2;
        _v24 = &mut _v2.fee_growth_inside_b_last;
        *_v24 = p3;
        if (*&_v2.liquidity == 0u128) {
            if (p4) refresh_position_owed_fee_to_zero(p0);
            delete_empty_position(p0);
            _v0 = true
        } else _v0 = false;
        (_v21, p1, _v0)
    }
    friend fun update_rewards(p0: object::Object<Info>, p1: vector<rewarder::PositionReward>)
        acquires Info
    {
        let _v0 = object::object_address<Info>(&p0);
        let _v1 = &mut borrow_global_mut<Info>(_v0).rewards;
        *_v1 = p1;
    }
}
