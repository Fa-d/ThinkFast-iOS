//
//  StatsRepositoryImpl.swift
//  ThinkFast
//
//  Created on 2025-01-01.
//

import Foundation
import SwiftData

final class StatsRepositoryImpl: StatsRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func getDailyStats(for date: Date) async throws -> DailyStats? {
        let startOfDay = date.startOfDay
        let endOfDay = date.endOfDay

        let descriptor = FetchDescriptor<DailyStats>(
            predicate: #Predicate { $0.date >= startOfDay && $0.date <= endOfDay }
        )
        return try context.fetch(descriptor).first
    }

    func saveDailyStats(_ stats: DailyStats) async throws {
        context.insert(stats)
        try context.save()
    }

    func calculateDailyStats(for date: Date) async throws -> DailyStats {
        // TODO: Implement actual calculation
        return DailyStats(
            date: date,
            totalMinutes: 0,
            averageSessionMinutes: 0.0,
            sessionsCount: 0,
            longestSessionMinutes: 0
        )
    }

    func getWeeklyStats() async throws -> [DailyStats] {
        let now = Date()
        let startOfWeek = now.startOfWeek

        let descriptor = FetchDescriptor<DailyStats>(
            predicate: #Predicate { $0.date >= startOfWeek && $0.date <= now }
        )
        return try context.fetch(descriptor)
    }

    func getMonthlyStats() async throws -> [DailyStats] {
        let now = Date()
        let startOfMonth = now.startOfMonth

        let descriptor = FetchDescriptor<DailyStats>(
            predicate: #Predicate { $0.date >= startOfMonth && $0.date <= now }
        )
        return try context.fetch(descriptor)
    }

    func getStats(for dateRange: ClosedRange<Date>) async throws -> [DailyStats] {
        let descriptor = FetchDescriptor<DailyStats>(
            predicate: #Predicate { $0.date >= dateRange.lowerBound && $0.date <= dateRange.upperBound }
        )
        return try context.fetch(descriptor)
    }

    func calculateTrend(period: TrendPeriod) async throws -> StatsTrend {
        // TODO: Implement actual trend calculation
        return StatsTrend(
            averageDailyMinutes: 0.0,
            trendDirection: .stable,
            percentageChange: 0.0,
            mostUsedApp: nil,
            totalSessions: 0
        )
    }

    func getAverageUsage(for app: String?, days: Int) async throws -> Double {
        // TODO: Implement actual calculation
        return 0.0
    }
}
