//
//  JitaiInterventionManager.swift
//  Intently
//
//  Created on 2025-01-07.
//  JITAI-enabled Intervention Manager
//

import Foundation
import SwiftUI

/// JITAI-enabled Intervention Manager
///
/// This manager integrates all JITAI components to provide intelligent,
/// personalized intervention timing and content selection.
final class JitaiInterventionManager: ObservableObject {

    // MARK: - Published Properties
    @Published var currentIntervention: InterventionContentModel?
    @Published var isShowingIntervention = false
    @Published var lastRateLimitResult: AdaptiveRateLimitResult?

    // MARK: - Dependencies
    private let personaDetector: PersonaDetector
    private let opportunityDetector: OpportunityDetector
    private let personaAwareContentSelector: PersonaAwareContentSelector
    private let adaptiveRateLimiter: AdaptiveInterventionRateLimiter
    private let interventionResultRepository: InterventionResultRepository
    private let goalRepository: GoalRepository
    private let usageRepository: UsageRepository
    private let userDefaults: UserDefaults

    // MARK: - State
    private var currentSessionStart: Date?
    private var currentSessionApp: String?
    private var lastDecisionContext: InterventionContext?

    // MARK: - Initialization
    init(
        personaDetector: PersonaDetector,
        opportunityDetector: OpportunityDetector,
        personaAwareContentSelector: PersonaAwareContentSelector,
        adaptiveRateLimiter: AdaptiveInterventionRateLimiter,
        interventionResultRepository: InterventionResultRepository,
        goalRepository: GoalRepository,
        usageRepository: UsageRepository,
        userDefaults: UserDefaults = .standard
    ) {
        self.personaDetector = personaDetector
        self.opportunityDetector = opportunityDetector
        self.personaAwareContentSelector = personaAwareContentSelector
        self.adaptiveRateLimiter = adaptiveRateLimiter
        self.interventionResultRepository = interventionResultRepository
        self.goalRepository = goalRepository
        self.usageRepository = usageRepository
        self.userDefaults = userDefaults
    }

    // MARK: - Public Methods

    /// Check if we should show an intervention for the given app
    /// - Parameters:
    ///   - app: Target app bundle ID
    ///   - currentUsage: Current session duration in milliseconds
    ///   - interventionType: Type of intervention to check for
    /// - Returns: True if intervention should be shown
    func shouldShowIntervention(
        for app: String,
        currentUsage: TimeInterval,
        interventionType: JitaiInterventionType = .reminder
    ) async -> Bool {
        // Build intervention context
        guard let context = await buildInterventionContext(
            targetApp: app,
            currentUsage: currentUsage,
            interventionType: interventionType
        ) else {
            logDebug("Failed to build intervention context")
            return false
        }

        // Check if we should show intervention using JITAI logic
        let rateLimitResult = await adaptiveRateLimiter.canShowIntervention(
            interventionContext: context,
            interventionType: interventionType,
            sessionDurationMs: currentUsage
        )

        self.lastRateLimitResult = rateLimitResult

        if rateLimitResult.allowed {
            logInfo("Intervention approved: \(rateLimitResult.reason)")
            return true
        } else {
            logDebug("Intervention blocked: \(rateLimitResult.reason)")
            return false
        }
    }

    /// Get and show intervention content
    /// - Parameters:
    ///   - app: Target app bundle ID
    ///   - currentUsage: Current session duration in milliseconds
    ///   - interventionType: Type of intervention
    @MainActor
    func showIntervention(
        for app: String,
        currentUsage: TimeInterval,
        interventionType: JitaiInterventionType = .reminder
    ) async {
        // Build intervention context
        guard let context = await buildInterventionContext(
            targetApp: app,
            currentUsage: currentUsage,
            interventionType: interventionType
        ) else {
            logDebug("Failed to build intervention context")
            return
        }

        // Select content using persona-aware selector
        let contentSelection = await personaAwareContentSelector.selectContent(
            context: context,
            interventionType: interventionType
        )

        // Generate actual content
        let contentSelector = ContentSelector()
        let content = contentSelector.generateContentByType(
            contentTypeName: contentSelection.contentType.rawValue,
            context: context
        )

        // Store context for later use
        self.lastDecisionContext = context
        self.currentIntervention = content
        self.isShowingIntervention = true

        logInfo("Showing intervention: \(contentSelection.contentType.rawValue)")
        logDebug("Selection reason: \(contentSelection.selectionReason)")
    }

