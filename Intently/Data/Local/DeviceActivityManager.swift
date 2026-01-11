//
//  DeviceActivityManager.swift
//  Intently
//
//  Created on 2025-01-02.
//

import DeviceActivity
import FamilyControls
import SwiftUI
import os.log

// MARK: - Intervention Trigger Type
enum InterventionTrigger: CustomStringConvertible {
    case appLaunch                       // App was just launched
    case timeThreshold(duration: TimeInterval)  // Session exceeded threshold
    case quickReopen                     // User reopened quickly after closing
    case extendedSession(duration: TimeInterval) // Session is unusually long
    case goalExceeded                    // User exceeded their daily goal

    var description: String {
        switch self {
        case .appLaunch:
            return "appLaunch"
        case .timeThreshold(let duration):
            return "timeThreshold(\(Int(duration))ms)"
        case .quickReopen:
            return "quickReopen"
        case .extendedSession(let duration):
            return "extendedSession(\(Int(duration))ms)"
        case .goalExceeded:
            return "goalExceeded"
        }
    }
}

// MARK: - JitAI Monitoring State
struct JitAIMonitoringState {
    var isMonitoring: Bool = false
    var targetApps: Set<String> = []
    var lastInterventionTime: [String: Date] = [:]  // Per-app last intervention time
    var currentSessionStart: [String: Date] = [:]    // Per-app session start time
}

// MARK: - Device Activity Manager
@MainActor
class DeviceActivityManager: NSObject, ObservableObject {
    private let logger = Logger(subsystem: "dev.sadakat.intently", category: "DeviceActivity")

    @Published var isAuthorized = false
    @Published var isMonitoring = false
    @Published var authorizationError: String?

    // MARK: - JitAI Dependencies
    private weak var jitaiManager: JitaiInterventionManager?

    // MARK: - JitAI State
    private var jitaiState = JitAIMonitoringState()

    // MARK: - Constants
    private let minimumInterventionInterval: TimeInterval = 5 * 60  // 5 minutes between interventions
    private let quickReopenThreshold: TimeInterval = 2 * 60        // 2 minutes = quick reopen
    private let extendedSessionThreshold: TimeInterval = 20 * 60   // 20 minutes = extended session

    // MARK: - Initialization
    init(jitaiManager: JitaiInterventionManager? = nil) {
        self.jitaiManager = jitaiManager
        super.init()
        checkAuthorizationStatus()
    }

