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

    /// Searches what is around the driver and, failing that, the spots they have parked at
    /// before — which is the whole point of a code you can read off an old receipt.
    ///
    /// An empty query is not a search: it stays on what is nearby, because dropping every
    /// remembered spot onto the map would bury the ones actually within walking distance.
    static func matching(
        _ query: String,
        nearby: [ParkingLot],
        remembered: [ParkingLot]
    ) -> [ParkingLot] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nearby }

        let found = matching(trimmed, in: nearby)
        let foundIDs = Set(found.map(\.id))

        return found + matching(trimmed, in: remembered).filter { !foundIDs.contains($0.id) }
    }

    /// Adds spots that belong on the map whatever the search turned up — the ones with a
    /// car parked in them, and the one whose card is open — without listing any twice.
    /// `extra` is deduplicated against itself too: two cars in one spot arrive as the same
    /// lot twice, and a repeated identifier would break the map's `ForEach`.
    static func appending(_ extra: [ParkingLot], to lots: [ParkingLot]) -> [ParkingLot] {
        var known = Set(lots.map(\.id))
        return lots + extra.filter { known.insert($0.id).inserted }
    }

    private static let nameOptions: String.CompareOptions = [.caseInsensitive, .diacriticInsensitive]
}
