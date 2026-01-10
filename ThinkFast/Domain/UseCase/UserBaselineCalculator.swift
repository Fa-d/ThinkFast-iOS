//
//  UserBaselineCalculator.swift
//  ThinkFast
//
//  Created on 2025-01-07.
//  First-Week Retention: Calculates user baseline from first 7 days
//

import Foundation

/// User Baseline Calculator
///
/// Calculates the user's baseline usage from their first week of data.
/// Called on Day 7 or on demand to provide personalized comparison.
final class UserBaselineCalculator {

    // MARK: - Dependencies
    private let usageRepository: UsageRepository
    private let goalRepository: GoalRepository
    private let userDefaults: UserDefaults

    // MARK: - UserDefaults Keys
    private enum Keys {
        static let baselineCalculated = "baseline_calculated"
        static let baselineStartDate = "baseline_start_date"
        static let baselineEndDate = "baseline_end_date"
        static let baselineAverageMinutes = "baseline_average_minutes"
        static let baselineFacebookMinutes = "baseline_facebook_minutes"
        static let baselineInstagramMinutes = "baseline_instagram_minutes"
    }

    // MARK: - Initialization
    init(
        usageRepository: UsageRepository,
        goalRepository: GoalRepository,
        userDefaults: UserDefaults = .standard
    ) {
        self.usageRepository = usageRepository
        self.goalRepository = goalRepository
        self.userDefaults = userDefaults
    }

    // MARK: - Public Methods

    /// Calculate user baseline from first 7 days of usage
    /// - Returns: Calculated baseline info, or nil if not enough data
    func calculateBaseline() async -> BaselineComparisonInfo? {
        // 1. Get earliest goal to determine onboarding date
        let goals = (try? await goalRepository.getAllGoals()) ?? []
        guard !goals.isEmpty else {
            logDebug("No goals found, cannot calculate baseline")
            return nil
        }

        // Sort by start date and get earliest
        let sortedGoals = goals.sorted(by: { $0.startDate < $1.startDate })
        guard let earliestGoal = sortedGoals.first else {
            return nil
        }

        // 2. Calculate date range (first goal date + 6 days = 7 days total)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let startDate = dateFormatter.string(from: earliestGoal.startDate)
        guard let startDateObj = dateFormatter.date(from: startDate) else {
            return nil
        }

        guard let endDateObj = Calendar.current.date(byAdding: .day, value: 6, to: startDateObj) else {
            return nil
        }

        let endDate = dateFormatter.string(from: endDateObj)

        // 3. Check if we have 7 days of data
        let today = dateFormatter.string(from: Date())
        if endDate > today {
            logDebug("Not enough data yet (need \(endDate), have \(today))")
            return nil
        }

        // 4. Get sessions for first week
        let sessions = (try? await usageRepository.getSessionsInRange(
            startDate: startDate,
            endDate: endDate
        )) ?? []

        // 5. Calculate per-app usage
        var facebookTotalSeconds: TimeInterval = 0
        var instagramTotalSeconds: TimeInterval = 0

        for session in sessions {
            let durationSeconds = session.duration

            if session.targetApp.contains("facebook") {
                facebookTotalSeconds += durationSeconds
            } else if session.targetApp.contains("instagram") {
                instagramTotalSeconds += durationSeconds
            }
        }

        // 6. Convert to minutes and calculate averages
        let facebookMinutes = Int(facebookTotalSeconds / 60)
        let instagramMinutes = Int(instagramTotalSeconds / 60)
        let totalMinutes = facebookMinutes + instagramMinutes
        let averageDailyMinutes = totalMinutes / 7
        let facebookAverage = facebookMinutes / 7
        let instagramAverage = instagramMinutes / 7

        // 7. Create baseline info
        let baselineInfo = BaselineComparisonInfo(
            firstWeekStartDate: startDate,
            firstWeekEndDate: endDate,
            averageDailyMinutes: averageDailyMinutes,
            facebookAverageMinutes: facebookAverage,
            instagramAverageMinutes: instagramAverage
        )

        // 8. Save to UserDefaults
        saveBaselineInfo(baselineInfo)

        logInfo("Baseline calculated: \(averageDailyMinutes) min/day average")

        return baselineInfo
    }

