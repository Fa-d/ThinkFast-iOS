//
//  OnboardingQuestManager.swift
//  Intently
//
//  Created on 2025-01-07.
//  First-Week Retention: Manages 7-day onboarding quest state
//

import Foundation
import SwiftUI

/// Onboarding Quest Manager
///
/// Manages the 7-day onboarding quest that drives first-week retention.
/// Tracks quest progress, milestone completion, and celebration states.
final class OnboardingQuestManager: ObservableObject {

    // MARK: - Published Properties
    @Published var currentQuest: OnboardingQuest = OnboardingQuest()
    @Published var showQuestCard: Bool = true

    // MARK: - Dependencies
    private let goalRepository: GoalRepository
    private let usageRepository: UsageRepository
    private let userDefaults: UserDefaults

    // MARK: - UserDefaults Keys
    private enum Keys {
        static let questStarted = "quest_started"
        static let questStartDate = "quest_start_date"
        static let questCompleted = "quest_completed"
        static let questCompletionDate = "quest_completion_date"
        static let questCardDismissed = "quest_card_dismissed"

        static func dayMilestoneKey(day: Int) -> String {
            return "day_\(day)_milestone_shown"
        }

        static let firstSessionCelebrated = "first_session_celebrated"
        static let firstUnderGoalCelebrated = "first_under_goal_celebrated"
    }

    // MARK: - Initialization
    init(
        goalRepository: GoalRepository,
        usageRepository: UsageRepository,
        userDefaults: UserDefaults = .standard
    ) {
        self.goalRepository = goalRepository
        self.usageRepository = usageRepository
        self.userDefaults = userDefaults
    }

    // MARK: - Public Methods

    /// Load current quest status and update published property
    func loadQuestStatus() async {
        // Auto-start quest if goals exist but quest not started
        let goals = (try? await goalRepository.getAllGoals()) ?? []

        if !goals.isEmpty,
           !isQuestActive(),
           !isQuestCompleted() {
            // Find earliest goal start date
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"

            let sortedGoals = goals.sorted(by: { $0.startDate < $1.startDate })

            if let earliestGoal = sortedGoals.first {
                let startDate = dateFormatter.string(from: earliestGoal.startDate)
                startQuest(startDate: startDate)
            }
        }

        let currentDay = getCurrentQuestDay()
        let daysCompleted = max(currentDay - 1, 0)

        // Check if card was dismissed
        let dismissed = userDefaults.bool(forKey: Keys.questCardDismissed)
        showQuestCard = !dismissed && isQuestActive()

        await MainActor.run {
            currentQuest = OnboardingQuest(
                isActive: isQuestActive(),
                currentDay: currentDay,
                totalDays: 7,
                daysCompleted: daysCompleted,
                isCompleted: isQuestCompleted(),
                nextMilestone: currentDay > 0 && currentDay < 7
                    ? "Complete today to unlock Day \(currentDay + 1) reward!"
                    : nil
            )
        }

        logDebug("Quest status loaded: Day \(currentDay)/7, Active: \(currentQuest.isActive)")
    }

    /// Start the 7-day quest
    func startQuest(startDate: String) {
        userDefaults.set(true, forKey: Keys.questStarted)
        userDefaults.set(startDate, forKey: Keys.questStartDate)
        logInfo("Quest started on \(startDate)")
    }

    /// Check if quest is currently active
    func isQuestActive() -> Bool {
        let started = userDefaults.bool(forKey: Keys.questStarted)
        let completed = userDefaults.bool(forKey: Keys.questCompleted)

        guard started, !completed else {
            return false
        }

        // Check if quest expired (more than 7 days since start)
        guard let startDateString = userDefaults.string(forKey: Keys.questStartDate) else {
            return false
        }

        let currentDay = getCurrentQuestDay()
        return (1...7).contains(currentDay)
    }

