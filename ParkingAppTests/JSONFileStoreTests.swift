import Foundation
import Testing
@testable import ParkingApp

@Suite("JSONFileStore")
struct JSONFileStoreTests {

    @Test("writes a value and reads back an identical copy")
    func writesAndReadsValue() throws {
        // Arrange
        let directory = makeTemporaryDirectoryURL()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = JSONFileStore(directoryURL: directory)
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
        let directory = makeTemporaryDirectoryURL()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = JSONFileStore(directoryURL: directory)

        // Act
        let loaded = try store.read(StoredTicket.self, forKey: "ticket")

        // Assert
        #expect(loaded == nil)
    }

    @Test("replaces the previous value stored under the same key")
    func overwritesExistingValue() throws {
        // Arrange
        let directory = makeTemporaryDirectoryURL()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = JSONFileStore(directoryURL: directory)
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
        let directory = makeTemporaryDirectoryURL()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = JSONFileStore(directoryURL: directory)
        try store.write(StoredTicket.sample, forKey: "ticket")

        // Act
        try store.removeValue(forKey: "ticket")
        let loaded = try store.read(StoredTicket.self, forKey: "ticket")

        // Assert
        #expect(loaded == nil)
    }

    @Test("removing an unknown key does nothing")
    func removingUnknownKeyDoesNothing() throws {
        // Arrange
        let directory = makeTemporaryDirectoryURL()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = JSONFileStore(directoryURL: directory)

        // Act & Assert
        try store.removeValue(forKey: "ticket")
    }

    @Test("throws corruptedData when the stored file is not valid JSON")
    func throwsWhenStoredFileIsCorrupted() throws {
        // Arrange
        let directory = makeTemporaryDirectoryURL()
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try Data("not json".utf8).write(to: directory.appending(path: "ticket.json"))
        let store = JSONFileStore(directoryURL: directory)

        // Act & Assert
        #expect(throws: AppError.corruptedData(key: "ticket")) {
            try store.read(StoredTicket.self, forKey: "ticket")
        }
    }

    @Test(
        "rejects keys that could escape the store directory",
        arguments: ["", "../escape", "nested/key", "with space"]
    )
    func rejectsInvalidKeys(key: String) throws {
        // Arrange
        let directory = makeTemporaryDirectoryURL()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = JSONFileStore(directoryURL: directory)

        // Act & Assert
        #expect(throws: AppError.invalidStorageKey(key: key)) {
            try store.write(StoredTicket.sample, forKey: key)
        }
    }
}
