import CoreLocation
import Foundation
import Testing
@testable import ParkingApp

@Suite("ParkingLotGenerator")
struct ParkingLotGeneratorTests {

    private let lisbon = CLLocationCoordinate2D(latitude: 38.7223, longitude: -9.1393)
    private let porto = CLLocationCoordinate2D(latitude: 41.1579, longitude: -8.6291)

    @Test("generates the requested number of lots")
    func generatesRequestedCount() {
        // Act
        let lots = ParkingLotGenerator.lots(around: lisbon)

        // Assert
        #expect(lots.count == ParkingLotGenerator.defaultCount)
    }

    @Test("produces the same lots for the same coordinate")
    func isDeterministic() {
        // Act
        let first = ParkingLotGenerator.lots(around: lisbon)
        let second = ParkingLotGenerator.lots(around: lisbon)

        // Assert
        #expect(first == second)
    }

    @Test("keeps the same lots when the location jitters by a few metres")
    func toleratesLocationJitter() {
        // Arrange
        let jittered = CLLocationCoordinate2D(
            latitude: lisbon.latitude + 0.0001,
            longitude: lisbon.longitude - 0.0001
        )

        // Act
        let lots = ParkingLotGenerator.lots(around: lisbon)
        let afterJitter = ParkingLotGenerator.lots(around: jittered)

        // Assert
        #expect(lots == afterJitter)
    }

    @Test("produces different lots for a different city")
    func differsBetweenLocations() {
        // Act
        let lisbonLots = ParkingLotGenerator.lots(around: lisbon)
        let portoLots = ParkingLotGenerator.lots(around: porto)

        // Assert
        #expect(lisbonLots != portoLots)
    }

    @Test("places every lot within the configured distance range")
    func placesLotsWithinRange() {
        // Arrange
        let origin = CLLocation(latitude: lisbon.latitude, longitude: lisbon.longitude)
        // The generator uses a flat-earth approximation, so allow a small margin.
        let tolerance = 1.05
        // Lots hang off the centre of a ~100 m grid cell rather than the exact reading,
        // which shifts them relative to the user by up to half a cell.
        let gridAllowance: CLLocationDistance = 100

        // Act
        let lots = ParkingLotGenerator.lots(around: lisbon)

        // Assert
        for lot in lots {
            let distance = origin.distance(
                from: CLLocation(latitude: lot.latitude, longitude: lot.longitude)
            )
            #expect(distance >= ParkingLotGenerator.minimumDistance / tolerance - gridAllowance)
            #expect(distance <= ParkingLotGenerator.maximumDistance * tolerance + gridAllowance)
        }
    }

    @Test("gives every lot a distinct name and identifier")
    func lotsAreDistinct() {
        // Act
        let lots = ParkingLotGenerator.lots(around: lisbon)

        // Assert
        #expect(Set(lots.map(\.name)).count == lots.count)
        #expect(Set(lots.map(\.id)).count == lots.count)
    }

    @Test("never reports more free spaces than the lot has")
    func availableSpacesFitTheLot() {
        // Act
        let lots = ParkingLotGenerator.lots(around: lisbon)

        // Assert
        for lot in lots {
            #expect(lot.availableSpaces >= 0)
            #expect(lot.availableSpaces <= lot.totalSpaces)
            #expect(lot.totalSpaces > 0)
        }
    }

    @Test("charges a positive hourly rate")
    func chargesPositiveRate() {
        // Act
        let lots = ParkingLotGenerator.lots(around: lisbon)

        // Assert
        for lot in lots {
            #expect(lot.hourlyRate > 0)
        }
    }

    @Test("honours a smaller requested count", arguments: [0, 1, 3])
    func honoursRequestedCount(count: Int) {
        // Act
        let lots = ParkingLotGenerator.lots(around: lisbon, count: count)

        // Assert
        #expect(lots.count == count)
    }
}
