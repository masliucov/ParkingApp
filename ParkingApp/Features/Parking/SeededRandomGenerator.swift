import Foundation

/// A random source that always produces the same sequence for the same seed.
///
/// Uses xorshift64*, which is small and fast. It is not suitable for anything that
/// needs unpredictability.
struct SeededRandomGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        // xorshift never escapes a zero state, so a seed of zero needs replacing.
        state = seed == 0 ? 0x9E37_79B9_7F4A_7C15 : seed
    }

    mutating func next() -> UInt64 {
        state ^= state >> 12
        state ^= state << 25
        state ^= state >> 27
        return state &* 2_685_821_657_736_338_717
    }
}
