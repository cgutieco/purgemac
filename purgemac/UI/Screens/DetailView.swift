//
//  DetailView.swift
//  PurgeMac
//
//  PurgeMac - Deep Cleaning Uninstaller for macOS
//

import SwiftUI

// MARK: - Detail View

struct DetailView: View {
    @ObservedObject var viewModel: ScannerViewModel
    @Environment(\.themeManager) private var themeManager
    @Environment(\.localization) private var localization
    
    @State private var showDeleteConfirmation = false
    @State private var deletePermenantly = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header: Toolbar
            VStack(spacing: 0) {
                DetailToolbar(
                    appName: viewModel.scannedApp?.displayName ?? "App",
                    onBack: { viewModel.reset() },
                    onRescan: {
                        Task {
                            await viewModel.rescan()
                        }
                    }
                )
                Divider()
            }
            .background(.ultraThinMaterial)
            .zIndex(1) // Ensure header stays on top visually if needed
            
            // Body: Split View (Takes all remaining space)
            HSplitView {
                // Sidebar
                DetailSidebar(
                    app: viewModel.scannedApp,
                    selectedCount: viewModel.selectedCount,
                    selectedSize: viewModel.selectedSize,
                    totalSize: viewModel.totalSize,
                    artifacts: viewModel.artifacts
                )
                .frame(minWidth: 180, idealWidth: 200, maxWidth: 250)
                .frame(maxHeight: .infinity) // Ensure sidebar takes full height
                
                // File list
                VStack(spacing: 0) {
                    // Stats bar
                    StatsBar(
                        selectedCount: viewModel.selectedCount,
                        totalCount: viewModel.totalCount,
                        selectedSize: viewModel.selectedSize,
                        totalSize: viewModel.totalSize,
                        onSelectAll: { viewModel.selectAll() },
                        onDeselectAll: { viewModel.deselectAll() },
                        onSelectCategory: { category in
                            viewModel.deselectAll()
                            viewModel.selectCategory(category)
                        }
                    )
                    
                    Divider()
                    
                    // File list con callbacks directos al ViewModel
                    FileListWithCallbacks(
                        artifacts: viewModel.artifacts,
                        onToggle: { id in
                            viewModel.toggleArtifactById(id)
                        },
                        onSelectAllInCategory: { category in
                            viewModel.selectCategory(category)
                        },
                        onDeselectAllInCategory: { category in
                            viewModel.deselectCategory(category)
                        }
                    )
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity) // Ensure file list expands
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity) // Ensure HSplitView expands in the VStack
            
            // Footer: Control Panel
            VStack(spacing: 0) {
                Divider()
                DetailControlPanel(
                    selectedCount: viewModel.selectedCount,
                    selectedSize: viewModel.selectedSize,
                    canDelete: viewModel.canDelete,
                    onSelectAll: { viewModel.selectAll() },
                    onDeselectAll: { viewModel.deselectAll() },
                    onDelete: { permanently in
                        deletePermenantly = permanently
                        showDeleteConfirmation = true
                    }
                )
            }
            .background(.ultraThinMaterial)
            .zIndex(1) // Ensure footer stays on top visually if needed
        }
        .confirmationDialog(
            L10n.delete,
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button(L10n.moveToTrash, role: .destructive) {
                Task {
                    await viewModel.deleteSelected(permanently: false)
                }
            }
            
            Button(L10n.deletePermanently, role: .destructive) {
                Task {
                    await viewModel.deleteSelected(permanently: true)
                }
            }
            
            Button(L10n.cancel, role: .cancel) {}
        } message: {
            Text("\(viewModel.selectedCount) \(L10n.selectedFiles) (\(ByteCountFormatter.string(fromByteCount: viewModel.selectedSize, countStyle: .file)))")
        }
        .id(localization.version)
    }
}

// MARK: - Detail Toolbar

struct DetailToolbar: View {
    let appName: String
    var onBack: () -> Void
    var onRescan: () -> Void
    @Environment(\.localization) private var localization
    
