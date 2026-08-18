import Foundation

/// A `KeyValueStore` that keeps everything in memory. Used by tests and SwiftUI
/// previews so they never touch the file system.
final class InMemoryKeyValueStore: KeyValueStore, @unchecked Sendable {
    private let lock = NSLock()
    private var storage: [String: Data]

    init(storage: [String: Data] = [:]) {
        self.storage = storage
    }

    func read<Value: Decodable>(_ type: Value.Type, forKey key: String) throws -> Value? {
        lock.lock()
        let data = storage[key]
        lock.unlock()

        guard let data else { return nil }

        do {
            return try StorageCoder.makeDecoder().decode(Value.self, from: data)
        } catch {
            throw AppError.corruptedData(key: key)
        }
    }

    func write<Value: Encodable>(_ value: Value, forKey key: String) throws {
        let data: Data
        do {
            data = try StorageCoder.makeEncoder().encode(value)
        } catch {
            throw AppError.storageWriteFailed(key: key)
        }

        lock.lock()
        storage[key] = data
        lock.unlock()
    }

    func removeValue(forKey key: String) throws {
        lock.lock()
        storage[key] = nil
        lock.unlock()
    }
}
