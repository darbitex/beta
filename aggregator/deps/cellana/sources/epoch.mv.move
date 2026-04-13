module 0x4bf51972879e3b95c4781a5cdcb9e1ee24ef483e7d22f2d903626f126df62bd1::epoch {
    use 0x1::timestamp;
    public fun now(): u64 {
        timestamp::now_seconds() / 604800
    }
}
