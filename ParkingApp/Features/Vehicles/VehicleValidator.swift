import Foundation

/// Validates and normalizes vehicle details before they are stored.
enum VehicleValidator {
    static let maximumModelLength = 40
    static let minimumPlateLength = 4
    static let maximumPlateLength = 10

    static func validateModel(_ rawModel: String) throws -> String {
        let model = rawModel.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !model.isEmpty, model.count <= maximumModelLength else {
            throw VehicleError.invalidModel
        }
        return model
    }

    /// Plate formats differ from country to country, so this checks length and
    /// characters rather than a national pattern.
    static func validateLicensePlate(_ rawPlate: String) throws -> String {
        let plate = normalizePlate(rawPlate)
        guard plate.count >= minimumPlateLength,
              plate.count <= maximumPlateLength,
              plate.allSatisfy(isAllowedPlateCharacter),
              plate.contains(where: { $0.isLetter || $0.isNumber }) else {
            throw VehicleError.invalidLicensePlate
        }
        return plate
    }

    /// Uppercased and stripped of whitespace, so "aa 00 bb" and "AA00BB" never count as
    /// two different plates.
    static func normalizePlate(_ rawPlate: String) -> String {
        rawPlate.uppercased().filter { !$0.isWhitespace }
    }

    private static func isAllowedPlateCharacter(_ character: Character) -> Bool {
        character.isLetter || character.isNumber || character == "-"
    }
}
