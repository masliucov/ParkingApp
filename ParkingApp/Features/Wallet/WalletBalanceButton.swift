import SwiftUI

/// The balance in the corner of the screen, with the one button that changes it.
///
/// The amount and the plus are a single control: what the driver wants after reading a
/// balance they do not like is always the same thing.
struct WalletBalanceButton: View {
    let formattedBalance: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.extraSmall) {
                Text(formattedBalance)
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()
                    .lineLimit(1)

                Image(systemName: "plus.circle.fill")
                    .font(.subheadline)
            }
        }
        .accessibilityLabel("Balance \(formattedBalance)")
        .accessibilityHint("Adds money to your balance")
    }
}

#Preview {
    NavigationStack {
        Color.clear
            .navigationTitle("Find parking")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    WalletBalanceButton(formattedBalance: "€12.50", action: {})
                }
            }
    }
}
