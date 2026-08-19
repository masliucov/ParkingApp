import SwiftUI

struct SettingsView: View {
    @State private var viewModel: SettingsViewModel

    private let onSignOut: () -> Void

    init(
        authService: AuthService,
        user: User,
        onSignOut: @escaping () -> Void,
        onUpdated: @escaping (User) -> Void
    ) {
        self.onSignOut = onSignOut
        _viewModel = State(
            initialValue: SettingsViewModel(
                authService: authService,
                user: user,
                onUpdated: onUpdated
            )
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

                emailRow

                if let errorMessage = viewModel.errorMessage {
                    FormErrorText(message: errorMessage)
                }

                if let successMessage = viewModel.successMessage {
                    Label(successMessage, systemImage: "checkmark.circle.fill")
                        .font(.footnote)
                        .foregroundStyle(.green)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Button("Save changes") {
                    viewModel.submit()
                }
                .buttonStyle(.primary)
                .disabled(!viewModel.canSubmit)
                .padding(.top, Theme.Spacing.small)

                Button("Sign out", role: .destructive, action: onSignOut)
                    .padding(.top, Theme.Spacing.medium)
            }
            .padding(Theme.Spacing.large)
            .frame(maxWidth: Theme.Layout.maxContentWidth)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }

    /// The email is shown for context but cannot be changed: it identifies the account.
    private var emailRow: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.extraSmall) {
            Text("Email")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)

            Text(viewModel.email)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, Theme.Spacing.medium)
                .frame(height: Theme.Layout.controlHeight)
                .background(Color(.tertiarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous))
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    NavigationStack {
        SettingsView(
            authService: AuthService(
                repository: StoredUserRepository(store: InMemoryKeyValueStore()),
                sessionStore: SessionStore(store: InMemoryKeyValueStore())
            ),
            user: User(id: UUID(), name: "Ana Silva", email: "ana@example.com", createdAt: Date()),
            onSignOut: {},
            onUpdated: { _ in }
        )
    }
}
