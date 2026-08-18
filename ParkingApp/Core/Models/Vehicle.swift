import Foundation

/// A car registered by a user.
struct Vehicle: Codable, Equatable, Identifiable, Sendable {
    let id: UUID
    let ownerID: UUID
    /// Trimmed, as the user typed it.
    let model: String
    /// Normalized: uppercase, without spaces.
    let licensePlate: String
    let createdAt: Date
}
