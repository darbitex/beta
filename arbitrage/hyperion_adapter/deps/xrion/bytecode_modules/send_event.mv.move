module 0xd6e31e55a750d442bcfb60bbf842d152b102ffa5ac3ae3f2c8b43748c36a3e6f::send_event {
    use 0x1::object;
    use 0x1::fungible_asset;
    use 0x1::string;
    use 0x1::error;
    use 0x1::event;
    friend 0xd6e31e55a750d442bcfb60bbf842d152b102ffa5ac3ae3f2c8b43748c36a3e6f::permission_control;
    friend 0xd6e31e55a750d442bcfb60bbf842d152b102ffa5ac3ae3f2c8b43748c36a3e6f::xrion;
    friend 0xd6e31e55a750d442bcfb60bbf842d152b102ffa5ac3ae3f2c8b43748c36a3e6f::reward;
    struct AllocationRewardToEpoch has copy, drop, store {
        caller: address,
        epoch: u64,
        meta: object::Object<fungible_asset::Metadata>,
        amount: u64,
    }
    struct CanClaimEvent has copy, drop, store {
        caller: address,
        epoch: u64,
    }
    struct ClaimFeeFromEpoch has copy, drop, store {
        caller: address,
        stake_details: address,
        epoch: u64,
        meta: object::Object<fungible_asset::Metadata>,
        amount: u64,
        total: u64,
        remain: u64,
    }
    struct ClaimRewardEvent has copy, drop, store {
        epoch: u64,
        claimer: address,
        claim_position: address,
        claim_meta: object::Object<fungible_asset::Metadata>,
        claim_amount: u64,
        global: GlobalStakeEvent,
    }
    struct GlobalStakeEvent has copy, drop, store {
        total_stake: u64,
        current_epoch_time: u64,
        current_epoch_total_xrion: u64,
    }
    struct ClaimStakeEvent has copy, drop, store {
        staker: address,
        unstake_amount: u64,
        unstake_time: u64,
        position: address,
        global: GlobalStakeEvent,
    }
    struct EpochForEvent has copy, drop, store {
        epoch_time: u64,
        current_xrion_amount: u64,
    }
    struct ExtendEvent has copy, drop, store {
        staker: address,
        original_unlock_time: u64,
        original_stake_amount: u64,
        extend_stake_amount: u64,
        extend_unlock_time: u64,
        list: vector<EpochForEvent>,
        old_list: vector<EpochForEvent>,
        position: address,
        global: GlobalStakeEvent,
    }
    struct ExtendEventV2 has copy, drop, store {
        staker: address,
        original_unlock_time: u64,
        original_stake_amount: u64,
        extend_stake_amount: u64,
        extend_unlock_time: u64,
        list: vector<EpochForEvent>,
        old_list: vector<EpochForEvent>,
        position: address,
        index: u64,
        global: GlobalStakeEvent,
    }
    struct FeeToEpoch has copy, drop, store {
        epoch: u64,
        meta: object::Object<fungible_asset::Metadata>,
        amount: u64,
    }
    struct PermissionCallEvent has copy, drop, store {
        caller: address,
        module_name: string::String,
        function_name: string::String,
    }
    struct StakeEvent has copy, drop, store {
        staker: address,
        stake_amount: u64,
        unstake_time: u64,
        init_xrion_amount: u64,
        list: vector<EpochForEvent>,
        stake_position: address,
        global: GlobalStakeEvent,
    }
    struct StakeEventV2 has copy, drop, store {
        staker: address,
        stake_amount: u64,
        unstake_time: u64,
        init_xrion_amount: u64,
        list: vector<EpochForEvent>,
        stake_position: address,
        index: u64,
        global: GlobalStakeEvent,
    }
    struct SwapFeeEvent has copy, drop, store {
        epoch: u64,
        from: object::Object<fungible_asset::Metadata>,
        to: object::Object<fungible_asset::Metadata>,
        amount: u64,
        min_receive: u64,
    }
    struct SwapStart has copy, drop, store {
        caller: address,
        epoch: u64,
        meta: object::Object<fungible_asset::Metadata>,
        amount: u64,
    }
    struct UnstakePrincipal has copy, drop, store {
        caller: address,
        position: address,
        unstake_time: u64,
        amount: u64,
        current_epoch: u64,
    }
    fun create_epoch_for_event(p0: vector<u64>, p1: vector<u64>): vector<EpochForEvent> {
        let _v0 = 0x1::vector::empty<EpochForEvent>();
        let _v1 = 0x1::vector::length<u64>(&p0);
        let _v2 = 0x1::vector::length<u64>(&p1);
        if (!(_v1 == _v2)) {
            let _v3 = error::aborted(1);
            abort _v3
        };
        let _v4 = 0;
        let _v5 = false;
        let _v6 = 0x1::vector::length<u64>(&p0);
        loop {
            if (_v5) _v4 = _v4 + 1 else _v5 = true;
            if (!(_v4 < _v6)) break;
            let _v7 = &mut _v0;
            let _v8 = *0x1::vector::borrow<u64>(&p0, _v4);
            let _v9 = *0x1::vector::borrow<u64>(&p1, _v4);
            let _v10 = EpochForEvent{epoch_time: _v8, current_xrion_amount: _v9};
            0x1::vector::push_back<EpochForEvent>(_v7, _v10);
            continue
        };
        _v0
    }
    friend fun send_allocation_to_epoch_event(p0: address, p1: object::Object<fungible_asset::Metadata>, p2: u64, p3: u64) {
        event::emit<AllocationRewardToEpoch>(AllocationRewardToEpoch{caller: p0, epoch: p3, meta: p1, amount: p2});
    }
    friend fun send_can_claim_event(p0: address, p1: u64) {
        event::emit<CanClaimEvent>(CanClaimEvent{caller: p0, epoch: p1});
    }
    friend fun send_claim_fee_from_epoch_event(p0: address, p1: address, p2: object::Object<fungible_asset::Metadata>, p3: u64, p4: u64, p5: u64, p6: u64) {
        event::emit<ClaimFeeFromEpoch>(ClaimFeeFromEpoch{caller: p0, stake_details: p1, epoch: p4, meta: p2, amount: p3, total: p5, remain: p6});
    }
    friend fun send_claim_reward_event(p0: address, p1: address, p2: object::Object<fungible_asset::Metadata>, p3: u64, p4: u64, p5: u64, p6: u64, p7: u64) {
        let _v0 = GlobalStakeEvent{total_stake: p5, current_epoch_time: p6, current_epoch_total_xrion: p7};
        event::emit<ClaimRewardEvent>(ClaimRewardEvent{epoch: p4, claimer: p0, claim_position: p1, claim_meta: p2, claim_amount: p3, global: _v0});
    }
    friend fun send_extend_event(p0: address, p1: u64, p2: u64, p3: u64, p4: u64, p5: vector<u64>, p6: vector<u64>, p7: vector<u64>, p8: vector<u64>, p9: address, p10: u64, p11: u64, p12: u64) {
        let _v0 = create_epoch_for_event(p5, p6);
        let _v1 = create_epoch_for_event(p7, p8);
        let _v2 = GlobalStakeEvent{total_stake: p10, current_epoch_time: p11, current_epoch_total_xrion: p12};
        event::emit<ExtendEvent>(ExtendEvent{staker: p0, original_unlock_time: p1, original_stake_amount: p2, extend_stake_amount: p3, extend_unlock_time: p4, list: _v0, old_list: _v1, position: p9, global: _v2});
    }
    friend fun send_extend_v2_event(p0: address, p1: u64, p2: u64, p3: u64, p4: u64, p5: vector<u64>, p6: vector<u64>, p7: vector<u64>, p8: vector<u64>, p9: address, p10: u64, p11: u64, p12: u64, p13: u64) {
        let _v0 = create_epoch_for_event(p5, p6);
        let _v1 = create_epoch_for_event(p7, p8);
        let _v2 = GlobalStakeEvent{total_stake: p10, current_epoch_time: p11, current_epoch_total_xrion: p12};
        event::emit<ExtendEventV2>(ExtendEventV2{staker: p0, original_unlock_time: p1, original_stake_amount: p2, extend_stake_amount: p3, extend_unlock_time: p4, list: _v0, old_list: _v1, position: p9, index: p13, global: _v2});
    }
    friend fun send_fee_to_epoch_event(p0: object::Object<fungible_asset::Metadata>, p1: u64, p2: u64) {
        event::emit<FeeToEpoch>(FeeToEpoch{epoch: p2, meta: p0, amount: p1});
    }
    friend fun send_permission_event(p0: address, p1: string::String, p2: string::String) {
        event::emit<PermissionCallEvent>(PermissionCallEvent{caller: p0, module_name: p2, function_name: p1});
    }
    friend fun send_stake_event(p0: address, p1: u64, p2: u64, p3: u64, p4: vector<u64>, p5: vector<u64>, p6: address, p7: u64, p8: u64, p9: u64) {
        let _v0 = create_epoch_for_event(p4, p5);
        let _v1 = GlobalStakeEvent{total_stake: p7, current_epoch_time: p8, current_epoch_total_xrion: p9};
        event::emit<StakeEvent>(StakeEvent{staker: p0, stake_amount: p1, unstake_time: p2, init_xrion_amount: p3, list: _v0, stake_position: p6, global: _v1});
    }
    friend fun send_stake_v2_event(p0: address, p1: u64, p2: u64, p3: u64, p4: vector<u64>, p5: vector<u64>, p6: address, p7: u64, p8: u64, p9: u64, p10: u64) {
        let _v0 = create_epoch_for_event(p4, p5);
        let _v1 = GlobalStakeEvent{total_stake: p7, current_epoch_time: p8, current_epoch_total_xrion: p9};
        event::emit<StakeEventV2>(StakeEventV2{staker: p0, stake_amount: p1, unstake_time: p2, init_xrion_amount: p3, list: _v0, stake_position: p6, index: p10, global: _v1});
    }
    friend fun send_swap_fee_event(p0: object::Object<fungible_asset::Metadata>, p1: object::Object<fungible_asset::Metadata>, p2: u64, p3: u64, p4: u64) {
        event::emit<SwapFeeEvent>(SwapFeeEvent{epoch: p3, from: p0, to: p1, amount: p2, min_receive: p4});
    }
    friend fun send_swap_start_event(p0: address, p1: u64, p2: object::Object<fungible_asset::Metadata>, p3: u64) {
        event::emit<SwapStart>(SwapStart{caller: p0, epoch: p1, meta: p2, amount: p3});
    }
    friend fun send_unstake_event(p0: address, p1: u64, p2: u64, p3: address, p4: u64, p5: u64, p6: u64) {
        let _v0 = GlobalStakeEvent{total_stake: p4, current_epoch_time: p5, current_epoch_total_xrion: p6};
        event::emit<ClaimStakeEvent>(ClaimStakeEvent{staker: p0, unstake_amount: p1, unstake_time: p2, position: p3, global: _v0});
    }
    friend fun send_unstake_principal_event(p0: address, p1: address, p2: u64, p3: u64, p4: u64) {
        event::emit<UnstakePrincipal>(UnstakePrincipal{caller: p0, position: p1, unstake_time: p3, amount: p2, current_epoch: p4});
    }
}
