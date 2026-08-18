import Foundation

/// Read and write access to parking sessions.
protocol ParkingSessionRepository: Sendable {
    /// The user's sessions, newest first.
    func sessions(for userID: UUID) throws -> [ParkingSession]
    /// Inserts the session, or replaces the existing one with the same identifier.
    func save(_ session: ParkingSession) throws
}

/// Keeps every session in a single JSON document.
struct StoredParkingSessionRepository: ParkingSessionRepository {
    static let storageKey = "parkingSessions"

    let store: KeyValueStore

    func sessions(for userID: UUID) throws -> [ParkingSession] {
        try allSessions()
            .filter { $0.userID == userID }
            .sorted { $0.startedAt > $1.startedAt }
    }

    func save(_ session: ParkingSession) throws {
        let updated = try allSessions().upserting(session)
        try store.write(updated, forKey: Self.storageKey)
    }

    private func allSessions() throws -> [ParkingSession] {
        try store.read([ParkingSession].self, forKey: Self.storageKey) ?? []
    }
}
