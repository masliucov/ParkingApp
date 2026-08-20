import Foundation
import Observation

@MainActor
@Observable
final class AddTimeViewModel {
    let session: ParkingSession

    var duration: ParkingDuration = .oneHour
    /// Kept in step with the balance shown above the map, which is where it is topped up.
    var balance: Decimal = 0

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

    var formattedBalance: String {
        ParkingPricing.formatted(balance)
    }

    var hasEnoughBalance: Bool {
        balance >= price
    }

    /// Said before the driver taps Pay rather than after: an empty balance is the one thing
    /// stopping them that they can fix without leaving the screen.
    var balanceWarning: String? {
        guard !hasEnoughBalance else { return nil }
        let missing = ParkingPricing.formatted(price - balance)
        return "Not enough balance. Add \(missing) or more to buy this time."
    }

    var canPay: Bool {
        hasEnoughBalance
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
