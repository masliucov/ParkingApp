import Foundation

/// The driver's balance: putting money in, and paying for parking out of it.
///
/// No card is ever charged. The balance is a number kept on this device, spent on prices
/// that are themselves invented — but it is spent for real, so a driver cannot park with
/// an empty wallet.
struct WalletService: Sendable {
    let repository: WalletRepository

    /// A driver who has never added money has an empty wallet rather than none, so every
    /// screen can show a balance without first creating one.
    func wallet(for userID: UUID) throws -> Wallet {
        try repository.wallet(for: userID) ?? .empty(userID: userID)
    }

    func balance(for userID: UUID) throws -> Decimal {
        try wallet(for: userID).balance
    }

    func canAfford(_ amount: Decimal, userID: UUID) throws -> Bool {
        try wallet(for: userID).canAfford(amount)
    }

    /// Puts money in. Nothing is taken from a card: the amount is simply credited.
    @discardableResult
    func add(_ amount: Decimal, userID: UUID) throws -> Wallet {
        guard amount > 0 else { throw WalletError.invalidAmount }

        let credited = try wallet(for: userID).adding(amount)
        try repository.save(credited)
        return credited
    }

    /// Takes the price of a stay out, or refuses and says how much is missing.
    ///
    /// A price of zero is allowed and changes nothing: a free stay is still a stay.
    @discardableResult
    func charge(_ amount: Decimal, userID: UUID) throws -> Wallet {
        guard amount >= 0 else { throw WalletError.invalidAmount }

        let current = try wallet(for: userID)
        guard current.canAfford(amount) else {
            throw WalletError.insufficientFunds(shortfall: current.shortfall(for: amount))
        }

        let charged = current.subtracting(amount)
        try repository.save(charged)
        return charged
    }
}
