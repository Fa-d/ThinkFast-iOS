//
//  QuickWinCelebrations.swift
//  ThinkFast
//
//  Created on 2025-01-07.
//  First-Week Retention: Quick win celebration dialogs
//

import SwiftUI

/// Quick Win Celebration View
///
/// Shows celebratory dialogs for early achievements:
/// - First Session Tracked
/// - First Under Goal
/// - Day 1 Complete
/// - Day 2 Complete
struct QuickWinCelebration: View {

    // MARK: - Properties
    let quickWin: QuickWinType
    let onDismiss: () -> Void

    @State private var showConfetti = false
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0

    // MARK: - Body
    var body: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    dismiss()
                }

            // Celebration card
            VStack(spacing: 20) {
                // Emoji with animation
                Text(quickWin.emoji)
                    .font(.system(size: 80))
                    .scaleEffect(showConfetti ? 1.2 : 1.0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.5), value: showConfetti)

                // Title
                Text(quickWin.title)
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)

                // Message
                Text(quickWin.message)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)

                // Continue button
                Button(action: dismiss) {
                    Text("Continue")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
            )
            .padding(.horizontal, 32)
            .scaleEffect(scale)
            .opacity(opacity)
        }
        .onAppear {
            // Trigger entrance animation
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                scale = 1.0
                opacity = 1.0
            }

            // Trigger emoji bounce
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation {
                    showConfetti = true
                }
            }

            // Haptic feedback
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)

            // Auto-dismiss after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                dismiss()
            }
        }
    }

    // MARK: - Actions
    private func dismiss() {
        withAnimation(.easeOut(duration: 0.2)) {
            scale = 0.8
            opacity = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            onDismiss()
        }
    }
}

// MARK: - Manager View

/// Quick Win Manager View
///
/// Shows a quick win celebration when one is available.
/// Automatically checks for and displays celebrations.
struct QuickWinManager: View {

    @StateObject private var viewModel: QuickWinViewModel

    init(viewModel: QuickWinViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        Group {
            if let quickWin = viewModel.currentQuickWin {
                QuickWinCelebration(
                    quickWin: quickWin,
                    onDismiss: {
                        viewModel.dismissCelebration()
                    }
                )
                .transition(.opacity)
            }
        }
        .animation(.easeInOut, value: viewModel.currentQuickWin != nil)
    }
}

// MARK: - View Model

/// Quick Win View Model
///
/// Manages quick win celebration state and checking.
@MainActor
final class QuickWinViewModel: ObservableObject {

    @Published var currentQuickWin: QuickWinType?

    private let questManager: OnboardingQuestManager

    init(questManager: OnboardingQuestManager) {
        self.questManager = questManager
    }

    /// Check for quick wins to celebrate
    func checkQuickWins() async {
        if let quickWin = await questManager.checkQuickWinMilestones() {
            currentQuickWin = quickWin
        }
    }

    /// Dismiss current celebration
    func dismissCelebration() {
        currentQuickWin = nil
    }
}

// MARK: - Day Completion Celebration

/// Day Completion Celebration
///
/// Special celebration for completing Day 1 or Day 2.
struct DayCompletionCelebration: View {

    let day: Int
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    onDismiss()
                }

            VStack(spacing: 20) {
                // Trophy emoji
                Text("🏆")
                    .font(.system(size: 80))

                Text("Day \(day) Complete!")
                    .font(.title)
                    .fontWeight(.bold)

                Text(day == 1
                     ? "You crushed Day 1! Keep this momentum going!"
                     : "Two days down! You're building a great habit.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)

                Button(action: onDismiss) {
                    Text("Continue")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
            )
            .padding(.horizontal, 32)
        }
        .onAppear {
            // Haptic feedback
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)

            // Auto-dismiss after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                onDismiss()
            }
        }
    }
}

// MARK: - Preview

#Preview("First Session") {
    QuickWinCelebration(
        quickWin: .firstSession,
        onDismiss: {}
    )
}

#Preview("First Under Goal") {
    QuickWinCelebration(
        quickWin: .firstUnderGoal,
        onDismiss: {}
    )
}

#Preview("Day 1 Complete") {
    DayCompletionCelebration(
        day: 1,
        onDismiss: {}
    )
}

#Preview("Day 2 Complete") {
    DayCompletionCelebration(
        day: 2,
        onDismiss: {}
    )
}
