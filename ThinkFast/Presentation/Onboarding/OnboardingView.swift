//
//  OnboardingView.swift
//  ThinkFast
//
//  Created on 2025-01-01.
//

import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dependencies) private var dependencies

    @State private var currentStep = 0
    @State private var selectedApps: Set<String> = []
    @State private var dailyGoalMinutes: Int = 60

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
                        selectedApps: $selectedApps,
                        onNext: nextStep
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
            // Save goals for selected apps
            let bundleMapping: [String: String] = [
                "Facebook": "com.facebook.Facebook",
                "Instagram": "com.burbn.instagram",
                "TikTok": "com.zhiliaoapp.musically",
                "X (Twitter)": "com.atebits.Tweetie2",
                "YouTube": "com.google.YouTube",
                "Snapchat": "com.toyopagroup.picaboo"
            ]

            for appName in selectedApps {
                if let bundleId = bundleMapping[appName] {
                    let goal = Goal(
                        targetApp: bundleId,
                        targetAppName: appName,
                        dailyLimitMinutes: dailyGoalMinutes,
                        startDate: Date(),
                        isEnabled: true,
                        syncStatus: "pending"
                    )
                    modelContext.insert(goal)
                }
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
                Text("Welcome to ThinkFast")
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

                Text("ThinkFast helps you stay mindful of your app usage")
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
    @Binding var selectedApps: Set<String>
    let onNext: () -> Void

    private let availableApps = [
        ("Facebook", "facebook", true),
        ("Instagram", "instagram", true),
        ("TikTok", "tiktok", true),
        ("X (Twitter)", "twitter", true),
        ("YouTube", "youtube", true),
        ("Snapchat", "snapchat", false)
    ]

    var body: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            VStack(spacing: AppTheme.Spacing.sm) {
                Text("Which apps to track?")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Select the apps you want to monitor")
                    .font(.subheadline)
                    .foregroundColor(.appTextSecondary)
            }

            ScrollView {
                VStack(spacing: AppTheme.Spacing.sm) {
                    ForEach(availableApps, id: \.0) { app in
                        AppSelectionRow(
                            name: app.0,
                            icon: app.1,
                            isRecommended: app.2,
                            isSelected: selectedApps.contains(app.0),
                            onTap: {
                                if selectedApps.contains(app.0) {
                                    selectedApps.remove(app.0)
                                } else {
                                    selectedApps.insert(app.0)
                                }
                            }
                        )
                    }
                }
            }

            PrimaryButton(
                title: "Continue (\(selectedApps.count))",
                action: onNext,
                isDisabled: selectedApps.isEmpty
            )
            .padding(.horizontal)
        }
        .padding()
    }
}

struct AppSelectionRow: View {
    let name: String
    let icon: String
    let isRecommended: Bool
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AppTheme.Spacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 45, height: 45)

                    Text(String(name.prefix(1)))
                        .font(.title2)
                        .fontWeight(.semibold)
                }

                VStack(alignment: .leading) {
                    HStack(spacing: 4) {
                        Text(name)
                            .font(.subheadline)
                            .fontWeight(.medium)

                        if isRecommended {
                            Text("Recommended")
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.appSecondary.opacity(0.3))
                                .foregroundColor(.appPrimary)
                                .cornerRadius(4)
                        }
                    }
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .appPrimary : .appTextTertiary)
                    .font(.title3)
            }
            .padding()
            .background(isSelected ? Color.appPrimary.opacity(0.1) : Color.appSecondaryBackground)
            .cornerRadius(AppTheme.CornerRadius.md)
        }
        .buttonStyle(PlainButtonStyle())
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

                Text("ThinkFast needs a few permissions to work properly")
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

            PrimaryButton(title: "Start Using ThinkFast", action: onComplete)
                .padding(.horizontal)
        }
        .padding()
    }
}

#Preview {
    OnboardingView()
}
