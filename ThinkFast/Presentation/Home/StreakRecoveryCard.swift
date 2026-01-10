//
//  StreakRecoveryCard.swift
//  ThinkFast
//
//  Created on 2025-01-07.
//  Streak Recovery: UI component for showing streak recovery progress
//

import SwiftUI

/// Streak Recovery Card
///
/// Shows streak recovery progress when a user has broken their streak.
/// Displays contextual messages and progress toward recovery.
struct StreakRecoveryCard: View {

    let recovery: StreakRecovery
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundColor(.orange)
                    .font(.title3)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Streak Recovery")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text("Get back on track!")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Dismiss button
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .imageScale(.large)
                }
            }

            // Previous streak info
            HStack(spacing: 4) {
                Image(systemName: "trophy.fill")
                    .foregroundColor(.yellow)
                    .font(.caption)

                Text("Your \(recovery.previousStreak)-day streak was amazing!")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Progress section
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(recovery.shortMessage)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    Spacer()

                    Text("\(recovery.currentRecoveryDays)/\(recovery.calculatedRecoveryTarget) days")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.orange.opacity(0.2))
                            .frame(height: 8)

                        // Progress fill
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.orange)
                            .frame(width: geometry.size.width * CGFloat(recovery.recoveryProgress), height: 8)
                            .animation(.easeInOut(duration: 0.3), value: recovery.recoveryProgress)
                    }
                }
                .frame(height: 8)

                // Day indicators
                HStack(spacing: 0) {
                    ForEach(1...recovery.calculatedRecoveryTarget, id: \.self) { day in
                        if day > 1 {
                            Spacer()
                        }

                        RecoveryDayIndicator(
                            day: day,
                            currentDay: recovery.currentRecoveryDays,
                            isCompleted: day <= recovery.currentRecoveryDays
                        )

                        if day < recovery.calculatedRecoveryTarget {
                            Spacer()
                        }
                    }
                }
            }

            // Motivational message
            Text(recovery.recoveryMessage)
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 4)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Recovery Day Indicator

/// Recovery Day Indicator Component
///
/// Shows individual day status in the recovery progress.
private struct RecoveryDayIndicator: View {
    let day: Int
    let currentDay: Int
    let isCompleted: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(indicatorColor)
                .frame(width: 20, height: 20)

            if isCompleted {
                Image(systemName: "checkmark")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.white)
            } else if day == currentDay {
                Text("\(day)")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
            } else {
                Text("\(day)")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
    }

    private var indicatorColor: Color {
        if isCompleted {
            return .green
        } else if day == currentDay {
            return .orange
        } else {
            return Color.gray.opacity(0.3)
        }
    }
}

// MARK: - Streak Freeze Button

/// Streak Freeze Button
///
/// Shows available streak freezes and allows using them.
struct StreakFreezeButton: View {
    let freezeStatus: StreakFreezeStatus
    let onUseFreeze: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Text(freezeStatus.freezeIcon)
                .font(.title2)

            VStack(alignment: .leading, spacing: 2) {
                Text("Streak Freeze")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                Text("\(freezeStatus.freezeCountText) available")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if freezeStatus.canUseFreeze && !freezeStatus.isOutOfFreezes {
                Button("Use") {
                    onUseFreeze()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.cyan.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.cyan.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Preview

#Preview("Streak Recovery - Day 1") {
    let recovery = StreakRecovery(
        targetApp: "com.instagram.android",
        targetAppName: "Instagram",
        previousStreak: 14,
        recoveryStartDate: Date(),
        currentRecoveryDays: 1,
        isRecoveryComplete: false,
        requiredRecoveryDays: 7
    )

    return VStack {
        StreakRecoveryCard(
            recovery: recovery,
            onDismiss: {}
        )

        Spacer()
    }
    .padding()
}

#Preview("Streak Recovery - Almost Complete") {
    let recovery = StreakRecovery(
        targetApp: "com.facebook.katana",
        targetAppName: "Facebook",
        previousStreak: 20,
        recoveryStartDate: Date().addingTimeInterval(-6 * 24 * 3600),
        currentRecoveryDays: 6,
        isRecoveryComplete: false,
        requiredRecoveryDays: 7
    )

    return VStack {
        StreakRecoveryCard(
            recovery: recovery,
            onDismiss: {}
        )

        Spacer()
    }
    .padding()
}

#Preview("Streak Freeze") {
    let freezeStatus = StreakFreezeStatus(
        freezesAvailable: 2,
        maxFreezes: 3,
        hasActiveFreeze: false,
        freezeActivationDate: nil,
        canUseFreeze: true
    )

    return VStack {
        StreakFreezeButton(
            freezeStatus: freezeStatus,
            onUseFreeze: {}
        )

        Spacer()
    }
    .padding()
}
