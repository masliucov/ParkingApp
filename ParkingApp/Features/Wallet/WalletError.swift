import Foundation

/// Everything that can stop money moving in or out of a balance.
enum WalletError: LocalizedError, Equatable {
    case invalidAmount
    /// Carries what is missing, so the driver is told the number they need rather than
    /// just that they are short.
    case insufficientFunds(shortfall: Decimal)

    var errorDescription: String? {
        switch self {
        case .invalidAmount:
            return "Please choose an amount to add to your balance."
        case .insufficientFunds(let shortfall):
            return "Not enough balance. Add \(ParkingPricing.formatted(shortfall)) or more to pay for this."
        }
    }
}
