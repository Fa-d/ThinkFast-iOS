//
//  PersonaDetector.swift
//  Intently
//
//  Created on 2025-01-07.
//  JITAI Phase 2: Analyzes user behavior to detect behavioral persona
//

import Foundation

/// Persona Detector
/// Phase 2 JITAI: Analyzes user behavior to detect behavioral persona
///
/// Uses intervention and usage data to automatically segment users into personas
/// for personalized intervention strategies.
///
/// Caching: Results are cached for 6 hours to avoid repeated analysis
final class PersonaDetector: ObservableObject {

    // MARK: - Dependencies
    private let interventionResultRepository: InterventionResultRepository
    private let usageRepository: UsageRepository
    private let userDefaults: UserDefaults

    // MARK: - Constants
    private let cacheDurationMs: Int64 = 6 * 60 * 60 * 1000 // 6 hours
    private let minDaysForAnalysis = 3
    private let optimalDaysForAnalysis = 14

    // MARK: - Cache
    private var cachedDetection: DetectedPersona?
    private var cacheTimestamp: Int64 = 0

    // MARK: - Initialization
    init(
        interventionResultRepository: InterventionResultRepository,
        usageRepository: UsageRepository,
        userDefaults: UserDefaults = .standard
    ) {
        self.interventionResultRepository = interventionResultRepository
        self.usageRepository = usageRepository
        self.userDefaults = userDefaults
    }

    // MARK: - Public Methods

    /// Detect user persona with caching
    /// - Parameter forceRefresh: Force re-analysis even if cache is valid
    /// - Returns: Detected persona with confidence level
    func detectPersona(forceRefresh: Bool = false) async -> DetectedPersona {
        let now = currentTimestampMs()

        // Return cached result if still valid
        if !forceRefresh,
           let cached = cachedDetection,
           (now - cacheTimestamp) < cacheDurationMs {
            logDebug("Using cached persona: \(cached.persona.rawValue)")
            return cached
        }

        // Perform fresh analysis
        let analytics = await gatherAnalytics()
        let persona = UserPersona.detect(
            daysSinceInstall: analytics.daysSinceInstall,
            avgDailySessions: analytics.avgDailySessions,
            avgSessionLengthMin: analytics.avgSessionLengthMin,
            quickReopenRate: analytics.quickReopenRate,
            usageTrend: analytics.usageTrend
        )
        let confidence = calculateConfidence(daysSinceInstall: analytics.daysSinceInstall)

        let detected = DetectedPersona(
            persona: persona,
            confidence: confidence,
            analytics: analytics,
            detectedAt: now
        )

        // Cache the result
        cachedDetection = detected
        cacheTimestamp = now

        logInfo("Detected persona: \(persona.displayName) (\(confidence.rawValue))")

        return detected
    }

    /// Clear cached persona detection
    /// Call when significant user behavior changes are expected
    func clearCache() {
        cachedDetection = nil
        cacheTimestamp = 0
        logDebug("Persona detection cache cleared")
    }

    // MARK: - Private Methods

