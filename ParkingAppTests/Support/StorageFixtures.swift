import Foundation

/// A small `Codable` value used to exercise the storage layer.
struct StoredTicket: Codable, Equatable {
    let id: UUID
    let plate: String
    let startedAt: Date

    /// `startedAt` uses whole seconds because the stores encode dates as ISO 8601,
    /// which does not preserve fractional seconds.
    static let sample = StoredTicket(
        id: UUID(),
        plate: "AA-00-BB",
        startedAt: Date(timeIntervalSince1970: 1_755_000_000)
    )
}

/// A unique directory under the system temporary directory. It is not created on disk,
/// which lets tests verify that the store creates it on demand.
func makeTemporaryDirectoryURL() -> URL {
    FileManager.default.temporaryDirectory
        .appending(path: "ParkingAppTests-\(UUID().uuidString)")
}