    /// Get saved baseline from UserDefaults
    /// - Returns: Saved baseline info, or nil if not calculated
    func getSavedBaseline() -> BaselineComparisonInfo? {
        guard userDefaults.bool(forKey: Keys.baselineCalculated) else {
            return nil
        }

        guard let startDate = userDefaults.string(forKey: Keys.baselineStartDate),
              let endDate = userDefaults.string(forKey: Keys.baselineEndDate) else {
            return nil
        }

        let avgMinutes = userDefaults.integer(forKey: Keys.baselineAverageMinutes)
        let fbMinutes = userDefaults.integer(forKey: Keys.baselineFacebookMinutes)
        let igMinutes = userDefaults.integer(forKey: Keys.baselineInstagramMinutes)

        return BaselineComparisonInfo(
            firstWeekStartDate: startDate,
            firstWeekEndDate: endDate,
            averageDailyMinutes: avgMinutes,
            facebookAverageMinutes: fbMinutes,
            instagramAverageMinutes: igMinutes
        )
    }

    /// Check if baseline should be calculated
    /// - Returns: True if it's day 7 or later and baseline not yet calculated
    func shouldCalculateBaseline() async -> Bool {
        // Don't calculate if already done
        if getSavedBaseline() != nil {
            return false
        }

        // Check if we have goals
        let goals = (try? await goalRepository.getAllGoals()) ?? []
        guard !goals.isEmpty else {
            return false
        }

        // Check if it's been 7 days since first goal
        let sortedGoals = goals.sorted(by: { $0.startDate < $1.startDate })
        guard let earliestGoal = sortedGoals.first else {
            return false
        }

        guard let day7Date = Calendar.current.date(byAdding: .day, value: 6, to: earliestGoal.startDate) else {
            return false
        }

        return Date() >= day7Date
    }

    /// Get today's usage compared to baseline
    /// - Returns: Today's minutes, or nil if baseline not available
    func getTodayVsBaseline() async -> (today: Int, baseline: Int)? {
        guard let baseline = getSavedBaseline() else {
            return nil
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let today = dateFormatter.string(from: Date())

        let sessions = (try? await usageRepository.getSessionsInRange(
            startDate: today,
            endDate: today
        )) ?? []

        let todaySeconds = sessions.reduce(TimeInterval(0)) { total, session in
            return total + session.duration
        }

        let todayMinutes = Int(todaySeconds / 60)

        return (today: todayMinutes, baseline: baseline.averageDailyMinutes)
    }

    // MARK: - Private Methods

    /// Save baseline info to UserDefaults
    private func saveBaselineInfo(_ baseline: BaselineComparisonInfo) {
        userDefaults.set(true, forKey: Keys.baselineCalculated)
        userDefaults.set(baseline.firstWeekStartDate, forKey: Keys.baselineStartDate)
        userDefaults.set(baseline.firstWeekEndDate, forKey: Keys.baselineEndDate)
        userDefaults.set(baseline.averageDailyMinutes, forKey: Keys.baselineAverageMinutes)
        userDefaults.set(baseline.facebookAverageMinutes, forKey: Keys.baselineFacebookMinutes)
        userDefaults.set(baseline.instagramAverageMinutes, forKey: Keys.baselineInstagramMinutes)
    }

    /// Clear saved baseline (for testing purposes)
    func clearBaseline() {
        userDefaults.removeObject(forKey: Keys.baselineCalculated)
        userDefaults.removeObject(forKey: Keys.baselineStartDate)
        userDefaults.removeObject(forKey: Keys.baselineEndDate)
        userDefaults.removeObject(forKey: Keys.baselineAverageMinutes)
        userDefaults.removeObject(forKey: Keys.baselineFacebookMinutes)
        userDefaults.removeObject(forKey: Keys.baselineInstagramMinutes)
        logDebug("Baseline cleared")
    }

    // MARK: - Logging

    private func logDebug(_ message: String) {
        #if DEBUG
        print("[UserBaselineCalculator] DEBUG: \(message)")
        #endif
    }

    private func logInfo(_ message: String) {
        print("[UserBaselineCalculator] INFO: \(message)")
    }
}
