import Foundation
import Testing
@testable import ParkingApp

@Suite("CarMake")
struct CarMakeTests {

    @Test("offers every brand while nothing is typed")
    func offersEverythingForAnEmptyQuery() {
        // Arrange
        let queries = ["", "   "]

        // Act & Assert
        for query in queries {
            #expect(CarMake.matching(query) == CarMake.all)
        }
    }

    @Test("finds a brand however it is capitalized")
    func ignoresCase() {
        // Act
        let matches = CarMake.matching("porsche")

        // Assert
        #expect(matches.contains("Porsche"))
    }

    @Test("finds a brand typed without its accents")
    func ignoresAccents() {
        // Act & Assert
        #expect(CarMake.matching("skoda").contains("Škoda"))
        #expect(CarMake.matching("citroen").contains("Citroën"))
    }

    @Test("matches the middle of a name, not only the start")
    func matchesInsideTheName() {
        // Act
        let matches = CarMake.matching("wagen")

        // Assert
        #expect(matches == ["Volkswagen"])
    }

    @Test("puts the brands that start with the query first")
    func ranksPrefixMatchesFirst() throws {
        // Act
        let matches = CarMake.matching("la")

        // Assert
        #expect(matches.first == "Lada")

        let landRover = try #require(matches.firstIndex(of: "Land Rover"))
        let tesla = try #require(matches.firstIndex(of: "Tesla"))
        #expect(landRover < tesla)
    }

    @Test("finds nothing for a brand it does not know")
    func findsNothingForAnUnknownBrand() {
        // Act & Assert
        #expect(CarMake.matching("Zzyzx").isEmpty)
    }

    @Test("keeps the catalogue alphabetical and free of repeats")
    func catalogueIsSortedAndUnique() {
        // Arrange
        let sorted = CarMake.all.sorted { $0.localizedStandardCompare($1) == .orderedAscending }

        // Act & Assert
        #expect(CarMake.all == sorted)
        #expect(Set(CarMake.all).count == CarMake.all.count)
        #expect(!CarMake.all.isEmpty)
    }
}