    var body: some View {
        HStack(spacing: 16) {
            Button {
                onBack()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                    Text(L10n.back)
                }
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            
            Divider()
                .frame(height: 20)
            
            Text(appName)
                .font(.headline)
            
            Spacer()
            
            Button {
                onRescan()
            } label: {
                Label(L10n.rescan, systemImage: "arrow.clockwise")
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .id(localization.version)
    }
}

// MARK: - Detail Sidebar

struct DetailSidebar: View {
    let app: ScannedApp?
    let selectedCount: Int
    let selectedSize: Int64
    let totalSize: Int64
    let artifacts: [AppArtifact]
    
    @Environment(\.localization) private var localization
    
    private var categories: [ArtifactCategory] {
        let unique = Set(artifacts.map(\.category))
        return unique.sorted { $0.rawValue < $1.rawValue }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if let app {
                VStack(spacing: 16) {
                    if let icon = app.icon {
                        Image(nsImage: icon)
                            .resizable()
                            .frame(width: 64, height: 64)
                            .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
                    }
                    
                    Text(app.displayName)
                        .font(.headline)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                    
                    if let bundleId = app.bundleIdentifier {
                        Text(bundleId)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                .padding()
                
                Divider().padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 12) {
                    StatItem(label: L10n.totalFiles, value: "\(artifacts.count)")
                    StatItem(label: L10n.totalSize, value: ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file))
                    StatItem(label: L10n.selected, value: "\(selectedCount)", color: .accentColor)
                    StatItem(label: L10n.toFree, value: ByteCountFormatter.string(fromByteCount: selectedSize, countStyle: .file), color: .red)
                }
                .padding()
                .id(localization.version)
                
                Divider().padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(L10n.byCategory)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    
                    ForEach(categories, id: \.self) { category in
                        let categoryArtifacts = artifacts.filter { $0.category == category }
                        CategoryItem(
                            category: category,
                            count: categoryArtifacts.count,
                            size: categoryArtifacts.reduce(0) { $0 + $1.sizeBytes }
                        )
                    }
                }
                .padding()
            }
            
            Spacer()
        }
        .background(Color.primary.opacity(0.02))
    }
}

// MARK: - Stats Bar

private struct StatsBar: View {
    let selectedCount: Int
    let totalCount: Int
    let selectedSize: Int64
    let totalSize: Int64
    var onSelectAll: () -> Void
    var onDeselectAll: () -> Void
    var onSelectCategory: (ArtifactCategory) -> Void
    @Environment(\.localization) private var localization
    
    var body: some View {
        HStack(spacing: 24) {
            Label("\(selectedCount)/\(totalCount) \(L10n.selectedFiles)", systemImage: "doc.on.doc")
            
            Divider().frame(height: 16)
            
            Label(
                "\(ByteCountFormatter.string(fromByteCount: selectedSize, countStyle: .file))",
                systemImage: "externaldrive"
            )
            
            Spacer()
            
            Menu {
                Button(L10n.selectAll) { onSelectAll() }
                Button(L10n.deselectAll) { onDeselectAll() }
                Divider()
                Button(L10n.caches) { onSelectCategory(.caches) }
                Button(L10n.applicationSupport) { onSelectCategory(.applicationSupport) }
            } label: {
                Label(L10n.selectAll, systemImage: "checklist")
            }
            .menuStyle(.borderlessButton)
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.primary.opacity(0.02))
        .id(localization.version)
    }
}

// MARK: - Detail Control Panel

private struct DetailControlPanel: View {
    let selectedCount: Int
    let selectedSize: Int64
    let canDelete: Bool
    var onSelectAll: () -> Void
    var onDeselectAll: () -> Void
    var onDelete: (Bool) -> Void
    @Environment(\.localization) private var localization
    
    var body: some View {
        HStack(spacing: 16) {
            HStack(spacing: 8) {
                Button(L10n.selectAll) { onSelectAll() }
                    .buttonStyle(.plain)
                    .foregroundStyle(Color.accentColor)
                
                Text("·").foregroundStyle(.tertiary)
                
                Button(L10n.deselectAll) { onDeselectAll() }
                    .buttonStyle(.plain)
                    .foregroundStyle(Color.accentColor)
            }
            .font(.callout)
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(selectedCount) \(L10n.selectedFiles)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text(ByteCountFormatter.string(fromByteCount: selectedSize, countStyle: .file))
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            Button {
                onDelete(false)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "trash.fill")
                    Text(L10n.delete)
                }
                .font(.body)
                .fontWeight(.medium)
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(canDelete ? Color.red : Color.gray)
                }
            }
            .buttonStyle(.plain)
            .disabled(!canDelete)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(.ultraThinMaterial)
        .id(localization.version)
    }
}

// MARK: - Helper Views

private struct StatItem: View {
    let label: String
    let value: String
    var color: Color = .primary
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.callout)
                .fontWeight(.medium)
                .foregroundStyle(color)
        }
    }
}

