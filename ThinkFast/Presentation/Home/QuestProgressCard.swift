//
//  QuestProgressCard.swift
//  ThinkFast
//
//  Created on 2025-01-07.
//  First-Week Retention: 7-day quest progress card UI
//

import SwiftUI

/// Quest Progress Card
///
/// Displays the 7-day onboarding quest progress on the home screen.
/// Shows current day, progress bar, and next milestone.
struct QuestProgressCard: View {

    // MARK: - Properties
    let quest: OnboardingQuest
    let onDismiss: () -> Void

    // MARK: - Body
    var body: some View {
        if quest.isActive && !quest.isCompleted {
            VStack(alignment: .leading, spacing: 12) {
                // Header with dismiss button
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("7-Day Quest")
                            .font(.headline)
                            .foregroundColor(.primary)

                        Text("Build your mindful usage habit")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Button(action: onDismiss) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                            .imageScale(.large)
                    }
                }

                // Day indicator
                HStack(spacing: 8) {
                    Text("Day")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text("\(quest.currentDay)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.accentColor)

                    Text("of \(quest.totalDays)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.accentColor.opacity(0.2))
                            .frame(height: 12)

                        // Progress fill
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.accentColor)
                            .frame(width: geometry.size.width * CGFloat(quest.progressPercentage), height: 12)
                            .animation(.easeInOut(duration: 0.3), value: quest.progressPercentage)
                    }
                }
                .frame(height: 12)

                // Day indicators
                HStack(spacing: 0) {
                    ForEach(1...quest.totalDays, id: \.self) { day in
                        if day > 1 {
                            Spacer()
                        }

                        DayIndicator(
                            day: day,
                            currentDay: quest.currentDay,
                            isCompleted: day <= quest.daysCompleted
                        )

                        if day < quest.totalDays {
                            Spacer()
                        }
                    }
                }

                // Next milestone
                if let milestone = quest.nextMilestone {
                    HStack(spacing: 6) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)

                        Text(milestone)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.accentColor.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

// MARK: - Day Indicator

/// Day Indicator Component
///
/// Shows individual day status in the quest progress.
private struct DayIndicator: View {
    let day: Int
    let currentDay: Int
    let isCompleted: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(indicatorColor)
                .frame(width: 24, height: 24)

            if isCompleted {
                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
            } else if day == currentDay {
                Text("\(day)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
            } else {
                Text("\(day)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
    }

    private var indicatorColor: Color {
        if isCompleted {
            return .green
        } else if day == currentDay {
            return .accentColor
        } else {
            return Color.gray.opacity(0.3)
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        // Day 1
        QuestProgressCard(
            quest: OnboardingQuest(
                isActive: true,
                currentDay: 1,
                totalDays: 7,
                daysCompleted: 0,
                isCompleted: false,
                nextMilestone: "Complete today to unlock Day 2 reward!"
            ),
            onDismiss: {}
        )

        // Day 4
        QuestProgressCard(
            quest: OnboardingQuest(
                isActive: true,
                currentDay: 4,
                totalDays: 7,
                daysCompleted: 3,
                isCompleted: false,
                nextMilestone: "Complete today to unlock Day 5 reward!"
            ),
            onDismiss: {}
        )

        Spacer()
    }
    .padding()
}
