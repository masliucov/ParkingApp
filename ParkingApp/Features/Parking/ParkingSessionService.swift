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

    /// Adds time to the end of the stay rather than to the current moment, so time
    /// already paid for is never lost.
    func extend(
        _ session: ParkingSession,
        by duration: ParkingDuration,
        now: Date = .storageNow()
    ) throws -> ParkingSession {
        guard session.isActive(at: now) else { throw ParkingSessionError.sessionEnded }

        let extended = ParkingSession(
            id: session.id,
            userID: session.userID,
            vehicle: session.vehicle,
            lot: session.lot,
            startedAt: session.startedAt,
            expiresAt: session.expiresAt.addingTimeInterval(duration.timeInterval),
            amountPaid: session.amountPaid + ParkingPricing.price(
                hourlyRate: session.lot.hourlyRate,
                minutes: duration.minutes
            )
        )

        try repository.save(extended)
        return extended
    }

    func activeSession(for userID: UUID, at date: Date = .storageNow()) throws -> ParkingSession? {
        try repository.sessions(for: userID).first { $0.isActive(at: date) }
    }

    func sessions(for userID: UUID) throws -> [ParkingSession] {
        try repository.sessions(for: userID)
    }
}
