//
//  AppArtifact.swift
//  PurgeMac
//
//  PurgeMac - Deep Cleaning Uninstaller for macOS
//

import Foundation

// MARK: - Artifact Category

enum ArtifactCategory: String, CaseIterable, Identifiable, Sendable {
    case application        = "Application"
    case applicationSupport = "Application Support"
    case caches             = "Caches"
    case preferences        = "Preferences"
    case logs               = "Logs"
    case containers         = "Containers"
    case savedState         = "Saved Application State"
    case httpStorages       = "HTTPStorages"
    case webKit             = "WebKit"
    case launchAgents       = "Launch Agents"
    case cookies            = "Cookies"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .application:        return "app.fill"
        case .applicationSupport: return "folder.fill"
        case .caches:             return "internaldrive.fill"
        case .preferences:        return "gearshape.fill"
        case .logs:               return "doc.text.fill"
        case .containers:         return "shippingbox.fill"
        case .savedState:         return "clock.arrow.circlepath"
        case .httpStorages:       return "network"
        case .webKit:             return "safari.fill"
        case .launchAgents:       return "bolt.fill"
        case .cookies:            return "circle.grid.3x3.fill"
        }
    }
    
    var localizedName: String {
        switch self {
        case .application:        return L10n.catApplication
        case .applicationSupport: return L10n.catAppSupport
        case .caches:             return L10n.catCaches
        case .preferences:        return L10n.catPreferences
        case .logs:               return L10n.catLogs
        case .containers:         return L10n.catContainers
        case .savedState:         return L10n.catSavedState
        case .httpStorages:       return L10n.catHttpStorages
        case .webKit:             return L10n.catWebKit
        case .launchAgents:       return L10n.catLaunchAgents
        case .cookies:            return L10n.catCookies
        }
    }
    
    var librarySubpath: String {
        switch self {
        case .application:        return ""
        case .applicationSupport: return "Application Support"
        case .caches:             return "Caches"
        case .preferences:        return "Preferences"
        case .logs:               return "Logs"
        case .containers:         return "Containers"
        case .savedState:         return "Saved Application State"
        case .httpStorages:       return "HTTPStorages"
        case .webKit:             return "WebKit"
        case .launchAgents:       return "LaunchAgents"
        case .cookies:            return "Cookies"
        }
    }
}

// MARK: - App Artifact Model

struct AppArtifact: Identifiable, Hashable, Sendable {
    let id: UUID
    let path: URL
    let category: ArtifactCategory
    let sizeBytes: Int64
    let displayName: String
    var isSelected: Bool
    
    nonisolated init(
        id: UUID = UUID(),
        path: URL,
        category: ArtifactCategory,
        sizeBytes: Int64,
        isSelected: Bool = true
    ) {
        self.id = id
        self.path = path
        self.category = category
        self.sizeBytes = sizeBytes
        self.displayName = path.pathComponents.last ?? ""
        self.isSelected = isSelected
    }
    
    // MARK: - Computed Properties
    
    var fullPath: String {
        path.path
    }
    
    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: sizeBytes, countStyle: .file)
    }
    
    // MARK: - Hashable
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: AppArtifact, rhs: AppArtifact) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Preview Helpers

#if DEBUG
extension AppArtifact {
    static let preview = AppArtifact(
        path: URL(fileURLWithPath: "/Users/user/Library/Caches/com.example.app"),
        category: .caches,
        sizeBytes: 15_000_000
    )
    
    static let previewList: [AppArtifact] = [
        AppArtifact(
            path: URL(fileURLWithPath: "/Users/user/Library/Application Support/ExampleApp"),
            category: .applicationSupport,
            sizeBytes: 50_000_000
        ),
        AppArtifact(
            path: URL(fileURLWithPath: "/Users/user/Library/Caches/com.example.app"),
            category: .caches,
            sizeBytes: 15_000_000
        ),
        AppArtifact(
            path: URL(fileURLWithPath: "/Users/user/Library/Preferences/com.example.app.plist"),
            category: .preferences,
            sizeBytes: 4_096
        ),
        AppArtifact(
            path: URL(fileURLWithPath: "/Users/user/Library/Logs/ExampleApp"),
            category: .logs,
            sizeBytes: 1_200_000
        )
    ]
}
#endif
