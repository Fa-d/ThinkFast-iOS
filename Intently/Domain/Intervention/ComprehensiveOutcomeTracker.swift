//
//  ComprehensiveOutcomeTracker.swift
//  Intently
//
//  Created on 2025-01-11.
//  JITAI Phase 3: Full lifecycle intervention outcome tracking
//

import Foundation

/// Comprehensive Outcome Tracker
/// Phase 3 JITAI: Tracks full intervention lifecycle and effectiveness
///
/// This tracker goes beyond simple user choice recording to capture:
/// - Full session duration after intervention
/// - Compliance detection (did user stay away?)
/// - Quick reopen detection
/// - Time-to-decision metrics
/// - Reward calculation for Thompson Sampling
///
/// Integration:
/// - Updates burden tracker with new data
/// - Calculates rewards for Thompson Sampling engine
/// - Stores comprehensive outcomes for analysis
final class ComprehensiveOutcomeTracker: ObservableObject {

    // MARK: - Published Properties
    @Published var recentOutcomes: [ComprehensiveInterventionOutcome] = []

    // MARK: - Dependencies
    private let interventionResultRepository: InterventionResultRepository
    private let usageRepository: UsageRepository
    private let burdenTracker: InterventionBurdenTracker

    // MARK: - Constants
    private let quickReopenThresholdMs: Int64 = 5 * 60 * 1000      // 5 minutes
    private let complianceThresholdMs: Int64 = 15 * 60 * 1000      // 15 minutes
    private let maxStoredOutcomes = 100                            // Keep recent outcomes in memory

    // Session tracking for compliance detection
    private var activeSessions: [UUID: SessionTrackingData] = [:]

    // MARK: - Initialization
    init(
        interventionResultRepository: InterventionResultRepository,
        usageRepository: UsageRepository,
        burdenTracker: InterventionBurdenTracker
    ) {
        self.interventionResultRepository = interventionResultRepository
        self.usageRepository = usageRepository
        self.burdenTracker = burdenTracker
    }

    // MARK: - Public Methods

    /// Record a comprehensive intervention outcome
    /// - Parameter outcome: The outcome to record
    func recordOutcome(outcome: ComprehensiveInterventionOutcome) async throws {
        // Store in memory for quick access
        await MainActor.run {
            recentOutcomes.append(outcome)
            if recentOutcomes.count > maxStoredOutcomes {
                recentOutcomes.removeFirst()
            }
        }

        // Also save to intervention result repository for persistence
        let result = InterventionResult(
            sessionId: outcome.sessionId,
            targetApp: outcome.targetApp,
            interventionType: outcome.contentType,
            contentType: outcome.contentType,
            userChoice: outcome.userChoice,
            feedbackTimestamp: outcome.timestamp,
            sessionDuration: TimeInterval(outcome.totalSessionDuration ?? 0) / 1000,
            wasEffective: outcome.wasEffective,
            timeOfDay: getTimeOfDay(from: outcome.timestamp),
            hourOfDay: Calendar.current.component(.hour, from: outcome.timestamp),
            streakAtTime: 0,  // Would need to be passed in
            goalProgressAtTime: nil,
            quickReopen: outcome.didReopenQuickly,
            opportunityScore: outcome.opportunityScoreAtTime,
            opportunityLevel: outcome.opportunityScoreAtTime >= 70 ? "EXCELLENT" :
                             outcome.opportunityScoreAtTime >= 50 ? "GOOD" :
                             outcome.opportunityScoreAtTime >= 30 ? "MODERATE" : "POOR",
            persona: outcome.personaAtTime,
            decisionSource: "jitai"
        )

        try await interventionResultRepository.saveResult(result)

        // Invalidate burden tracker cache since we have new data
        await burdenTracker.invalidateCache()

        logInfo("Recorded outcome for session \(outcome.sessionId): \(outcome.userChoice) (reward: \(outcome.reward))")
    }

    /// Start tracking a session for compliance detection
    /// - Parameters:
    ///   - sessionId: Unique session identifier
    ///   - targetApp: App being tracked
    ///   - interventionTimestamp: When intervention was shown
    func startSessionTracking(
        sessionId: UUID,
        targetApp: String,
        interventionTimestamp: Date = Date()
    ) {
        activeSessions[sessionId] = SessionTrackingData(
            sessionId: sessionId,
            targetApp: targetApp,
            interventionTimestamp: interventionTimestamp
        )

        logDebug("Started tracking session \(sessionId) for compliance")
    }

    /// Complete session tracking and record final outcome
    /// - Parameters:
    ///   - sessionId: Session to complete
    ///   - userChoice: User's choice
    ///   - wasEffective: Whether intervention was effective
    ///   - sessionDurationMs: Total session duration after intervention
    ///   - burdenScore: Burden score at time of intervention
    ///   - persona: Detected persona at time
    ///   - opportunityScore: Opportunity score at time
    func completeSessionTracking(
        sessionId: UUID,
        userChoice: String,
        wasEffective: Bool,
        sessionDurationMs: Int64,
        burdenScore: Int = 50,
        persona: String = "",
        opportunityScore: Int = 50
    ) async throws {
        guard let trackingData = activeSessions[sessionId] else {
            logDebug("No active session found for \(sessionId)")
            return
        }

        let interventionTimestamp = trackingData.interventionTimestamp
        let timeSinceIntervention = Int64(Date().timeIntervalSince(interventionTimestamp) * 1000)

        // Check for quick reopen
        let didReopenQuickly = timeSinceIntervention < quickReopenThresholdMs

        let outcome = ComprehensiveInterventionOutcome(
            sessionId: sessionId,
            targetApp: trackingData.targetApp,
            contentType: "",  // Would need to be passed in
            userChoice: userChoice,
            wasEffective: wasEffective,
            timeToShowDecisionMs: timeSinceIntervention,
            sessionDurationAfterIntervention: sessionDurationMs,
            didReopenQuickly: didReopenQuickly,
            totalSessionDuration: sessionDurationMs,
            burdenScoreAtTime: burdenScore,
            personaAtTime: persona,
            opportunityScoreAtTime: opportunityScore,
            timestamp: interventionTimestamp
        )

        try await recordOutcome(outcome: outcome)

        // Remove from active sessions
        activeSessions.removeValue(forKey: sessionId)
    }

