//
//  FileRow.swift
//  PurgeMac
//
//  PurgeMac - Deep Cleaning Uninstaller for macOS
//

import SwiftUI

// MARK: - File Row

struct FileRow: View {
    let artifact: AppArtifact
    var isSelected: Bool
    var onToggle: (Bool) -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 12) {
            CheckboxAtom(isChecked: Binding(
                get: { isSelected },
                set: { _ in }
            ))
            .allowsHitTesting(false)
            
            // Category Icon
            IconAtom.forCategory(artifact.category, size: .medium)
                .frame(width: 24)
            
            // File Info
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
            
            // Size
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
            onToggle(!isSelected)
        }
    }
}

// MARK: - Compact File Row

struct CompactFileRow: View {
    let artifact: AppArtifact
    var isSelected: Bool
    var onToggle: (Bool) -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            Toggle(isOn: Binding(
                get: { isSelected },
                set: { onToggle($0) }
            )) {
                EmptyView()
            }
            .toggleStyle(.checkbox)
            .labelsHidden()
            
            Image(systemName: artifact.category.icon)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Text(artifact.displayName)
                .font(.callout)
                .lineLimit(1)
                .truncationMode(.middle)
            
            Spacer()
            
            Text(artifact.formattedSize)
                .font(.caption)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
    }
}

// MARK: - Category Header Row

struct CategoryHeaderRow: View {
    let category: ArtifactCategory
    let count: Int
    let totalSize: Int64
    var isExpanded: Bool = true
    var onToggle: (() -> Void)? = nil
    
    var body: some View {
        HStack(spacing: 8) {
            if onToggle != nil {
                Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            IconAtom.forCategory(category, size: .small)
            
            Text(category.rawValue)
                .font(.headline)
            
            Text("(\(count))")
                .font(.callout)
                .foregroundStyle(.secondary)
            
            Spacer()
            
            SizeLabel(bytes: totalSize, style: .compact)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(6)
        .contentShape(Rectangle())
        .onTapGesture {
            onToggle?()
        }
    }
}

// MARK: - Preview

#if DEBUG
struct FileRowPreview: View {
    @State private var selections: Set<UUID> = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Standard Row").font(.headline).padding(.bottom, 8)
            
            ForEach(AppArtifact.previewList) { artifact in
                FileRow(
                    artifact: artifact,
                    isSelected: selections.contains(artifact.id)
                ) { selected in
                    if selected {
                        selections.insert(artifact.id)
                    } else {
                        selections.remove(artifact.id)
                    }
                }
            }
            
            Divider().padding(.vertical, 12)
            
            Text("Category Header").font(.headline).padding(.bottom, 8)
            CategoryHeaderRow(
                category: .caches,
                count: 3,
                totalSize: 25_000_000
            )
        }
        .padding()
        .frame(width: 500, height: 400)
    }
}

#Preview("File Row") {
    FileRowPreview()
}
#endif
