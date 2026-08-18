import Foundation

/// Account creation and sign in. Everything stays on the device — see `PasswordHasher`.
struct AuthService: Sendable {
    let repository: UserRepository
    let sessionStore: SessionStore

    /// Creates an account and signs it in.
    func signUp(name rawName: String, email rawEmail: String, password: String, confirmation: String) throws -> User {
        let name = try AuthValidator.validateName(rawName)
        let email = try AuthValidator.validateEmail(rawEmail)
        _ = try AuthValidator.validatePassword(password)

        guard password == confirmation else { throw AuthError.passwordsDoNotMatch }
        guard try repository.account(withEmail: email) == nil else {
            throw AuthError.emailAlreadyRegistered
        }

        let salt = PasswordHasher.makeSalt()
        let account = StoredAccount(
            user: User(id: UUID(), name: name, email: email, createdAt: .storageNow()),
            passwordSalt: salt,
            passwordHash: PasswordHasher.hash(password: password, salt: salt)
        )

        try repository.save(account)
        try sessionStore.save(userID: account.user.id)
        return account.user
    }

    /// An unknown email and a wrong password fail the same way, so the app never reveals
    /// which addresses are registered.
    func signIn(email rawEmail: String, password: String) throws -> User {
        let email = AuthValidator.normalize(rawEmail)

        guard let account = try repository.account(withEmail: email),
              PasswordHasher.verify(
                  password: password,
                  salt: account.passwordSalt,
                  expectedHash: account.passwordHash
              ) else {
            throw AuthError.invalidCredentials
        }

        try sessionStore.save(userID: account.user.id)
        return account.user
    }

    /// Changes the display name, keeping every other detail of the account.
    func updateName(_ rawName: String, for user: User) throws -> User {
        let name = try AuthValidator.validateName(rawName)

        guard let account = try repository.account(withID: user.id) else {
            throw AuthError.accountNotFound
        }

        let updated = StoredAccount(
            user: User(
                id: account.user.id,
                name: name,
                email: account.user.email,
                createdAt: account.user.createdAt
            ),
            passwordSalt: account.passwordSalt,
            passwordHash: account.passwordHash
        )
        try repository.save(updated)
        return updated.user
    }

    func signOut() throws {
        try sessionStore.clear()
    }

    /// The signed-in user from a previous launch, if the account still exists.
    func restoreSession() throws -> User? {
        guard let id = try sessionStore.currentUserID() else { return nil }

        guard let account = try repository.account(withID: id) else {
            // The account is gone; drop the stale pointer.
            try sessionStore.clear()
            return nil
        }
        return account.user
    }
}
