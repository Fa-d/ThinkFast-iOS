//
//  AdaptiveInterventionRateLimiter.swift
//  ThinkFast
//
//  Created on 2025-01-07.
//  JITAI Phase 2: Smart rate limiting with persona and opportunity awareness
//

import Foundation

/// Adaptive Intervention Rate Limiter
/// Phase 2 JITAI: Smart rate limiting with persona and opportunity awareness
///
/// Enhances the base rate limiting with:
/// 1. Persona detection (always runs for analytics)
/// 2. Opportunity score calculation (always runs for analytics)
/// 3. Basic rate limit checks (existing logic)
/// 4. Persona-specific frequency adjustments
/// 5. Rich decision context for analytics
final class AdaptiveInterventionRateLimiter: ObservableObject {

    // MARK: - Dependencies
    private let interventionPreferences: InterventionPreferences
    private let personaDetector: PersonaDetector
    private let opportunityDetector: OpportunityDetector
    private let userDefaults: UserDefaults

    // MARK: - Constants
    // Persona-specific cooldown multipliers
    private let problematicMultiplier: Float = 2.0    // 2x cooldown for problematic users
    private let heavyCompulsiveMultiplier: Float = 1.5  // 1.5x cooldown
    private let bingeMultiplier: Float = 1.0           // Normal cooldown
    private let moderateMultiplier: Float = 1.0        // Normal cooldown
    private let casualMultiplier: Float = 0.7          // 0.7x cooldown (more frequent)
    private let newUserMultiplier: Float = 0.5        // 0.5x cooldown (gentle onboarding)

    // Feedback adjustments
    private let helpfulCooldownReduction: Float = 0.9    // -10% cooldown
    private let disruptiveCooldownIncrease: Float = 1.2  // +20% cooldown

    // Base cooldown
    private let baseCooldownMs: Int64 = 5 * 60 * 1000  // 5 minutes

    // MARK: - State
    @Published var lastInterventionTime: Int64 = 0
    @Published var currentCooldown: Int64 = 0

    // MARK: - Initialization
    init(
        interventionPreferences: InterventionPreferences,
        personaDetector: PersonaDetector,
        opportunityDetector: OpportunityDetector,
        userDefaults: UserDefaults = .standard
    ) {
        self.interventionPreferences = interventionPreferences
        self.personaDetector = personaDetector
        self.opportunityDetector = opportunityDetector
        self.userDefaults = userDefaults

        // Load saved state
        self.lastInterventionTime = userDefaults.object(forKey: "lastInterventionTime") as? Int64 ?? 0
        self.currentCooldown = userDefaults.object(forKey: "currentCooldown") as? Int64 ?? baseCooldownMs
    }

    // MARK: - Public Methods

