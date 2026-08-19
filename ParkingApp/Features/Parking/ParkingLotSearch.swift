import Foundation

/// Narrows the parking spots on the map to the ones worth showing for what was typed.
enum ParkingLotSearch {
    /// Matches a code by the digits it starts with, or a street by any part of its name,
    /// so both "48" and "augusta" get somewhere. Order is left alone: the caller sorted
    /// the lots by distance and the nearest should stay first.
    static func matching(_ query: String, in lots: [ParkingLot]) -> [ParkingLot] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return lots }

        return lots.filter { lot in
            lot.code.hasPrefix(trimmed) || lot.name.range(of: trimmed, options: nameOptions) != nil
        }
    }

    private static let nameOptions: String.CompareOptions = [.caseInsensitive, .diacriticInsensitive]
}
