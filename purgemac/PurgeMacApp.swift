//
//  PurgeMacApp.swift
//  PurgeMac
//
//  PurgeMac - Deep Cleaning Uninstaller for macOS
//

import SwiftUI

@main
struct PurgeMacApp: App {
    @State private var themeManager = ThemeManager()
    @State private var localization = LocalizationManager.shared
    @Environment(\.openWindow) private var openWindow
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.themeManager, themeManager)
                .environment(\.localization, localization)
                .applyTheme(themeManager)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultSize(width: 700, height: 500)
        .commands {
            // MARK: - Appearance Menu (renamed from View to avoid duplicate)
            CommandMenu(L10n.appearance) {
                // Theme Submenu
                Menu(L10n.theme) {
                    ForEach(AppTheme.allCases) { theme in
                        Button {
                            themeManager.selectedTheme = theme
                        } label: {
                            HStack {
                                Image(systemName: theme.icon)
                                Text(theme.rawValue)
                                if themeManager.selectedTheme == theme {
                                    Spacer()
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                }
                
                // Transparency Level Submenu
                Menu(L10n.transparency) {
                    ForEach(TransparencyLevel.allCases) { level in
                        Button {
                            themeManager.transparencyLevel = level
                        } label: {
                            HStack {
                                Text(level.displayName)
                                if themeManager.transparencyLevel == level {
                                    Spacer()
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                }
                
                Divider()
                
                // Language Submenu
                Menu(L10n.language) {
                    ForEach(AppLanguage.allCases) { lang in
                        Button {
                            localization.currentLanguage = lang
                        } label: {
                            HStack {
                                Image(systemName: lang.icon)
                                Text(lang.displayName)
                                if localization.currentLanguage == lang {
                                    Spacer()
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                }
            }
            
            // MARK: - Tools Menu
            ToolsCommands()
            
            // MARK: - Help Menu
            CommandGroup(replacing: .help) {
                Button(L10n.about) {
                    openWindow(id: "about")
                }
                
                Divider()
                
                Button(L10n.help) {
                    if let url = URL(string: "https://github.com/purgemac/help") {
                        NSWorkspace.shared.open(url)
                    }
                }
                
                Divider()
                
                Button(L10n.fdaGuide) {
                    openFullDiskAccessSettings()
                }
                
                Button(L10n.howToEnableFDA) {
                    // Show a helper window or sheet
                    openFullDiskAccessSettings()
                }
                
                Divider()
                
                Button(L10n.reportIssue) {
                    if let url = URL(string: "https://github.com/purgemac/issues") {
                        NSWorkspace.shared.open(url)
                    }
                }
            }
        }
        
        // MARK: - Settings Window
        Settings {
            SettingsView()
                .environment(\.themeManager, themeManager)
                .environment(\.localization, localization)
        }
        
        // MARK: - About Window
        Window(L10n.about, id: "about") {
            AboutView()
                .environment(\.themeManager, themeManager)
                .environment(\.localization, localization)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultPosition(.center)
    }
    
    // MARK: - Helper Functions
    
    private func openFullDiskAccessSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles") {
            NSWorkspace.shared.open(url)
        }
    }
}

// MARK: - Settings View

struct SettingsView: View {
    @Environment(\.themeManager) private var themeManager
    @Environment(\.localization) private var localization
    
    var body: some View {
        TabView {
            // MARK: - General Tab
            Form {
                Section(L10n.language) {
                    Picker(L10n.language, selection: Binding(
                        get: { localization.currentLanguage },
                        set: { localization.currentLanguage = $0 }
                    )) {
                        ForEach(AppLanguage.allCases) { lang in
                            Label(lang.displayName, systemImage: lang.icon)
                                .tag(lang)
                        }
                    }
                    .pickerStyle(.radioGroup)
                    
                    Text(L10n.changesTakeEffect)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .formStyle(.grouped)
            .tabItem {
                Label(L10n.general, systemImage: "gearshape")
            }
            .tag(0)
            .id(localization.version)
            
            // MARK: - Appearance Tab
            Form {
                Section(L10n.theme) {
                    Picker(L10n.theme, selection: Binding(
                        get: { themeManager.selectedTheme },
                        set: { themeManager.selectedTheme = $0 }
                    )) {
                        ForEach(AppTheme.allCases) { theme in
                            Label(theme.rawValue, systemImage: theme.icon)
                                .tag(theme)
                        }
                    }
                    .pickerStyle(.radioGroup)
                }
                
                Section(L10n.transparency) {
                    Picker(L10n.transparencyLevel, selection: Binding(
                        get: { themeManager.transparencyLevel },
                        set: { themeManager.transparencyLevel = $0 }
                    )) {
                        ForEach(TransparencyLevel.allCases) { level in
                            Text(level.displayName)
                                .tag(level)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    Text(L10n.adjustGlassEffect)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .formStyle(.grouped)
            .tabItem {
                Label(L10n.appearance, systemImage: "paintbrush")
            }
            .tag(1)
            .id(localization.version)
            
            // MARK: - Permissions Tab
            Form {
                Section(L10n.fullDiskAccess) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "externaldrive.badge.checkmark")
                                .font(.title2)
                                .foregroundStyle(.green)
                            
                            VStack(alignment: .leading) {
                                Text(L10n.fullDiskAccess)
                                    .font(.headline)
                                Text(L10n.requiredToScan)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        Button(L10n.openSettings) {
                            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles") {
                                NSWorkspace.shared.open(url)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                
                Section(L10n.howToEnable) {
                    VStack(alignment: .leading, spacing: 8) {
                        StepRow(number: 1, text: L10n.stepOpenSettings)
                        StepRow(number: 2, text: L10n.stepPrivacySecurity)
                        StepRow(number: 3, text: L10n.stepEnablePurgemac)
                        StepRow(number: 4, text: L10n.stepRestartPurgemac)
                    }
                }
            }
            .formStyle(.grouped)
            .tabItem {
                Label(L10n.permissions, systemImage: "lock.shield")
            }
            .tag(2)
            .id(localization.version)
        }
        .frame(width: 450, height: 320)
    }
}

// MARK: - Helper Views

private struct StepRow: View {
    let number: Int
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Text("\(number)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .frame(width: 20, height: 20)
                .background(Circle().fill(Color.accentColor))
            
            Text(text)
                .font(.callout)
        }
    }
}

// MARK: - Tools Commands

struct ToolsCommands: Commands {
    @FocusedValue(\.scannerViewModel) var viewModel
    
    var body: some Commands {
        CommandMenu(L10n.tools) {
            Button(L10n.cleanCacheOnly) {
                viewModel?.setCacheOnlyMode()
            }
            .keyboardShortcut("K", modifiers: [.command, .shift])
            .disabled(viewModel == nil || viewModel?.state.isLoading == true)
            
            Button(L10n.rescanCurrentApp) {
                Task { @MainActor in
                    await viewModel?.rescan()
                }
            }
            .keyboardShortcut("R", modifiers: .command)
            .disabled(viewModel?.scannedApp == nil || viewModel?.state.isLoading == true)
            
            Divider()
            
            Button(L10n.openApplicationsFolder) {
                let url = URL(fileURLWithPath: "/Applications")
                NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: url.path)
            }
            .keyboardShortcut("O", modifiers: [.command, .shift])
        }
    }
}
