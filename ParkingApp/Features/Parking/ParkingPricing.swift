import Foundation

/// What a stay costs.
enum ParkingPricing {
    /// Charged pro rata, rounded to the nearest cent.
    static func price(hourlyRate: Decimal, minutes: Int) -> Decimal {
        guard minutes > 0, hourlyRate > 0 else { return 0 }
        return rounded(hourlyRate * Decimal(minutes) / 60)
    }

    /// Formatted in the device's currency, falling back to euros.
    static func formatted(_ amount: Decimal) -> String {
        amount.formatted(.currency(code: Locale.current.currency?.identifier ?? "EUR"))
    }

    private static func rounded(_ value: Decimal) -> Decimal {
        var input = value
        var result = Decimal()
        NSDecimalRound(&result, &input, 2, .plain)
        return result
    }
}

extension Decimal {
    /// An exact amount, built from whole cents.
    ///
    /// Writing `0.83` goes through `Double` on its way to `Decimal` and lands on
    /// 0.8299999999999997952, which then fails to match a properly rounded price.
    static func cents(_ cents: Int) -> Decimal {
        Decimal(cents) / 100
    }
}
