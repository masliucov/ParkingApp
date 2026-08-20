import Foundation

/// Starting and reading parking sessions.
///
/// No card is charged, but a stay is paid for: its price comes out of the balance the
/// driver keeps in the app, and `amountPaid` records what it cost.
struct ParkingSessionService: Sendable {
    let repository: ParkingSessionRepository
    /// Where a stay is paid from. Every path that costs money goes through `pay`, so there
    /// is one place where parking and the balance could fall out of step.
    let wallet: WalletService

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

        let price = ParkingPricing.price(hourlyRate: lot.hourlyRate, minutes: duration.minutes)
        let session = ParkingSession(
            id: UUID(),
            userID: userID,
            vehicle: vehicle,
            lot: lot,
            startedAt: now,
            expiresAt: now.addingTimeInterval(duration.timeInterval),
            amountPaid: price
        )

        try pay(price, for: session)
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

        let price = ParkingPricing.price(
            hourlyRate: session.lot.hourlyRate,
            minutes: duration.minutes
        )
        let extended = ParkingSession(
            id: session.id,
            userID: session.userID,
            vehicle: session.vehicle,
            lot: session.lot,
            startedAt: session.startedAt,
            expiresAt: session.expiresAt.addingTimeInterval(duration.timeInterval),
            amountPaid: session.amountPaid + price
        )

        try pay(price, for: extended)
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

    /// Takes the price out of the balance and only then writes the stay, so a driver whose
    /// balance is short is turned away before anything is parked.
    ///
    /// If the write fails the charge goes back: both go to the same store, so a refund that
    /// fails too means the storage itself is gone, and either way what the driver is told
    /// about is the failure that started it.
    private func pay(_ price: Decimal, for session: ParkingSession) throws {
        try wallet.charge(price, userID: session.userID)

        do {
            try repository.save(session)
        } catch {
            _ = try? wallet.add(price, userID: session.userID)
            throw error
        }
    }
}
