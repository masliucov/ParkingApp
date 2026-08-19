import CoreLocation
import Foundation
import Observation

@MainActor
@Observable
final class ParkingMapViewModel {
    private(set) var lots: [ParkingLot] = []
    private(set) var isSearching = false
    private(set) var hasSearched = false
    private(set) var searchErrorMessage: String?

    var selectedLot: ParkingLot?
    var query = ""

    private let locationProvider: LocationProvider
    private let finder: StreetParkingFinder

    init(locationProvider: LocationProvider, finder: StreetParkingFinder = StreetParkingFinder()) {
        self.locationProvider = locationProvider
        self.finder = finder
    }

    var coordinate: CLLocationCoordinate2D? {
        locationProvider.coordinate
    }

    var locationErrorMessage: String? {
        locationProvider.errorMessage
    }

    var isLocationDenied: Bool {
        locationProvider.isDenied
    }

    var isWaitingForLocation: Bool {
        locationProvider.coordinate == nil && !locationProvider.isDenied
    }

    var hasNoNearbyParking: Bool {
        hasSearched && !isSearching && lots.isEmpty && searchErrorMessage == nil
    }

    /// What the map draws: everything found, or what matches the code or street typed.
    var visibleLots: [ParkingLot] {
        ParkingLotSearch.matching(query, in: lots)
    }

    /// A search that hides every spot needs saying, otherwise the map just looks empty.
    var hasNoMatches: Bool {
        !lots.isEmpty && visibleLots.isEmpty
    }

    /// Rounded to roughly 100 metres, so walking a few steps does not start a new search.
    var searchKey: String? {
        guard let coordinate else { return nil }
        let latitude = (coordinate.latitude * 1000).rounded()
        let longitude = (coordinate.longitude * 1000).rounded()
        return "\(latitude),\(longitude)"
    }

    func requestLocation() {
        locationProvider.requestLocation()
    }

    func loadLots() async {
        guard let coordinate else { return }

        isSearching = true
        searchErrorMessage = nil

        do {
            lots = try await finder.spots(near: coordinate)
            selectedLot = nil
        } catch {
            lots = []
            searchErrorMessage = error.localizedDescription
        }

        isSearching = false
        hasSearched = true
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
