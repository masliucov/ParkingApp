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
}
