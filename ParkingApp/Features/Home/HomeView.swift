import SwiftUI

/// What a signed-in user sees.
struct HomeView: View {
    let user: User
    let onSignOut: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: Theme.Spacing.large) {
                Spacer()

                VStack(spacing: Theme.Spacing.small) {
                    Text("Welcome, \(user.name)")
                        .font(.title2.bold())
                        .multilineTextAlignment(.center)
                    Text("Your vehicles and the parking map arrive in the next steps.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                Spacer()

                Button("Sign out", action: onSignOut)
                    .buttonStyle(.primary)
            }
            .padding(Theme.Spacing.large)
            .frame(maxWidth: Theme.Layout.maxContentWidth)
            .frame(maxWidth: .infinity)
            .navigationTitle("ParkingApp")
        }
    }
}

#Preview {
    HomeView(
        user: User(id: UUID(), name: "Ana Silva", email: "ana@example.com", createdAt: Date()),
        onSignOut: {}
    )
}
