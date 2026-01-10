//
//  OnboardingModels.swift
//  Intently
//
//  Created on 2025-01-07.
//  First-Week Retention: Domain Models for Quest, Quick Wins, and Baseline
//

import Foundation

// MARK: - Onboarding Quest Model

/// Onboarding Quest Model
/// Represents the 7-day onboarding quest progress
///
/// Shown to users in their first week to drive engagement and retention
/// Tracks progress from Day 1 to Day 7 with rewards and milestones
struct OnboardingQuest: Codable, Equatable {
    /// Whether the quest is currently active
    var isActive: Bool = false

    /// Current quest day (1-7), or 0 if not active
    var currentDay: Int = 0

    /// Total quest days (always 7)
    var totalDays: Int = 7

    /// Number of completed days
    var daysCompleted: Int = 0

    /// Progress percentage (0.0 to 1.0)
    var progressPercentage: Double {
        guard totalDays > 0 else { return 0 }
        return Double(daysCompleted) / Double(totalDays)
    }

    /// Whether the entire quest is completed
    var isCompleted: Bool = false

    /// Next milestone message (e.g., "Complete today to unlock Day 3 reward!")
    var nextMilestone: String? = nil

    /// Create a quest with default values
    static func create(
        isActive: Bool = false,
        currentDay: Int = 0,
        totalDays: Int = 7,
        daysCompleted: Int = 0,
        isCompleted: Bool = false,
        nextMilestone: String? = nil
    ) -> OnboardingQuest {
        return OnboardingQuest(
            isActive: isActive,
            currentDay: currentDay,
            totalDays: totalDays,
            daysCompleted: daysCompleted,
            isCompleted: isCompleted,
            nextMilestone: nextMilestone
        )
    }
}

// MARK: - Quick Win Type

/// Quick Win Celebration Types
/// Defines the types of quick win celebrations shown in the first 3 days
///
/// These celebrations provide immediate positive reinforcement to new users
/// helping them feel accomplished and engaged early on.
enum QuickWinType: String, Codable {
    /// Day 1: First session tracked ever
    case firstSession = "FIRST_SESSION"

    /// Day 1: First session completed under daily goal
    case firstUnderGoal = "FIRST_UNDER_GOAL"

    /// Day 1 → 2: Successfully completed Day 1
    case dayOneComplete = "DAY_ONE_COMPLETE"

    /// Day 2 → 3: Successfully completed Day 2
    case dayTwoComplete = "DAY_TWO_COMPLETE"

    /// Display title for the quick win
    var title: String {
        switch self {
        case .firstSession:
            return "First Session Tracked!"
        case .firstUnderGoal:
            return "Under Goal!"
        case .dayOneComplete:
            return "Day 1 Complete!"
        case .dayTwoComplete:
            return "Day 2 Complete!"
        }
    }

    /// Message shown to user
    var message: String {
        switch self {
        case .firstSession:
            return "Great start! You've taken your first step towards mindful usage."
        case .firstUnderGoal:
            return "Amazing! You're already staying within your goal."
        case .dayOneComplete:
            return "You crushed Day 1! Keep this momentum going!"
        case .dayTwoComplete:
            return "Two days down! You're building a great habit."
        }
    }

    /// Emoji for celebration
    var emoji: String {
        switch self {
        case .firstSession: return "🎯"
        case .firstUnderGoal: return "⭐"
        case .dayOneComplete: return "🏆"
        case .dayTwoComplete: return "🚀"
        }
    }
}

// MARK: - Baseline Comparison Info

/// Baseline Comparison Info
/// Lightweight struct for baseline comparison UI display
///
/// Used for displaying baseline comparisons in the UI.
/// Works with the existing SwiftData UserBaseline model for persistence.
struct BaselineComparisonInfo: Codable, Equatable {
    /// First week start date ("yyyy-MM-dd")
    var firstWeekStartDate: String

    /// First week end date ("yyyy-MM-dd")
    var firstWeekEndDate: String

    /// Average daily minutes across first week
    var averageDailyMinutes: Int

    /// Facebook average daily minutes
    var facebookAverageMinutes: Int

    /// Instagram average daily minutes
    var instagramAverageMinutes: Int

    /// Population average benchmark (hardcoded)
    static let populationAverageMinutes = 45

    /// Calculate difference from population average
    /// - Returns: Positive if better than average (lower usage), negative if worse
    func comparisonToPopulation() -> Int {
        return Self.populationAverageMinutes - averageDailyMinutes
    }

    /// Get motivational message based on performance vs population
    /// - Returns: Encouraging message with comparison
    func comparisonMessage() -> String {
        let diff = comparisonToPopulation()
        if diff > 0 {
            return "You're saving \(diff) min/day vs average user!"
        } else if diff < 0 {
            return "You're \(abs(diff)) min above average. Let's improve!"
        } else {
            return "You're right at the average. Room to grow!"
        }
    }

    /// Get trend direction compared to baseline
    /// - Parameter currentMinutes: Current usage in minutes
    /// - Returns: Trend message
    func trendMessage(currentMinutes: Int) -> String {
        let diff = averageDailyMinutes - currentMinutes
        if diff > 0 {
            return "\(diff) min below baseline"
        } else if diff < 0 {
            return "\(abs(diff)) min above baseline"
        } else {
            return "At baseline"
        }
    }

    /// Create baseline info with values
    static func create(
        firstWeekStartDate: String,
        firstWeekEndDate: String,
        averageDailyMinutes: Int,
        facebookAverageMinutes: Int = 0,
        instagramAverageMinutes: Int = 0
    ) -> BaselineComparisonInfo {
        return BaselineComparisonInfo(
            firstWeekStartDate: firstWeekStartDate,
            firstWeekEndDate: firstWeekEndDate,
            averageDailyMinutes: averageDailyMinutes,
            facebookAverageMinutes: facebookAverageMinutes,
            instagramAverageMinutes: instagramAverageMinutes
        )
    }

    /// Create from SwiftData UserBaseline model
    static func from(userBaseline: UserBaseline) -> BaselineComparisonInfo? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        return BaselineComparisonInfo(
            firstWeekStartDate: dateFormatter.string(from: userBaseline.firstWeekStartDate),
            firstWeekEndDate: dateFormatter.string(from: userBaseline.calculationDate ?? userBaseline.firstWeekStartDate),
            averageDailyMinutes: Int(userBaseline.averageDailyMinutes),
            facebookAverageMinutes: Int(userBaseline.facebookAverageMinutes),
            instagramAverageMinutes: Int(userBaseline.instagramAverageMinutes)
        )
    }
}

// MARK: - Quest Day Milestone

/// Quest Day Milestone
/// Represents completion status for each day (1-7)
struct QuestDayMilestone: Codable, Equatable {
    /// Day number (1-7)
    var day: Int

    /// Whether this day was completed
    var isCompleted: Bool

    /// Whether the celebration was shown
    var celebrationShown: Bool

    /// Timestamp when completed
    var completedAt: Date?

    /// Create a milestone
    static func create(
        day: Int,
        isCompleted: Bool = false,
        celebrationShown: Bool = false,
        completedAt: Date? = nil
    ) -> QuestDayMilestone {
        return QuestDayMilestone(
            day: day,
            isCompleted: isCompleted,
            celebrationShown: celebrationShown,
            completedAt: completedAt
        )
    }
}
