import Foundation

/// Folds text into a number the same way on every launch.
///
/// `String.hashValue` is salted per process, so anything derived from it changes when the
/// app reopens. Prices and lot codes have to hold still, so they fold the characters here
/// instead. This is FNV-1a: cheap, well spread, and not meant to resist anyone.
enum StableHash {
    private static let offsetBasis: UInt64 = 14_695_981_039_346_656_037
    private static let prime: UInt64 = 1_099_511_628_211

    static func of(_ text: String) -> UInt64 {
        text.unicodeScalars.reduce(offsetBasis) { hash, scalar in
            (hash ^ UInt64(scalar.value)) &* prime
        }
    }
}
