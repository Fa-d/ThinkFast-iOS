//
//  GoalRepository.swift
//  ThinkFast
//
//  Created on 2025-01-01.
//

import Foundation

protocol GoalRepository {
    // MARK: - Goal Management
    func setGoal(for app: String, appName: String?, dailyLimitMinutes: Int) async throws
    func getGoal(for app: String) async throws -> Goal?
    func getAllGoals() async throws -> [Goal]
    func updateGoal(_ goal: Goal) async throws
    func deleteGoal(for app: String) async throws
    func toggleGoal(for app: String, enabled: Bool) async throws

    // MARK: - Streak Management
    func updateStreak(for app: String, completed: Bool) async throws
    func checkGoalCompletion(for app: String, date: Date) async throws -> Bool
    func getGoalsWithStreaks() async throws -> [Goal]

    // MARK: - Progress
    func getGoalProgress(for app: String, date: Date) async throws -> GoalProgress
}
