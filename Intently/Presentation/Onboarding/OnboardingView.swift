//
//  OnboardingView.swift
//  Intently
//
//  Created on 2025-01-01.
//

import SwiftUI
import SwiftData
import FamilyControls
import ManagedSettings

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dependencies) private var dependencies

    @State private var currentStep = 0
    @State private var selectedApps: Set<String> = []
    @State private var appActivitySelection = FamilyActivitySelection()
    @State private var dailyGoalMinutes: Int = 60
    @State private var showingAppPicker = false

    private let totalSteps = 6

    var body: some View {
        VStack(spacing: 0) {
            // Progress
            ProgressView(value: Double(currentStep + 1), total: Double(totalSteps))
                .padding(.top)

            // Content
            Group {
                switch currentStep {
                case 0:
                    WelcomeStep(onNext: nextStep)
                case 1:
                    ValuePropStep(onNext: nextStep)
                case 2:
                    GoalSetupStep(
                        dailyGoalMinutes: $dailyGoalMinutes,
                        onNext: nextStep
                    )
                case 3:
                    AppSelectionStep(
                        appActivitySelection: $appActivitySelection,
                        onNext: nextStep,
                        showPicker: { showingAppPicker = true }
                    )
                case 4:
                    PermissionStep(onNext: nextStep)
                case 5:
                    CompletionStep(onComplete: completeOnboarding)
                default:
                    WelcomeStep(onNext: nextStep)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color.appBackground)
        .fullScreenCover(isPresented: $showingAppPicker) {
            AppPickerFullScreenView(
                appActivitySelection: $appActivitySelection,
                onDismiss: { showingAppPicker = false }
            )
        }
    }

    private func nextStep() {
        if currentStep < totalSteps - 1 {
            withAnimation {
                currentStep += 1
            }
        }
    }

    private func completeOnboarding() {
        Task {
            // Save the FamilyActivitySelection to shared UserDefaults for DeviceActivity extension
            if let sharedDefaults = UserDefaults(suiteName: "group.dev.sadakat.intently") {
                // Save selection count
                let selectionCount = appActivitySelection.applicationTokens.count
                sharedDefaults.set(selectionCount, forKey: "selectedAppsCount")

                // Save selection timestamp
                sharedDefaults.set(Date(), forKey: "selectionDate")
                sharedDefaults.synchronize()
            }

            // Create placeholder goals for each selected application
            // Note: We can't extract bundle IDs from ApplicationToken, but we track the count
            let appCount = appActivitySelection.applicationTokens.count

            for index in 0..<appCount {
                let goal = Goal(
                    targetApp: "selection_\(index)",  // Placeholder ID
                    targetAppName: "Selected App \(index + 1)",  // Placeholder name
                    dailyLimitMinutes: dailyGoalMinutes,
                    startDate: Date(),
                    isEnabled: true,
                    syncStatus: "pending"
                )
                modelContext.insert(goal)
            }

            try? modelContext.save()

            // Mark onboarding as complete
            UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        }
    }
}

// MARK: - Onboarding Steps

struct WelcomeStep: View {
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            Spacer()

            Image(systemName: "brain.head.profile")
                .font(.system(size: 80))
                .foregroundColor(.appPrimary)

            VStack(spacing: AppTheme.Spacing.sm) {
                Text("Welcome to Intently")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Build healthier digital habits and reclaim your time")
                    .font(.body)
                    .foregroundColor(.appTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Spacer()

            PrimaryButton(title: "Get Started", action: onNext)
                .padding(.horizontal)
        }
        .padding()
    }
}

struct ValuePropStep: View {
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            VStack(spacing: AppTheme.Spacing.sm) {
                Text("How it works")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Intently helps you stay mindful of your app usage")
                    .font(.subheadline)
                    .foregroundColor(.appTextSecondary)
            }

            VStack(spacing: AppTheme.Spacing.lg) {
                FeatureRow(
                    icon: "target",
                    title: "Set Goals",
                    description: "Define daily usage limits for your apps"
                )

                FeatureRow(
                    icon: "hand.raised.fill",
                    title: "Get Reminders",
                    description: "Gentle interventions when you exceed limits"
                )

                FeatureRow(
                    icon: "flame.fill",
                    title: "Build Streaks",
                    description: "Track progress and maintain momentum"
                )
            }

            Spacer()

            PrimaryButton(title: "Continue", action: onNext)
                .padding(.horizontal)
        }
        .padding()
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.appPrimary)
                .frame(width: 50)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.appTextSecondary)
            }

            Spacer()
        }
        .padding()
        .background(Color.appSecondaryBackground)
        .cornerRadius(AppTheme.CornerRadius.md)
    }
}

struct GoalSetupStep: View {
    @Binding var dailyGoalMinutes: Int
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            VStack(spacing: AppTheme.Spacing.sm) {
                Text("Set your daily goal")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("How much time per app is reasonable for you?")
                    .font(.subheadline)
                    .foregroundColor(.appTextSecondary)
            }

            VStack(spacing: AppTheme.Spacing.lg) {
                Text("\(dailyGoalMinutes)")
                    .font(.system(size: 60, weight: .bold, design: .rounded))
                    .foregroundColor(.appPrimary)

                Text("minutes per day")
                    .font(.title3)
                    .foregroundColor(.appTextSecondary)

                VStack(spacing: AppTheme.Spacing.sm) {
                    Slider(value: Binding(
                        get: { Double(dailyGoalMinutes) },
                        set: { dailyGoalMinutes = Int($0) }
                    ), in: 15...180, step: 15)

                    HStack {
                        Text("15m")
                            .font(.caption)
                            .foregroundColor(.appTextTertiary)
                        Spacer()
                        Text("3h")
                            .font(.caption)
                            .foregroundColor(.appTextTertiary)
                    }
                }
            }

