module 0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387::governance_action {
    use 0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387::error;
    struct GovernanceAction has copy, drop {
        value: u8,
    }
    public fun from_u8(p0: u8): GovernanceAction {
        let _v0;
        if (0u8 <= p0) _v0 = p0 <= 4u8 else _v0 = false;
        if (!_v0) {
            let _v1 = error::invalid_governance_action();
            abort _v1
        };
        GovernanceAction{value: p0}
    }
    public fun new_contract_upgrade(): GovernanceAction {
        GovernanceAction{value: 0u8}
    }
    public fun new_set_data_sources(): GovernanceAction {
        GovernanceAction{value: 2u8}
    }
    public fun new_set_governance_data_source(): GovernanceAction {
        GovernanceAction{value: 1u8}
    }
    public fun new_set_stale_price_threshold(): GovernanceAction {
        GovernanceAction{value: 4u8}
    }
    public fun new_set_update_fee(): GovernanceAction {
        GovernanceAction{value: 3u8}
    }
}
