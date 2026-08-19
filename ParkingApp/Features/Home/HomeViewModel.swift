import Foundation
import Observation

@MainActor
@Observable
final class HomeViewModel {
    private(set) var activeSession: ParkingSession?
    private(set) var errorMessage: String?

    private let sessionService: ParkingSessionService
    private let userID: UUID

    init(sessionService: ParkingSessionService, userID: UUID) {
        self.sessionService = sessionService
        self.userID = userID
    }

    func refresh() {
        do {
            activeSession = try sessionService.activeSession(for: userID)
            errorMessage = nil
        } catch {
            activeSession = nil
            errorMessage = error.localizedDescription
        }
    }

    /// Waits out the running session, then refreshes so the card disappears the moment
    /// the time is up.
    func waitForExpiry() async {
        guard let session = activeSession else { return }

        let remaining = session.remainingTime(at: Date())
        guard remaining > 0 else {
            refresh()
            return
        }

        try? await Task.sleep(for: .seconds(remaining))
        guard !Task.isCancelled else { return }

        refresh()
    }
}
