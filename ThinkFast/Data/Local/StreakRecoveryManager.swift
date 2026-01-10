//
//  StreakRecoveryManager.swift
//  ThinkFast
//
//  Created on 2025-01-07.
//  Streak Recovery: Manages streak recovery logic
//

import Foundation
import SwiftUI

/// Streak Recovery Manager
///
/// Manages streak recovery when users miss their daily goal.
/// Provides dynamic recovery targets based on previous streak length.
final class StreakRecoveryManager: ObservableObject {

    // MARK: - Published Properties
    @Published var activeRecoveries: [StreakRecovery] = []

    // MARK: - Dependencies
    private let goalRepository: GoalRepository
    private let streakRecoveryRepository: StreakRecoveryRepository
    private let usageRepository: UsageRepository

    // MARK: - Initialization
    init(
        goalRepository: GoalRepository,
        streakRecoveryRepository: StreakRecoveryRepository,
        usageRepository: UsageRepository
    ) {
        self.goalRepository = goalRepository
        self.streakRecoveryRepository = streakRecoveryRepository
        self.usageRepository = usageRepository
    }

    // MARK: - Public Methods

    /// Check all goals and create recovery records for broken streaks
    func checkAndUpdateStreaks() async {
        let goals = (try? await goalRepository.getAllGoals()) ?? []

        for goal in goals {
            await checkAndUpdateStreak(for: goal)
        }

        // Load active recoveries
        await loadActiveRecoveries()
    }

    /// Check and update streak for a specific goal
    func checkAndUpdateStreak(for goal: Goal) async {
        // Check if streak was broken (goal not met today)
        let today = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today) ?? today

        // Get yesterday's usage
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let yesterdayStr = dateFormatter.string(from: yesterday)
        let sessions = (try? await usageRepository.getSessionsInRange(
            startDate: yesterdayStr,
            endDate: yesterdayStr
        )) ?? []

        let yesterdayMs = sessions.reduce(TimeInterval(0)) { total, session in
            return total + session.duration
        }
        let yesterdayMinutes = Int(yesterdayMs / 60)

        // Check if streak was broken yesterday
        let streakBroken = yesterdayMinutes > goal.dailyLimitMinutes

        if streakBroken && goal.currentStreak > 0 && goal.lastBrokenDate == nil {
            // Streak was broken! Create recovery record
            await createRecovery(for: goal)
        }
    }

    /// Create a recovery record for a goal
    func createRecovery(for goal: Goal) async {
        // Check if recovery already exists
        if let existing = try? await streakRecoveryRepository.getRecovery(for: goal.targetApp) {
            // Recovery already in progress, don't create new one
            logDebug("Recovery already exists for \(goal.targetApp)")
            return
        }

        // Calculate recovery target (50% of streak or 7 days, whichever is lower)
        let halfStreak = max(goal.currentStreak / 2, 1)
        let requiredDays = min(halfStreak, 7)

        let recovery = StreakRecovery(
            targetApp: goal.targetApp,
            targetAppName: goal.targetAppName,
            previousStreak: goal.currentStreak,
            recoveryStartDate: Date(),
            currentRecoveryDays: 0,
            isRecoveryComplete: false,
            requiredRecoveryDays: requiredDays
        )

        try? await streakRecoveryRepository.saveRecovery(recovery)
        logInfo("Created recovery for \(goal.targetApp): \(goal.currentStreak)-day streak")
    }

    /// Update recovery progress for a goal
    func updateRecoveryProgress(for app: String) async {
        guard let recovery = try? await streakRecoveryRepository.getRecovery(for: app) else {
            return
        }

        // Check if goal was met today
        let today = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let todayStr = dateFormatter.string(from: today)

        let sessions = (try? await usageRepository.getSessionsInRange(
            startDate: todayStr,
            endDate: todayStr
        )) ?? []

        let todayMs = sessions.reduce(TimeInterval(0)) { total, session in
            return total + session.duration
        }
        let todayMinutes = Int(todayMs / 60)

        // Get goal to check if under limit
        guard let goal = try? await goalRepository.getGoal(for: app) else {
            return
        }

        let goalMetToday = todayMinutes <= goal.dailyLimitMinutes

        if goalMetToday {
            // Increment recovery days
            recovery.currentRecoveryDays += 1

            // Check if recovery is complete
            let target = recovery.calculatedRecoveryTarget
            if recovery.currentRecoveryDays >= target {
                recovery.isRecoveryComplete = true
                recovery.recoveryCompletionDate = Date()

                // Restore the streak
                goal.currentStreak = recovery.previousStreak
                goal.lastBrokenDate = nil
                try? await goalRepository.updateGoal(goal)

                logInfo("Recovery complete for \(app): \(recovery.previousStreak)-day streak restored")
            }

            try? await streakRecoveryRepository.updateRecovery(recovery)
        }

        await loadActiveRecoveries()
    }

    /// Get streak freeze status for a user
    func getStreakFreezeStatus() async -> StreakFreezeStatus {
        // TODO: Implement streak freeze preferences storage
        // For now, return default status
        return StreakFreezeStatus(
            freezesAvailable: 1,
            maxFreezes: 3,
            hasActiveFreeze: false,
            freezeActivationDate: nil,
            canUseFreeze: true
        )
    }

    /// Use a streak freeze to protect current streak
    func useStreakFreeze(for app: String) async -> Bool {
        let status = await getStreakFreezeStatus()

        guard status.canUseFreeze && !status.isOutOfFreezes else {
            logDebug("No streak freezes available")
            return false
        }

        // TODO: Implement freeze logic
        logInfo("Streak freeze used for \(app)")
        return true
    }

    /// Load all active recoveries
    func loadActiveRecoveries() async {
        let allRecoveries = (try? await streakRecoveryRepository.getAllRecoveries()) ?? []
        activeRecoveries = allRecoveries.filter { !$0.isRecoveryComplete }
    }

    /// Get recovery for a specific app
    func getRecovery(for app: String) async -> StreakRecovery? {
        return try? await streakRecoveryRepository.getRecovery(for: app)
    }

    // MARK: - Logging

    private func logDebug(_ message: String) {
        #if DEBUG
        print("[StreakRecoveryManager] DEBUG: \(message)")
        #endif
    }

    private func logInfo(_ message: String) {
        print("[StreakRecoveryManager] INFO: \(message)")
    }
}
