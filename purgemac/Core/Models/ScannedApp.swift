//
//  ScannedApp.swift
//  PurgeMac
//
//  PurgeMac - Deep Cleaning Uninstaller for macOS
//

import Foundation
import AppKit

// MARK: - Scanned App Model

struct ScannedApp: Identifiable, Equatable {
    let id: UUID
    let appURL: URL
    let bundleIdentifier: String?
    let displayName: String
    let icon: NSImage?
    var artifacts: [AppArtifact]
    
    init(
        id: UUID = UUID(),
        appURL: URL,
        bundleIdentifier: String? = nil,
        displayName: String,
        icon: NSImage? = nil,
        artifacts: [AppArtifact] = []
    ) {
        self.id = id
        self.appURL = appURL
        self.bundleIdentifier = bundleIdentifier
        self.displayName = displayName
        self.icon = icon
        self.artifacts = artifacts
    }
    
    // MARK: - Computed Properties
    
    var totalSize: Int64 {
        artifacts.reduce(0) { $0 + $1.sizeBytes }
    }
    
    var formattedTotalSize: String {
        ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
    }
    
    var selectedSize: Int64 {
        artifacts.filter(\.isSelected).reduce(0) { $0 + $1.sizeBytes }
    }
    
    var formattedSelectedSize: String {
        ByteCountFormatter.string(fromByteCount: selectedSize, countStyle: .file)
    }
    
    var selectedCount: Int {
        artifacts.filter(\.isSelected).count
    }
    
    var artifactsByCategory: [ArtifactCategory: [AppArtifact]] {
        Dictionary(grouping: artifacts, by: \.category)
    }
    
    var categories: [ArtifactCategory] {
        Array(Set(artifacts.map(\.category))).sorted { $0.rawValue < $1.rawValue }
    }
    
    // MARK: - Equatable
    
    static func == (lhs: ScannedApp, rhs: ScannedApp) -> Bool {
        lhs.id == rhs.id &&
        lhs.appURL == rhs.appURL &&
        lhs.artifacts == rhs.artifacts
    }
}

// MARK: - Factory Methods

extension ScannedApp {
    static func from(appURL: URL) -> ScannedApp? {
        guard appURL.pathExtension == "app" else { return nil }
        
        let bundle = Bundle(url: appURL)
        let bundleIdentifier = bundle?.bundleIdentifier
        let displayName = FileManager.default.displayName(atPath: appURL.path)
        
        let icon = NSWorkspace.shared.icon(forFile: appURL.path)
        
        return ScannedApp(
            appURL: appURL,
            bundleIdentifier: bundleIdentifier,
            displayName: displayName,
            icon: icon
        )
    }
}

// MARK: - Preview Helpers

#if DEBUG
extension ScannedApp {
    static let preview = ScannedApp(
        appURL: URL(fileURLWithPath: "/Applications/Example.app"),
        bundleIdentifier: "com.example.app",
        displayName: "Example App",
        icon: NSImage(systemSymbolName: "app.fill", accessibilityDescription: nil),
        artifacts: AppArtifact.previewList
    )
}
#endif
