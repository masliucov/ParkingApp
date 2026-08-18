import Foundation

/// Validates and normalizes what the user typed, before anything is stored.
enum AuthValidator {
    static let minimumPasswordLength = 8
    static let maximumPasswordLength = 128
    static let maximumNameLength = 60
    static let maximumEmailLength = 254

    /// Trims the name and rejects an empty or over-long one.
    static func validateName(_ rawName: String) throws -> String {
        let name = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty, name.count <= maximumNameLength else {
            throw AuthError.invalidName
        }
        return name
    }

    /// Trims and lowercases only. Used on sign in, where a malformed address must fail
    /// exactly like an unknown one.
    static func normalize(_ rawEmail: String) -> String {
        rawEmail.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    /// Normalizes and rejects anything that is not a plausible address.
    static func validateEmail(_ rawEmail: String) throws -> String {
        let email = normalize(rawEmail)
        guard email.count <= maximumEmailLength, isPlausibleEmail(email) else {
            throw AuthError.invalidEmail
        }
        return email
    }

    /// Requires length plus at least one letter and one number.
    static func validatePassword(_ password: String) throws -> String {
        guard password.count >= minimumPasswordLength,
              password.count <= maximumPasswordLength,
              password.contains(where: \.isLetter),
              password.contains(where: \.isNumber) else {
            throw AuthError.weakPassword
        }
        return password
    }

    /// Shape check only: one `@`, a non-empty local part, and a domain with at least two
    /// non-empty labels.
    private static func isPlausibleEmail(_ email: String) -> Bool {
        guard !email.contains(where: \.isWhitespace) else { return false }

        let parts = email.split(separator: "@", omittingEmptySubsequences: false)
        guard parts.count == 2, !parts[0].isEmpty else { return false }

        let domainLabels = parts[1].split(separator: ".", omittingEmptySubsequences: false)
        guard domainLabels.count >= 2 else { return false }
        return domainLabels.allSatisfy { !$0.isEmpty }
    }
}
