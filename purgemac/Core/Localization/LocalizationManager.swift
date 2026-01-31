//
//  LocalizationManager.swift
//  PurgeMac
//
//  PurgeMac - Deep Cleaning Uninstaller for macOS
//

import Foundation
import SwiftUI

// MARK: - App Language

enum AppLanguage: String, CaseIterable, Identifiable {
    case system = "system"
    case english = "en"
    case spanish = "es"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .system: return "System"
        case .english: return "English"
        case .spanish: return "Español"
        }
    }
    
    var icon: String {
        switch self {
        case .system: return "gearshape"
        case .english: return "globe.americas"
        case .spanish: return "globe.europe.africa"
        }
    }
    
    /// Returns the actual language code to use
    var resolvedLanguageCode: String {
        switch self {
        case .system:
            return Locale.current.language.languageCode?.identifier ?? "en"
        case .english:
            return "en"
        case .spanish:
            return "es"
        }
    }
}

// MARK: - Localized Strings

enum L10n {
    // MARK: - General
    static var appName: String { localized("app_name") }
    static var appTagline: String { localized("app_tagline") }
    
    // MARK: - Home
    static var dragAppHere: String { localized("drag_app_here") }
    static var toFindResidualFiles: String { localized("to_find_residual_files") }
    static var tip: String { localized("tip") }
    static var tipText: String { localized("tip_text") }
    
    // MARK: - Scanning
    static var scanning: String { localized("scanning") }
    static var searchingResidualFiles: String { localized("searching_residual_files") }
    static var cancel: String { localized("cancel") }
    
    // MARK: - Detail
    static var back: String { localized("back") }
    static var rescan: String { localized("rescan") }
    static var selectAll: String { localized("select_all") }
    static var deselectAll: String { localized("deselect_all") }
    static var selectedFiles: String { localized("selected_files") }
    static var delete: String { localized("delete") }
    static var moveToTrash: String { localized("move_to_trash") }
    static var deletePermanently: String { localized("delete_permanently") }
    static var totalFiles: String { localized("total_files") }
    static var totalSize: String { localized("total_size") }
    static var selected: String { localized("selected") }
    static var toFree: String { localized("to_free") }
    static var byCategory: String { localized("by_category") }
    
    // MARK: - Success
    static var cleanupComplete: String { localized("cleanup_complete") }
    static var spaceFreed: String { localized("space_freed") }
    static var scanAnotherApp: String { localized("scan_another_app") }
    static var backToHome: String { localized("back_to_home") }
    
    // MARK: - Errors
    static var noArtifactsFound: String { localized("no_artifacts_found") }
    static var appIsClean: String { localized("app_is_clean") }
    static var permissionRequired: String { localized("permission_required") }
    static var permissionDescription: String { localized("permission_description") }
    static var openSettings: String { localized("open_settings") }
    static var invalidApp: String { localized("invalid_app") }
    static var deletionFailed: String { localized("deletion_failed") }
    static var retry: String { localized("retry") }
    static var doNotCloseApp: String { localized("do_not_close_app") }
    static var recent: String { localized("recent") }
    
    // MARK: - Settings
    static var settings: String { localized("settings") }
    static var appearance: String { localized("appearance") }
    static var theme: String { localized("theme") }
    static var transparency: String { localized("transparency") }
    static var language: String { localized("language") }
    static var permissions: String { localized("permissions") }
    static var fullDiskAccess: String { localized("full_disk_access") }
    static var dropToScan: String { localized("drop_to_scan") }
    static var addApp: String { localized("add_app") }
    static var general: String { localized("general") }
    static var transparencyLevel: String { localized("transparency_level") }
    static var changesTakeEffect: String { localized("changes_take_effect") }
    static var adjustGlassEffect: String { localized("adjust_glass_effect") }
    static var tools: String { localized("tools") }
    static var refreshApps: String { localized("refresh_apps") }
    static var openLogs: String { localized("open_logs") }
    static var help: String { localized("help") }
    static var about: String { localized("about") }
    static var close: String { localized("close") }
    static var undoCleanup: String { localized("undo_cleanup") }
    static var permanentDeleteWarning: String { localized("permanent_delete_warning") }
    
