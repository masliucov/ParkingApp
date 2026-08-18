import CoreLocation
import Foundation

/// A parking lot shown on the map.
struct ParkingLot: Codable, Equatable, Identifiable, Sendable {
    let id: String
    let name: String
    let latitude: Double
    let longitude: Double
    let hourlyRate: Decimal
    let availableSpaces: Int
    let totalSpaces: Int

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var hasSpacesAvailable: Bool {
        availableSpaces > 0
    }

    var formattedHourlyRate: String {
        ParkingPricing.formatted(hourlyRate)
    }
}
