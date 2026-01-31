//
//  IconAtom.swift
//  PurgeMac
//
//  PurgeMac - Deep Cleaning Uninstaller for macOS
//

import SwiftUI

// MARK: - Icon Size

enum IconSize: CGFloat, CaseIterable {
    case tiny   = 12
    case small  = 16
    case medium = 20
    case large  = 24
    case xlarge = 32
    case hero   = 48
    case giant  = 72
    
    var fontWeight: Font.Weight {
        switch self {
        case .tiny, .small: return .regular
        case .medium, .large: return .medium
        case .xlarge, .hero: return .light
        case .giant: return .ultraLight
        }
    }
}

// MARK: - Icon Atom

struct IconAtom: View {
    let systemName: String
    var size: IconSize = .medium
    var color: Color? = nil
    var renderingMode: SymbolRenderingMode = .hierarchical
    
    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: size.rawValue, weight: size.fontWeight))
            .symbolRenderingMode(renderingMode)
            .foregroundStyle(color ?? .primary)
    }
}

// MARK: - Convenience Initializers

extension IconAtom {
    static func forCategory(_ category: ArtifactCategory, size: IconSize = .medium) -> IconAtom {
        IconAtom(
            systemName: category.icon,
            size: size,
            color: .accentColor,
            renderingMode: .hierarchical
        )
    }
    
    static func trash(size: IconSize = .medium) -> IconAtom {
        IconAtom(systemName: "trash.fill", size: size, color: .red)
    }
    
    static func checkmark(size: IconSize = .medium) -> IconAtom {
        IconAtom(systemName: "checkmark.circle.fill", size: size, color: .green)
    }
    
    static func warning(size: IconSize = .medium) -> IconAtom {
        IconAtom(systemName: "exclamationmark.triangle.fill", size: size, color: .orange)
    }
    
    static func error(size: IconSize = .medium) -> IconAtom {
        IconAtom(systemName: "xmark.circle.fill", size: size, color: .red)
    }
    
    static func folder(size: IconSize = .medium) -> IconAtom {
        IconAtom(systemName: "folder.fill", size: size, color: .blue)
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Icon Atom") {
    VStack(spacing: 20) {
        HStack(spacing: 20) {
            ForEach(IconSize.allCases, id: \.rawValue) { size in
                IconAtom(systemName: "app.fill", size: size)
            }
        }
        
        Divider()
        
        HStack(spacing: 20) {
            IconAtom.trash()
            IconAtom.checkmark()
            IconAtom.warning()
            IconAtom.error()
            IconAtom.folder()
        }
        
        Divider()
        
        HStack(spacing: 20) {
            ForEach(ArtifactCategory.allCases.prefix(4)) { category in
                IconAtom.forCategory(category, size: .large)
            }
        }
    }
    .padding()
    .frame(width: 400, height: 200)
}
#endif
