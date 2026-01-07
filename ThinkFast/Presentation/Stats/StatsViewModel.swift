//
//  StatsViewModel.swift
//  ThinkFast
//
//  Created on 2025-01-01.
//

import Foundation
import SwiftUI

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
}

enum StatsPeriod: String, CaseIterable {
    case day = "Day"
    case week = "Week"
    case month = "Month"
}
