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
    private let onFinished: () -> Void

    init(
        service: VehicleService,
        ownerID: UUID,
        vehicle: Vehicle?,
        onFinished: @escaping () -> Void
    ) {
        self.service = service
        self.ownerID = ownerID
        self.vehicle = vehicle
        self.onFinished = onFinished
        model = vehicle?.model ?? ""
        licensePlate = vehicle?.licensePlate ?? ""
    }

    var title: String {
        vehicle == nil ? "Add vehicle" : "Edit vehicle"
    }

    var canSubmit: Bool {
        !model.isEmpty && !licensePlate.isEmpty
    }

    /// Only a vehicle that is already registered can be removed.
    var canDelete: Bool {
        vehicle != nil
    }

    func submit() {
        do {
            if let vehicle {
                _ = try service.update(vehicle, model: model, licensePlate: licensePlate)
            } else {
                _ = try service.register(model: model, licensePlate: licensePlate, ownerID: ownerID)
            }
            errorMessage = nil
            onFinished()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Refused while the car is parked, in which case the message says so and the form
    /// stays open.
    func delete() {
        guard let vehicle else { return }

        do {
            try service.delete(vehicle)
            errorMessage = nil
            onFinished()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
