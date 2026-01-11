//
//  JitaiModels.swift
//  Intently
//
//  Created on 2025-01-07.
//  JITAI (Just-In-Time Adaptive Intervention) Domain Models
//

import Foundation

// MARK: - Confidence Level
enum ConfidenceLevel: String, Codable {
    case low = "LOW"
    case medium = "MEDIUM"
    case high = "HIGH"
}

// MARK: - Intervention Decision
enum InterventionDecision: String, Codable {
    case interveneNow = "INTERVENE_NOW"
    case interveneWithConsideration = "INTERVENE_WITH_CONSIDERATION"
    case waitForBetterOpportunity = "WAIT_FOR_BETTER_OPPORTUNITY"
    case skipIntervention = "SKIP_INTERVENTION"
}

// MARK: - Opportunity Level
enum OpportunityLevel: String, Codable {
    case excellent = "EXCELLENT"
    case good = "GOOD"
    case moderate = "MODERATE"
    case poor = "POOR"
}

// MARK: - Usage Trend Type
enum UsageTrendType: String, Codable {
    case escalating = "ESCALATING"
    case increasing = "INCREASING"
    case stable = "STABLE"
    case decreasing = "DECREASING"
    case declining = "DECLINING"
}

// MARK: - Usage Pattern
enum UsagePattern: String, Codable {
    case compulsiveChecking = "COMPULSIVE_CHECKING"
    case bingeSessions = "BINGE_SESSIONS"
    case balanced = "BALANCED"
    case casual = "CASUAL"
    case escalating = "ESCALATING"
    case unknown = "UNKNOWN"
}

// MARK: - Intervention Frequency
enum JitaiInterventionFrequency: String, Codable {
    case onboarding = "ONBOARDING"
    case minimal = "MINIMAL"
    case conservative = "CONSERVATIVE"
    case balanced = "BALANCED"
    case moderate = "MODERATE"
    case adaptive = "ADAPTIVE"
}

// MARK: - Intervention Type (for context)
enum JitaiInterventionType: String, Codable {
    case reminder = "REMINDER"
    case timer = "TIMER"
    case custom = "CUSTOM"
}

// MARK: - Usage Comparison
enum UsageComparison: String, Codable {
    case less = "LESS"
    case more = "MORE"
    case same = "SAME"
    case noComparison = "NO_COMPARISON"
}

// MARK: - Friction Level
enum FrictionLevel: Int, Codable {
    case gentle = 0
    case moderate = 1
    case firm = 2
    case locked = 3

    var displayName: String {
        switch self {
        case .gentle: return "Gentle"
        case .moderate: return "Moderate"
        case .firm: return "Firm"
        case .locked: return "Locked"
        }
    }

    var description: String {
        switch self {
        case .gentle: return "Simple message, no delay"
        case .moderate: return "3-second pause before proceeding"
        case .firm: return "5-second pause with reflection prompts"
        case .locked: return "10-second pause, maximum friction"
        }
    }

    var delayMs: Int {
        switch self {
        case .gentle: return 0
        case .moderate: return 3000
        case .firm: return 5000
        case .locked: return 10000
        }
    }

    var requiresInteraction: Bool {
        switch self {
        case .gentle: return false
        case .moderate, .firm, .locked: return true
        }
    }

    static func fromDaysSinceInstall(_ days: Int) -> FrictionLevel {
        switch days {
        case 0..<14: return .gentle
        case 14..<28: return .moderate
        default: return .firm
        }
    }
}

// MARK: - Content Type
enum ContentType: String, Codable, CaseIterable {
    case reflection = "REFLECTION"
    case timeAlternative = "TIME_ALTERNATIVE"
    case breathing = "BREATHING"
    case stats = "STATS"
    case emotionalAppeal = "EMOTIONAL_APPEAL"
    case quote = "QUOTE"
    case gamification = "GAMIFICATION"
    case activitySuggestion = "ACTIVITY_SUGGESTION"

