module 0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c::user_label {
    use 0x1::string;
    use 0x1::smart_vector;
    use 0x1::smart_table;
    use 0x1::signer;
    use 0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c::package_manager;
    use 0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c::caas_integration;
    use 0x92af222254470faeda82d447067ce14b38ceafedb4c7ea462bf6b1e98cecf1f8::namespace;
    use 0x1::object;
    use 0x92af222254470faeda82d447067ce14b38ceafedb4c7ea462bf6b1e98cecf1f8::label;
    use 0x1::vector;
    use 0x1::event;
    friend 0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c::rewarder;
    struct AddLabelEnumEvent has copy, drop, store {
        admin: address,
        label: string::String,
    }
    struct Label has key {
        enums: smart_vector::SmartVector<string::String>,
    }
    struct AddLabelEnumEventV1 has copy, drop, store {
        label: string::String,
    }
    struct AddUserLabelEvent has copy, drop, store {
        user: address,
        label: string::String,
    }
    struct LabelRecords has key {
        labels: smart_table::SmartTable<address, smart_vector::SmartVector<string::String>>,
    }
    struct RemoveUserLabelEvent has copy, drop, store {
        user: address,
        label: string::String,
    }
    entry fun initialize(p0: &signer) {
        assert!(package_manager::is_super_admin(signer::address_of(p0)), 230001);
        let _v0 = object::address_to_object<namespace::NamespaceCore>(caas_integration::primary_namespace_address());
        let _v1 = caas_integration::get_witness();
        label::create<caas_integration::Witness>(_v0, _v1);
    }
    public fun has_label(p0: address, p1: string::String): bool {
        let _v0 = object::address_to_object<namespace::NamespaceCore>(caas_integration::primary_namespace_address());
        let _v1 = caas_integration::get_witness();
        label::has_label<caas_integration::Witness>(_v0, p0, p1, _v1)
    }
    public entry fun add_label_enum(p0: &signer, p1: string::String) {
        let _v0 = string::utf8(vector[97u8, 100u8, 100u8, 95u8, 108u8, 97u8, 98u8, 101u8, 108u8, 95u8, 101u8, 110u8, 117u8, 109u8]);
        package_manager::assert_admin(p0, _v0);
        add_label_enum_internal(p1);
    }
    friend fun add_label_enum_internal(p0: string::String) {
        let _v0 = object::address_to_object<namespace::NamespaceCore>(caas_integration::primary_namespace_address());
        let _v1 = caas_integration::get_witness();
        label::add_enums<caas_integration::Witness>(_v0, p0, _v1);
        event::emit<AddLabelEnumEventV1>(AddLabelEnumEventV1{label: p0});
    }
    entry fun add_label_enum_batch(p0: &signer, p1: vector<string::String>) {
        let _v0 = p1;
        vector::reverse<string::String>(&mut _v0);
        let _v1 = _v0;
        let _v2 = vector::length<string::String>(&_v1);
        while (_v2 > 0) {
            let _v3 = vector::pop_back<string::String>(&mut _v1);
            add_label_enum(p0, _v3);
            _v2 = _v2 - 1;
            continue
        };
        vector::destroy_empty<string::String>(_v1);
    }
    entry fun batch_remove_of_user_labels(p0: &signer, p1: address, p2: vector<string::String>) {
        let _v0 = p2;
        vector::reverse<string::String>(&mut _v0);
        let _v1 = _v0;
        let _v2 = vector::length<string::String>(&_v1);
        while (_v2 > 0) {
            let _v3 = vector::pop_back<string::String>(&mut _v1);
            remove_user_label(p0, p1, _v3);
            _v2 = _v2 - 1;
            continue
        };
        vector::destroy_empty<string::String>(_v1);
    }
    public entry fun remove_user_label(p0: &signer, p1: address, p2: string::String) {
        let _v0 = string::utf8(vector[114u8, 101u8, 109u8, 111u8, 118u8, 101u8, 95u8, 117u8, 115u8, 101u8, 114u8, 95u8, 108u8, 97u8, 98u8, 101u8, 108u8]);
        package_manager::assert_admin(p0, _v0);
        assert!(is_label_legal(p2), 230005);
        let _v1 = object::address_to_object<namespace::NamespaceCore>(caas_integration::primary_namespace_address());
        let _v2 = caas_integration::get_witness();
        label::remove_label<caas_integration::Witness>(_v1, p1, p2, _v2);
        event::emit<RemoveUserLabelEvent>(RemoveUserLabelEvent{user: p1, label: p2});
    }
    public fun get_user_labels(p0: address): vector<string::String> {
        let _v0 = object::address_to_object<namespace::NamespaceCore>(caas_integration::primary_namespace_address());
        let _v1 = caas_integration::get_witness();
        label::get_address_labels<caas_integration::Witness>(_v0, p0, _v1)
    }
    friend fun is_label_legal(p0: string::String): bool {
        let _v0 = object::address_to_object<namespace::NamespaceCore>(caas_integration::primary_namespace_address());
        let _v1 = caas_integration::get_witness();
        label::has_label_enum<caas_integration::Witness>(_v0, p0, _v1)
    }
    entry fun remove_user_label_batch(p0: &signer, p1: vector<address>, p2: string::String) {
        let _v0 = p1;
        vector::reverse<address>(&mut _v0);
        let _v1 = _v0;
        let _v2 = vector::length<address>(&_v1);
        while (_v2 > 0) {
            let _v3 = vector::pop_back<address>(&mut _v1);
            remove_user_label(p0, _v3, p2);
            _v2 = _v2 - 1;
            continue
        };
        vector::destroy_empty<address>(_v1);
    }
    public entry fun set_user_label(p0: &signer, p1: address, p2: string::String) {
        let _v0 = string::utf8(vector[115u8, 101u8, 116u8, 95u8, 117u8, 115u8, 101u8, 114u8, 95u8, 108u8, 97u8, 98u8, 101u8, 108u8]);
        package_manager::assert_admin(p0, _v0);
        set_user_label_internal(p1, p2);
    }
    friend fun set_user_label_internal(p0: address, p1: string::String) {
        assert!(is_label_legal(p1), 230005);
        let _v0 = object::address_to_object<namespace::NamespaceCore>(caas_integration::primary_namespace_address());
        let _v1 = caas_integration::get_witness();
        label::set_label<caas_integration::Witness>(_v0, p0, p1, _v1);
        event::emit<AddUserLabelEvent>(AddUserLabelEvent{user: p0, label: p1});
    }
    entry fun set_user_label_batch(p0: &signer, p1: vector<address>, p2: string::String) {
        let _v0 = p1;
        vector::reverse<address>(&mut _v0);
        let _v1 = _v0;
        let _v2 = vector::length<address>(&_v1);
        while (_v2 > 0) {
            let _v3 = vector::pop_back<address>(&mut _v1);
            set_user_label(p0, _v3, p2);
            _v2 = _v2 - 1;
            continue
        };
        vector::destroy_empty<address>(_v1);
    }
}
