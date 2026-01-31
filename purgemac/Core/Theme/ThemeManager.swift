//
//  ThemeManager.swift
//  PurgeMac
//
//  PurgeMac - Deep Cleaning Uninstaller for macOS
//

import SwiftUI

// MARK: - App Theme

enum AppTheme: String, CaseIterable, Identifiable {
    case light    = "Claro"
    case dark     = "Oscuro"
    case system   = "Sistema"
    case glassMax = "Glass-Max"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .light:    return "sun.max.fill"
        case .dark:     return "moon.fill"
        case .system:   return "circle.lefthalf.filled"
        case .glassMax: return "cube.transparent.fill"
        }
    }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .light:    return .light
        case .dark:     return .dark
        case .system:   return nil
        case .glassMax: return .dark
        }
    }
}

// MARK: - Transparency Level

enum TransparencyLevel: Double, CaseIterable, Identifiable {
    case minimum = 0.30
    case low     = 0.50
    case medium  = 0.70
    case high    = 0.85
    case maximum = 0.95
    
    var id: Double { rawValue }
    
    var displayName: String {
        switch self {
        case .minimum: return "Mínimo (30%)"
        case .low:     return "Bajo (50%)"
        case .medium:  return "Medio (70%)"
        case .high:    return "Alto (85%)"
        case .maximum: return "Máximo (95%)"
        }
    }
    
    var material: Material {
        switch self {
        case .minimum: return .ultraThickMaterial
        case .low:     return .thickMaterial
        case .medium:  return .regularMaterial
        case .high:    return .thinMaterial
        case .maximum: return .ultraThinMaterial
        }
    }
}

// MARK: - Theme Manager

@Observable
final class ThemeManager {
    
    // MARK: - Stored Properties (persisted via @AppStorage wrapper in views)
    
    var selectedTheme: AppTheme {
        didSet {
            UserDefaults.standard.set(selectedTheme.rawValue, forKey: "selectedTheme")
        }
    }
    
    var transparencyLevel: TransparencyLevel {
        didSet {
            UserDefaults.standard.set(transparencyLevel.rawValue, forKey: "transparencyLevel")
        }
    }
    
    // MARK: - Computed Properties
    
    var currentMaterial: Material {
        if selectedTheme == .glassMax {
            return .ultraThinMaterial
        }
        return transparencyLevel.material
    }
    
    var preferredColorScheme: ColorScheme? {
        selectedTheme.colorScheme
    }
    
    var isGlassMaxEnabled: Bool {
        selectedTheme == .glassMax
    }
    
    // MARK: - Initialization
    
    init() {
        if let themeRaw = UserDefaults.standard.string(forKey: "selectedTheme"),
           let theme = AppTheme(rawValue: themeRaw) {
            self.selectedTheme = theme
        } else {
            self.selectedTheme = .system
        }
        
        let transparencyRaw = UserDefaults.standard.double(forKey: "transparencyLevel")
        if transparencyRaw > 0,
           let level = TransparencyLevel(rawValue: transparencyRaw) {
            self.transparencyLevel = level
        } else {
            self.transparencyLevel = .medium
        }
    }
    
    // MARK: - Actions
    
    func cycleTheme() {
        guard let currentIndex = AppTheme.allCases.firstIndex(of: selectedTheme) else { return }
        let nextIndex = (currentIndex + 1) % AppTheme.allCases.count
        selectedTheme = AppTheme.allCases[nextIndex]
    }
    
    func cycleTransparency() {
        guard let currentIndex = TransparencyLevel.allCases.firstIndex(of: transparencyLevel) else { return }
        let nextIndex = (currentIndex + 1) % TransparencyLevel.allCases.count
        transparencyLevel = TransparencyLevel.allCases[nextIndex]
    }
}

// MARK: - Environment Key

private struct ThemeManagerKey: EnvironmentKey {
    static let defaultValue = ThemeManager()
}

extension EnvironmentValues {
    var themeManager: ThemeManager {
        get { self[ThemeManagerKey.self] }
        set { self[ThemeManagerKey.self] = newValue }
    }
}
