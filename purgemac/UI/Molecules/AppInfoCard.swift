//
//  AppInfoCard.swift
//  PurgeMac
//
//  PurgeMac - Deep Cleaning Uninstaller for macOS
//

import SwiftUI
import AppKit

// MARK: - App Info Card

struct AppInfoCard: View {
    let app: ScannedApp
    var style: CardStyle = .standard
    @Environment(\.localization) private var localization
    
    enum CardStyle {
        case standard   // Vertical con icono grande
        case compact    // Horizontal pequeño
        case sidebar    // Para barra lateral
    }
    
    var body: some View {
        switch style {
        case .standard:
            standardCard.id(localization.version)
        case .compact:
            compactCard.id(localization.version)
        case .sidebar:
            sidebarCard.id(localization.version)
        }
    }
    
    // MARK: - Standard Style
    
    private var standardCard: some View {
        VStack(spacing: 16) {
            appIcon(size: 64)
            
            // App Name
            Text(app.displayName)
                .font(.title2)
                .fontWeight(.semibold)
                .lineLimit(2)
                .multilineTextAlignment(.center)
            
            // Bundle ID
            if let bundleId = app.bundleIdentifier {
                Text(bundleId)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            
            Divider()
                .frame(width: 100)
            
            // Stats
            VStack(spacing: 8) {
                StatRow(label: L10n.totalFiles, value: "\(app.artifacts.count)")
                StatRow(label: L10n.totalSize, value: app.formattedTotalSize)
                StatRow(label: L10n.selected, value: app.formattedSelectedSize, color: .accentColor)
            }
        }
        .padding(24)
        .glassBackground(cornerRadius: 16)
    }
    
    // MARK: - Compact Style
    
    private var compactCard: some View {
        HStack(spacing: 12) {
            appIcon(size: 40)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(app.displayName)
                    .font(.headline)
                    .lineLimit(1)
                
                Text("\(app.artifacts.count) \(L10n.totalFiles.lowercased()) · \(app.formattedTotalSize)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding(12)
        .glassBackground(cornerRadius: 10)
    }
    
    // MARK: - Sidebar Style
    
    private var sidebarCard: some View {
        VStack(spacing: 12) {
            appIcon(size: 48)
            
            Text(app.displayName)
                .font(.headline)
                .lineLimit(2)
                .multilineTextAlignment(.center)
            
            VStack(spacing: 4) {
                Text("\(L10n.totalSize): \(app.formattedTotalSize)")
                    .font(.callout)
                    .fontWeight(.medium)
                
                Text("\(app.selectedCount) \(L10n.selected.lowercased())")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Helpers
    
    @ViewBuilder
    private func appIcon(size: CGFloat) -> some View {
        if let icon = app.icon {
            Image(nsImage: icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size, height: size)
        } else {
            Image(systemName: "app.fill")
                .font(.system(size: size * 0.6))
                .foregroundStyle(.secondary)
                .frame(width: size, height: size)
                .background {
                    RoundedRectangle(cornerRadius: size * 0.2)
                        .fill(Color.secondary.opacity(0.1))
                }
        }
    }
}

// MARK: - Stat Row

private struct StatRow: View {
    let label: String
    let value: String
    var color: Color = .primary
    
    var body: some View {
        HStack {
            Text(label)
                .font(.callout)
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.callout)
                .fontWeight(.medium)
                .foregroundStyle(color)
                .monospacedDigit()
        }
    }
}

// MARK: - Drop Target Card

/// Tarjeta que muestra el objetivo del drop
struct DropTargetCard: View {
    var isTargeted: Bool = false
    @Environment(\.localization) private var localization
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "app.badge.plus")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(isTargeted ? Color.accentColor : Color.secondary)
                .symbolEffect(.bounce, value: isTargeted)
            
            Text(isTargeted ? L10n.dropToScan : L10n.dragAppHere)
                .font(.headline)
                .foregroundStyle(isTargeted ? .primary : .secondary)
        }
        .id(localization.version)
        .frame(width: 160, height: 160)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(
                            isTargeted ? Color.accentColor : Color.secondary.opacity(0.3),
                            style: StrokeStyle(lineWidth: 2, dash: [8])
                        )
                }
        }
        .animation(.easeInOut(duration: 0.2), value: isTargeted)
    }
}

// MARK: - Preview

#if DEBUG
#Preview("App Info Card") {
    HStack(spacing: 24) {
        AppInfoCard(app: .preview, style: .standard)
        
        VStack(spacing: 16) {
            AppInfoCard(app: .preview, style: .compact)
            AppInfoCard(app: .preview, style: .sidebar)
                .frame(width: 180)
                .background(Color.secondary.opacity(0.1))
        }
    }
    .padding()
    .frame(width: 600, height: 400)
}

#Preview("Drop Target Card") {
    HStack(spacing: 24) {
        DropTargetCard(isTargeted: false)
        DropTargetCard(isTargeted: true)
    }
    .padding()
    .frame(width: 400, height: 250)
}
#endif
