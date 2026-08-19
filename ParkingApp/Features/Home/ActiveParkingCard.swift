import SwiftUI

/// The countdown for parking that is currently running.
struct ActiveParkingCard: View {
    let session: ParkingSession
    let onAddTime: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
            // Ticks once a second, and stops on its own while the screen is away.
            TimelineView(.periodic(from: .now, by: 1)) { context in
                countdown(at: context.date)
            }

            details

            Button("Add time", action: onAddTime)
                .buttonStyle(.primary)
        }
        .padding(.vertical, Theme.Spacing.small)
    }

    private func countdown(at date: Date) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.extraSmall) {
            Text(session.formattedRemainingTime(at: date))
                .font(.system(size: 44, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .contentTransition(.numericText())
                .foregroundStyle(session.isActive(at: date) ? Color.primary : Color.secondary)

            Text(session.isActive(at: date) ? "remaining" : "parking ended")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.extraSmall) {
            Label(session.lot.name, systemImage: "signpost.right")
            Label(session.vehicle.licensePlate, systemImage: "car")
            Label(
                "Ends at \(session.expiresAt.formatted(date: .omitted, time: .shortened))",
                systemImage: "clock"
            )
            Label("Paid \(session.formattedAmountPaid)", systemImage: "tag")
        }
        .font(.footnote)
        .foregroundStyle(.secondary)
    }
}

#Preview {
    List {
        Section("Active parking") {
            ActiveParkingCard(
                session: ParkingSession(
                    id: UUID(),
                    userID: UUID(),
                    vehicle: Vehicle(
                        id: UUID(),
                        ownerID: UUID(),
                        model: "Renault Clio",
                        licensePlate: "AA-00-BB",
                        createdAt: Date()
                    ),
                    lot: ParkingLot(
                        id: "preview",
                        name: "Rua Augusta",
                        latitude: 38.7112,
                        longitude: -9.1376,
                        hourlyRate: .cents(120),
                        availableSpaces: 8,
                        totalSpaces: 40
                    ),
                    startedAt: Date(),
                    expiresAt: Date().addingTimeInterval(3600),
                    amountPaid: .cents(120)
                ),
                onAddTime: {}
            )
        }
    }
}
