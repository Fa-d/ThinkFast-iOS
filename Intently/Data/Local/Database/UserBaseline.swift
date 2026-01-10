//
//  UserBaseline.swift
//  Intently
//
//  Created on 2025-01-01.
//

import Foundation
import SwiftData

@Model
final class UserBaseline {
    // MARK: - Core Properties
    var firstWeekStartDate: Date = Date()
    var totalUsageMinutes: Int = 0
    var averageDailyMinutes: Double = 0.0

    // MARK: - App-specific Baselines
    var facebookAverageMinutes: Double = 0.0
    var instagramAverageMinutes: Double = 0.0
    var tiktokAverageMinutes: Double?
    var twitterAverageMinutes: Double?
    var youtubeAverageMinutes: Double?

    // MARK: - Session Data
    var averageSessionsPerDay: Double = 0.0
    var averageSessionLength: Double = 0.0

    // MARK: - Computed Metrics
    var peakUsageHour: Int = 12 // 0-23
    var mostUsedApp: String?

    // MARK: - Status
    var isBaselineComplete: Bool = false
    var calculationDate: Date?

    // MARK: - Sync Properties
    var userId: String?
    var syncStatus: String = "pending"
    var lastModified: Date = Date()
    var cloudId: String?

    // MARK: - Initializer
    init(
        firstWeekStartDate: Date = Date(),
        totalUsageMinutes: Int = 0,
        averageDailyMinutes: Double = 0.0,
        facebookAverageMinutes: Double = 0.0,
        instagramAverageMinutes: Double = 0.0,
        tiktokAverageMinutes: Double? = nil,
        twitterAverageMinutes: Double? = nil,
        youtubeAverageMinutes: Double? = nil,
        averageSessionsPerDay: Double = 0.0,
        averageSessionLength: Double = 0.0,
        peakUsageHour: Int = 12,
        mostUsedApp: String? = nil,
        isBaselineComplete: Bool = false,
        calculationDate: Date? = nil,
        userId: String? = nil,
        syncStatus: String = "pending",
        lastModified: Date = Date(),
        cloudId: String? = nil
    ) {
        self.firstWeekStartDate = firstWeekStartDate
        self.totalUsageMinutes = totalUsageMinutes
        self.averageDailyMinutes = averageDailyMinutes
        self.facebookAverageMinutes = facebookAverageMinutes
        self.instagramAverageMinutes = instagramAverageMinutes
        self.tiktokAverageMinutes = tiktokAverageMinutes
        self.twitterAverageMinutes = twitterAverageMinutes
        self.youtubeAverageMinutes = youtubeAverageMinutes
        self.averageSessionsPerDay = averageSessionsPerDay
        self.averageSessionLength = averageSessionLength
        self.peakUsageHour = peakUsageHour
        self.mostUsedApp = mostUsedApp
        self.isBaselineComplete = isBaselineComplete
        self.calculationDate = calculationDate
        self.userId = userId
        self.syncStatus = syncStatus
        self.lastModified = lastModified
        self.cloudId = cloudId
    }
}

// MARK: - Computed Properties
extension UserBaseline {
    var formattedAverageDaily: String {
        let hours = Int(averageDailyMinutes) / 60
        let minutes = Int(averageDailyMinutes) % 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }

    var formattedAverageSession: String {
        let minutes = Int(averageSessionLength)
        let seconds = Int((averageSessionLength.truncatingRemainder(dividingBy: 1)) * 60)
        return "\(minutes)m \(seconds)s"
    }

    var daysInBaseline: Int {
        let calendar = Calendar.current
        let endDate = calculationDate ?? Date()
        let components = calendar.dateComponents([.day], from: firstWeekStartDate, to: endDate)
        return max(1, components.day ?? 1)
    }
}