    // MARK: - Categories
    static var applicationSupport: String { localized("category_app_support") }
    static var caches: String { localized("category_caches") }
    static var preferences: String { localized("category_preferences") }
    static var logs: String { localized("category_logs") }
    static var containers: String { localized("category_containers") }
    static var cleanCacheOnly: String { localized("clean_cache_only") }
    static var rescanCurrentApp: String { localized("rescan_current_app") }
    static var openApplicationsFolder: String { localized("open_applications_folder") }
    static var reportIssue: String { localized("report_issue") }
    static var stepOpenSettings: String { localized("step_open_settings") }
    static var stepPrivacySecurity: String { localized("step_privacy_security") }
    static var stepEnablePurgemac: String { localized("step_enable_purgemac") }
    static var stepRestartPurgemac: String { localized("step_restart_purgemac") }
    static var requiredToScan: String { localized("required_to_scan") }
    static var howToEnable: String { localized("how_to_enable") }
    static var fdaGuide: String { localized("fda_guide") }
    static var howToEnableFDA: String { localized("how_to_enable_fda") }
    
    // MARK: - Dynamic Status
    static func searchingIn(_ category: String) -> String {
        let fmt = localized("searching_in_param")
        return String(format: fmt, category)
    }
    
    static func deletingFile(_ name: String) -> String {
        let fmt = localized("deleting_param")
        return String(format: fmt, name)
    }
    
    static var startingScan: String { localized("starting_scan") }
    static var scanningCaches: String { localized("scanning_caches") }
    static var preparingDeletion: String { localized("preparing_deletion") }
    
    // MARK: - Cache Only Mode
    static var cacheOnlyHint: String { localized("cache_only_hint") }
    static var cacheOnlyMode: String { localized("cache_only_mode") }
    
    // MARK: - Recent Apps
    static var recentApps: String { localized("recent_apps") }
    static var noRecentApps: String { localized("no_recent_apps") }
    static var noRecentAppsHint: String { localized("no_recent_apps_hint") }
    static var clearHistory: String { localized("clear_history") }
    static var artifacts: String { localized("artifacts") }
    
    // MARK: - Categories
    static var catApplication: String { localized("cat_app") }
    static var catAppSupport: String { localized("cat_app_support") }
    static var catCaches: String { localized("cat_caches") }
    static var catPreferences: String { localized("cat_prefs") }
    static var catLogs: String { localized("cat_logs") }
    static var catContainers: String { localized("cat_containers") }
    static var catSavedState: String { localized("cat_saved_state") }
    static var catHttpStorages: String { localized("cat_http_storages") }
    static var catWebKit: String { localized("cat_webkit") }
    static var catLaunchAgents: String { localized("cat_launch_agents") }
    static var catCookies: String { localized("cat_cookies") }
    
    static func string(for key: String) -> String {
        return localized(key)
    }
    
    // MARK: - Localization Helper
    
    private static func localized(_ key: String) -> String {
        return LocalizationManager.shared.string(for: key)
    }
}

// MARK: - Localization Manager

@Observable
final class LocalizationManager {
    
    // MARK: - Singleton
    
    static let shared = LocalizationManager()
    
    // MARK: - Properties
    
    /// Version counter to force view re-renders when language changes
    var version: Int = 0
    
    var currentLanguage: AppLanguage {
        didSet {
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: "appLanguage")
            updateBundle()
            version += 1  // Trigger view updates
        }
    }
    
    /// The bundle to use for localization (changes based on selected language)
    private var localizationBundle: Bundle = .main
    
    // MARK: - Initialization
    
    private init() {
        if let savedLang = UserDefaults.standard.string(forKey: "appLanguage"),
           let lang = AppLanguage(rawValue: savedLang) {
            self.currentLanguage = lang
        } else {
            self.currentLanguage = .system
        }
        
        updateBundle()
    }
    
    // MARK: - Methods
    
    func string(for key: String) -> String {
        // Use the localization bundle to get the string from the String Catalog
        let value = localizationBundle.localizedString(forKey: key, value: nil, table: nil)
        // If the key wasn't found, return the key itself
        return value == key ? key : value
    }
    
    private func updateBundle() {
        let languageCode = currentLanguage.resolvedLanguageCode
        
        // Try to find a bundle for the selected language
        if let path = Bundle.main.path(forResource: languageCode, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            localizationBundle = bundle
        } else {
            // Fallback to main bundle if language bundle not found
            localizationBundle = .main
        }
    }
}

// MARK: - Environment Key

private struct LocalizationManagerKey: EnvironmentKey {
    static let defaultValue = LocalizationManager.shared
}

extension EnvironmentValues {
    var localization: LocalizationManager {
        get { self[LocalizationManagerKey.self] }
        set { self[LocalizationManagerKey.self] = newValue }
    }
}
