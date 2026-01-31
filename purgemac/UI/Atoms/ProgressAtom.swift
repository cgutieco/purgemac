//
//  ProgressAtom.swift
//  PurgeMac
//
//  PurgeMac - Deep Cleaning Uninstaller for macOS
//

import SwiftUI

// MARK: - Progress Style

enum ProgressAtomStyle {
    case linear      // Barra horizontal
    case circular    // Spinner circular
    case bar         // Barra con porcentaje
}

// MARK: - Progress Atom

struct ProgressAtom: View {
    var value: Double? = nil
    var total: Double = 1.0
    var style: ProgressAtomStyle = .linear
    var tint: Color = .accentColor
    var showPercentage: Bool = false
    
    private var progress: Double {
        guard let value else { return 0 }
        return min(max(value / total, 0), 1)
    }
    
    private var percentageText: String {
        "\(Int(progress * 100))%"
    }
    
    var body: some View {
        switch style {
        case .linear:
            linearProgress
        case .circular:
            circularProgress
        case .bar:
            barProgress
        }
    }
    
    // MARK: - Linear Style
    
    private var linearProgress: some View {
        Group {
            if let value {
                ProgressView(value: value, total: total)
                    .progressViewStyle(.linear)
                    .tint(tint)
            } else {
                ProgressView()
                    .progressViewStyle(.linear)
                    .tint(tint)
            }
        }
    }
    
    // MARK: - Circular Style
    
    private var circularProgress: some View {
        Group {
            if let value {
                ProgressView(value: value, total: total)
                    .progressViewStyle(.circular)
                    .tint(tint)
            } else {
                ProgressView()
                    .progressViewStyle(.circular)
                    .controlSize(.small)
            }
        }
    }
    
    // MARK: - Bar Style with Percentage
    
    private var barProgress: some View {
        HStack(spacing: 8) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.secondary.opacity(0.2))
                    
                    if value != nil {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(tint)
                            .frame(width: geometry.size.width * progress)
                            .animation(.easeInOut(duration: 0.3), value: progress)
                    } else {
                        IndeterminateProgressBar()
                            .tint(tint)
                    }
                }
            }
            .frame(height: 8)
            
            if showPercentage && value != nil {
                Text(percentageText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                    .frame(width: 40, alignment: .trailing)
            }
        }
    }
}

// MARK: - Indeterminate Progress Bar

struct IndeterminateProgressBar: View {
    @State private var offset: CGFloat = -1
    var tint: Color = .accentColor
    
    var body: some View {
        GeometryReader { geometry in
            RoundedRectangle(cornerRadius: 4)
                .fill(
                    LinearGradient(
                        colors: [.clear, tint, .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: geometry.size.width * 0.4)
                .offset(x: offset * geometry.size.width)
                .onAppear {
                    withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                        offset = 1.4
                    }
                }
        }
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Progress Atom") {
    VStack(spacing: 24) {
        Group {
            Text("Linear Determinate").font(.caption)
            ProgressAtom(value: 0.6, style: .linear)
            
            Text("Linear Indeterminate").font(.caption)
            ProgressAtom(style: .linear)
        }
        
        Divider()
        
        HStack(spacing: 24) {
            VStack {
                Text("Circular").font(.caption)
                ProgressAtom(value: 0.7, style: .circular)
            }
            VStack {
                Text("Spinning").font(.caption)
                ProgressAtom(style: .circular)
            }
        }
        
        Divider()
        
        Group {
            Text("Bar with %").font(.caption)
            ProgressAtom(value: 0.45, style: .bar, showPercentage: true)
            
            Text("Bar Indeterminate").font(.caption)
            ProgressAtom(style: .bar)
        }
    }
    .padding()
    .frame(width: 300, height: 350)
}
#endif
