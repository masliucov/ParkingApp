import SwiftUI

/// What a signed-in user sees.
struct HomeView: View {
    let user: User
    let environment: AppEnvironment

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
                    NavigationLink {
                        ParkingMapView(locationProvider: environment.locationProvider)
                    } label: {
                        Label("Find parking", systemImage: "map.fill")
                    }

                    NavigationLink {
                        VehicleListView(
                            vehicleService: environment.vehicleService,
                            ownerID: user.id
                        )
                    } label: {
                        Label("My vehicles", systemImage: "car.fill")
                    }

                    NavigationLink {
                        SettingsView(authService: environment.authService, user: user) { updated in
                            environment.setCurrentUser(updated)
                        }
                    } label: {
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
        }
    }
}

#Preview {
    HomeView(
        user: User(id: UUID(), name: "Ana Silva", email: "ana@example.com", createdAt: Date()),
        environment: AppEnvironment(store: InMemoryKeyValueStore())
    )
}