            Spacer()

            PrimaryButton(title: "Continue", action: onNext)
                .padding(.horizontal)
        }
        .padding()
    }
}

struct AppSelectionStep: View {
    @Binding var appActivitySelection: FamilyActivitySelection
    let onNext: () -> Void
    let showPicker: () -> Void

    @State private var selectionCount = 0

    var body: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            // Header
            VStack(spacing: AppTheme.Spacing.sm) {
                Image(systemName: "app.badge.checkmark")
                    .font(.system(size: 50))
                    .foregroundColor(.appPrimary)

                Text("Which apps to track?")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Select the apps you want to monitor and set limits for")
                    .font(.body)
                    .foregroundColor(.appTextSecondary)
                    .multilineTextAlignment(.center)
            }

            // Selected apps preview
            if selectionCount == 0 {
                emptyStateView
            } else {
                selectedAppsPreview
            }

            Spacer()

            // Action buttons
            VStack(spacing: AppTheme.Spacing.md) {
                Button(action: showPicker) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text(selectionCount > 0 ? "Change Apps" : "Select Apps to Track")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.appPrimary)
                    .foregroundColor(.white)
                    .cornerRadius(AppTheme.CornerRadius.md)
                }

                if selectionCount > 0 {
                    PrimaryButton(
                        title: "Continue (\(selectionCount))",
                        action: onNext
                    )
                } else {
                    Text("Select at least one app to continue")
                        .font(.caption)
                        .foregroundColor(.appRed)
                }
            }
            .padding()
        }
        .padding()
        .task {
            updateSelectionCount()
        }
        .onChange(of: appActivitySelection) { _, _ in
            updateSelectionCount()
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            Image(systemName: "app.dashed")
                .font(.system(size: 60))
                .foregroundColor(.appTextTertiary)

            Text("No apps selected yet")
                .font(.headline)
                .foregroundColor(.appTextSecondary)

            Text("Tap the button above to select apps")
                .font(.caption)
                .foregroundColor(.appTextTertiary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    private var selectedAppsPreview: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                Text("\(selectionCount) app\(selectionCount == 1 ? "" : "s") selected")
                    .font(.subheadline)
                    .foregroundColor(.appTextSecondary)

                // Show selection count with visual indicator
                VStack(spacing: AppTheme.Spacing.xs) {
                    ForEach(0..<min(selectionCount, 5), id: \.self) { _ in
                        HStack(spacing: AppTheme.Spacing.sm) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.appGreen)
                            Text("Selected app")
                                .font(.subheadline)
                                .foregroundColor(.appTextSecondary)
                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 4)
                        .background(Color.appSecondaryBackground)
                        .cornerRadius(8)
                    }

                    if selectionCount > 5 {
                        Text("+ \(selectionCount - 5) more...")
                            .font(.caption)
                            .foregroundColor(.appTextTertiary)
                            .padding(.horizontal)
                    }
                }
            }
        }
    }

    private func updateSelectionCount() {
        selectionCount = appActivitySelection.applicationTokens.count
    }
}

// Full-screen wrapper for FamilyActivityPicker
struct AppPickerFullScreenView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var appActivitySelection: FamilyActivitySelection
    let onDismiss: () -> Void

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: AppTheme.Spacing.sm) {
                    Text("Select Apps to Track")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Choose the apps you want Intently to monitor")
                        .font(.subheadline)
                        .foregroundColor(.appTextSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding()

                Divider()

                // FamilyActivityPicker - takes up available space
                FamilyActivityPicker(
                    selection: $appActivitySelection
                )
            }
            .navigationTitle("Select Apps")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onDismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onDismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

struct PermissionStep: View {
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            VStack(spacing: AppTheme.Spacing.sm) {
                Text("Enable permissions")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Intently needs a few permissions to work properly")
                    .font(.subheadline)
                    .foregroundColor(.appTextSecondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: AppTheme.Spacing.lg) {
                PermissionRow(
                    icon: "chart.bar.fill",
                    title: "Screen Time",
                    description: "To monitor your app usage",
                    isGranted: .constant(true)
                )

                PermissionRow(
                    icon: "bell.fill",
                    title: "Notifications",
                    description: "To send you gentle reminders",
                    isGranted: .constant(false)
                )
            }

            Spacer()

            PrimaryButton(title: "Grant Permissions", action: onNext)
                .padding(.horizontal)
        }
        .padding()
    }
}

struct PermissionRow: View {
    let icon: String
    let title: String
    let description: String
    @Binding var isGranted: Bool

    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.appPrimary)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.appTextSecondary)
            }

            Spacer()

            if isGranted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.appGreen)
                    .font(.title3)
            } else {
                Button("Allow") {
                    isGranted = true
                }
                .font(.caption)
                .foregroundColor(.appPrimary)
            }
        }
        .padding()
        .background(Color.appSecondaryBackground)
        .cornerRadius(AppTheme.CornerRadius.md)
    }
}

struct CompletionStep: View {
    let onComplete: () -> Void

    var body: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.appGreen)

            VStack(spacing: AppTheme.Spacing.sm) {
                Text("You're all set!")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Your journey to mindful tech usage starts now")
                    .font(.body)
                    .foregroundColor(.appTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Spacer()

            PrimaryButton(title: "Start Using Intently", action: onComplete)
                .padding(.horizontal)
        }
        .padding()
    }
}

#Preview {
    OnboardingView()
}
