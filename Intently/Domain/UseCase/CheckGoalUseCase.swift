//
//  CheckGoalUseCase.swift
//  Intently
//
//  Created on 2025-01-01.
//

import Foundation

struct CheckGoalUseCase {
    private let goalRepository: GoalRepository
    private let usageRepository: UsageRepository

    init(goalRepository: GoalRepository, usageRepository: UsageRepository) {
        self.goalRepository = goalRepository
        self.usageRepository = usageRepository
    }

    func execute(for app: String, date: Date = Date()) async throws -> GoalStatus {
        guard let goal = try await goalRepository.getGoal(for: app) else {
            return GoalStatus.noGoalSet
        }

        // Get today's usage for this app
        let startOfDay = date.startOfDay
        let endOfDay = date.endOfDay
        let sessions = try await usageRepository.getSessions(for: app, dateRange: startOfDay...endOfDay)

        let totalUsed = sessions.reduce(0) { $0 + $1.duration }
        let usedMinutes = Int(totalUsed / 60)
        let limitMinutes = goal.dailyLimitMinutes

        let percentageUsed = Double(usedMinutes) / Double(limitMinutes)

        if usedMinutes >= limitMinutes {
            return GoalStatus.exceeded(
                usedMinutes: usedMinutes,
                limitMinutes: limitMinutes,
                percentageUsed: percentageUsed
            )
        } else if percentageUsed >= 0.8 {
            return GoalStatus.approaching(
                usedMinutes: usedMinutes,
                limitMinutes: limitMinutes,
                percentageUsed: percentageUsed
            )
        } else {
            return GoalStatus.onTrack(
                usedMinutes: usedMinutes,
                limitMinutes: limitMinutes,
                percentageUsed: percentageUsed
            )
        }
    }
}

enum GoalStatus {
    case noGoalSet
    case onTrack(usedMinutes: Int, limitMinutes: Int, percentageUsed: Double)
    case approaching(usedMinutes: Int, limitMinutes: Int, percentageUsed: Double)
    case exceeded(usedMinutes: Int, limitMinutes: Int, percentageUsed: Double)

    var isOverLimit: Bool {
        if case .exceeded = self { return true }
        return false
    }

    var isApproaching: Bool {
        if case .approaching = self { return true }
        return false
    }
}
