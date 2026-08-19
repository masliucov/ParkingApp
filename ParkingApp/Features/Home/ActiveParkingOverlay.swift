import SwiftUI

/// The stays still running, laid over the map.
///
/// Deliberately compact: the map underneath is the point of the screen. With more than one
/// car the cards page sideways instead of stacking, so the overlay never grows past the
/// bottom of the map.
struct ActiveParkingOverlay: View {
    let sessions: [ParkingSession]
    let onAddTime: (ParkingSession) -> Void

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: Theme.Spacing.medium) {
                ForEach(sessions) { session in
                    CompactParkingCard(session: session) {
                        onAddTime(session)
                    }
                    .containerRelativeFrame(.horizontal)
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.viewAligned)
        .scrollIndicators(.hidden)
        .scrollDisabled(sessions.count == 1)
        // Insets the cards without breaking the paging: each one still spans the width it
        // scrolls by.
        .safeAreaPadding(.horizontal, Theme.Spacing.medium)
    }
}

private struct CompactParkingCard: View {
    let session: ParkingSession
    let onAddTime: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.small) {
            // Ticks once a second, and stops on its own while the screen is away.
            TimelineView(.periodic(from: .now, by: 1)) { context in
                countdown(at: context.date)
            }

            HStack(spacing: Theme.Spacing.medium) {
                Label(session.vehicle.licensePlate, systemImage: "car")
                Label(session.lot.code, systemImage: "parkingsign")
                Label(session.lot.name, systemImage: "signpost.right")
                    .lineLimit(1)
            }
            .font(.footnote)
            .foregroundStyle(.secondary)

            Button("Add time", action: onAddTime)
                .buttonStyle(.primary)
        }
        .padding(Theme.Spacing.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            .regularMaterial,
            in: RoundedRectangle(cornerRadius: Theme.Radius.large, style: .continuous)
        )
    }

    private func countdown(at date: Date) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.small) {
            Text(session.formattedRemainingTime(at: date))
                .font(.system(size: 32, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .contentTransition(.numericText())
                .foregroundStyle(session.isActive(at: date) ? Color.primary : Color.secondary)

            Text(session.isActive(at: date) ? "remaining" : "parking ended")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }
}