    /// Gather behavioral analytics for persona detection
    private func gatherAnalytics() async -> PersonaAnalytics {
        let installDate = getInstallDate()
        let daysSinceInstall = installDate > 0
            ? Int((currentTimestampMs() - installDate) / (24 * 60 * 60 * 1000))
            : 0

        // Determine analysis date range
        let analysisDays = min(optimalDaysForAnalysis, max(minDaysForAnalysis, daysSinceInstall))

        let endDate = Date()
        guard let startDate = Calendar.current.date(byAdding: .day, value: -analysisDays, to: endDate) else {
            return PersonaAnalytics(
                daysSinceInstall: daysSinceInstall,
                totalSessions: 0,
                avgDailySessions: 0,
                avgSessionLengthMin: 0,
                quickReopenRate: 0,
                usageTrend: .stable,
                lastAnalysisDate: formatDate(endDate)
            )
        }

        // Get intervention results for analysis
        let startTimestamp = Int64(startDate.timeIntervalSince1970 * 1000)
        let endTimestamp = Int64(endDate.timeIntervalSince1970 * 1000) + (24 * 60 * 60 * 1000 - 1)

        let recentResults = (try? await interventionResultRepository.getResultsInRange(
            startTimestamp: startTimestamp,
            endTimestamp: endTimestamp
        )) ?? []

        // Get usage sessions for analysis
        let usageSessions = (try? await usageRepository.getSessionsInRange(
            startDate: formatDate(startDate),
            endDate: formatDate(endDate)
        )) ?? []

        // Calculate metrics
        let totalSessions = usageSessions.count
        let avgDailySessions = analysisDays > 0 ? Double(totalSessions) / Double(analysisDays) : 0

        let sessionDurations = usageSessions.compactMap { session -> Double? in
            guard let end = session.endTimestamp else { return nil }
            let duration = end.timeIntervalSince(session.startTimestamp)
            return duration > 0 ? duration / 60.0 : nil // Convert to minutes
        }
        let avgSessionLengthMin = sessionDurations.isEmpty ? 0 : sessionDurations.reduce(0, +) / Double(sessionDurations.count)

        // Calculate quick reopen rate
        let quickReopens = recentResults.filter { $0.quickReopen }.count
        let quickReopenRate = recentResults.isEmpty ? 0 : Double(quickReopens) / Double(recentResults.count)

        // Detect usage trend
        let usageTrend = detectUsageTrend(sessions: usageSessions, days: analysisDays)

        return PersonaAnalytics(
            daysSinceInstall: daysSinceInstall,
            totalSessions: totalSessions,
            avgDailySessions: avgDailySessions,
            avgSessionLengthMin: avgSessionLengthMin,
            quickReopenRate: quickReopenRate,
            usageTrend: usageTrend,
            lastAnalysisDate: formatDate(endDate)
        )
    }

    /// Detect usage trend over time
    private func detectUsageTrend(sessions: [UsageSession], days: Int) -> UsageTrendType {
        guard sessions.count >= 3, days >= 3 else {
            return .stable
        }

        // Group sessions by day and count
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let sessionsByDay = Dictionary(grouping: sessions) { session in
            dateFormatter.string(from: session.date)
        }.mapValues { $0.count }

        guard sessionsByDay.count >= 3 else {
            return .stable
        }

        // Sort by date and get counts
        let sortedDays = sessionsByDay.keys.sorted()
        let counts = sortedDays.compactMap { sessionsByDay[$0] }

        // Calculate trend using linear regression
        let count = counts.count
        let n = Double(count)
        let sumX = Double((0..<count).reduce(0) { $0 + $1 })
        let sumY = Double(counts.reduce(0) { $0 + $1 })
        let sumXY = Double(counts.enumerated().reduce(0) { $0 + $1.offset * $1.element })
        let sumXX = Double((0..<count).reduce(0) { $0 + $1 * $1 })

        // Calculate slope
        let slope: Double
        if n > 1 {
            let numerator = n * sumXY - sumX * sumY
            let denominator = n * sumXX - sumX * sumX
            slope = denominator != 0 ? numerator / denominator : 0
        } else {
            slope = 0
        }

        // Calculate average daily sessions
        let avgDaily = sumY > 0 ? Double(sumY) / n : 0

        // Classify trend based on slope
        switch (slope, avgDaily) {
        case (_, _) where slope > 0.5 && avgDaily > 10:
            return .escalating
        case (_, _) where slope > 0.2:
            return .increasing
        case (_, _) where slope < -0.5:
            return .declining
        case (_, _) where slope < -0.2:
            return .decreasing
        default:
            return .stable
        }
    }

    /// Calculate confidence level in persona detection
    private func calculateConfidence(daysSinceInstall: Int) -> ConfidenceLevel {
        switch daysSinceInstall {
        case 0..<7: return .low
        case 7..<14: return .medium
        default: return .high
        }
    }

    /// Get install date from user defaults
    private func getInstallDate() -> Int64 {
        return userDefaults.object(forKey: "installDate") as? Int64 ?? 0
    }

    /// Format date to string
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    /// Get current timestamp in milliseconds
    private func currentTimestampMs() -> Int64 {
        return Int64(Date().timeIntervalSince1970 * 1000)
    }

    // MARK: - Logging

    private func logDebug(_ message: String) {
        #if DEBUG
        print("[PersonaDetector] DEBUG: \(message)")
        #endif
    }

    private func logInfo(_ message: String) {
        print("[PersonaDetector] INFO: \(message)")
    }
}
