import Foundation
import Observation

@MainActor
@Observable
final class ParkingHistoryViewModel {
    private(set) var sessions: [ParkingSession] = []
    private(set) var errorMessage: String?

    private let sessionService: ParkingSessionService
    private let userID: UUID

    init(sessionService: ParkingSessionService, userID: UUID) {
        self.sessionService = sessionService
        self.userID = userID
    }

    func load() {
        do {
            sessions = try sessionService.sessions(for: userID)
            errorMessage = nil
        } catch {
            sessions = []
            errorMessage = error.localizedDescription
        }
    }
}
