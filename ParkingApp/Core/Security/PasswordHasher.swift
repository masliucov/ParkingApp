import CryptoKit
import Foundation

/// Salted SHA-256 password hashing.
///
/// Accounts live on this device, so there is no server to authenticate against.
/// A shipping app needs a backend and a slow hash (PBKDF2, scrypt, Argon2): SHA-256 is
/// fast, which makes offline brute force cheap.
enum PasswordHasher {
    /// A fresh 256-bit random salt, base64 encoded.
    static func makeSalt() -> String {
        SymmetricKey(size: .bits256).withUnsafeBytes { Data($0).base64EncodedString() }
    }

    /// Base64 encoded SHA-256 digest of `salt + password`.
    static func hash(password: String, salt: String) -> String {
        let digest = SHA256.hash(data: Data((salt + password).utf8))
        return Data(digest).base64EncodedString()
    }

    /// Whether `password` reproduces `expectedHash` under `salt`.
    static func verify(password: String, salt: String, expectedHash: String) -> Bool {
        areEqual(hash(password: password, salt: salt), expectedHash)
    }

    /// Compares every byte, so timing does not reveal where the first difference is.
    private static func areEqual(_ lhs: String, _ rhs: String) -> Bool {
        let left = Array(lhs.utf8)
        let right = Array(rhs.utf8)
        guard left.count == right.count else { return false }

        var difference: UInt8 = 0
        for (leftByte, rightByte) in zip(left, right) {
            difference |= leftByte ^ rightByte
        }
        return difference == 0
    }
}
