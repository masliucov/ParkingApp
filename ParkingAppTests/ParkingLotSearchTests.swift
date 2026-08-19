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
