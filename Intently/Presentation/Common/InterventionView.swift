//
//  InterventionView.swift
//  Intently
//
//  Created on 2025-01-01.
//

import SwiftUI

struct InterventionView: View {
    let content: InterventionContent
    let onContinue: () -> Void
    let onQuit: () -> Void
    let onDismiss: () -> Void

    @State private var isAnimating = false
    @State private var showQuitConfirmation = false

    var body: some View {
        ZStack {
            // Background blur
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    onDismiss()
                }

            // Intervention Card
            VStack(spacing: 0) {
                // Header
                header

                Divider()

                // Content
                contentView

                Divider()

                // Actions
                actionsView
            }
            .background(Color.appBackground)
            .cornerRadius(AppTheme.CornerRadius.xl)
            .shadow(radius: 20)
            .padding(AppTheme.Spacing.lg)
            .scaleEffect(isAnimating ? 1.0 : 0.8)
            .opacity(isAnimating ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                isAnimating = true
            }
        }
    }

    // MARK: - Header
    private var header: some View {
        HStack {
            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.appTextSecondary)
                    .font(.title3)
            }

            Text(content.title)
                .font(.headline)
                .foregroundColor(.appTextPrimary)

            Spacer()
        }
        .padding()
    }

    // MARK: - Content View
    @ViewBuilder
    private var contentView: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            // Icon based on type
            interventionIcon
                .font(.system(size: 50))
                .foregroundColor(interventionColor)

            // Message
            Text(content.content)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.appTextPrimary)
                .padding(.horizontal)

            // Additional context based on type
            additionalContext
        }
        .padding(AppTheme.Spacing.xl)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Intervention Icon
    private var interventionIcon: some View {
        Image(systemName: iconName)
    }

    private var iconName: String {
        switch content.type {
        case .reflection:
            return "brain.head.profile"
        case .timeAlternative:
            return "clock.fill"
        case .breathing:
            return "wind"
        case .stats:
            return "chart.bar.fill"
        case .emotional:
            return "heart.fill"
        case .activity:
            return "figure.run"
        }
    }

    private var interventionColor: Color {
        switch content.type {
        case .reflection:
            return .blue
        case .timeAlternative:
            return .purple
        case .breathing:
            return .cyan
        case .stats:
            return .orange
        case .emotional:
            return .pink
        case .activity:
            return .green
        }
    }

    // MARK: - Additional Context
    @ViewBuilder
    private var additionalContext: some View {
        switch content.type {
        case .reflection:
            EmptyView()
        case .timeAlternative:
            Text("Try something different instead")
                .font(.caption)
                .foregroundColor(.appTextSecondary)
        case .breathing:
            Text("Take a moment to reset")
                .font(.caption)
                .foregroundColor(.appTextSecondary)
        case .stats:
            EmptyView()
        case .emotional:
            Text("Remember why you started")
                .font(.caption)
                .foregroundColor(.appTextSecondary)
        case .activity:
            Text("Build a better habit")
                .font(.caption)
                .foregroundColor(.appTextSecondary)
        }
    }

    // MARK: - Actions
    private var actionsView: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            // Primary Action
            Button(action: showQuitConfirmation ? onQuit : onContinue) {
                HStack {
                    Image(systemName: showQuitConfirmation ? "checkmark.circle.fill" : "arrow.right.circle.fill")
                    Text(showQuitConfirmation ? "Yes, Quit" : content.actionLabel)
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(showQuitConfirmation ? Color.appGreen : Color.appPrimary)
                .cornerRadius(AppTheme.CornerRadius.md)
            }

            // Secondary Action (if showing quit confirmation)
            if showQuitConfirmation {
                Button("Cancel") {
                    withAnimation {
                        showQuitConfirmation = false
                    }
                }
                .font(.subheadline)
                .foregroundColor(.appTextSecondary)
                .padding(.vertical, 4)
            } else {
                // Dismiss / Continue Anyway
                Button(action: {
                    showQuitConfirmation = true
                }) {
                    Text("I want to quit")
                        .font(.subheadline)
                        .foregroundColor(.appRed)
                }
                .padding(.vertical, 4)
            }

            // Bottom dismiss
            Button(content.dismissLabel) {
                onDismiss()
            }
            .font(.caption)
            .foregroundColor(.appTextTertiary)
            .padding(.bottom, 4)
        }
        .padding()
    }
}

// MARK: - Breathing Exercise View
struct BreathingExerciseView: View {
    let onComplete: () -> Void
    @State private var isInhale = true
    @State private var scale: CGFloat = 1.0

    var body: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            Text("Breathing Exercise")
                .font(.title2)
                .fontWeight(.bold)

            Text(isInhale ? "Inhale" : "Exhale")
                .font(.title3)
                .foregroundColor(.appTextSecondary)

            Circle()
                .fill(interventionColor.opacity(0.3))
                .frame(width: 150, height: 150)
                .scaleEffect(scale)

            Button("Done") {
                onComplete()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .onAppear {
            startBreathing()
        }
    }

    private var interventionColor: Color {
        .cyan
    }

    private func startBreathing() {
        withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
            scale = isInhale ? 1.3 : 1.0
        }
        Timer.scheduledTimer(withTimeInterval: 4, repeats: true) { _ in
            isInhale.toggle()
        }
    }
}

// MARK: - Preview
#Preview("Reflection") {
    InterventionView(
        content: InterventionContent(
            type: .reflection,
            content: "Do you really need to use this app right now?",
            title: "Quick Reflection",
            actionLabel: "I'll Think About It",
            dismissLabel: "Continue Anyway"
        ),
        onContinue: {},
        onQuit: {},
        onDismiss: {}
    )
}

#Preview("Time Alternative") {
    InterventionView(
        content: InterventionContent(
            type: .timeAlternative,
            content: "Read a book for 10 minutes",
            title: "Better Alternatives",
            actionLabel: "Sounds Good",
            dismissLabel: "Not Now"
        ),
        onContinue: {},
        onQuit: {},
        onDismiss: {}
    )
}

#Preview("Breathing") {
    InterventionView(
        content: InterventionContent(
            type: .breathing,
            content: "Take 5 deep breaths",
            title: "Pause & Breathe",
            actionLabel: "Start Breathing",
            dismissLabel: "Skip"
        ),
        onContinue: {},
        onQuit: {},
        onDismiss: {}
    )
}
