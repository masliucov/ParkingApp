import Foundation
import OSLog

/// A `KeyValueStore` that keeps one JSON document per key inside a directory.
struct JSONFileStore: KeyValueStore {
    private static let logger = Logger(subsystem: "com.arti.ParkingApp", category: "storage")
    private static let folderName = "ParkingApp"
    private static let fileExtension = "json"

    let directoryURL: URL

    init(directoryURL: URL) {
        self.directoryURL = directoryURL
    }

    /// The store used by the running app, rooted in Application Support.
    static func applicationSupport() throws -> JSONFileStore {
        do {
            let base = try FileManager.default.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            return JSONFileStore(directoryURL: base.appending(path: folderName))
        } catch {
            logger.error("Application Support is unreachable: \(error.localizedDescription, privacy: .public)")
            throw AppError.storageUnavailable
        }
    }

    func read<Value: Decodable>(_ type: Value.Type, forKey key: String) throws -> Value? {
        let url = try fileURL(forKey: key)
        guard FileManager.default.fileExists(atPath: url.path(percentEncoded: false)) else {
            return nil
        }

        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            Self.logger.error("Read failed for \(key, privacy: .public): \(error.localizedDescription, privacy: .public)")
            throw AppError.storageReadFailed(key: key)
        }

        do {
            return try StorageCoder.makeDecoder().decode(Value.self, from: data)
        } catch {
            Self.logger.error("Decode failed for \(key, privacy: .public): \(error.localizedDescription, privacy: .public)")
            throw AppError.corruptedData(key: key)
        }
    }

    func write<Value: Encodable>(_ value: Value, forKey key: String) throws {
        let url = try fileURL(forKey: key)

        let data: Data
        do {
            data = try StorageCoder.makeEncoder().encode(value)
        } catch {
            Self.logger.error("Encode failed for \(key, privacy: .public): \(error.localizedDescription, privacy: .public)")
            throw AppError.storageWriteFailed(key: key)
        }

        do {
            try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
            try data.write(to: url, options: .atomic)
        } catch {
            Self.logger.error("Write failed for \(key, privacy: .public): \(error.localizedDescription, privacy: .public)")
            throw AppError.storageWriteFailed(key: key)
        }
    }

    func removeValue(forKey key: String) throws {
        let url = try fileURL(forKey: key)
        guard FileManager.default.fileExists(atPath: url.path(percentEncoded: false)) else {
            return
        }

        do {
            try FileManager.default.removeItem(at: url)
        } catch {
            Self.logger.error("Delete failed for \(key, privacy: .public): \(error.localizedDescription, privacy: .public)")
            throw AppError.storageWriteFailed(key: key)
        }
    }

    // MARK: - Helpers

    private func fileURL(forKey key: String) throws -> URL {
        guard Self.isValidKey(key) else {
            throw AppError.invalidStorageKey(key: key)
        }
        return directoryURL.appending(path: "\(key).\(Self.fileExtension)")
    }

    /// Keys become file names, so anything that could escape `directoryURL` is rejected.
    private static func isValidKey(_ key: String) -> Bool {
        guard !key.isEmpty else { return false }
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        return key.unicodeScalars.allSatisfy(allowed.contains)
    }
}
