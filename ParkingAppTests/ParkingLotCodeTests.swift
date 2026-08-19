import CoreLocation
import Foundation
import Testing
@testable import ParkingApp

@Suite("ParkingLot code")
struct ParkingLotCodeTests {

    @Test("is always four digits")
    func isFourDigits() {
        // Arrange
        let lots = [
            makeLot(name: "Rua Augusta", latitude: 38.7112, longitude: -9.1376),
            makeLot(name: "Avenida da Liberdade", latitude: 38.7185, longitude: -9.1447),
            makeLot(name: "Street parking", latitude: 0, longitude: 0)
        ]

        // Act & Assert
        for lot in lots {
            let isAllDigits = lot.code.allSatisfy(\.isNumber)

            #expect(lot.code.count == 4)
            #expect(isAllDigits)
        }
    }

    @Test("stays the same for the same spot")
    func isStableForTheSameSpot() {
        // Arrange
        let lot = makeLot(name: "Rua Augusta", latitude: 38.7112, longitude: -9.1376)
        let sameSpotFoundAgain = makeLot(name: "Rua Augusta", latitude: 38.7112, longitude: -9.1376)

        // Act & Assert
        #expect(lot.code == sameSpotFoundAgain.code)
    }

    @Test("differs between two spots on the same street")
    func differsBetweenSpots() {
        // Arrange
        let first = makeLot(name: "Rua Augusta", latitude: 38.7112, longitude: -9.1376)
        let second = makeLot(name: "Rua Augusta", latitude: 38.7120, longitude: -9.1380)

        // Act & Assert
        #expect(first.code != second.code)
    }

    // MARK: - Helpers

    private func makeLot(name: String, latitude: Double, longitude: Double) -> ParkingLot {
        ParkingLot(
            id: ParkingLotPricing.identifier(
                name: name,
                coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            ),
            name: name,
            latitude: latitude,
            longitude: longitude,
            hourlyRate: .cents(120),
            availableSpaces: 8,
            totalSpaces: 40
        )
    }
}
