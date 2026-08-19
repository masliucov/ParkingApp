import CoreLocation
import MapKit

/// Works out what the map should frame when it is sent to a particular spot.
enum ParkingMapCamera {
    /// Close enough to see which side of the street the spot was on.
    static let defaultSpan: CLLocationDistance = 400

    /// Roughly the share of the map's height taken by the card pinned to the bottom.
    private static let cardClearance = 0.25

    /// Constant everywhere, unlike a degree of longitude, which is why the spot is nudged
    /// along this axis and not the other.
    private static let metresPerDegreeLatitude = 111_320.0

    /// Frames `lot` above the card at the bottom of the map rather than dead centre, where
    /// the card would sit on top of its pin.
    ///
    /// Moving the centre south lifts the spot up the screen.
    static func region(
        focusing lot: ParkingLot,
        span: CLLocationDistance = defaultSpan
    ) -> MKCoordinateRegion {
        let shift = span * cardClearance / metresPerDegreeLatitude

        return MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: lot.latitude - shift,
                longitude: lot.longitude
            ),
            latitudinalMeters: span,
            longitudinalMeters: span
        )
    }
}
