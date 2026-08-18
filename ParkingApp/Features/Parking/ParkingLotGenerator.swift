import CoreLocation
import Foundation

/// Builds the nearby parking lots for a coordinate.
///
/// The app has no source of real parking data, so these lots are invented. The seed
/// comes from the coordinate itself, which keeps them in the same places instead of
/// moving every time the map redraws.
enum ParkingLotGenerator {
    static let defaultCount = 5
    static let minimumDistance: CLLocationDistance = 150
    static let maximumDistance: CLLocationDistance = 1200

    private static let metersPerDegreeLatitude: Double = 111_320
    private static let hourlyRates: [Decimal] = [0.80, 1.00, 1.20, 1.50, 1.80, 2.00, 2.50]
    private static let names = [
        "Central Garage",
        "Market Square Parking",
        "Riverside Car Park",
        "Station Parking",
        "Old Town Garage",
        "Harbour Parking",
        "Cathedral Car Park",
        "Park & Ride North",
        "City Hall Garage",
        "Green Avenue Parking",
    ]

    /// Never returns more lots than there are names available.
    static func lots(around center: CLLocationCoordinate2D, count: Int = defaultCount) -> [ParkingLot] {
        let anchor = anchor(for: center)
        let seed = seed(for: anchor)
        var generator = SeededRandomGenerator(seed: seed)
        let chosenNames = names.shuffled(using: &generator).prefix(max(0, count))

        var lots: [ParkingLot] = []
        for (index, name) in chosenNames.enumerated() {
            let distance = Double.random(in: minimumDistance...maximumDistance, using: &generator)
            let bearing = Double.random(in: 0..<(2 * .pi), using: &generator)
            let totalSpaces = Int.random(in: 40...400, using: &generator)
            let placement = coordinate(from: anchor, distance: distance, bearing: bearing)

            lots.append(
                ParkingLot(
                    id: "\(seed)-\(index)",
                    name: name,
                    latitude: placement.latitude,
                    longitude: placement.longitude,
                    hourlyRate: hourlyRates.randomElement(using: &generator) ?? 1.50,
                    availableSpaces: Int.random(in: 0...totalSpaces, using: &generator),
                    totalSpaces: totalSpaces
                )
            )
        }
        return lots
    }

    /// The centre of a grid cell roughly 100 metres across.
    ///
    /// Both the seed and the lot positions hang off this instead of the raw reading, so
    /// the lots stay where they are while the phone's GPS drifts around.
    private static func anchor(for coordinate: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
        CLLocationCoordinate2D(
            latitude: (coordinate.latitude * 1000).rounded() / 1000,
            longitude: (coordinate.longitude * 1000).rounded() / 1000
        )
    }

    private static func seed(for coordinate: CLLocationCoordinate2D) -> UInt64 {
        let latitude = Int64((coordinate.latitude * 1000).rounded())
        let longitude = Int64((coordinate.longitude * 1000).rounded())
        return UInt64(bitPattern: (latitude &* 73_856_093) ^ (longitude &* 19_349_663))
    }

    /// Flat-earth offset. Over a kilometre or two the error is a few metres, far below
    /// the accuracy this screen needs.
    private static func coordinate(
        from center: CLLocationCoordinate2D,
        distance: CLLocationDistance,
        bearing: Double
    ) -> CLLocationCoordinate2D {
        let latitudeOffset = (distance * cos(bearing)) / metersPerDegreeLatitude

        // Meridians converge towards the poles; the floor keeps the maths finite there.
        let convergence = max(cos(center.latitude * .pi / 180), 0.01)
        let longitudeOffset = (distance * sin(bearing)) / (metersPerDegreeLatitude * convergence)

        return CLLocationCoordinate2D(
            latitude: center.latitude + latitudeOffset,
            longitude: center.longitude + longitudeOffset
        )
    }
}
