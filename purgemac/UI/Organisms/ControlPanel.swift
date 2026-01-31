//
//  ControlPanel.swift
//  PurgeMac
//
//  PurgeMac - Deep Cleaning Uninstaller for macOS
//

import SwiftUI

// MARK: - Control Panel

struct ControlPanel: View {
    let selectedCount: Int
    let totalCount: Int
    let selectedSize: Int64
    var isDeleting: Bool = false
    var deleteProgress: Double? = nil
    
    var onSelectAll: () -> Void
    var onDeselectAll: () -> Void
    var onDelete: () -> Void
    var onCancel: (() -> Void)? = nil
    
    @Environment(\.themeManager) private var themeManager
    @Environment(\.localization) private var localization
    
    private var hasSelection: Bool {
        selectedCount > 0
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Selection info
            selectionInfo
            
            Spacer()
            
            // Actions
            if isDeleting {
                deletingState
            } else {
                actionButtons
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background {
            Rectangle()
                .fill(themeManager.currentMaterial)
                .overlay(alignment: .top) {
                    Divider()
                }
        }
    }
    
    // MARK: - Selection Info
    
    private var selectionInfo: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(selectedCount) \(L10n.selectedFiles)")
                .font(.callout)
                .foregroundStyle(.secondary)
            
            if hasSelection {
                HStack(spacing: 4) {
                    Text("Total:")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    
                    SizeLabel(bytes: selectedSize, style: .detailed, colorCoded: true)
                }
            }
        }
        .id(localization.version)
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        HStack(spacing: 12) {
            // Select/Deselect buttons
            Menu {
                Button(L10n.selectAll, action: onSelectAll)
                Button(L10n.deselectAll, action: onDeselectAll)
            } label: {
                Label(L10n.selectAll, systemImage: "checklist")
                    .font(.callout)
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
            
            // Delete button
            ActionButton.delete(
                title: "\(L10n.delete) \(ByteCountFormatter.string(fromByteCount: selectedSize, countStyle: .file))",
                size: .medium,
                isLoading: false
            ) {
                onDelete()
            }
            .disabled(!hasSelection)
        }
        .id(localization.version)
    }
    
    // MARK: - Deleting State
    
    private var deletingState: some View {
        HStack(spacing: 16) {
            if let progress = deleteProgress {
                ProgressAtom(value: progress, style: .bar, showPercentage: true)
                    .frame(width: 150)
            } else {
                ProgressAtom(style: .circular)
            }
            
            Text(L10n.delete)
                .font(.callout)
                .foregroundStyle(.secondary)
            
            if let onCancel {
                Button(L10n.cancel) {
                    onCancel()
                }
                .buttonStyle(.plain)
                .foregroundStyle(.red)
            }
        }
        .id(localization.version)
    }
}

// MARK: - Minimal Control Panel

struct MinimalControlPanel: View {
    let selectedSize: Int64
    var isDisabled: Bool = false
    var onDelete: () -> Void
    @Environment(\.localization) private var localization
    
    var body: some View {
        HStack {
            Spacer()
            
            ActionButton.delete(
                title: L10n.deletePermanently,
                size: .large
            ) {
                onDelete()
            }
            .disabled(isDisabled)
            .id(localization.version)
            
            Spacer()
        }
        .padding()
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Control Panel") {
    VStack(spacing: 0) {
        Spacer()
        
        ControlPanel(
            selectedCount: 3,
            totalCount: 5,
            selectedSize: 45_000_000,
            onSelectAll: {},
            onDeselectAll: {},
            onDelete: {}
        )
        .environment(\.themeManager, ThemeManager())
    }
    .frame(width: 600, height: 150)
    .background(Color.gray.opacity(0.1))
}

#Preview("Control Panel - Deleting") {
    VStack(spacing: 0) {
        Spacer()
        
        ControlPanel(
            selectedCount: 3,
            totalCount: 5,
            selectedSize: 45_000_000,
            isDeleting: true,
            deleteProgress: 0.65,
            onSelectAll: {},
            onDeselectAll: {},
            onDelete: {},
            onCancel: {}
        )
        .environment(\.themeManager, ThemeManager())
    }
    .frame(width: 600, height: 150)
    .background(Color.gray.opacity(0.1))
}

#Preview("Minimal Control Panel") {
    MinimalControlPanel(
        selectedSize: 150_000_000,
        onDelete: {}
    )
    .frame(width: 400, height: 80)
}
#endif
