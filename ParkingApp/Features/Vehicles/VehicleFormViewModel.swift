import Foundation
import Observation

@MainActor
@Observable
final class VehicleFormViewModel {
    var model: String
    var licensePlate: String

    private(set) var errorMessage: String?

    private let service: VehicleService
    private let ownerID: UUID
    private let vehicle: Vehicle?
    private let onSaved: () -> Void

    init(service: VehicleService, ownerID: UUID, vehicle: Vehicle?, onSaved: @escaping () -> Void) {
        self.service = service
        self.ownerID = ownerID
        self.vehicle = vehicle
        self.onSaved = onSaved
        model = vehicle?.model ?? ""
        licensePlate = vehicle?.licensePlate ?? ""
    }

    var title: String {
        vehicle == nil ? "Add vehicle" : "Edit vehicle"
    }

    var canSubmit: Bool {
        !model.isEmpty && !licensePlate.isEmpty
    }

    func submit() {
        do {
            if let vehicle {
                _ = try service.update(vehicle, model: model, licensePlate: licensePlate)
            } else {
                _ = try service.register(model: model, licensePlate: licensePlate, ownerID: ownerID)
            }
            errorMessage = nil
            onSaved()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