    var displayName: String {
        switch self {
        case .reflection: return "Reflection"
        case .timeAlternative: return "Time Alternative"
        case .breathing: return "Breathing"
        case .stats: return "Statistics"
        case .emotionalAppeal: return "Emotional Appeal"
        case .quote: return "Quote"
        case .gamification: return "Gamification"
        case .activitySuggestion: return "Activity Suggestion"
        }
    }
}

// MARK: - User Persona
enum UserPersona: String, Codable {
    case heavyCompulsiveUser = "HEAVY_COMPULSIVE_USER"
    case heavyBingeUser = "HEAVY_BINGE_USER"
    case moderateBalancedUser = "MODERATE_BALANCED_USER"
    case casualUser = "CASUAL_USER"
    case problematicPatternUser = "PROBLEMATIC_PATTERN_USER"
    case newUser = "NEW_USER"

    var displayName: String {
        switch self {
        case .heavyCompulsiveUser: return "Heavy Compulsive User"
        case .heavyBingeUser: return "Heavy Binge User"
        case .moderateBalancedUser: return "Moderate Balanced User"
        case .casualUser: return "Casual User"
        case .problematicPatternUser: return "Problematic Pattern User"
        case .newUser: return "New User"
        }
    }

    var description: String {
        switch self {
        case .heavyCompulsiveUser:
            return "15+ sessions/day, 40%+ quick reopens. Needs strong friction to break patterns."
        case .heavyBingeUser:
            return "6+ sessions/day, 25+ min sessions. Long engagement needs activity alternatives."
        case .moderateBalancedUser:
            return "8-12 sessions/day, 8-15 min sessions. Balanced approach needed."
        case .casualUser:
            return "4-6 sessions/day, 5-8 min sessions. Light touch interventions."
        case .problematicPatternUser:
            return "Escalating usage, 50%+ quick reopens. High priority intervention needed."
        case .newUser:
            return "First 14 days. Onboarding mode with gentle interventions."
        }
    }

    var frequency: JitaiInterventionFrequency {
        switch self {
        case .heavyCompulsiveUser: return .conservative
        case .heavyBingeUser: return .moderate
        case .moderateBalancedUser: return .balanced
        case .casualUser: return .adaptive
        case .problematicPatternUser: return .minimal
        case .newUser: return .onboarding
        }
    }

    var baseWeights: [ContentType: Int] {
        switch self {
        case .heavyCompulsiveUser:
            return [.reflection: 50, .timeAlternative: 20, .breathing: 15,
                    .emotionalAppeal: 10, .activitySuggestion: 5]
        case .heavyBingeUser:
            return [.timeAlternative: 40, .reflection: 30, .activitySuggestion: 15,
                    .emotionalAppeal: 10, .breathing: 5]
        case .moderateBalancedUser:
            return [.reflection: 35, .timeAlternative: 30, .breathing: 15,
                    .activitySuggestion: 10, .emotionalAppeal: 10]
        case .casualUser:
            return [.reflection: 25, .breathing: 20, .timeAlternative: 20,
                    .activitySuggestion: 20, .emotionalAppeal: 15]
        case .problematicPatternUser:
            return [.reflection: 60, .timeAlternative: 20, .emotionalAppeal: 15,
                    .breathing: 5, .activitySuggestion: 0]
        case .newUser:
            return [.reflection: 25, .breathing: 25, .timeAlternative: 20,
                    .activitySuggestion: 15, .emotionalAppeal: 15]
        }
    }

