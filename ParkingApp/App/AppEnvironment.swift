import Foundation
import Observation

/// Builds the app's dependencies once and holds the signed-in user.
@MainActor
@Observable
final class AppEnvironment {
    let authService: AuthService
    let vehicleService: VehicleService
    let sessionService: ParkingSessionService
    let locationProvider = LocationProvider()

    private(set) var currentUser: User?
    private(set) var errorMessage: String?

    init(store: KeyValueStore) {
        authService = AuthService(
            repository: StoredUserRepository(store: store),
            sessionStore: SessionStore(store: store)
        )
        vehicleService = VehicleService(repository: StoredVehicleRepository(store: store))
        sessionService = ParkingSessionService(
            repository: StoredParkingSessionRepository(store: store)
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

    /// Used after signing in and after the profile is edited.
    func setCurrentUser(_ user: User) {
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
