import Foundation

/// Starting and reading parking sessions.
///
/// Nothing is charged. `amountPaid` only records what the stay would have cost.
struct ParkingSessionService: Sendable {
    let repository: ParkingSessionRepository

    /// One session at a time per driver.
    func start(
        lot: ParkingLot,
        vehicle: Vehicle,
        duration: ParkingDuration,
        userID: UUID,
        now: Date = .storageNow()
    ) throws -> ParkingSession {
        guard lot.hasSpacesAvailable else { throw ParkingSessionError.lotIsFull }
        guard try activeSession(for: userID, at: now) == nil else {
            throw ParkingSessionError.alreadyParked
        }

        let session = ParkingSession(
            id: UUID(),
            userID: userID,
            vehicle: vehicle,
            lot: lot,
            startedAt: now,
            expiresAt: now.addingTimeInterval(duration.timeInterval),
            amountPaid: ParkingPricing.price(hourlyRate: lot.hourlyRate, minutes: duration.minutes)
        )

        try repository.save(session)
        return session
    }

    func activeSession(for userID: UUID, at date: Date = .storageNow()) throws -> ParkingSession? {
        try repository.sessions(for: userID).first { $0.isActive(at: date) }
    }

    func sessions(for userID: UUID) throws -> [ParkingSession] {
        try repository.sessions(for: userID)
    }
}
