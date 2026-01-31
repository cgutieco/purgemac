//
//  RecentAppEntry.swift
//  PurgeMac
//
//  PurgeMac - Deep Cleaning Uninstaller for macOS
//

import Foundation
import AppKit

// MARK: - Recent App Entry

/// Modelo ligero para persistencia del historial de apps escaneadas
struct RecentAppEntry: Codable, Identifiable, Equatable, Sendable {
    let id: UUID
    let appPath: String
    let bundleIdentifier: String?
    let displayName: String
    let lastScannedDate: Date
    let totalArtifactsFound: Int
    let totalSizeBytes: Int64
    
    // MARK: - Computed Properties
    
    var appURL: URL {
        URL(fileURLWithPath: appPath)
    }
    
    /// Obtiene el icono dinámicamente (no se persiste)
    @MainActor
    var icon: NSImage? {
        NSWorkspace.shared.icon(forFile: appPath)
    }
    
    /// Verifica si la app aún existe en el sistema
    nonisolated var appExists: Bool {
        FileManager.default.fileExists(atPath: appPath)
    }
    
    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: totalSizeBytes, countStyle: .file)
    }
    
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: lastScannedDate, relativeTo: Date())
    }
    
    // MARK: - Factory
    
    nonisolated static func create(
        appURL: URL,
        bundleIdentifier: String?,
        displayName: String,
        artifactCount: Int,
        totalSize: Int64
    ) -> RecentAppEntry {
        RecentAppEntry(
            id: UUID(),
            appPath: appURL.path,
            bundleIdentifier: bundleIdentifier,
            displayName: displayName,
            lastScannedDate: Date(),
            totalArtifactsFound: artifactCount,
            totalSizeBytes: totalSize
        )
    }
}

// MARK: - Preview Helpers

#if DEBUG
extension RecentAppEntry {
    static let preview = RecentAppEntry(
        id: UUID(),
        appPath: "/Applications/Safari.app",
        bundleIdentifier: "com.apple.Safari",
        displayName: "Safari",
        lastScannedDate: Date().addingTimeInterval(-3600),
        totalArtifactsFound: 12,
        totalSizeBytes: 524_288_000
    )
    
    static let previewList: [RecentAppEntry] = [
        RecentAppEntry(
            id: UUID(),
            appPath: "/Applications/Safari.app",
            bundleIdentifier: "com.apple.Safari",
            displayName: "Safari",
            lastScannedDate: Date().addingTimeInterval(-3600),
            totalArtifactsFound: 12,
            totalSizeBytes: 524_288_000
        ),
        RecentAppEntry(
            id: UUID(),
            appPath: "/Applications/Xcode.app",
            bundleIdentifier: "com.apple.dt.Xcode",
            displayName: "Xcode",
            lastScannedDate: Date().addingTimeInterval(-86400),
            totalArtifactsFound: 25,
            totalSizeBytes: 1_073_741_824
        )
    ]
}
#endif
