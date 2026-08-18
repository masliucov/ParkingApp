import Foundation
import Testing
@testable import ParkingApp

@Suite("InMemoryKeyValueStore")
struct InMemoryKeyValueStoreTests {

    @Test("writes a value and reads back an identical copy")
    func writesAndReadsValue() throws {
        // Arrange
        let store = InMemoryKeyValueStore()
        let ticket = StoredTicket.sample

        // Act
        try store.write(ticket, forKey: "ticket")
        let loaded = try store.read(StoredTicket.self, forKey: "ticket")

        // Assert
        #expect(loaded == ticket)
    }

    @Test("returns nil when the key was never written")
    func returnsNilForUnknownKey() throws {
        // Arrange
        let store = InMemoryKeyValueStore()

        // Act
        let loaded = try store.read(StoredTicket.self, forKey: "ticket")

        // Assert
        #expect(loaded == nil)
    }

    @Test("replaces the previous value stored under the same key")
    func overwritesExistingValue() throws {
        // Arrange
        let store = InMemoryKeyValueStore()
        let first = StoredTicket.sample
        let second = StoredTicket(id: UUID(), plate: "ZZ-99-XX", startedAt: first.startedAt)

        // Act
        try store.write(first, forKey: "ticket")
        try store.write(second, forKey: "ticket")
        let loaded = try store.read(StoredTicket.self, forKey: "ticket")

        // Assert
        #expect(loaded == second)
    }

    @Test("removes a stored value")
    func removesStoredValue() throws {
        // Arrange
        let store = InMemoryKeyValueStore()
        try store.write(StoredTicket.sample, forKey: "ticket")

        // Act
        try store.removeValue(forKey: "ticket")
        let loaded = try store.read(StoredTicket.self, forKey: "ticket")

        // Assert
        #expect(loaded == nil)
    }

    @Test("throws corruptedData when the seeded value is not valid JSON")
    func throwsWhenSeededValueIsCorrupted() throws {
        // Arrange
        let store = InMemoryKeyValueStore(storage: ["ticket": Data("not json".utf8)])

        // Act & Assert
        #expect(throws: AppError.corruptedData(key: "ticket")) {
            try store.read(StoredTicket.self, forKey: "ticket")
        }
    }
}
