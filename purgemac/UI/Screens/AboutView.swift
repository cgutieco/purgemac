//
//  AboutView.swift
//  PurgeMac
//
//  PurgeMac - Deep Cleaning Uninstaller for macOS
//

import SwiftUI

// MARK: - About View

struct AboutView: View {
    @Environment(\.themeManager) private var themeManager
    @Environment(\.dismiss) private var dismiss
    
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    
    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // App Icon
            if let appIcon = NSApplication.shared.applicationIconImage {
                Image(nsImage: appIcon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                    .shadow(color: .black.opacity(0.2), radius: 10, y: 5)
            }
            
            // App Name & Tagline
            VStack(spacing: 8) {
                Text(L10n.appName)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text(L10n.appTagline)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            // Version Info
            VStack(spacing: 4) {
                Text("Version \(appVersion) (\(buildNumber))")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                
                Text("© 2026 PurgeMac")
                    .font(.caption2)
                    .foregroundStyle(.quaternary)
            }
            
            Spacer()
                .frame(height: 8)
            
            // Close Button
            Button(L10n.close) {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.regular)
        }
        .padding(32)
        .frame(width: 300, height: 320)
        .background(themeManager.currentMaterial)
    }
}

// MARK: - Preview

#if DEBUG
#Preview("About View") {
    AboutView()
        .environment(\.themeManager, ThemeManager())
}
#endif
