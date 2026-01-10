//
//  NotificationManager.swift
//  Intently
//
//  Created on 2025-01-01.
//

import Foundation
import UserNotifications

final class NotificationManager: ObservableObject {
    static let shared = NotificationManager()

    @Published var isAuthorized = false
    @Published var notificationEnabled = true

    private let center = UNUserNotificationCenter.current()

    // MARK: - Authorization
    func requestAuthorization() async throws {
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
        let granted = try await center.requestAuthorization(options: options)

        await MainActor.run {
            self.isAuthorized = granted
            self.notificationEnabled = granted
        }
    }

    // MARK: - Check Authorization Status
    func checkAuthorizationStatus() async -> Bool {
        let settings = await center.notificationSettings()
        return settings.authorizationStatus == .authorized
    }

    // MARK: - Schedule Notifications
    func scheduleReminder(title: String, body: String, at: Date) async throws {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.badge = 1

        let triggerDate = Calendar.current.dateComponents([.hour, .minute], from: at)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: true)

        let request = UNNotificationRequest(
            identifier: "daily-reminder",
            content: content,
            trigger: trigger
        )

        try await center.add(request)
    }

    // MARK: - Streak Recovery Notification
    func sendStreakRecoveryNotification(for app: String, recoveryDays: Int, totalDays: Int) async throws {
        let content = UNMutableNotificationContent()
        content.title = "Streak Recovery Progress"
        content.body = "\(recoveryDays)/\(totalDays) days to recover your \(app) streak!"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)

        let request = UNNotificationRequest(
            identifier: "streak-recovery-\(app)",
            content: content,
            trigger: trigger
        )

        try await center.add(request)
    }

    // MARK: - Goal Exceeded Notification
    func sendGoalExceededNotification(for app: String, usedMinutes: Int, limitMinutes: Int) async throws {
        let content = UNMutableNotificationContent()
        content.title = "Goal Exceeded"
        content.body = "You've used \(app) for \(usedMinutes) minutes today (limit: \(limitMinutes)min)"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)

        let request = UNNotificationRequest(
            identifier: "goal-exceeded-\(app)",
            content: content,
            trigger: trigger
        )

        try await center.add(request)
    }

    // MARK: - Streak Achieved Notification
    func sendStreakAchievedNotification(for app: String, streak: Int) async throws {
        let content = UNMutableNotificationContent()
        content.title = "🔥 Streak Achieved!"
        content.body = "\(streak) days on \(app)! Keep it up!"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)

        let request = UNNotificationRequest(
            identifier: "streak-\(app)-\(streak)",
            content: content,
            trigger: trigger
        )

        try await center.add(request)
    }

    // MARK: - Cancel All
    func cancelAllNotifications() async {
        center.removeAllPendingNotificationRequests()
        center.removeAllDeliveredNotifications()
    }

    // MARK: - Cancel Specific
    func cancelNotification(with identifier: String) async {
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    // MARK: - Get Pending Count
    func getPendingCount() async -> Int {
        let requests = await center.pendingNotificationRequests()
        return requests.count
    }
}

// MARK: - Notification Categories
extension NotificationManager {
    func setupCategories() async throws {
        // Streak recovery action
        let recoveryAction = UNNotificationAction(
            identifier: "VIEW_PROGRESS",
            title: "View Progress",
            options: .foreground
        )

        let recoveryCategory = UNNotificationCategory(
            identifier: "STREAK_RECOVERY",
            actions: [recoveryAction],
            intentIdentifiers: []
        )

        // Goal exceeded action
        let quitAction = UNNotificationAction(
            identifier: "QUIT_APP",
            title: "I'll Stop",
            options: .foreground
        )

        let continueAction = UNNotificationAction(
            identifier: "CONTINUE",
            title: "Continue Anyway",
            options: []
        )

        let goalCategory = UNNotificationCategory(
            identifier: "GOAL_EXCEEDED",
            actions: [quitAction, continueAction],
            intentIdentifiers: []
        )

        try await center.setNotificationCategories([recoveryCategory, goalCategory])
    }
}
