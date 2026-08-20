import Foundation
import Testing
@testable import ParkingApp

@Suite("WalletService")
struct WalletServiceTests {

    @Test("a driver who has never added money has an empty balance")
    func startsEmpty() throws {
        // Arrange
        let service = makeService()

        // Act & Assert
        #expect(try service.balance(for: UUID()) == 0)
    }

    @Test("adds money to the balance")
    func addsFunds() throws {
        // Arrange
        let service = makeService()
        let user = UUID()

        // Act
        let wallet = try service.add(.cents(1_000), userID: user)

        // Assert
        #expect(wallet.balance == .cents(1_000))
        #expect(try service.balance(for: user) == .cents(1_000))
    }

    @Test("adds to what is already there")
    func addsToExistingBalance() throws {
        // Arrange
        let service = makeService()
        let user = UUID()
        _ = try service.add(.cents(500), userID: user)

        // Act
        _ = try service.add(.cents(250), userID: user)

        // Assert
        #expect(try service.balance(for: user) == .cents(750))
    }

    @Test("refuses to add nothing")
    func refusesEmptyTopUp() {
        // Arrange
        let service = makeService()

        // Act & Assert
        #expect(throws: WalletError.invalidAmount) {
            try service.add(0, userID: UUID())
        }
        #expect(throws: WalletError.invalidAmount) {
            try service.add(.cents(-500), userID: UUID())
        }
    }

    @Test("keeps each driver's balance to themselves")
    func keepsBalancesSeparate() throws {
        // Arrange
        let service = makeService()
        let driver = UUID()
        let otherDriver = UUID()

        // Act
        _ = try service.add(.cents(1_000), userID: driver)

        // Assert
        #expect(try service.balance(for: driver) == .cents(1_000))
        #expect(try service.balance(for: otherDriver) == 0)
    }

    @Test("keeps the balance across services sharing a store")
    func persistsBalance() throws {
        // Arrange
        let store = InMemoryKeyValueStore()
        let user = UUID()
        _ = try makeService(store: store).add(.cents(1_500), userID: user)

        // Act
        let balance = try makeService(store: store).balance(for: user)

        // Assert
        #expect(balance == .cents(1_500))
    }

    // MARK: - Paying

    @Test("takes what is paid out of the balance")
    func chargesBalance() throws {
        // Arrange
        let service = makeService()
        let user = UUID()
        _ = try service.add(.cents(1_000), userID: user)

        // Act
        let wallet = try service.charge(.cents(120), userID: user)

        // Assert
        #expect(wallet.balance == .cents(880))
        #expect(try service.balance(for: user) == .cents(880))
    }

    @Test("lets a driver spend their balance down to nothing")
    func chargesTheWholeBalance() throws {
        // Arrange
        let service = makeService()
        let user = UUID()
        _ = try service.add(.cents(240), userID: user)

        // Act
        let wallet = try service.charge(.cents(240), userID: user)

        // Assert
        #expect(wallet.balance == 0)
    }

    @Test("refuses a charge the balance cannot cover and says how much is missing")
    func refusesChargeOverBalance() throws {
        // Arrange
        let service = makeService()
        let user = UUID()
        _ = try service.add(.cents(200), userID: user)

        // Act & Assert
        #expect(throws: WalletError.insufficientFunds(shortfall: .cents(100))) {
            try service.charge(.cents(300), userID: user)
        }
    }

    @Test("leaves the balance alone when a charge is refused")
    func keepsBalanceWhenChargeRefused() throws {
        // Arrange
        let service = makeService()
        let user = UUID()
        _ = try service.add(.cents(200), userID: user)

        // Act
        #expect(throws: WalletError.self) {
            try service.charge(.cents(300), userID: user)
        }

        // Assert
        #expect(try service.balance(for: user) == .cents(200))
    }

    @Test("names the whole price as missing when there is no balance at all")
    func reportsWholePriceAsMissingWhenEmpty() {
        // Arrange
        let service = makeService()

        // Act & Assert
        #expect(throws: WalletError.insufficientFunds(shortfall: .cents(120))) {
            try service.charge(.cents(120), userID: UUID())
        }
    }

    @Test("charges nothing for a stay that costs nothing")
    func chargesNothingForAFreeStay() throws {
        // Arrange
        let service = makeService()
        let user = UUID()

        // Act
        let wallet = try service.charge(0, userID: user)

        // Assert
        #expect(wallet.balance == 0)
    }

    @Test("refuses a negative charge rather than paying the driver")
    func refusesNegativeCharge() {
        // Arrange
        let service = makeService()

        // Act & Assert
        #expect(throws: WalletError.invalidAmount) {
            try service.charge(.cents(-120), userID: UUID())
        }
    }

    @Test("reports whether the balance covers an amount")
    func reportsAffordability() throws {
        // Arrange
        let service = makeService()
        let user = UUID()
        _ = try service.add(.cents(500), userID: user)

        // Act & Assert
        #expect(try service.canAfford(.cents(500), userID: user))
        #expect(try !service.canAfford(.cents(501), userID: user))
    }

    // MARK: - Helpers

    private func makeService(store: KeyValueStore = InMemoryKeyValueStore()) -> WalletService {
        WalletService(repository: StoredWalletRepository(store: store))
    }
}
