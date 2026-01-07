//
//  GoalRepositoryImpl.swift
//  ThinkFast
//
//  Created on 2025-01-01.
//

import Foundation
import SwiftData

final class GoalRepositoryImpl: GoalRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func setGoal(for app: String, appName: String?, dailyLimitMinutes: Int) async throws {
        let goal = Goal(
            targetApp: app,
            targetAppName: appName,
            dailyLimitMinutes: dailyLimitMinutes,
            startDate: Date()
        )
        context.insert(goal)
        try context.save()
    }

    func getGoal(for app: String) async throws -> Goal? {
        let descriptor = FetchDescriptor<Goal>(
            predicate: #Predicate { $0.targetApp == app }
        )
        return try context.fetch(descriptor).first
    }

    func getAllGoals() async throws -> [Goal] {
        let descriptor = FetchDescriptor<Goal>()
        return try context.fetch(descriptor)
    }

    func updateGoal(_ goal: Goal) async throws {
        goal.lastModified = Date()
        try context.save()
    }

    func deleteGoal(for app: String) async throws {
        guard let goal = try await getGoal(for: app) else { return }
        context.delete(goal)
        try context.save()
    }

    func toggleGoal(for app: String, enabled: Bool) async throws {
        guard let goal = try await getGoal(for: app) else { return }
        goal.isEnabled = enabled
        goal.lastModified = Date()
        try context.save()
    }

    func updateStreak(for app: String, completed: Bool) async throws {
        guard let goal = try await getGoal(for: app) else { return }
        if completed {
            goal.currentStreak += 1
            goal.lastCompletedDate = Date()
            if goal.currentStreak > goal.longestStreak {
                goal.longestStreak = goal.currentStreak
            }
        } else {
            goal.currentStreak = 0
            goal.lastBrokenDate = Date()
        }
        goal.lastModified = Date()
        try context.save()
    }

    func checkGoalCompletion(for app: String, date: Date) async throws -> Bool {
        guard let goal = try await getGoal(for: app) else { return false }
        // TODO: Implement actual goal checking logic
        return true
    }

    func getGoalsWithStreaks() async throws -> [Goal] {
        let descriptor = FetchDescriptor<Goal>(
            predicate: #Predicate { $0.isEnabled }
        )
        return try context.fetch(descriptor)
    }

    func getGoalProgress(for app: String, date: Date) async throws -> GoalProgress {
        guard let goal = try await getGoal(for: app) else {
            throw RepositoryError.notFound
        }
        // TODO: Calculate actual progress
        return GoalProgress(
            app: app,
            appName: goal.targetAppName,
            dailyLimit: goal.dailyLimitMinutes,
            usedMinutes: 0,
            remainingMinutes: goal.dailyLimitMinutes,
            percentageUsed: 0.0,
            isOverLimit: false
        )
    }
}

enum RepositoryError: Error {
    case notFound
    case saveFailed
    case deleteFailed
}