    static func detect(
        daysSinceInstall: Int,
        avgDailySessions: Double,
        avgSessionLengthMin: Double,
        quickReopenRate: Double,
        usageTrend: UsageTrendType
    ) -> UserPersona {
        // New user - first 14 days
        if daysSinceInstall < 14 {
            return .newUser
        }

        // Problematic pattern - escalating usage
        if usageTrend == .escalating && quickReopenRate > 0.40 {
            return .problematicPatternUser
        }

        // Heavy compulsive - many short sessions with high quick reopen rate
        if avgDailySessions >= 15 && quickReopenRate >= 0.35 && avgSessionLengthMin < 5 {
            return .heavyCompulsiveUser
        }

        // Heavy binge - fewer but longer sessions
        if avgDailySessions >= 6 && avgSessionLengthMin >= 20 {
            return .heavyBingeUser
        }

        // Moderate balanced - in the middle
        if avgDailySessions >= 8 && avgDailySessions <= 13 {
            return .moderateBalancedUser
        }

        // Casual - light usage
        if avgDailySessions < 8 {
            return .casualUser
        }

        // Default to moderate balanced
        return .moderateBalancedUser
    }
}

// MARK: - Intervention Context
struct InterventionContext: Codable {
    // Time context
    var timeOfDay: Int
    var dayOfWeek: Int
    var isWeekend: Bool

    // Session context
    var targetApp: String
    var currentSessionMinutes: Int
    var sessionCount: Int

    // Recent activity
    var lastSessionEndTime: Int64
    var timeSinceLastSession: Int64
    var quickReopenAttempt: Bool

    // Usage statistics
    var totalUsageToday: Int64
    var totalUsageYesterday: Int64
    var weeklyAverage: Int64

    // Goals and progress
    var goalMinutes: Int?
    var isOverGoal: Bool
    var streakDays: Int

    // User settings
    var userFrictionLevel: FrictionLevel
    var daysSinceInstall: Int

    // Best records
    var bestSessionMinutes: Int

    // Computed properties
    var isLateNight: Bool {
        timeOfDay >= 22 || timeOfDay <= 5
    }

    var isWeekendMorning: Bool {
        isWeekend && (6...11).contains(timeOfDay)
    }

    var isExtendedSession: Bool {
        currentSessionMinutes >= 15
    }

    var isHighFrequencyDay: Bool {
        sessionCount >= 10
    }

    var isFirstSessionOfDay: Bool {
        sessionCount == 1
    }

    var usageVsYesterday: UsageComparison {
        if totalUsageYesterday == 0 { return .noComparison }
        if totalUsageToday < totalUsageYesterday { return .less }
        if totalUsageToday > totalUsageYesterday { return .more }
        return .same
    }

    var usageVsAverage: UsageComparison {
        if weeklyAverage == 0 { return .noComparison }
        if totalUsageToday < weeklyAverage { return .less }
        if totalUsageToday > weeklyAverage { return .more }
        return .same
    }

    static func create(
        targetApp: String,
        currentSessionDuration: TimeInterval = 0,
        sessionCount: Int,
        lastSessionEndTime: Int64,
        totalUsageToday: Int64,
        totalUsageYesterday: Int64,
        weeklyAverage: Int64,
        goalMinutes: Int?,
        streakDays: Int,
        installDate: Date?,
        bestSessionMinutes: Int
    ) -> InterventionContext {
        let calendar = Calendar.current
        let now = Date()
        let timeOfDay = calendar.component(.hour, from: now)
        let dayOfWeek = calendar.component(.weekday, from: now)
        let isWeekend = dayOfWeek == 1 || dayOfWeek == 7

        let currentTime = Int64(now.timeIntervalSince1970 * 1000)
        let timeSinceLastSession = lastSessionEndTime > 0 ? currentTime - lastSessionEndTime : Int64.max
        let quickReopenAttempt = timeSinceLastSession < 2 * 60 * 1000

        let currentSessionMinutes = Int(currentSessionDuration / 60)
        let totalUsageTodayMinutes = totalUsageToday / 60
        let isOverGoal = goalMinutes.map { totalUsageTodayMinutes > $0 } ?? false

        let daysSinceInstall: Int
        if let installDate = installDate {
            let seconds = now.timeIntervalSince(installDate)
            daysSinceInstall = max(0, Int(seconds / (24 * 60 * 60)))
        } else {
            daysSinceInstall = 0
        }

        let frictionLevel = FrictionLevel.fromDaysSinceInstall(daysSinceInstall)

        return InterventionContext(
            timeOfDay: timeOfDay,
            dayOfWeek: dayOfWeek,
            isWeekend: isWeekend,
            targetApp: targetApp,
            currentSessionMinutes: currentSessionMinutes,
            sessionCount: sessionCount,
            lastSessionEndTime: lastSessionEndTime,
            timeSinceLastSession: timeSinceLastSession,
            quickReopenAttempt: quickReopenAttempt,
            totalUsageToday: totalUsageTodayMinutes,
            totalUsageYesterday: totalUsageYesterday / 60,
            weeklyAverage: weeklyAverage / 60,
            goalMinutes: goalMinutes,
            isOverGoal: isOverGoal,
            streakDays: streakDays,
            userFrictionLevel: frictionLevel,
            daysSinceInstall: daysSinceInstall,
            bestSessionMinutes: bestSessionMinutes
        )
    }
}

