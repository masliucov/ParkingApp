import SwiftUI

struct VehicleFormView: View {
    @State private var viewModel: VehicleFormViewModel
    @State private var isChoosingMake = false
    @State private var isConfirmingDelete = false
    @Environment(\.dismiss) private var dismiss

    init(
        vehicleService: VehicleService,
        ownerID: UUID,
        vehicle: Vehicle?,
        onFinished: @escaping () -> Void
    ) {
        _viewModel = State(
            initialValue: VehicleFormViewModel(
                service: vehicleService,
                ownerID: ownerID,
                vehicle: vehicle,
                onFinished: onFinished
            )
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.medium) {
                    FormSelectionField(
                        title: "Car brand",
                        value: viewModel.model.isEmpty ? nil : viewModel.model,
                        placeholder: "Select a brand"
                    ) {
                        isChoosingMake = true
                    }
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

                    if viewModel.canDelete {
                        Button("Delete vehicle", role: .destructive) {
                            isConfirmingDelete = true
                        }
                        .padding(.top, Theme.Spacing.small)
                    }
                }
                .padding(Theme.Spacing.large)
                .frame(maxWidth: Theme.Layout.maxContentWidth)
                .frame(maxWidth: .infinity)
            }
            .navigationTitle(viewModel.title)
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $isChoosingMake) {
                CarMakePicker(selection: $viewModel.model)
            }
            .confirmationDialog(
                "Delete this vehicle?",
                isPresented: $isConfirmingDelete,
                titleVisibility: .visible
            ) {
                Button("Delete vehicle", role: .destructive) {
                    viewModel.delete()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Past parking keeps this car in your history. This cannot be undone.")
            }
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
        vehicleService: AppEnvironment(store: InMemoryKeyValueStore()).vehicleService,
        ownerID: UUID(),
        vehicle: nil,
        onFinished: {}
    )
}
