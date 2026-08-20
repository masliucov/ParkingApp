import SwiftUI

/// Shown on a paying screen when the balance will not cover what is about to be paid.
///
/// It carries the way out with it: being told the balance is short is no use on a screen
/// the driver would otherwise have to leave to fix it.
struct InsufficientBalanceNotice: View {
    let message: String
    let onAddFunds: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.small) {
            Label(message, systemImage: "exclamationmark.triangle.fill")
                .font(.footnote)
                .foregroundStyle(.orange)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button("Add funds", action: onAddFunds)
                .font(.footnote.weight(.semibold))
        }
        .padding(.vertical, Theme.Spacing.extraSmall)
    }
}

#Preview {
    Form {
        Section {
            InsufficientBalanceNotice(
                message: "Not enough balance. Add €1.20 or more to pay for this stay.",
                onAddFunds: {}
            )
        }
    }
}
