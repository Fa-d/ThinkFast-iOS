//
//  JitaiModels.swift
//  ThinkFast
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
