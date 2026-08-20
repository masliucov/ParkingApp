import Foundation
@testable import ParkingApp

/// A wallet repository where every driver starts with money in it.
///
/// Parking is paid for out of the balance, so without this every test about starting a stay
/// would have to top up first and would half be a test about the wallet. The tests that are
/// about the wallet use `StoredWalletRepository` and add the money themselves.
struct FundedWalletRepository: WalletRepository {
    let store: KeyValueStore
    /// What a driver has before they have ever paid for anything.
    let openingBalance: Decimal

    func wallet(for userID: UUID) throws -> Wallet? {
        try stored.wallet(for: userID) ?? Wallet(userID: userID, balance: openingBalance)
    }

    func save(_ wallet: Wallet) throws {
        try stored.save(wallet)
    }

    private var stored: StoredWalletRepository {
        StoredWalletRepository(store: store)
    }
}

extension WalletService {
    /// A wallet service whose drivers can already afford to park.
    static func funded(
        store: KeyValueStore = InMemoryKeyValueStore(),
        openingBalance: Decimal = .cents(10_000)
    ) -> WalletService {
        WalletService(
            repository: FundedWalletRepository(store: store, openingBalance: openingBalance)
        )
    }
}
