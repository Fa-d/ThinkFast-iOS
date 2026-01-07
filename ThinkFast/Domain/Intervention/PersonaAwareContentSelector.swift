//
//  PersonaAwareContentSelector.swift
//  ThinkFast
//
//  Created on 2025-01-07.
//  JITAI Phase 2: Personalized intervention content based on behavioral persona
//

import Foundation

/// Persona-Aware Content Selector
/// Phase 2 JITAI: Personalized intervention content based on behavioral persona
///
/// This class enhances content selection by:
/// 1. Detecting user persona (cached if recent)
/// 2. Getting persona-specific base weights
/// 3. Applying context-aware adjustments (late night, quick reopen, etc.)
/// 4. Applying effectiveness adjustments (if 30+ interventions data)
/// 5. Selecting content type using weighted randomization
/// 6. Generating content with persona awareness
/// 7. Tracking selection for analytics
final class PersonaAwareContentSelector: ObservableObject {

    // MARK: - Dependencies
    private let personaDetector: PersonaDetector
    private let contentSelector: ContentSelector

    // MARK: - Constants
    private let minEffectivenessData = 30
    private let maxRecentSelectionsSize = 10

    // MARK: - State
    private var recentSelections: [ContentType] = []

    // MARK: - Initialization
    init(
        personaDetector: PersonaDetector,
        contentSelector: ContentSelector
    ) {
        self.personaDetector = personaDetector
        self.contentSelector = contentSelector
    }

    // MARK: - Public Methods

    /// Select content with persona awareness
    /// - Parameters:
    ///   - context: Current intervention context
    ///   - interventionType: REMINDER or TIMER
    ///   - effectivenessData: Optional historical effectiveness data
    /// - Returns: Persona-aware content selection with metadata
    func selectContent(
        context: InterventionContext,
        interventionType: JitaiInterventionType,
        effectivenessData: [ContentEffectivenessStats] = []
    ) async -> PersonaAwareContentSelection {

        // Step 1: Detect user persona (cached if recent)
        let detectedPersona = await personaDetector.detectPersona()
        let persona = detectedPersona.persona

        logInfo("Content selection for persona: \(persona.rawValue)")

        // Step 2: Get persona-specific base weights
        let baseWeights = getPersonaBaseWeights(persona: persona)

        // Step 3: Apply context-aware adjustments
        let contextAdjustedWeights = applyContextAdjustments(
            baseWeights: baseWeights,
            context: context,
            persona: persona,
            interventionType: interventionType
        )

        // Step 4: Apply effectiveness adjustments (if sufficient data)
        let totalEffectivenessData = effectivenessData.reduce(0) { $0 + $1.total }
        let finalWeights = totalEffectivenessData >= minEffectivenessData
            ? applyEffectivenessAdjustments(
                baseWeights: contextAdjustedWeights,
                effectivenessData: effectivenessData
            )
            : contextAdjustedWeights

        // Step 5: Select content type using weighted randomization
        let contentType = selectContentType(weights: finalWeights)

        // Step 6: Generate selection reason
        let selectionReason = generateSelectionReason(
            persona: persona,
            contentType: contentType,
            context: context
        )

        // Track selection to prevent repetition
        trackSelection(contentType: contentType)

        // Convert weights to [String: Int] for serialization
        let weightsStringMap = Dictionary(uniqueKeysWithValues: finalWeights.map { ($0.key.rawValue, $0.value) })

        return PersonaAwareContentSelection(
            contentType: contentType,
            persona: persona,
            selectionReason: selectionReason,
            weights: weightsStringMap,
            detectedAt: currentTimestampMs()
        )
    }

    /// Clear selection history (for testing)
    func clearHistory() {
        recentSelections.removeAll()
        logDebug("Selection history cleared")
    }

    // MARK: - Private Methods

    /// Get base weights for a persona
    private func getPersonaBaseWeights(persona: UserPersona) -> [ContentType: Int] {
        return persona.baseWeights
    }

