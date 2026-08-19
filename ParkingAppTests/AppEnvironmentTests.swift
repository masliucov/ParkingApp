import Foundation
import Testing
@testable import ParkingApp

@Suite("AppEnvironment")
@MainActor
struct AppEnvironmentTests {

    @Test("puts the signed-in user back as it is built, before any screen is drawn")
    func restoresSessionWhenBuilt() throws {
        // Arrange: an account signed in against a store that outlives this environment
        let store = InMemoryKeyValueStore()
        let signedUp = try AppEnvironment(store: store).authService.signUp(
            name: "Ana Silva",
            email: "ana@example.com",
            password: "parking123",
            confirmation: "parking123"
        )

        // Act: what happens on the next launch
        let relaunched = AppEnvironment(store: store)

        // Assert: nil here would show the sign-in screen for a frame before correcting
        #expect(relaunched.currentUser == signedUp)
    }

    @Test("starts signed out when nothing was stored")
    func startsSignedOutWithoutASession() {
        // Act
        let environment = AppEnvironment(store: InMemoryKeyValueStore())

        // Assert
        #expect(environment.currentUser == nil)
    }

    @Test("forgets the user after signing out")
    func forgetsUserAfterSignOut() throws {
        // Arrange
        let store = InMemoryKeyValueStore()
        let environment = AppEnvironment(store: store)
        _ = try environment.authService.signUp(
            name: "Ana Silva",
            email: "ana@example.com",
            password: "parking123",
            confirmation: "parking123"
        )

        // Act
        environment.signOut()

        // Assert: and the next launch stays out too
        #expect(environment.currentUser == nil)
        #expect(AppEnvironment(store: store).currentUser == nil)
    }
}
