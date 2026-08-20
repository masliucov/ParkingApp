import Foundation
import Testing
@testable import ParkingApp

@Suite("VehicleService")
struct VehicleServiceTests {

    // MARK: - Register

    @Test("registers a vehicle with normalized details")
    func registersVehicle() throws {
        // Arrange
        let service = makeService()
        let owner = UUID()

        // Act
        let vehicle = try service.register(
            model: "  Renault Clio ",
            licensePlate: " aa 00 bb ",
            ownerID: owner
        )

        // Assert
        #expect(vehicle.model == "Renault Clio")
        #expect(vehicle.licensePlate == "AA00BB")
        #expect(vehicle.ownerID == owner)
        #expect(try service.vehicles(ownedBy: owner) == [vehicle])
    }

    @Test("rejects a blank model")
    func rejectsBlankModel() {
        // Arrange
        let service = makeService()

        // Act & Assert
        #expect(throws: VehicleError.invalidModel) {
            try service.register(model: "  ", licensePlate: "AA-00-BB", ownerID: UUID())
        }
    }

    @Test("rejects an invalid plate")
    func rejectsInvalidPlate() {
        // Arrange
        let service = makeService()

        // Act & Assert
        #expect(throws: VehicleError.invalidLicensePlate) {
            try service.register(model: "Renault Clio", licensePlate: "AB", ownerID: UUID())
        }
    }

    @Test("rejects a plate the same owner already registered, however it is written")
    func rejectsDuplicatePlateForSameOwner() throws {
        // Arrange
        let service = makeService()
        let owner = UUID()
        _ = try service.register(model: "Renault Clio", licensePlate: "AA-00-BB", ownerID: owner)

        // Act & Assert
        #expect(throws: VehicleError.licensePlateAlreadyRegistered) {
            try service.register(model: "Renault Megane", licensePlate: " aa-00-bb ", ownerID: owner)
        }
    }

    @Test("allows two owners to register the same plate")
    func allowsSamePlateForDifferentOwners() throws {
        // Arrange
        let service = makeService()
        let firstOwner = UUID()
        let secondOwner = UUID()
        _ = try service.register(model: "Renault Clio", licensePlate: "AA-00-BB", ownerID: firstOwner)

        // Act
        let shared = try service.register(
            model: "Renault Clio",
            licensePlate: "AA-00-BB",
            ownerID: secondOwner
        )

        // Assert
        #expect(try service.vehicles(ownedBy: secondOwner) == [shared])
    }

    @Test("does not store a vehicle it rejected")
    func rejectedVehicleIsNotStored() throws {
        // Arrange
        let store = InMemoryKeyValueStore()
        let service = makeService(store: store)

        // Act & Assert
        #expect(throws: VehicleError.invalidLicensePlate) {
            try service.register(model: "Renault Clio", licensePlate: "AB", ownerID: UUID())
        }
        #expect(try store.read([Vehicle].self, forKey: StoredVehicleRepository.storageKey) == nil)
    }

    // MARK: - Update

    @Test("updates a vehicle while keeping its identity and creation date")
    func updatesVehicle() throws {
        // Arrange
        let service = makeService()
        let owner = UUID()
        let original = try service.register(
            model: "Renault Clio",
            licensePlate: "AA-00-BB",
            ownerID: owner
        )

        // Act
        let updated = try service.update(original, model: "Renault Megane", licensePlate: "CC-11-DD")

        // Assert
        #expect(updated.id == original.id)
        #expect(updated.createdAt == original.createdAt)
        #expect(updated.model == "Renault Megane")
        #expect(updated.licensePlate == "CC-11-DD")
        #expect(try service.vehicles(ownedBy: owner) == [updated])
    }

    @Test("lets a vehicle keep its own plate when only the model changes")
    func keepsOwnPlateOnUpdate() throws {
        // Arrange
        let service = makeService()
        let owner = UUID()
        let original = try service.register(
            model: "Renault Clio",
            licensePlate: "AA-00-BB",
            ownerID: owner
        )

        // Act
        let updated = try service.update(original, model: "Renault Clio RS", licensePlate: "AA-00-BB")

        // Assert
        #expect(updated.licensePlate == "AA-00-BB")
    }

    @Test("rejects an update to a plate another vehicle of the same owner already uses")
    func rejectsUpdateToTakenPlate() throws {
        // Arrange
        let service = makeService()
        let owner = UUID()
        let first = try service.register(model: "Renault Clio", licensePlate: "AA-00-BB", ownerID: owner)
        _ = try service.register(model: "Renault Megane", licensePlate: "CC-11-DD", ownerID: owner)

        // Act & Assert
        #expect(throws: VehicleError.licensePlateAlreadyRegistered) {
            try service.update(first, model: "Renault Clio", licensePlate: "CC-11-DD")
        }
    }

    // MARK: - Delete

    @Test("deletes a vehicle")
    func deletesVehicle() throws {
        // Arrange
        let service = makeService()
        let owner = UUID()
        let kept = try service.register(model: "Renault Clio", licensePlate: "AA-00-BB", ownerID: owner)
        let removed = try service.register(model: "Renault Megane", licensePlate: "CC-11-DD", ownerID: owner)

        // Act
        try service.delete(removed)

        // Assert
        #expect(try service.vehicles(ownedBy: owner) == [kept])
    }

    @Test("frees the plate of a deleted vehicle for reuse")
    func freesPlateAfterDelete() throws {
        // Arrange
        let service = makeService()
        let owner = UUID()
        let vehicle = try service.register(model: "Renault Clio", licensePlate: "AA-00-BB", ownerID: owner)
        try service.delete(vehicle)

        // Act
        let replacement = try service.register(
            model: "Renault Megane",
            licensePlate: "AA-00-BB",
            ownerID: owner
        )

        // Assert
        #expect(try service.vehicles(ownedBy: owner) == [replacement])
    }

    @Test("refuses to delete a vehicle while it is parked")
    func refusesToDeleteParkedVehicle() throws {
        // Arrange
        let store = InMemoryKeyValueStore()
        let service = makeService(store: store)
        let owner = UUID()
        let vehicle = try service.register(
            model: "Renault",
            licensePlate: "AA-00-BB",
            ownerID: owner
        )
        try park(vehicle, ownerID: owner, in: store)

        // Act & Assert
        #expect(throws: VehicleError.vehicleIsParked) {
            try service.delete(vehicle, now: now)
        }
        #expect(try service.vehicles(ownedBy: owner) == [vehicle])
    }

    @Test("deletes a vehicle once its stay has ended")
    func deletesVehicleAfterStayEnds() throws {
        // Arrange
        let store = InMemoryKeyValueStore()
        let service = makeService(store: store)
        let owner = UUID()
        let vehicle = try service.register(
            model: "Renault",
            licensePlate: "AA-00-BB",
            ownerID: owner
        )
        try park(vehicle, ownerID: owner, in: store)

        // Act
        try service.delete(vehicle, now: now.addingTimeInterval(3601))

        // Assert
        #expect(try service.vehicles(ownedBy: owner).isEmpty)
    }

    @Test("reports which of the owner's vehicles are parked")
    func reportsParkedVehicles() throws {
        // Arrange
        let store = InMemoryKeyValueStore()
        let service = makeService(store: store)
        let owner = UUID()
        let parked = try service.register(
            model: "Renault",
            licensePlate: "AA-00-BB",
            ownerID: owner
        )
        let free = try service.register(model: "Peugeot", licensePlate: "CC-11-DD", ownerID: owner)
        try park(parked, ownerID: owner, in: store)

        // Act
        let parkedIDs = try service.parkedVehicleIDs(ownedBy: owner, now: now)

        // Assert
        #expect(parkedIDs == [parked.id])
        #expect(!parkedIDs.contains(free.id))
    }

    // MARK: - Helpers

    private let now = Date(timeIntervalSince1970: 1_755_000_000)

    private func makeService(store: KeyValueStore = InMemoryKeyValueStore()) -> VehicleService {
        VehicleService(
            repository: StoredVehicleRepository(store: store),
            sessionService: ParkingSessionService(
                repository: StoredParkingSessionRepository(store: store),
                wallet: .funded(store: store)
            )
        )
    }

    /// Starts an hour of parking for `vehicle` at `now`, over the same store the service
    /// reads, so deleting it has something to trip over.
    private func park(_ vehicle: Vehicle, ownerID: UUID, in store: KeyValueStore) throws {
        let sessions = ParkingSessionService(
            repository: StoredParkingSessionRepository(store: store),
            wallet: .funded(store: store)
        )
        _ = try sessions.start(
            lot: ParkingLot(
                id: "Rua Augusta@38.71120,-9.13760",
                name: "Rua Augusta",
                latitude: 38.7112,
                longitude: -9.1376,
                hourlyRate: .cents(120),
                availableSpaces: 8,
                totalSpaces: 40
            ),
            vehicle: vehicle,
            duration: .oneHour,
            userID: ownerID,
            now: now
        )
    }
}
