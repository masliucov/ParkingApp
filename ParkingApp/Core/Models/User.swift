import Foundation

/// A registered account, as the rest of the app sees it.
struct User: Codable, Equatable, Identifiable, Sendable {
    let id: UUID
    let name: String
    /// Always normalized: trimmed and lowercased.
    let email: String
    let createdAt: Date
}

/// An account as persisted. Stays inside `AuthService` and `UserRepository`, so password
/// material never reaches a view.
struct StoredAccount: Codable, Equatable, Identifiable, Sendable {
    var id: UUID { user.id }

    let user: User
    /// Base64 random salt, unique per account.
    let passwordSalt: String
    /// Base64 SHA-256 of salt + password.
    let passwordHash: String
}