// MARK: - Detected Persona
struct DetectedPersona: Codable {
    var persona: UserPersona
    var confidence: ConfidenceLevel
    var analytics: PersonaAnalytics
    var detectedAt: Int64
}

// MARK: - Persona Analytics
struct PersonaAnalytics: Codable {
    var daysSinceInstall: Int
    var totalSessions: Int
    var avgDailySessions: Double
    var avgSessionLengthMin: Double
    var quickReopenRate: Double
    var usageTrend: UsageTrendType
    var lastAnalysisDate: String
}

// MARK: - Opportunity Detection
struct OpportunityDetection: Codable {
    var score: Int
    var level: OpportunityLevel
    var decision: InterventionDecision
    var breakdown: OpportunityBreakdown
    var detectedAt: Int64
}

// MARK: - Opportunity Breakdown
struct OpportunityBreakdown: Codable {
    var timeReceptiveness: Int
    var sessionPattern: Int
    var cognitiveLoad: Int
    var historicalSuccess: Int
    var userState: Int
    var factors: [String: String]
}

// MARK: - Persona-Aware Content Selection
struct PersonaAwareContentSelection: Codable {
    var contentType: ContentType
    var persona: UserPersona
    var selectionReason: String
    var weights: [String: Int]
    var detectedAt: Int64
}

// MARK: - Adaptive Rate Limit Result
struct AdaptiveRateLimitResult: Codable {
    var allowed: Bool
    var reason: String
    var cooldownRemainingMs: Int64
    var persona: UserPersona?
    var personaConfidence: ConfidenceLevel?
    var opportunityScore: Int?
    var opportunityLevel: OpportunityLevel?
    var decision: InterventionDecision?
    var decisionSource: String
}

// MARK: - Content Effectiveness Stats
struct ContentEffectivenessStats: Codable {
    var contentType: String
    var total: Int
    var dismissalRate: Double
    var avgDecisionTimeMs: Double?
}

// MARK: - Intervention Feedback
enum InterventionFeedback: String, Codable {
    case helpful = "HELPFUL"
    case disruptive = "DISRUPTIVE"
    case neutral = "NEUTRAL"
}

// MARK: - Burden Level (for burden tracking)
enum BurdenLevel: String, Codable {
    case low = "LOW"
    case moderate = "MODERATE"
    case high = "HIGH"
    case critical = "CRITICAL"

    var displayName: String {
        switch self {
        case .low: return "Low"
        case .moderate: return "Moderate"
        case .high: return "High"
        case .critical: return "Critical"
        }
    }

    var description: String {
        switch self {
        case .low: return "User is receptive to interventions"
        case .moderate: return "Some fatigue detected, proceed with caution"
        case .high: return "High fatigue, reduce intervention frequency"
        case .critical: return "Maximum fatigue, minimize interventions"
        }
    }
}

