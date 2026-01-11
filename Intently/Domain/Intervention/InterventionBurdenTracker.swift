//
//  InterventionBurdenTracker.swift
//  Intently
//
//  Created on 2025-01-11.
//  JITAI Phase 3: Tracks user fatigue from interventions
//

import Foundation

/// Intervention Burden Tracker
/// Phase 3 JITAI: Monitors user fatigue to adapt intervention frequency
///
/// Tracks multiple metrics to determine if the user is experiencing
/// intervention fatigue:
/// - Dismiss and timeout rates
/// - Response times
/// - Intervention frequency
/// - Engagement trends
/// - Effectiveness over time
///
/// Caching: Results are cached for 10 minutes
final class InterventionBurdenTracker: ObservableObject {

    // MARK: - Published Properties
    @Published var currentBurdenLevel: BurdenLevel = .moderate
    @Published var currentBurdenScore: Int = 50

    // MARK: - Dependencies
    private let interventionResultRepository: InterventionResultRepository
    private let usageRepository: UsageRepository

    // MARK: - Constants
    private let cacheDurationMs: Int64 = 10 * 60 * 1000  // 10 minutes
    private let analysisWindowDays = 30                 // Analyze last 30 days

    // Minimum interventions needed for burden analysis
    private let minInterventionsForAnalysis = 5

    // MARK: - Cache
    private var cachedMetrics: InterventionBurdenMetrics?
    private var cacheTimestamp: Int64 = 0

    // MARK: - Initialization
    init(
        interventionResultRepository: InterventionResultRepository,
        usageRepository: UsageRepository
    ) {
        self.interventionResultRepository = interventionResultRepository
        self.usageRepository = usageRepository
    }

    // MARK: - Public Methods

    /// Calculate current burden metrics with caching
    /// - Parameter forceRefresh: Force recalculation even if cache is valid
    /// - Returns: Current burden metrics
    func calculateCurrentBurdenMetrics(forceRefresh: Bool = false) async -> InterventionBurdenMetrics {
        let now = currentTimestampMs()

        // Return cached result if still valid
        if !forceRefresh,
           let cached = cachedMetrics,
           (now - cacheTimestamp) < cacheDurationMs {
            logDebug("Using cached burden metrics: \(cached.getBurdenSummary())")
            return cached
        }

        // Calculate fresh metrics
        let metrics = await calculateBurdenMetrics()
        var mutableMetrics = metrics

        // Update published properties
        await MainActor.run {
            currentBurdenScore = mutableMetrics.calculateBurdenScore()
            currentBurdenLevel = mutableMetrics.calculateBurdenLevel()
        }

        // Cache the result
        cachedMetrics = mutableMetrics
        cacheTimestamp = now

        logInfo("Burden calculated: \(mutableMetrics.getBurdenSummary())")

        return mutableMetrics
    }

    /// Check if user is currently experiencing high burden
    /// - Returns: True if burden level is high or critical
    func isHighBurden() async -> Bool {
        let metrics = await calculateCurrentBurdenMetrics()
        var mutableMetrics = metrics
        let level = mutableMetrics.calculateBurdenLevel()
        return level == .high || level == .critical
    }

    /// Get recommended cooldown adjustment based on current burden
    /// - Returns: Multiplier for cooldown (0.5x to 3.0x)
    func getRecommendedCooldownAdjustment() async -> Float {
        let metrics = await calculateCurrentBurdenMetrics()
        var mutableMetrics = metrics
        return mutableMetrics.getRecommendedCooldownMultiplier()
    }

    /// Get a human-readable burden summary
    /// - Returns: Summary string describing current burden state
    func getBurdenSummary() async -> String {
        let metrics = await calculateCurrentBurdenMetrics()
        return metrics.getBurdenSummary()
    }

    /// Clear cached burden metrics
    /// Call when significant intervention events occur
    func invalidateCache() {
        cachedMetrics = nil
        cacheTimestamp = 0
        logDebug("Burden metrics cache cleared")
    }

    // MARK: - Private Methods

