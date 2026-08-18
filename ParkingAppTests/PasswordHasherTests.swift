import Foundation
import Testing
@testable import ParkingApp

@Suite("PasswordHasher")
struct PasswordHasherTests {

    @Test("produces the same hash for the same password and salt")
    func hashIsDeterministic() {
        // Arrange
        let salt = PasswordHasher.makeSalt()

        // Act
        let first = PasswordHasher.hash(password: "parking123", salt: salt)
        let second = PasswordHasher.hash(password: "parking123", salt: salt)

        // Assert
        #expect(first == second)
    }

    @Test("produces different hashes for the same password under different salts")
    func hashDependsOnSalt() {
        // Arrange
        let password = "parking123"

        // Act
        let first = PasswordHasher.hash(password: password, salt: PasswordHasher.makeSalt())
        let second = PasswordHasher.hash(password: password, salt: PasswordHasher.makeSalt())

        // Assert
        #expect(first != second)
    }

    @Test("never stores the password itself")
    func hashDoesNotContainPassword() {
        // Arrange
        let password = "parking123"

        // Act
        let hash = PasswordHasher.hash(password: password, salt: PasswordHasher.makeSalt())

        // Assert
        #expect(!hash.contains(password))
    }

    @Test("verifies the correct password")
    func verifyAcceptsCorrectPassword() {
        // Arrange
        let salt = PasswordHasher.makeSalt()
        let hash = PasswordHasher.hash(password: "parking123", salt: salt)

        // Act
        let isValid = PasswordHasher.verify(password: "parking123", salt: salt, expectedHash: hash)

        // Assert
        #expect(isValid)
    }

    @Test("rejects a wrong password")
    func verifyRejectsWrongPassword() {
        // Arrange
        let salt = PasswordHasher.makeSalt()
        let hash = PasswordHasher.hash(password: "parking123", salt: salt)

        // Act
        let isValid = PasswordHasher.verify(password: "parking124", salt: salt, expectedHash: hash)

        // Assert
        #expect(!isValid)
    }

    @Test("generates a different salt every time")
    func saltsAreUnique() {
        // Act
        let salts = Set((0..<50).map { _ in PasswordHasher.makeSalt() })

        // Assert
        #expect(salts.count == 50)
    }
}
