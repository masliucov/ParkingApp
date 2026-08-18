import Foundation

/// Shared JSON configuration for every `KeyValueStore`.
enum StorageCoder {
    static func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }

    static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}

extension Date {
    /// The current time, truncated to whole seconds.
    ///
    /// Stored files use ISO 8601, which drops fractions of a second. Creating timestamps
    /// at that precision keeps an in-memory value equal to the one read back later.
    static func storageNow() -> Date {
        Date(timeIntervalSince1970: Date().timeIntervalSince1970.rounded(.down))
    }
}
