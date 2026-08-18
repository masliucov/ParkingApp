import Foundation
import Observation

/// Builds the app's dependencies once and holds the signed-in user.
@MainActor
@Observable
final class AppEnvironment {
    let authService: AuthService

    private(set) var currentUser: User?
    private(set) var errorMessage: String?

    init(store: KeyValueStore) {
        authService = AuthService(
            repository: StoredUserRepository(store: store),
            sessionStore: SessionStore(store: store)
        )
    }

    /// Falls back to a memory store if Application Support cannot be opened, so storage
    /// trouble does not stop the app from launching.
    static func live() -> AppEnvironment {
        do {
            return AppEnvironment(store: try JSONFileStore.applicationSupport())
        } catch {
            let environment = AppEnvironment(store: InMemoryKeyValueStore())
            environment.errorMessage = error.localizedDescription
            return environment
        }
    }

    func restoreSession() {
        do {
            currentUser = try authService.restoreSession()
        } catch {
            currentUser = nil
            errorMessage = error.localizedDescription
        }
    }

    func signIn(_ user: User) {
        currentUser = user
    }

    func signOut() {
        do {
            try authService.signOut()
        } catch {
            errorMessage = error.localizedDescription
        }
        currentUser = nil
    }

    func dismissError() {
        errorMessage = nil
    }
}
