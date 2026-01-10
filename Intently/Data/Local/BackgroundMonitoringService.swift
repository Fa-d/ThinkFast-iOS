//
//  BackgroundMonitoringService.swift
//  Intently
//
//  Created on 2025-01-02.
//

import Foundation
import BackgroundTasks
import os.log
import SwiftData
import UserNotifications

// MARK: - Background Monitoring Service
@MainActor
class BackgroundMonitoringService: ObservableObject {
    private let logger = Logger(subsystem: "dev.sadakat.thinkfast", category: "BackgroundMonitoring")

    private let backgroundTaskIdentifier = "dev.sadakat.thinkfast.usage-sync"
    private let interventionTaskIdentifier = "dev.sadakat.thinkfast.intervention-check"

    @Published var isScheduled = false
    @Published var lastSyncDate: Date?

    private var deviceActivityManager: DeviceActivityManager?
    private var modelContext: ModelContext?

    init() {
        registerBackgroundTasks()
    }

    func setDeviceActivityManager(_ manager: DeviceActivityManager) {
        self.deviceActivityManager = manager
    }

    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }

    // MARK: - Register Background Tasks
    private func registerBackgroundTasks() {
        logger.log("Registering background tasks")

        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: backgroundTaskIdentifier,
            using: nil
        ) { [weak self] task in
            Task {
                await self?.handleUsageSync(task: task as! BGProcessingTask)
            }
        }

        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: interventionTaskIdentifier,
            using: nil
        ) { [weak self] task in
            Task {
                await self?.handleInterventionCheck(task: task as! BGProcessingTask)
            }
        }

        logger.log("Background tasks registered")
    }

    // MARK: - Schedule Background Sync
    func scheduleBackgroundSync() async {
        logger.log("Scheduling background sync")

        let request = BGProcessingTaskRequest(identifier: backgroundTaskIdentifier)
        request.requiresNetworkConnectivity = true
        request.requiresExternalPower = false

        do {
            try await BGTaskScheduler.shared.submit(request)
            await MainActor.run {
                self.isScheduled = true
            }
            logger.log("Background sync scheduled successfully")
        } catch {
            logger.error("Failed to schedule background sync: \(error.localizedDescription)")
            await MainActor.run {
                self.isScheduled = false
            }
        }
    }

    // MARK: - Schedule Intervention Check
    func scheduleInterventionCheck(every minutes: TimeInterval = 30) async {
        logger.log("Scheduling intervention check")

        let request = BGAppRefreshTaskRequest(identifier: interventionTaskIdentifier)
        let earliestDate = Date().addingTimeInterval(minutes)
        request.earliestBeginDate = earliestDate

        do {
            try await BGTaskScheduler.shared.submit(request)
            logger.log("Intervention check scheduled")
        } catch {
            logger.error("Failed to schedule intervention check: \(error.localizedDescription)")
        }
    }

    // MARK: - Handle Usage Sync
    private func handleUsageSync(task: BGProcessingTask) async {
        logger.log("Handling background usage sync")

        task.expirationHandler = {
            task.setTaskCompleted(success: false)
            self.logger.log("Background task expired")
        }

        do {
            await syncUsageData()

            await MainActor.run {
                self.lastSyncDate = Date()
            }

            await scheduleBackgroundSync()

            task.setTaskCompleted(success: true)
            logger.log("Background sync completed successfully")
        } catch {
            logger.error("Background sync failed: \(error.localizedDescription)")
            task.setTaskCompleted(success: false)

            Task {
                try? await Task.sleep(nanoseconds: UInt64(5 * 1_000_000_000))
                await self.scheduleBackgroundSync()
            }
        }
    }

    // MARK: - Handle Intervention Check
    private func handleInterventionCheck(task: BGProcessingTask) async {
        logger.log("Handling intervention check")

        task.expirationHandler = {
            task.setTaskCompleted(success: false)
            self.logger.log("Intervention check task expired")
        }

        do {
            await checkAndTriggerInterventions()
            await scheduleInterventionCheck()

            task.setTaskCompleted(success: true)
            logger.log("Intervention check completed")
        } catch {
            logger.error("Intervention check failed: \(error.localizedDescription)")
            task.setTaskCompleted(success: false)
        }
    }

    // MARK: - Sync Usage Data
    private func syncUsageData() async {
        logger.log("Syncing usage data")

        guard let context = modelContext else {
            logger.error("Model context not available")
            return
        }

        guard let deviceActivityManager = deviceActivityManager else {
            logger.error("DeviceActivityManager not available")
            return
        }

        let goalDescriptor = FetchDescriptor<Goal>()
        guard let goals = try? context.fetch(goalDescriptor) else {
            logger.error("Failed to fetch goals")
            return
        }

        let today = Calendar.current.startOfDay(for: Date())

        for goal in goals {
            let usage = await deviceActivityManager.getAppUsage(for: goal.targetApp)

            let statsDescriptor = FetchDescriptor<DailyStats>(
                predicate: #Predicate<DailyStats> { stat in
                    stat.date == today
                }
            )

            do {
                let existingStats = try context.fetch(statsDescriptor)

                if let stat = existingStats.first {
                    stat.totalMinutes = Int(usage / 60)
                } else {
                    let newStat = DailyStats(
                        date: today,
                        totalMinutes: Int(usage / 60)
                    )
                    context.insert(newStat)
                }

                try context.save()
                logger.log("Synced stats for \(goal.targetAppName ?? goal.targetApp)")
            } catch {
                logger.error("Failed to save stats: \(error.localizedDescription)")
            }
        }

        updateSharedDefaults()
    }

    // MARK: - Check and Trigger Interventions
    private func checkAndTriggerInterventions() async {
        logger.log("Checking for intervention triggers")

        guard let context = modelContext else {
            return
        }

        let today = Calendar.current.startOfDay(for: Date())

        for goal in (try? context.fetch(FetchDescriptor<Goal>())) ?? [] {
            let statsDescriptor = FetchDescriptor<DailyStats>(
                predicate: #Predicate<DailyStats> { stat in
                    stat.date == today
                }
            )

            if let stats = try? context.fetch(statsDescriptor),
               let todayStat = stats.first,
               todayStat.totalMinutes > goal.dailyLimitMinutes {

                await scheduleInterventionNotification(for: goal.targetAppName ?? goal.targetApp)
            }
        }
    }

    // MARK: - Schedule Intervention Notification
    private func scheduleInterventionNotification(for appName: String) async {
        let content = UNMutableNotificationContent()
        content.title = "Intently"
        content.body = "You've reached your daily limit for \(appName). Take a mindful break!"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )

        try? await UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Update Shared Defaults
    private func updateSharedDefaults() {
        guard let context = modelContext,
              let sharedDefaults = UserDefaults(suiteName: "group.dev.sadakat.thinkfast") else {
            return
        }

        let today = Calendar.current.startOfDay(for: Date())
        let statsDescriptor = FetchDescriptor<DailyStats>(
            predicate: #Predicate<DailyStats> { stat in
                stat.date == today
            }
        )

        guard let stats = try? context.fetch(statsDescriptor) else {
            return
        }

        let totalMinutes = stats.reduce(0) { $0 + $1.totalMinutes }

        sharedDefaults.set(totalMinutes, forKey: "todayUsage")
        sharedDefaults.set(today, forKey: "lastSyncDate")

        logger.log("Updated shared defaults - Total: \(totalMinutes)m")
    }

    // MARK: - Cancel All Tasks
    func cancelAllTasks() async {
        logger.log("Canceling all background tasks")

        await BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: backgroundTaskIdentifier)
        await BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: interventionTaskIdentifier)

        await MainActor.run {
            self.isScheduled = false
        }

        logger.log("All background tasks canceled")
    }
}
