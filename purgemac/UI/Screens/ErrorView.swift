//
//  ErrorView.swift
//  PurgeMac
//
//  PurgeMac - Deep Cleaning Uninstaller for macOS
//

import SwiftUI
import AppKit

// MARK: - Error View

struct ErrorView: View {
    let error: ScanError
    var onRetry: () -> Void
    var onDismiss: () -> Void
    
    @State private var showContent = false
    @Environment(\.themeManager) private var themeManager
    @Environment(\.localization) private var localization
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: 24) {
                errorIcon
                    .scaleEffect(showContent ? 1 : 0.8)
                    .opacity(showContent ? 1 : 0)
                
                Text(errorTitle)
                    .font(.title)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 10)
                
                Text(error.localizedDescription)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 400)
                    .opacity(showContent ? 1 : 0)
                
                if let recovery = error.recoverySuggestion {
                    Text(recovery)
                        .font(.callout)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .opacity(showContent ? 1 : 0)
                }
                
                if error == .permissionDenied {
                    permissionHelp
                        .opacity(showContent ? 1 : 0)
                }
            }
            
            Spacer()
            
            actionButtons
                .opacity(showContent ? 1 : 0)
                .padding(.bottom, 40)
        }
        .padding(.horizontal, 40)
        .animation(.easeOut(duration: 0.5), value: showContent)
        .onAppear {
            showContent = true
        }
    }
    
    // MARK: - Error Icon
    
    private var errorIcon: some View {
        ZStack {
            Circle()
                .fill(errorColor.opacity(0.15))
                .frame(width: 120, height: 120)
                .blur(radius: 20)
            
            Image(systemName: errorIconName)
                .font(.system(size: 64, weight: .light))
                .foregroundStyle(errorColor)
                .symbolRenderingMode(.hierarchical)
        }
    }
    
    private var errorIconName: String {
        switch error {
        case .noArtifactsFound:
            return "checkmark.circle"
        case .permissionDenied:
            return "lock.shield"
        case .invalidApp:
            return "app.badge.fill"
        case .deletionFailed:
            return "trash.slash"
        case .unknownError:
            return "exclamationmark.triangle"
        }
    }
    
    private var errorColor: Color {
        switch error {
        case .noArtifactsFound:
            return .green
        default:
            return .orange
        }
    }
    
    private var errorTitle: String {
        switch error {
        case .noArtifactsFound:
            return L10n.appIsClean
        case .permissionDenied:
            return L10n.permissionRequired
        case .invalidApp:
            return L10n.invalidApp
        case .deletionFailed:
            return L10n.deletionFailed
        case .unknownError:
            return L10n.deletionFailed
        }
    }
    
    // MARK: - Permission Help
    
    private var permissionHelp: some View {
        VStack(spacing: 16) {
            Divider()
                .padding(.vertical, 8)
            
            Text(L10n.howToEnableFDA + ":")
                .font(.subheadline)
                .fontWeight(.medium)
            
            VStack(alignment: .leading, spacing: 12) {
                HelpStep(number: 1, text: L10n.stepOpenSettings)
                HelpStep(number: 2, text: L10n.stepPrivacySecurity)
                HelpStep(number: 3, text: L10n.stepEnablePurgemac)
                HelpStep(number: 4, text: L10n.stepRestartPurgemac)
            }
            .padding()
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.primary.opacity(0.03))
            }
        }
        .frame(maxWidth: 350)
        .id(localization.version)
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        HStack(spacing: 16) {
            if error == .permissionDenied {
                ActionButton.primary(title: L10n.openSettings, icon: "gearshape.fill") {
                    openFullDiskAccessSettings()
                }
            }
            
            if error == .noArtifactsFound {
                ActionButton.primary(title: L10n.scanAnotherApp, icon: "plus") {
                    onDismiss()
                }
            } else {
                ActionButton.secondary(title: L10n.retry, icon: "arrow.clockwise") {
                    onRetry()
                }
            }
            
            Button(L10n.backToHome) {
                onDismiss()
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
        }
        .id(localization.version)
    }
    
    // MARK: - Actions
    
    private func openFullDiskAccessSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles") {
            NSWorkspace.shared.open(url)
        }
    }
}

// MARK: - Help Step

private struct HelpStep: View {
    let number: Int
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .frame(width: 20, height: 20)
                .background(Circle().fill(Color.accentColor))
            
            Text(text)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Permission Denied") {
    ErrorView(
        error: .permissionDenied,
        onRetry: {},
        onDismiss: {}
    )
    .environment(\.themeManager, ThemeManager())
    .frame(width: 600, height: 550)
}

#Preview("No Artifacts") {
    ErrorView(
        error: .noArtifactsFound,
        onRetry: {},
        onDismiss: {}
    )
    .environment(\.themeManager, ThemeManager())
    .frame(width: 500, height: 450)
}

#Preview("Invalid App") {
    ErrorView(
        error: .invalidApp,
        onRetry: {},
        onDismiss: {}
    )
    .environment(\.themeManager, ThemeManager())
    .frame(width: 500, height: 400)
}
#endif
