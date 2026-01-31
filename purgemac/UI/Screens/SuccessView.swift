//
//  SuccessView.swift
//  PurgeMac
//
//  PurgeMac - Deep Cleaning Uninstaller for macOS
//

import SwiftUI

// MARK: - Success View

struct SuccessView: View {
    let freedBytes: Int64
    var appName: String?
    var canUndo: Bool = false
    var wasPermanent: Bool = false
    var onDone: () -> Void
    var onUndo: (() -> Void)?
    
    @State private var showContent = false
    @State private var particlesVisible = false
    @State private var undoTimeRemaining: Int = 30
    @State private var undoTimer: Timer?
    @Environment(\.themeManager) private var themeManager
    @Environment(\.localization) private var localization
    
    var body: some View {
        ZStack {
            if particlesVisible {
                ConfettiView()
                    .ignoresSafeArea()
            }
            
            VStack(spacing: 32) {
                Spacer()
                
                successIcon
                
                VStack(spacing: 12) {
                    Text(L10n.cleanupComplete)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 20)
                    
                    if let appName {
                        Text(appName)
                            .font(.title3)
                            .foregroundStyle(.secondary)
                            .opacity(showContent ? 1 : 0)
                    }
                }
                
                freedSpaceCard
                    .opacity(showContent ? 1 : 0)
                    .scaleEffect(showContent ? 1 : 0.9)
                
                // Undo section
                undoSection
                    .opacity(showContent ? 1 : 0)
                
                Spacer()
                
                VStack(spacing: 16) {
                    ActionButton.primary(title: L10n.scanAnotherApp, icon: "plus.circle.fill") {
                        stopUndoTimer()
                        onDone()
                    }
                    
                    Button(L10n.backToHome) {
                        stopUndoTimer()
                        onDone()
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                }
                .opacity(showContent ? 1 : 0)
                .padding(.bottom, 40)
                .id(localization.version)
            }
            .padding(.horizontal, 40)
        }
        .onAppear {
            animateIn()
            if canUndo && !wasPermanent {
                startUndoTimer()
            }
        }
        .onDisappear {
            stopUndoTimer()
        }
    }
    
    // MARK: - Undo Section
    
    @ViewBuilder
    private var undoSection: some View {
        if wasPermanent {
            // Advertencia de eliminación permanente
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                Text(L10n.permanentDeleteWarning)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.orange.opacity(0.1))
            }
        } else if canUndo && undoTimeRemaining > 0 {
            // Botón de deshacer con timer
            Button {
                stopUndoTimer()
                onUndo?()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.uturn.backward.circle.fill")
                    Text(L10n.undoCleanup)
                    Text("(\(undoTimeRemaining)s)")
                        .foregroundStyle(.secondary)
                }
                .font(.callout)
                .fontWeight(.medium)
                .foregroundStyle(.blue)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.blue.opacity(0.1))
                }
            }
            .buttonStyle(.plain)
        }
    }
    
    // MARK: - Timer
    
    private func startUndoTimer() {
        undoTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if undoTimeRemaining > 0 {
                undoTimeRemaining -= 1
            } else {
                stopUndoTimer()
            }
        }
    }
    
    private func stopUndoTimer() {
        undoTimer?.invalidate()
        undoTimer = nil
    }
    
    // MARK: - Subviews
    
    private var successIcon: some View {
        ZStack {
            Circle()
                .fill(Color.green.opacity(0.2))
                .frame(width: 140, height: 140)
                .blur(radius: 30)
                .scaleEffect(showContent ? 1.2 : 0.8)
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80, weight: .light))
                .foregroundStyle(.green)
                .symbolRenderingMode(.hierarchical)
                .scaleEffect(showContent ? 1 : 0.5)
                .rotationEffect(.degrees(showContent ? 0 : -180))
        }
        .animation(.spring(response: 0.6, dampingFraction: 0.6), value: showContent)
    }
    
    private var freedSpaceCard: some View {
        VStack(spacing: 8) {
            Text(L10n.spaceFreed)
                .font(.caption)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(1)
            
            Text(ByteCountFormatter.string(fromByteCount: freedBytes, countStyle: .file))
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundStyle(.green)
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 40)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.green.opacity(0.3), lineWidth: 1)
                }
        }
        .id(localization.version)
    }
    
    // MARK: - Animation
    
    private func animateIn() {
        withAnimation(.easeOut(duration: 0.8)) {
            showContent = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            particlesVisible = true
        }
    }
}

