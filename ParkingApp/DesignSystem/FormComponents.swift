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

/// A labelled row that opens a picker, styled like `FormField` so a chosen value and a
/// typed one sit at the same height in a form.
struct FormSelectionField: View {
    let title: String
    /// What the user picked, or nil to show `placeholder` greyed out.
    let value: String?
    let placeholder: String
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.extraSmall) {
            Text(title)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)

            Button(action: action) {
                HStack {
                    Text(value ?? placeholder)
                        .foregroundStyle(value == nil ? .secondary : .primary)
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, Theme.Spacing.medium)
                .frame(height: Theme.Layout.controlHeight)
                .frame(maxWidth: .infinity)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(title)
            .accessibilityValue(value ?? placeholder)
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
