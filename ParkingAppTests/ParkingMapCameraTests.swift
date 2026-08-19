import CoreLocation
import Foundation
import Testing
@testable import ParkingApp

@Suite("ParkingMapCamera")
struct ParkingMapCameraTests {

    private let span: CLLocationDistance = 400

    @Test("frames the spot above the centre, clear of the card at the bottom")
    func framesSpotAboveTheCentre() {
        // Arrange
        let lot = makeLot()

        // Act
        let region = ParkingMapCamera.region(focusing: lot, span: span)

        // Assert: a centre south of the spot pushes the spot up the screen
        #expect(region.center.latitude < lot.latitude)
        #expect(region.center.longitude == lot.longitude)
    }

    @Test("keeps the spot well inside what the map shows")
    func keepsSpotOnScreen() {
        // Arrange
        let lot = makeLot()

        // Act
        let region = ParkingMapCamera.region(focusing: lot, span: span)

        // Assert: the shift stays inside the top half, so the pin never leaves the view
        let shift = lot.latitude - region.center.latitude
        #expect(shift < region.span.latitudeDelta / 2)
        #expect(shift > 0)
    }

    @Test("frames a wider span with a proportionally larger shift")
    func scalesWithTheSpan() {
        // Arrange
        let lot = makeLot()

        // Act
        let near = ParkingMapCamera.region(focusing: lot, span: span)
        let far = ParkingMapCamera.region(focusing: lot, span: span * 2)

        // Assert
        #expect(lot.latitude - far.center.latitude > lot.latitude - near.center.latitude)
    }

    // MARK: - Helpers

    private func makeLot() -> ParkingLot {
        ParkingLot(
            id: "Rua Augusta@38.71120,-9.13760",
            name: "Rua Augusta",
            latitude: 38.7112,
            longitude: -9.1376,
            hourlyRate: .cents(120),
            availableSpaces: 8,
            totalSpaces: 40
        )
    }
}
