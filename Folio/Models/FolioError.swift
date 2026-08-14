import Foundation

enum FolioError: Error, Equatable, Sendable {
    case emptyWorkspace
    case unreadable(String)
    case encrypted
    case writeFailed
    case cancelled
    case diskFull
    case passwordMismatch
    case noPassword
    case invalidRange
    case outOfBounds(Int)

    var localizationKey: String {
        switch self {
        case .emptyWorkspace: return "error.emptyWorkspace"
        case .unreadable: return "error.unreadable"
        case .encrypted: return "error.encrypted"
        case .writeFailed: return "error.writeFailed"
        case .cancelled: return "error.cancelled"
        case .diskFull: return "error.diskFull"
        case .passwordMismatch: return "error.passwordMismatch"
        case .noPassword: return "error.noPassword"
        case .invalidRange: return "error.invalidRange"
        case .outOfBounds: return "error.outOfBounds"
        }
    }
}
