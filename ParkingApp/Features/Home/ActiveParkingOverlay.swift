import SwiftUI

/// The stays still running, laid over the map.
///
/// Deliberately compact: the map underneath is the point of the screen. With more than one
/// car the cards page sideways instead of stacking, so the overlay never grows past the
/// bottom of the map.
struct ActiveParkingOverlay: View {
    /// How much of the next card stays on screen. Without it the card fills the width and
    /// a second stay is invisible until the driver happens to swipe. It has to clear the
    /// card's own corner radius, or all that shows is a sliver of rounded edge.
    private static let visibleSliver: CGFloat = 32

    let sessions: [ParkingSession]
    let onAddTime: (ParkingSession) -> Void
    let onEnd: (ParkingSession) -> Void

    @State private var scrolledSessionID: UUID?

    private var hasMoreThanOne: Bool {
        sessions.count > 1
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.small) {
            if hasMoreThanOne {
                pageHeader
                    .padding(.horizontal, Theme.Spacing.medium)
            }

            cards
        }
    }

    private var cards: some View {
        ScrollView(.horizontal) {
            HStack(spacing: Theme.Spacing.medium) {
                ForEach(sessions) { session in
                    CompactParkingCard(
                        session: session,
                        onAddTime: { onAddTime(session) },
                        onEnd: { onEnd(session) }
                    )
                    .containerRelativeFrame(.horizontal) { width, _ in
                        guard hasMoreThanOne else { return width }
                        return width - (Self.visibleSliver + Theme.Spacing.medium)
                    }
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.viewAligned)
        .scrollPosition(id: $scrolledSessionID)
        .scrollIndicators(.hidden)
        .scrollDisabled(!hasMoreThanOne)
        // Insets the cards without breaking the paging: each one still spans the width it
        // scrolls by.
        .safeAreaPadding(.horizontal, Theme.Spacing.medium)
    }

    /// Says out loud that there is more than one stay, so the swipe is never the only clue.
    private var pageHeader: some View {
        HStack(spacing: Theme.Spacing.small) {
            Text("\(sessions.count) cars parked")
                .font(.caption.weight(.semibold))

            Spacer()

            HStack(spacing: 5) {
                ForEach(sessions) { session in
                    Circle()
                        .fill(session.id == currentSessionID ? Color.primary : Color.secondary)
                        .opacity(session.id == currentSessionID ? 1 : 0.4)
                        .frame(width: 6, height: 6)
                }
            }
            .accessibilityHidden(true)

            Image(systemName: "chevron.compact.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
        }
        .padding(.horizontal, Theme.Spacing.medium)
        .padding(.vertical, Theme.Spacing.extraSmall)
        .background(.regularMaterial, in: Capsule())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(sessions.count) cars parked. Swipe sideways to see the others.")
    }

    /// Falls back to the first card, which is what the scroll view shows before it has
    /// been moved at all.
    private var currentSessionID: UUID? {
        scrolledSessionID ?? sessions.first?.id
    }
}

private struct CompactParkingCard: View {
    let session: ParkingSession
    let onAddTime: () -> Void
    let onEnd: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.small) {
            // Ticks once a second, and stops on its own while the screen is away.
            TimelineView(.periodic(from: .now, by: 1)) { context in
                countdown(at: context.date)
            }

            // Plate and code are short and must never truncate, so they share a line and
            // the street gets one of its own. All three on one row cut the plate in half.
            HStack(spacing: Theme.Spacing.medium) {
                Label(session.vehicle.licensePlate, systemImage: "car")
                    .fixedSize()

                Label(session.lot.code, systemImage: "parkingsign")
                    .fixedSize()

                Spacer(minLength: 0)
            }
            .font(.footnote.monospacedDigit())
            .foregroundStyle(.secondary)

            Label(session.lot.name, systemImage: "signpost.right")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: Theme.Spacing.small) {
                Button("Add time", action: onAddTime)
                    .buttonStyle(.primary)

                Button("End", role: .destructive, action: onEnd)
                    .buttonStyle(.bordered)
                    .controlSize(.large)
            }
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
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(session.isActive(at: date) ? "remaining" : "parking ended")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .accessibilityElement(children: .combine)
    }
}