    /// Apply context-aware adjustments to base weights
    private func applyContextAdjustments(
        baseWeights: [ContentType: Int],
        context: InterventionContext,
        persona: UserPersona,
        interventionType: JitaiInterventionType
    ) -> [ContentType: Int] {
        var adjustedWeights = baseWeights

        // Context adjustments by persona type
        switch persona {
        case .heavyCompulsiveUser:
            // HEAVY_COMPULSIVE_USER: Focus on breaking compulsive patterns
            if context.isLateNight {
                adjustedWeights[.reflection, default: 0] += 15
                adjustedWeights[.emotionalAppeal, default: 0] += 10
            }
            if context.quickReopenAttempt {
                // Double down on reflection for compulsive reopens
                adjustedWeights[.reflection, default: 0] *= 2
                adjustedWeights[.emotionalAppeal, default: 0] += 15
            }

        case .heavyBingeUser:
            // HEAVY_BINGE_USER: Focus on providing activity alternatives
            if context.isLateNight {
                adjustedWeights[.activitySuggestion, default: 0] += 20
                adjustedWeights[.breathing, default: 0] += 15
            }
            if context.isExtendedSession {
                // Extra emphasis on time alternatives for long binges
                let currentWeight = adjustedWeights[.timeAlternative, default: 0]
                adjustedWeights[.timeAlternative] = currentWeight + (currentWeight / 2)  // Add 50% more weight
            }

        case .moderateBalancedUser:
            // MODERATE_BALANCED_USER: Balanced approach
            if context.quickReopenAttempt {
                adjustedWeights[.reflection, default: 0] += 20
            }
            if context.isExtendedSession {
                adjustedWeights[.timeAlternative, default: 0] += 15
            }

        case .casualUser:
            // CASUAL_USER: Light touch interventions
            if context.isLateNight {
                adjustedWeights[.breathing, default: 0] += 15
                adjustedWeights[.activitySuggestion, default: 0] += 10
            }
            if context.quickReopenAttempt {
                adjustedWeights[.reflection, default: 0] += 10
                adjustedWeights[.breathing, default: 0] += 10
            }

        case .problematicPatternUser:
            // PROBLEMATIC_PATTERN_USER: Strong intervention needed
            // Always emphasize reflection for problematic patterns
            adjustedWeights[.reflection, default: 0] += 20

            if context.quickReopenAttempt {
                // Maximum emphasis on breaking the pattern
                adjustedWeights[.reflection, default: 0] += 30
                adjustedWeights[.emotionalAppeal, default: 0] += 20
                // Remove activity suggestions - they need reflection first
                adjustedWeights[.activitySuggestion] = 0
            }

        case .newUser:
            // NEW_USER: Gentle onboarding approach
            // Emphasize breathing and gentle content
            if context.isLateNight {
                adjustedWeights[.breathing, default: 0] += 15
                adjustedWeights[.activitySuggestion, default: 0] += 10
            }
            // Reduce emotional appeals for new users
            adjustedWeights[.emotionalAppeal, default: 0] = (adjustedWeights[.emotionalAppeal, default: 0] * 1) / 2
        }

        // Additional context-specific adjustments (apply to all personas)
        if context.isWeekendMorning {
            adjustedWeights[.activitySuggestion, default: 0] += 10
        }

        if interventionType == .timer {
            // Timer interventions always emphasize time alternatives
            adjustedWeights[.timeAlternative, default: 0] += 20
        }

        // Ensure no negative weights
        for key in adjustedWeights.keys {
            adjustedWeights[key] = max(0, adjustedWeights[key] ?? 0)
        }

        return adjustedWeights.filter { $0.value > 0 }
    }

    /// Apply effectiveness-based adjustments to weights
    private func applyEffectivenessAdjustments(
        baseWeights: [ContentType: Int],
        effectivenessData: [ContentEffectivenessStats]
    ) -> [ContentType: Int] {
        guard !effectivenessData.isEmpty else { return baseWeights }

        var adjustedWeights = baseWeights

        // Calculate average dismissal rate
        let avgSuccessRate = effectivenessData.map { $0.dismissalRate }.reduce(0, +) / Double(effectivenessData.count)

        for stats in effectivenessData {
            guard let contentType = mapStringToContentType(stats.contentType) else {
                continue
            }

            if let currentWeight = adjustedWeights[contentType] {
                // Boost weight if content performs above average
                let adjustment: Double
                switch stats.dismissalRate {
                case let rate where rate >= avgSuccessRate + 15:
                    adjustment = 1.25  // Significantly above average: boost by 25%
                case let rate where rate >= avgSuccessRate + 5:
                    adjustment = 1.15  // Moderately above average: boost by 15%
                case let rate where rate >= avgSuccessRate:
                    adjustment = 1.05  // Slightly above average: boost by 5%
                case let rate where rate < avgSuccessRate - 15:
                    adjustment = 0.8   // Significantly below average: reduce by 20%
                default:
                    adjustment = 1.0   // No change
                }

                adjustedWeights[contentType] = Int(Double(currentWeight) * adjustment)
            }
        }

        return adjustedWeights
    }

