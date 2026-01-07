//
//  StreakRecoveryRepository.swift
//  ThinkFast
//
//  Created on 2025-01-01.
//

import Foundation

protocol StreakRecoveryRepository {
    // MARK: - Recovery Management
    func initiateRecovery(for app: String, brokenStreak: Int) async throws -> StreakRecovery
    func getRecovery(for app: String) async throws -> StreakRecovery?
    func getAllRecoveries() async throws -> [StreakRecovery]
    func getActiveRecoveries() async throws -> [StreakRecovery]

    // MARK: - Progress
    func updateRecoveryProgress(for app: String, completedDay: Bool) async throws
    func completeRecovery(for app: String) async throws
    func cancelRecovery(for app: String) async throws

    // MARK: - Reminders
    func updateReminderDate(for app: String) async throws
    func shouldShowReminder(for app: String) async throws -> Bool

    // MARK: - Status
    func getRecoveryStatus(for app: String) async throws -> RecoveryStatus
}

// MARK: - Supporting Types
enum RecoveryStatus {
    case notNeeded
    case inProgress(progress: Double, daysCompleted: Int, daysTotal: Int)
    case completed(restoredStreak: Int)
    case expired
}
