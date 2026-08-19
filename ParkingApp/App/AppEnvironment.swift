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
    let notifications = ParkingNotifications()

    private(set) var currentUser: User?
    private(set) var errorMessage: String?

    init(store: KeyValueStore) {
        authService = AuthService(
            repository: StoredUserRepository(store: store),
            sessionStore: SessionStore(store: store)
        )
        let sessions = ParkingSessionService(
            repository: StoredParkingSessionRepository(store: store)
        )
        sessionService = sessions
        vehicleService = VehicleService(
            repository: StoredVehicleRepository(store: store),
            sessionService: sessions
        )

        // Restored here rather than when the first screen appears. Reading the stored
        // session is a local, synchronous lookup, and leaving it until then meant a frame
        // of the sign-in screen before the signed-in user was put back.
        restoreSession()
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

    private func restoreSession() {
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
