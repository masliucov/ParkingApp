import SwiftUI

/// Decides between the authentication flow and the signed-in experience.
struct RootView: View {
    let environment: AppEnvironment

    var body: some View {
        Group {
            if let user = environment.currentUser {
                MainTabView(user: user, environment: environment)
            } else {
                AuthLandingView(authService: environment.authService) { user in
                    environment.setCurrentUser(user)
                }
            }
        }
        // Only signing in and out are worth animating; the session is already restored by
        // the time this is first drawn.
        .animation(.easeInOut(duration: 0.25), value: environment.currentUser)
        .alert("Something went wrong", isPresented: isShowingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(environment.errorMessage ?? "")
        }
    }

    private var isShowingError: Binding<Bool> {
        Binding(
            get: { environment.errorMessage != nil },
            set: { isPresented in
                if !isPresented { environment.dismissError() }
            }
        )
    }
}

#Preview {
    RootView(environment: AppEnvironment(store: InMemoryKeyValueStore()))
}
