//
//  ScanState.swift
//  PurgeMac
//
//  PurgeMac - Deep Cleaning Uninstaller for macOS
//

import Foundation

// MARK: - Scan State Machine

enum ScanState: Equatable {
    case idle
    case scanning(progress: Double)
    case found(ScannedApp)
    case deleting(progress: Double)
    case success(freedBytes: Int64)
    case error(ScanError)
    
    // MARK: - Computed Properties
    
    var isLoading: Bool {
        switch self {
        case .scanning, .deleting:
            return true
        default:
            return false
        }
    }
    
    var canReset: Bool {
        switch self {
        case .found, .success, .error:
            return true
        default:
            return false
        }
    }
}

// MARK: - Scan Errors

enum ScanError: LocalizedError, Equatable {
    case noArtifactsFound
    case permissionDenied
    case deletionFailed(message: String)
    case invalidApp
    case unknownError(message: String)
    
    var errorDescription: String? {
        switch self {
        case .noArtifactsFound:
            return L10n.noArtifactsFound
        case .permissionDenied:
            return L10n.permissionDescription
        case .deletionFailed(let message):
            return String(format: L10n.deletionFailed, message)
        case .invalidApp:
            return L10n.invalidApp
        case .unknownError(let message):
            let fmt = L10n.string(for: "unknown_error")
            return String(format: fmt, message)
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .permissionDenied:
            return L10n.howToEnableFDA
        case .deletionFailed:
            return L10n.changesTakeEffect // Actually we might need a better one but this is a start
        default:
            return nil
        }
    }
}
