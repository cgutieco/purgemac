//
//  FileListView.swift
//  PurgeMac
//
//  PurgeMac - Deep Cleaning Uninstaller for macOS
//

import SwiftUI

// MARK: - File List View

struct FileListView: View {
    @Binding var artifacts: [AppArtifact]
    var groupByCategory: Bool = true
    
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                if groupByCategory {
                    ForEach(categories, id: \.self) { category in
                        CategorySectionView(
                            category: category,
                            artifacts: $artifacts
                        )
                    }
                } else {
                    ForEach($artifacts) { $artifact in
                        FileRowBindable(artifact: $artifact)
                    }
                }
            }
            .padding()
        }
    }
    
    private var categories: [ArtifactCategory] {
        let uniqueCategories = Set(artifacts.map(\.category))
        return uniqueCategories.sorted { $0.rawValue < $1.rawValue }
    }
}

// MARK: - Category Section View

private struct CategorySectionView: View {
    let category: ArtifactCategory
    @Binding var artifacts: [AppArtifact]
    
    @State private var isExpanded = true
    
    private var categoryArtifacts: [AppArtifact] {
        artifacts.filter { $0.category == category }
    }
    
    private var totalSize: Int64 {
        categoryArtifacts.reduce(0) { $0 + $1.sizeBytes }
    }
    
    private var selectedCount: Int {
        categoryArtifacts.filter(\.isSelected).count
    }
    
    private var allSelected: Bool {
        categoryArtifacts.allSatisfy(\.isSelected)
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
                
                Text("(\(categoryArtifacts.count))")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                // Selection toggle
                Button(allSelected ? L10n.deselectAll : L10n.selectAll) {
                    toggleAllInCategory(!allSelected)
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
                    ForEach($artifacts) { $artifact in
                        if artifact.category == category {
                            FileRowBindable(artifact: $artifact)
                        }
                    }
                }
                .padding(.leading, 24)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
    
    private func toggleAllInCategory(_ selected: Bool) {
        for index in artifacts.indices where artifacts[index].category == category {
            artifacts[index].isSelected = selected
        }
    }
}

// MARK: - File Row Bindable

struct FileRowBindable: View {
    @Binding var artifact: AppArtifact
    
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: artifact.isSelected ? "checkmark.square.fill" : "square")
                .font(.system(size: 18))
                .foregroundStyle(artifact.isSelected ? Color.accentColor : Color.secondary)
            
            IconAtom.forCategory(artifact.category, size: .medium)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(artifact.displayName)
                    .font(.body)
                    .fontWeight(.medium)
                    .lineLimit(1)
                    .truncationMode(.middle)
                
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
            artifact.isSelected.toggle()
        }
    }
}

// MARK: - Empty State

struct FileListEmptyState: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(.green)
            
            Text(L10n.appIsClean)
                .font(.title2)
                .fontWeight(.medium)
            
            Text(L10n.noArtifactsFound)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// MARK: - Preview

#if DEBUG
struct FileListPreviewWrapper: View {
    @State private var artifacts = AppArtifact.previewList
    
    var body: some View {
        FileListView(artifacts: $artifacts)
            .frame(width: 500, height: 400)
    }
}

#Preview("File List View") {
    FileListPreviewWrapper()
}

#Preview("Empty State") {
    FileListEmptyState()
        .frame(width: 400, height: 300)
}
#endif
