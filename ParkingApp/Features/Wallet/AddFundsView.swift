import SwiftUI

/// Puts money into the balance.
///
/// Laid out like the screens that spend it: what you have now, what you are choosing, and
/// where it leaves you.
struct AddFundsView: View {
    let wallet: WalletViewModel

    @State private var amount: TopUpAmount = .ten
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Balance") {
                    LabeledContent("Available now", value: wallet.formattedBalance)
                }

                Section("Add") {
                    Picker("Amount", selection: $amount) {
                        ForEach(TopUpAmount.allCases) { option in
                            Text(option.title).tag(option)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }

                Section {
                    LabeledContent("New balance", value: wallet.formattedBalance(after: amount))
                        .font(.headline)
                } footer: {
                    Text("No card is charged. Adding money is simulated in this app.")
                }

                if let errorMessage = wallet.errorMessage {
                    Section {
                        FormErrorText(message: errorMessage)
                    }
                }
            }
            .navigationTitle("Add funds")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button("Add \(amount.title)") {
                    add()
                }
                .buttonStyle(.primary)
                .padding(Theme.Spacing.large)
                .background(.bar)
            }
        }
    }

    /// Stays open when the money did not go in, so the reason is still on screen.
    private func add() {
        guard wallet.add(amount) else { return }
        dismiss()
    }
}

#Preview {
    AddFundsView(
        wallet: WalletViewModel(
            service: WalletService(repository: StoredWalletRepository(store: InMemoryKeyValueStore())),
            userID: UUID()
        )
    )
}
