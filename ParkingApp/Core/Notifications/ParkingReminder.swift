import Foundation

/// Decides when to warn a driver that their parking is running out.
enum ParkingReminder {
    /// How far ahead of the end the warning goes out.
    static let leadTime: TimeInterval = 10 * 60

    struct Plan: Equatable, Sendable {
        /// Seconds from now, or nil when there is not enough time left to warn ahead.
        let reminderDelay: TimeInterval?
        /// Seconds from now, or nil when the parking has already ended.
        let expiryDelay: TimeInterval?

        static let none = Plan(reminderDelay: nil, expiryDelay: nil)

        var isEmpty: Bool {
            reminderDelay == nil && expiryDelay == nil
        }
    }

    static func plan(for session: ParkingSession, at now: Date) -> Plan {
        let remaining = session.remainingTime(at: now)
        guard remaining > 0 else { return .none }

        // Below the lead time there is no point warning "ends in 10 minutes".
        let reminderDelay = remaining > leadTime ? remaining - leadTime : nil
        return Plan(reminderDelay: reminderDelay, expiryDelay: remaining)
    }
}
