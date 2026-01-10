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
    /// Calculate recovery target: 50% of previous streak OR 7 days, whichever is lower
    /// Example: 20-day streak → recover in 7 days
    ///          6-day streak → recover in 3 days
    var calculatedRecoveryTarget: Int {
        let halfStreak = max(previousStreak / 2, 1)
        return min(halfStreak, 7)
    }

    var recoveryProgress: Double {
        let target = calculatedRecoveryTarget
        return min(Double(currentRecoveryDays) / Double(target), 1.0)
    }

    var isRecoveryInProgress: Bool {
        return !isRecoveryComplete && currentRecoveryDays > 0
    }

    var daysRemaining: Int {
        let target = calculatedRecoveryTarget
        return max(0, target - currentRecoveryDays)
    }

    var progressMessage: String {
        if isRecoveryComplete {
            return "Streak recovered!"
        } else if currentRecoveryDays == 0 {
            return "Start your recovery"
        } else {
            return "\(currentRecoveryDays)/\(calculatedRecoveryTarget) days"
        }
    }

    /// Get contextual recovery message based on current progress
    var recoveryMessage: String {
        let target = calculatedRecoveryTarget
        let remaining = target - currentRecoveryDays

        if isRecoveryComplete {
            return "You're back on track! 🎉"
        } else if currentRecoveryDays == 0 {
            return "Your \(previousStreak)-day streak was amazing! You're 1 day away from getting back on track."
        } else if remaining == 1 {
            return "Just 1 day until you're back on track!"
        } else if remaining > 1 {
            return "\(remaining) days until you're back on track!"
        } else {
            return "Almost there! Keep going!"
        }
    }

    /// Get shortened message for cards
    var shortMessage: String {
        let target = calculatedRecoveryTarget
        let remaining = target - currentRecoveryDays

        if isRecoveryComplete {
            return "Back on track!"
        } else if currentRecoveryDays == 0 {
            return "Start your comeback today"
        } else if remaining == 1 {
            return "1 more day!"
        } else {
            return "\(remaining) more days"
        }
    }

    /// Check if current day count is a recovery milestone (1, 3, 7, 14 days)
    func isRecoveryMilestone(days: Int) -> Bool {
        return [1, 3, 7, 14].contains(days)
    }

    /// Check if today is a recovery day that should trigger notification
    var shouldNotifyToday: Bool {
        guard !isRecoveryComplete else { return false }

        // Check if we've already reminded today
        let calendar = Calendar.current
        if let lastReminder = lastReminderDate {
            let today = calendar.startOfDay(for: Date())
            let reminderDay = calendar.startOfDay(for: lastReminder)
            if today == reminderDay {
                return false
            }
        }

        // Notify on milestone days
        return isRecoveryMilestone(days: currentRecoveryDays)
    }
}

// MARK: - Streak Freeze Status
/// Represents the status of streak freeze functionality
struct StreakFreezeStatus: Codable {
    let freezesAvailable: Int
    let maxFreezes: Int
    let hasActiveFreeze: Bool
    let freezeActivationDate: Date?
    let canUseFreeze: Bool

    /// Get display text for freeze count
    var freezeCountText: String {
        return "\(freezesAvailable)/\(maxFreezes)"
    }

    /// Check if user is out of freezes
    var isOutOfFreezes: Bool {
        return freezesAvailable <= 0
    }

    /// Get freeze icon based on availability
    var freezeIcon: String {
        if freezesAvailable > 2 {
            return "❄️❄️❄️"
        } else if freezesAvailable == 2 {
            return "❄️❄️"
        } else if freezesAvailable == 1 {
            return "❄️"
        } else {
            return "💔"
        }
    }
}
