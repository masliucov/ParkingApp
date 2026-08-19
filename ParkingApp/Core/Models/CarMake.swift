import Foundation

/// The car brands a driver can pick from when registering a vehicle.
///
/// The list is fixed rather than fetched: there is no free registry of car brands, it
/// changes about once a year, and a driver who cannot find a car is stuck either way.
enum CarMake {
    /// Alphabetical, so the picker reads the way a list of brands is expected to.
    static let all = [
        "Abarth", "Acura", "Aiways", "Alfa Romeo", "Alpine", "Aston Martin", "Audi",
        "Bentley", "BMW", "Bugatti", "Buick", "BYD",
        "Cadillac", "Chery", "Chevrolet", "Chrysler", "Citroën", "Cupra",
        "Dacia", "Daewoo", "Daihatsu", "Dodge", "DS",
        "Ferrari", "Fiat", "Fisker", "Ford",
        "Genesis", "GMC", "Great Wall",
        "Haval", "Honda", "Hummer", "Hyundai",
        "Infiniti", "Isuzu", "Iveco",
        "Jaguar", "Jeep",
        "Kia", "Koenigsegg",
        "Lada", "Lamborghini", "Lancia", "Land Rover", "Leapmotor", "Lexus", "Lincoln",
        "Lotus", "Lucid",
        "Mahindra", "Maserati", "Maybach", "Mazda", "McLaren", "Mercedes-Benz", "MG",
        "Mini", "Mitsubishi", "Morgan",
        "Nio", "Nissan",
        "Opel",
        "Pagani", "Peugeot", "Polestar", "Pontiac", "Porsche",
        "Ram", "Renault", "Rimac", "Rivian", "Rolls-Royce",
        "Saab", "Seat", "Škoda", "Smart", "SsangYong", "Subaru", "Suzuki",
        "Tata", "Tesla", "Toyota",
        "Vauxhall", "VinFast", "Volkswagen", "Volvo",
        "Xpeng",
        "Zeekr"
    ]

    /// The brands worth showing for what has been typed so far, with the ones that start
    /// with the query first: typing "la" should reach Lada before Tesla.
    ///
    /// Case and accents are ignored, so "skoda" finds Škoda on a keyboard that has no Š.
    static func matching(_ query: String) -> [String] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return all }

        let matches = all.filter { $0.range(of: trimmed, options: searchOptions) != nil }
        let startsWithQuery = { (make: String) in
            make.range(of: trimmed, options: searchOptions)?.lowerBound == make.startIndex
        }
        return matches.filter(startsWithQuery) + matches.filter { !startsWithQuery($0) }
    }

    private static let searchOptions: String.CompareOptions = [.caseInsensitive, .diacriticInsensitive]
}
