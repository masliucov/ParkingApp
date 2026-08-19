import CoreLocation
import Foundation

/// Invents what a spot costs and how full it is.
///
/// There is no source of real parking prices, so both are made up. They come from the
/// spot's own street and position, which keeps them steady between launches.
enum ParkingLotPricing {
    static let hourlyRates: [Decimal] = [80, 100, 120, 150, 180, 200, 250].map(Decimal.cents)

    struct Details: Equatable, Sendable {
        let hourlyRate: Decimal
        let availableSpaces: Int
        let totalSpaces: Int
    }

    static func details(name: String, coordinate: CLLocationCoordinate2D) -> Details {
        var generator = SeededRandomGenerator(seed: seed(name: name, coordinate: coordinate))
        let totalSpaces = Int.random(in: 40...400, using: &generator)

        return Details(
            hourlyRate: hourlyRates.randomElement(using: &generator) ?? .cents(150),
            availableSpaces: Int.random(in: 0...totalSpaces, using: &generator),
            totalSpaces: totalSpaces
        )
    }

    /// Stable across searches, so the same place keeps the same identity.
    static func identifier(name: String, coordinate: CLLocationCoordinate2D) -> String {
        "\(name)@\(rounded(coordinate.latitude)),\(rounded(coordinate.longitude))"
    }

    private static func seed(name: String, coordinate: CLLocationCoordinate2D) -> UInt64 {
        let latitude = Int64((coordinate.latitude * 100_000).rounded())
        let longitude = Int64((coordinate.longitude * 100_000).rounded())
        let position = (latitude &* 73_856_093) ^ (longitude &* 19_349_663)

        return UInt64(bitPattern: position) ^ StableHash.of(name)
    }

    /// Five decimals is around a metre, enough to tell two lots apart.
    private static func rounded(_ degrees: Double) -> String {
        String(format: "%.5f", degrees)
    }
}
