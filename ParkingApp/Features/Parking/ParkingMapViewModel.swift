import CoreLocation
import Foundation
import Observation

@MainActor
@Observable
final class ParkingMapViewModel {
    var selectedLot: ParkingLot?

    private let locationProvider: LocationProvider

    init(locationProvider: LocationProvider) {
        self.locationProvider = locationProvider
    }

    var coordinate: CLLocationCoordinate2D? {
        locationProvider.coordinate
    }

    var errorMessage: String? {
        locationProvider.errorMessage
    }

    var isLocationDenied: Bool {
        locationProvider.isDenied
    }

    var isWaitingForLocation: Bool {
        locationProvider.coordinate == nil && !locationProvider.isDenied
    }

    /// Generated on demand: the result only depends on the coordinate, so there is
    /// nothing to keep in sync.
    var lots: [ParkingLot] {
        guard let coordinate else { return [] }
        return ParkingLotGenerator.lots(around: coordinate)
    }

    func requestLocation() {
        locationProvider.requestLocation()
    }

    func select(_ lot: ParkingLot) {
        selectedLot = lot
    }

    func clearSelection() {
        selectedLot = nil
    }

    func formattedDistance(to lot: ParkingLot) -> String? {
        guard let coordinate else { return nil }

        let origin = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let destination = CLLocation(latitude: lot.latitude, longitude: lot.longitude)

        return Measurement(value: origin.distance(from: destination), unit: UnitLength.meters)
            .formatted(.measurement(width: .abbreviated, usage: .road))
    }
}
