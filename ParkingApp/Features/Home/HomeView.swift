import SwiftUI

/// What a signed-in user sees.
struct HomeView: View {
    let user: User
    let environment: AppEnvironment

    @State private var viewModel: HomeViewModel
    @State private var sessionBeingExtended: ParkingSession?

    init(user: User, environment: AppEnvironment) {
        self.user = user
        self.environment = environment
        _viewModel = State(
            initialValue: HomeViewModel(
                sessionService: environment.sessionService,
                notifications: environment.notifications,
                userID: user.id
            )
        )
    }

    /// By value, so a screen is only built when it is opened. Building the map up front
    /// left it with the width of a list row.
    private enum Destination: Hashable {
        case parking
        case vehicles
        case history
        case settings
    }

    var body: some View {
        NavigationStack {
            List {
                greeting

                if let session = viewModel.activeSession {
                    activeParking(session)
                }

                Section {
                    NavigationLink(value: Destination.parking) {
                        Label("Find parking", systemImage: "map.fill")
                    }

                    NavigationLink(value: Destination.vehicles) {
                        Label("My vehicles", systemImage: "car.fill")
                    }

                    NavigationLink(value: Destination.history) {
                        Label("History", systemImage: "clock.arrow.circlepath")
                    }

                    NavigationLink(value: Destination.settings) {
                        Label("Settings", systemImage: "gearshape.fill")
                    }
                }

                Section {
                    Button("Sign out", role: .destructive) {
                        environment.signOut()
                    }
                }
            }
            .navigationTitle("ParkingApp")
            .navigationDestination(for: Destination.self, destination: view(for:))
            .task {
                await viewModel.refresh()
            }
            .task(id: viewModel.activeSession?.id) {
                await viewModel.waitForExpiry()
            }
            .sheet(item: $sessionBeingExtended) { session in
                AddTimeView(session: session, sessionService: environment.sessionService) {
                    sessionBeingExtended = nil
                    Task { await viewModel.refresh() }
                }
            }
        }
    }

    private var greeting: some View {
        Section {
            VStack(alignment: .leading, spacing: Theme.Spacing.extraSmall) {
                Text("Welcome, \(user.name)")
                    .font(.title3.bold())
                Text(user.email)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, Theme.Spacing.extraSmall)
        }
    }

    private func activeParking(_ session: ParkingSession) -> some View {
        Section("Active parking") {
            ActiveParkingCard(session: session) {
                sessionBeingExtended = session
            }
        }
    }

    @ViewBuilder
    private func view(for destination: Destination) -> some View {
        switch destination {
        case .parking:
            ParkingMapView(user: user, environment: environment) {
                Task { await viewModel.refresh() }
            }

        case .vehicles:
            VehicleListView(vehicleService: environment.vehicleService, ownerID: user.id)

        case .history:
            ParkingHistoryView(sessionService: environment.sessionService, userID: user.id)

        case .settings:
            SettingsView(authService: environment.authService, user: user) { updated in
                environment.setCurrentUser(updated)
            }
        }
    }
}

#Preview {
    HomeView(
        user: User(id: UUID(), name: "Ana Silva", email: "ana@example.com", createdAt: Date()),
        environment: AppEnvironment(store: InMemoryKeyValueStore())
    )
}
