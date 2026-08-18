import CoreLocation
import Foundation

/// Picks the rough places to go looking for street parking.
///
/// The positions are deterministic: the same spot on the map always produces the same
/// candidates, so nothing moves around while the phone's GPS drifts.
enum ParkingSpotCandidates {
    static let minimumDistance: CLLocationDistance = 150
    static let maximumDistance: CLLocationDistance = 900

    private static let metersPerDegreeLatitude: Double = 111_320

    static func coordinates(around center: CLLocationCoordinate2D, count: Int) -> [CLLocationCoordinate2D] {
        guard count > 0 else { return [] }

        let anchor = anchor(for: center)
        var generator = SeededRandomGenerator(seed: seed(for: anchor))
        let slice = (2 * Double.pi) / Double(count)

        var candidates: [CLLocationCoordinate2D] = []
        for index in 0..<count {
            // One candidate per slice of the compass, so they surround the user instead
            // of bunching up on one side.
            let bearing = slice * Double(index) + Double.random(in: 0..<slice, using: &generator)
            let distance = Double.random(in: minimumDistance...maximumDistance, using: &generator)

            candidates.append(coordinate(from: anchor, distance: distance, bearing: bearing))
        }
        return candidates
    }

    /// The centre of a grid cell roughly 100 metres across.
    ///
    /// Both the seed and the candidate positions hang off this instead of the raw
    /// reading, so the spots stay put while the GPS wanders.
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

    /// Flat-earth offset. Under a kilometre the error is a few metres, and the point is
    /// only a starting guess anyway.
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
