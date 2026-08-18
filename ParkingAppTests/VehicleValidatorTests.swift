import Foundation
import Testing
@testable import ParkingApp

@Suite("VehicleValidator")
struct VehicleValidatorTests {

    // MARK: - Model

    @Test("trims surrounding whitespace from the model")
    func trimsModel() throws {
        // Act
        let model = try VehicleValidator.validateModel("  Renault Clio  ")

        // Assert
        #expect(model == "Renault Clio")
    }

    @Test("rejects a blank model", arguments: ["", "   ", "\n"])
    func rejectsBlankModel(rawModel: String) {
        // Act & Assert
        #expect(throws: VehicleError.invalidModel) {
            try VehicleValidator.validateModel(rawModel)
        }
    }

    @Test("rejects a model longer than the maximum")
    func rejectsOverlongModel() {
        // Arrange
        let rawModel = String(repeating: "a", count: VehicleValidator.maximumModelLength + 1)

        // Act & Assert
        #expect(throws: VehicleError.invalidModel) {
            try VehicleValidator.validateModel(rawModel)
        }
    }

    // MARK: - License plate

    @Test("uppercases the plate and removes spaces")
    func normalizesPlate() throws {
        // Act
        let plate = try VehicleValidator.validateLicensePlate(" aa 00 bb ")

        // Assert
        #expect(plate == "AA00BB")
    }

    @Test("keeps hyphens, which many countries print on the plate")
    func keepsHyphens() throws {
        // Act
        let plate = try VehicleValidator.validateLicensePlate("aa-00-bb")

        // Assert
        #expect(plate == "AA-00-BB")
    }

    @Test(
        "accepts plates from different countries",
        arguments: ["AA-00-BB", "00-AA-00", "1234ABC", "AB12CDE"]
    )
    func acceptsPlausiblePlates(rawPlate: String) throws {
        // Act
        let plate = try VehicleValidator.validateLicensePlate(rawPlate)

        // Assert
        #expect(plate == rawPlate)
    }

    @Test(
        "rejects plates that are empty, too short, too long or hold illegal characters",
        arguments: ["", "AB", "ABCDEFGHIJK", "AA_00_BB", "AA/00", "----"]
    )
    func rejectsInvalidPlates(rawPlate: String) {
        // Act & Assert
        #expect(throws: VehicleError.invalidLicensePlate) {
            try VehicleValidator.validateLicensePlate(rawPlate)
        }
    }

    @Test("normalizes the same plate written in different ways to one value")
    func normalizesEquivalentPlates() {
        // Act
        let spaced = VehicleValidator.normalizePlate("aa 00 bb")
        let tight = VehicleValidator.normalizePlate("AA00BB")

        // Assert
        #expect(spaced == tight)
    }
}
