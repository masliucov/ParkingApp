import Foundation
import Observation

@MainActor
@Observable
final class VehicleListViewModel {
    private(set) var vehicles: [Vehicle] = []
    private(set) var errorMessage: String?

    var isAddingVehicle = false
    var vehicleBeingEdited: Vehicle?

    private let service: VehicleService
    private let ownerID: UUID

    init(service: VehicleService, ownerID: UUID) {
        self.service = service
        self.ownerID = ownerID
    }

    func load() {
        do {
            vehicles = try service.vehicles(ownedBy: ownerID)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func delete(at offsets: IndexSet) {
        let selected = offsets.map { vehicles[$0] }
        do {
            for vehicle in selected {
                try service.delete(vehicle)
            }
            load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func dismissError() {
        errorMessage = nil
    }
}
