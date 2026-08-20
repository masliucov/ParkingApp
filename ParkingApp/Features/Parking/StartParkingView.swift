import SwiftUI

struct StartParkingView: View {
    @State private var viewModel: StartParkingViewModel
    @State private var isAddingFunds = false
    @Environment(\.dismiss) private var dismiss

    /// The same balance the map shows, so topping up here changes it there too.
    private let wallet: WalletViewModel

    init(
        lot: ParkingLot,
        user: User,
        vehicleService: VehicleService,
        sessionService: ParkingSessionService,
        wallet: WalletViewModel,
        onStarted: @escaping () -> Void
    ) {
        self.wallet = wallet
        _viewModel = State(
            initialValue: StartParkingViewModel(
                lot: lot,
                user: user,
                vehicleService: vehicleService,
                sessionService: sessionService,
                onStarted: onStarted
            )
        )
    }

    @ViewBuilder
    private func vehicleRow(_ vehicle: Vehicle) -> some View {
        let label = "\(vehicle.model) · \(vehicle.licensePlate)"

        if viewModel.isParked(vehicle) {
            // Inline pickers hand their rows a single label, so the state has to travel
            // in the text itself to survive being drawn as a picker option.
            Text("\(label) — already parked")
        } else {
            Text(label)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Spot") {
                    LabeledContent("Street", value: viewModel.lot.name)
                    LabeledContent("Rate", value: "\(viewModel.lot.formattedHourlyRate) / hour")
                }

                Section("Vehicle") {
                    if viewModel.hasVehicles {
                        Picker("Vehicle", selection: $viewModel.selectedVehicleID) {
                            ForEach(viewModel.vehicles) { vehicle in
                                vehicleRow(vehicle)
                                    .tag(Optional(vehicle.id))
                            }
                        }
                        .pickerStyle(.inline)
                        .labelsHidden()
                    } else {
                        Text("Register a vehicle before you park.")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("How long") {
                    Picker("Duration", selection: $viewModel.duration) {
                        ForEach(ParkingDuration.allCases) { duration in
                            Text(duration.title).tag(duration)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }

                Section {
                    LabeledContent("Total", value: viewModel.formattedPrice)
                        .font(.headline)

                    LabeledContent("Balance", value: viewModel.formattedBalance)
                        .foregroundStyle(viewModel.hasEnoughBalance ? Color.primary : Color.orange)

                    if let balanceWarning = viewModel.balanceWarning {
                        InsufficientBalanceNotice(message: balanceWarning) {
                            isAddingFunds = true
                        }
                    }
                } footer: {
                    Text("No card is charged. Paying is simulated in this app.")
                }

                if let errorMessage = viewModel.errorMessage {
                    Section {
                        FormErrorText(message: errorMessage)
                    }
                }
            }
            .navigationTitle("Start parking")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button(viewModel.payButtonTitle) {
                    viewModel.pay()
                }
                .buttonStyle(.primary)
                .disabled(!viewModel.canPay)
                .padding(Theme.Spacing.large)
                .background(.bar)
            }
            .task {
                viewModel.load()
            }
            .onChange(of: wallet.balance, initial: true) { _, balance in
                viewModel.balance = balance
            }
            .sheet(isPresented: $isAddingFunds) {
                AddFundsView(wallet: wallet)
            }
        }
    }
}

#Preview {
    StartParkingView(
        lot: ParkingLot(
            id: "preview",
            name: "Rua Augusta",
            latitude: 38.7112,
            longitude: -9.1376,
            hourlyRate: 1.20,
            availableSpaces: 8,
            totalSpaces: 40
        ),
        user: User(id: UUID(), name: "Ana Silva", email: "ana@example.com", createdAt: Date()),
        vehicleService: AppEnvironment(store: InMemoryKeyValueStore()).vehicleService,
        sessionService: ParkingSessionService(
            repository: StoredParkingSessionRepository(store: InMemoryKeyValueStore()),
            wallet: WalletService(repository: StoredWalletRepository(store: InMemoryKeyValueStore()))
        ),
        wallet: WalletViewModel(
            service: WalletService(repository: StoredWalletRepository(store: InMemoryKeyValueStore())),
            userID: UUID()
        ),
        onStarted: {}
    )
}