    /// Calculate burden metrics from intervention history
    private func calculateBurdenMetrics() async -> InterventionBurdenMetrics {
        let now = Date()
        let dayAgo = Calendar.current.date(byAdding: .day, value: -1, to: now) ?? now
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: now) ?? now
        let analysisStart = Calendar.current.date(byAdding: .day, value: -analysisWindowDays, to: now) ?? now

        // Get intervention results for different time windows
        let startTimestamp = Int64(analysisStart.timeIntervalSince1970 * 1000)
        let endTimestamp = Int64(now.timeIntervalSince1970 * 1000)

        let allResults = (try? await interventionResultRepository.getResultsInRange(
            startTimestamp: startTimestamp,
            endTimestamp: endTimestamp
        )) ?? []

        guard !allResults.isEmpty else {
            return createDefaultMetrics()
        }

        // Calculate metrics from results
        let dismissRate = calculateDismissRate(results: allResults)
        let timeoutRate = calculateTimeoutRate(results: allResults)
        let avgResponseTime = calculateAvgResponseTime(results: allResults)
        let snoozeFrequency = calculateSnoozeFrequency(results: allResults)
        let effectiveness = calculateRollingEffectiveness(results: allResults)

        // Get intervention counts
        let interventionsLast24h = countInterventions(in: allResults, since: dayAgo)
        let interventionsLast7d = countInterventions(in: allResults, since: weekAgo)

        // Analyze trends
        let engagementTrend = analyzeEngagementTrend(results: allResults)
        let effectivenessTrend = analyzeEffectivenessTrend(results: allResults)
        let helpfulnessRatio = calculateHelpfulnessRatio(results: allResults)

