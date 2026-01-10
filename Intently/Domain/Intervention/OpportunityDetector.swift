//
//  OpportunityDetector.swift
//  Intently
//
//  Created on 2025-01-07.
//  JITAI Phase 2: Determines optimal moments for interventions
//

import Foundation

/// Opportunity Detector
/// Phase 2 JITAI: Determines optimal moments for interventions
///
/// Calculates a 0-100 opportunity score based on five factors:
/// 1. Time Receptiveness (25 pts): Optimal intervention times
/// 2. Session Pattern (20 pts): Quick reopen, first session, extended
/// 3. Cognitive Load (15 pts): Lower cognitive load = better reception
/// 4. Historical Success (20 pts): Past success in similar contexts
/// 5. User State (20 pts): Positive state, on streak
///
/// Caching: Results are cached for 5 minutes within a session
final class OpportunityDetector: ObservableObject {

    // MARK: - Dependencies
    private let interventionResultRepository: InterventionResultRepository
    private let userDefaults: UserDefaults

    // MARK: - Constants
    private let cacheDurationMs: Int64 = 5 * 60 * 1000 // 5 minutes
    private let minHistoricalData = 10 // Minimum interventions for historical analysis

    // Time ranges (hour of day)
    private let lateNightStart = 22  // 10 PM
    private let lateNightEnd = 2     // 2 AM
    private let earlyMorningStart = 3 // 3 AM
    private let earlyMorningEnd = 5   // 5 AM
    private let morningStart = 6       // 6 AM
    private let morningEnd = 9         // 9 AM
    private let midDayStart = 10      // 10 AM
    private let midDayEnd = 16        // 4 PM
    private let eveningStart = 17      // 5 PM
    private let eveningEnd = 21        // 9 PM

    // MARK: - Cache
    private var cachedDetection: OpportunityDetection?
    private var cacheTimestamp: Int64 = 0
    private var cachedApp: String?

    // MARK: - Initialization
    init(
        interventionResultRepository: InterventionResultRepository,
        userDefaults: UserDefaults = .standard
    ) {
        self.interventionResultRepository = interventionResultRepository
        self.userDefaults = userDefaults
    }

    // MARK: - Public Methods

    /// Detect intervention opportunity with caching
    /// - Parameters:
    ///   - context: Current intervention context
    ///   - forceRefresh: Force re-calculation even if cache is valid
    /// - Returns: Opportunity detection with JITAI decision
    func detectOpportunity(
        context: InterventionContext,
        forceRefresh: Bool = false
    ) async -> OpportunityDetection {
        let now = currentTimestampMs()

        // Return cached result if still valid for same app
        if !forceRefresh,
           let cached = cachedDetection,
           cachedApp == context.targetApp,
           (now - cacheTimestamp) < cacheDurationMs {
            logDebug("Using cached opportunity: \(cached.score) (\(cached.level.rawValue))")
            return cached
        }

        // Calculate fresh opportunity score
        let breakdown = await calculateBreakdown(context: context)
        let score = breakdown.timeReceptiveness +
                    breakdown.sessionPattern +
                    breakdown.cognitiveLoad +
                    breakdown.historicalSuccess +
                    breakdown.userState

        let level: OpportunityLevel
        switch score {
        case 70...: level = .excellent
        case 50..<70: level = .good
        case 30..<50: level = .moderate
        default: level = .poor
        }

        let decision: InterventionDecision
        switch score {
        case 70...: decision = .interveneNow
        case 50..<70: decision = .interveneWithConsideration
        case 30..<50: decision = .waitForBetterOpportunity
        default: decision = .skipIntervention
        }

        let detection = OpportunityDetection(
            score: score,
            level: level,
            decision: decision,
            breakdown: breakdown,
            detectedAt: now
        )

        // Cache the result
        cachedDetection = detection
        cacheTimestamp = now
        cachedApp = context.targetApp

        logInfo("Opportunity: \(score)/100 (\(level.rawValue)) - \(decision.rawValue)")

        return detection
    }

    /// Clear cached opportunity detection
    func clearCache() {
        cachedDetection = nil
        cacheTimestamp = 0
        cachedApp = nil
        logDebug("Opportunity detection cache cleared")
    }

    // MARK: - Private Methods

