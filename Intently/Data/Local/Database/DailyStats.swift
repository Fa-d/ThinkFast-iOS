//
//  DailyStats.swift
//  Intently
//
//  Created on 2025-01-01.
//

import Foundation
import SwiftData

@Model
final class DailyStats {
    // MARK: - Core Properties
    var date: Date = Date()
    var totalMinutes: Int = 0
    var averageSessionMinutes: Double = 0.0
    var sessionsCount: Int = 0
    var longestSessionMinutes: Int = 0

    // MARK: - Breakdown by App
    var appBreakdown: String? // JSON string: ["com.facebook": 120, "com.instagram": 90]

    // MARK: - Sync Properties
    var userId: String?
    var syncStatus: String = "pending"
    var lastModified: Date = Date()
    var cloudId: String?

    // MARK: - Initializer
    init(
        date: Date = Date(),
        totalMinutes: Int = 0,
        averageSessionMinutes: Double = 0.0,
        sessionsCount: Int = 0,
        longestSessionMinutes: Int = 0,
        appBreakdown: String? = nil,
        userId: String? = nil,
        syncStatus: String = "pending",
        lastModified: Date = Date(),
        cloudId: String? = nil
    ) {
        self.date = date
        self.totalMinutes = totalMinutes
        self.averageSessionMinutes = averageSessionMinutes
        self.sessionsCount = sessionsCount
        self.longestSessionMinutes = longestSessionMinutes
        self.appBreakdown = appBreakdown
        self.userId = userId
        self.syncStatus = syncStatus
        self.lastModified = lastModified
        self.cloudId = cloudId
    }
}

// MARK: - Computed Properties
extension DailyStats {
    var formattedTotalTime: String {
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }

    var formattedAverageTime: String {
        let minutes = Int(averageSessionMinutes)
        let seconds = Int((averageSessionMinutes.truncatingRemainder(dividingBy: 1)) * 60)
        return "\(minutes)m \(seconds)s"
    }
}
