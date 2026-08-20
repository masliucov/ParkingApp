import Foundation
import Testing
@testable import ParkingApp

@Suite("ParkingSessionService")
struct ParkingSessionServiceTests {

    private let now = Date(timeIntervalSince1970: 1_755_000_000)

    @Test("starts a session that runs for the chosen duration")
    func startsSession() throws {
        // Arrange
        let service = makeService()
        let user = UUID()

        // Act
        let session = try service.start(
            lot: makeLot(),
            vehicle: makeVehicle(ownerID: user),
            duration: .twoHours,
            userID: user,
            now: now
        )

        // Assert
        #expect(session.startedAt == now)
        #expect(session.expiresAt == now.addingTimeInterval(2 * 3600))
        #expect(session.isActive(at: now))
    }

    @Test("charges the price of the chosen duration")
    func chargesForDuration() throws {
        // Arrange
        let service = makeService()
        let user = UUID()

        // Act
        let session = try service.start(
            lot: makeLot(hourlyRate: .cents(150)),
            vehicle: makeVehicle(ownerID: user),
            duration: .thirtyMinutes,
            userID: user,
            now: now
        )

        // Assert
        #expect(session.amountPaid == .cents(75))
    }

    @Test("keeps a copy of the vehicle and the spot")
    func keepsCopies() throws {
        // Arrange
        let service = makeService()
        let user = UUID()
        let vehicle = makeVehicle(ownerID: user)
        let lot = makeLot()

        // Act
        let session = try service.start(
            lot: lot,
            vehicle: vehicle,
            duration: .oneHour,
            userID: user,
            now: now
        )

        // Assert
        #expect(session.vehicle == vehicle)
        #expect(session.lot == lot)
    }

