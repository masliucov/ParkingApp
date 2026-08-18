import SwiftUI

/// The main call to action across the app.
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        StyledLabel(configuration: configuration)
    }

    /// A nested view so `@Environment` values resolve for the button being styled.
    private struct StyledLabel: View {
        let configuration: ButtonStyleConfiguration

        @Environment(\.isEnabled) private var isEnabled

        var body: some View {
            configuration.label
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: Theme.Layout.controlHeight)
                .background(Color.accentColor.opacity(configuration.isPressed ? 0.8 : 1))
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous))
                .opacity(isEnabled ? 1 : 0.4)
                .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
        }
    }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    static var primary: PrimaryButtonStyle { PrimaryButtonStyle() }
}