        return InterventionBurdenMetrics(
            avgResponseTime: avgResponseTime,
            dismissRate: dismissRate,
            timeoutRate: timeoutRate,
            snoozeFrequency: snoozeFrequency,
            recentEngagementTrend: engagementTrend,
            interventionsLast24h: interventionsLast24h,
            interventionsLast7d: interventionsLast7d,
            effectivenessRolling7d: effectiveness,
            effectivenessTrend: effectivenessTrend,
            helpfulnessRatio: helpfulnessRatio,
            sampleSize: allResults.count
        )
    }

    /// Create default metrics when no data is available
    private func createDefaultMetrics() -> InterventionBurdenMetrics {
        return InterventionBurdenMetrics(
            avgResponseTime: 5000,
            dismissRate: 0.0,
            timeoutRate: 0.0,
            snoozeFrequency: 0,
            recentEngagementTrend: .stable,
            interventionsLast24h: 0,
            interventionsLast7d: 0,
            effectivenessRolling7d: 0.5,
            effectivenessTrend: .stable,
            helpfulnessRatio: 0.5,
            sampleSize: 0
        )
    }

    /// Calculate the rate of dismissals (vs meaningful engagement)
    private func calculateDismissRate(results: [InterventionResult]) -> Float {
        guard results.count >= minInterventionsForAnalysis else { return 0.0 }

        let dismissed = results.filter { result in
            result.userChoice.lowercased() == "skip" ||
            result.userChoice.lowercased() == "dismiss" ||
            result.userChoice.lowercased() == "continue"
        }.count

        return Float(dismissed) / Float(results.count)
    }

    /// Calculate the rate of timeouts (no response within expected time)
    private func calculateTimeoutRate(results: [InterventionResult]) -> Float {
        guard results.count >= minInterventionsForAnalysis else { return 0.0 }

        // Assume timeout if response time > 30 seconds (30000ms)
        let timeoutThreshold: Int64 = 30000

        let timeouts = results.filter { result in
            // Calculate response time from session duration
            // If session continued immediately, likely timed out or ignored
            return result.sessionDuration < 1 && result.userChoice.isEmpty
        }.count

        return Float(timeouts) / Float(results.count)
    }

    /// Calculate average response time in milliseconds
    private func calculateAvgResponseTime(results: [InterventionResult]) -> Int64 {
        guard results.count >= minInterventionsForAnalysis else { return 5000 }

        // Use session duration as proxy for response time
        let responseTimes = results.compactMap { result -> Int64? in
            guard result.sessionDuration > 0 else { return nil }
            return Int64(result.sessionDuration * 1000)
        }

        guard !responseTimes.isEmpty else { return 5000 }

        let total = responseTimes.reduce(Int64(0), +)
        return total / Int64(responseTimes.count)
    }

    /// Count snoozes (user chose to delay)
    private func calculateSnoozeFrequency(results: [InterventionResult]) -> Int {
        return results.filter { $0.userChoice.lowercased() == "snooze" }.count
    }

    /// Calculate rolling 7-day effectiveness rate
    private func calculateRollingEffectiveness(results: [InterventionResult]) -> Float {
        guard results.count >= minInterventionsForAnalysis else { return 0.5 }

        // Consider intervention effective if user chose to quit/go_back
        let effective = results.filter { result in
            result.wasEffective == true ||
            result.userChoice.lowercased() == "go_back" ||
            result.userChoice.lowercased() == "quit"
        }.count

        return Float(effective) / Float(results.count)
    }

    /// Count interventions since a given date
    private func countInterventions(in results: [InterventionResult], since date: Date) -> Int {
        let sinceTimestamp = Int64(date.timeIntervalSince1970 * 1000)
        return results.filter { result in
            Int64(result.feedbackTimestamp.timeIntervalSince1970 * 1000) >= sinceTimestamp
        }.count
    }

    /// Analyze engagement trend over recent interventions
    private func analyzeEngagementTrend(results: [InterventionResult]) -> Trend {
        guard results.count >= 10 else { return .stable }

        // Split into two halves and compare engagement
        let midpoint = results.count / 2
        let firstHalf = Array(results.prefix(midpoint))
        let secondHalf = Array(results.suffix(midpoint))

        let firstEngagement = calculateEngagementScore(results: firstHalf)
        let secondEngagement = calculateEngagementScore(results: secondHalf)

        let diff = secondEngagement - firstEngagement

        if diff > 0.1 {
            return .increasing
        } else if diff < -0.1 {
            return .declining
        } else {
            return .stable
        }
    }

    /// Calculate engagement score for a set of results
    private func calculateEngagementScore(results: [InterventionResult]) -> Float {
        guard !results.isEmpty else { return 0.5 }

        let positiveChoices = results.filter { result in
            result.userChoice.lowercased() == "go_back" ||
            result.userChoice.lowercased() == "quit" ||
            result.userChoice.lowercased() == "snooze"
        }.count

        return Float(positiveChoices) / Float(results.count)
    }

    /// Analyze effectiveness trend over time
    private func analyzeEffectivenessTrend(results: [InterventionResult]) -> Trend {
        guard results.count >= 10 else { return .stable }

        let midpoint = results.count / 2
        let firstHalf = Array(results.prefix(midpoint))
        let secondHalf = Array(results.suffix(midpoint))

        let firstEffective = calculateRollingEffectiveness(results: firstHalf)
        let secondEffective = calculateRollingEffectiveness(results: secondHalf)

        let diff = secondEffective - firstEffective

        if diff > 0.1 {
            return .increasing
        } else if diff < -0.1 {
            return .declining
        } else {
            return .stable
        }
    }

    /// Calculate ratio of helpful responses
    private func calculateHelpfulnessRatio(results: [InterventionResult]) -> Float {
        guard results.count >= minInterventionsForAnalysis else { return 0.5 }

        // Count interventions where user took positive action
        let helpful = results.filter { result in
            result.wasEffective == true
        }.count

        return Float(helpful) / Float(results.count)
    }

    /// Get current timestamp in milliseconds
    private func currentTimestampMs() -> Int64 {
        return Int64(Date().timeIntervalSince1970 * 1000)
    }

    // MARK: - Logging

    private func logDebug(_ message: String) {
        #if DEBUG
        print("[InterventionBurdenTracker] DEBUG: \(message)")
        #endif
    }

    private func logInfo(_ message: String) {
        print("[InterventionBurdenTracker] INFO: \(message)")
    }
}
