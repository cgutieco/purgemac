//
//  StatusIndicator.swift
//  PurgeMac
//
//  PurgeMac - Deep Cleaning Uninstaller for macOS
//

import SwiftUI

// MARK: - Status Type

enum StatusType {
    case idle
    case scanning
    case deleting
    case success
    case error
    case warning
    
    var icon: String {
        switch self {
        case .idle:     return "circle.dashed"
        case .scanning: return "magnifyingglass"
        case .deleting: return "trash"
        case .success:  return "checkmark.circle.fill"
        case .error:    return "xmark.circle.fill"
        case .warning:  return "exclamationmark.triangle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .idle:     return .secondary
        case .scanning: return .accentColor
        case .deleting: return .orange
        case .success:  return .green
        case .error:    return .red
        case .warning:  return .orange
        }
    }
    
    var isAnimated: Bool {
        switch self {
        case .scanning, .deleting: return true
        default: return false
        }
    }
}

// MARK: - Status Indicator

struct StatusIndicator: View {
    let status: StatusType
    var message: String
    var progress: Double? = nil
    var showProgress: Bool = true
    
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Icon or Spinner
            ZStack {
                if status.isAnimated {
                    // Spinning icon
                    Image(systemName: status.icon)
                        .font(.system(size: 32, weight: .medium))
                        .foregroundStyle(status.color)
                        .rotationEffect(.degrees(isAnimating ? 360 : 0))
                        .animation(
                            .linear(duration: 1.5).repeatForever(autoreverses: false),
                            value: isAnimating
                        )
                        .onAppear { isAnimating = true }
                        .onDisappear { isAnimating = false }
                } else {
                    // Static icon
                    Image(systemName: status.icon)
                        .font(.system(size: 32, weight: .medium))
                        .foregroundStyle(status.color)
                        .symbolEffect(.bounce, value: status == .success || status == .error)
                }
            }
            .frame(width: 48, height: 48)
            
            // Message
            Text(message)
                .font(.body)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
            
            // Progress Bar (optional)
            if showProgress, let progress, status.isAnimated {
                ProgressAtom(value: progress, style: .bar, showPercentage: true)
                    .frame(width: 200)
            }
        }
        .padding()
    }
}

// MARK: - Compact Status Indicator

struct CompactStatusIndicator: View {
    let status: StatusType
    var message: String
    
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 8) {
            if status.isAnimated {
                ProgressView()
                    .controlSize(.small)
                    .progressViewStyle(.circular)
            } else {
                Image(systemName: status.icon)
                    .font(.callout)
                    .foregroundStyle(status.color)
            }
            
            Text(message)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Status Badge

struct StatusBadge: View {
    let status: StatusType
    var count: Int? = nil
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(status.color)
                .frame(width: 8, height: 8)
            
            if let count {
                Text("\(count)")
                    .font(.caption2)
                    .fontWeight(.medium)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background {
            Capsule()
                .fill(status.color.opacity(0.15))
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Status Indicator") {
    VStack(spacing: 24) {
        HStack(spacing: 32) {
            StatusIndicator(status: .idle, message: L10n.scanning)
            StatusIndicator(status: .scanning, message: L10n.startingScan, progress: 0.45)
        }
        
        Divider()
        
        HStack(spacing: 32) {
            StatusIndicator(status: .success, message: L10n.cleanupComplete, showProgress: false)
            StatusIndicator(status: .error, message: L10n.permissionRequired, showProgress: false)
        }
        
        Divider()
        
        HStack(spacing: 16) {
            CompactStatusIndicator(status: .scanning, message: L10n.searchingResidualFiles)
            CompactStatusIndicator(status: .success, message: L10n.cleanupComplete)
        }
        
        Divider()
        
        HStack(spacing: 12) {
            StatusBadge(status: .success)
            StatusBadge(status: .warning, count: 3)
            StatusBadge(status: .error, count: 1)
        }
    }
    .padding()
    .frame(width: 600, height: 500)
}
#endif
