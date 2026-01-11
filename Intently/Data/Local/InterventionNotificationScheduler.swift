//
//  InterventionNotificationScheduler.swift
//  Intently
//
//  Created on 2025-01-11.
//  iOS-specific intervention delivery via notifications
//

import Foundation
import UserNotifications

/// Intervention Notification Scheduler
/// Delivers interventions via iOS push notifications
///
/// Since iOS doesn't allow overlay-style interventions like Android,
/// we use UNUserNotificationCenter with:
/// - Rich notifications with action buttons
/// - Time Sensitive notifications for urgent interventions
/// - Category-based actions for user interaction
/// - Critical alerts (requires entitlement) for high-stakes moments
final class InterventionNotificationScheduler: NSObject, ObservableObject {

    // MARK: - Published Properties
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published var pendingInterventions: [PendingIntervention] = []

    // MARK: - Constants
    private let interventionCategoryIdentifier = "INTERVENTION_CATEGORY"
    private let timeSensitiveIdentifier = "TIME_SENSITIVE"

    // Action identifiers
    private let actionTakeBreak = "ACTION_TAKE_BREAK"
    private let actionContinue = "ACTION_CONTINUE"
    private let actionSnooze = "ACTION_SNOOZE"

    // MARK: - Dependencies
    private let center: UNUserNotificationCenter
    private weak var jitaiManager: JitaiInterventionManager?

    // MARK: - Initialization
    init(jitaiManager: JitaiInterventionManager? = nil) {
        self.center = UNUserNotificationCenter.current()
        self.jitaiManager = jitaiManager
        super.init()

        center.delegate = self
        setupNotificationCategories()
        checkAuthorizationStatus()
    }

    // MARK: - Public Methods

    /// Request notification authorization
    /// - Returns: True if authorization was granted
    func requestAuthorization() async throws -> Bool {
        let options: UNAuthorizationOptions = [.alert, .sound, .badge, .criticalAlert]

        let granted = try await center.requestAuthorization(options: options)

        await MainActor.run {
            authorizationStatus = granted ? .authorized : .denied
        }

        if granted {
            logInfo("Notification authorization granted")
        } else {
            logInfo("Notification authorization denied")
        }

        return granted
    }

    /// Schedule an intervention notification
    /// - Parameters:
    ///   - content: Intervention content model
    ///   - context: Intervention context
    ///   - scheduledFor: When to deliver (nil = immediate)
    func scheduleIntervention(
        content: InterventionContentModel,
        context: InterventionContext,
        scheduledFor: Date? = nil
    ) {
        let identifier = "intervention_\(UUID().uuidString)"
        let triggerDate = scheduledFor ?? Date()

        // Create notification content
        let notificationContent = UNMutableNotificationContent()
        notificationContent.title = content.title
        notificationContent.body = content.subtext
        notificationContent.sound = .default
        notificationContent.categoryIdentifier = interventionCategoryIdentifier
        notificationContent.userInfo = [
            "sessionId": context.targetApp,
            "targetApp": context.targetApp,
            "contentType": content.type.rawValue,
            "interventionId": identifier
        ]

        // Set interruption level based on urgency
        if context.isOverGoal || context.isExtendedSession {
            notificationContent.interruptionLevel = .timeSensitive
        } else {
            notificationContent.interruptionLevel = .active
        }

        // Create trigger
        let trigger: UNNotificationTrigger
        if let scheduledFor = scheduledFor, scheduledFor > Date() {
            let triggerDate = scheduledFor
            trigger = UNTimeIntervalNotificationTrigger(
                timeInterval: triggerDate.timeIntervalSinceNow,
                repeats: false
            )
        } else {
            trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        }

        // Schedule request
        let request = UNNotificationRequest(
            identifier: identifier,
            content: notificationContent,
            trigger: trigger
        )

        center.add(request) { error in
            if let error = error {
                self.logDebug("Failed to schedule notification: \(error)")
            } else {
                self.logInfo("Scheduled intervention notification: \(identifier)")

                // Track as pending
                Task { @MainActor in
                    self.pendingInterventions.append(PendingIntervention(
                        id: UUID(),
                        content: content,
                        scheduledFor: triggerDate,
                        context: context
                    ))
                }
            }
        }
    }

    /// Send an immediate intervention notification
    /// - Parameter content: Intervention content to deliver
    func sendImmediateIntervention(content: InterventionContentModel) {
        // Create a minimal context
        let context = InterventionContext(
            timeOfDay: Calendar.current.component(.hour, from: Date()),
            dayOfWeek: Calendar.current.component(.weekday, from: Date()),
            isWeekend: false,
            targetApp: "unknown",
            currentSessionMinutes: 0,
            sessionCount: 1,
            lastSessionEndTime: 0,
            timeSinceLastSession: 0,
            quickReopenAttempt: false,
            totalUsageToday: 0,
            totalUsageYesterday: 0,
            weeklyAverage: 0,
            goalMinutes: nil,
            isOverGoal: false,
            streakDays: 0,
            userFrictionLevel: .gentle,
            daysSinceInstall: 0,
            bestSessionMinutes: 0
        )

        scheduleIntervention(content: content, context: context, scheduledFor: nil)
    }

