import SwiftUI

struct VehicleFormView: View {
    @State private var viewModel: VehicleFormViewModel
    @Environment(\.dismiss) private var dismiss

    init(
        vehicleService: VehicleService,
        ownerID: UUID,
        vehicle: Vehicle?,
        onSaved: @escaping () -> Void
    ) {
        _viewModel = State(
            initialValue: VehicleFormViewModel(
                service: vehicleService,
                ownerID: ownerID,
                vehicle: vehicle,
                onSaved: onSaved
            )
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.medium) {
                    FormField(
                        title: "Car model",
                        text: $viewModel.model,
                        autocapitalization: .words
                    )
                    FormField(
                        title: "License plate",
                        text: $viewModel.licensePlate,
                        autocapitalization: .characters
                    )

                    if let errorMessage = viewModel.errorMessage {
                        FormErrorText(message: errorMessage)
                    }

                    Button("Save") {
                        viewModel.submit()
                    }
                    .buttonStyle(.primary)
                    .disabled(!viewModel.canSubmit)
                    .padding(.top, Theme.Spacing.small)
                }
                .padding(Theme.Spacing.large)
                .frame(maxWidth: Theme.Layout.maxContentWidth)
                .frame(maxWidth: .infinity)
            }
            .navigationTitle(viewModel.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    VehicleFormView(
        vehicleService: VehicleService(
            repository: StoredVehicleRepository(store: InMemoryKeyValueStore())
        ),
        ownerID: UUID(),
        vehicle: nil,
        onSaved: {}
    )
}