// MARK: - Trend (for engagement patterns)
enum Trend: String, Codable {
    case increasing = "INCREASING"
    case declining = "DECLINING"
    case stable = "STABLE"

    var displayName: String {
        switch self {
        case .increasing: return "Increasing"
        case .declining: return "Declining"
        case .stable: return "Stable"
        }
    }
}

// MARK: - Intervention Burden Metrics
struct InterventionBurdenMetrics: Codable {
    let avgResponseTime: Int64           // Average time to respond (ms)
    let dismissRate: Float               // Rate of dismissals (0-1)
    let timeoutRate: Float               // Rate of timeouts (0-1)
    let snoozeFrequency: Int             // Number of snoozes
    let recentEngagementTrend: Trend     // Engagement trend direction
    let interventionsLast24h: Int        // Interventions in last 24 hours
    let interventionsLast7d: Int         // Interventions in last 7 days
    let effectivenessRolling7d: Float    // Rolling effectiveness (0-1)
    let effectivenessTrend: Trend        // Effectiveness trend
    let helpfulnessRatio: Float          // Helpful vs total responses
    let sampleSize: Int                  // Number of data points

    private var calculatedBurdenScore: Int?
    private var calculatedBurdenLevel: BurdenLevel?

    // Explicit initializer for the public properties only
    init(
        avgResponseTime: Int64,
        dismissRate: Float,
        timeoutRate: Float,
        snoozeFrequency: Int,
        recentEngagementTrend: Trend,
        interventionsLast24h: Int,
        interventionsLast7d: Int,
        effectivenessRolling7d: Float,
        effectivenessTrend: Trend,
        helpfulnessRatio: Float,
        sampleSize: Int
    ) {
        self.avgResponseTime = avgResponseTime
        self.dismissRate = dismissRate
        self.timeoutRate = timeoutRate
        self.snoozeFrequency = snoozeFrequency
        self.recentEngagementTrend = recentEngagementTrend
        self.interventionsLast24h = interventionsLast24h
        self.interventionsLast7d = interventionsLast7d
        self.effectivenessRolling7d = effectivenessRolling7d
        self.effectivenessTrend = effectivenessTrend
        self.helpfulnessRatio = helpfulnessRatio
        self.sampleSize = sampleSize
        self.calculatedBurdenScore = nil
        self.calculatedBurdenLevel = nil
    }

    /// Calculate burden score (0-100, higher = more burdened)
    mutating func calculateBurdenScore() -> Int {
        if let cached = calculatedBurdenScore {
            return cached
        }

        // Dismiss rate contributes up to 30 points
        let dismissScore = Int(dismissRate * 30)

        // Timeout rate contributes up to 20 points
        let timeoutScore = Int(timeoutRate * 20)

        // Snooze frequency contributes up to 10 points
        let snoozeScore = min(snoozeFrequency * 2, 10)

        // Intervention frequency contributes up to 15 points
        let frequencyScore = min(interventionsLast24h * 2, 15)

        // Effectiveness contributes up to 25 points (lower effectiveness = higher burden)
        let effectivenessScore = Int((1.0 - effectivenessRolling7d) * 25)

        let totalScore = dismissScore + timeoutScore + snoozeScore + frequencyScore + effectivenessScore

        calculatedBurdenScore = min(totalScore, 100)
        return calculatedBurdenScore ?? 50
    }

    /// Get burden level based on score
    mutating func calculateBurdenLevel() -> BurdenLevel {
        if let cached = calculatedBurdenLevel {
            return cached
        }

        let score = calculateBurdenScore()

        switch score {
        case 0..<25:
            calculatedBurdenLevel = .low
        case 25..<50:
            calculatedBurdenLevel = .moderate
        case 50..<75:
            calculatedBurdenLevel = .high
        default:
            calculatedBurdenLevel = .critical
        }

        return calculatedBurdenLevel ?? .moderate
    }

