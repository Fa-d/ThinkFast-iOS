//
//  HomeViewModel.swift
//  Intently
//
//  Created on 2025-01-01.
//

import Foundation
import SwiftUI
import SwiftData

@Observable
final class HomeViewModel {
    // MARK: - Published Properties
    var isLoading = false
    var todayStats: DailyStats?
    var activeGoals: [Goal] = []
    var recentSessions: [UsageSession] = []

    // MARK: - Computed Properties
    var todayTotalMinutes: Int {
        todayStats?.totalMinutes ?? 0
    }

    var formattedTodayUsage: String {
        let hours = todayTotalMinutes / 60
        let minutes = todayTotalMinutes % 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }

    var goalProgress: Double {
        guard let goal = activeGoals.first else { return 0 }
        let used = todayTotalMinutes
        let limit = goal.dailyLimitMinutes
        return min(Double(used) / Double(limit), 1.0)
    }

    // MARK: - Dependencies
    private let statsRepository: StatsRepository
    private let goalRepository: GoalRepository
    private let usageRepository: UsageRepository
    private let trackedAppsRepository: TrackedAppsRepository

    init(
        statsRepository: StatsRepository,
        goalRepository: GoalRepository,
        usageRepository: UsageRepository,
        trackedAppsRepository: TrackedAppsRepository
    ) {
        self.statsRepository = statsRepository
        self.goalRepository = goalRepository
        self.usageRepository = usageRepository
        self.trackedAppsRepository = trackedAppsRepository
    }

    // MARK: - Actions
    func loadData() async {
        isLoading = true
        defer { isLoading = false }

        // Load today's stats
        let today = Date()
        todayStats = try? await statsRepository.getDailyStats(for: today)

        // If no stats exist, calculate them
        if todayStats == nil {
            todayStats = try? await statsRepository.calculateDailyStats(for: today)
        }

        // Load active goals
        activeGoals = (try? await goalRepository.getGoalsWithStreaks()) ?? []

        // Load recent sessions
        let startOfDay = today.startOfDay
        let endOfDay = today.endOfDay
        recentSessions = (try? await usageRepository.getSessions(for: startOfDay...endOfDay)) ?? []
    }

    func refresh() {
        Task {
            await loadData()
        }
    }

    // MARK: - App Status
    func getGoalStatus(for app: String) -> GoalProgress? {
        // TODO: Implement goal progress calculation per app
        return nil
    }

    func getStreakLabel(for app: String) -> String {
        guard let goal = activeGoals.first(where: { $0.targetApp == app }) else {
            return "No goal set"
        }
        return goal.streakLabel
    }
}
