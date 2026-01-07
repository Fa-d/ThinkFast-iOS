//
//  StreakRecovery.swift
//  ThinkFast
//
//  Created on 2025-01-01.
//

import Foundation
import SwiftData

@Model
final class StreakRecovery {
    // MARK: - Core Properties
    var targetApp: String = ""
    var targetAppName: String?
    var previousStreak: Int = 0
    var recoveryStartDate: Date = Date()
    var currentRecoveryDays: Int = 0
    var isRecoveryComplete: Bool = false
    var recoveryCompletionDate: Date?

    // MARK: - Recovery Configuration
    var requiredRecoveryDays: Int = 3 // Days to recover streak

    // MARK: - Notifications
    var lastReminderDate: Date?
    var hasRemindedToday: Bool = false

    // MARK: - Sync Properties
    var userId: String?
    var syncStatus: String = "pending"
    var lastModified: Date = Date()
    var cloudId: String?

    // MARK: - Initializer
    init(
        targetApp: String = "",
        targetAppName: String? = nil,
        previousStreak: Int = 0,
        recoveryStartDate: Date = Date(),
        currentRecoveryDays: Int = 0,
        isRecoveryComplete: Bool = false,
        recoveryCompletionDate: Date? = nil,
        requiredRecoveryDays: Int = 3,
        lastReminderDate: Date? = nil,
        hasRemindedToday: Bool = false,
        userId: String? = nil,
        syncStatus: String = "pending",
        lastModified: Date = Date(),
        cloudId: String? = nil
    ) {
        self.targetApp = targetApp
        self.targetAppName = targetAppName
        self.previousStreak = previousStreak
        self.recoveryStartDate = recoveryStartDate
        self.currentRecoveryDays = currentRecoveryDays
        self.isRecoveryComplete = isRecoveryComplete
        self.recoveryCompletionDate = recoveryCompletionDate
        self.requiredRecoveryDays = requiredRecoveryDays
        self.lastReminderDate = lastReminderDate
        self.hasRemindedToday = hasRemindedToday
        self.userId = userId
        self.syncStatus = syncStatus
        self.lastModified = lastModified
        self.cloudId = cloudId
    }
}

// MARK: - Computed Properties
extension StreakRecovery {
    var recoveryProgress: Double {
        return Double(currentRecoveryDays) / Double(requiredRecoveryDays)
    }

    var isRecoveryInProgress: Bool {
        return !isRecoveryComplete && currentRecoveryDays > 0
    }

    var daysRemaining: Int {
        return max(0, requiredRecoveryDays - currentRecoveryDays)
    }

    var progressMessage: String {
        if isRecoveryComplete {
            return "Streak recovered!"
        } else if currentRecoveryDays == 0 {
            return "Start your recovery"
        } else {
            return "\(currentRecoveryDays)/\(requiredRecoveryDays) days"
        }
    }
}
