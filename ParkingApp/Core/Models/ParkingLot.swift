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

    /// Four digits a driver can read off the map and type back into the search field.
    ///
    /// Derived from `id` rather than stored, so a spot keeps its code between searches and
    /// launches, and stays out of the sessions that hold a copy of this lot.
    var code: String {
        String(format: "%04d", StableHash.of(id) % 10_000)
    }

    var hasSpacesAvailable: Bool {
        availableSpaces > 0
    }

    var formattedHourlyRate: String {
        ParkingPricing.formatted(hourlyRate)
    }
}
