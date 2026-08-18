import SwiftUI

struct SignUpView: View {
    @State private var viewModel: SignUpViewModel

    init(authService: AuthService, onAuthenticated: @escaping (User) -> Void) {
        _viewModel = State(
            initialValue: SignUpViewModel(authService: authService, onAuthenticated: onAuthenticated)
        )
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.medium) {
                FormField(
                    title: "Full name",
                    text: $viewModel.name,
                    textContentType: .name,
                    autocapitalization: .words
                )
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
                    textContentType: .newPassword
                )
                FormField(
                    title: "Confirm password",
                    text: $viewModel.passwordConfirmation,
                    isSecure: true,
                    textContentType: .newPassword
                )

                if let errorMessage = viewModel.errorMessage {
                    FormErrorText(message: errorMessage)
                }

                Button("Create account") {
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
        .navigationTitle("Create account")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        SignUpView(
            authService: AuthService(
                repository: StoredUserRepository(store: InMemoryKeyValueStore()),
                sessionStore: SessionStore(store: InMemoryKeyValueStore())
            ),
            onAuthenticated: { _ in }
        )
    }
}
