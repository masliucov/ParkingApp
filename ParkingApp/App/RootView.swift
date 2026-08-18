import SwiftUI

/// Decides between the authentication flow and the signed-in experience.
struct RootView: View {
    let environment: AppEnvironment

    var body: some View {
        Group {
            if let user = environment.currentUser {
                HomeView(user: user, environment: environment)
            } else {
                AuthLandingView(authService: environment.authService) { user in
                    environment.setCurrentUser(user)
                }
            }
        }
        .animation(.easeInOut(duration: 0.25), value: environment.currentUser)
        .task {
            environment.restoreSession()
        }
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