private struct CategoryItem: View {
    let category: ArtifactCategory
    let count: Int
    let size: Int64
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: category.icon)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 16)
            
            Text(category.rawValue)
                .font(.caption)
                .lineLimit(1)
            
            Spacer()
            
            Text(ByteCountFormatter.string(fromByteCount: size, countStyle: .file))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - File List with Callbacks

struct FileListWithCallbacks: View {
    let artifacts: [AppArtifact]
    var onToggle: (UUID) -> Void
    var onSelectAllInCategory: (ArtifactCategory) -> Void
    var onDeselectAllInCategory: (ArtifactCategory) -> Void
    
    private var categories: [ArtifactCategory] {
        let unique = Set(artifacts.map(\.category))
        return unique.sorted { $0.rawValue < $1.rawValue }
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                ForEach(categories, id: \.self) { category in
                    CategorySectionWithCallbacks(
                        category: category,
                        artifacts: artifacts.filter { $0.category == category },
                        onToggle: onToggle,
                        onSelectAll: { onSelectAllInCategory(category) },
                        onDeselectAll: { onDeselectAllInCategory(category) }
                    )
                }
            }
            .padding()
        }
    }
}

// MARK: - Category Section with Callbacks

private struct CategorySectionWithCallbacks: View {
    let category: ArtifactCategory
    let artifacts: [AppArtifact]
    var onToggle: (UUID) -> Void
    var onSelectAll: () -> Void
    var onDeselectAll: () -> Void
    
    @State private var isExpanded = true
    
    private var totalSize: Int64 {
        artifacts.reduce(0) { $0 + $1.sizeBytes }
    }
    
    private var allSelected: Bool {
        artifacts.allSatisfy(\.isSelected)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack(spacing: 8) {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isExpanded.toggle()
                    }
                } label: {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(width: 16)
                }
                .buttonStyle(.plain)
                
                IconAtom.forCategory(category, size: .small)
                
                Text(category.rawValue)
                    .font(.headline)
                
                Text("(\(artifacts.count))")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Button(allSelected ? L10n.deselectAll : L10n.selectAll) {
                    if allSelected {
                        onDeselectAll()
                    } else {
                        onSelectAll()
                    }
                }
                .font(.caption)
                .buttonStyle(.plain)
                .foregroundStyle(Color.accentColor)
                
                SizeLabel(bytes: totalSize, style: .compact)
                    .frame(width: 70, alignment: .trailing)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(Color.secondary.opacity(0.05))
            .cornerRadius(8)
            
            // Items
            if isExpanded {
                VStack(spacing: 2) {
                    ForEach(artifacts) { artifact in
                        FileRowWithCallback(
                            artifact: artifact,
                            onToggle: { onToggle(artifact.id) }
                        )
                    }
                }
                .padding(.leading, 24)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

// MARK: - File Row with Callback

private struct FileRowWithCallback: View {
    let artifact: AppArtifact
    var onToggle: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 12) {
            if artifact.isProtected {
                ZStack {
                    RoundedRectangle(cornerRadius: 4)
                        .strokeBorder(Color.secondary.opacity(0.5), lineWidth: 1)
                        .background(RoundedRectangle(cornerRadius: 4).fill(Color.secondary.opacity(0.1)))
                        .frame(width: 18, height: 18)
                    
                    Image(systemName: "lock.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
            } else {
                Image(systemName: artifact.isSelected ? "checkmark.square.fill" : "square")
                    .font(.system(size: 18))
                    .foregroundStyle(artifact.isSelected ? Color.accentColor : Color.secondary)
            }
            
            IconAtom.forCategory(artifact.category, size: .medium)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    Text(artifact.displayName)
                        .font(.body)
                        .fontWeight(.medium)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    
                    if artifact.isProtected {
                        Text("Protected System")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.cyan)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .overlay(
                                Capsule()
                                    .strokeBorder(Color.cyan, lineWidth: 1)
                            )
                    }
                }
                
                Text(artifact.fullPath)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            
            Spacer()
            
            SizeLabel(artifact: artifact)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .contentShape(Rectangle())
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(isHovered ? Color.primary.opacity(0.05) : Color.clear)
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
        .onTapGesture {
            if !artifact.isProtected {
                onToggle()
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Detail View") {
    DetailView(viewModel: ScannerViewModel())
        .environment(\.themeManager, ThemeManager())
        .frame(width: 800, height: 600)
}
#endif
