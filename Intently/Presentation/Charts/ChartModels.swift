//
//  ChartModels.swift
//  Intently
//
//  Created on 2025-01-07.
//  Shared data models for charts
//

import SwiftUI

// MARK: - Daily Usage Data

/// Daily usage data for bar and line charts
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

// MARK: - App Breakdown Data

/// Container for app breakdown data
struct AppBreakdownData {
    let apps: [AppUsageBreakdown]
    let totalMinutes: Int
}
