//
//  GoalViewModel.swift
//  ThinkFast
//
//  Created on 2025-01-01.
//

import Foundation
import SwiftUI

@Observable
final class GoalViewModel {
    // MARK: - Published Properties
    var isLoading = false
    var goals: [Goal] = []
    var trackedApps: [TrackedApp] = []

    // MARK: - Editing State
    var editingGoal: Goal?
    var editedDailyLimit: Int = 60

    // MARK: - Dependencies
    private let goalRepository: GoalRepository
    private let trackedAppsRepository: TrackedAppsRepository

    init(
        goalRepository: GoalRepository,
        trackedAppsRepository: TrackedAppsRepository
    ) {
        self.goalRepository = goalRepository
        self.trackedAppsRepository = trackedAppsRepository
    }

    // MARK: - Actions
    func loadData() async {
        isLoading = true
        defer { isLoading = false }

        goals = (try? await goalRepository.getAllGoals()) ?? []
        trackedApps = (try? await trackedAppsRepository.getTrackedApps()) ?? []
    }

    // MARK: - Add/Edit Goal
    func setGoal(for app: TrackedApp, dailyLimitMinutes: Int) async {
        try? await goalRepository.setGoal(
            for: app.id,
            appName: app.name,
            dailyLimitMinutes: dailyLimitMinutes
        )
        await loadData()
    }

    func updateGoal(_ goal: Goal) async {
        try? await goalRepository.updateGoal(goal)
        await loadData()
    }

    func deleteGoal(for app: String) async {
        try? await goalRepository.deleteGoal(for: app)
        await loadData()
    }

    func toggleGoal(for app: String, enabled: Bool) async {
        try? await goalRepository.toggleGoal(for: app, enabled: enabled)
        await loadData()
    }

    // MARK: - Helper Methods
    func getGoal(for app: String) -> Goal? {
        goals.first { $0.targetApp == app }
    }

    func getProgress(for goal: Goal) async -> GoalProgress? {
        return try? await goalRepository.getGoalProgress(for: goal.targetApp, date: Date())
    }
}
