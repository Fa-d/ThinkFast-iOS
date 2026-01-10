//
//  AnalyticsManager.swift
//  Intently
//
//  Created on 2025-01-01.
//

import Foundation
import FirebaseAnalytics

// MARK: - Analytics Manager
class AnalyticsManager {
    static let shared = AnalyticsManager()

    private init() {}

    // MARK: - Setup
    func setup() {
        // Firebase Analytics is automatically configured by FirebaseApp.configure()
    }

    // MARK: - Screen Tracking
    func trackScreen(_ screenName: String) {
        let eventName = "screen_view"
        let parameters: [String: Any] = [
            "screen_name": screenName,
            "screen_class": screenName
        ]
        logEvent(eventName, parameters: parameters)
    }

    // MARK: - User Actions
    func trackAppOpen() {
        logEvent("app_open")
    }

    func trackOnboardingStarted() {
        logEvent("onboarding_started")
    }

    func trackOnboardingCompleted() {
        logEvent("onboarding_completed")
    }

    func trackOnboardingStep(step: Int, stepName: String) {
        logEvent("onboarding_step_\(step)", parameters: ["step_name": stepName])
    }

    // MARK: - Goal Events
    func trackGoalSet(for app: String, limit: Int) {
        logEvent("goal_set", parameters: [
            "app_name": app,
            "daily_limit": limit
        ])
    }

    func trackGoalUpdated(for app: String, oldLimit: Int, newLimit: Int) {
        logEvent("goal_updated", parameters: [
            "app_name": app,
            "old_limit": oldLimit,
            "new_limit": newLimit
        ])
    }

    func trackGoalDeleted(for app: String) {
        logEvent("goal_deleted", parameters: ["app_name": app])
    }

    func trackGoalExceeded(for app: String, used: Int, limit: Int) {
        logEvent("goal_exceeded", parameters: [
            "app_name": app,
            "used_minutes": used,
            "limit_minutes": limit,
            "exceeded_by": used - limit
        ])
    }

    func trackGoalAchieved(for app: String) {
        logEvent("goal_achieved", parameters: ["app_name": app])
    }

    // MARK: - Streak Events
    func trackStreakStarted(for app: String) {
        logEvent("streak_started", parameters: ["app_name": app])
    }

    func trackStreakBroken(for app: String, streakLength: Int) {
        logEvent("streak_broken", parameters: [
            "app_name": app,
            "streak_length": streakLength
        ])
    }

    func trackStreakRecovered(for app: String, streakLength: Int) {
        logEvent("streak_recovered", parameters: [
            "app_name": app,
            "streak_length": streakLength
        ])
    }

    func trackStreakMilestone(for app: String, streak: Int, milestone: String) {
        logEvent("streak_milestone", parameters: [
            "app_name": app,
            "streak": streak,
            "milestone": milestone
        ])
    }

    // MARK: - Intervention Events
    func trackInterventionShown(
        for app: String,
        type: String,
        contentType: String
    ) {
        logEvent("intervention_shown", parameters: [
            "app_name": app,
            "intervention_type": type,
            "content_type": contentType
        ])
    }

    func trackInterventionResponse(
        for app: String,
        type: String,
        response: String,
        sessionDuration: TimeInterval
    ) {
        logEvent("intervention_response", parameters: [
            "app_name": app,
            "intervention_type": type,
            "user_choice": response,
            "session_duration": sessionDuration
        ])
    }

    func trackInterventionDismissed(for app: String, type: String) {
        logEvent("intervention_dismissed", parameters: [
            "app_name": app,
            "intervention_type": type
        ])
    }

    // MARK: - Session Events
    func trackSessionStarted(for app: String) {
        logEvent("session_started", parameters: ["app_name": app])
    }

    func trackSessionEnded(
        for app: String,
        duration: TimeInterval,
        wasInterrupted: Bool,
        interventionCount: Int
    ) {
        logEvent("session_ended", parameters: [
            "app_name": app,
            "duration_seconds": duration,
            "was_interrupted": wasInterrupted,
            "intervention_count": interventionCount
        ])
    }

    // MARK: - Achievement Events
    func trackAchievementUnlocked(_ achievementId: String, title: String) {
        logEvent("achievement_unlocked", parameters: [
            "achievement_id": achievementId,
            "achievement_title": title
        ])
    }

    // MARK: - Settings Events
    func trackNotificationToggled(enabled: Bool) {
        logEvent("notification_toggled", parameters: ["enabled": enabled])
    }

    func trackInterventionFrequencyChanged(to: String) {
        logEvent("intervention_frequency_changed", parameters: ["frequency": to])
    }

    func trackAppearanceChanged(to: String) {
        logEvent("appearance_changed", parameters: ["mode": to])
    }

    // MARK: - Achievement View
    func trackAchievementViewed(achievementId: String) {
        logEvent("achievement_viewed", parameters: ["achievement_id": achievementId])
    }

    // MARK: - Helper
    private func logEvent(_ name: String, parameters: [String: Any]? = nil) {
        #if DEBUG
        print("[Analytics] \(name): \(parameters ?? [:])")
        #endif

        Analytics.logEvent(name, parameters: parameters)
    }
}

// MARK: - Event Names
enum AnalyticsEvent {
    static let appOpen = "app_open"
    static let onboardingCompleted = "onboarding_completed"
    static let goalSet = "goal_set"
    static let goalAchieved = "goal_achieved"
    static let streakStarted = "streak_started"
    static let interventionShown = "intervention_shown"
    static let sessionEnded = "session_ended"
    static let achievementUnlocked = "achievement_unlocked"
}