    /// Select content type using weighted randomization
    private func selectContentType(weights: [ContentType: Int]) -> ContentType {
        // Filter out recently selected types to ensure variety
        let availableTypes = weights.filter { !recentSelections.contains($0.key) }

        // If we've used all types recently, reset the history
        let finalWeights = availableTypes.isEmpty ? {
            recentSelections.removeAll()
            return weights
        }() : availableTypes

        // Perform weighted random selection
        let totalWeight = finalWeights.values.reduce(0, +)
        var randomValue = Int.random(in: 0..<totalWeight)

        for (contentType, weight) in finalWeights {
            randomValue -= weight
            if randomValue < 0 {
                return contentType
            }
        }

        // Fallback
        return .reflection
    }

    /// Map content type string to ContentType enum
    private func mapStringToContentType(_ contentType: String) -> ContentType? {
        switch contentType.lowercased() {
        case "reflection": return .reflection
        case "timealternative", "time_alternative": return .timeAlternative
        case "breathing": return .breathing
        case "stats", "usage": return .stats
        case "emotional", "emotionalappeal", "emotional_appeal": return .emotionalAppeal
        case "quote": return .quote
        case "gamification": return .gamification
        case "activity", "activitysuggestion", "activity_suggestion": return .activitySuggestion
        default: return nil
        }
    }

    /// Generate human-readable explanation for content selection
    private func generateSelectionReason(
        persona: UserPersona,
        contentType: ContentType,
        context: InterventionContext
    ) -> String {
        var parts: [String] = []

        // Add persona context
        parts.append("Detected as \(persona.displayName)")

        // Add content type rationale
        let rationale: String
        switch (persona, contentType) {
        case (.heavyCompulsiveUser, .reflection):
            rationale = "Reflection helps break compulsive patterns"
        case (.heavyCompulsiveUser, .timeAlternative):
            rationale = "Time alternatives provide perspective"
        case (.heavyCompulsiveUser, .breathing):
            rationale = "Breathing reduces immediate anxiety"
        case (.heavyBingeUser, .timeAlternative):
            rationale = "Time alternatives address extended sessions"
        case (.heavyBingeUser, .activitySuggestion):
            rationale = "Activity suggestions break binge cycles"
        case (.moderateBalancedUser, .reflection):
            rationale = "Self-awareness supports balanced usage"
        case (.moderateBalancedUser, .timeAlternative):
            rationale = "Time perspective aids moderation"
        case (.casualUser, _):
            rationale = "Light-touch support for casual usage"
        case (.problematicPatternUser, .reflection):
            rationale = "Strong reflection needed for escalating usage"
        case (.problematicPatternUser, .emotionalAppeal):
            rationale = "Direct appeal for problematic patterns"
        case (.newUser, _):
            rationale = "Gentle introduction for new user"
        default:
            rationale = "Selected for this context"
        }
        parts.append(rationale)

        // Add context factors
        var contextFactors: [String] = []
        if context.isLateNight { contextFactors.append("late night") }
        if context.quickReopenAttempt { contextFactors.append("quick reopen") }
        if context.isExtendedSession { contextFactors.append("extended session") }
        if context.isFirstSessionOfDay { contextFactors.append("first session") }

        if !contextFactors.isEmpty {
            parts.append("Context: \(contextFactors.joined(separator: ", "))")
        }

        return parts.joined(separator: " | ")
    }

    /// Track selection to prevent repetition
    private func trackSelection(contentType: ContentType) {
        recentSelections.append(contentType)

        // Keep only last N selections
        if recentSelections.count > maxRecentSelectionsSize {
            recentSelections.removeFirst()
        }
    }

    private func currentTimestampMs() -> Int64 {
        return Int64(Date().timeIntervalSince1970 * 1000)
    }

    // MARK: - Logging

    private func logDebug(_ message: String) {
        #if DEBUG
        print("[PersonaAwareContentSelector] DEBUG: \(message)")
        #endif
    }

    private func logInfo(_ message: String) {
        print("[PersonaAwareContentSelector] INFO: \(message)")
    }
}
