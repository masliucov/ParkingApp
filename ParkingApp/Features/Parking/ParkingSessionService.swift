import Foundation

/// Starting and reading parking sessions.
///
/// Nothing is charged. `amountPaid` only records what the stay would have cost.
struct ParkingSessionService: Sendable {
    let repository: ParkingSessionRepository

    /// One session at a time per vehicle. A driver with two cars can park both.
    func start(
        lot: ParkingLot,
        vehicle: Vehicle,
        duration: ParkingDuration,
        userID: UUID,
        now: Date = .storageNow()
    ) throws -> ParkingSession {
        guard lot.hasSpacesAvailable else { throw ParkingSessionError.lotIsFull }
        guard try activeSession(forVehicle: vehicle.id, userID: userID, at: now) == nil else {
            throw ParkingSessionError.vehicleAlreadyParked
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

    /// Ends a stay now rather than at the hour it was paid up to, for the driver who
    /// leaves early. Nothing is refunded: `amountPaid` stays as it was, which is what the
    /// history goes on reporting.
    func end(_ session: ParkingSession, now: Date = .storageNow()) throws -> ParkingSession {
        guard session.isActive(at: now) else { throw ParkingSessionError.sessionEnded }

        let ended = ParkingSession(
            id: session.id,
            userID: session.userID,
            vehicle: session.vehicle,
            lot: session.lot,
            startedAt: session.startedAt,
            expiresAt: now,
            amountPaid: session.amountPaid
        )

        try repository.save(ended)
        return ended
    }

    /// Everything the driver has parked right now, soonest to run out first.
    func activeSessions(for userID: UUID, at date: Date = .storageNow()) throws -> [ParkingSession] {
        try repository.sessions(for: userID)
            .filter { $0.isActive(at: date) }
            .sorted { $0.expiresAt < $1.expiresAt }
    }

    func activeSession(
        forVehicle vehicleID: UUID,
        userID: UUID,
        at date: Date = .storageNow()
    ) throws -> ParkingSession? {
        try activeSessions(for: userID, at: date).first { $0.vehicle.id == vehicleID }
    }

    /// The vehicles that cannot be parked again until their stay runs out, so the screen
    /// that starts parking can say so before the driver pays.
    func parkedVehicleIDs(for userID: UUID, at date: Date = .storageNow()) throws -> Set<UUID> {
        Set(try activeSessions(for: userID, at: date).map(\.vehicle.id))
    }

    func sessions(for userID: UUID) throws -> [ParkingSession] {
        try repository.sessions(for: userID)
    }
}
