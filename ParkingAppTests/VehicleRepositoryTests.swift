import Foundation
import Testing
@testable import ParkingApp

@Suite("StoredVehicleRepository")
struct VehicleRepositoryTests {

    @Test("returns only the vehicles of the given owner")
    func returnsOnlyOwnersVehicles() throws {
        // Arrange
        let repository = StoredVehicleRepository(store: InMemoryKeyValueStore())
        let owner = UUID()
        let mine = makeVehicle(ownerID: owner, plate: "AA-00-BB")
        let theirs = makeVehicle(ownerID: UUID(), plate: "CC-11-DD")

        // Act
        try repository.save(mine)
        try repository.save(theirs)

        // Assert
        #expect(try repository.vehicles(ownedBy: owner) == [mine])
    }

    @Test("keeps vehicles in the order they were added")
    func keepsInsertionOrder() throws {
        // Arrange
        let repository = StoredVehicleRepository(store: InMemoryKeyValueStore())
        let owner = UUID()
        let first = makeVehicle(ownerID: owner, plate: "AA-00-BB")
        let second = makeVehicle(ownerID: owner, plate: "CC-11-DD")

        // Act
        try repository.save(first)
        try repository.save(second)

        // Assert
        #expect(try repository.vehicles(ownedBy: owner) == [first, second])
    }

    @Test("finds a vehicle by identifier")
    func findsVehicleByID() throws {
        // Arrange
        let repository = StoredVehicleRepository(store: InMemoryKeyValueStore())
        let vehicle = makeVehicle(ownerID: UUID(), plate: "AA-00-BB")
        try repository.save(vehicle)

        // Act & Assert
        #expect(try repository.vehicle(withID: vehicle.id) == vehicle)
        #expect(try repository.vehicle(withID: UUID()) == nil)
    }

    @Test("replaces the vehicle that already has the same identifier")
    func replacesVehicleWithSameID() throws {
        // Arrange
        let repository = StoredVehicleRepository(store: InMemoryKeyValueStore())
        let original = makeVehicle(ownerID: UUID(), plate: "AA-00-BB")
        let renamed = Vehicle(
            id: original.id,
            ownerID: original.ownerID,
            model: "Renault Megane",
            licensePlate: original.licensePlate,
            createdAt: original.createdAt
        )
        try repository.save(original)

        // Act
        try repository.save(renamed)

        // Assert
        #expect(try repository.vehicles(ownedBy: original.ownerID) == [renamed])
    }

    @Test("removes a deleted vehicle and leaves the others alone")
    func deletesVehicle() throws {
        // Arrange
        let repository = StoredVehicleRepository(store: InMemoryKeyValueStore())
        let owner = UUID()
        let kept = makeVehicle(ownerID: owner, plate: "AA-00-BB")
        let removed = makeVehicle(ownerID: owner, plate: "CC-11-DD")
        try repository.save(kept)
        try repository.save(removed)

        // Act
        try repository.delete(vehicleWithID: removed.id)

        // Assert
        #expect(try repository.vehicles(ownedBy: owner) == [kept])
    }

    @Test("deleting an unknown vehicle changes nothing")
    func deletingUnknownVehicleChangesNothing() throws {
        // Arrange
        let repository = StoredVehicleRepository(store: InMemoryKeyValueStore())
        let vehicle = makeVehicle(ownerID: UUID(), plate: "AA-00-BB")
        try repository.save(vehicle)

        // Act
        try repository.delete(vehicleWithID: UUID())

        // Assert
        #expect(try repository.vehicles(ownedBy: vehicle.ownerID) == [vehicle])
    }

    @Test("keeps vehicles across repository instances sharing a store")
    func persistsAcrossInstances() throws {
        // Arrange
        let store = InMemoryKeyValueStore()
        let vehicle = makeVehicle(ownerID: UUID(), plate: "AA-00-BB")
        try StoredVehicleRepository(store: store).save(vehicle)

        // Act
        let found = try StoredVehicleRepository(store: store).vehicles(ownedBy: vehicle.ownerID)

        // Assert
        #expect(found == [vehicle])
    }

    // MARK: - Helpers

    private func makeVehicle(ownerID: UUID, plate: String) -> Vehicle {
        Vehicle(
            id: UUID(),
            ownerID: ownerID,
            model: "Renault Clio",
            licensePlate: plate,
            createdAt: Date(timeIntervalSince1970: 1_755_000_000)
        )
    }
}
