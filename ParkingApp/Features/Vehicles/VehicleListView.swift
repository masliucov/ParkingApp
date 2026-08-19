import SwiftUI

struct VehicleListView: View {
    @State private var viewModel: VehicleListViewModel

    private let vehicleService: VehicleService
    private let ownerID: UUID

    init(vehicleService: VehicleService, ownerID: UUID) {
        self.vehicleService = vehicleService
        self.ownerID = ownerID
        _viewModel = State(
            initialValue: VehicleListViewModel(service: vehicleService, ownerID: ownerID)
        )
    }

    var body: some View {
        content
            .navigationTitle("My vehicles")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        viewModel.isAddingVehicle = true
                    } label: {
                        Label("Add vehicle", systemImage: "plus")
                    }
                }
            }
            .task {
                viewModel.load()
            }
            .sheet(isPresented: $viewModel.isAddingVehicle) {
                form(for: nil) {
                    viewModel.isAddingVehicle = false
                }
            }
            .sheet(item: $viewModel.vehicleBeingEdited) { vehicle in
                form(for: vehicle) {
                    viewModel.vehicleBeingEdited = nil
                }
            }
            .alert("Something went wrong", isPresented: isShowingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.vehicles.isEmpty {
            ContentUnavailableView {
                Label("No vehicles yet", systemImage: "car")
            } description: {
                Text("Add the car you want to park.")
            } actions: {
                Button("Add vehicle") {
                    viewModel.isAddingVehicle = true
                }
                .buttonStyle(.borderedProminent)
            }
        } else {
            List {
                ForEach(viewModel.vehicles) { vehicle in
                    Button {
                        viewModel.vehicleBeingEdited = vehicle
                    } label: {
                        VehicleRow(vehicle: vehicle, isParked: viewModel.isParked(vehicle))
                    }
                    .buttonStyle(.plain)
                }
                .onDelete { offsets in
                    viewModel.delete(at: offsets)
                }
            }
        }
    }

    private func form(for vehicle: Vehicle?, onClose: @escaping () -> Void) -> some View {
        VehicleFormView(
            vehicleService: vehicleService,
            ownerID: ownerID,
            vehicle: vehicle
        ) {
            onClose()
            viewModel.load()
        }
    }

    private var isShowingError: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: { isPresented in
                if !isPresented { viewModel.dismissError() }
            }
        )
    }
}

private struct VehicleRow: View {
    let vehicle: Vehicle
    let isParked: Bool

    var body: some View {
        HStack(spacing: Theme.Spacing.medium) {
            Image(systemName: "car.fill")
                .foregroundStyle(Color.accentColor)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: Theme.Spacing.extraSmall) {
                Text(vehicle.model)
                    .font(.body.weight(.medium))

                HStack(spacing: Theme.Spacing.small) {
                    Text(vehicle.licensePlate)
                        .font(.footnote.monospaced())
                        .foregroundStyle(.secondary)

                    if isParked {
                        parkedBadge
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.tertiary)
                .accessibilityHidden(true)
        }
        .padding(.vertical, Theme.Spacing.extraSmall)
    }

    private var parkedBadge: some View {
        Text("Parked")
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, Theme.Spacing.small)
            .padding(.vertical, 2)
            .background(Color.accentColor.opacity(0.15), in: Capsule())
            .foregroundStyle(Color.accentColor)
            .accessibilityLabel("Parked right now")
    }
}

#Preview {
    NavigationStack {
        VehicleListView(
            vehicleService: AppEnvironment(store: InMemoryKeyValueStore()).vehicleService,
            ownerID: UUID()
        )
    }
}
