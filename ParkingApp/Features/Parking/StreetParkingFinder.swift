import CoreLocation
import MapKit

enum StreetParkingError: LocalizedError, Equatable {
    case mapServiceUnavailable

    var errorDescription: String? {
        "We could not reach the map service. Check your connection and try again."
    }
}

/// Puts random parking spots on real streets near the user.
///
/// A random point on its own can land in the sea, inside a block or in the middle of a
/// field. So each point is only a guess: walking directions are requested towards it,
/// and the route that comes back runs along real streets. The end of that route is the
/// spot, and the route's name is the street it sits on.
struct StreetParkingFinder: Sendable {
    static let maximumSpots = 5

    /// Throws only when every single lookup failed, which means the map service could
    /// not be reached rather than that the area has no streets.
    func spots(near coordinate: CLLocationCoordinate2D, count: Int = maximumSpots) async throws -> [ParkingLot] {
        let candidates = ParkingSpotCandidates.coordinates(around: coordinate, count: count)
        guard !candidates.isEmpty else { return [] }

        let found = await withTaskGroup(of: ParkingLot?.self) { group in
            for candidate in candidates {
                group.addTask { await spot(at: candidate, from: coordinate) }
            }

            var spots: [ParkingLot] = []
            for await spot in group {
                if let spot {
                    spots.append(spot)
                }
            }
            return spots
        }

        guard !found.isEmpty else { throw StreetParkingError.mapServiceUnavailable }

        let origin = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return found.sorted { distance(from: origin, to: $0) < distance(from: origin, to: $1) }
    }

    private func spot(at candidate: CLLocationCoordinate2D, from origin: CLLocationCoordinate2D) async -> ParkingLot? {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: origin))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: candidate))
        request.transportType = .walking

        guard let route = try? await MKDirections(request: request).calculate().routes.first,
              let placement = endOfRoute(route) else {
            return nil
        }

        let name = route.name.isEmpty ? "Street parking" : route.name
        let details = ParkingLotPricing.details(name: name, coordinate: placement)

        return ParkingLot(
            id: ParkingLotPricing.identifier(name: name, coordinate: placement),
            name: name,
            latitude: placement.latitude,
            longitude: placement.longitude,
            hourlyRate: details.hourlyRate,
            availableSpaces: details.availableSpaces,
            totalSpaces: details.totalSpaces
        )
    }

    /// Where the walking route ends: the point on the street network closest to the
    /// candidate.
    private func endOfRoute(_ route: MKRoute) -> CLLocationCoordinate2D? {
        let polyline = route.polyline
        guard polyline.pointCount > 0 else { return nil }

        var coordinates = [CLLocationCoordinate2D](
            repeating: CLLocationCoordinate2D(),
            count: polyline.pointCount
        )
        polyline.getCoordinates(&coordinates, range: NSRange(location: 0, length: polyline.pointCount))

        return coordinates.last
    }

    private func distance(from origin: CLLocation, to lot: ParkingLot) -> CLLocationDistance {
        origin.distance(from: CLLocation(latitude: lot.latitude, longitude: lot.longitude))
    }
}