    /// Get recommended cooldown multiplier based on burden
    mutating func getRecommendedCooldownMultiplier() -> Float {
        let level = calculateBurdenLevel()

        switch level {
        case .low:
            return 0.5      // Show interventions more frequently
        case .moderate:
            return 1.0      // Normal frequency
        case .high:
            return 1.5      // Reduce frequency
        case .critical:
            return 3.0      // Significantly reduce frequency
        }
    }

    /// Get human-readable summary
    func getBurdenSummary() -> String {
        let score = calculatedBurdenScore ?? 50
        let level = calculatedBurdenLevel ?? .moderate

        return "Burden: \(score)/100 (\(level.displayName)) - \(level.description)"
    }
}

// MARK: - Thompson Sampling State (for ML-based content selection)
struct ThompsonSamplingState: Codable {
    var alpha: Float    // Success count + prior
    var beta: Float     // Failure count + prior

    /// Initialize with optimistic prior (Beta(1, 1))
    init(alpha: Float = 1.0, beta: Float = 1.0) {
        self.alpha = alpha
        self.beta = beta
    }

    /// Sample from Beta distribution
    func sample() -> Float {
        // Use Gamma distribution approximation for Beta sampling
        // Beta(alpha, beta) = Gamma(alpha, 1) / (Gamma(alpha, 1) + Gamma(beta, 1))
        let gammaAlpha = gamma(alpha)
        let gammaBeta = gamma(beta)
        return gammaAlpha / (gammaAlpha + gammaBeta)
    }

    /// Simple Gamma approximation using log-gamma
    private func gamma(_ alpha: Float) -> Float {
        // Marsaglia and Tsang's method for Gamma sampling
        if alpha < 1 {
            return gamma(1 + alpha) * pow(Float.random(in: 0...1), 1.0 / alpha)
        }

        let d = alpha - 1.0 / 3.0
        let c = 1.0 / sqrt(9.0 * d)

        while true {
            var x: Float = 0
            var v: Float = 0

            repeat {
                x = Float.random(in: 0...1)
                v = 1.0 + c * x
            } while v <= 0

            v = v * v * v
            let u = Float.random(in: 0...1)

            if u < 1.0 - 0.0331 * (x * x) * (x * x) {
                return d * v * pow(u, 1.0 / alpha)
            }

            if log(u) < 0.5 * x * x + d * (1.0 - v + log(v)) {
                return d * v * pow(u, 1.0 / alpha)
            }
        }
    }

    /// Get expected value (mean of Beta distribution)
    var expectedValue: Float {
        return alpha / (alpha + beta)
    }

    /// Get total pulls
    var totalPulls: Int {
        return Int(alpha + beta - 2)  // Subtract priors
    }
}

// MARK: - Arm Selection Result
struct ArmSelection: Codable {
    let armId: String           // Content type selected
    let confidence: Float       // Confidence in selection (0-1)
    let strategy: String        // "exploration" or "exploitation"
    let sampledValue: Float     // The sampled value from Thompson Sampling
    let totalPulls: Int         // Total times this arm has been pulled

    var displayName: String {
        return ContentType(rawValue: armId)?.displayName ?? armId
    }
}

// MARK: - Arm Statistics
struct ArmStats: Codable {
    let armId: String
    let alpha: Int              // Success count
    let beta: Int               // Failure count
    let pullCount: Int          // Total selections
    let successRate: Float      // Alpha / (Alpha + Beta)
    let sampleMean: Float       // Expected value
    let lastUpdated: Date

    var contentType: ContentType? {
        return ContentType(rawValue: armId)
    }

    var displayName: String {
        return contentType?.displayName ?? armId
    }
}

