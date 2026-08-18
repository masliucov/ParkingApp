import Foundation

/// How long a driver can pay for in one go.
enum ParkingDuration: Int, CaseIterable, Identifiable, Sendable {
    case thirtyMinutes = 30
    case oneHour = 60
    case twoHours = 120
    case threeHours = 180
    case fourHours = 240
    case eightHours = 480

    var id: Int { rawValue }

    var minutes: Int { rawValue }

    var timeInterval: TimeInterval { TimeInterval(rawValue * 60) }

    var title: String {
        switch self {
        case .thirtyMinutes:
            return "30 min"
        case .oneHour:
            return "1 hour"
        default:
            return "\(minutes / 60) hours"
        }
    }
}
