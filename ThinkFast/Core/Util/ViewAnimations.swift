//
//  ViewAnimations.swift
//  ThinkFast
//
//  Created on 2025-01-01.
//

import SwiftUI

// MARK: - Animation Modifiers
extension View {
    /// Fade in animation
    func fadeIn(
        duration: Double = 0.3,
        delay: Double = 0
    ) -> some View {
        opacity(0)
            .onAppear {
                withAnimation(.easeIn(duration: duration).delay(delay)) {
                    self.opacity(1)
                }
            }
    }

    /// Scale animation on appear
    func scaleIn(
        initialScale: CGFloat = 0.8,
        duration: Double = 0.3
    ) -> some View {
        scaleEffect(initialScale)
            .onAppear {
                withAnimation(.spring(response: duration, dampingFraction: 0.7)) {
                    self.scaleEffect(1.0)
                }
            }
    }

    /// Slide in from edge
    func slideIn(
        from edge: Edge = .bottom,
        duration: Double = 0.4
    ) -> some View {
        offset(offsetFor(edge: edge))
            .onAppear {
                withAnimation(.easeOut(duration: duration)) {
                    self.offset(.zero)
                }
            }
    }

    private func offsetFor(edge: Edge) -> CGSize {
        switch edge {
        case .top: return CGSize(width: 0, height: -50)
        case .bottom: return CGSize(width: 0, height: 50)
        case .leading: return CGSize(width: -50, height: 0)
        case .trailing: return CGSize(width: 50, height: 0)
        }
    }

    /// Bounce animation
    func bounce(on condition: Bool = true) -> some View {
        self.scaleEffect(condition ? 1.05 : 1.0)
            .animation(
                condition ? Animation.spring(response: 0.3, dampingFraction: 0.5) : .default,
                value: condition
            )
    }

    /// Shimmer effect for loading
    func shimmer() -> some View {
        self.overlay(
            GeometryReader { geometry in
                LinearGradient(
                    colors: [.clear, .white.opacity(0.3), .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: geometry.size.width)
                .offset(x: -geometry.size.width)
                .onAppear {
                    withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                        HStack(spacing: 0) {
                            ForEach(0..<2) { _ in
                                Rectangle()
                                    .fill(Color.clear)
                                    .frame(width: geometry.size.width)
                            }
                        }
                        .offset(x: geometry.size.width * 2)
                    }
                }
            }
        )
    }

    /// Card press animation
    func cardPress() -> some View {
        self.scaleEffect(0.98)
            .animation(.easeInOut(duration: 0.1), value: 0.98)
    }

    /// Stagger animation for lists
    func staggered(
        delay: Double = 0.1,
        @ViewBuilder content: () -> some View
    ) -> some View {
        content()
            .opacity(0)
            .offset(y: 20)
            .onAppear {
                withAnimation(.easeOut(duration: 0.5).delay(delay)) {
                    self.opacity(1)
                    self.offset(y: 0)
                }
            }
    }
}

// MARK: - Button Animation
struct AnimatedButton: View {
    let action: () -> Void
    let label: String
    let isLoading: Bool
    let style: ButtonStyle

    enum ButtonStyle {
        case primary
        case secondary
        case destructive
    }

    var body: some View {
        Button(action: {
            HapticFeedback.buttonPress()
            action()
        }) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                }
                Text(label)
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(backgroundForStyle)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.95 : 1)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
    }

    @State private var isPressed = false

    private var backgroundForStyle: Color {
        switch style {
        case .primary:
            return .appPrimary
        case .secondary:
            return .appSecondary
        case .destructive:
            return .appRed
        }
    }
}

// MARK: - Confetti Animation
struct ConfettiView: View {
    var isShowing: Bool

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if isShowing {
                    ForEach(0..<50) { _ in
                        Circle()
                            .fill(randomColorValue)
                            .frame(width: 8, height: 8)
                            .position(
                                x: CGFloat.random(in: 0...geometry.size.width),
                                y: CGFloat.random(in: 0...geometry.size.height)
                            )
                            .opacity(0)
                            .transition(.opacity)
                    }
                }
            }
        }
        .onChange(of: isShowing) { _, newValue in
            if newValue {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                    // Trigger confetti
                }
            }
        }
    }

    private var randomColorValue: Color {
        let colors: [Color] = [.appPrimary, .appSecondary, .appGreen, .appOrange, .appRed, .purple, .pink]
        return colors.randomElement() ?? .appPrimary
    }
}

// MARK: - Progress Animation
struct AnimatedProgressBar: View {
    let progress: Double
    let color: Color

    @State private var animatedProgress: Double = 0

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.appTertiaryBackground)
                    .frame(height: 8)

                RoundedRectangle(cornerRadius: 4)
                    .fill(color)
                    .frame(width: geometry.size.width * CGFloat(animatedProgress), height: 8)
            }
        }
        .onChange(of: progress) { _, newValue in
            withAnimation(.easeInOut(duration: 0.5)) {
                animatedProgress = newValue
            }
        }
    }
}

// MARK: - List Row Animation
struct AnimatedListRow<Content: View>: View {
    let content: Content
    let delay: Double

    @State private var isVisible = false

    var body: some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 20)
            .animation(.easeOut(duration: 0.4).delay(delay), value: isVisible)
            .onAppear {
                isVisible = true
            }
    }
}

// MARK: - Pulse Animation
struct PulsingView: View {
    let isActive: Bool
    let color: Color

    var body: some View {
        Circle()
            .stroke(isActive ? color : Color.clear, lineWidth: 4)
            .scaleEffect(isActive ? 1.1 : 1.0)
            .opacity(isActive ? 0.8 : 0.0)
            .animation(
                isActive ? .easeInOut(duration: 1).repeatForever(autoreverses: true) : .default,
                value: isActive
            )
    }
}

// MARK: - Loading State View
struct LoadingStateView: View {
    let message: String

    var body: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .appPrimary))
                .scaleEffect(1.5)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.appTextSecondary)
        }
        .padding()
    }
}

// MARK: - Empty State Animation
struct AnimatedEmptyState: View {
    let image: String
    let title: String
    let subtitle: String
    let actionTitle: String?
    let action: (() -> Void)?

    var body: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            Image(systemName: image)
                .font(.system(size: 60))
                .foregroundColor(.appTextTertiary)
                .scaleIn()

            Text(title)
                .font(.headline)
                .fadeIn()

            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(.appTextSecondary)
                .multilineTextAlignment(.center)
                .fadeIn(delay: 0.2)

            if let actionTitle = actionTitle, let action = action {
                Button(actionTitle, action: action)
                    .fadeIn(delay: 0.4)
            }
        }
        .padding()
    }
}
