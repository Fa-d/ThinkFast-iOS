//
//  InterventionLiveActivityManager.swift
//  Intently
//
//  Created on 2025-01-11.
//  iOS 16.1+ Live Activities for intervention delivery
//

import Foundation
import SwiftUI
import ActivityKit

/// Intervention Live Activity Manager
/// Displays dynamic intervention hints on Lock Screen and StandBy
///
/// Live Activities provide:
/// - Dynamic Lock Screen updates
/// - StandBy display support
/// - Real-time intervention progress
/// - Dismissible with minimal effort
/// - Interactive buttons (iOS 16.2+)
///
/// Requirements:
/// - iOS 16.1+
/// - "Live Activities" capability enabled
/// - Live Activities entitlement in entitlements file
@available(iOS 16.1, *)
final class InterventionLiveActivityManager: ObservableObject {

    // MARK: - Published Properties
    @Published var activeActivities: [String: Date] = [:]
    @Published var isAvailable: Bool = false

    // MARK: - Dependencies
    private weak var jitaiManager: JitaiInterventionManager?

    // MARK: - Initialization
    init(jitaiManager: JitaiInterventionManager? = nil) {
        self.jitaiManager = jitaiManager
        checkAvailability()
    }

    // MARK: - Public Methods

    /// Check if Live Activities are available on this device
    /// - Returns: True if Live Activities are supported and authorized
    func checkAvailability() -> Bool {
        guard #available(iOS 16.1, *) else {
            logDebug("Live Activities require iOS 16.1+")
            return false
        }

        let available = ActivityAuthorizationInfo().areActivitiesEnabled
        isAvailable = available

        if available {
            logInfo("Live Activities are available")
        } else {
            logInfo("Live Activities are not available or not enabled")
        }

        return available
    }

    /// Request Live Activity authorization (iOS 16.2+)
    @available(iOS 16.2, *)
    func requestAuthorization() async throws -> Bool {
        // In iOS 16.2+, users must grant permission for Live Activities
        // The system automatically handles this, but we can check status
        let authInfo = ActivityAuthorizationInfo()

        if authInfo.areActivitiesEnabled {
            await MainActor.run {
                isAvailable = true
            }
            return true
        }

        return false
    }

    /// Start a Live Activity for intervention
    /// - Parameters:
    ///   - content: Intervention content
    ///   - context: Intervention context
    /// - Returns: Activity ID if started successfully
    @discardableResult
    func startLiveActivity(
        content: InterventionContentModel,
        context: InterventionContext
    ) async -> String? {
        guard checkAvailability() else {
            logDebug("Cannot start Live Activity - not available")
            return nil
        }

        // Create initial state
        let initialState = LiveActivityAttributes.ContentState(
            title: content.title,
            message: content.subtext,
            progress: nil,
            actionButtons: [
                LiveActivityButton(id: "take_break", title: content.actionLabel),
                LiveActivityButton(id: "continue", title: content.dismissLabel)
            ]
        )

        do {
            // Create the activity
            let activity = try Activity<LiveActivityAttributes>.request(
                attributes: LiveActivityAttributes(
                    targetApp: context.targetApp,
                    contentType: content.type.rawValue,
                    startTime: Date()
                ),
                content: .init(state: initialState, staleDate: nil)
            )

            let activityId = activity.id
            logInfo("Started Live Activity: \(activityId)")

            await MainActor.run {
                activeActivities[activityId] = Date()
            }

            return activityId
        } catch {
            logDebug("Failed to start Live Activity: \(error)")
            return nil
        }
    }

    /// Update an existing Live Activity
    /// - Parameters:
    ///   - id: Activity ID to update
    ///   - newState: New state to apply
    func updateLiveActivity(id: String, newState: LiveActivityAttributes.ContentState) async {
        guard checkAvailability() else { return }

        Task {
            for activity in Activity<LiveActivityAttributes>.activities {
                if activity.id == id {
                    await activity.update(ActivityContent(state: newState, staleDate: nil))

                    logDebug("Updated Live Activity: \(id)")
                    return
                }
            }
            logDebug("Live Activity not found for update: \(id)")
        }
    }

    /// Update Live Activity with session progress
    /// - Parameters:
    ///   - id: Activity ID
    ///   - currentMinutes: Current session duration
    ///   - goalMinutes: Goal duration
    ///   - message: Updated message
    func updateLiveActivityProgress(
        id: String,
        currentMinutes: Int,
        goalMinutes: Int?,
        message: String
    ) async {
        let progress: Double?
        if let goal = goalMinutes, goal > 0 {
            progress = Double(currentMinutes) / Double(goal)
        } else {
            progress = nil
        }

        let newState = LiveActivityAttributes.ContentState(
            title: "Session in Progress",
            message: message,
            progress: progress,
            actionButtons: [
                LiveActivityButton(id: "take_break", title: "Take a Break")
            ]
        )

        await updateLiveActivity(id: id, newState: newState)
    }

    /// End a Live Activity
    /// - Parameters:
    ///   - id: Activity ID to end
    ///   - dismissalPolicy: When to dismiss
    ///   - finalState: Optional final state to show
    func endLiveActivity(
        id: String,
        dismissalPolicy: DismissalPolicy = .default,
        finalState: LiveActivityAttributes.ContentState? = nil
    ) async {
        guard checkAvailability() else { return }

        Task {
            for activity in Activity<LiveActivityAttributes>.activities {
                if activity.id == id {
                    switch dismissalPolicy {
                    case .immediate:
                        await activity.end(using: nil, dismissalPolicy: .immediate)

                    case .after(let seconds):
                        let futureDate = Date().addingTimeInterval(seconds)
                        let finalContent = finalState.map { state in
                            ActivityContent(state: state, staleDate: futureDate)
                        }
                        await activity.end(finalContent, dismissalPolicy: .after(futureDate))

                    case .default:
                        let defaultFinal = finalState ?? LiveActivityAttributes.ContentState(
                            title: "Session Ended",
                            message: "Good choice!",
                            progress: nil,
                            actionButtons: []
                        )
                        let finalContent = ActivityContent(state: defaultFinal, staleDate: nil)
                        await activity.end(
                            finalContent,
                            dismissalPolicy: .default
                        )
                    }

                    logInfo("Ended Live Activity: \(id)")

                    await MainActor.run {
                        activeActivities.removeValue(forKey: id)
                    }

                    return
                }
            }
            logDebug("Live Activity not found for ending: \(id)")
        }
    }

    /// End all active Live Activities
    /// - Parameter dismissalPolicy: When to dismiss
    func endAllLiveActivities(dismissalPolicy: DismissalPolicy = .immediate) async {
        guard checkAvailability() else { return }

        let ids = Array(activeActivities.keys)

        for id in ids {
            await endLiveActivity(id: id, dismissalPolicy: dismissalPolicy)
        }

        logInfo("Ended \(ids.count) Live Activities")
    }

    /// Get count of active Live Activities
    /// - Returns: Number of active activities
    func getActiveCount() async -> Int {
        return activeActivities.count
    }

    /// Check if a specific Live Activity is still active
    /// - Parameter id: Activity ID to check
    /// - Returns: True if activity is still active
    func isActivityActive(id: String) -> Bool {
        return activeActivities[id] != nil
    }

    // MARK: - Logging

    private func logDebug(_ message: String) {
        #if DEBUG
        print("[InterventionLiveActivityManager] DEBUG: \(message)")
        #endif
    }

    private func logInfo(_ message: String) {
        print("[InterventionLiveActivityManager] INFO: \(message)")
    }
}

