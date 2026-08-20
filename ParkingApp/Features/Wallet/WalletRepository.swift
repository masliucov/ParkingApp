import Foundation

/// Read and write access to balances.
protocol WalletRepository: Sendable {
    /// The driver's wallet, or `nil` when they have never had one.
    func wallet(for userID: UUID) throws -> Wallet?
    /// Inserts the wallet, or replaces the one already held for that driver.
    func save(_ wallet: Wallet) throws
}

/// Keeps every wallet in a single JSON document.
struct StoredWalletRepository: WalletRepository {
    static let storageKey = "wallets"

    let store: KeyValueStore

    func wallet(for userID: UUID) throws -> Wallet? {
        try allWallets().first { $0.userID == userID }
    }

    func save(_ wallet: Wallet) throws {
        let updated = try allWallets().upserting(wallet)
        try store.write(updated, forKey: Self.storageKey)
    }

    private func allWallets() throws -> [Wallet] {
        try store.read([Wallet].self, forKey: Self.storageKey) ?? []
    }
}
