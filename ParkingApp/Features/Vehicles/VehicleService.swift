import Foundation

/// Registering and editing the cars a user can park.
struct VehicleService: Sendable {
    let repository: VehicleRepository
    /// Only consulted to refuse deleting a car that is still parked.
    let sessionService: ParkingSessionService

    func vehicles(ownedBy ownerID: UUID) throws -> [Vehicle] {
        try repository.vehicles(ownedBy: ownerID)
    }

    func register(model rawModel: String, licensePlate rawPlate: String, ownerID: UUID) throws -> Vehicle {
        let model = try VehicleValidator.validateModel(rawModel)
        let plate = try VehicleValidator.validateLicensePlate(rawPlate)
        try checkPlateIsFree(plate, ownerID: ownerID, ignoring: nil)

        let vehicle = Vehicle(
            id: UUID(),
            ownerID: ownerID,
            model: model,
            licensePlate: plate,
            createdAt: .storageNow()
        )
        try repository.save(vehicle)
        return vehicle
    }

    func update(_ vehicle: Vehicle, model rawModel: String, licensePlate rawPlate: String) throws -> Vehicle {
        let model = try VehicleValidator.validateModel(rawModel)
        let plate = try VehicleValidator.validateLicensePlate(rawPlate)
        try checkPlateIsFree(plate, ownerID: vehicle.ownerID, ignoring: vehicle.id)

        let updated = Vehicle(
            id: vehicle.id,
            ownerID: vehicle.ownerID,
            model: model,
            licensePlate: plate,
            createdAt: vehicle.createdAt
        )
        try repository.save(updated)
        return updated
    }

    /// A car that is parked cannot be removed. The stay is paid for and still counting
    /// down, and the card on the home screen would be left naming a car the driver can no
    /// longer find in the app.
    func delete(_ vehicle: Vehicle, now: Date = .storageNow()) throws {
        let isParked = try sessionService.activeSession(
            forVehicle: vehicle.id,
            userID: vehicle.ownerID,
            at: now
        ) != nil

        guard !isParked else { throw VehicleError.vehicleIsParked }

        try repository.delete(vehicleWithID: vehicle.id)
    }

    /// Plates are unique per owner, not globally: two accounts on the same device may
    /// well be two people registering the same family car.
    private func checkPlateIsFree(_ plate: String, ownerID: UUID, ignoring id: UUID?) throws {
        let isTaken = try repository.vehicles(ownedBy: ownerID)
            .contains { $0.licensePlate == plate && $0.id != id }

        if isTaken {
            throw VehicleError.licensePlateAlreadyRegistered
        }
    }
}
