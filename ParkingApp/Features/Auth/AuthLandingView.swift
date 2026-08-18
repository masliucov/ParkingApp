import SwiftUI

/// Shown while nobody is signed in.
struct AuthLandingView: View {
    let authService: AuthService
    let onAuthenticated: (User) -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: Theme.Spacing.large) {
                Spacer()
                logo
                welcome
                Spacer()
                actions
            }
            .padding(Theme.Spacing.large)
            .frame(maxWidth: Theme.Layout.maxContentWidth)
            .frame(maxWidth: .infinity)
        }
    }

    private var logo: some View {
        Image(systemName: "parkingsign.circle.fill")
            .font(.system(size: 88))
            .foregroundStyle(Color.accentColor)
            .accessibilityHidden(true)
    }

    private var welcome: some View {
        VStack(spacing: Theme.Spacing.small) {
            Text("ParkingApp")
                .font(.largeTitle.bold())
            Text("Park smarter. Pay only for the time you need.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var actions: some View {
        VStack(spacing: Theme.Spacing.medium) {
            NavigationLink {
                SignUpView(authService: authService, onAuthenticated: onAuthenticated)
            } label: {
                Text("Create account")
            }
            .buttonStyle(.primary)

            NavigationLink {
                SignInView(authService: authService, onAuthenticated: onAuthenticated)
            } label: {
                Text("I already have an account")
                    .font(.subheadline.weight(.semibold))
            }
        }
    }
}

#Preview {
    AuthLandingView(
        authService: AuthService(
            repository: StoredUserRepository(store: InMemoryKeyValueStore()),
            sessionStore: SessionStore(store: InMemoryKeyValueStore())
        ),
        onAuthenticated: { _ in }
    )
}