    @Test("refuses to park the same vehicle twice at once")
    func refusesSecondSessionForTheSameVehicle() throws {
        // Arrange
        let service = makeService()
        let user = UUID()
        let vehicle = makeVehicle(ownerID: user)
        _ = try service.start(
            lot: makeLot(),
            vehicle: vehicle,
            duration: .oneHour,
            userID: user,
            now: now
        )

        // Act & Assert
        #expect(throws: ParkingSessionError.vehicleAlreadyParked) {
            try service.start(
                lot: makeLot(),
                vehicle: vehicle,
                duration: .oneHour,
                userID: user,
                now: now.addingTimeInterval(600)
            )
        }
    }

    @Test("parks two of the driver's vehicles at the same time")
    func parksTwoVehiclesAtOnce() throws {
        // Arrange
        let service = makeService()
        let user = UUID()
        let first = try service.start(
            lot: makeLot(),
            vehicle: makeVehicle(ownerID: user),
            duration: .oneHour,
            userID: user,
            now: now
        )

        // Act
        let second = try service.start(
            lot: makeLot(),
            vehicle: makeVehicle(ownerID: user),
            duration: .twoHours,
            userID: user,
            now: now
        )

        // Assert
        let active = try service.activeSessions(for: user, at: now)
        #expect(active.count == 2)
        #expect(active.contains(first))
        #expect(active.contains(second))
    }

    @Test("lists what runs out first at the top")
    func sortsActiveSessionsByEnd() throws {
        // Arrange
        let service = makeService()
        let user = UUID()
        let longStay = try service.start(
            lot: makeLot(),
            vehicle: makeVehicle(ownerID: user),
            duration: .fourHours,
            userID: user,
            now: now
        )
        let shortStay = try service.start(
            lot: makeLot(),
            vehicle: makeVehicle(ownerID: user),
            duration: .thirtyMinutes,
            userID: user,
            now: now
        )

        // Act
        let active = try service.activeSessions(for: user, at: now)

        // Assert
        #expect(active == [shortStay, longStay])
    }

    @Test("parks a vehicle again once its previous stay has expired")
    func allowsSessionAfterExpiry() throws {
        // Arrange
        let service = makeService()
        let user = UUID()
        let vehicle = makeVehicle(ownerID: user)
        _ = try service.start(
            lot: makeLot(),
            vehicle: vehicle,
            duration: .oneHour,
            userID: user,
            now: now
        )

        // Act
        let session = try service.start(
            lot: makeLot(),
            vehicle: vehicle,
            duration: .oneHour,
            userID: user,
            now: now.addingTimeInterval(3601)
        )

        // Assert
        #expect(session.isActive(at: now.addingTimeInterval(3601)))
    }

    @Test("does not block a different driver")
    func doesNotBlockAnotherDriver() throws {
        // Arrange
        let service = makeService()
        let firstDriver = UUID()
        let secondDriver = UUID()
        _ = try service.start(
            lot: makeLot(),
            vehicle: makeVehicle(ownerID: firstDriver),
            duration: .oneHour,
            userID: firstDriver,
            now: now
        )

        // Act
        let session = try service.start(
            lot: makeLot(),
            vehicle: makeVehicle(ownerID: secondDriver),
            duration: .oneHour,
            userID: secondDriver,
            now: now
        )

        // Assert
        #expect(session.userID == secondDriver)
    }

    @Test("refuses a spot with no free spaces")
    func refusesFullLot() {
        // Arrange
        let service = makeService()
        let user = UUID()

        // Act & Assert
        #expect(throws: ParkingSessionError.lotIsFull) {
            try service.start(
                lot: makeLot(availableSpaces: 0),
                vehicle: makeVehicle(ownerID: user),
                duration: .oneHour,
                userID: user,
                now: now
            )
        }
    }

    @Test("stops reporting a session as active once it expires")
    func expiresSession() throws {
        // Arrange
        let service = makeService()
        let user = UUID()
        _ = try service.start(
            lot: makeLot(),
            vehicle: makeVehicle(ownerID: user),
            duration: .oneHour,
            userID: user,
            now: now
        )

        // Act & Assert
        #expect(try service.activeSessions(for: user, at: now.addingTimeInterval(3599)).count == 1)
        #expect(try service.activeSessions(for: user, at: now.addingTimeInterval(3600)).isEmpty)
    }

    @Test("keeps expired sessions in the history")
    func keepsHistory() throws {
        // Arrange
        let store = InMemoryKeyValueStore()
        let service = makeService(store: store)
        let user = UUID()
        _ = try service.start(
            lot: makeLot(),
            vehicle: makeVehicle(ownerID: user),
            duration: .oneHour,
            userID: user,
            now: now
        )

        // Act
        let sessions = try makeService(store: store).sessions(for: user)

        // Assert
        #expect(sessions.count == 1)
    }

    // MARK: - Adding time

    @Test("adds time to the end of the stay, not to the current moment")
    func extendsFromTheEnd() throws {
        // Arrange
        let service = makeService()
        let user = UUID()
        let session = try service.start(
            lot: makeLot(),
            vehicle: makeVehicle(ownerID: user),
            duration: .oneHour,
            userID: user,
            now: now
        )

        // Act: ten minutes in, buy another hour
        let extended = try service.extend(session, by: .oneHour, now: now.addingTimeInterval(600))

        // Assert
        #expect(extended.expiresAt == session.expiresAt.addingTimeInterval(3600))
    }

    @Test("adds the price of the extra time to what was already paid")
    func extendsAmountPaid() throws {
        // Arrange
        let service = makeService()
        let user = UUID()
        let session = try service.start(
            lot: makeLot(hourlyRate: .cents(120)),
            vehicle: makeVehicle(ownerID: user),
            duration: .oneHour,
            userID: user,
            now: now
        )

        // Act
        let extended = try service.extend(session, by: .oneHour, now: now)

        // Assert
        #expect(session.amountPaid == .cents(120))
        #expect(extended.amountPaid == .cents(240))
    }

    @Test("keeps the vehicle, the spot and the start time")
    func extendsKeepsDetails() throws {
        // Arrange
        let service = makeService()
        let user = UUID()
        let session = try service.start(
            lot: makeLot(),
            vehicle: makeVehicle(ownerID: user),
            duration: .oneHour,
            userID: user,
            now: now
        )

        // Act
        let extended = try service.extend(session, by: .thirtyMinutes, now: now)

        // Assert
        #expect(extended.id == session.id)
        #expect(extended.vehicle == session.vehicle)
        #expect(extended.lot == session.lot)
        #expect(extended.startedAt == session.startedAt)
    }

    @Test("extends the session in place instead of starting another")
    func extendsInPlace() throws {
        // Arrange
        let store = InMemoryKeyValueStore()
        let service = makeService(store: store)
        let user = UUID()
        let session = try service.start(
            lot: makeLot(),
            vehicle: makeVehicle(ownerID: user),
            duration: .oneHour,
            userID: user,
            now: now
        )

        // Act
        _ = try service.extend(session, by: .oneHour, now: now)

        // Assert
        #expect(try service.sessions(for: user).count == 1)
    }

    @Test("reports the extended session as the active one")
    func extendedSessionStaysActive() throws {
        // Arrange
        let service = makeService()
        let user = UUID()
        let session = try service.start(
            lot: makeLot(),
            vehicle: makeVehicle(ownerID: user),
            duration: .oneHour,
            userID: user,
            now: now
        )

        // Act
        _ = try service.extend(session, by: .oneHour, now: now)

        // Assert: the original hour is up, the bought hour is not
        #expect(try service.activeSessions(for: user, at: now.addingTimeInterval(3601)).count == 1)
    }

    @Test("refuses to add time to parking that has already ended")
    func refusesToExtendEndedSession() throws {
        // Arrange
        let service = makeService()
        let user = UUID()
        let session = try service.start(
            lot: makeLot(),
            vehicle: makeVehicle(ownerID: user),
            duration: .oneHour,
            userID: user,
            now: now
        )

        // Act & Assert
        #expect(throws: ParkingSessionError.sessionEnded) {
            try service.extend(session, by: .oneHour, now: now.addingTimeInterval(3600))
        }
    }

    @Test("ends a stay right away instead of at the time bought")
    func endsStayEarly() throws {
        // Arrange
        let service = makeService()
        let user = UUID()
        let session = try service.start(
            lot: makeLot(),
            vehicle: makeVehicle(ownerID: user),
            duration: .twoHours,
            userID: user,
            now: now
        )
        let leavingEarly = now.addingTimeInterval(600)

        // Act
        let ended = try service.end(session, now: leavingEarly)

        // Assert
        #expect(ended.expiresAt == leavingEarly)
        #expect(!ended.isActive(at: leavingEarly))
        #expect(try service.activeSessions(for: user, at: leavingEarly).isEmpty)
    }

    @Test("keeps what was paid when parking ends early")
    func keepsAmountPaidWhenEndingEarly() throws {
        // Arrange
        let service = makeService()
        let user = UUID()
        let session = try service.start(
            lot: makeLot(hourlyRate: .cents(150)),
            vehicle: makeVehicle(ownerID: user),
            duration: .twoHours,
            userID: user,
            now: now
        )

        // Act
        let ended = try service.end(session, now: now.addingTimeInterval(600))

        // Assert
        #expect(ended.amountPaid == session.amountPaid)
    }

    @Test("keeps a stay that ended early in the history")
    func keepsEndedStayInHistory() throws {
        // Arrange
        let service = makeService()
        let user = UUID()
        let session = try service.start(
            lot: makeLot(),
            vehicle: makeVehicle(ownerID: user),
            duration: .twoHours,
            userID: user,
            now: now
        )

        // Act
        let ended = try service.end(session, now: now.addingTimeInterval(600))

        // Assert
        #expect(try service.sessions(for: user) == [ended])
    }

    @Test("frees the vehicle to be parked again once the stay is ended")
    func freesVehicleAfterEndingEarly() throws {
        // Arrange
        let service = makeService()
        let user = UUID()
        let vehicle = makeVehicle(ownerID: user)
        let session = try service.start(
            lot: makeLot(),
            vehicle: vehicle,
            duration: .twoHours,
            userID: user,
            now: now
        )
        let leavingEarly = now.addingTimeInterval(600)
        _ = try service.end(session, now: leavingEarly)

        // Act & Assert: starting again would throw if the vehicle still counted as parked
        #expect(throws: Never.self) {
            try service.start(
                lot: makeLot(),
                vehicle: vehicle,
                duration: .oneHour,
                userID: user,
                now: leavingEarly
            )
        }
    }

    @Test("refuses to end parking that has already ended")
    func refusesToEndFinishedParking() throws {
        // Arrange
        let service = makeService()
        let user = UUID()
        let session = try service.start(
            lot: makeLot(),
            vehicle: makeVehicle(ownerID: user),
            duration: .oneHour,
            userID: user,
            now: now
        )

        // Act & Assert
        #expect(throws: ParkingSessionError.sessionEnded) {
            try service.end(session, now: now.addingTimeInterval(3600))
        }
    }

    @Test("reports which vehicles are parked and which are free")
    func reportsParkedVehicles() throws {
        // Arrange
        let service = makeService()
        let user = UUID()
        let parked = makeVehicle(ownerID: user)
        let free = makeVehicle(ownerID: user)
        _ = try service.start(
            lot: makeLot(),
            vehicle: parked,
            duration: .oneHour,
            userID: user,
            now: now
        )

        // Act
        let parkedIDs = try service.parkedVehicleIDs(for: user, at: now)

        // Assert
        #expect(parkedIDs == [parked.id])
        #expect(!parkedIDs.contains(free.id))
    }

    @Test("frees a vehicle again once its stay has expired")
    func reportsNoParkedVehiclesAfterExpiry() throws {
        // Arrange
        let service = makeService()
        let user = UUID()
        _ = try service.start(
            lot: makeLot(),
            vehicle: makeVehicle(ownerID: user),
            duration: .oneHour,
            userID: user,
            now: now
        )

        // Act & Assert
        #expect(try service.parkedVehicleIDs(for: user, at: now.addingTimeInterval(3601)).isEmpty)
    }

    // MARK: - Paying from the balance

    @Test("pays for the stay out of the balance")
    func paysForTheStayFromTheBalance() throws {
        // Arrange
        let service = makeService(openingBalance: .cents(1_000))
        let user = UUID()

        // Act
        let session = try service.start(
            lot: makeLot(hourlyRate: .cents(120)),
            vehicle: makeVehicle(ownerID: user),
            duration: .twoHours,
            userID: user,
            now: now
        )

        // Assert
        #expect(session.amountPaid == .cents(240))
        #expect(try service.wallet.balance(for: user) == .cents(760))
    }

    @Test("refuses to start a stay the balance cannot cover and says how much is missing")
    func refusesToStartWithoutEnoughBalance() {
        // Arrange
        let service = makeService(openingBalance: .cents(100))
        let user = UUID()

        // Act & Assert
        #expect(throws: WalletError.insufficientFunds(shortfall: .cents(20))) {
            try service.start(
                lot: makeLot(hourlyRate: .cents(120)),
                vehicle: makeVehicle(ownerID: user),
                duration: .oneHour,
                userID: user,
                now: now
            )
        }
    }

    @Test("parks nothing when the balance is short")
    func parksNothingWhenBalanceIsShort() throws {
        // Arrange
        let service = makeService(openingBalance: .cents(100))
        let user = UUID()

        // Act
        #expect(throws: WalletError.self) {
            try service.start(
                lot: makeLot(hourlyRate: .cents(120)),
                vehicle: makeVehicle(ownerID: user),
                duration: .oneHour,
                userID: user,
                now: now
            )
        }

        // Assert
        #expect(try service.sessions(for: user).isEmpty)
        #expect(try service.wallet.balance(for: user) == .cents(100))
    }

    @Test("pays for added time out of the balance")
    func paysForAddedTimeFromTheBalance() throws {
        // Arrange
        let service = makeService(openingBalance: .cents(1_000))
        let user = UUID()
        let session = try service.start(
            lot: makeLot(hourlyRate: .cents(120)),
            vehicle: makeVehicle(ownerID: user),
            duration: .oneHour,
            userID: user,
            now: now
        )

        // Act
        _ = try service.extend(session, by: .thirtyMinutes, now: now)

        // Assert: the hour, then half of one more
        #expect(try service.wallet.balance(for: user) == .cents(820))
    }

    @Test("refuses to add time the balance cannot cover")
    func refusesToAddTimeWithoutEnoughBalance() throws {
        // Arrange: an hour bought at 1.50 leaves 0.50 of the 2.00 opening balance
        let service = makeService(openingBalance: .cents(200))
        let user = UUID()
        let session = try service.start(
            lot: makeLot(hourlyRate: .cents(150)),
            vehicle: makeVehicle(ownerID: user),
            duration: .oneHour,
            userID: user,
            now: now
        )

        // Act & Assert
        #expect(throws: WalletError.insufficientFunds(shortfall: .cents(25))) {
            try service.extend(session, by: .thirtyMinutes, now: now)
        }
    }

    @Test("leaves the stay as it was when there is not enough to add time")
    func keepsStayUnchangedWhenBalanceIsShort() throws {
        // Arrange
        let service = makeService(openingBalance: .cents(200))
        let user = UUID()
        let session = try service.start(
            lot: makeLot(hourlyRate: .cents(150)),
            vehicle: makeVehicle(ownerID: user),
            duration: .oneHour,
            userID: user,
            now: now
        )

        // Act
        #expect(throws: WalletError.self) {
            try service.extend(session, by: .thirtyMinutes, now: now)
        }

        // Assert
        #expect(try service.sessions(for: user) == [session])
        #expect(try service.wallet.balance(for: user) == .cents(50))
    }

    @Test("gives nothing back to the balance when a stay ends early")
    func refundsNothingWhenEndingEarly() throws {
        // Arrange
        let service = makeService(openingBalance: .cents(1_000))
        let user = UUID()
        let session = try service.start(
            lot: makeLot(hourlyRate: .cents(120)),
            vehicle: makeVehicle(ownerID: user),
            duration: .twoHours,
            userID: user,
            now: now
        )

        // Act
        _ = try service.end(session, now: now.addingTimeInterval(600))

        // Assert
        #expect(try service.wallet.balance(for: user) == .cents(760))
    }

    // MARK: - Helpers

    private func makeService(
        store: KeyValueStore = InMemoryKeyValueStore(),
        openingBalance: Decimal = .cents(10_000)
    ) -> ParkingSessionService {
        ParkingSessionService(
            repository: StoredParkingSessionRepository(store: store),
            wallet: .funded(store: store, openingBalance: openingBalance)
        )
    }

    private func makeLot(hourlyRate: Decimal = .cents(120), availableSpaces: Int = 8) -> ParkingLot {
        ParkingLot(
            id: "Rua Augusta@38.71120,-9.13760",
            name: "Rua Augusta",
            latitude: 38.7112,
            longitude: -9.1376,
            hourlyRate: hourlyRate,
            availableSpaces: availableSpaces,
            totalSpaces: 40
        )
    }

    private func makeVehicle(ownerID: UUID) -> Vehicle {
        Vehicle(
            id: UUID(),
            ownerID: ownerID,
            model: "Renault Clio",
            licensePlate: "AA-00-BB",
            createdAt: now
        )
    }
}
