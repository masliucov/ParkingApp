import Foundation
import Observation

@MainActor
@Observable
final class SignUpViewModel {
    var name = ""
    var email = ""
    var password = ""
    var passwordConfirmation = ""

    private(set) var errorMessage: String?

    private let authService: AuthService
    private let onAuthenticated: (User) -> Void

    init(authService: AuthService, onAuthenticated: @escaping (User) -> Void) {
        self.authService = authService
        self.onAuthenticated = onAuthenticated
    }

    /// Only blocks on empty fields. The real rules run on submit, so the user gets a
    /// message instead of a dead button.
    var canSubmit: Bool {
        !name.isEmpty && !email.isEmpty && !password.isEmpty && !passwordConfirmation.isEmpty
    }

    func submit() {
        do {
            let user = try authService.signUp(
                name: name,
                email: email,
                password: password,
                confirmation: passwordConfirmation
            )
            errorMessage = nil
            onAuthenticated(user)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