// MARK: - Confetti View

struct ConfettiView: View {
    @State private var particles: [ConfettiParticle] = []
    @State private var isAnimating = true
    @State private var isFadingOut = false
    @State private var timer: Timer?
    
    var body: some View {
        GeometryReader { geometry in
            TimelineView(.animation(minimumInterval: 0.02)) { _ in
                Canvas { context, size in
                    for particle in particles {
                        let rect = CGRect(
                            x: particle.x,
                            y: particle.y,
                            width: particle.size,
                            height: particle.size
                        )
                        
                        context.fill(
                            Path(ellipseIn: rect),
                            with: .color(particle.color.opacity(particle.opacity))
                        )
                    }
                }
            }
            .onAppear {
                generateParticles(in: geometry.size)
                animateParticles(in: geometry.size)
            }
            .onDisappear {
                timer?.invalidate()
                timer = nil
            }
        }
    }
    
    private func generateParticles(in size: CGSize) {
        let colors: [Color] = [.green, .blue, .yellow, .orange, .pink, .purple]
        let width = max(size.width, 600) // Asegurar un mínimo de ancho
        
        for _ in 0..<60 {
            particles.append(ConfettiParticle(
                x: CGFloat.random(in: 0...width),
                y: CGFloat.random(in: -100...0),
                size: CGFloat.random(in: 4...10),
                color: colors.randomElement() ?? .green,
                velocity: CGFloat.random(in: 80...180),
                opacity: 1.0
            ))
        }
    }
    
    private func animateParticles(in size: CGSize) {
        let width = max(size.width, 600)
        let startTime = Date()
        let animationDuration: TimeInterval = 4.0
        let fadeOutStart: TimeInterval = 2.5
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { currentTimer in
            let elapsedTime = Date().timeIntervalSince(startTime)
            
            var globalFadeMultiplier: Double = 1.0
            if elapsedTime > fadeOutStart {
                let fadeProgress = (elapsedTime - fadeOutStart) / (animationDuration - fadeOutStart)
                globalFadeMultiplier = max(0, 1.0 - fadeProgress)
            }
            
            for i in particles.indices {
                particles[i].y += particles[i].velocity * 0.02
                particles[i].x += CGFloat.random(in: -2...2)
                
                if elapsedTime > fadeOutStart {
                    particles[i].opacity = particles[i].opacity * 0.97 * globalFadeMultiplier
                } else {
                    if particles[i].y > size.height * 0.7 {
                        particles[i].opacity -= 0.02
                    }
                }
                
                if elapsedTime < fadeOutStart && particles[i].opacity <= 0.1 {
                    particles[i].y = CGFloat.random(in: -50...0)
                    particles[i].x = CGFloat.random(in: 0...width)
                    particles[i].opacity = 1.0
                }
            }
            
            if elapsedTime >= animationDuration {
                currentTimer.invalidate()
                timer = nil
                particles.removeAll()
            }
        }
    }
}

private struct ConfettiParticle {
    var x: CGFloat
    var y: CGFloat
    var size: CGFloat
    var color: Color
    var velocity: CGFloat
    var opacity: Double
}

// MARK: - Preview

#if DEBUG
#Preview("Success View") {
    SuccessView(
        freedBytes: 2_500_000_000,
        appName: "Slack",
        onDone: {}
    )
    .environment(\.themeManager, ThemeManager())
    .frame(width: 600, height: 500)
}

#Preview("Success View - Small") {
    SuccessView(
        freedBytes: 150_000_000,
        appName: nil,
        onDone: {}
    )
    .environment(\.themeManager, ThemeManager())
    .frame(width: 500, height: 450)
}
#endif
