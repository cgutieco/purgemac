//
//  PermissionService.swift
//  PurgeMac
//
//  PurgeMac - Deep Cleaning Uninstaller for macOS
//

import Foundation
import AppKit

// MARK: - Permission Service

actor PermissionService {
    
    // MARK: - Singleton
    
    static let shared = PermissionService()
    
    private init() {}
    
    // MARK: - Full Disk Access Check
    
    func hasFullDiskAccess() -> Bool {
        let testPaths = [
            FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Mail"),
            FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Safari"),
            FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Containers")
        ]
        
        for path in testPaths {
            if FileManager.default.isReadableFile(atPath: path.path) {
                return true
            }
        }
        
        let appSupport = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support")
        
        do {
            let contents = try FileManager.default.contentsOfDirectory(at: appSupport, includingPropertiesForKeys: nil)
            return contents.count > 5
        } catch {
            return false
        }
    }
    
    func canAccess(path: URL) -> Bool {
        FileManager.default.isReadableFile(atPath: path.path)
    }
    
    func canWrite(to path: URL) -> Bool {
        FileManager.default.isWritableFile(atPath: path.path)
    }
    
    // MARK: - Open System Preferences
    
    @MainActor
    func openFullDiskAccessSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles") {
            NSWorkspace.shared.open(url)
        }
    }
    
    @MainActor
    func openPrivacySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy") {
            NSWorkspace.shared.open(url)
        }
    }
}

// MARK: - Permission Status

enum PermissionStatus {
    case granted
    case denied
    case unknown
    
    var description: String {
        switch self {
        case .granted: return "Acceso concedido"
        case .denied: return "Acceso denegado"
        case .unknown: return "Estado desconocido"
        }
    }
}