    /// Calculate detailed breakdown of opportunity score
    private func calculateBreakdown(context: InterventionContext) async -> OpportunityBreakdown {
        let timeScore = calculateTimeReceptiveness(context: context)
        let sessionScore = calculateSessionPattern(context: context)
        let cognitiveScore = calculateCognitiveLoad(context: context)
        let historicalScore = await calculateHistoricalSuccess(context: context)
        let userStateScore = await calculateUserState(context: context)

        var factors: [String: String] = [:]
        factors["time"] = getTimeDescription(hour: context.timeOfDay, isWeekend: context.isWeekend)
        factors["session"] = getSessionPatternDescription(context: context)
        factors["cognitive"] = getCognitiveLoadDescription(context: context)
        factors["historical"] = getHistoricalSuccessDescription(score: historicalScore)
        factors["user_state"] = getUserStateDescription(context: context)

        return OpportunityBreakdown(
            timeReceptiveness: timeScore,
            sessionPattern: sessionScore,
            cognitiveLoad: cognitiveScore,
            historicalSuccess: historicalScore,
            userState: userStateScore,
            factors: factors
        )
    }

    /// Time Receptiveness (25 points)
    /// Optimal intervention times based on hour of day and day of week
    private func calculateTimeReceptiveness(context: InterventionContext) -> Int {
        let hour = context.timeOfDay
        let isWeekend = context.isWeekend

        // Late night (22:00-02:00) - high receptiveness if over goal
        if (hour >= lateNightStart || hour <= lateNightEnd) {
            return context.isOverGoal ? 25 : 20
        }

        // Early morning (03:00-05:00) - low receptiveness
        if (earlyMorningStart...earlyMorningEnd).contains(hour) {
            return 5
        }

        // Morning (06:00-09:00) - high receptiveness, especially on weekends
        if (morningStart...morningEnd).contains(hour) {
            if isWeekend && context.sessionCount == 1 { return 25 }
            if isWeekend { return 22 }
            if context.sessionCount == 1 { return 23 }
            return 20
        }

        // Mid-day (10:00-16:00) - moderate receptiveness
        if (midDayStart...midDayEnd).contains(hour) {
            if context.isOverGoal { return 18 }
            if context.currentSessionMinutes >= 15 { return 15 }
            return 12
        }

        // Evening (17:00-21:00) - moderate to high receptiveness
        if (eveningStart...eveningEnd).contains(hour) {
            if isWeekend && context.isOverGoal { return 23 }
            if context.isOverGoal { return 20 }
            return 15
        }

        return 10
    }

    /// Session Pattern (20 points)
    /// Based on quick reopen, first session, or extended session
    private func calculateSessionPattern(context: InterventionContext) -> Int {
        // Quick reopen - highest priority for intervention
        if context.quickReopenAttempt {
            return 20
        }

        // First session of the day
        if context.isFirstSessionOfDay {
            return 15
        }

        // Extended session (> 15 minutes)
        if context.isExtendedSession {
            if context.currentSessionMinutes >= 30 { return 18 }
            return 12
        }

        // Moderate session (5-15 minutes)
        if context.currentSessionMinutes >= 5 {
            return 8
        }

        // Short session (< 5 minutes) - may not need intervention yet
        return 5
    }

    /// Cognitive Load (15 points)
    /// Lower cognitive load = better intervention reception
    private func calculateCognitiveLoad(context: InterventionContext) -> Int {
        var score = 15 // Start with maximum

        // Reduce score if likely high cognitive load situations
        // Quick reopens suggest compulsive checking (lower cognitive resistance)
        if !context.quickReopenAttempt {
            score -= 3
        }

        // Longer sessions suggest deeper engagement (higher cognitive load)
        if context.currentSessionMinutes >= 20 {
            score -= 5
        } else if context.currentSessionMinutes >= 10 {
            score -= 2
        }

        // Late night interventions may be more effective (less cognitive resistance)
        if context.isLateNight {
            score += 2
        }

        return max(0, min(15, score))
    }

