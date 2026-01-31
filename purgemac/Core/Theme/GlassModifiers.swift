//
//  GlassModifiers.swift
//  PurgeMac
//
//  PurgeMac - Deep Cleaning Uninstaller for macOS
//

import SwiftUI
import AppKit

// MARK: - Visual Effect Background (NSVisualEffectView wrapper)

struct VisualEffectBackground: NSViewRepresentable {
    var material: NSVisualEffectView.Material
    var blendingMode: NSVisualEffectView.BlendingMode
    var state: NSVisualEffectView.State
    
    init(
        material: NSVisualEffectView.Material = .hudWindow,
        blendingMode: NSVisualEffectView.BlendingMode = .behindWindow,
        state: NSVisualEffectView.State = .active
    ) {
        self.material = material
        self.blendingMode = blendingMode
        self.state = state
    }
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = state
        view.wantsLayer = true
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
        nsView.state = state
    }
}

// MARK: - Transparency to NSVisualEffectView Material Mapping

extension TransparencyLevel {
    var visualEffectMaterial: NSVisualEffectView.Material {
        switch self {
        case .minimum: return .sidebar        // Most opaque
        case .low:     return .menu
        case .medium:  return .popover
        case .high:    return .hudWindow
        case .maximum: return .fullScreenUI   // Most transparent
        }
    }
}

// MARK: - Window Background Modifier

struct WindowVisualEffectModifier: ViewModifier {
    @Environment(\.themeManager) private var themeManager
    
    func body(content: Content) -> some View {
        content
            .background {
                VisualEffectBackground(
                    material: themeManager.transparencyLevel.visualEffectMaterial,
                    blendingMode: .behindWindow,
                    state: .active
                )
                .ignoresSafeArea()
            }
    }
}

// MARK: - Glass Background Modifier

struct GlassBackgroundModifier: ViewModifier {
    @Environment(\.themeManager) private var themeManager
    
    var cornerRadius: CGFloat = 12
    var strokeColor: Color = .white.opacity(0.2)
    var strokeWidth: CGFloat = 0.5
    
    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(themeManager.currentMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(strokeColor, lineWidth: strokeWidth)
                    }
            }
    }
}

// MARK: - Glass Max Effect Modifier

struct GlassMaxEffectModifier: ViewModifier {
    @Environment(\.themeManager) private var themeManager
    
    func body(content: Content) -> some View {
        if themeManager.isGlassMaxEnabled {
            content
                .saturation(1.1)
                .brightness(0.02)
        } else {
            content
        }
    }
}

// MARK: - Vibrancy Text Modifier

struct VibrancyTextModifier: ViewModifier {
    var style: VibrancyStyle = .primary
    
    enum VibrancyStyle {
        case primary
        case secondary
        case tertiary
        
        var foregroundStyle: some ShapeStyle {
            switch self {
            case .primary:   return .primary
            case .secondary: return .secondary
            case .tertiary:  return .tertiary
            }
        }
    }
    
    func body(content: Content) -> some View {
        content
            .foregroundStyle(style.foregroundStyle)
    }
}

// MARK: - Drop Zone Highlight Modifier

struct DropZoneHighlightModifier: ViewModifier {
    var isTargeted: Bool
    
    func body(content: Content) -> some View {
        content
            .overlay {
                if isTargeted {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.accentColor, lineWidth: 2)
                        .background {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.accentColor.opacity(0.1))
                        }
                }
            }
            .animation(.easeInOut(duration: 0.2), value: isTargeted)
    }
}

// MARK: - View Extensions

extension View {
    func glassBackground(
        cornerRadius: CGFloat = 12,
        strokeColor: Color = .white.opacity(0.2),
        strokeWidth: CGFloat = 0.5
    ) -> some View {
        modifier(GlassBackgroundModifier(
            cornerRadius: cornerRadius,
            strokeColor: strokeColor,
            strokeWidth: strokeWidth
        ))
    }
    
    func glassMaxEffect() -> some View {
        modifier(GlassMaxEffectModifier())
    }
    
    func vibrancyText(_ style: VibrancyTextModifier.VibrancyStyle = .primary) -> some View {
        modifier(VibrancyTextModifier(style: style))
    }
    
    func dropZoneHighlight(isTargeted: Bool) -> some View {
        modifier(DropZoneHighlightModifier(isTargeted: isTargeted))
    }
    
    func applyTheme(_ themeManager: ThemeManager) -> some View {
        self.preferredColorScheme(themeManager.preferredColorScheme)
    }
    
    /// Applies a full-window visual effect that blurs the desktop wallpaper behind the window
    func windowVisualEffect() -> some View {
        modifier(WindowVisualEffectModifier())
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Glass Modifiers") {
    VStack(spacing: 20) {
        Text("Glass Background")
            .padding()
            .glassBackground()
        
        Text("Primary Vibrancy")
            .vibrancyText(.primary)
        
        Text("Secondary Vibrancy")
            .vibrancyText(.secondary)
        
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.clear)
            .frame(width: 200, height: 100)
            .dropZoneHighlight(isTargeted: true)
    }
    .padding()
    .frame(width: 300, height: 300)
    .background(Color.gray.opacity(0.3))
}
#endif
