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

    // MARK: - Helpers

    private func makeService(store: KeyValueStore = InMemoryKeyValueStore()) -> VehicleService {
        VehicleService(repository: StoredVehicleRepository(store: store))
    }
}
