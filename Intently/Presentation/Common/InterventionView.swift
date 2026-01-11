//
//  InterventionView.swift
//  Intently
//
//  Created on 2025-01-01.
//

import SwiftUI

struct InterventionView: View {
    let content: InterventionContent
    let frictionLevel: FrictionLevel
    let onContinue: () -> Void
    let onQuit: () -> Void
    let onDismiss: () -> Void

    @State private var isAnimating = false
    @State private var showQuitConfirmation = false
    @State private var countdownSeconds: Int = 0
    @State private var canProceed = false
    @State private var showBreathingExercise = false

    var body: some View {
        ZStack {
            // Background blur
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    if frictionLevel == .gentle {
                        onDismiss()
                    }
                }

            // Intervention Card
            VStack(spacing: 0) {
                // Header with friction indicator
                header

                Divider()

                // Friction-level specific countdown or breathing
                if frictionLevel.requiresInteraction {
                    frictionView
                }

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

            // Start countdown if needed
            if frictionLevel.requiresInteraction {
                startCountdown()
            }
        }
        .sheet(isPresented: $showBreathingExercise) {
            BreathingExerciseView(onComplete: {
                showBreathingExercise = false
            })
        }
    }

    // MARK: - Friction View
    @ViewBuilder
    private var frictionView: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            // Countdown timer
            if countdownSeconds > 0 {
                VStack(spacing: AppTheme.Spacing.sm) {
                    Text(frictionLevel.description)
                        .font(.caption)
                        .foregroundColor(.appTextSecondary)

                    Text("\(countdownSeconds)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(canProceed ? .appGreen : .appPrimary)

                    if !canProceed {
                        Text("Please wait before continuing")
                            .font(.caption)
                            .foregroundColor(.appTextSecondary)
                    }
                }
                .padding(.vertical, AppTheme.Spacing.lg)
            }

            // Breathing exercise prompt (for firm friction)
            if frictionLevel == .firm && canProceed && !showBreathingExercise {
                Button(action: { showBreathingExercise = true }) {
                    HStack {
                        Image(systemName: "wind")
                        Text("Take a Breathing Exercise")
                    }
                    .font(.subheadline)
                    .foregroundColor(.appPrimary)
                    .padding(.horizontal, AppTheme.Spacing.lg)
                    .padding(.vertical, AppTheme.Spacing.sm)
                    .background(Color.appPrimary.opacity(0.1))
                    .cornerRadius(AppTheme.CornerRadius.md)
                }
            }
        }
        .padding(.vertical, AppTheme.Spacing.md)
        .background(Color.appBackground.opacity(0.5))
    }

    // MARK: - Start Countdown
    private func startCountdown() {
        countdownSeconds = frictionLevel.delayMs / 1000
        canProceed = false

        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if countdownSeconds > 0 {
                countdownSeconds -= 1
            } else {
                timer.invalidate()
                canProceed = true
            }
        }
    }

    // MARK: - Header
    private var header: some View {
        HStack {
            // Dismiss button (only for gentle friction)
            if frictionLevel == .gentle {
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.appTextSecondary)
                        .font(.title3)
                }
            } else {
                // Friction level indicator for higher friction
                frictionIndicator
                    .font(.caption2)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(frictionColor.opacity(0.2))
                    .foregroundColor(frictionColor)
                    .cornerRadius(12)
            }

            Text(content.title)
                .font(.headline)
                .foregroundColor(.appTextPrimary)

            Spacer()

            // Friction badge
            Text(frictionLevel.displayName.uppercased())
                .font(.caption2)
                .fontWeight(.semibold)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(frictionColor.opacity(0.2))
                .foregroundColor(frictionColor)
                .cornerRadius(4)
        }
        .padding()
    }

    // MARK: - Friction Indicator
    private var frictionIndicator: some View {
        HStack(spacing: 4) {
            ForEach(0..<4) { index in
                Circle()
                    .fill(index < frictionLevel.rawValue + 1 ? frictionColor : Color.gray.opacity(0.3))
                    .frame(width: 6, height: 6)
            }
        }
    }

    // MARK: - Friction Color
    private var frictionColor: Color {
        switch frictionLevel {
        case .gentle:
            return .green
        case .moderate:
            return .yellow
        case .firm:
            return .orange
        case .locked:
            return .red
        }
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
            // Primary Action - affected by friction level
            Button(action: canProceed || !frictionLevel.requiresInteraction ? (showQuitConfirmation ? onQuit : onContinue) : {}) {
                HStack {
                    Image(systemName: showQuitConfirmation ? "checkmark.circle.fill" : "arrow.right.circle.fill")
                    Text(showQuitConfirmation ? "Yes, Quit" : content.actionLabel)
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background((canProceed || !frictionLevel.requiresInteraction) ? (showQuitConfirmation ? Color.appGreen : Color.appPrimary) : Color.gray)
                .cornerRadius(AppTheme.CornerRadius.md)
            }
            .disabled(!canProceed && frictionLevel.requiresInteraction && !showQuitConfirmation)

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
            } else if frictionLevel != .locked {
                // Dismiss / Continue Anyway (not available for locked friction)
                Button(action: {
                    showQuitConfirmation = true
                }) {
                    Text("I want to quit")
                        .font(.subheadline)
                        .foregroundColor(.appRed)
                }
                .padding(.vertical, 4)
            }

            // Bottom dismiss (only for gentle friction)
            if frictionLevel == .gentle {
                Button(content.dismissLabel) {
                    onDismiss()
                }
                .font(.caption)
                .foregroundColor(.appTextTertiary)
                .padding(.bottom, 4)
            } else if frictionLevel == .locked {
                // Message for locked friction
                Text("This intervention requires your attention")
                    .font(.caption)
                    .foregroundColor(.appTextSecondary)
                    .padding(.bottom, 4)
            }
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
#Preview("Reflection - Gentle") {
    InterventionView(
        content: InterventionContent(
            type: .reflection,
            content: "Do you really need to use this app right now?",
            title: "Quick Reflection",
            actionLabel: "I'll Think About It",
            dismissLabel: "Continue Anyway"
        ),
        frictionLevel: .gentle,
        onContinue: {},
        onQuit: {},
        onDismiss: {}
    )
}

#Preview("Time Alternative - Moderate") {
    InterventionView(
        content: InterventionContent(
            type: .timeAlternative,
            content: "Read a book for 10 minutes",
            title: "Better Alternatives",
            actionLabel: "Sounds Good",
            dismissLabel: "Not Now"
        ),
        frictionLevel: .moderate,
        onContinue: {},
        onQuit: {},
        onDismiss: {}
    )
}

#Preview("Breathing - Firm") {
    InterventionView(
        content: InterventionContent(
            type: .breathing,
            content: "Take 5 deep breaths",
            title: "Pause & Breathe",
            actionLabel: "Start Breathing",
            dismissLabel: "Skip"
        ),
        frictionLevel: .firm,
        onContinue: {},
        onQuit: {},
        onDismiss: {}
    )
}

#Preview("Locked - Maximum Friction") {
    InterventionView(
        content: InterventionContent(
            type: .reflection,
            content: "You've exceeded your daily limit. Take a break and come back tomorrow.",
            title: "Time for a Break",
            actionLabel: "I Understand",
            dismissLabel: ""
        ),
        frictionLevel: .locked,
        onContinue: {},
        onQuit: {},
        onDismiss: {}
    )
}
