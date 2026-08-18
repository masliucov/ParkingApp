import Foundation

/// The persistence boundary of the app.
///
/// Features depend on this protocol rather than on the file system, which keeps them
/// testable: production uses `JSONFileStore`, tests and previews use
/// `InMemoryKeyValueStore`.
protocol KeyValueStore: Sendable {
    /// Returns the stored value, or `nil` when nothing was ever written for `key`.
    func read<Value: Decodable>(_ type: Value.Type, forKey key: String) throws -> Value?

    /// Stores `value`, replacing whatever was previously kept under `key`.
    func write<Value: Encodable>(_ value: Value, forKey key: String) throws

    /// Deletes the value stored under `key`. Unknown keys are ignored.
    func removeValue(forKey key: String) throws
}
