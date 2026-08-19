import Foundation
import Observation

@MainActor
@Observable
final class StartParkingViewModel {
    let lot: ParkingLot

    private(set) var vehicles: [Vehicle] = []
    private(set) var parkedVehicleIDs: Set<UUID> = []
    private(set) var errorMessage: String?

    var selectedVehicleID: UUID?
    var duration: ParkingDuration = .oneHour

    private let user: User
    private let vehicleService: VehicleService
    private let sessionService: ParkingSessionService
    private let onStarted: () -> Void

    init(
        lot: ParkingLot,
        user: User,
        vehicleService: VehicleService,
        sessionService: ParkingSessionService,
        onStarted: @escaping () -> Void
    ) {
        self.lot = lot
        self.user = user
        self.vehicleService = vehicleService
        self.sessionService = sessionService
        self.onStarted = onStarted
    }

    var hasVehicles: Bool {
        !vehicles.isEmpty
    }

    var price: Decimal {
        ParkingPricing.price(hourlyRate: lot.hourlyRate, minutes: duration.minutes)
    }

    var formattedPrice: String {
        ParkingPricing.formatted(price)
    }

    var payButtonTitle: String {
        "Pay \(formattedPrice)"
    }

    var canPay: Bool {
        guard let selectedVehicleID, lot.hasSpacesAvailable else { return false }
        return !parkedVehicleIDs.contains(selectedVehicleID)
    }

    /// A vehicle with a stay running cannot start another one, so the picker says so
    /// instead of letting the driver find out from an error after tapping Pay.
    func isParked(_ vehicle: Vehicle) -> Bool {
        parkedVehicleIDs.contains(vehicle.id)
    }

    func load() {
        do {
            vehicles = try vehicleService.vehicles(ownedBy: user.id)
            parkedVehicleIDs = try sessionService.parkedVehicleIDs(for: user.id)
            selectedVehicleID = selectedVehicleID ?? firstVehicleFreeToPark?.id
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Preferring a vehicle that is free keeps the common case — park the other car —
    /// one tap away, and falls back to the first vehicle so the picker is never empty.
    private var firstVehicleFreeToPark: Vehicle? {
        vehicles.first { !isParked($0) } ?? vehicles.first
    }

    func pay() {
        guard let vehicle = vehicles.first(where: { $0.id == selectedVehicleID }) else { return }

        do {
            _ = try sessionService.start(
                lot: lot,
                vehicle: vehicle,
                duration: duration,
                userID: user.id
            )
            errorMessage = nil
            onStarted()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
