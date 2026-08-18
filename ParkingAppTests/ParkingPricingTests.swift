import Foundation
import Testing
@testable import ParkingApp

@Suite("ParkingPricing")
struct ParkingPricingTests {

    @Test("charges the hourly rate for a full hour")
    func chargesRateForOneHour() {
        // Act
        let price = ParkingPricing.price(hourlyRate: .cents(150), minutes: 60)

        // Assert
        #expect(price == .cents(150))
    }

    @Test("charges half the rate for half an hour")
    func chargesHalfRateForHalfHour() {
        // Act
        let price = ParkingPricing.price(hourlyRate: .cents(150), minutes: 30)

        // Assert
        #expect(price == .cents(75))
    }

    @Test("multiplies the rate over several hours")
    func multipliesOverHours() {
        // Act
        let price = ParkingPricing.price(hourlyRate: .cents(120), minutes: 480)

        // Assert
        #expect(price == .cents(960))
    }

    @Test("rounds to the nearest cent")
    func roundsToCents() {
        // Act
        let price = ParkingPricing.price(hourlyRate: .cents(100), minutes: 50)

        // Assert: 50 minutes at 1.00 an hour is 0.8333…
        #expect(price == .cents(83))
    }

    @Test("costs nothing for no time", arguments: [0, -30])
    func chargesNothingForNoTime(minutes: Int) {
        // Act
        let price = ParkingPricing.price(hourlyRate: .cents(150), minutes: minutes)

        // Assert
        #expect(price == 0)
    }

    @Test("costs nothing where parking is free")
    func chargesNothingWhenFree() {
        // Act
        let price = ParkingPricing.price(hourlyRate: 0, minutes: 120)

        // Assert
        #expect(price == 0)
    }

    @Test("charges more for longer stays")
    func chargesMoreForLongerStays() {
        // Arrange
        let durations = ParkingDuration.allCases.sorted { $0.minutes < $1.minutes }

        // Act
        let prices = durations.map { ParkingPricing.price(hourlyRate: .cents(120), minutes: $0.minutes) }

        // Assert
        #expect(prices.first ?? 0 > 0)
        for (cheaper, dearer) in zip(prices, prices.dropFirst()) {
            #expect(dearer > cheaper)
        }
    }

    @Test("builds an exact amount from cents")
    func centsAreExact() {
        // Act & Assert: the same value written as a literal is not exact.
        #expect(Decimal.cents(83) == Decimal(83) / 100)
        #expect(Decimal.cents(83) != 0.83)
    }
}