    /// Check if we can show an intervention with JITAI intelligence
    ///
    /// IMPORTANT: This ALWAYS runs persona and opportunity detection, even when
    /// basic rate limit checks fail. This provides rich context for analytics and
    /// better understanding of user behavior.
    ///
    /// - Parameters:
    ///   - interventionContext: Current intervention context
    ///   - interventionType: Type of intervention (REMINDER or TIMER)
    ///   - sessionDurationMs: Duration of current session
    ///   - forceRefreshPersona: Force persona re-detection
    /// - Returns: AdaptiveRateLimitResult with rich JITAI context
    func canShowIntervention(
        interventionContext: InterventionContext,
        interventionType: JitaiInterventionType,
        sessionDurationMs: TimeInterval,
        forceRefreshPersona: Bool = false
    ) async -> AdaptiveRateLimitResult {

        // Step 1: Always detect user persona (for analytics and better context)
        let detectedPersona = await personaDetector.detectPersona(forceRefresh: forceRefreshPersona)
        let persona = detectedPersona.persona
        let personaConfidence = detectedPersona.confidence

        // Step 2: Always calculate opportunity score (for analytics and better context)
        let opportunityDetection = await opportunityDetector.detectOpportunity(
            context: interventionContext
        )
        let opportunityScore = opportunityDetection.score
        let opportunityLevel = opportunityDetection.level
        let jitaiDecision = opportunityDetection.decision

        // Step 3: Basic rate limit checks (existing logic)
        let now = currentTimestampMs()
        let timeSinceLastIntervention = now - lastInterventionTime

        if timeSinceLastIntervention < currentCooldown {
            // In cooldown period
            return AdaptiveRateLimitResult(
                allowed: false,
                reason: "Cooldown active. \(formattedTimeRemaining(timeSinceLastIntervention)) remaining",
                cooldownRemainingMs: currentCooldown - timeSinceLastIntervention,
                persona: persona,
                personaConfidence: personaConfidence,
                opportunityScore: opportunityScore,
                opportunityLevel: opportunityLevel,
                decision: jitaiDecision,
                decisionSource: "BASIC_RATE_LIMIT"
            )
        }

        // Step 4: Apply persona-specific frequency rules
        // Extended "daytime" window to 6 AM - 11 PM
        let isDaytime = (6...23).contains(interventionContext.timeOfDay)
        let personaAllowed = checkPersonaFrequencyRules(
            persona: persona,
            opportunityScore: opportunityScore,
            opportunityLevel: opportunityLevel,
            isDaytime: isDaytime
        )

        if !personaAllowed {
            let reason = generatePersonaBlockReason(
                persona: persona,
                opportunityScore: opportunityScore,
                opportunityLevel: opportunityLevel
            )

            // Calculate cooldown based on persona
            let personaCooldownMs = calculatePersonaCooldown(persona: persona)

            return AdaptiveRateLimitResult(
                allowed: false,
                reason: reason,
                cooldownRemainingMs: personaCooldownMs,
                persona: persona,
                personaConfidence: personaConfidence,
                opportunityScore: opportunityScore,
                opportunityLevel: opportunityLevel,
                decision: .skipIntervention,
                decisionSource: "PERSONA_FREQUENCY"
            )
        }

        // Step 5: Apply JITAI decision filter
        let finalDecision: AdaptiveRateLimitResult
        switch jitaiDecision {
        case .skipIntervention:
            finalDecision = AdaptiveRateLimitResult(
                allowed: false,
                reason: "Low opportunity score (\(opportunityScore)/100)",
                cooldownRemainingMs: 5 * 60 * 1000,  // 5 minutes
                persona: persona,
                personaConfidence: personaConfidence,
                opportunityScore: opportunityScore,
                opportunityLevel: opportunityLevel,
                decision: jitaiDecision,
                decisionSource: "OPPORTUNITY_DETECTION"
            )
        default:
            // All checks passed
            finalDecision = AdaptiveRateLimitResult(
                allowed: true,
                reason: generateSuccessReason(
                    persona: persona,
                    opportunityScore: opportunityScore,
                    opportunityLevel: opportunityLevel,
                    jitaiDecision: jitaiDecision
                ),
                cooldownRemainingMs: 0,
                persona: persona,
                personaConfidence: personaConfidence,
                opportunityScore: opportunityScore,
                opportunityLevel: opportunityLevel,
                decision: jitaiDecision,
                decisionSource: "JITAI_APPROVED"
            )
        }

        return finalDecision
    }

    /// Record that an intervention was shown
    func recordIntervention(interventionType: JitaiInterventionType) {
        lastInterventionTime = currentTimestampMs()
        currentCooldown = calculatePersonaCooldown(
            persona: getPersonaFromFrequency(interventionType)
        )
        saveState()
    }

    /// Adjust cooldown based on user feedback
    func adjustCooldownForFeedback(feedback: InterventionFeedback) {
        let currentMultiplier = getCooldownMultiplier()
        let newMultiplier: Float

        switch feedback {
        case .helpful:
            let reduced = currentMultiplier * helpfulCooldownReduction
            newMultiplier = max(0.5, reduced)  // Minimum 0.5x
        case .disruptive:
            let increased = currentMultiplier * disruptiveCooldownIncrease
            newMultiplier = min(3.0, increased)  // Maximum 3.0x
        case .neutral:
            newMultiplier = currentMultiplier
        }

        if newMultiplier != currentMultiplier {
            setCooldownMultiplier(newMultiplier)
            logInfo("Cooldown adjusted for \(feedback.rawValue): \(currentMultiplier) → \(newMultiplier)")
        }
    }

    /// Escalate cooldown when user repeatedly dismisses
    func escalateCooldown() {
        currentCooldown = min(30 * 60 * 1000, currentCooldown + baseCooldownMs)  // Max 30 min
        saveState()
    }

    /// Reset cooldown when user engages positively
    func resetCooldown() {
        currentCooldown = baseCooldownMs
        saveState()
    }

    // MARK: - Private Methods

    /// Check persona-specific frequency rules
    private func checkPersonaFrequencyRules(
        persona: UserPersona,
        opportunityScore: Int,
        opportunityLevel: OpportunityLevel,
        isDaytime: Bool
    ) -> Bool {
        switch persona.frequency {
        case .minimal:
            // MINIMAL: Only EXCELLENT opportunities
            return opportunityLevel == .excellent

        case .conservative:
            // CONSERVATIVE: Only GOOD or EXCELLENT
            return opportunityLevel == .excellent || opportunityLevel == .good

        case .balanced:
            // BALANCED: Anything except POOR
            return opportunityLevel != .poor

        case .moderate:
            // MODERATE: Score >= 25 (includes MODERATE and above)
            return opportunityScore >= 25

        case .adaptive:
            // ADAPTIVE: Context-dependent
            if opportunityLevel == .excellent { return true }
            if opportunityLevel == .good && isDaytime { return true }
            return opportunityScore >= 40

        case .onboarding:
            // ONBOARDING: Moderate+, daytime only (6 AM - 11 PM)
            return isDaytime && opportunityScore >= 30
        }
    }

