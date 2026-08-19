import SwiftUI

/// What a signed-in user sees: the map first, everything else a tab away.
struct MainTabView: View {
    let user: User
    let environment: AppEnvironment

    @State private var viewModel: ActiveParkingViewModel

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
        TabView {
            Tab("Map", systemImage: "map.fill") {
                NavigationStack {
                    ParkingMapView(user: user, environment: environment, activeParking: viewModel)
                }
            }

            Tab("Vehicles", systemImage: "car.fill") {
                NavigationStack {
                    VehicleListView(vehicleService: environment.vehicleService, ownerID: user.id)
                }
            }

            Tab("History", systemImage: "clock.arrow.circlepath") {
                NavigationStack {
                    ParkingHistoryView(
                        sessionService: environment.sessionService,
                        userID: user.id
                    )
                }
            }

            Tab("Settings", systemImage: "gearshape.fill") {
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
}

#Preview {
    MainTabView(
        user: User(id: UUID(), name: "Ana Silva", email: "ana@example.com", createdAt: Date()),
        environment: AppEnvironment(store: InMemoryKeyValueStore())
    )
}
