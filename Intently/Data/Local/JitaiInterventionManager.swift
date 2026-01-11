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
///
/// Enhanced with:
/// - Burden tracking for fatigue management
/// - Thompson Sampling for optimal content selection
/// - Comprehensive outcome tracking
/// - Decision logging for analytics
final class JitaiInterventionManager: ObservableObject {

    // MARK: - Published Properties
    @Published var currentIntervention: InterventionContentModel?
    @Published var isShowingIntervention = false
    @Published var lastRateLimitResult: AdaptiveRateLimitResult?
    @Published var currentBurdenLevel: BurdenLevel = .moderate
    @Published var currentDecision: InterventionDecisionFull?

    // MARK: - Dependencies
    private let personaDetector: PersonaDetector
    private let opportunityDetector: OpportunityDetector
    private let personaAwareContentSelector: PersonaAwareContentSelector
    private let adaptiveRateLimiter: AdaptiveInterventionRateLimiter
    private let interventionResultRepository: InterventionResultRepository
    private let goalRepository: GoalRepository
    private let usageRepository: UsageRepository
    private let userDefaults: UserDefaults

    // NEW: Advanced JITAI components
    private let burdenTracker: InterventionBurdenTracker
    private let thompsonSamplingEngine: ThompsonSamplingEngine
    private let outcomeTracker: ComprehensiveOutcomeTracker
    private let decisionLogger: DecisionLogger

