module 0xd6e31e55a750d442bcfb60bbf842d152b102ffa5ac3ae3f2c8b43748c36a3e6f::blacklist {
    friend 0xd6e31e55a750d442bcfb60bbf842d152b102ffa5ac3ae3f2c8b43748c36a3e6f::xrion;
    enum Status has drop, store, key {
        BlackList,
        WhiteList,
        Normal,
        Pending {
            pending_xrion: u64,
        }
    }
    friend fun create_blacklist(): Status {
        Status::BlackList{}
    }
    friend fun create_normal(): Status {
        Status::Normal{}
    }
    friend fun create_pending(p0: u64): Status {
        Status::Pending{pending_xrion: p0}
    }
    friend fun create_whitelist(): Status {
        Status::WhiteList{}
    }
    friend fun is_blacklist(p0: &Status): bool {
        let _v0;
        if (p0 is BlackList) _v0 = true else if (p0 is WhiteList) _v0 = false else if (p0 is Normal) _v0 = false else if (p0 is Pending) _v0 = false else abort 14566554180833181697;
        _v0
    }
    friend fun is_pending(p0: &Status): bool {
        let _v0;
        if (p0 is BlackList) _v0 = false else if (p0 is WhiteList) _v0 = false else if (p0 is Normal) _v0 = false else if (p0 is Pending) _v0 = true else abort 14566554180833181697;
        _v0
    }
    friend fun is_pending_or_blacklist(p0: &Status): bool {
        let _v0;
        if (p0 is BlackList) _v0 = true else if (p0 is WhiteList) _v0 = false else if (p0 is Normal) _v0 = false else if (p0 is Pending) _v0 = true else abort 14566554180833181697;
        _v0
    }
}
