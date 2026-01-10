//
//  StreakRecoveryRepositoryImpl.swift
//  ThinkFast
//
//  Created on 2025-01-01.
//

import Foundation
import SwiftData

final class StreakRecoveryRepositoryImpl: StreakRecoveryRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func initiateRecovery(for app: String, brokenStreak: Int) async throws -> StreakRecovery {
        let recovery = StreakRecovery(
            targetApp: app,
            previousStreak: brokenStreak,
            recoveryStartDate: Date()
        )
        context.insert(recovery)
        try context.save()
        return recovery
    }

    func getRecovery(for app: String) async throws -> StreakRecovery? {
        let descriptor = FetchDescriptor<StreakRecovery>(
            predicate: #Predicate { $0.targetApp == app && $0.isRecoveryComplete == false }
        )
        return try context.fetch(descriptor).first
    }

    func getAllRecoveries() async throws -> [StreakRecovery] {
        let descriptor = FetchDescriptor<StreakRecovery>()
        return try context.fetch(descriptor)
    }

    func getActiveRecoveries() async throws -> [StreakRecovery] {
        let descriptor = FetchDescriptor<StreakRecovery>(
            predicate: #Predicate { $0.isRecoveryComplete == false }
        )
        return try context.fetch(descriptor)
    }

    func saveRecovery(_ recovery: StreakRecovery) async throws {
        context.insert(recovery)
        try context.save()
    }

    func updateRecovery(_ recovery: StreakRecovery) async throws {
        recovery.lastModified = Date()
        try context.save()
    }

    func updateRecoveryProgress(for app: String, completedDay: Bool) async throws {
        guard let recovery = try await getRecovery(for: app) else { return }
        if completedDay {
            recovery.currentRecoveryDays += 1
            recovery.lastModified = Date()
        }
        try context.save()
    }

    func completeRecovery(for app: String) async throws {
        guard let recovery = try await getRecovery(for: app) else { return }
        recovery.isRecoveryComplete = true
        recovery.recoveryCompletionDate = Date()
        recovery.lastModified = Date()
        try context.save()
    }

    func cancelRecovery(for app: String) async throws {
        guard let recovery = try await getRecovery(for: app) else { return }
        context.delete(recovery)
        try context.save()
    }

    func updateReminderDate(for app: String) async throws {
        guard let recovery = try await getRecovery(for: app) else { return }
        recovery.lastReminderDate = Date()
        recovery.lastModified = Date()
        try context.save()
    }

    func shouldShowReminder(for app: String) async throws -> Bool {
        guard let recovery = try await getRecovery(for: app) else { return false }
        return !recovery.hasRemindedToday
    }

    func getRecoveryStatus(for app: String) async throws -> RecoveryStatus {
        guard let recovery = try await getRecovery(for: app) else {
            return .notNeeded
        }

        if recovery.isRecoveryComplete {
            return .completed(restoredStreak: recovery.previousStreak)
        } else {
            return .inProgress(
                progress: recovery.recoveryProgress,
                daysCompleted: recovery.currentRecoveryDays,
                daysTotal: recovery.requiredRecoveryDays
            )
        }
    }
}
