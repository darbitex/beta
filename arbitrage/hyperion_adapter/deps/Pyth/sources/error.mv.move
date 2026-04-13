module 0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387::error {
    use 0x1::error;
    public fun data_source_emitter_address_and_chain_ids_different_lengths(): u64 {
        error::invalid_argument(25)
    }
    public fun governance_contract_upgrade_chain_id_zero(): u64 {
        error::invalid_argument(22)
    }
    public fun incorrect_identifier_length(): u64 {
        error::invalid_argument(2)
    }
    public fun insufficient_fee(): u64 {
        error::invalid_argument(6)
    }
    public fun invalid_accumulator_message(): u64 {
        error::invalid_argument(27)
    }
    public fun invalid_accumulator_payload(): u64 {
        error::invalid_argument(26)
    }
    public fun invalid_attestation_magic_value(): u64 {
        error::invalid_argument(24)
    }
    public fun invalid_batch_attestation_header_size(): u64 {
        error::invalid_argument(18)
    }
    public fun invalid_data_source(): u64 {
        error::invalid_argument(3)
    }
    public fun invalid_governance_action(): u64 {
        error::invalid_argument(16)
    }
    public fun invalid_governance_data_source(): u64 {
        error::invalid_argument(14)
    }
    public fun invalid_governance_magic_value(): u64 {
        error::invalid_argument(20)
    }
    public fun invalid_governance_module(): u64 {
        error::invalid_argument(12)
    }
    public fun invalid_governance_sequence_number(): u64 {
        error::invalid_argument(15)
    }
    public fun invalid_governance_target_chain_id(): u64 {
        error::invalid_argument(13)
    }
    public fun invalid_hash_length(): u64 {
        error::invalid_argument(11)
    }
    public fun invalid_keccak160_length(): u64 {
        error::invalid_argument(30)
    }
    public fun invalid_price_status(): u64 {
        error::invalid_argument(23)
    }
    public fun invalid_proof(): u64 {
        error::invalid_argument(29)
    }
    public fun invalid_publish_times_length(): u64 {
        error::invalid_argument(5)
    }
    public fun invalid_upgrade_hash(): u64 {
        error::invalid_argument(10)
    }
    public fun invalid_wormhole_message(): u64 {
        error::invalid_argument(28)
    }
    public fun magnitude_too_large(): u64 {
        error::invalid_argument(21)
    }
    public fun negative_value(): u64 {
        error::invalid_state(1)
    }
    public fun no_fresh_data(): u64 {
        error::already_exists(7)
    }
    public fun overflow(): u64 {
        error::out_of_range(17)
    }
    public fun positive_value(): u64 {
        error::invalid_state(19)
    }
    public fun stale_price_update(): u64 {
        error::already_exists(4)
    }
    public fun unauthorized_upgrade(): u64 {
        error::permission_denied(9)
    }
    public fun unknown_price_feed(): u64 {
        error::not_found(8)
    }
}