    /// Handle user's response to intervention
    /// - Parameters:
    ///   - choice: User's choice ("continue", "quit", "skip")
    ///   - sessionDuration: Total session duration
    @MainActor
    func handleResponse(
        choice: String,
        sessionDuration: TimeInterval
    ) async {
        guard let context = lastDecisionContext,
              let intervention = currentIntervention else {
            logDebug("No intervention context available")
            dismissIntervention()
            return
        }

        // Record intervention result with JITAI context
        let result = InterventionResult(
            sessionId: UUID(),
            targetApp: context.targetApp,
            interventionType: intervention.type.rawValue,
            contentType: intervention.content,
            userChoice: choice,
            feedbackTimestamp: Date(),
            sessionDuration: sessionDuration,
            wasEffective: choice == "quit",
            timeOfDay: getTimeOfDay(),
            hourOfDay: context.timeOfDay,
            streakAtTime: context.streakDays,
            goalProgressAtTime: context.goalMinutes,
            quickReopen: context.quickReopenAttempt,
            opportunityScore: lastRateLimitResult?.opportunityScore ?? 0,
            opportunityLevel: lastRateLimitResult?.opportunityLevel?.rawValue ?? "",
            persona: lastRateLimitResult?.persona?.rawValue ?? "",
            decisionSource: lastRateLimitResult?.decisionSource ?? ""
        )

        do {
            try await interventionResultRepository.saveResult(result)
            logInfo("Recorded intervention result: \(choice)")
        } catch {
            logDebug("Failed to save intervention result: \(error)")
        }

        // Record that intervention was shown for rate limiting
        adaptiveRateLimiter.recordIntervention(
            interventionType: context.isExtendedSession ? .timer : .reminder
        )

        dismissIntervention()
    }

    /// Dismiss the current intervention
    @MainActor
    func dismissIntervention() {
        isShowingIntervention = false
        currentIntervention = nil
        lastDecisionContext = nil
    }

    /// Get current detected persona
    func getCurrentPersona() async -> UserPersona? {
        let detected = await personaDetector.detectPersona()
        return detected.persona
    }

    /// Force refresh persona detection
    func refreshPersona() async {
        await personaDetector.detectPersona(forceRefresh: true)
    }

    /// Clear all JITAI caches
    func clearCaches() async {
        await personaDetector.clearCache()
        await opportunityDetector.clearCache()
    }

    // MARK: - Private Methods

    /// Build intervention context from current state
    private func buildInterventionContext(
        targetApp: String,
        currentUsage: TimeInterval,
        interventionType: JitaiInterventionType
    ) async -> InterventionContext? {
        // Get goal for this app
        guard let goal = try? await goalRepository.getGoal(for: targetApp) else {
            logDebug("No goal found for app: \(targetApp)")
            return nil
        }

        // Get session data
        let today = Date()
        let sessions = (try? await usageRepository.getSessionsInRange(
            startDate: formatDate(today),
            endDate: formatDate(today)
        )) ?? []

        // Calculate session stats
        let sessionCount = sessions.filter { $0.targetApp == targetApp }.count

        // Get yesterday's usage
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today) ?? today
        let yesterdaySessions = (try? await usageRepository.getSessionsInRange(
            startDate: formatDate(yesterday),
            endDate: formatDate(yesterday)
        )) ?? []
        let yesterdayUsage = yesterdaySessions
            .filter { $0.targetApp == targetApp }
            .reduce(Int64(0)) { $0 + Int64((($1.endTimestamp ?? $1.startTimestamp).timeIntervalSince($1.startTimestamp)) * 1000) }

        // Get weekly average
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: today) ?? today
        let weekSessions = (try? await usageRepository.getSessionsInRange(
            startDate: formatDate(weekAgo),
            endDate: formatDate(today)
        )) ?? []
        let weekUsage = weekSessions
            .filter { $0.targetApp == targetApp }
            .reduce(Int64(0)) { $0 + Int64((($1.endTimestamp ?? $1.startTimestamp).timeIntervalSince($1.startTimestamp)) * 1000) }
        let weeklyAverage = weekUsage > 0 ? weekUsage / 7 : 0

        // Get last session end time
        let appSessions = sessions.filter { $0.targetApp == targetApp }
            .sorted { $0.startTimestamp > $1.startTimestamp }
        let lastSessionEnd = appSessions.dropFirst().first?.endTimestamp.map { Int64($0.timeIntervalSince1970 * 1000) } ?? 0

        // Get best session (shortest)
        let bestSession = appSessions
            .compactMap { session -> Int? in
                guard let end = session.endTimestamp else { return nil }
                let duration = end.timeIntervalSince(session.startTimestamp)
                return duration > 0 ? Int(duration / 60) : nil
            }
            .min() ?? 0

        // Get install date
        let installDate = userDefaults.object(forKey: "installDate") as? Date

        let totalUsageToday = appSessions.reduce(Int64(0)) { total, session in
            let duration = (session.endTimestamp ?? session.startTimestamp).timeIntervalSince(session.startTimestamp)
            return total + Int64(duration * 1000)
        }

        return InterventionContext.create(
            targetApp: targetApp,
            currentSessionDuration: currentUsage,
            sessionCount: sessionCount,
            lastSessionEndTime: lastSessionEnd,
            totalUsageToday: totalUsageToday,
            totalUsageYesterday: yesterdayUsage,
            weeklyAverage: weeklyAverage,
            goalMinutes: goal.dailyLimitMinutes,
            streakDays: goal.currentStreak,
            installDate: installDate,
            bestSessionMinutes: bestSession
        )
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    private func getTimeOfDay() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "morning"
        case 12..<17: return "afternoon"
        case 17..<21: return "evening"
        default: return "night"
        }
    }

    // MARK: - Logging

    private func logDebug(_ message: String) {
        #if DEBUG
        print("[JitaiInterventionManager] DEBUG: \(message)")
        #endif
    }

    private func logInfo(_ message: String) {
        print("[JitaiInterventionManager] INFO: \(message)")
    }
}
