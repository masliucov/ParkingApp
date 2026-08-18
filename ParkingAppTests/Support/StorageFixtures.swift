import Foundation

/// A small `Codable` value for exercising the storage layer.
struct StoredTicket: Codable, Equatable {
    let id: UUID
    let plate: String
    let startedAt: Date

    /// Whole seconds: the stores encode dates as ISO 8601, which drops fractions.
    static let sample = StoredTicket(
        id: UUID(),
        plate: "AA-00-BB",
        startedAt: Date(timeIntervalSince1970: 1_755_000_000)
    )
}

/// A unique directory under the temporary directory, deliberately not created on disk.
func makeTemporaryDirectoryURL() -> URL {
    FileManager.default.temporaryDirectory
        .appending(path: "ParkingAppTests-\(UUID().uuidString)")
}