// MARK: - Live Activity Attributes

struct LiveActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var title: String
        var message: String
        var progress: Double?
        var actionButtons: [LiveActivityButton]

        func hash(into hasher: inout Hasher) {
            hasher.combine(title)
            hasher.combine(message)
            hasher.combine(progress)
            hasher.combine(actionButtons)
        }

        static func == (lhs: ContentState, rhs: ContentState) -> Bool {
            return lhs.title == rhs.title &&
                   lhs.message == rhs.message &&
                   lhs.progress == rhs.progress &&
                   lhs.actionButtons == rhs.actionButtons
        }
    }

    let targetApp: String
    let contentType: String
    let startTime: Date
}

// MARK: - Live Activity Button

struct LiveActivityButton: Codable, Identifiable, Hashable {
    let id: String
    let title: String

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(title)
    }

    static func == (lhs: LiveActivityButton, rhs: LiveActivityButton) -> Bool {
        return lhs.id == rhs.id && lhs.title == rhs.title
    }
}

// MARK: - Dismissal Policy

enum DismissalPolicy {
    case immediate                      // Dismiss immediately
    case after(TimeInterval)            // Dismiss after delay
    case `default`                      // Use system default (approx 4 hours)
}

// MARK: - Live Activity View (for Lock Screen display)
// TODO: Implement Live Activity UI view
// This requires ActivityViewContext from ActivityKit and SwiftUI setup

/*
@available(iOS 16.1, *)
struct InterventionLiveActivityView: View {
    let context: ActivityViewContext<LiveActivityAttributes>

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(context.state.title)
                .font(.headline)
                .foregroundColor(.primary)

            Text(context.state.message)
                .font(.subheadline)
                .foregroundColor(.secondary)

            if let progress = context.state.progress {
                ProgressView(value: progress)
                    .progressViewStyle(.linear)
            }

            HStack(spacing: 8) {
                ForEach(context.state.actionButtons) { button in
                    Text(button.title)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(8)
                }
            }
        }
        .padding(12)
    }
}
*/

// MARK: - Dynamic Island Layout (iOS 16.2+)
// Note: Dynamic Island implementation requires additional setup
// This is a placeholder for future implementation

/*
@available(iOS 16.2, *)
struct InterventionDynamicIsland {
    let context: ActivityViewContext<LiveActivityAttributes>

    // TODO: Implement Dynamic Island UI
    // Requires: DynamicIsland region configuration and custom UI
}
*/
