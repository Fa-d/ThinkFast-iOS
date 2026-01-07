//
//  CloudKitSyncManager.swift
//  ThinkFast
//
//  Created on 2025-01-02.
//

import CloudKit
import Foundation
import os.log
import SwiftData

// MARK: - CloudKit Sync Manager
@MainActor
class CloudKitSyncManager: ObservableObject {
    private let logger = Logger(subsystem: "dev.sadakat.thinkfast", category: "CloudKit")

    private let container = CKContainer(identifier: "iCloud.dev.sadakat.thinkfast")
    private let privateDatabase: CKDatabase

    @Published var isSyncing = false
    @Published var lastSyncDate: Date?
    @Published var syncError: String?

    // Record types
    private enum RecordType {
        static let goal = "CD_Goal"
        static let dailyStats = "CD_DailyStats"
        static let usageSession = "CD_UsageSession"
    }

    init() {
        self.privateDatabase = container.privateCloudDatabase
        setupCloudKit()
    }

    // MARK: - Setup CloudKit
    private func setupCloudKit() {
        logger.log("Setting up CloudKit")

        Task {
            do {
                let accountStatus = try await container.accountStatus()
                await handleAccountStatus(accountStatus)
            } catch {
                logger.error("Failed to check account status: \(error.localizedDescription)")
                await MainActor.run {
                    self.syncError = "CloudKit unavailable: \(error.localizedDescription)"
                }
            }
        }
    }

    // MARK: - Handle Account Status
    private func handleAccountStatus(_ status: CKAccountStatus) async {
        await MainActor.run {
            switch status {
            case .available:
                logger.log("iCloud account available")
                self.syncError = nil
            case .noAccount:
                logger.error("No iCloud account")
                self.syncError = "No iCloud account found"
            case .restricted:
                logger.error("iCloud account restricted")
                self.syncError = "iCloud access restricted"
            case .temporarilyUnavailable:
                logger.error("iCloud temporarily unavailable")
                self.syncError = "iCloud temporarily unavailable"
            case .couldNotDetermine:
                logger.error("Could not determine iCloud status")
                self.syncError = "Unknown iCloud error"
            @unknown default:
                logger.error("Unknown iCloud status")
                self.syncError = "Unknown iCloud error"
            }
        }
    }

    // MARK: - Sync Goals
    func syncGoals(_ goals: [Goal]) async throws {
        logger.log("Syncing \(goals.count) goals")

        await MainActor.run {
            self.isSyncing = true
        }

        let records = goals.map { goal in
            let record = CKRecord(recordType: RecordType.goal)
            record["targetApp"] = goal.targetApp
            record["targetAppName"] = goal.targetAppName
            record["dailyLimitMinutes"] = goal.dailyLimitMinutes
            record["startDate"] = goal.startDate
            record["currentStreak"] = goal.currentStreak
            record["longestStreak"] = goal.longestStreak
            record["lastUpdated"] = goal.lastUpdated
            record["isEnabled"] = goal.isEnabled
            record["lastCompletedDate"] = goal.lastCompletedDate
            record["lastBrokenDate"] = goal.lastBrokenDate
            record["syncStatus"] = goal.syncStatus
            record["lastModified"] = goal.lastModified
            if let cloudId = goal.cloudId {
                record["cloudId"] = cloudId
            }
            return record
        }

        let operation = CKModifyRecordsOperation(recordsToSave: records, recordIDsToDelete: [])
        operation.modifyRecordsCompletionBlock = { savedRecords, deletedRecordIDs, error in
            if let error = error {
                self.logger.error("Failed to sync goals: \(error.localizedDescription)")
            } else {
                self.logger.log("Goals synced successfully")
            }
        }
        await privateDatabase.add(operation)

        await MainActor.run {
            self.lastSyncDate = Date()
            self.isSyncing = false
        }

        logger.log("Goals synced successfully")
    }

    // MARK: - Fetch Goals
    func fetchGoals() async throws -> [Goal] {
        logger.log("Fetching goals from CloudKit")

        let query = CKQuery(recordType: RecordType.goal, predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "targetAppName", ascending: true)]

        let (matchResults, _) = try await privateDatabase.records(matching: query)

        var goals: [Goal] = []
        for (_, result) in matchResults {
            switch result {
            case .success(let record):
                let goal = Goal(
                    targetApp: record["targetApp"] as? String ?? "",
                    targetAppName: record["targetAppName"] as? String,
                    dailyLimitMinutes: record["dailyLimitMinutes"] as? Int ?? 60,
                    startDate: record["startDate"] as? Date ?? Date(),
                    currentStreak: record["currentStreak"] as? Int ?? 0,
                    longestStreak: record["longestStreak"] as? Int ?? 0,
                    lastUpdated: record["lastUpdated"] as? Date ?? Date(),
                    isEnabled: record["isEnabled"] as? Bool ?? true,
                    lastCompletedDate: record["lastCompletedDate"] as? Date,
                    lastBrokenDate: record["lastBrokenDate"] as? Date,
                    userId: nil,
                    syncStatus: record["syncStatus"] as? String ?? "synced",
                    lastModified: record["lastModified"] as? Date ?? Date(),
                    cloudId: record.recordID.recordName
                )
                goals.append(goal)
            case .failure(let error):
                logger.error("Failed to fetch goal: \(error.localizedDescription)")
            }
        }

        logger.log("Fetched \(goals.count) goals")
        return goals
    }

    // MARK: - Delete Goal
    func deleteGoal(cloudId: String) async throws {
        logger.log("Deleting goal: \(cloudId)")

        let recordID = CKRecord.ID(recordName: cloudId)
        try await privateDatabase.deleteRecord(withID: recordID)

        logger.log("Goal deleted successfully")
    }

    // MARK: - Sync All Data
    func syncAllData(goals: [Goal], stats: [DailyStats]) async {
        logger.log("Syncing all data")

        do {
            let accountStatus = try await container.accountStatus()
            await handleAccountStatus(accountStatus)

            guard accountStatus == .available else {
                logger.error("iCloud not available")
                return
            }

            try await syncGoals(goals)

            await MainActor.run {
                self.lastSyncDate = Date()
                self.syncError = nil
            }

            logger.log("All data synced successfully")
        } catch {
            logger.error("Sync failed: \(error.localizedDescription)")
            await MainActor.run {
                self.syncError = error.localizedDescription
            }
        }
    }
}

// MARK: - CloudKit Sync Error
enum CloudKitSyncError: LocalizedError {
    case notAvailable
    case accountNotFound
    case networkError(String)
    case syncFailed(String)

    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "CloudKit is not available"
        case .accountNotFound:
            return "No iCloud account found"
        case .networkError(let message):
            return "Network error: \(message)"
        case .syncFailed(let message):
            return "Sync failed: \(message)"
        }
    }
}
