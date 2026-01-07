//
//  Goal.swift
//  ThinkFast
//
//  Created on 2025-01-01.
//

import Foundation
import SwiftData

@Model
final class Goal {
    // MARK: - Core Properties
    var targetApp: String = ""
    var targetAppName: String?
    var dailyLimitMinutes: Int = 60
    var startDate: Date = Date()
    var currentStreak: Int = 0
    var longestStreak: Int = 0
    var lastUpdated: Date = Date()
    var isEnabled: Bool = true

    // MARK: - Streak History
    var lastCompletedDate: Date?
    var lastBrokenDate: Date?

    // MARK: - Sync Properties
    var userId: String?
    var syncStatus: String = "pending"
    var lastModified: Date = Date()
    var cloudId: String?

    // MARK: - Initializer
    init(
        targetApp: String = "",
        targetAppName: String? = nil,
        dailyLimitMinutes: Int = 60,
        startDate: Date = Date(),
        currentStreak: Int = 0,
        longestStreak: Int = 0,
        lastUpdated: Date = Date(),
        isEnabled: Bool = true,
        lastCompletedDate: Date? = nil,
        lastBrokenDate: Date? = nil,
        userId: String? = nil,
        syncStatus: String = "pending",
        lastModified: Date = Date(),
        cloudId: String? = nil
    ) {
        self.targetApp = targetApp
        self.targetAppName = targetAppName
        self.dailyLimitMinutes = dailyLimitMinutes
        self.startDate = startDate
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.lastUpdated = lastUpdated
        self.isEnabled = isEnabled
        self.lastCompletedDate = lastCompletedDate
        self.lastBrokenDate = lastBrokenDate
        self.userId = userId
        self.syncStatus = syncStatus
        self.lastModified = lastModified
        self.cloudId = cloudId
    }
}

// MARK: - Computed Properties
extension Goal {
    var formattedDailyLimit: String {
        let hours = dailyLimitMinutes / 60
        let minutes = dailyLimitMinutes % 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }

    var isStreakActive: Bool {
        guard let lastCompleted = lastCompletedDate else { return false }
        return Calendar.current.dateComponents([.day], from: lastCompleted, to: Date()).day ?? 0 <= 1
    }

    var streakLabel: String {
        if currentStreak == 0 {
            return "No streak"
        } else if currentStreak < 7 {
            return "\(currentStreak) day streak"
        } else if currentStreak < 30 {
            return "\(currentStreak) days - On fire!"
        } else {
            return "\(currentStreak) days - Legendary!"
        }
    }
}
