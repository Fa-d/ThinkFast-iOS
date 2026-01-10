//
//  StatsRepository.swift
//  Intently
//
//  Created on 2025-01-01.
//

import Foundation

protocol StatsRepository {
    // MARK: - Daily Stats
    func getDailyStats(for date: Date) async throws -> DailyStats?
    func saveDailyStats(_ stats: DailyStats) async throws
    func calculateDailyStats(for date: Date) async throws -> DailyStats

    // MARK: - Period Stats
    func getWeeklyStats() async throws -> [DailyStats]
    func getMonthlyStats() async throws -> [DailyStats]
    func getStats(for dateRange: ClosedRange<Date>) async throws -> [DailyStats]

    // MARK: - Trends
    func calculateTrend(period: TrendPeriod) async throws -> StatsTrend
    func getAverageUsage(for app: String?, days: Int) async throws -> Double
}

// MARK: - Supporting Types
enum TrendPeriod {
    case week
    case month
    case threeMonths
    case year
}

struct StatsTrend {
    let averageDailyMinutes: Double
    let trendDirection: TrendDirection
    let percentageChange: Double
    let mostUsedApp: String?
    let totalSessions: Int
}

enum TrendDirection {
    case up
    case down
    case stable
}

struct GoalProgress {
    let app: String
    let appName: String?
    let dailyLimit: Int
    let usedMinutes: Int
    let remainingMinutes: Int
    let percentageUsed: Double
    let isOverLimit: Bool
}