// MARK: - Comprehensive Intervention Outcome
struct ComprehensiveInterventionOutcome: Codable {
    let sessionId: UUID
    let targetApp: String
    let contentType: String
    let userChoice: String
    let wasEffective: Bool
    let timeToShowDecisionMs: Int64
    let sessionDurationAfterIntervention: Int64?  // Duration after intervention (ms)
    let didReopenQuickly: Bool                    // Reopened within 5 minutes
    let totalSessionDuration: Int64?               // Full session duration (ms)
    let burdenScoreAtTime: Int
    let personaAtTime: String
    let opportunityScoreAtTime: Int
    let reward: Float                              // Calculated reward for ML
    let timestamp: Date

    /// Create from basic intervention data
    init(
        sessionId: UUID,
        targetApp: String,
        contentType: String,
        userChoice: String,
        wasEffective: Bool,
        timeToShowDecisionMs: Int64,
        sessionDurationAfterIntervention: Int64? = nil,
        didReopenQuickly: Bool = false,
        totalSessionDuration: Int64? = nil,
        burdenScoreAtTime: Int = 50,
        personaAtTime: String = "",
        opportunityScoreAtTime: Int = 50,
        timestamp: Date = Date()
    ) {
        self.sessionId = sessionId
        self.targetApp = targetApp
        self.contentType = contentType
        self.userChoice = userChoice
        self.wasEffective = wasEffective
        self.timeToShowDecisionMs = timeToShowDecisionMs
        self.sessionDurationAfterIntervention = sessionDurationAfterIntervention
        self.didReopenQuickly = didReopenQuickly
        self.totalSessionDuration = totalSessionDuration
        self.burdenScoreAtTime = burdenScoreAtTime
        self.personaAtTime = personaAtTime
        self.opportunityScoreAtTime = opportunityScoreAtTime
        self.timestamp = timestamp

        // Calculate reward based on effectiveness and compliance
        self.reward = Self.calculateReward(
            userChoice: userChoice,
            wasEffective: wasEffective,
            didReopenQuickly: didReopenQuickly,
            sessionDurationAfter: sessionDurationAfterIntervention
        )
    }

    /// Calculate reward for Thompson Sampling (range: -1.0 to 1.0)
    private static func calculateReward(
        userChoice: String,
        wasEffective: Bool,
        didReopenQuickly: Bool,
        sessionDurationAfter: Int64?
    ) -> Float {
        var reward: Float = 0.0

        // Base reward from user choice
        switch userChoice.lowercased() {
        case "go_back", "quit", "take_a_break":
            reward += 1.0
        case "snooze":
            reward += 0.5
        case "continue", "skip", "dismiss":
            reward += 0.0
        default:
            reward += 0.0
        }

        // Effectiveness bonus
        if wasEffective {
            reward += 0.3
        }

        // Quick reopen penalty (non-compliance)
        if didReopenQuickly {
            reward -= 0.5
        }

        // Session duration consideration
        if let durationAfter = sessionDurationAfter {
            let minutesAfter = durationAfter / 60_000

            // If user stayed away for a meaningful time, reward that
            if minutesAfter > 15 {
                reward += 0.2
            } else if minutesAfter < 5 {
                reward -= 0.3
            }
        }

        return max(-1.0, min(1.0, reward))
    }

    /// Check if outcome indicates compliance
    var isCompliant: Bool {
        return wasEffective && !didReopenQuickly
    }

    /// Get compliance duration in minutes
    var complianceDurationMinutes: Int? {
        guard let duration = sessionDurationAfterIntervention else { return nil }
        return Int(duration / 60_000)
    }
}

// MARK: - Intervention Delivery Method
enum InterventionDeliveryMethod: String, Codable {
    case automatic = "AUTOMATIC"       // Choose best method automatically
    case notification = "NOTIFICATION" // Use push notification
    case liveActivity = "LIVE_ACTIVITY" // Use Live Activity (iOS 16.1+)
    case inApp = "IN_APP"              // Show in-app when user is active
}
