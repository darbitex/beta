module 0xb31e712b26fd295357355f6845e77c888298636609e93bc9b05f0f604049f434::deployer {
    use 0x1::account;
    use 0x1::code;
    use 0x1::signer;
    struct DeployingSignerCapability has key {
        signer_cap: account::SignerCapability,
        deployer: address,
    }
    public fun claim_signer_capability(p0: &signer, p1: address): account::SignerCapability
        acquires DeployingSignerCapability
    {
        let _v0;
        assert!(exists<DeployingSignerCapability>(p1), 0);
        let DeployingSignerCapability{signer_cap: _v1, deployer: _v2} = move_from<DeployingSignerCapability>(p1);
        let _v3 = signer::address_of(p0);
        if (_v3 == _v2) _v0 = true else _v0 = _v3 == p1;
        assert!(_v0, 1);
        _v1
    }
    public entry fun deploy_derived(p0: &signer, p1: vector<u8>, p2: vector<vector<u8>>, p3: vector<u8>)
        acquires DeployingSignerCapability
    {
        let _v0;
        let _v1 = signer::address_of(p0);
        let _v2 = account::create_resource_address(&_v1, p3);
        if (exists<DeployingSignerCapability>(_v2)) _v0 = account::create_signer_with_capability(&borrow_global<DeployingSignerCapability>(_v2).signer_cap) else {
            let (_v3,_v4) = account::create_resource_account(p0, p3);
            _v0 = _v3;
            let _v5 = &_v0;
            let _v6 = DeployingSignerCapability{signer_cap: _v4, deployer: _v1};
            move_to<DeployingSignerCapability>(_v5, _v6)
        };
        code::publish_package_txn(&_v0, p1, p2);
    }
}
