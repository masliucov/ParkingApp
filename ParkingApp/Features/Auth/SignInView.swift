import SwiftUI

struct SignInView: View {
    @State private var viewModel: SignInViewModel

    init(authService: AuthService, onAuthenticated: @escaping (User) -> Void) {
        _viewModel = State(
            initialValue: SignInViewModel(authService: authService, onAuthenticated: onAuthenticated)
        )
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.medium) {
                FormField(
                    title: "Email",
                    text: $viewModel.email,
                    textContentType: .emailAddress,
                    keyboardType: .emailAddress
                )
                FormField(
                    title: "Password",
                    text: $viewModel.password,
                    isSecure: true,
                    textContentType: .password
                )

                if let errorMessage = viewModel.errorMessage {
                    FormErrorText(message: errorMessage)
                }

                Button("Sign in") {
                    viewModel.submit()
                }
                .buttonStyle(.primary)
                .disabled(!viewModel.canSubmit)
                .padding(.top, Theme.Spacing.small)
            }
            .padding(Theme.Spacing.large)
            .frame(maxWidth: Theme.Layout.maxContentWidth)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("Sign in")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        SignInView(
            authService: AuthService(
                repository: StoredUserRepository(store: InMemoryKeyValueStore()),
                sessionStore: SessionStore(store: InMemoryKeyValueStore())
            ),
            onAuthenticated: { _ in }
        )
    }
}
