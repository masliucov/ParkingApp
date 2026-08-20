import SwiftUI

struct ParkingHistoryView: View {
    @State private var viewModel: ParkingHistoryViewModel

    private let onShowOnMap: (ParkingLot) -> Void

    init(
        sessionService: ParkingSessionService,
        userID: UUID,
        onShowOnMap: @escaping (ParkingLot) -> Void
    ) {
        self.onShowOnMap = onShowOnMap
        _viewModel = State(
            initialValue: ParkingHistoryViewModel(sessionService: sessionService, userID: userID)
        )
    }

    var body: some View {
        content
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                viewModel.load()
            }
            .alert("Something went wrong", isPresented: isShowingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.sessions.isEmpty {
            ContentUnavailableView {
                Label("No parking yet", systemImage: "clock.arrow.circlepath")
            } description: {
                Text("Everywhere you park will show up here.")
            }
        } else {
            List(viewModel.sessions) { session in
                ParkingHistoryRow(session: session) {
                    onShowOnMap(session.lot)
                }
            }
        }
    }

    private var isShowingError: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: { _ in }
        )
    }
}

private struct ParkingHistoryRow: View {
    let session: ParkingSession
    let onShowOnMap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.extraSmall) {
            HStack {
                street

                Spacer()

                Text(session.formattedAmountPaid)
                    .font(.body.weight(.medium))
                    .monospacedDigit()
            }

            Text(session.startedAt.formatted(date: .abbreviated, time: .shortened))
                .font(.footnote)
                .foregroundStyle(.secondary)

            HStack(spacing: Theme.Spacing.medium) {
                Label(session.vehicle.licensePlate, systemImage: "car")
                Label(session.formattedTotalDuration, systemImage: "clock")
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, Theme.Spacing.extraSmall)
    }

    /// Tapping the street opens it on the map. The row itself stays inert: the rest of it
    /// is a receipt, and nothing else here is worth a tap.
    private var street: some View {
        Button(action: onShowOnMap) {
            HStack(spacing: Theme.Spacing.extraSmall) {
                Text(session.lot.name)
                    .font(.body.weight(.medium))
                    .multilineTextAlignment(.leading)

                Image(systemName: "map")
                    .font(.footnote)
            }
            .foregroundStyle(Color.accentColor)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(session.lot.name), show on map")
        .accessibilityAddTraits(.isButton)
    }
}

#Preview {
    NavigationStack {
        ParkingHistoryView(
            sessionService: ParkingSessionService(
                repository: StoredParkingSessionRepository(store: InMemoryKeyValueStore()),
                wallet: WalletService(repository: StoredWalletRepository(store: InMemoryKeyValueStore()))
            ),
            userID: UUID(),
            onShowOnMap: { _ in }
        )
    }
}
