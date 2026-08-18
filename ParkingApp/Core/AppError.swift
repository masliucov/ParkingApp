import Foundation

/// Errors that reach the user interface.
///
/// `errorDescription` is what the user reads; `logDescription` keeps the failing key
/// for the console.
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

    /// For the console, never for the user.
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
