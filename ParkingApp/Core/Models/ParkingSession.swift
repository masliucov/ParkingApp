import Foundation

/// A paid stay at a parking spot.
///
/// The vehicle and the spot are copies, not references: a spot will not be found again
/// by the next search, and a vehicle can be deleted mid-stay.
struct ParkingSession: Codable, Equatable, Identifiable, Sendable {
    let id: UUID
    let userID: UUID
    let vehicle: Vehicle
    let lot: ParkingLot
    let startedAt: Date
    let expiresAt: Date
    let amountPaid: Decimal

    func isActive(at date: Date) -> Bool {
        date < expiresAt
    }

    func remainingTime(at date: Date) -> TimeInterval {
        max(0, expiresAt.timeIntervalSince(date))
    }

    /// Counts down as hours, minutes and seconds.
    func formattedRemainingTime(at date: Date) -> String {
        Duration.seconds(Int(remainingTime(at: date)))
            .formatted(.time(pattern: .hourMinuteSecond))
    }

    var formattedAmountPaid: String {
        ParkingPricing.formatted(amountPaid)
    }
}
