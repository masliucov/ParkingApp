import CoreLocation
import Foundation

/// Invents the commercial details of a parking lot.
///
/// Apple Maps knows where parking is, not what it costs, so the price and the occupancy
/// are made up. Both are derived from the lot's own name and position, which keeps them
/// stable between launches instead of changing on every search.
enum ParkingLotPricing {
    static let hourlyRates: [Decimal] = [0.80, 1.00, 1.20, 1.50, 1.80, 2.00, 2.50]

    struct Details: Equatable, Sendable {
        let hourlyRate: Decimal
        let availableSpaces: Int
        let totalSpaces: Int
    }

    static func details(name: String, coordinate: CLLocationCoordinate2D) -> Details {
        var generator = SeededRandomGenerator(seed: seed(name: name, coordinate: coordinate))
        let totalSpaces = Int.random(in: 40...400, using: &generator)

        return Details(
            hourlyRate: hourlyRates.randomElement(using: &generator) ?? 1.50,
            availableSpaces: Int.random(in: 0...totalSpaces, using: &generator),
            totalSpaces: totalSpaces
        )
    }

    /// Stable across searches, so the same real place keeps the same identity.
    static func identifier(name: String, coordinate: CLLocationCoordinate2D) -> String {
        "\(name)@\(rounded(coordinate.latitude)),\(rounded(coordinate.longitude))"
    }

    private static func seed(name: String, coordinate: CLLocationCoordinate2D) -> UInt64 {
        let latitude = Int64((coordinate.latitude * 100_000).rounded())
        let longitude = Int64((coordinate.longitude * 100_000).rounded())
        let position = (latitude &* 73_856_093) ^ (longitude &* 19_349_663)

        return UInt64(bitPattern: position) ^ nameSeed(name)
    }

    /// `String.hashValue` is salted per launch, so the characters are folded by hand to
    /// keep the price of a lot the same every time the app opens.
    private static func nameSeed(_ name: String) -> UInt64 {
        name.unicodeScalars.reduce(UInt64(14_695_981_039_346_656_037)) { hash, scalar in
            (hash ^ UInt64(scalar.value)) &* 1_099_511_628_211
        }
    }

    /// Five decimals is around a metre, enough to tell two lots apart.
    private static func rounded(_ degrees: Double) -> String {
        String(format: "%.5f", degrees)
    }
}
