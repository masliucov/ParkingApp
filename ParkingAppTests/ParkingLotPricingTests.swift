import CoreLocation
import Foundation
import Testing
@testable import ParkingApp

@Suite("ParkingLotPricing")
struct ParkingLotPricingTests {

    private let coordinate = CLLocationCoordinate2D(latitude: 38.7223, longitude: -9.1393)

    @Test("gives the same lot the same details every time")
    func isDeterministic() {
        // Act
        let first = ParkingLotPricing.details(name: "Central Garage", coordinate: coordinate)
        let second = ParkingLotPricing.details(name: "Central Garage", coordinate: coordinate)

        // Assert
        #expect(first == second)
    }

    @Test("gives two lots at the same place different details")
    func differsByName() {
        // Act
        let first = ParkingLotPricing.details(name: "Central Garage", coordinate: coordinate)
        let second = ParkingLotPricing.details(name: "Riverside Car Park", coordinate: coordinate)

        // Assert
        #expect(first != second)
    }

    @Test("charges one of the configured hourly rates")
    func usesConfiguredRates() {
        // Act
        let details = ParkingLotPricing.details(name: "Central Garage", coordinate: coordinate)

        // Assert
        #expect(ParkingLotPricing.hourlyRates.contains(details.hourlyRate))
        #expect(details.hourlyRate > 0)
    }

    @Test("never reports more free spaces than the lot has")
    func availableSpacesFitTheLot() {
        // Act
        let details = ParkingLotPricing.details(name: "Central Garage", coordinate: coordinate)

        // Assert
        #expect(details.totalSpaces > 0)
        #expect(details.availableSpaces >= 0)
        #expect(details.availableSpaces <= details.totalSpaces)
    }

    @Test("builds the same identifier for the same place")
    func identifierIsStable() {
        // Act
        let first = ParkingLotPricing.identifier(name: "Central Garage", coordinate: coordinate)
        let second = ParkingLotPricing.identifier(name: "Central Garage", coordinate: coordinate)

        // Assert
        #expect(first == second)
    }

    @Test("builds different identifiers for different places")
    func identifierSeparatesPlaces() {
        // Arrange
        let elsewhere = CLLocationCoordinate2D(latitude: 41.1579, longitude: -8.6291)

        // Act
        let lisbon = ParkingLotPricing.identifier(name: "Central Garage", coordinate: coordinate)
        let porto = ParkingLotPricing.identifier(name: "Central Garage", coordinate: elsewhere)

        // Assert
        #expect(lisbon != porto)
    }

    @Test("keeps the identifier stable under sub-metre coordinate noise")
    func identifierToleratesNoise() {
        // Arrange
        let noisy = CLLocationCoordinate2D(
            latitude: coordinate.latitude + 0.000001,
            longitude: coordinate.longitude - 0.000001
        )

        // Act
        let exact = ParkingLotPricing.identifier(name: "Central Garage", coordinate: coordinate)
        let shifted = ParkingLotPricing.identifier(name: "Central Garage", coordinate: noisy)

        // Assert
        #expect(exact == shifted)
    }
}