    /// Historical Success (20 points)
    /// Based on past intervention success in similar contexts
    private func calculateHistoricalSuccess(context: InterventionContext) async -> Int {
        // Get recent interventions for this app
        let recentResults = (try? await interventionResultRepository.getRecentResultsForApp(
            targetApp: context.targetApp,
            limit: 50
        )) ?? []

        // Not enough data yet
        if recentResults.count < minHistoricalData {
            return 12 // Neutral-leaning positive
        }

        // Filter for similar context (same time of day)
        let similarContextResults = recentResults.filter { result in
            let hourDiff = abs(result.hourOfDay - context.timeOfDay)
            return hourDiff <= 2 || hourDiff >= 22 // Within 2 hours
        }

        // If no similar context data, use overall stats
        let relevantResults = similarContextResults.count >= 5 ? similarContextResults : recentResults

        // Calculate go-back rate (success metric)
        let goBackCount = relevantResults.filter { $0.userChoice == "GO_BACK" }.count
        let successRate = relevantResults.isEmpty ? 50.0 : (Double(goBackCount) / Double(relevantResults.count)) * 100

        // Convert success rate to 0-20 points
        switch successRate {
        case 60...: return 20
        case 50..<60: return 17
        case 40..<50: return 14
        case 30..<40: return 10
        default: return 5
        }
    }

    /// User State (20 points)
    /// Based on positive state indicators like streaks, goals met
    private func calculateUserState(context: InterventionContext) async -> Int {
        var score = 10 // Start with neutral

        // Check if user is on a streak (from context)
        let currentStreak = context.streakDays
        switch currentStreak {
        case 7...: score += 5    // Week+ streak
        case 3..<7: score += 3    // 3+ day streak
        default: break
        }

        // Check if user is improving (using context data)
        if context.totalUsageToday < context.totalUsageYesterday && context.totalUsageYesterday > 0 {
            score += 3
        }

        // Check if user is under their weekly average
        if context.totalUsageToday < context.weeklyAverage && context.weeklyAverage > 0 {
            score += 2
        }

        // Add points if over goal (user needs intervention)
        if context.isOverGoal {
            score += 3
        }

        // Bonus for extended streaks (2+ weeks)
        if currentStreak >= 14 {
            score += 2
        }

        return max(0, min(20, score))
    }

    // MARK: - Helper Methods

    private func getTimeDescription(hour: Int, isWeekend: Bool) -> String {
        let timeOfDayName: String
        switch hour {
        case 0...2: timeOfDayName = "Late Night"
        case 3...5: timeOfDayName = "Early Morning"
        case 6...9: timeOfDayName = "Morning"
        case 10...16: timeOfDayName = "Mid-Day"
        case 17...21: timeOfDayName = "Evening"
        default: timeOfDayName = "Night"
        }

        let dayName = isWeekend ? "Weekend" : "Weekday"
        return "\(timeOfDayName) on \(dayName)"
    }

    private func getSessionPatternDescription(context: InterventionContext) -> String {
        if context.quickReopenAttempt {
            return "Quick Reopen"
        }
        if context.isFirstSessionOfDay {
            return "First Session"
        }
        if context.currentSessionMinutes >= 30 {
            return "Extended (>30min)"
        }
        if context.currentSessionMinutes >= 15 {
            return "Extended (>15min)"
        }
        if context.currentSessionMinutes >= 5 {
            return "Moderate (5-15min)"
        }
        return "Short (<5min)"
    }

    private func getCognitiveLoadDescription(context: InterventionContext) -> String {
        if context.quickReopenAttempt {
            return "Lower (compulsive)"
        }
        if context.currentSessionMinutes >= 20 {
            return "Higher (deep engagement)"
        }
        return "Moderate"
    }

    private func getHistoricalSuccessDescription(score: Int) -> String {
        switch score {
        case 20: return "Excellent success rate"
        case 17: return "Good success rate"
        case 14: return "Moderate success rate"
        case 10: return "Lower success rate"
        case 5: return "Poor success rate"
        default: return "Neutral (insufficient data)"
        }
    }

    private func getUserStateDescription(context: InterventionContext) -> String {
        var parts: [String] = []
        if context.isOverGoal { parts.append("Over goal") }
        if context.isLateNight { parts.append("Late night") }
        return parts.isEmpty ? "Normal state" : parts.joined(separator: ", ")
    }

    private func currentTimestampMs() -> Int64 {
        return Int64(Date().timeIntervalSince1970 * 1000)
    }

    // MARK: - Logging

    private func logDebug(_ message: String) {
        #if DEBUG
        print("[OpportunityDetector] DEBUG: \(message)")
        #endif
    }

    private func logInfo(_ message: String) {
        print("[OpportunityDetector] INFO: \(message)")
    }
}
