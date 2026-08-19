import Foundation

/// Everything that can stop a parking session from starting.
enum ParkingSessionError: LocalizedError, Equatable {
    case vehicleAlreadyParked
    case lotIsFull
    case sessionEnded

    var errorDescription: String? {
        switch self {
        case .vehicleAlreadyParked:
            return "This vehicle is already parked. Add time to it instead of starting again."
        case .lotIsFull:
            return "This spot has no free spaces right now."
        case .sessionEnded:
            return "Your parking has already ended. Start a new one."
        }
    }
}
