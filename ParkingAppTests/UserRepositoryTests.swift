import Foundation
import Testing
@testable import ParkingApp

@Suite("StoredUserRepository")
struct UserRepositoryTests {

    @Test("finds a saved account by email")
    func findsAccountByEmail() throws {
        // Arrange
        let repository = StoredUserRepository(store: InMemoryKeyValueStore())
        let account = makeAccount(email: "ana@example.com")

        // Act
        try repository.save(account)
        let found = try repository.account(withEmail: "ana@example.com")

        // Assert
        #expect(found == account)
    }

    @Test("matches an email regardless of case and whitespace")
    func matchesEmailCaseInsensitively() throws {
        // Arrange
        let repository = StoredUserRepository(store: InMemoryKeyValueStore())
        let account = makeAccount(email: "ana@example.com")
        try repository.save(account)

        // Act
        let found = try repository.account(withEmail: "  ANA@Example.com ")

        // Assert
        #expect(found == account)
    }

    @Test("finds a saved account by identifier")
    func findsAccountByID() throws {
        // Arrange
        let repository = StoredUserRepository(store: InMemoryKeyValueStore())
        let account = makeAccount(email: "ana@example.com")
        try repository.save(account)

        // Act
        let found = try repository.account(withID: account.user.id)

        // Assert
        #expect(found == account)
    }

    @Test("returns nil for an unknown account")
    func returnsNilForUnknownAccount() throws {
        // Arrange
        let repository = StoredUserRepository(store: InMemoryKeyValueStore())

        // Act & Assert
        #expect(try repository.account(withEmail: "ana@example.com") == nil)
        #expect(try repository.account(withID: UUID()) == nil)
    }

    @Test("keeps accounts separate instead of overwriting them")
    func keepsMultipleAccounts() throws {
        // Arrange
        let repository = StoredUserRepository(store: InMemoryKeyValueStore())
        let first = makeAccount(email: "ana@example.com")
        let second = makeAccount(email: "bruno@example.com")

        // Act
        try repository.save(first)
        try repository.save(second)

        // Assert
        #expect(try repository.account(withEmail: "ana@example.com") == first)
        #expect(try repository.account(withEmail: "bruno@example.com") == second)
    }

    @Test("replaces the account that already has the same identifier")
    func replacesAccountWithSameID() throws {
        // Arrange
        let repository = StoredUserRepository(store: InMemoryKeyValueStore())
        let original = makeAccount(email: "ana@example.com")
        let renamed = StoredAccount(
            user: User(
                id: original.user.id,
                name: "Ana Costa",
                email: original.user.email,
                createdAt: original.user.createdAt
            ),
            passwordSalt: original.passwordSalt,
            passwordHash: original.passwordHash
        )
        try repository.save(original)

        // Act
        try repository.save(renamed)

        // Assert
        #expect(try repository.account(withID: original.user.id) == renamed)
    }

    @Test("keeps accounts across repository instances sharing a store")
    func persistsAcrossInstances() throws {
        // Arrange
        let store = InMemoryKeyValueStore()
        let account = makeAccount(email: "ana@example.com")
        try StoredUserRepository(store: store).save(account)

        // Act
        let found = try StoredUserRepository(store: store).account(withEmail: "ana@example.com")

        // Assert
        #expect(found == account)
    }

    // MARK: - Helpers

    private func makeAccount(email: String) -> StoredAccount {
        let salt = PasswordHasher.makeSalt()
        return StoredAccount(
            user: User(
                id: UUID(),
                name: "Ana Silva",
                email: email,
                createdAt: Date(timeIntervalSince1970: 1_755_000_000)
            ),
            passwordSalt: salt,
            passwordHash: PasswordHasher.hash(password: "parking123", salt: salt)
        )
    }
}
