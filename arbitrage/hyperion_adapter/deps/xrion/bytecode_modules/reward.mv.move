module 0xd6e31e55a750d442bcfb60bbf842d152b102ffa5ac3ae3f2c8b43748c36a3e6f::reward {
    use 0x1::object;
    use 0x1::fungible_asset;
    use 0x1::option;
    use 0x1::type_info;
    use 0x1::primary_fungible_store;
    use 0xd6e31e55a750d442bcfb60bbf842d152b102ffa5ac3ae3f2c8b43748c36a3e6f::xrion;
    use 0x1::string;
    use 0xd6e31e55a750d442bcfb60bbf842d152b102ffa5ac3ae3f2c8b43748c36a3e6f::package_manager;
    use 0xd6e31e55a750d442bcfb60bbf842d152b102ffa5ac3ae3f2c8b43748c36a3e6f::permission_control;
    use 0xd6e31e55a750d442bcfb60bbf842d152b102ffa5ac3ae3f2c8b43748c36a3e6f::send_event;
    use 0x1::error;
    use 0x1::signer;
    struct Loan<T0> {
        type: T0,
        meta: object::Object<fungible_asset::Metadata>,
        amount: u64,
        epoch: u64,
    }
    struct SwapType has store, key {
        loaned: bool,
        type: option::Option<type_info::TypeInfo>,
    }
    public entry fun deposit(p0: &signer, p1: object::Object<fungible_asset::Metadata>, p2: u64) {
        let _v0 = primary_fungible_store::withdraw<fungible_asset::Metadata>(p0, p1, p2);
        xrion::deposit_to_current_epoch(p0, _v0);
    }
    fun init_module(p0: &signer) {
        let _v0 = string::utf8(vector[114u8, 101u8, 119u8, 97u8, 114u8, 100u8]);
        let _v1 = package_manager::get_rion_signer();
        let _v2 = &_v1;
        let _v3 = permission_control::get_function_info(string::utf8(vector[115u8, 116u8, 97u8, 114u8, 116u8, 95u8, 115u8, 119u8, 97u8, 112u8]), _v0);
        let _v4 = permission_control::get_function_info(string::utf8(vector[101u8, 110u8, 100u8, 95u8, 115u8, 119u8, 97u8, 112u8]), _v0);
        permission_control::assignment_function_level(p0, _v3, 0u8);
        permission_control::assignment_function_level(p0, _v4, 0u8);
        _v3 = permission_control::get_function_info(string::utf8(vector[115u8, 101u8, 116u8, 95u8, 116u8, 121u8, 112u8, 101u8]), _v0);
        permission_control::assignment_function_level(p0, _v3, 1u8);
        let _v5 = option::none<type_info::TypeInfo>();
        let _v6 = SwapType{loaned: false, type: _v5};
        move_to<SwapType>(_v2, _v6);
    }
    fun check_permission(p0: &signer, p1: string::String) {
        let _v0 = string::utf8(vector[114u8, 101u8, 119u8, 97u8, 114u8, 100u8]);
        let _v1 = permission_control::get_function_info(p1, _v0);
        permission_control::check_permission(p0, _v1);
    }
    public fun deposit_fa(p0: fungible_asset::FungibleAsset) {
        xrion::deposit_to_current_epoch_without_limit(p0);
    }
    public fun end_swap<T0: store>(p0: &signer, p1: Loan<T0>, p2: fungible_asset::FungibleAsset): T0
        acquires SwapType
    {
        let _v0 = string::utf8(vector[101u8, 110u8, 100u8, 95u8, 115u8, 119u8, 97u8, 112u8]);
        check_permission(p0, _v0);
        let _v1 = package_manager::get_rion_address();
        let _v2 = borrow_global_mut<SwapType>(_v1);
        if (!option::is_some<type_info::TypeInfo>(&_v2.type)) {
            let _v3 = error::aborted(3);
            abort _v3
        };
        if (!*&_v2.loaned) {
            let _v4 = error::aborted(4);
            abort _v4
        };
        let _v5 = type_info::type_of<T0>();
        let _v6 = *option::borrow<type_info::TypeInfo>(&_v2.type);
        if (!(_v5 == _v6)) {
            let _v7 = error::aborted(1);
            abort _v7
        };
        let _v8 = &mut _v2.loaned;
        *_v8 = false;
        let Loan<T0>{type: _v9, meta: _v10, amount: _v11, epoch: _v12} = p1;
        let _v13 = _v12;
        let _v14 = fungible_asset::metadata_from_asset(&p2);
        let _v15 = fungible_asset::amount(&p2);
        send_event::send_swap_fee_event(_v10, _v14, _v11, _v13, _v15);
        xrion::swap_reward_to_current_epoch(p0, _v13, p2);
        _v9
    }
    public entry fun set_current_epoch_can_claim(p0: &signer) {
        let _v0 = xrion::get_current_time() as u64;
        xrion::set_can_claim(p0, _v0);
    }
    public entry fun set_epoch_can_claim(p0: &signer, p1: u64) {
        xrion::set_can_claim(p0, p1);
    }
    public entry fun set_type<T0>(p0: &signer)
        acquires SwapType
    {
        let _v0 = string::utf8(vector[115u8, 101u8, 116u8, 95u8, 116u8, 121u8, 112u8, 101u8]);
        check_permission(p0, _v0);
        let _v1 = package_manager::get_rion_address();
        let _v2 = borrow_global_mut<SwapType>(_v1);
        let _v3 = option::some<type_info::TypeInfo>(type_info::type_of<T0>());
        let _v4 = &mut _v2.type;
        *_v4 = _v3;
    }
    public fun start_swap<T0: store>(p0: &signer, p1: T0, p2: u64, p3: object::Object<fungible_asset::Metadata>, p4: option::Option<u64>): (Loan<T0>, fungible_asset::FungibleAsset)
        acquires SwapType
    {
        let _v0;
        let _v1 = string::utf8(vector[115u8, 116u8, 97u8, 114u8, 116u8, 95u8, 115u8, 119u8, 97u8, 112u8]);
        check_permission(p0, _v1);
        let _v2 = package_manager::get_rion_address();
        let _v3 = borrow_global_mut<SwapType>(_v2);
        if (*&_v3.loaned) {
            let _v4 = error::aborted(4);
            abort _v4
        };
        if (!option::is_some<type_info::TypeInfo>(&_v3.type)) {
            let _v5 = error::aborted(3);
            abort _v5
        };
        let _v6 = type_info::type_of<T0>();
        let _v7 = *option::borrow<type_info::TypeInfo>(&_v3.type);
        if (!(_v6 == _v7)) {
            let _v8 = error::aborted(1);
            abort _v8
        };
        let _v9 = &mut _v3.loaned;
        *_v9 = true;
        if (option::is_none<u64>(&p4)) _v0 = xrion::get_current_time() as u64 else _v0 = option::destroy_some<u64>(p4);
        let _v10 = xrion::get_fee_from_epoch(_v0, p2, p3);
        let _v11 = fungible_asset::amount(&_v10);
        let _v12 = Loan<T0>{type: p1, meta: p3, amount: _v11, epoch: _v0};
        send_event::send_swap_start_event(signer::address_of(p0), _v0, p3, _v11);
        (_v12, _v10)
    }
}
