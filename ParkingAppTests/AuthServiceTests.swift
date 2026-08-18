import Foundation
import Testing
@testable import ParkingApp

@Suite("AuthService")
struct AuthServiceTests {

    // MARK: - Sign up

    @Test("creates an account and signs it in")
    func signUpCreatesAccountAndSession() throws {
        // Arrange
        let service = makeService()

        // Act
        let user = try service.signUp(
            name: "  Ana Silva ",
            email: " Ana@Example.com ",
            password: "parking123",
            confirmation: "parking123"
        )

        // Assert
        #expect(user.name == "Ana Silva")
        #expect(user.email == "ana@example.com")
        #expect(try service.restoreSession() == user)
    }

    @Test("rejects an email that is already registered, ignoring case")
    func signUpRejectsDuplicateEmail() throws {
        // Arrange
        let service = makeService()
        _ = try service.signUp(
            name: "Ana Silva",
            email: "ana@example.com",
            password: "parking123",
            confirmation: "parking123"
        )

        // Act & Assert
        #expect(throws: AuthError.emailAlreadyRegistered) {
            try service.signUp(
                name: "Ana Costa",
                email: "ANA@example.com",
                password: "parking456",
                confirmation: "parking456"
            )
        }
    }

    @Test("rejects a confirmation that does not match the password")
    func signUpRejectsMismatchedConfirmation() {
        // Arrange
        let service = makeService()

        // Act & Assert
        #expect(throws: AuthError.passwordsDoNotMatch) {
            try service.signUp(
                name: "Ana Silva",
                email: "ana@example.com",
                password: "parking123",
                confirmation: "parking124"
            )
        }
    }

    @Test("rejects an invalid email before touching storage")
    func signUpRejectsInvalidEmail() throws {
        // Arrange
        let store = InMemoryKeyValueStore()
        let service = makeService(store: store)

        // Act & Assert
        #expect(throws: AuthError.invalidEmail) {
            try service.signUp(
                name: "Ana Silva",
                email: "ana@example",
                password: "parking123",
                confirmation: "parking123"
            )
        }
        #expect(try store.read([StoredAccount].self, forKey: StoredUserRepository.storageKey) == nil)
    }

    @Test("rejects a weak password")
    func signUpRejectsWeakPassword() {
        // Arrange
        let service = makeService()

        // Act & Assert
        #expect(throws: AuthError.weakPassword) {
            try service.signUp(
                name: "Ana Silva",
                email: "ana@example.com",
                password: "short1",
                confirmation: "short1"
            )
        }
    }

    @Test("stores the password as a salted hash, never in plain text")
    func signUpDoesNotStorePlainPassword() throws {
        // Arrange
        let store = InMemoryKeyValueStore()
        let service = makeService(store: store)

        // Act
        _ = try service.signUp(
            name: "Ana Silva",
            email: "ana@example.com",
            password: "parking123",
            confirmation: "parking123"
        )

        // Assert
        let accounts = try #require(
            try store.read([StoredAccount].self, forKey: StoredUserRepository.storageKey)
        )
        let account = try #require(accounts.first)
        #expect(account.passwordHash != "parking123")
        #expect(account.passwordSalt != "parking123")
        #expect(
            account.passwordHash == PasswordHasher.hash(
                password: "parking123",
                salt: account.passwordSalt
            )
        )
    }

    // MARK: - Sign in

    @Test("signs in with the correct credentials, ignoring email case")
    func signInAcceptsCorrectCredentials() throws {
        // Arrange
        let store = InMemoryKeyValueStore()
        let created = try makeService(store: store).signUp(
            name: "Ana Silva",
            email: "ana@example.com",
            password: "parking123",
            confirmation: "parking123"
        )
        let service = makeService(store: store)

        // Act
        let user = try service.signIn(email: " ANA@Example.com ", password: "parking123")

        // Assert
        #expect(user == created)
    }

    @Test("rejects a wrong password")
    func signInRejectsWrongPassword() throws {
        // Arrange
        let store = InMemoryKeyValueStore()
        _ = try makeService(store: store).signUp(
            name: "Ana Silva",
            email: "ana@example.com",
            password: "parking123",
            confirmation: "parking123"
        )
        let service = makeService(store: store)

        // Act & Assert
        #expect(throws: AuthError.invalidCredentials) {
            try service.signIn(email: "ana@example.com", password: "parking124")
        }
    }

    @Test("reports an unknown email exactly like a wrong password")
    func signInRejectsUnknownEmailTheSameWay() {
        // Arrange
        let service = makeService()

        // Act & Assert
        #expect(throws: AuthError.invalidCredentials) {
            try service.signIn(email: "nobody@example.com", password: "parking123")
        }
    }

    // MARK: - Session

    @Test("restores the signed-in user in a later launch")
    func restoresSessionAcrossLaunches() throws {
        // Arrange
        let store = InMemoryKeyValueStore()
        let created = try makeService(store: store).signUp(
            name: "Ana Silva",
            email: "ana@example.com",
            password: "parking123",
            confirmation: "parking123"
        )

        // Act
        let restored = try makeService(store: store).restoreSession()

        // Assert
        #expect(restored == created)
    }

    @Test("has no session before anyone signs in")
    func hasNoSessionInitially() throws {
        // Arrange
        let service = makeService()

        // Act & Assert
        #expect(try service.restoreSession() == nil)
    }

    @Test("forgets the user after signing out")
    func signOutClearsSession() throws {
        // Arrange
        let store = InMemoryKeyValueStore()
        let service = makeService(store: store)
        _ = try service.signUp(
            name: "Ana Silva",
            email: "ana@example.com",
            password: "parking123",
            confirmation: "parking123"
        )

        // Act
        try service.signOut()

        // Assert
        #expect(try service.restoreSession() == nil)
        #expect(try makeService(store: store).restoreSession() == nil)
    }

    @Test("drops a session pointing at an account that no longer exists")
    func restoreSessionClearsStalePointer() throws {
        // Arrange
        let store = InMemoryKeyValueStore()
        let service = makeService(store: store)
        try SessionStore(store: store).save(userID: UUID())

        // Act
        let restored = try service.restoreSession()

        // Assert
        #expect(restored == nil)
        #expect(try SessionStore(store: store).currentUserID() == nil)
    }

    // MARK: - Helpers

    private func makeService(store: KeyValueStore = InMemoryKeyValueStore()) -> AuthService {
        AuthService(
            repository: StoredUserRepository(store: store),
            sessionStore: SessionStore(store: store)
        )
    }
}
