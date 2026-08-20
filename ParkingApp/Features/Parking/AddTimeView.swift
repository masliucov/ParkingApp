import SwiftUI

struct AddTimeView: View {
    @State private var viewModel: AddTimeViewModel
    @State private var isAddingFunds = false
    @Environment(\.dismiss) private var dismiss

    /// The same balance the map shows, so topping up here changes it there too.
    private let wallet: WalletViewModel

    init(
        session: ParkingSession,
        sessionService: ParkingSessionService,
        wallet: WalletViewModel,
        onExtended: @escaping () -> Void
    ) {
        self.wallet = wallet
        _viewModel = State(
            initialValue: AddTimeViewModel(
                session: session,
                sessionService: sessionService,
                onExtended: onExtended
            )
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Parking") {
                    LabeledContent("Street", value: viewModel.session.lot.name)
                    LabeledContent("Vehicle", value: viewModel.session.vehicle.licensePlate)
                    LabeledContent("Ends at", value: viewModel.formattedCurrentEndTime)
                }

                Section("Add") {
                    Picker("Extra time", selection: $viewModel.duration) {
                        ForEach(ParkingDuration.allCases) { duration in
                            Text(duration.title).tag(duration)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }

                Section {
                    LabeledContent("New end time", value: viewModel.formattedNewEndTime)
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
            .navigationTitle("Add time")
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
    AddTimeView(
        session: ParkingSession(
            id: UUID(),
            userID: UUID(),
            vehicle: Vehicle(
                id: UUID(),
                ownerID: UUID(),
                model: "Renault Clio",
                licensePlate: "AA-00-BB",
                createdAt: Date()
            ),
            lot: ParkingLot(
                id: "preview",
                name: "Rua Augusta",
                latitude: 38.7112,
                longitude: -9.1376,
                hourlyRate: .cents(120),
                availableSpaces: 8,
                totalSpaces: 40
            ),
            startedAt: Date(),
            expiresAt: Date().addingTimeInterval(3600),
            amountPaid: .cents(120)
        ),
        sessionService: ParkingSessionService(
            repository: StoredParkingSessionRepository(store: InMemoryKeyValueStore()),
            wallet: WalletService(repository: StoredWalletRepository(store: InMemoryKeyValueStore()))
        ),
        wallet: WalletViewModel(
            service: WalletService(repository: StoredWalletRepository(store: InMemoryKeyValueStore())),
            userID: UUID()
        ),
        onExtended: {}
    )
}
