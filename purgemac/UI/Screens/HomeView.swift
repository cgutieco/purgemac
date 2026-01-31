//
//  HomeView.swift
//  PurgeMac
//
//  PurgeMac - Deep Cleaning Uninstaller for macOS
//

import SwiftUI

// MARK: - Main Content View

struct MainContentView: View {
    @StateObject private var viewModel = ScannerViewModel()
    @Environment(\.themeManager) private var themeManager
    
    var body: some View {
        ZStack {
            // Glass background
            Rectangle()
                .fill(themeManager.currentMaterial)
                .ignoresSafeArea()
            
            Group {
                switch viewModel.state {
                case .idle:
                    HomeScreen(viewModel: viewModel)
                        .transition(.opacity)
                    
                case .scanning:
                    ScanningScreen(viewModel: viewModel)
                        .transition(.opacity.combined(with: .scale(scale: 0.98)))
                    
                case .found:
                    DetailView(viewModel: viewModel)
                        .transition(.move(edge: .trailing))
                    
                case .deleting:
                    DeletingScreen(viewModel: viewModel)
                        .transition(.opacity)
                    
                case .success(let freedBytes):
                    SuccessView(
                        freedBytes: freedBytes,
                        appName: viewModel.scannedApp?.displayName,
                        canUndo: viewModel.canUndo,
                        wasPermanent: viewModel.lastDeletionWasPermanent,
                        onDone: { viewModel.reset() },
                        onUndo: {
                            Task {
                                let restored = await viewModel.undoLastDeletion()
                                if restored > 0 {
                                    print("Restored \(restored) files")
                                }
                            }
                        }
                    )
                    .transition(.scale.combined(with: .opacity))
                    
                case .error(let error):
                    ErrorView(
                        error: error,
                        onRetry: {
                            if let url = viewModel.scannedApp?.appURL {
                                Task { await viewModel.scanApp(at: url) }
                            } else {
                                viewModel.reset()
                            }
                        },
                        onDismiss: { viewModel.reset() }
                    )
                    .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.35), value: viewModel.state)
        }
        .frame(minWidth: 700, minHeight: 500)
        .environment(\.scannerViewModel, viewModel)
        .focusedSceneValue(\.scannerViewModel, viewModel)
    }
}

// MARK: - Home Screen

struct HomeScreen: View {
    @ObservedObject var viewModel: ScannerViewModel
    @Environment(\.themeManager) private var themeManager
    @Environment(\.localization) private var localization
    
    @State private var showRecentApps = false
    
    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.top, 20)
                .padding(.bottom, 32)
            
            Spacer()
            
            DropZone(isCacheOnlyMode: viewModel.scanMode == .cacheOnly) { appURL in
                Task {
                    switch viewModel.scanMode {
                    case .full:
                        await viewModel.scanApp(at: appURL)
                    case .cacheOnly:
                        await viewModel.scanCacheOnly(at: appURL)
                    }
                }
            }
            
            Spacer()
            
            footerTip
                .padding(.bottom, 24)
            
            quickActions
                .padding(.bottom, 20)
        }
        .padding(.horizontal, 32)
        .glassMaxEffect()
        .sheet(isPresented: $showRecentApps) {
            RecentAppsSheet(viewModel: viewModel)
        }
    }
    
    private var header: some View {
        VStack(spacing: 8) {
            Text(L10n.appName)
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text(L10n.appTagline)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .id(localization.version)  // Force refresh on language change
    }
    
    private var footerTip: some View {
        HStack(spacing: 8) {
            Image(systemName: "lightbulb.fill")
                .foregroundStyle(.yellow)
            
            Text(L10n.tipText)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background {
            Capsule()
                .fill(Color.yellow.opacity(0.1))
        }
        .id(localization.version)
    }
    
    private var quickActions: some View {
        HStack(spacing: 20) {
            QuickActionButton(icon: "folder", title: "Applications") {
                openApplicationsFolder()
            }
            
            QuickActionButton(icon: "clock.arrow.circlepath", title: L10n.recent) {
                showRecentApps = true
            }
        }
    }
    
    private func openApplicationsFolder() {
        let url = URL(fileURLWithPath: "/Applications")
        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: url.path)
    }
}

// MARK: - Quick Action Button

private struct QuickActionButton: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.caption)
            }
            .foregroundStyle(.secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background {
                Capsule()
                    .fill(isHovered ? Color.primary.opacity(0.08) : Color.clear)
            }
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}

// MARK: - Scanning Screen

struct ScanningScreen: View {
    @ObservedObject var viewModel: ScannerViewModel
    @Environment(\.themeManager) private var themeManager
    @Environment(\.localization) private var localization
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            if let app = viewModel.scannedApp {
                VStack(spacing: 16) {
                    if let icon = app.icon {
                        Image(nsImage: icon)
                            .resizable()
                            .frame(width: 80, height: 80)
                            .shadow(color: .black.opacity(0.2), radius: 10, y: 4)
                    }
                    
                    Text(app.displayName)
                        .font(.title2)
                        .fontWeight(.semibold)
                }
            }
            
            StatusIndicator(
                status: .scanning,
                message: viewModel.statusMessage == .none ? L10n.searchingResidualFiles : viewModel.statusMessage.localized,
                progress: viewModel.currentProgress
            )
            .id(localization.version)
            
            Button(L10n.cancel) {
                viewModel.reset()
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .padding(.top, 8)
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Deleting Screen

struct DeletingScreen: View {
    @ObservedObject var viewModel: ScannerViewModel
    @Environment(\.localization) private var localization
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            if let app = viewModel.scannedApp, let icon = app.icon {
                Image(nsImage: icon)
                    .resizable()
                    .frame(width: 64, height: 64)
                    .opacity(0.5)
            }
            
            StatusIndicator(
                status: .deleting,
                message: viewModel.statusMessage == .none ? L10n.delete : viewModel.statusMessage.localized,
                progress: viewModel.currentProgress
            )
            .id(localization.version)
            
            Text(L10n.doNotCloseApp)
                .font(.caption)
                .foregroundStyle(.tertiary)
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Main Content View") {
    MainContentView()
        .environment(\.themeManager, ThemeManager())
        .frame(width: 800, height: 600)
}
#endif
