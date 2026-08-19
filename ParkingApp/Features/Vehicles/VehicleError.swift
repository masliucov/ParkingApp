import Foundation

/// Everything that can stop a vehicle from being saved.
enum VehicleError: LocalizedError, Equatable {
    case invalidModel
    case invalidLicensePlate
    case licensePlateAlreadyRegistered
    case vehicleIsParked

    var errorDescription: String? {
        switch self {
        case .invalidModel:
            return "Please choose the car brand."
        case .invalidLicensePlate:
            return "Please enter a valid license plate."
        case .licensePlateAlreadyRegistered:
            return "You already have a vehicle with this license plate."
        case .vehicleIsParked:
            return "This car is parked right now. Wait for the stay to end before deleting it."
        }
    }
}
