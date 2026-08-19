import Foundation
import Testing
@testable import ParkingApp

@Suite("ParkingReminder")
struct ParkingReminderTests {

    private let now = Date(timeIntervalSince1970: 1_755_000_000)

    @Test("warns ten minutes before the end, and again at the end")
    func plansBothReminders() {
        // Arrange
        let session = makeSession(minutesRemaining: 60)

        // Act
        let plan = ParkingReminder.plan(for: session, at: now)

        // Assert
        #expect(plan.reminderDelay == minutes(50))
        #expect(plan.expiryDelay == minutes(60))
    }

    @Test("skips the early warning when less than the lead time is left")
    func skipsReminderWhenTooLate() {
        // Arrange
        let session = makeSession(minutesRemaining: 5)

        // Act
        let plan = ParkingReminder.plan(for: session, at: now)

        // Assert
        #expect(plan.reminderDelay == nil)
        #expect(plan.expiryDelay == minutes(5))
    }

    @Test("skips the early warning when exactly the lead time is left")
    func skipsReminderAtExactlyTheLeadTime() {
        // Arrange
        let session = makeSession(minutesRemaining: 10)

        // Act
        let plan = ParkingReminder.plan(for: session, at: now)

        // Assert
        #expect(plan.reminderDelay == nil)
        #expect(plan.expiryDelay == ParkingReminder.leadTime)
    }

    @Test("plans nothing for parking that has already ended")
    func plansNothingWhenExpired() {
        // Arrange
        let session = makeSession(minutesRemaining: -1)

        // Act
        let plan = ParkingReminder.plan(for: session, at: now)

        // Assert
        #expect(plan.isEmpty)
    }

    @Test("pushes both reminders back when time is added")
    func followsAnExtendedSession() {
        // Arrange
        let session = makeSession(minutesRemaining: 60)
        let extended = makeSession(minutesRemaining: 120)

        // Act
        let before = ParkingReminder.plan(for: session, at: now)
        let after = ParkingReminder.plan(for: extended, at: now)

        // Assert
        #expect(after.reminderDelay == minutes(110))
        #expect((after.expiryDelay ?? 0) > (before.expiryDelay ?? 0))
    }

    // MARK: - Helpers

    private func minutes(_ count: Int) -> TimeInterval {
        TimeInterval(count * 60)
    }

    private func makeSession(minutesRemaining: Int) -> ParkingSession {
        ParkingSession(
            id: UUID(),
            userID: UUID(),
            vehicle: Vehicle(
                id: UUID(),
                ownerID: UUID(),
                model: "Renault Clio",
                licensePlate: "AA-00-BB",
                createdAt: now
            ),
            lot: ParkingLot(
                id: "Rua Augusta@38.71120,-9.13760",
                name: "Rua Augusta",
                latitude: 38.7112,
                longitude: -9.1376,
                hourlyRate: .cents(120),
                availableSpaces: 8,
                totalSpaces: 40
            ),
            startedAt: now,
            expiresAt: now.addingTimeInterval(minutes(minutesRemaining)),
            amountPaid: .cents(120)
        )
    }
}
