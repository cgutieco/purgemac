//
//  SizeLabel.swift
//  PurgeMac
//
//  PurgeMac - Deep Cleaning Uninstaller for macOS
//

import SwiftUI

// MARK: - Size Label Style

enum SizeLabelStyle {
    case compact    // "15 MB"
    case detailed   // "15.2 MB"
    case full       // "15,234,567 bytes"
}

// MARK: - Size Label

struct SizeLabel: View {
    let bytes: Int64
    var style: SizeLabelStyle = .compact
    var showIcon: Bool = false
    var colorCoded: Bool = true
    
    private var formattedSize: String {
        let formatter = ByteCountFormatter()
        
        switch style {
        case .compact:
            formatter.countStyle = .file
            formatter.allowedUnits = [.useKB, .useMB, .useGB]
            formatter.zeroPadsFractionDigits = false
        case .detailed:
            formatter.countStyle = .file
            formatter.includesActualByteCount = false
        case .full:
            formatter.countStyle = .file
            formatter.includesActualByteCount = true
        }
        
        return formatter.string(fromByteCount: bytes)
    }
    
    private var sizeColor: Color {
        guard colorCoded else { return .secondary }
        
        let mb = Double(bytes) / 1_000_000
        
        switch mb {
        case 0..<1:      return .secondary       // < 1 MB: gris
        case 1..<10:     return .primary         // 1-10 MB: normal
        case 10..<100:   return .orange          // 10-100 MB: advertencia
        default:         return .red             // > 100 MB: crítico
        }
    }
    
    private var sizeIcon: String {
        let mb = Double(bytes) / 1_000_000
        
        switch mb {
        case 0..<1:      return "doc.fill"
        case 1..<10:     return "doc.zipper"
        case 10..<100:   return "externaldrive.fill"
        default:         return "externaldrive.fill.badge.exclamationmark"
        }
    }
    
    var body: some View {
        HStack(spacing: 4) {
            if showIcon {
                Image(systemName: sizeIcon)
                    .font(.caption)
                    .foregroundStyle(sizeColor)
            }
            
            Text(formattedSize)
                .font(.callout)
                .monospacedDigit()
                .foregroundStyle(sizeColor)
        }
    }
}

// MARK: - Convenience Initializers

extension SizeLabel {
    init(artifact: AppArtifact, style: SizeLabelStyle = .compact) {
        self.bytes = artifact.sizeBytes
        self.style = style
        self.showIcon = false
        self.colorCoded = true
    }
    
    static func total(_ bytes: Int64) -> SizeLabel {
        SizeLabel(bytes: bytes, style: .detailed, showIcon: true, colorCoded: true)
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Size Label") {
    VStack(alignment: .leading, spacing: 16) {
        Text("By Size").font(.headline)
        HStack(spacing: 20) {
            SizeLabel(bytes: 500)           // < 1 KB
            SizeLabel(bytes: 500_000)       // ~500 KB
            SizeLabel(bytes: 5_000_000)     // ~5 MB
            SizeLabel(bytes: 50_000_000)    // ~50 MB
            SizeLabel(bytes: 500_000_000)   // ~500 MB
        }
        
        Divider()
        
        Text("Styles").font(.headline)
        VStack(alignment: .leading, spacing: 8) {
            SizeLabel(bytes: 15_234_567, style: .compact)
            SizeLabel(bytes: 15_234_567, style: .detailed)
            SizeLabel(bytes: 15_234_567, style: .full)
        }
        
        Divider()
        
        Text("With Icon").font(.headline)
        SizeLabel(bytes: 150_000_000, showIcon: true)
        
        Divider()
        
        Text("Total Style").font(.headline)
        SizeLabel.total(2_500_000_000) // 2.5 GB
    }
    .padding()
    .frame(width: 400, height: 350)
}
#endif
