import Foundation
import Observation

@MainActor
@Observable
final class SignInViewModel {
    var email = ""
    var password = ""

    private(set) var errorMessage: String?

    private let authService: AuthService
    private let onAuthenticated: (User) -> Void

    init(authService: AuthService, onAuthenticated: @escaping (User) -> Void) {
        self.authService = authService
        self.onAuthenticated = onAuthenticated
    }

    var canSubmit: Bool {
        !email.isEmpty && !password.isEmpty
    }

    func submit() {
        do {
            let user = try authService.signIn(email: email, password: password)
            errorMessage = nil
            onAuthenticated(user)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
