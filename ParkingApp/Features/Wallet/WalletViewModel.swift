import Foundation
import Observation

/// The balance as the screens see it.
///
/// Held above the map rather than inside each sheet, so the amount in the corner, the
/// warning on the paying screens and the money actually in the store never disagree.
@MainActor
@Observable
final class WalletViewModel {
    private(set) var balance: Decimal = 0
    private(set) var errorMessage: String?

    private let service: WalletService
    private let userID: UUID

    init(service: WalletService, userID: UUID) {
        self.service = service
        self.userID = userID
    }

    var formattedBalance: String {
        ParkingPricing.formatted(balance)
    }

    /// Where the balance lands if `amount` goes in, shown before the driver commits to it.
    func formattedBalance(after amount: TopUpAmount) -> String {
        ParkingPricing.formatted(balance + amount.amount)
    }

    /// Read after anything that spends money, so the corner of the screen keeps up.
    func load() {
        do {
            balance = try service.balance(for: userID)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Returns whether the money went in, so the screen only closes when it did.
    func add(_ amount: TopUpAmount) -> Bool {
        do {
            balance = try service.add(amount.amount, userID: userID).balance
            errorMessage = nil
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func dismissError() {
        errorMessage = nil
    }
}
