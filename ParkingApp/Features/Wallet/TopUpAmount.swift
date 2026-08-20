import Foundation

/// How much a driver can add to their balance in one go.
///
/// A closed list rather than a typed amount: it is one tap, and there is nothing to
/// mistype or to validate.
enum TopUpAmount: Int, CaseIterable, Identifiable, Sendable {
    case five = 500
    case ten = 1_000
    case twenty = 2_000
    case fifty = 5_000

    var id: Int { rawValue }

    /// Whole cents, so a top-up never picks up the rounding error `Double` would bring.
    var amount: Decimal { .cents(rawValue) }

    var title: String { ParkingPricing.formatted(amount) }
}
