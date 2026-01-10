//
//  StatsViewModel.swift
//  ThinkFast
//
//  Created on 2025-01-01.
//

import Foundation
import SwiftUI

// MARK: - Chart Data Models (TODO: These should be in ChartModels.swift)
struct DailyUsageData: Identifiable, Equatable {
    let id = UUID()
    let date: Date
    let minutes: Int
    let sessions: Int
    let goalMinutes: Int?

    var dayLabel: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "E"
            return formatter.string(from: date).prefix(3).uppercased()
        }
    }

    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
}

struct AppBreakdownData {
    let apps: [AppUsageBreakdown]
    let totalMinutes: Int
}

struct AppUsageBreakdown: Identifiable {
    let id: String
    let appName: String
    let minutes: Int
    let percentage: Double
}

struct HourlyUsage: Identifiable {
    let id: Int  // Hour of day (0-23)
    let hour: Int
    let minutes: Int
}

@Observable
final class StatsViewModel {
    // MARK: - Published Properties
    var isLoading = false
    var selectedPeriod: StatsPeriod = .week
    var dailyStats: [DailyStats] = []
    var trend: StatsTrend?

    // MARK: - Computed Properties
    var totalUsage: String {
        let totalMinutes = dailyStats.reduce(0) { $0 + $1.totalMinutes }
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        return "\(hours)h \(minutes)m"
    }

    var averageDaily: String {
        guard !dailyStats.isEmpty else { return "0m" }
        let avg = dailyStats.reduce(0.0) { $0 + $1.averageSessionMinutes }
        let averageAvg = avg / Double(dailyStats.count)
        let minutes = Int(averageAvg)
        return "\(minutes)m avg"
    }

    var longestSession: String {
        let longest = dailyStats.max(by: { $0.longestSessionMinutes < $1.longestSessionMinutes })?.longestSessionMinutes ?? 0
        let hours = longest / 60
        let minutes = longest % 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }

    // MARK: - Dependencies
    private let statsRepository: StatsRepository

    init(statsRepository: StatsRepository) {
        self.statsRepository = statsRepository
    }

    // MARK: - Actions
    func loadData() async {
        isLoading = true
        defer { isLoading = false }

        switch selectedPeriod {
        case .day:
            let today = Date()
            if let stats = try? await statsRepository.getDailyStats(for: today) {
                dailyStats = [stats]
            }
        case .week:
            dailyStats = (try? await statsRepository.getWeeklyStats()) ?? []
        case .month:
            dailyStats = (try? await statsRepository.getMonthlyStats()) ?? []
        }

        // Calculate trend
        if let trendResult = try? await statsRepository.calculateTrend(period: .week) {
            trend = trendResult
        }
    }

    func changePeriod(_ period: StatsPeriod) {
        selectedPeriod = period
        Task {
            await loadData()
        }
    }

    // MARK: - Chart Data
    var chartData: [(date: Date, minutes: Int)] {
        return dailyStats.map { ($0.date, $0.totalMinutes) }
    }

    // Weekly chart data for bar and line charts
    var weeklyChartData: [DailyUsageData]? {
        guard !dailyStats.isEmpty else { return nil }
        return dailyStats.map { stat in
            DailyUsageData(
                date: stat.date,
                minutes: stat.totalMinutes,
                sessions: stat.sessionsCount,
                goalMinutes: nil
            )
        }
    }

    // Average goal minutes across all goals
    var averageGoalMinutes: Int? {
        // This would come from goal repository
        // For now, return a default or calculate from stats
        return nil
    }

    // App breakdown data for donut chart
    var appBreakdownData: AppBreakdownData? {
        guard !dailyStats.isEmpty else { return nil }

        // Aggregate app usage from daily stats
        // This is a simplified version - real implementation would need app-specific data
        let totalMinutes = dailyStats.reduce(0) { $0 + $1.totalMinutes }

        // Create dummy app breakdown for visualization
        // In production, this would come from actual app usage data
        let apps = [
            AppUsageBreakdown(
                id: "social_media",
                appName: "Social Media",
                minutes: Int(Double(totalMinutes) * 0.4),
                percentage: 40.0
            ),
            AppUsageBreakdown(
                id: "entertainment",
                appName: "Entertainment",
                minutes: Int(Double(totalMinutes) * 0.3),
                percentage: 30.0
            ),
            AppUsageBreakdown(
                id: "productivity",
                appName: "Productivity",
                minutes: Int(Double(totalMinutes) * 0.2),
                percentage: 20.0
            ),
            AppUsageBreakdown(
                id: "other",
                appName: "Other",
                minutes: Int(Double(totalMinutes) * 0.1),
                percentage: 10.0
            )
        ]

        return AppBreakdownData(apps: apps, totalMinutes: totalMinutes)
    }

    // Hourly usage data for heatmap
    var hourlyUsageData: [HourlyUsage]? {
        // This would come from usage events repository
        // For now, generate sample data
        return (0..<24).map { hour in
            // Simulate realistic usage pattern
            let baseUsage: Double
            switch hour {
            case 7..<11: baseUsage = 30
            case 11..<14: baseUsage = 20
            case 14..<18: baseUsage = 45
            case 18..<22: baseUsage = 70
            case 22..<24: baseUsage = 40
            default: baseUsage = 5
            }
            let variance = Double.random(in: -10...10)
            return HourlyUsage(
                id: hour,
                hour: hour,
                minutes: Int(max(0, baseUsage + variance))
            )
        }
    }

    // Today's usage formatted for HomeView
    func getFormattedTodayUsage() async -> String {
        let today = Date()
        if let todayStats = try? await statsRepository.getDailyStats(for: today) {
            let hours = todayStats.totalMinutes / 60
            let minutes = todayStats.totalMinutes % 60
            if hours > 0 {
                return "\(hours)h \(minutes)m"
            }
            return "\(minutes)m"
        }
        return "0m"
    }
}

enum StatsPeriod: String, CaseIterable {
    case day = "Day"
    case week = "Week"
    case month = "Month"
}
