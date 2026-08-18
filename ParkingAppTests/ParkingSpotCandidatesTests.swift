import CoreLocation
import Foundation
import Testing
@testable import ParkingApp

@Suite("ParkingSpotCandidates")
struct ParkingSpotCandidatesTests {

    private let lisbon = CLLocationCoordinate2D(latitude: 38.7223, longitude: -9.1393)
    private let porto = CLLocationCoordinate2D(latitude: 41.1579, longitude: -8.6291)

    @Test("returns the requested number of candidates", arguments: [0, 1, 5, 8])
    func returnsRequestedCount(count: Int) {
        // Act
        let candidates = ParkingSpotCandidates.coordinates(around: lisbon, count: count)

        // Assert
        #expect(candidates.count == count)
    }

    @Test("produces the same candidates for the same place")
    func isDeterministic() {
        // Act
        let first = ParkingSpotCandidates.coordinates(around: lisbon, count: 5)
        let second = ParkingSpotCandidates.coordinates(around: lisbon, count: 5)

        // Assert
        #expect(coordinatesMatch(first, second))
    }

    @Test("keeps the same candidates when the location jitters by a few metres")
    func toleratesLocationJitter() {
        // Arrange
        let jittered = CLLocationCoordinate2D(
            latitude: lisbon.latitude + 0.0001,
            longitude: lisbon.longitude - 0.0001
        )

        // Act
        let steady = ParkingSpotCandidates.coordinates(around: lisbon, count: 5)
        let afterJitter = ParkingSpotCandidates.coordinates(around: jittered, count: 5)

        // Assert
        #expect(coordinatesMatch(steady, afterJitter))
    }

    @Test("produces different candidates in a different city")
    func differsBetweenPlaces() {
        // Act
        let lisbonCandidates = ParkingSpotCandidates.coordinates(around: lisbon, count: 5)
        let portoCandidates = ParkingSpotCandidates.coordinates(around: porto, count: 5)

        // Assert
        #expect(!coordinatesMatch(lisbonCandidates, portoCandidates))
    }

    @Test("keeps every candidate within walking distance")
    func staysWithinWalkingDistance() {
        // Arrange
        let origin = CLLocation(latitude: lisbon.latitude, longitude: lisbon.longitude)
        // A flat-earth offset from the centre of a ~100 m grid cell, so allow for both.
        let tolerance = 1.05
        let gridAllowance: CLLocationDistance = 100

        // Act
        let candidates = ParkingSpotCandidates.coordinates(around: lisbon, count: 5)

        // Assert
        for candidate in candidates {
            let distance = origin.distance(
                from: CLLocation(latitude: candidate.latitude, longitude: candidate.longitude)
            )
            #expect(distance >= ParkingSpotCandidates.minimumDistance / tolerance - gridAllowance)
            #expect(distance <= ParkingSpotCandidates.maximumDistance * tolerance + gridAllowance)
        }
    }

    @Test("spreads the candidates around the user instead of bunching them together")
    func spreadsAroundTheUser() {
        // Arrange
        let count = 5
        let slice = 360.0 / Double(count)

        // Act
        let candidates = ParkingSpotCandidates.coordinates(around: lisbon, count: count)
        let bearings = candidates.map { bearing(from: lisbon, to: $0) }

        // Assert: one candidate per slice of the compass.
        let occupiedSlices = Set(bearings.map { Int($0 / slice) })
        #expect(occupiedSlices.count == count)
    }

    // MARK: - Helpers

    private func coordinatesMatch(
        _ first: [CLLocationCoordinate2D],
        _ second: [CLLocationCoordinate2D]
    ) -> Bool {
        guard first.count == second.count else { return false }

        return zip(first, second).allSatisfy {
            $0.latitude == $1.latitude && $0.longitude == $1.longitude
        }
    }

    /// Degrees clockwise from north, in the same flat-earth terms the generator uses.
    private func bearing(from origin: CLLocationCoordinate2D, to target: CLLocationCoordinate2D) -> Double {
        let convergence = cos(origin.latitude * .pi / 180)
        let deltaNorth = target.latitude - origin.latitude
        let deltaEast = (target.longitude - origin.longitude) * convergence

        let degrees = atan2(deltaEast, deltaNorth) * 180 / .pi
        return degrees < 0 ? degrees + 360 : degrees
    }
}
