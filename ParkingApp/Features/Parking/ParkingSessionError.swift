import Foundation

/// Everything that can stop a parking session from starting.
enum ParkingSessionError: LocalizedError, Equatable {
    case alreadyParked
    case lotIsFull

    var errorDescription: String? {
        switch self {
        case .alreadyParked:
            return "You already have parking running. Wait for it to end before starting another."
        case .lotIsFull:
            return "This spot has no free spaces right now."
        }
    }
}
