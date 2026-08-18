import Foundation
import Testing
@testable import ParkingApp

@Suite("AuthValidator")
struct AuthValidatorTests {

    // MARK: - Name

    @Test("trims surrounding whitespace from the name")
    func trimsName() throws {
        // Act
        let name = try AuthValidator.validateName("  Ana Silva  ")

        // Assert
        #expect(name == "Ana Silva")
    }

    @Test("rejects a blank name", arguments: ["", "   ", "\n"])
    func rejectsBlankName(rawName: String) {
        // Act & Assert
        #expect(throws: AuthError.invalidName) {
            try AuthValidator.validateName(rawName)
        }
    }

    @Test("rejects a name longer than the maximum")
    func rejectsOverlongName() {
        // Arrange
        let rawName = String(repeating: "a", count: AuthValidator.maximumNameLength + 1)

        // Act & Assert
        #expect(throws: AuthError.invalidName) {
            try AuthValidator.validateName(rawName)
        }
    }

    // MARK: - Email

    @Test("normalizes the email to lowercase without whitespace")
    func normalizesEmail() throws {
        // Act
        let email = try AuthValidator.validateEmail("  Ana.Silva@Example.COM ")

        // Assert
        #expect(email == "ana.silva@example.com")
    }

    @Test(
        "accepts plausible addresses",
        arguments: ["ana@example.com", "ana.silva+parking@mail.example.co.uk", "a@b.co"]
    )
    func acceptsPlausibleEmails(rawEmail: String) throws {
        // Act
        let email = try AuthValidator.validateEmail(rawEmail)

        // Assert
        #expect(email == rawEmail.lowercased())
    }

    @Test(
        "rejects malformed addresses",
        arguments: ["", "ana", "ana@", "@example.com", "ana@example", "ana@.com", "ana@example.", "an a@example.com", "ana@@example.com"]
    )
    func rejectsMalformedEmails(rawEmail: String) {
        // Act & Assert
        #expect(throws: AuthError.invalidEmail) {
            try AuthValidator.validateEmail(rawEmail)
        }
    }

    @Test("rejects an email longer than the maximum")
    func rejectsOverlongEmail() {
        // Arrange
        let local = String(repeating: "a", count: AuthValidator.maximumEmailLength)
        let rawEmail = "\(local)@example.com"

        // Act & Assert
        #expect(throws: AuthError.invalidEmail) {
            try AuthValidator.validateEmail(rawEmail)
        }
    }

    // MARK: - Password

    @Test("accepts a password with letters, numbers and enough length")
    func acceptsStrongPassword() throws {
        // Act
        let password = try AuthValidator.validatePassword("parking123")

        // Assert
        #expect(password == "parking123")
    }

    @Test(
        "rejects passwords that are too short or miss a letter or a number",
        arguments: ["park12", "parkingapp", "12345678", ""]
    )
    func rejectsWeakPasswords(rawPassword: String) {
        // Act & Assert
        #expect(throws: AuthError.weakPassword) {
            try AuthValidator.validatePassword(rawPassword)
        }
    }

    @Test("rejects a password longer than the maximum")
    func rejectsOverlongPassword() {
        // Arrange
        let rawPassword = String(repeating: "a1", count: AuthValidator.maximumPasswordLength)

        // Act & Assert
        #expect(throws: AuthError.weakPassword) {
            try AuthValidator.validatePassword(rawPassword)
        }
    }
}
