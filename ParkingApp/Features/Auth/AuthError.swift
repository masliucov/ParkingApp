import Foundation

/// Everything that can stop a sign up or sign in.
enum AuthError: LocalizedError, Equatable {
    case invalidName
    case invalidEmail
    case weakPassword
    case passwordsDoNotMatch
    case emailAlreadyRegistered
    case invalidCredentials

    var errorDescription: String? {
        switch self {
        case .invalidName:
            return "Please enter your name."
        case .invalidEmail:
            return "Please enter a valid email address."
        case .weakPassword:
            return "Your password needs at least \(AuthValidator.minimumPasswordLength) characters, including a letter and a number."
        case .passwordsDoNotMatch:
            return "The two passwords do not match."
        case .emailAlreadyRegistered:
            return "An account already exists for this email address."
        case .invalidCredentials:
            // Vague on purpose: a precise message would reveal which emails are registered.
            return "Email or password is incorrect."
        }
    }
}
