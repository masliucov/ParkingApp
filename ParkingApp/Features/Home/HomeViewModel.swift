import Foundation
import Observation

@MainActor
@Observable
final class HomeViewModel {
    private(set) var activeSession: ParkingSession?
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

    /// Reads the running session and puts the reminders in step with it. Every path that
    /// changes parking ends up here, so there is one place where the two can disagree.
    func refresh() async {
        do {
            activeSession = try sessionService.activeSession(for: userID)
            errorMessage = nil
        } catch {
            activeSession = nil
            errorMessage = error.localizedDescription
        }

        await notifications.reschedule(for: activeSession)
    }

    /// Waits out the running session, then refreshes so the card disappears the moment
    /// the time is up.
    func waitForExpiry() async {
        guard let session = activeSession else { return }

        let remaining = session.remainingTime(at: Date())
        guard remaining > 0 else {
            await refresh()
            return
        }

        try? await Task.sleep(for: .seconds(remaining))
        guard !Task.isCancelled else { return }

        await refresh()
    }
}