    /// Handle notification response
    /// - Parameters:
    ///   - identifier: Notification identifier
    ///   - choice: User's choice (take_break, continue, snooze)
    func handleNotificationResponse(identifier: String, choice: String) async {
        logInfo("Handling notification response: \(identifier) -> \(choice)")

        // Remove from pending
        await MainActor.run {
            pendingInterventions.removeAll { $0.id.uuidString.contains(identifier) }
        }

        // Forward to JitAI manager if available
        guard let manager = jitaiManager else {
            logDebug("No JitAI manager available to handle response")
            return
        }

        // Map choice to expected format
        let mappedChoice: String
        switch choice.lowercased() {
        case actionTakeBreak.lowercased():
            mappedChoice = "GO_BACK"
        case actionContinue.lowercased():
            mappedChoice = "continue"
        case actionSnooze.lowercased():
            mappedChoice = "snooze"
        default:
            mappedChoice = choice
        }

        await manager.handleResponse(choice: mappedChoice, sessionDuration: 0)
    }

    /// Cancel all pending intervention notifications
    func cancelPendingInterventions() {
        center.getPendingNotificationRequests { requests in
            let interventionRequests = requests.filter {
                $0.identifier.hasPrefix("intervention_")
            }

            self.center.removePendingNotificationRequests(
                withIdentifiers: interventionRequests.map { $0.identifier }
            )

            Task { @MainActor in
                self.pendingInterventions.removeAll()
            }

            self.logInfo("Cancelled \(interventionRequests.count) pending interventions")
        }
    }

    /// Cancel a specific notification
    /// - Parameter identifier: Notification identifier to cancel
    func cancelNotification(identifier: String) {
        center.removePendingNotificationRequests(withIdentifiers: [identifier])

        Task { @MainActor in
            pendingInterventions.removeAll { $0.id.uuidString.contains(identifier) }
        }

        logDebug("Cancelled notification: \(identifier)")
    }

    /// Get number of pending notifications
    /// - Returns: Count of pending intervention notifications
    func getPendingCount() async -> Int {
        return await withCheckedContinuation { continuation in
            center.getPendingNotificationRequests { requests in
                let count = requests.filter { $0.identifier.hasPrefix("intervention_") }.count
                continuation.resume(returning: count)
            }
        }
    }

    // MARK: - Private Methods

    private func setupNotificationCategories() {
        // Define actions
        let takeBreakAction = UNNotificationAction(
            identifier: actionTakeBreak,
            title: "Take a Break",
            options: [.foreground]
        )

        let continueAction = UNNotificationAction(
            identifier: actionContinue,
            title: "Continue",
            options: []
        )

        let snoozeAction = UNNotificationAction(
            identifier: actionSnooze,
            title: "Snooze 5 min",
            options: []
        )

        // Create category
        let category = UNNotificationCategory(
            identifier: interventionCategoryIdentifier,
            actions: [takeBreakAction, snoozeAction, continueAction],
            intentIdentifiers: [],
            options: []
        )

        center.setNotificationCategories([category])
        logDebug("Notification categories configured")
    }

    private func checkAuthorizationStatus() {
        center.getNotificationSettings { settings in
            Task { @MainActor in
                self.authorizationStatus = settings.authorizationStatus
            }
        }
    }

    // MARK: - Logging

    private func logDebug(_ message: String) {
        #if DEBUG
        print("[InterventionNotificationScheduler] DEBUG: \(message)")
        #endif
    }

    private func logInfo(_ message: String) {
        print("[InterventionNotificationScheduler] INFO: \(message)")
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension InterventionNotificationScheduler: UNUserNotificationCenterDelegate {

    /// Called when app is in foreground and notification is delivered
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound])
    }

    /// Called when user responds to notification action
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let identifier = response.notification.request.identifier
        let actionIdentifier = response.actionIdentifier

        Task {
            // Handle the response
            if actionIdentifier == UNNotificationDefaultActionIdentifier {
                // User tapped the notification (default action)
                await handleNotificationResponse(identifier: identifier, choice: "opened")
            } else if actionIdentifier == UNNotificationDismissActionIdentifier {
                // User dismissed the notification
                await handleNotificationResponse(identifier: identifier, choice: "dismissed")
            } else {
                // User tapped an action button
                await handleNotificationResponse(identifier: identifier, choice: actionIdentifier)
            }
        }

        completionHandler()
    }
}

// MARK: - Pending Intervention

struct PendingIntervention: Identifiable {
    let id: UUID
    let content: InterventionContentModel
    let scheduledFor: Date
    let context: InterventionContext

    var isOverdue: Bool {
        return scheduledFor < Date()
    }

    var timeUntilDelivery: TimeInterval {
        return scheduledFor.timeIntervalSinceNow
    }
}
