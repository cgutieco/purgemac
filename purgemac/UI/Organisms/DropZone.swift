//
//  DropZone.swift
//  PurgeMac
//
//  PurgeMac - Deep Cleaning Uninstaller for macOS
//

import SwiftUI
import UniformTypeIdentifiers

// MARK: - Drop Zone

struct DropZone: View {
    var isCacheOnlyMode: Bool = false
    var onAppDropped: (URL) -> Void
    
    @State private var isTargeted = false
    @State private var isAnimating = false
    @Environment(\.themeManager) private var themeManager
    @Environment(\.localization) private var localization
    
    // Animation states
    @State private var iconScale: CGFloat = 1.0
    @State private var pulseOpacity: Double = 0.0
    
    var body: some View {
        ZStack {
            // Background pulse animation
            Circle()
                .fill(Color.accentColor.opacity(0.1))
                .scaleEffect(isAnimating ? 1.2 : 0.8)
                .opacity(pulseOpacity)
                .animation(
                    .easeInOut(duration: 2).repeatForever(autoreverses: true),
                    value: isAnimating
                )
            
            // Main drop area
            VStack(spacing: 24) {
                // Icon
                ZStack {
                    // Glow effect when targeted
                    if isTargeted {
                        Circle()
                            .fill(Color.accentColor.opacity(0.2))
                            .frame(width: 120, height: 120)
                            .blur(radius: 20)
                    }
                    
                    Image(systemName: isTargeted ? "arrow.down.app.fill" : "arrow.down.app")
                        .font(.system(size: 72, weight: .light))
                        .foregroundStyle(isTargeted ? Color.accentColor : Color.secondary)
                        .symbolRenderingMode(.hierarchical)
                        .scaleEffect(iconScale)
                        .symbolEffect(.bounce, value: isTargeted)
                }
                .frame(width: 120, height: 120)
                
                // Text
                VStack(spacing: 8) {
                    Text(isTargeted ? L10n.dropToScan : L10n.dragAppHere)
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundStyle(isTargeted ? .primary : .secondary)
                    
                    Text(isCacheOnlyMode ? L10n.cacheOnlyHint : L10n.toFindResidualFiles)
                        .font(.callout)
                        .foregroundStyle(isCacheOnlyMode ? AnyShapeStyle(Color.orange) : AnyShapeStyle(.tertiary))
                        .opacity(isTargeted ? 0 : 1)
                    
                    if isCacheOnlyMode {
                        HStack(spacing: 4) {
                            Image(systemName: "internaldrive.fill")
                            Text(L10n.cacheOnlyMode)
                        }
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.orange))
                        .opacity(isTargeted ? 0 : 1)
                    }
                }
                .id(localization.version)
            }
            .padding(60)
            .frame(maxWidth: 400, maxHeight: 350)
            .background {
                RoundedRectangle(cornerRadius: 24)
                    .fill(themeManager.currentMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: 24)
                            .strokeBorder(
                                isTargeted ? Color.accentColor : Color.secondary.opacity(0.2),
                                style: StrokeStyle(
                                    lineWidth: isTargeted ? 2 : 1,
                                    dash: isTargeted ? [] : [12, 8]
                                )
                            )
                    }
                    .shadow(
                        color: isTargeted ? Color.accentColor.opacity(0.3) : .clear,
                        radius: 20
                    )
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isTargeted)
        .onAppear {
            isAnimating = true
            pulseOpacity = 0.5
        }
        .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
            handleDrop(providers: providers)
        }
        .onChange(of: isTargeted) { _, targeted in
            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                iconScale = targeted ? 1.15 : 1.0
            }
        }
    }
    
    // MARK: - Drop Handling
    
    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        
        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, error in
            guard error == nil,
                  let data = item as? Data,
                  let url = URL(dataRepresentation: data, relativeTo: nil),
                  url.pathExtension.lowercased() == "app" else {
                return
            }
            
            DispatchQueue.main.async {
                onAppDropped(url)
            }
        }
        
        return true
    }
}

// MARK: - Compact Drop Zone

/// Versión compacta para usar en barra lateral
struct CompactDropZone: View {
    var onAppDropped: (URL) -> Void
    
    @State private var isTargeted = false
    @Environment(\.localization) private var localization
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "plus.app")
                .font(.system(size: 28, weight: .light))
                .foregroundStyle(isTargeted ? Color.accentColor : Color.secondary)
            
            Text(L10n.addApp)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .id(localization.version)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    isTargeted ? Color.accentColor : Color.secondary.opacity(0.3),
                    style: StrokeStyle(lineWidth: 1, dash: [6, 4])
                )
        }
        .animation(.easeInOut(duration: 0.2), value: isTargeted)
        .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
            guard let provider = providers.first else { return false }
            
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, error in
                guard error == nil,
                      let data = item as? Data,
                      let url = URL(dataRepresentation: data, relativeTo: nil),
                      url.pathExtension.lowercased() == "app" else {
                    return
                }
                
                DispatchQueue.main.async {
                    onAppDropped(url)
                }
            }
            
            return true
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Drop Zone") {
    VStack {
        DropZone { url in
            print("Dropped: \(url)")
        }
        .environment(\.themeManager, ThemeManager())
    }
    .padding()
    .frame(width: 500, height: 450)
    .background(Color.gray.opacity(0.1))
}

#Preview("Compact Drop Zone") {
    CompactDropZone { url in
        print("Dropped: \(url)")
    }
    .frame(width: 180)
    .padding()
}
#endif