    // Delivery components (accessed via container to avoid circular dependency)
    private var notificationScheduler: InterventionNotificationScheduler {
        AppDependencyContainer.shared.notificationScheduler
    }
    private var liveActivityManager: InterventionLiveActivityManager {
        AppDependencyContainer.shared.liveActivityManager
    }

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
        burdenTracker: InterventionBurdenTracker,
        thompsonSamplingEngine: ThompsonSamplingEngine,
        outcomeTracker: ComprehensiveOutcomeTracker,
        decisionLogger: DecisionLogger,
        userDefaults: UserDefaults = .standard
    ) {
        self.personaDetector = personaDetector
        self.opportunityDetector = opportunityDetector
        self.personaAwareContentSelector = personaAwareContentSelector
        self.adaptiveRateLimiter = adaptiveRateLimiter
        self.interventionResultRepository = interventionResultRepository
        self.goalRepository = goalRepository
        self.usageRepository = usageRepository
        self.burdenTracker = burdenTracker
        self.thompsonSamplingEngine = thompsonSamplingEngine
        self.outcomeTracker = outcomeTracker
        self.decisionLogger = decisionLogger
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

    // MARK: - Enhanced Public Methods (New)

    /// Get current burden level
    func getCurrentBurdenLevel() async -> BurdenLevel {
        let metrics = await burdenTracker.calculateCurrentBurdenMetrics()
        var mutableMetrics = metrics
        let level = mutableMetrics.calculateBurdenLevel()
        await MainActor.run {
            currentBurdenLevel = level
        }
        return currentBurdenLevel
    }

    /// Get comprehensive intervention decision with all JITAI factors
    /// - Parameters:
    ///   - app: Target app bundle ID
    ///   - currentUsage: Current session duration in milliseconds
    ///   - interventionType: Type of intervention to check for
    /// - Returns: Full intervention decision with rich context
    func getInterventionDecision(
        for app: String,
        currentUsage: TimeInterval,
        interventionType: JitaiInterventionType = .reminder
    ) async -> InterventionDecisionFull {
        // Build context
        guard let context = await buildInterventionContext(
            targetApp: app,
            currentUsage: currentUsage,
            interventionType: interventionType
        ) else {
            return InterventionDecisionFull(
                shouldShow: false,
                reason: "Failed to build context",
                opportunityScore: 0,
                burdenLevel: .moderate,
                recommendedCooldown: 300_000,  // 5 minutes default
                persona: nil,
                decisionSource: "context_build_failed"
            )
        }

        // Get persona detection
        let personaDetection = await personaDetector.detectPersona()

        // Get opportunity detection
        let opportunityDetection = await opportunityDetector.detectOpportunity(context: context)

        // Check rate limiting
        let rateLimitResult = await adaptiveRateLimiter.canShowIntervention(
            interventionContext: context,
            interventionType: interventionType,
            sessionDurationMs: currentUsage
        )

        // Get burden metrics
        let burdenMetrics = await burdenTracker.calculateCurrentBurdenMetrics()
        var mutableMetrics = burdenMetrics
        let burdenLevel = mutableMetrics.calculateBurdenLevel()
        let cooldownAdjustment = mutableMetrics.getRecommendedCooldownMultiplier()

        // Log all decisions
        decisionLogger.logPersonaDetection(
            persona: personaDetection.persona,
            confidence: personaDetection.confidence,
            analytics: personaDetection.analytics
        )
        decisionLogger.logOpportunityDetection(
            score: opportunityDetection.score,
            level: opportunityDetection.level,
            decision: opportunityDetection.decision,
            breakdown: opportunityDetection.breakdown
        )
        decisionLogger.logRateLimitDecision(
            allowed: rateLimitResult.allowed,
            reason: rateLimitResult.reason,
            burdenLevel: burdenLevel
        )

        // Check if burden is too high (async call needs to be extracted)
        let isHighBurden = await burdenTracker.isHighBurden()

        // Make final decision
        let shouldShow = rateLimitResult.allowed &&
                        opportunityDetection.score >= 50 &&
                        !isHighBurden

        let cooldownMs = Int64(300_000 * cooldownAdjustment)  // Base 5 min * adjustment

        let decision = InterventionDecisionFull(
            shouldShow: shouldShow,
            reason: shouldShow ? rateLimitResult.reason : "JITAI decision: skip",
            opportunityScore: opportunityDetection.score,
            burdenLevel: burdenLevel,
            recommendedCooldown: cooldownMs,
            persona: personaDetection.persona,
            decisionSource: rateLimitResult.decisionSource
        )

        // Store current decision
        await MainActor.run {
            currentDecision = decision
        }

        return decision
    }

    /// Show intervention with specified delivery method
    /// - Parameters:
    ///   - app: Target app bundle ID
    ///   - currentUsage: Current session duration in milliseconds
    ///   - interventionType: Type of intervention
    ///   - deliveryMethod: How to deliver the intervention
    func showInterventionWithDelivery(
        for app: String,
        currentUsage: TimeInterval,
        interventionType: JitaiInterventionType = .reminder,
        deliveryMethod: InterventionDeliveryMethod = .automatic
    ) async {
        // Get decision
        let decision = await getInterventionDecision(
            for: app,
            currentUsage: currentUsage,
            interventionType: interventionType
        )

        guard decision.shouldShow else {
            logInfo("Intervention not shown: \(decision.reason)")
            return
        }

        // Select content using Thompson Sampling if we have enough data
        let contentType: ContentType
        let useThompsonSampling = await thompsonSamplingEngine.hasSufficientDataForExploration()

        if useThompsonSampling {
            let armSelection = await thompsonSamplingEngine.selectArm()
            contentType = ContentType(rawValue: armSelection.armId) ?? .reflection

            decisionLogger.logThompsonSamplingSelection(
                selection: armSelection,
                allArmStats: await thompsonSamplingEngine.getAllArmStats()
            )
        } else {
            // Fall back to persona-aware selection
            guard let context = await buildInterventionContext(
                targetApp: app,
                currentUsage: currentUsage,
                interventionType: interventionType
            ) else {
                return
            }

            let contentSelection = await personaAwareContentSelector.selectContent(
                context: context,
                interventionType: interventionType
            )
            contentType = contentSelection.contentType

            let persona = await personaDetector.detectPersona()
            decisionLogger.logContentSelection(
                selected: contentType,
                persona: persona.persona,
                weights: persona.persona.baseWeights,
                reason: contentSelection.selectionReason
            )
        }

        // Generate content
        let contentSelector = ContentSelector()
        let content = contentSelector.generateContentByType(
            contentTypeName: contentType.rawValue,
            context: lastDecisionContext ?? InterventionContext(
                timeOfDay: 0,
                dayOfWeek: 0,
                isWeekend: false,
                targetApp: app,
                currentSessionMinutes: 0,
                sessionCount: 0,
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
        )

        // Determine delivery method
        let method: InterventionDeliveryMethod
        if deliveryMethod == .automatic {
            // Auto-select best method
            if #available(iOS 16.1, *),
               await liveActivityManager.checkAvailability() {
                method = .liveActivity
            } else {
                method = .notification
            }
        } else {
            method = deliveryMethod
        }

        // Deliver based on method
        switch method {
        case .inApp:
            // Show in app (original behavior)
            await MainActor.run {
                currentIntervention = InterventionContentModel(
                    type: contentType,
                    title: content.title,
                    content: content.content,
                    subtext: content.subtext,
                    actionLabel: "Take a Break",
                    dismissLabel: "Continue",
                    metadata: [:]
                )
                isShowingIntervention = true
            }

        case .notification:
            if let context = lastDecisionContext {
                notificationScheduler.scheduleIntervention(
                    content: InterventionContentModel(
                        type: contentType,
                        title: content.title,
                        content: content.content,
                        subtext: content.subtext,
                        actionLabel: "Take a Break",
                        dismissLabel: "Continue",
                        metadata: [:]
                    ),
                    context: context
                )
            }

        case .liveActivity:
            if #available(iOS 16.1, *),
               let context = lastDecisionContext {
                _ = await liveActivityManager.startLiveActivity(
                    content: InterventionContentModel(
                        type: contentType,
                        title: content.title,
                        content: content.content,
                        subtext: content.subtext,
                        actionLabel: "Take a Break",
                        dismissLabel: "Continue",
                        metadata: [:]
                    ),
                    context: context
                )
            }

        case .automatic:
            break  // Handled above
        }

        // Log delivery
        decisionLogger.logInterventionDelivered(
            method: method,
            contentId: contentType.rawValue,
            targetApp: app,
            success: true
        )
    }
}

// MARK: - Supporting Types

/// Full intervention decision with rich context
struct InterventionDecisionFull {
    let shouldShow: Bool
    let reason: String
    let opportunityScore: Int
    let burdenLevel: BurdenLevel
    let recommendedCooldown: Int64  // milliseconds
    let persona: UserPersona?
    let decisionSource: String

    var cooldownMinutes: Int {
        return Int(recommendedCooldown / 60_000)
    }
}
