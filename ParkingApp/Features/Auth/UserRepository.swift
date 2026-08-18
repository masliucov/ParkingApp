import Foundation

/// Read and write access to accounts.
protocol UserRepository: Sendable {
    func account(withEmail email: String) throws -> StoredAccount?
    func account(withID id: UUID) throws -> StoredAccount?
    /// Inserts the account, or replaces the existing one with the same identifier.
    func save(_ account: StoredAccount) throws
}

/// Keeps every account in a single JSON document.
struct StoredUserRepository: UserRepository {
    static let storageKey = "accounts"

    let store: KeyValueStore

    func account(withEmail email: String) throws -> StoredAccount? {
        let normalized = AuthValidator.normalize(email)
        return try accounts().first { $0.user.email == normalized }
    }

    func account(withID id: UUID) throws -> StoredAccount? {
        try accounts().first { $0.user.id == id }
    }

    func save(_ account: StoredAccount) throws {
        let updated = try accounts().upserting(account)
        try store.write(updated, forKey: Self.storageKey)
    }

    private func accounts() throws -> [StoredAccount] {
        try store.read([StoredAccount].self, forKey: Self.storageKey) ?? []
    }
}
