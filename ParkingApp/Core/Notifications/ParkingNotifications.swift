import Foundation
import UserNotifications

/// Local reminders for parking that is about to run out.
///
/// Permission is asked for the first time there is something worth scheduling, rather
/// than at launch, so the request arrives with a reason attached.
struct ParkingNotifications: Sendable {
    private static let reminderIdentifier = "parking.reminder"
    private static let expiryIdentifier = "parking.expiry"

    /// Replaces any pending reminders with ones matching `session`. Passing nil just
    /// clears them, which is what happens when parking ends.
    func reschedule(for session: ParkingSession?, now: Date = Date()) async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(
            withIdentifiers: [Self.reminderIdentifier, Self.expiryIdentifier]
        )

        guard let session else { return }

        let plan = ParkingReminder.plan(for: session, at: now)
        guard !plan.isEmpty, await isAuthorized() else { return }

        let minutes = Int(ParkingReminder.leadTime / 60)

        if let delay = plan.reminderDelay {
            await add(
                identifier: Self.reminderIdentifier,
                title: "Parking ends soon",
                body: "\(session.vehicle.licensePlate) at \(session.lot.name) ends in \(minutes) minutes.",
                after: delay
            )
        }

        if let delay = plan.expiryDelay {
            await add(
                identifier: Self.expiryIdentifier,
                title: "Parking has ended",
                body: "\(session.vehicle.licensePlate) at \(session.lot.name).",
                after: delay
            )
        }
    }

    private func isAuthorized() async -> Bool {
        let center = UNUserNotificationCenter.current()

        switch await center.notificationSettings().authorizationStatus {
        case .notDetermined:
            return (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
        case .authorized, .provisional, .ephemeral:
            return true
        default:
            return false
        }
    }

    private func add(identifier: String, title: String, body: String, after delay: TimeInterval) async {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            // A trigger needs a positive interval, however little time is left.
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: max(1, delay), repeats: false)
        )

        try? await UNUserNotificationCenter.current().add(request)
    }
}
