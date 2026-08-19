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

    /// Spots the driver has parked at before, searchable by code even when they are miles
    /// away. Only consulted once something is typed.
    private(set) var rememberedLots: [ParkingLot] = []

    private let locationProvider: LocationProvider
    private let finder: StreetParkingFinder
    private let sessionService: ParkingSessionService
    private let userID: UUID

    init(
        locationProvider: LocationProvider,
        sessionService: ParkingSessionService,
        userID: UUID,
        finder: StreetParkingFinder = StreetParkingFinder()
    ) {
        self.locationProvider = locationProvider
        self.sessionService = sessionService
        self.userID = userID
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
    ///
    /// A spot opened from the history is added on top, because it is somewhere the driver
    /// parked before rather than something this search turned up, and it would otherwise
    /// have a card with no pin under it.
    var visibleLots: [ParkingLot] {
        let matches = ParkingLotSearch.matching(
            query,
            nearby: lots,
            remembered: rememberedLots
        )

        guard let selectedLot, !matches.contains(where: { $0.id == selectedLot.id }) else {
            return matches
        }
        return matches + [selectedLot]
    }

    /// Collects the distinct spots out of the driver's stays, newest first, so a code from
    /// a recent receipt is the one found soonest.
    func loadRememberedLots() {
        guard let sessions = try? sessionService.sessions(for: userID) else { return }

        var seen = Set<String>()
        rememberedLots = sessions
            .reversed()
            .map(\.lot)
            .filter { seen.insert($0.id).inserted }
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
