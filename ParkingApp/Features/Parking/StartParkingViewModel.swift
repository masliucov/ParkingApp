import Foundation
import Observation

@MainActor
@Observable
final class StartParkingViewModel {
    let lot: ParkingLot

    private(set) var vehicles: [Vehicle] = []
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
        selectedVehicleID != nil && lot.hasSpacesAvailable
    }

    func load() {
        do {
            vehicles = try vehicleService.vehicles(ownedBy: user.id)
            selectedVehicleID = selectedVehicleID ?? vehicles.first?.id
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
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
