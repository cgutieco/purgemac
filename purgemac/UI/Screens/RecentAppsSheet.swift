//
//  RecentAppsSheet.swift
//  PurgeMac
//
//  PurgeMac - Deep Cleaning Uninstaller for macOS
//

import SwiftUI

// MARK: - Recent Apps Sheet

struct RecentAppsSheet: View {
    @ObservedObject var viewModel: ScannerViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.themeManager) private var themeManager
    @Environment(\.localization) private var localization
    
    @State private var recentApps: [RecentAppEntry] = []
    @State private var isLoading = true
    
    var body: some View {
        VStack(spacing: 0) {
            header
            
            Divider()
            
            if isLoading {
                loadingView
            } else if recentApps.isEmpty {
                emptyView
            } else {
                appsList
            }
            
            Divider()
            
            footer
        }
        .frame(width: 360, height: 450)
        .background(themeManager.currentMaterial)
        .task {
            await loadRecentApps()
        }
    }
    
    // MARK: - Header
    
    private var header: some View {
        HStack {
            Image(systemName: "clock.arrow.circlepath")
                .font(.title2)
                .foregroundStyle(.secondary)
            
            Text(L10n.recentApps)
                .font(.headline)
            
            Spacer()
            
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.tertiary)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .id(localization.version)
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView()
            Spacer()
        }
    }
    
    // MARK: - Empty View
    
    private var emptyView: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "clock")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)
            
            Text(L10n.noRecentApps)
                .font(.headline)
                .foregroundStyle(.secondary)
            
            Text(L10n.noRecentAppsHint)
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
            
            Spacer()
        }
        .padding()
        .id(localization.version)
    }
    
    // MARK: - Apps List
    
    private var appsList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(recentApps) { entry in
                    RecentAppRow(entry: entry) {
                        selectApp(entry)
                    }
                    
                    if entry.id != recentApps.last?.id {
                        Divider()
                            .padding(.leading, 60)
                    }
                }
            }
        }
    }
    
    // MARK: - Footer
    
    private var footer: some View {
        HStack {
            Button(L10n.clearHistory) {
                Task {
                    await HistoryService.shared.clearHistory()
                    recentApps = []
                }
            }
            .buttonStyle(.plain)
            .foregroundStyle(.red)
            .opacity(recentApps.isEmpty ? 0.5 : 1)
            .disabled(recentApps.isEmpty)
            
            Spacer()
        }
        .padding()
        .id(localization.version)
    }
    
    // MARK: - Actions
    
    private func loadRecentApps() async {
        recentApps = await HistoryService.shared.getRecentApps()
        isLoading = false
    }
    
    private func selectApp(_ entry: RecentAppEntry) {
        dismiss()
        
        Task {
            switch viewModel.scanMode {
            case .full:
                await viewModel.scanApp(at: entry.appURL)
            case .cacheOnly:
                await viewModel.scanCacheOnly(at: entry.appURL)
            }
        }
    }
}

// MARK: - Recent App Row

struct RecentAppRow: View {
    let entry: RecentAppEntry
    let onTap: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // App Icon
                if let icon = entry.icon {
                    Image(nsImage: icon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 40, height: 40)
                } else {
                    Image(systemName: "app.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(.tertiary)
                        .frame(width: 40, height: 40)
                }
                
                // Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.displayName)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    
                    Text("\(entry.formattedSize) · \(entry.totalArtifactsFound) \(L10n.artifacts)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Time ago
                Text(entry.timeAgo)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
            .background(isHovered ? Color.accentColor.opacity(0.1) : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Recent Apps Sheet") {
    RecentAppsSheet(viewModel: ScannerViewModel())
        .environment(\.themeManager, ThemeManager())
}
#endif
