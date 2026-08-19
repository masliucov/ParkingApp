import Foundation
import Observation

@MainActor
@Observable
final class AddTimeViewModel {
    let session: ParkingSession

    var duration: ParkingDuration = .oneHour

    private(set) var errorMessage: String?

    private let sessionService: ParkingSessionService
    private let onExtended: () -> Void

    init(
        session: ParkingSession,
        sessionService: ParkingSessionService,
        onExtended: @escaping () -> Void
    ) {
        self.session = session
        self.sessionService = sessionService
        self.onExtended = onExtended
    }

    var price: Decimal {
        ParkingPricing.price(hourlyRate: session.lot.hourlyRate, minutes: duration.minutes)
    }

    var formattedPrice: String {
        ParkingPricing.formatted(price)
    }

    var payButtonTitle: String {
        "Pay \(formattedPrice)"
    }

    /// Extra time goes onto the end of the stay, not onto the current moment, so time
    /// already paid for is never lost.
    var formattedNewEndTime: String {
        session.expiresAt
            .addingTimeInterval(duration.timeInterval)
            .formatted(date: .omitted, time: .shortened)
    }

    var formattedCurrentEndTime: String {
        session.expiresAt.formatted(date: .omitted, time: .shortened)
    }

    func pay() {
        do {
            _ = try sessionService.extend(session, by: duration)
            errorMessage = nil
            onExtended()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
