import Foundation
import Testing
@testable import ParkingApp

@Suite("StoredWalletRepository")
struct WalletRepositoryTests {

    @Test("has nothing for a driver who never added money")
    func returnsNothingForUnknownDriver() throws {
        // Arrange
        let repository = StoredWalletRepository(store: InMemoryKeyValueStore())

        // Act & Assert
        #expect(try repository.wallet(for: UUID()) == nil)
    }

    @Test("reads back the wallet it saved")
    func savesAndReadsWallet() throws {
        // Arrange
        let repository = StoredWalletRepository(store: InMemoryKeyValueStore())
        let wallet = Wallet(userID: UUID(), balance: .cents(1_250))

        // Act
        try repository.save(wallet)

        // Assert
        #expect(try repository.wallet(for: wallet.userID) == wallet)
    }

    @Test("replaces the wallet of the same driver instead of keeping two")
    func replacesWalletOfSameDriver() throws {
        // Arrange
        let store = InMemoryKeyValueStore()
        let repository = StoredWalletRepository(store: store)
        let user = UUID()
        try repository.save(Wallet(userID: user, balance: .cents(500)))

        // Act
        try repository.save(Wallet(userID: user, balance: .cents(900)))

        // Assert
        #expect(try repository.wallet(for: user)?.balance == .cents(900))
        #expect(try store.read([Wallet].self, forKey: StoredWalletRepository.storageKey)?.count == 1)
    }

    @Test("keeps one wallet per driver")
    func keepsOneWalletPerDriver() throws {
        // Arrange
        let repository = StoredWalletRepository(store: InMemoryKeyValueStore())
        let mine = Wallet(userID: UUID(), balance: .cents(500))
        let theirs = Wallet(userID: UUID(), balance: .cents(900))

        // Act
        try repository.save(mine)
        try repository.save(theirs)

        // Assert
        #expect(try repository.wallet(for: mine.userID) == mine)
        #expect(try repository.wallet(for: theirs.userID) == theirs)
    }

    @Test("keeps wallets across repositories sharing a store")
    func persistsAcrossInstances() throws {
        // Arrange
        let store = InMemoryKeyValueStore()
        let wallet = Wallet(userID: UUID(), balance: .cents(2_000))
        try StoredWalletRepository(store: store).save(wallet)

        // Act
        let found = try StoredWalletRepository(store: store).wallet(for: wallet.userID)

        // Assert
        #expect(found == wallet)
    }
}
