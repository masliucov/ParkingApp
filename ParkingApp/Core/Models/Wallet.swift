import Foundation

/// The money a driver keeps in the app, one wallet per account.
///
/// Balances are `Decimal` like every other amount here, and a wallet is never edited in
/// place: adding money or paying for a stay returns a new one.
struct Wallet: Codable, Equatable, Identifiable, Sendable {
    /// The account the money belongs to, which is what makes a wallet unique.
    var id: UUID { userID }

    let userID: UUID
    let balance: Decimal

    /// What a driver has before they have ever added anything.
    static func empty(userID: UUID) -> Wallet {
        Wallet(userID: userID, balance: 0)
    }

    func canAfford(_ amount: Decimal) -> Bool {
        balance >= amount
    }

    /// How much short of `amount` the balance is, and zero when it covers it.
    func shortfall(for amount: Decimal) -> Decimal {
        max(0, amount - balance)
    }

    func adding(_ amount: Decimal) -> Wallet {
        Wallet(userID: userID, balance: balance + amount)
    }

    func subtracting(_ amount: Decimal) -> Wallet {
        Wallet(userID: userID, balance: balance - amount)
    }

    var formattedBalance: String {
        ParkingPricing.formatted(balance)
    }
}