    // MARK: - Authorization
    func requestAuthorization() async -> Bool {
        logger.log("Requesting DeviceActivity authorization")

        let center = AuthorizationCenter.shared
        do {
            try await center.requestAuthorization(for: .child)
            await MainActor.run {
                self.isAuthorized = center.authorizationStatus == .approved
                if !self.isAuthorized {
                    self.authorizationError = "Authorization was not approved"
                }
            }
            logger.log("Authorization status: \(center.authorizationStatus.rawValue)")
            return isAuthorized
        } catch {
            await MainActor.run {
                self.authorizationError = error.localizedDescription
                self.isAuthorized = false
            }
            logger.error("Authorization failed: \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - Check Authorization
    func checkAuthorizationStatus() {
        let center = AuthorizationCenter.shared
        isAuthorized = center.authorizationStatus == .approved

        if case .notDetermined = center.authorizationStatus {
            logger.log("Authorization status: not determined")
        } else if case .approved = center.authorizationStatus {
            logger.log("Authorization status: approved")
        } else if case .denied = center.authorizationStatus {
            logger.log("Authorization status: denied")
        }
    }

    // MARK: - JitAI Monitoring

    /// Start JitAI monitoring for specified target apps
    /// - Parameters:
    ///   - targetApps: Set of app bundle identifiers to monitor
    ///   - schedule: DeviceActivitySchedule for monitoring periods
    func startJitaiMonitoring(
        targetApps: Set<String>,
        schedule: DeviceActivitySchedule
    ) async throws {
        guard isAuthorized else {
            logger.error("Cannot start monitoring: not authorized")
            throw DeviceActivityError.notAuthorized
        }

        logger.log("Starting JitAI monitoring for \(targetApps.count) apps")

        jitaiState.targetApps = targetApps
        jitaiState.isMonitoring = true
        isMonitoring = true

        // Initialize session tracking for all target apps
        for app in targetApps {
            jitaiState.currentSessionStart[app] = nil
            jitaiState.lastInterventionTime[app] = nil
        }

        logger.log("JitAI monitoring started successfully")
    }

    /// Stop JitAI monitoring
    func stopJitaiMonitoring() {
        logger.log("Stopping JitAI monitoring")

        jitaiState = JitAIMonitoringState()
        isMonitoring = false

        logger.log("JitAI monitoring stopped")
    }

    /// Trigger an intervention for a specific app
    /// - Parameters:
    ///   - app: Bundle identifier of the target app
    ///   - currentUsage: Current session duration in milliseconds
    ///   - triggerType: The type of trigger that caused this intervention
    func triggerIntervention(
        for app: String,
        currentUsage: TimeInterval,
        triggerType: InterventionTrigger
    ) async {
        guard jitaiState.isMonitoring else {
            logger.log("Not monitoring, skipping intervention trigger")
            return
        }

        guard jitaiState.targetApps.contains(app) else {
            logger.log("App \(app) not in target apps, skipping intervention")
            return
        }

        // Check minimum interval between interventions
        if let lastTime = jitaiState.lastInterventionTime[app] {
            let timeSinceLastIntervention = Date().timeIntervalSince(lastTime)
            if timeSinceLastIntervention < minimumInterventionInterval {
                logger.log("Minimum interval not met for \(app), skipping intervention")
                return
            }
        }

        // Determine intervention type based on trigger
        let interventionType: JitaiInterventionType
        switch triggerType {
        case .appLaunch, .quickReopen:
            interventionType = .reminder
        case .timeThreshold, .extendedSession, .goalExceeded:
            interventionType = .timer
        }

        logger.log("Triggering intervention for \(app) - trigger: \(triggerType), usage: \(currentUsage)ms")

        // Forward to JitAI manager
        guard let manager = jitaiManager else {
            logger.error("No JitAI manager available, cannot trigger intervention")
            return
        }

        // Check if we should show intervention using JitAI logic
        let shouldShow = await manager.shouldShowIntervention(
            for: app,
            currentUsage: currentUsage,
            interventionType: interventionType
        )

        if shouldShow {
            await manager.showIntervention(
                for: app,
                currentUsage: currentUsage,
                interventionType: interventionType
            )

            // Update last intervention time
            jitaiState.lastInterventionTime[app] = Date()
            logger.log("Intervention delivered for \(app)")
        } else {
            logger.log("Intervention blocked by JitAI logic for \(app)")
        }
    }

    /// Get session context for a specific app
    /// - Parameter app: Bundle identifier of the target app
    /// - Returns: Intervention context if available, nil otherwise
    func getSessionContext(for app: String) async -> InterventionContext? {
        guard jitaiState.isMonitoring else {
            return nil
        }

        // This would typically be called from the DeviceActivity extension
        // For now, we'll return a minimal context
        let calendar = Calendar.current
        let now = Date()

        return InterventionContext(
            timeOfDay: calendar.component(.hour, from: now),
            dayOfWeek: calendar.component(.weekday, from: now),
            isWeekend: calendar.component(.weekday, from: now) == 1 || calendar.component(.weekday, from: now) == 7,
            targetApp: app,
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
    }

    /// Record app launch event
    /// - Parameter app: Bundle identifier of the launched app
    func recordAppLaunch(for app: String) async {
        guard jitaiState.isMonitoring else { return }

        let now = Date()

        // Check if this is a quick reopen
        if let lastSessionEnd = jitaiState.currentSessionStart[app] {
            let timeSinceLastSession = now.timeIntervalSince(lastSessionEnd)
            if timeSinceLastSession < quickReopenThreshold {
                // Quick reopen detected
                logger.log("Quick reopen detected for \(app)")
                await triggerIntervention(
                    for: app,
                    currentUsage: 0,
                    triggerType: .quickReopen
                )
                return
            }
        }

        // Record session start
        jitaiState.currentSessionStart[app] = now

        // Trigger launch intervention
        await triggerIntervention(
            for: app,
            currentUsage: 0,
            triggerType: .appLaunch
        )
    }

    /// Record session end event
    /// - Parameters:
    ///   - app: Bundle identifier of the app
    ///   - duration: Session duration in milliseconds
    func recordSessionEnd(for app: String, duration: TimeInterval) async {
        guard jitaiState.isMonitoring else { return }

        jitaiState.currentSessionStart[app] = nil

        // Check if this was an extended session
        let durationMinutes = duration / (1000 * 60)
        if durationMinutes > extendedSessionThreshold {
            logger.log("Extended session detected for \(app): \(durationMinutes) minutes")

            // Trigger extended session intervention if user returns quickly
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                Task {
                    await self.triggerIntervention(
                        for: app,
                        currentUsage: duration,
                        triggerType: .extendedSession(duration: duration)
                    )
                }
            }
        }
    }

    /// Update session duration periodically
    /// - Parameters:
    ///   - app: Bundle identifier of the app
    ///   - duration: Current session duration in milliseconds
    func updateSessionDuration(for app: String, duration: TimeInterval) async {
        guard jitaiState.isMonitoring else { return }

        let durationMinutes = duration / (1000 * 60)

        // Check time threshold triggers (every 10 minutes)
        let threshold: TimeInterval = 10 * 60 * 1000  // 10 minutes in milliseconds
        if Int(duration) % Int(threshold) < Int(threshold) / 2 {
            await triggerIntervention(
                for: app,
                currentUsage: duration,
                triggerType: .timeThreshold(duration: duration)
            )
        }
    }

    /// Get current monitoring state
    func getMonitoringState() -> JitAIMonitoringState {
        return jitaiState
    }

    // MARK: - Get App Usage (from UserDefaults/Extension)
    func getAppUsage(for bundleIdentifier: String) async -> TimeInterval {
        // The DeviceActivity extension stores usage data in shared UserDefaults
        guard let sharedDefaults = UserDefaults(suiteName: "group.dev.sadakat.intently") else {
            return 0
        }

        let key = "usage_\(bundleIdentifier)"
        return TimeInterval(sharedDefaults.double(forKey: key))
    }

    // MARK: - Set App Usage (called by extension)
    func setAppUsage(for bundleIdentifier: String, minutes: TimeInterval) {
        guard let sharedDefaults = UserDefaults(suiteName: "group.dev.sadakat.intently") else {
            return
        }

        let key = "usage_\(bundleIdentifier)"
        sharedDefaults.set(minutes, forKey: key)
        sharedDefaults.synchronize()
    }

    // MARK: - Get All Tracked Apps Usage
    func getAllTrackedAppsUsage(bundleIdentifiers: [String]) async -> [String: TimeInterval] {
        var usage: [String: TimeInterval] = [:]

        for bundleId in bundleIdentifiers {
            usage[bundleId] = await getAppUsage(for: bundleId)
        }

        return usage
    }

    // MARK: - Update Total Usage
    func updateTodayUsage(_ minutes: Int) {
        guard let sharedDefaults = UserDefaults(suiteName: "group.dev.sadakat.intently") else {
            return
        }

        sharedDefaults.set(minutes, forKey: "todayUsage")
        sharedDefaults.set(Date(), forKey: "lastUpdate")
        sharedDefaults.synchronize()

        logger.log("Updated today's usage: \(minutes) minutes")
    }

    // MARK: - Get Today's Usage
    func getTodayUsage() -> Int {
        guard let sharedDefaults = UserDefaults(suiteName: "group.dev.sadakat.intently") else {
            return 0
        }

        return sharedDefaults.integer(forKey: "todayUsage")
    }
}

// MARK: - Device Activity Error
enum DeviceActivityError: LocalizedError {
    case notAuthorized
    case monitoringFailed(String)
    case fetchFailed(String)

    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Not authorized to access Screen Time data"
        case .monitoringFailed(let message):
            return "Failed to start monitoring: \(message)"
        case .fetchFailed(let message):
            return "Failed to fetch usage data: \(message)"
        }
    }
}

// MARK: - Authorization View
struct DeviceActivityAuthorizationView: View {
    @StateObject private var deviceActivityManager = DeviceActivityManager()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "chart.bar.fill")
                .font(.system(size: 60))
                .foregroundColor(.appPrimary)

            Text("Screen Time Access")
                .font(.title)
                .fontWeight(.bold)

            Text("Intently needs access to Screen Time data to track your app usage and help you achieve your goals.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.appTextSecondary)
                .padding(.horizontal)

            VStack(alignment: .leading, spacing: 12) {
                AuthorizationFeatureRow(icon: "lock.shield", title: "Privacy First", description: "Your data stays on your device")
                AuthorizationFeatureRow(icon: "chart.line.uptrend.xyaxis", title: "Track Usage", description: "See how much time you spend")
                AuthorizationFeatureRow(icon: "target", title: "Set Goals", description: "Achieve your daily limits")
            }
            .padding()

            Spacer()

            VStack(spacing: 12) {
                Button {
                    Task {
                        if await deviceActivityManager.requestAuthorization() {
                            dismiss()
                        }
                    }
                } label: {
                    Text("Authorize Screen Time")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.appPrimary)
                        .cornerRadius(12)
                }

                Button("Cancel") {
                    dismiss()
                }
                .foregroundColor(.appTextSecondary)
            }
            .padding()
        }
        .padding()
    }
}

struct AuthorizationFeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.appPrimary)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.appTextSecondary)
            }
        }
    }
}