    /// Generate explanation for why intervention was blocked by persona rules
    private func generatePersonaBlockReason(
        persona: UserPersona,
        opportunityScore: Int,
        opportunityLevel: OpportunityLevel
    ) -> String {
        switch persona.frequency {
        case .minimal:
            return "Problematic pattern: Only EXCELLENT opportunities allowed (score: \(opportunityScore), level: \(opportunityLevel.rawValue))"
        case .conservative:
            return "Heavy compulsive: Only GOOD or EXCELLENT opportunities (score: \(opportunityScore), level: \(opportunityLevel.rawValue))"
        case .balanced:
            return "Opportunity level too low: \(opportunityLevel.rawValue) (score: \(opportunityScore))"
        case .moderate:
            return "Score below threshold: \(opportunityScore) < 25"
        case .adaptive:
            return "Adaptive filtering: Current context not optimal (score: \(opportunityScore))"
        case .onboarding:
            return "New user onboarding: Daytime, moderate+ opportunities only"
        }
    }

    /// Generate success reason explaining why intervention was allowed
    private func generateSuccessReason(
        persona: UserPersona,
        opportunityScore: Int,
        opportunityLevel: OpportunityLevel,
        jitaiDecision: InterventionDecision
    ) -> String {
        var parts: [String] = []
        parts.append("Persona: \(persona.rawValue)")
        parts.append("Opportunity: \(opportunityLevel.rawValue) (\(opportunityScore)/100)")
        parts.append("Decision: \(jitaiDecision.rawValue)")
        return parts.joined(separator: " | ")
    }

    /// Calculate persona-specific cooldown in milliseconds
    private func calculatePersonaCooldown(persona: UserPersona) -> Int64 {
        let baseMultiplier: Float
        switch persona {
        case .problematicPatternUser:
            baseMultiplier = problematicMultiplier
        case .heavyCompulsiveUser:
            baseMultiplier = heavyCompulsiveMultiplier
        case .heavyBingeUser:
            baseMultiplier = bingeMultiplier
        case .moderateBalancedUser:
            baseMultiplier = moderateMultiplier
        case .casualUser:
            baseMultiplier = casualMultiplier
        case .newUser:
            baseMultiplier = newUserMultiplier
        }

        // Apply feedback adjustments
        let currentMultiplier = getCooldownMultiplier()
        let adjustedMultiplier = baseMultiplier * currentMultiplier

        return Int64(Float(baseCooldownMs) * adjustedMultiplier)
    }

    private func getPersonaFromFrequency(_ type: JitaiInterventionType) -> UserPersona {
        // This is a simplified mapping - in practice, we'd use the detected persona
        return .moderateBalancedUser
    }

    private func getCooldownMultiplier() -> Float {
        return userDefaults.float(forKey: "cooldownMultiplier")
    }

    private func setCooldownMultiplier(_ value: Float) {
        userDefaults.set(value, forKey: "cooldownMultiplier")
    }

    private func saveState() {
        userDefaults.set(lastInterventionTime, forKey: "lastInterventionTime")
        userDefaults.set(currentCooldown, forKey: "currentCooldown")
    }

    private func formattedTimeRemaining(_ timeSinceLast: Int64) -> String {
        let remaining = currentCooldown - timeSinceLast
        let minutes = remaining / (60 * 1000)
        let seconds = (remaining % (60 * 1000)) / 1000
        return "\(minutes)m \(seconds)s"
    }

    private func currentTimestampMs() -> Int64 {
        return Int64(Date().timeIntervalSince1970 * 1000)
    }

    // MARK: - Logging

    private func logDebug(_ message: String) {
        #if DEBUG
        print("[AdaptiveInterventionRateLimiter] DEBUG: \(message)")
        #endif
    }

    private func logInfo(_ message: String) {
        print("[AdaptiveInterventionRateLimiter] INFO: \(message)")
    }
}

// MARK: - Intervention Preferences

protocol InterventionPreferences {
    func getCooldownMultiplier() -> Float
    func setCooldownMultiplier(_ value: Float)
}

// Default implementation using UserDefaults
extension UserDefaults: InterventionPreferences {
    func getCooldownMultiplier() -> Float {
        return float(forKey: "cooldownMultiplier")
    }

    func setCooldownMultiplier(_ value: Float) {
        set(value, forKey: "cooldownMultiplier")
    }
}
