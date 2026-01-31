//
//  ActionButton.swift
//  PurgeMac
//
//  PurgeMac - Deep Cleaning Uninstaller for macOS
//

import SwiftUI

// MARK: - Button Style

enum ActionButtonStyle {
    case primary
    case secondary
    case destructive
    case ghost
    
    var backgroundColor: Color {
        switch self {
        case .primary:     return .accentColor
        case .secondary:   return Color(.controlBackgroundColor)
        case .destructive: return .red
        case .ghost:       return .clear
        }
    }
    
    var foregroundColor: Color {
        switch self {
        case .primary, .destructive: return .white
        case .secondary: return .primary
        case .ghost:     return .accentColor
        }
    }
    
    var hoverBackground: Color {
        switch self {
        case .primary:     return .accentColor.opacity(0.8)
        case .secondary:   return Color(.controlBackgroundColor).opacity(0.8)
        case .destructive: return .red.opacity(0.8)
        case .ghost:       return .accentColor.opacity(0.1)
        }
    }
}

// MARK: - Button Size

enum ActionButtonSize {
    case small
    case medium
    case large
    
    var verticalPadding: CGFloat {
        switch self {
        case .small:  return 6
        case .medium: return 10
        case .large:  return 14
        }
    }
    
    var horizontalPadding: CGFloat {
        switch self {
        case .small:  return 12
        case .medium: return 16
        case .large:  return 24
        }
    }
    
    var font: Font {
        switch self {
        case .small:  return .callout
        case .medium: return .body
        case .large:  return .headline
        }
    }
    
    var cornerRadius: CGFloat {
        switch self {
        case .small:  return 6
        case .medium: return 8
        case .large:  return 10
        }
    }
}

// MARK: - Action Button

struct ActionButton: View {
    let title: String
    var icon: String? = nil
    var style: ActionButtonStyle = .primary
    var size: ActionButtonSize = .medium
    var isLoading: Bool = false
    var isDisabled: Bool = false
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .controlSize(.small)
                        .progressViewStyle(.circular)
                } else if let icon {
                    Image(systemName: icon)
                        .font(size.font)
                }
                
                Text(title)
                    .font(size.font)
                    .fontWeight(.medium)
            }
            .padding(.vertical, size.verticalPadding)
            .padding(.horizontal, size.horizontalPadding)
            .foregroundStyle(style.foregroundColor)
            .background {
                RoundedRectangle(cornerRadius: size.cornerRadius)
                    .fill(isHovered ? style.hoverBackground : style.backgroundColor)
            }
            .overlay {
                if style == .ghost {
                    RoundedRectangle(cornerRadius: size.cornerRadius)
                        .stroke(Color.accentColor.opacity(0.5), lineWidth: 1)
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(isDisabled || isLoading)
        .opacity(isDisabled ? 0.5 : 1)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}

// MARK: - Convenience Constructors

extension ActionButton {
    static func delete(
        title: String = "Eliminar",
        size: ActionButtonSize = .medium,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) -> ActionButton {
        ActionButton(
            title: title,
            icon: "trash.fill",
            style: .destructive,
            size: size,
            isLoading: isLoading,
            action: action
        )
    }
    
    static func primary(
        title: String,
        icon: String? = nil,
        size: ActionButtonSize = .medium,
        action: @escaping () -> Void
    ) -> ActionButton {
        ActionButton(
            title: title,
            icon: icon,
            style: .primary,
            size: size,
            action: action
        )
    }
    
    static func secondary(
        title: String,
        icon: String? = nil,
        size: ActionButtonSize = .medium,
        action: @escaping () -> Void
    ) -> ActionButton {
        ActionButton(
            title: title,
            icon: icon,
            style: .secondary,
            size: size,
            action: action
        )
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Action Button") {
    VStack(spacing: 16) {
        HStack(spacing: 12) {
            ActionButton.primary(title: "Primary", icon: "plus") {}
            ActionButton.secondary(title: "Secondary") {}
            ActionButton.delete {}
        }
        
        HStack(spacing: 12) {
            ActionButton(title: "Ghost", style: .ghost) {}
            ActionButton(title: "Loading", isLoading: true) {}
            ActionButton(title: "Disabled", isDisabled: true) {}
        }
        
        HStack(spacing: 12) {
            ActionButton(title: "Small", size: .small) {}
            ActionButton(title: "Medium", size: .medium) {}
            ActionButton(title: "Large", size: .large) {}
        }
    }
    .padding()
    .frame(width: 500, height: 200)
}
#endif
