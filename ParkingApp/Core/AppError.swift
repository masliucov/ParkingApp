import Foundation

/// Errors that can reach the user interface.
///
/// `errorDescription` is what the user reads, so it stays short, actionable and free of
/// technical detail. `logDescription` keeps the context worth writing to the console,
/// such as the storage key that failed.
enum AppError: LocalizedError, Equatable {
    case storageUnavailable
    case storageReadFailed(key: String)
    case storageWriteFailed(key: String)
    case corruptedData(key: String)
    case invalidStorageKey(key: String)

    var errorDescription: String? {
        switch self {
        case .storageUnavailable:
            return "We could not reach the device storage. Please restart the app and try again."
        case .storageReadFailed:
            return "We could not load your saved data. Please try again."
        case .storageWriteFailed:
            return "We could not save your changes. Please try again."
        case .corruptedData:
            return "Some of your saved data was damaged and could not be opened."
        case .invalidStorageKey:
            return "Something went wrong while saving your data. Please try again."
        }
    }

    /// Technical description for logging. Never shown to the user.
    var logDescription: String {
        switch self {
        case .storageUnavailable:
            return "storageUnavailable"
        case .storageReadFailed(let key):
            return "storageReadFailed(key: \(key))"
        case .storageWriteFailed(let key):
            return "storageWriteFailed(key: \(key))"
        case .corruptedData(let key):
            return "corruptedData(key: \(key))"
        case .invalidStorageKey(let key):
            return "invalidStorageKey(key: \(key))"
        }
    }
}
