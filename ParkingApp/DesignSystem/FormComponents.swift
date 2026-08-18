import SwiftUI

/// A labelled text field in the app's style.
struct FormField: View {
    let title: String
    @Binding var text: String
    var isSecure = false
    var textContentType: UITextContentType?
    var keyboardType: UIKeyboardType = .default
    var autocapitalization: TextInputAutocapitalization = .never

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.extraSmall) {
            Text(title)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)

            input
                .textContentType(textContentType)
                .keyboardType(keyboardType)
                .textInputAutocapitalization(autocapitalization)
                .autocorrectionDisabled()
                .padding(.horizontal, Theme.Spacing.medium)
                .frame(height: Theme.Layout.controlHeight)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous))
        }
    }

    @ViewBuilder
    private var input: some View {
        if isSecure {
            SecureField(title, text: $text)
        } else {
            TextField(title, text: $text)
        }
    }
}

/// The message shown when a form cannot be submitted.
struct FormErrorText: View {
    let message: String

    var body: some View {
        Label(message, systemImage: "exclamationmark.triangle.fill")
            .font(.footnote)
            .foregroundStyle(.red)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
