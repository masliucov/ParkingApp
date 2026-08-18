import Foundation

/// Read and write access to vehicles.
protocol VehicleRepository: Sendable {
    /// The owner's vehicles, in the order they were added.
    func vehicles(ownedBy ownerID: UUID) throws -> [Vehicle]
    func vehicle(withID id: UUID) throws -> Vehicle?
    /// Inserts the vehicle, or replaces the existing one with the same identifier.
    func save(_ vehicle: Vehicle) throws
    func delete(vehicleWithID id: UUID) throws
}

/// Keeps every vehicle in a single JSON document.
struct StoredVehicleRepository: VehicleRepository {
    static let storageKey = "vehicles"

    let store: KeyValueStore

    func vehicles(ownedBy ownerID: UUID) throws -> [Vehicle] {
        try allVehicles().filter { $0.ownerID == ownerID }
    }

    func vehicle(withID id: UUID) throws -> Vehicle? {
        try allVehicles().first { $0.id == id }
    }

    func save(_ vehicle: Vehicle) throws {
        let updated = try allVehicles().upserting(vehicle)
        try store.write(updated, forKey: Self.storageKey)
    }

    func delete(vehicleWithID id: UUID) throws {
        let updated = try allVehicles().removing(id: id)
        try store.write(updated, forKey: Self.storageKey)
    }

    private func allVehicles() throws -> [Vehicle] {
        try store.read([Vehicle].self, forKey: Self.storageKey) ?? []
    }
}
