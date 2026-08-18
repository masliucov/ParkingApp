import SwiftUI

/// What a signed-in user sees.
struct HomeView: View {
    let user: User
    let environment: AppEnvironment

    /// Navigation goes by value so each screen is only built when it is opened. Building
    /// a destination up front hands it the size of a list row, which the map in
    /// particular does not recover from.
    private enum Destination: Hashable {
        case parking
        case vehicles
        case settings
    }

    var body: some View {
        NavigationStack {
            List {
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

                Section {
                    NavigationLink(value: Destination.parking) {
                        Label("Find parking", systemImage: "map.fill")
                    }

                    NavigationLink(value: Destination.vehicles) {
                        Label("My vehicles", systemImage: "car.fill")
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
        }
    }

    @ViewBuilder
    private func view(for destination: Destination) -> some View {
        switch destination {
        case .parking:
            ParkingMapView(locationProvider: environment.locationProvider)

        case .vehicles:
            VehicleListView(vehicleService: environment.vehicleService, ownerID: user.id)

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
