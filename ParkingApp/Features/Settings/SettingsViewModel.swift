import Foundation
import Observation

@MainActor
@Observable
final class SettingsViewModel {
    var name: String

    private(set) var errorMessage: String?
    private(set) var successMessage: String?

    private let authService: AuthService
    private let user: User
    private let onUpdated: (User) -> Void
    private var savedName: String

    init(authService: AuthService, user: User, onUpdated: @escaping (User) -> Void) {
        self.authService = authService
        self.user = user
        self.onUpdated = onUpdated
        name = user.name
        savedName = user.name
    }

    var email: String {
        user.email
    }

    var canSubmit: Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && trimmed != savedName
    }

    func submit() {
        do {
            let updated = try authService.updateName(name, for: user)
            savedName = updated.name
            name = updated.name
            errorMessage = nil
            successMessage = "Your name has been updated."
            onUpdated(updated)
        } catch {
            successMessage = nil
            errorMessage = error.localizedDescription
        }
    }
}
