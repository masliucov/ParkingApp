import Foundation

/// Remembers which account is signed in between launches.
struct SessionStore: Sendable {
    private struct Session: Codable, Equatable {
        let userID: UUID
    }

    static let storageKey = "session"

    let store: KeyValueStore

    func currentUserID() throws -> UUID? {
        try store.read(Session.self, forKey: Self.storageKey)?.userID
    }

    func save(userID: UUID) throws {
        try store.write(Session(userID: userID), forKey: Self.storageKey)
    }

    func clear() throws {
        try store.removeValue(forKey: Self.storageKey)
    }
}
