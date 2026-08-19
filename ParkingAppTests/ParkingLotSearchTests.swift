import Foundation
import Testing
@testable import ParkingApp

@Suite("ParkingLotSearch")
struct ParkingLotSearchTests {

    @Test("shows every lot while nothing is typed")
    func showsEverythingForAnEmptyQuery() {
        // Arrange
        let lots = [makeLot(name: "Rua Augusta"), makeLot(name: "Praça do Comércio")]

        // Act & Assert
        #expect(ParkingLotSearch.matching("", in: lots) == lots)
        #expect(ParkingLotSearch.matching("   ", in: lots) == lots)
    }

    @Test("finds a lot by its full code")
    func findsByFullCode() throws {
        // Arrange
        let lots = [makeLot(name: "Rua Augusta"), makeLot(name: "Praça do Comércio")]
        let wanted = try #require(lots.last)

        // Act
        let matches = ParkingLotSearch.matching(wanted.code, in: lots)

        // Assert
        #expect(matches == [wanted])
    }

    @Test("finds a lot by the digits its code starts with")
    func findsByPartialCode() throws {
        // Arrange
        let lot = makeLot(name: "Rua Augusta")
        let query = String(lot.code.prefix(2))

        // Act
        let matches = ParkingLotSearch.matching(query, in: [lot])

        // Assert
        #expect(matches == [lot])
    }

    @Test("finds a lot by street name, however it is capitalized")
    func findsByName() {
        // Arrange
        let augusta = makeLot(name: "Rua Augusta")
        let lots = [augusta, makeLot(name: "Praça do Comércio")]

        // Act & Assert
        #expect(ParkingLotSearch.matching("augusta", in: lots) == [augusta])
        #expect(ParkingLotSearch.matching("AUGUSTA", in: lots) == [augusta])
    }

    @Test("keeps the order it was given, so the nearest stays first")
    func keepsGivenOrder() {
        // Arrange
        let nearest = makeLot(name: "Rua Augusta")
        let furthest = makeLot(name: "Rua Augusta Nova")

        // Act
        let matches = ParkingLotSearch.matching("Rua Augusta", in: [nearest, furthest])

        // Assert
        #expect(matches == [nearest, furthest])
    }

    @Test("finds nothing for a code that is not there")
    func findsNothingForAnUnknownCode() {
        // Arrange
        let lots = [makeLot(name: "Rua Augusta")]
        let missing = "0000" == lots[0].code ? "1111" : "0000"

        // Act & Assert
        #expect(ParkingLotSearch.matching(missing, in: lots).isEmpty)
    }

    // MARK: - Nearby and remembered

    @Test("looks only at what is nearby while nothing is typed")
    func ignoresRememberedForAnEmptyQuery() {
        // Arrange
        let nearby = [makeLot(name: "Rua Augusta")]
        let remembered = [makeLot(name: "Praça do Comércio")]

        // Act
        let matches = ParkingLotSearch.matching("", nearby: nearby, remembered: remembered)

        // Assert: the map would otherwise fill with every spot ever parked at
        #expect(matches == nearby)
    }

    @Test("finds a spot from the history that this search did not turn up")
    func findsRememberedLot() {
        // Arrange
        let nearby = [makeLot(name: "Rua Augusta")]
        let parkedBefore = makeLot(name: "Praça do Comércio")

        // Act
        let matches = ParkingLotSearch.matching(
            parkedBefore.code,
            nearby: nearby,
            remembered: [parkedBefore]
        )

        // Assert
        #expect(matches == [parkedBefore])
    }

    @Test("puts what is nearby before what is only remembered")
    func ranksNearbyFirst() {
        // Arrange
        let nearby = makeLot(name: "Rua Augusta")
        let parkedBefore = makeLot(name: "Rua Augusta Nova")

        // Act
        let matches = ParkingLotSearch.matching(
            "Rua Augusta",
            nearby: [nearby],
            remembered: [parkedBefore]
        )

        // Assert
        #expect(matches == [nearby, parkedBefore])
    }

    @Test("does not list a spot twice when it is both nearby and remembered")
    func doesNotRepeatALot() {
        // Arrange
        let lot = makeLot(name: "Rua Augusta")

        // Act
        let matches = ParkingLotSearch.matching("Rua Augusta", nearby: [lot], remembered: [lot])

        // Assert
        #expect(matches == [lot])
    }

    // MARK: - Helpers

    private func makeLot(name: String) -> ParkingLot {
        ParkingLot(
            id: name,
            name: name,
            latitude: 38.7112,
            longitude: -9.1376,
            hourlyRate: .cents(120),
            availableSpaces: 8,
            totalSpaces: 40
        )
    }
}