    /// Check if a session indicates compliance
    /// - Parameter sessionId: Session to check
    /// - Returns: True if user complied (stayed away for > 15 min)
    func checkCompliance(sessionId: UUID) async -> Bool {
        // Check recent outcomes
        if let outcome = recentOutcomes.first(where: { $0.sessionId == sessionId }) {
            return outcome.isCompliant
        }

        // Check if we have tracking data
        guard let trackingData = activeSessions[sessionId] else {
            return false
        }

        let timeSinceIntervention = Int64(Date().timeIntervalSince(trackingData.interventionTimestamp) * 1000)
        return timeSinceIntervention >= complianceThresholdMs
    }

    /// Get outcomes within a date range
    /// - Parameters:
    ///   - start: Start date
    ///   - end: End date
    /// - Returns: Array of comprehensive outcomes
    func getOutcomesInRange(start: Date, end: Date) async -> [ComprehensiveInterventionOutcome] {
        let startTimestamp = Int64(start.timeIntervalSince1970 * 1000)
        let endTimestamp = Int64(end.timeIntervalSince1970 * 1000)

        // Filter recent outcomes from memory
        let fromMemory = recentOutcomes.filter { outcome in
            let outcomeTimestamp = Int64(outcome.timestamp.timeIntervalSince1970 * 1000)
            return outcomeTimestamp >= startTimestamp && outcomeTimestamp <= endTimestamp
        }

        // Also fetch from repository
        let startInterval = start.timeIntervalSince1970
        let endInterval = end.timeIntervalSince1970

        do {
            let storedResults = try await interventionResultRepository.getResultsInRange(
                startTimestamp: startTimestamp,
                endTimestamp: endTimestamp
            )

            // Convert to comprehensive outcomes
            let comprehensive = storedResults.map { result -> ComprehensiveInterventionOutcome in
                ComprehensiveInterventionOutcome(
                    sessionId: result.sessionId,
                    targetApp: result.targetApp,
                    contentType: result.contentType,
                    userChoice: result.userChoice,
                    wasEffective: result.wasEffective ?? false,
                    timeToShowDecisionMs: Int64(result.sessionDuration * 1000),
                    sessionDurationAfterIntervention: Int64(result.sessionDuration * 1000),
                    didReopenQuickly: result.quickReopen,
                    totalSessionDuration: Int64(result.sessionDuration * 1000),
                    burdenScoreAtTime: 50,  // Not stored in current model
                    personaAtTime: result.persona,
                    opportunityScoreAtTime: result.opportunityScore,
                    timestamp: result.feedbackTimestamp
                )
            }

            return fromMemory + comprehensive
        } catch {
            logDebug("Failed to fetch outcomes from repository: \(error)")
            return fromMemory
        }
    }

    /// Calculate reward for Thompson Sampling based on outcome
    /// - Parameter outcome: The outcome to calculate reward for
    /// - Returns: Reward value (-1.0 to 1.0)
    func calculateReward(outcome: ComprehensiveInterventionOutcome) -> Float {
        return outcome.reward
    }

    /// Get compliance rate for recent interventions
    /// - Returns: Ratio of compliant sessions (0-1)
    func getComplianceRate() async -> Float {
        guard !recentOutcomes.isEmpty else { return 0 }

        let compliant = recentOutcomes.filter { $0.isCompliant }.count
        return Float(compliant) / Float(recentOutcomes.count)
    }

    /// Get average compliance duration
    /// - Returns: Average minutes users stayed away after intervention
    func getAverageComplianceDuration() async -> Double {
        let compliantOutcomes = recentOutcomes.filter { $0.isCompliant }

        guard !compliantOutcomes.isEmpty else { return 0 }

        let durations = compliantOutcomes.compactMap { $0.complianceDurationMinutes }
        guard !durations.isEmpty else { return 0 }

        return Double(durations.reduce(0, +)) / Double(durations.count)
    }

    /// Get quick reopen rate
    /// - Returns: Ratio of sessions where user quickly reopened (0-1)
    func getQuickReopenRate() async -> Float {
        guard !recentOutcomes.isEmpty else { return 0 }

        let quickReopens = recentOutcomes.filter { $0.didReopenQuickly }.count
        return Float(quickReopens) / Float(recentOutcomes.count)
    }

    /// Clear recent outcomes from memory
    func clearRecentOutcomes() {
        recentOutcomes.removeAll()
        logDebug("Cleared recent outcomes from memory")
    }

    // MARK: - Private Methods

    private func getTimeOfDay(from date: Date) -> String {
        let hour = Calendar.current.component(.hour, from: date)
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
        print("[ComprehensiveOutcomeTracker] DEBUG: \(message)")
        #endif
    }

    private func logInfo(_ message: String) {
        print("[ComprehensiveOutcomeTracker] INFO: \(message)")
    }
}

// MARK: - Session Tracking Data

private struct SessionTrackingData {
    let sessionId: UUID
    let targetApp: String
    let interventionTimestamp: Date
}
