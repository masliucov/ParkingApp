import Foundation
import Observation

@MainActor
@Observable
final class HomeViewModel {
    private(set) var activeSessions: [ParkingSession] = []
    private(set) var errorMessage: String?

    private let sessionService: ParkingSessionService
    private let notifications: ParkingNotifications
    private let userID: UUID

    init(
        sessionService: ParkingSessionService,
        notifications: ParkingNotifications,
        userID: UUID
    ) {
        self.sessionService = sessionService
        self.notifications = notifications
        self.userID = userID
    }

    /// Changes whenever a stay starts, ends or gains time, so the wait below restarts.
    var expiryKey: String {
        activeSessions
            .map { "\($0.id.uuidString):\(Int($0.expiresAt.timeIntervalSince1970))" }
            .joined(separator: "|")
    }

    /// Reads what is parked and puts the reminders in step with it. Every path that
    /// changes parking ends up here, so there is one place where the two can disagree.
    func refresh() async {
        do {
            activeSessions = try sessionService.activeSessions(for: userID)
            errorMessage = nil
        } catch {
            activeSessions = []
            errorMessage = error.localizedDescription
        }

        await notifications.reschedule(for: activeSessions)
    }

    /// Waits for the next stay to run out, then refreshes so its card disappears the
    /// moment the time is up.
    func waitForExpiry() async {
        guard let next = activeSessions.map(\.expiresAt).min() else { return }

        let remaining = max(0, next.timeIntervalSince(Date()))
        guard remaining > 0 else {
            await refresh()
            return
        }

        try? await Task.sleep(for: .seconds(remaining))
        guard !Task.isCancelled else { return }

        await refresh()
    }
}