    /// Get current quest day (1-7), or 0 if not active
    func getCurrentQuestDay() -> Int {
        guard userDefaults.bool(forKey: Keys.questStarted),
              let startDateString = userDefaults.string(forKey: Keys.questStartDate) else {
            return 0
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        guard let startDate = dateFormatter.date(from: startDateString) else {
            return 0
        }

        let calendar = Calendar.current
        let today = Date()

        // Calculate days between start and today
        let startDay = calendar.startOfDay(for: startDate)
        let todayDay = calendar.startOfDay(for: today)

        let components = calendar.dateComponents([.day], from: startDay, to: todayDay)
        let daysDiff = components.day ?? 0
        let currentDay = daysDiff + 1

        // Return 0 if beyond 7 days
        return (1...7).contains(currentDay) ? currentDay : 0
    }

    /// Mark a quest day as completed
    func markDayCompleted(day: Int) {
        guard (1...7).contains(day) else { return }

        userDefaults.set(true, forKey: Keys.dayMilestoneKey(day: day))
        logInfo("Day \(day) marked as completed")

        // Check if all 7 days completed
        if day == 7 {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            markQuestComplete(date: dateFormatter.string(from: Date()))
        }
    }

    /// Check if day milestone has been shown
    func isDayMilestoneShown(day: Int) -> Bool {
        guard (1...7).contains(day) else { return false }
        return userDefaults.bool(forKey: Keys.dayMilestoneKey(day: day))
    }

    /// Mark the entire quest as complete
    func markQuestComplete(date: String) {
        userDefaults.set(true, forKey: Keys.questCompleted)
        userDefaults.set(date, forKey: Keys.questCompletionDate)
        logInfo("Quest completed on \(date)")
    }

    /// Check if quest has been completed
    func isQuestCompleted() -> Bool {
        return userDefaults.bool(forKey: Keys.questCompleted)
    }

    /// Dismiss the quest card from home screen
    func dismissQuestCard() {
        userDefaults.set(true, forKey: Keys.questCardDismissed)
        showQuestCard = false
        logDebug("Quest card dismissed")
    }

    // MARK: - Quick Win Celebrations

    /// Check if first session celebration was shown
    func isFirstSessionCelebrated() -> Bool {
        return userDefaults.bool(forKey: Keys.firstSessionCelebrated)
    }

    /// Mark first session celebration as shown
    func markFirstSessionCelebrated() {
        userDefaults.set(true, forKey: Keys.firstSessionCelebrated)
        logInfo("First session celebrated")
    }

    /// Check if first under goal celebration was shown
    func isFirstUnderGoalCelebrated() -> Bool {
        return userDefaults.bool(forKey: Keys.firstUnderGoalCelebrated)
    }

    /// Mark first under goal celebration as shown
    func markFirstUnderGoalCelebrated() {
        userDefaults.set(true, forKey: Keys.firstUnderGoalCelebrated)
        logInfo("First under goal celebrated")
    }

    /// Check for quick win milestones to celebrate
    func checkQuickWinMilestones() async -> QuickWinType? {
        // 1. First session ever
        if !isFirstSessionCelebrated() {
            let todayUsage = await getTodayTotalUsage()
            if todayUsage > 0 {
                markFirstSessionCelebrated()
                return .firstSession
            }
        }

        // 2. First session under goal
        if !isFirstUnderGoalCelebrated() {
            let todayUsage = await getTodayTotalUsage()
            let goals = (try? await goalRepository.getAllGoals()) ?? []
            let combinedGoal = goals.reduce(0) { result, goal in
                return result + goal.dailyLimitMinutes
            }

            if todayUsage > 0 && (todayUsage / 1000 / 60) < combinedGoal {
                markFirstUnderGoalCelebrated()
                return .firstUnderGoal
            }
        }

        // Day 1 & 2 complete checks happen after midnight via background check

        return nil
    }

    // MARK: - Private Methods

    /// Get total usage for today in milliseconds
    private func getTodayTotalUsage() async -> Int64 {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let today = dateFormatter.string(from: Date())

        let sessions = (try? await usageRepository.getSessionsInRange(
            startDate: today,
            endDate: today
        )) ?? []

        return sessions.reduce(Int64(0)) { total, session in
            let duration = (session.endTimestamp ?? session.startTimestamp)
                .timeIntervalSince(session.startTimestamp)
            return total + Int64(duration * 1000)
        }
    }

    // MARK: - Logging

    private func logDebug(_ message: String) {
        #if DEBUG
        print("[OnboardingQuestManager] DEBUG: \(message)")
        #endif
    }

    private func logInfo(_ message: String) {
        print("[OnboardingQuestManager] INFO: \(message)")
    }
}
