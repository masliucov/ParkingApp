import SwiftUI

struct ParkingHistoryView: View {
    @State private var viewModel: ParkingHistoryViewModel

    init(sessionService: ParkingSessionService, userID: UUID) {
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
                ParkingHistoryRow(session: session)
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

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.extraSmall) {
            HStack {
                Text(session.lot.name)
                    .font(.body.weight(.medium))

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
}

#Preview {
    NavigationStack {
        ParkingHistoryView(
            sessionService: ParkingSessionService(
                repository: StoredParkingSessionRepository(store: InMemoryKeyValueStore())
            ),
            userID: UUID()
        )
    }
}
