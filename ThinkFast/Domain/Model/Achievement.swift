//
//  Achievement.swift
//  ThinkFast
//
//  Created on 2025-01-01.
//

import Foundation

// MARK: - Achievement Model
struct Achievement: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let category: AchievementCategory
    let requirement: AchievementRequirement
    var isUnlocked: Bool
    var unlockedAt: Date?
    var progress: Double // 0.0 to 1.0
    var tier: AchievementTier

    var formattedProgress: String {
        "\(Int(progress * 100))%"
    }
}

enum AchievementCategory: String, CaseIterable, Codable {
    case streaks = "Streaks"
    case goals = "Goals"
    case timeSaved = "Time Saved"
    case consistency = "Consistency"
    case milestones = "Milestones"
}

enum AchievementTier: Int, Codable {
    case bronze = 1
    case silver = 2
    case gold = 3
    case platinum = 4

    var color: String {
        switch self {
        case .bronze: return "CD7F32" // Bronze
        case .silver: return "C0C0C0" // Silver
        case .gold: return "FFD700"   // Gold
        case .platinum: return "E5E4E2" // Platinum
        }
    }

    var name: String {
        switch self {
        case .bronze: return "Bronze"
        case .silver: return "Silver"
        case .gold: return "Gold"
        case .platinum: return "Platinum"
        }
    }
}

enum AchievementRequirement: Codable {
    case streakDays(streak: Int)
    case daysUnderGoal(days: Int)
    case totalMinutesSaved(minutes: Int)
    case consecutiveDays(days: Int)
    case totalSessions(sessions: Int)

    var description: String {
        switch self {
        case .streakDays(let streak):
            return "Reach a \(streak)-day streak"
        case .daysUnderGoal(let days):
            return "Stay under your goal for \(days) days"
        case .totalMinutesSaved(let minutes):
            return "Save \(minutes) minutes total"
        case .consecutiveDays(let days):
            return "\(days) days in a row under goal"
        case .totalSessions(let sessions):
            return "Complete \(sessions) successful sessions"
        }
    }
}

// MARK: - Achievement Manager
class AchievementManager: ObservableObject {
    @Published var achievements: [Achievement] = []

    private let userDefaults = UserDefaults.standard

    private enum Keys {
        static let achievements = "achievements"
    }

    init() {
        loadAchievements()
    }

    // MARK: - Predefined Achievements
    private func predefinedAchievements() -> [Achievement] {
        return [
            // Streak Achievements
            Achievement(
                id: "streak_3",
                title: "Getting Started",
                description: "Reach a 3-day streak",
                icon: "flame",
                category: .streaks,
                requirement: .streakDays(streak: 3),
                isUnlocked: false,
                progress: 0,
                tier: .bronze
            ),
            Achievement(
                id: "streak_7",
                title: "Week Warrior",
                description: "Reach a 7-day streak",
                icon: "flame.fill",
                category: .streaks,
                requirement: .streakDays(streak: 7),
                isUnlocked: false,
                progress: 0,
                tier: .silver
            ),
            Achievement(
                id: "streak_30",
                title: "Monthly Master",
                description: "Reach a 30-day streak",
                icon: "flame",
                category: .streaks,
                requirement: .streakDays(streak: 30),
                isUnlocked: false,
                progress: 0,
                tier: .gold
            ),

            // Goal Achievements
            Achievement(
                id: "under_goal_7",
                title: "First Week Success",
                description: "Stay under goal for 7 days",
                icon: "target",
                category: .goals,
                requirement: .daysUnderGoal(days: 7),
                isUnlocked: false,
                progress: 0,
                tier: .bronze
            ),
            Achievement(
                id: "under_goal_30",
                title: "Monthly Champion",
                description: "Stay under goal for 30 days",
                icon: "trophy",
                category: .goals,
                requirement: .daysUnderGoal(days: 30),
                isUnlocked: false,
                progress: 0,
                tier: .gold
            ),

            // Consistency
            Achievement(
                id: "consecutive_3",
                title: "Building Momentum",
                description: "3 consecutive days under goal",
                icon: "calendar",
                category: .consistency,
                requirement: .consecutiveDays(days: 3),
                isUnlocked: false,
                progress: 0,
                tier: .bronze
            ),
            Achievement(
                id: "consecutive_14",
                title: "Two Week Streak",
                description: "14 consecutive days under goal",
                icon: "calendar.badge.checkmark",
                category: .consistency,
                requirement: .consecutiveDays(days: 14),
                isUnlocked: false,
                progress: 0,
                tier: .silver
            ),

            // Milestones
            Achievement(
                id: "first_goal_set",
                title: "Goal Setter",
                description: "Set your first goal",
                icon: "flag.fill",
                category: .milestones,
                requirement: .streakDays(streak: 1),
                isUnlocked: false,
                progress: 0,
                tier: .bronze
            ),
            Achievement(
                id: "first_streak_recovery",
                title: "Comeback Kid",
                description: "Recover your first broken streak",
                icon: "arrow.uturn",
                category: .milestones,
                requirement: .streakDays(streak: 1),
                isUnlocked: false,
                progress: 0,
                tier: .bronze
            )
        ]
    }

    // MARK: - Load/Save
    func loadAchievements() {
        if let data = userDefaults.object(forKey: Keys.achievements) as? Data,
           let decoded = try? JSONDecoder().decode([Achievement].self, from: data) {
            achievements = decoded
        } else {
            achievements = predefinedAchievements()
        }
    }

    func saveAchievements() {
        if let encoded = try? JSONEncoder().encode(achievements) {
            userDefaults.set(encoded, forKey: Keys.achievements)
        }
    }

    // MARK: - Check Progress
    func updateProgress(
        currentStreak: Int,
        daysUnderGoal: Int,
        consecutiveDays: Int,
        totalSessions: Int
    ) {
        for index in achievements.indices {
            switch achievements[index].requirement {
            case .streakDays(let required):
                achievements[index].progress = min(Double(currentStreak) / Double(required), 1.0)
                if currentStreak >= required && !achievements[index].isUnlocked {
                    unlockAchievement(at: index)
                }
            case .daysUnderGoal(let required):
                achievements[index].progress = min(Double(daysUnderGoal) / Double(required), 1.0)
                if daysUnderGoal >= required && !achievements[index].isUnlocked {
                    unlockAchievement(at: index)
                }
            case .consecutiveDays(let required):
                achievements[index].progress = min(Double(consecutiveDays) / Double(required), 1.0)
                if consecutiveDays >= required && !achievements[index].isUnlocked {
                    unlockAchievement(at: index)
                }
            case .totalSessions(let required):
                achievements[index].progress = min(Double(totalSessions) / Double(required), 1.0)
                if totalSessions >= required && !achievements[index].isUnlocked {
                    unlockAchievement(at: index)
                }
            case .totalMinutesSaved:
                break
            }
        }
    }

    private func unlockAchievement(at index: Int) {
        achievements[index].isUnlocked = true
        achievements[index].unlockedAt = Date()
        saveAchievements()

        // Trigger haptic feedback
        HapticFeedback.streakAchieved()
    }

    // MARK: - Get Unlocked
    func getUnlockedAchievements() -> [Achievement] {
        return achievements.filter { $0.isUnlocked }
    }

    func getUnlockedCount() -> Int {
        achievements.filter { $0.isUnlocked }.count
    }
}
