import Foundation
import UserNotifications

/// Local reminders for parking that is about to run out.
///
/// Permission is asked for the first time there is something worth scheduling, rather
/// than at launch, so the request arrives with a reason attached.
struct ParkingNotifications: Sendable {
    /// Every reminder this app schedules carries this prefix, which is what makes it
    /// safe to clear them all and rebuild from the sessions that are actually running.
    private static let identifierPrefix = "parking."

    /// Replaces the pending reminders with ones matching `sessions`. An empty list just
    /// clears them, which is what happens when the last stay ends.
    func reschedule(for sessions: [ParkingSession], now: Date = Date()) async {
        let center = UNUserNotificationCenter.current()
        await clearPendingReminders(in: center)

        let plans = sessions.map { ($0, ParkingReminder.plan(for: $0, at: now)) }
            .filter { !$0.1.isEmpty }

        guard !plans.isEmpty, await isAuthorized() else { return }

        let minutes = Int(ParkingReminder.leadTime / 60)

        for (session, plan) in plans {
            let plate = session.vehicle.licensePlate

            if let delay = plan.reminderDelay {
                await add(
                    identifier: "\(Self.identifierPrefix)reminder.\(session.id.uuidString)",
                    title: "Parking ends soon",
                    body: "\(plate) at \(session.lot.name) ends in \(minutes) minutes.",
                    after: delay
                )
            }

            if let delay = plan.expiryDelay {
                await add(
                    identifier: "\(Self.identifierPrefix)expiry.\(session.id.uuidString)",
                    title: "Parking has ended",
                    body: "\(plate) at \(session.lot.name).",
                    after: delay
                )
            }
        }
    }

    private func clearPendingReminders(in center: UNUserNotificationCenter) async {
        let identifiers = await center.pendingNotificationRequests()
            .map(\.identifier)
            .filter { $0.hasPrefix(Self.identifierPrefix) }

        guard !identifiers.isEmpty else { return }
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
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
