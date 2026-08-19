import SwiftUI

/// What a signed-in user sees: the map first, everything else a tab away.
struct MainTabView: View {
    let user: User
    let environment: AppEnvironment

    @State private var viewModel: ActiveParkingViewModel
    @State private var selectedTab: AppTab = .map
    /// Set by the history, read once by the map, which clears it.
    @State private var lotToShow: ParkingLot?

    private enum AppTab: Hashable {
        case map, vehicles, history, settings
    }

    init(user: User, environment: AppEnvironment) {
        self.user = user
        self.environment = environment
        _viewModel = State(
            initialValue: ActiveParkingViewModel(
                sessionService: environment.sessionService,
                notifications: environment.notifications,
                userID: user.id
            )
        )
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Map", systemImage: "map.fill", value: .map) {
                NavigationStack {
                    ParkingMapView(
                        user: user,
                        environment: environment,
                        activeParking: viewModel,
                        lotToShow: $lotToShow
                    )
                }
            }

            Tab("Vehicles", systemImage: "car.fill", value: .vehicles) {
                NavigationStack {
                    VehicleListView(vehicleService: environment.vehicleService, ownerID: user.id)
                }
            }

            Tab("History", systemImage: "clock.arrow.circlepath", value: .history) {
                NavigationStack {
                    ParkingHistoryView(
                        sessionService: environment.sessionService,
                        userID: user.id,
                        onShowOnMap: show(on:)
                    )
                }
            }

            Tab("Settings", systemImage: "gearshape.fill", value: .settings) {
                NavigationStack {
                    SettingsView(
                        authService: environment.authService,
                        user: user,
                        onSignOut: environment.signOut,
                        onUpdated: environment.setCurrentUser
                    )
                }
            }
        }
        .task {
            await viewModel.refresh()
        }
        .task(id: viewModel.expiryKey) {
            await viewModel.waitForExpiry()
        }
    }

    /// Hands the spot to the map and switches to it, which is the only way the two tabs
    /// talk to each other.
    private func show(on lot: ParkingLot) {
        lotToShow = lot
        selectedTab = .map
    }
}

#Preview {
    MainTabView(
        user: User(id: UUID(), name: "Ana Silva", email: "ana@example.com", createdAt: Date()),
        environment: AppEnvironment(store: InMemoryKeyValueStore())
    )
}
