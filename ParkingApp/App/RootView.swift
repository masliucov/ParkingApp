import SwiftUI

/// Entry screen of the app.
///
/// From part 2 onwards this view decides between the authentication flow and the
/// signed-in experience. For now it only presents the app.
struct RootView: View {
    @State private var isShowingNextStepNotice = false

    var body: some View {
        VStack(spacing: Theme.Spacing.large) {
            Spacer()
            logo
            welcome
            Spacer()
            Button("Get started") {
                isShowingNextStepNotice = true
            }
            .buttonStyle(.primary)
        }
        .padding(Theme.Spacing.large)
        .frame(maxWidth: Theme.Layout.maxContentWidth)
        .frame(maxWidth: .infinity)
        .alert("Almost there", isPresented: $isShowingNextStepNotice) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Account creation arrives in the next step.")
        }
    }

    private var logo: some View {
        Image(systemName: "parkingsign.circle.fill")
            .font(.system(size: 88, weight: .regular))
            .foregroundStyle(Color.accentColor)
            .accessibilityHidden(true)
    }

    private var welcome: some View {
        VStack(spacing: Theme.Spacing.small) {
            Text("ParkingApp")
                .font(.largeTitle.bold())
            Text("Park smarter. Pay only for the time you need.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }
}

#Preview {
    RootView()
}
