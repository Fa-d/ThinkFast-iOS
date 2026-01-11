//
//  DecisionLogger.swift
//  Intently
//
//  Created on 2025-01-11.
//  JITAI Phase 3: Logs all JitAI decisions for analytics and debugging
//

import Foundation

/// Decision Logger
/// Phase 3 JITAI: Structured logging of all JitAI decision points
///
/// Logs all key decision points in the JitAI pipeline:
/// - Persona detection results
/// - Opportunity detection scores and breakdowns
/// - Content selection weights and reasoning
/// - Rate limit decisions
/// - Intervention delivery events
/// - Outcome recording events
///
/// Output: JSON exportable logs for analysis and debugging
final class DecisionLogger: ObservableObject {

    // MARK: - Published Properties
    @Published var logCount: Int = 0
    @Published var recentLogs: [DecisionEvent] = []

    // MARK: - Constants
    private let maxLogs = 1000              // Maximum logs to keep in memory
    private let maxRecentLogs = 50          // Recent logs for quick access
    private let storageKey = "jitai_decision_logs"

    // MARK: - State
    private var logs: [DecisionEvent] = []
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    // MARK: - Initialization
    init() {
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601
        loadPersistedLogs()
    }

    // MARK: - Public Methods - Persona Detection

    /// Log persona detection result
    /// - Parameters:
    ///   - persona: Detected persona
    ///   - confidence: Confidence level
    ///   - analytics: Analytics data used for detection
    func logPersonaDetection(
        persona: UserPersona,
        confidence: ConfidenceLevel,
        analytics: PersonaAnalytics
    ) {
        var data: [String: AnyCodable] = [:]
        data["persona"] = AnyCodable(persona.rawValue)
        data["confidence"] = AnyCodable(confidence.rawValue)
        data["days_since_install"] = AnyCodable(analytics.daysSinceInstall)
        data["avg_daily_sessions"] = AnyCodable(analytics.avgDailySessions)
        data["avg_session_length_min"] = AnyCodable(analytics.avgSessionLengthMin)
        data["quick_reopen_rate"] = AnyCodable(analytics.quickReopenRate)
        data["usage_trend"] = AnyCodable(analytics.usageTrend.rawValue)
        data["total_sessions"] = AnyCodable(analytics.totalSessions)

        addLog(type: .personaDetection, data: data)
    }

    // MARK: - Public Methods - Opportunity Detection

    /// Log opportunity detection result
    /// - Parameters:
    ///   - score: Opportunity score (0-100)
    ///   - level: Opportunity level
    ///   - decision: Intervention decision
    ///   - breakdown: Score breakdown
    func logOpportunityDetection(
        score: Int,
        level: OpportunityLevel,
        decision: InterventionDecision,
        breakdown: OpportunityBreakdown
    ) {
        var data: [String: AnyCodable] = [:]
        data["score"] = AnyCodable(score)
        data["level"] = AnyCodable(level.rawValue)
        data["decision"] = AnyCodable(decision.rawValue)

        var breakdownData: [String: AnyCodable] = [:]
        breakdownData["time_receptiveness"] = AnyCodable(breakdown.timeReceptiveness)
        breakdownData["session_pattern"] = AnyCodable(breakdown.sessionPattern)
        breakdownData["cognitive_load"] = AnyCodable(breakdown.cognitiveLoad)
        breakdownData["historical_success"] = AnyCodable(breakdown.historicalSuccess)
        breakdownData["user_state"] = AnyCodable(breakdown.userState)

        var factors: [String: AnyCodable] = [:]
        for (key, value) in breakdown.factors {
            factors[key] = AnyCodable(value)
        }
        breakdownData["factors"] = AnyCodable(factors)

        data["breakdown"] = AnyCodable(breakdownData)

        addLog(type: .opportunityDetection, data: data)
    }

    // MARK: - Public Methods - Content Selection

    /// Log content selection result
    /// - Parameters:
    ///   - selected: Selected content type
    ///   - persona: Persona at time of selection
    ///   - weights: Weight map for content types
    ///   - reason: Reason for selection
    func logContentSelection(
        selected: ContentType,
        persona: UserPersona,
        weights: [ContentType: Int],
        reason: String
    ) {
        var data: [String: AnyCodable] = [:]
        data["selected"] = AnyCodable(selected.rawValue)
        data["persona"] = AnyCodable(persona.rawValue)

        var weightsData: [String: AnyCodable] = [:]
        for (contentType, weight) in weights {
            weightsData[contentType.rawValue] = AnyCodable(weight)
        }
        data["weights"] = AnyCodable(weightsData)
        data["reason"] = AnyCodable(reason)

        addLog(type: .contentSelection, data: data)
    }

    /// Log Thompson Sampling arm selection
    /// - Parameters:
    ///   - selection: Arm selection result
    ///   - allArmStats: Statistics for all arms at time of selection
    func logThompsonSamplingSelection(
        selection: ArmSelection,
        allArmStats: [ArmStats]
    ) {
        var data: [String: AnyCodable] = [:]
        data["selected_arm"] = AnyCodable(selection.armId)
        data["confidence"] = AnyCodable(selection.confidence)
        data["strategy"] = AnyCodable(selection.strategy)
        data["sampled_value"] = AnyCodable(selection.sampledValue)
        data["total_pulls"] = AnyCodable(selection.totalPulls)

        var statsArray: [[String: AnyCodable]] = []
        for stat in allArmStats {
            var statData: [String: AnyCodable] = [:]
            statData["arm_id"] = AnyCodable(stat.armId)
            statData["alpha"] = AnyCodable(stat.alpha)
            statData["beta"] = AnyCodable(stat.beta)
            statData["pull_count"] = AnyCodable(stat.pullCount)
            statData["success_rate"] = AnyCodable(stat.successRate)
            statData["sample_mean"] = AnyCodable(stat.sampleMean)
            statsArray.append(statData)
        }
        data["all_arm_stats"] = AnyCodable(statsArray)

        addLog(type: .contentSelection, data: data)
    }

    // MARK: - Public Methods - Rate Limiting

    /// Log rate limit decision
    /// - Parameters:
    ///   - allowed: Whether intervention was allowed
    ///   - reason: Reason for decision
    ///   - cooldownRemaining: Remaining cooldown time
    ///   - burdenLevel: Burden level at time of decision
    func logRateLimitDecision(
        allowed: Bool,
        reason: String,
        cooldownRemaining: Int64 = 0,
        burdenLevel: BurdenLevel = .moderate
    ) {
        var data: [String: AnyCodable] = [:]
        data["allowed"] = AnyCodable(allowed)
        data["reason"] = AnyCodable(reason)
        data["cooldown_remaining_ms"] = AnyCodable(cooldownRemaining)
        data["burden_level"] = AnyCodable(burdenLevel.rawValue)

        addLog(type: .rateLimitDecision, data: data)
    }

    // MARK: - Public Methods - Intervention Delivery

    /// Log intervention delivery
    /// - Parameters:
    ///   - method: Delivery method used
    ///   - contentId: Content identifier
    ///   - targetApp: Target app bundle ID
    ///   - success: Whether delivery was successful
    func logInterventionDelivered(
        method: InterventionDeliveryMethod,
        contentId: String,
        targetApp: String,
        success: Bool
    ) {
        var data: [String: AnyCodable] = [:]
        data["method"] = AnyCodable(method.rawValue)
        data["content_id"] = AnyCodable(contentId)
        data["target_app"] = AnyCodable(targetApp)
        data["success"] = AnyCodable(success)

        addLog(type: .interventionDelivered, data: data)
    }

    // MARK: - Public Methods - Outcome Recording

    /// Log outcome recording
    /// - Parameters:
    ///   - sessionId: Session identifier
    ///   - userChoice: User's choice
    ///   - wasEffective: Whether intervention was effective
    ///   - reward: Calculated reward
    func logOutcomeRecorded(
        sessionId: UUID,
        userChoice: String,
        wasEffective: Bool,
        reward: Float
    ) {
        var data: [String: AnyCodable] = [:]
        data["session_id"] = AnyCodable(sessionId.uuidString)
        data["user_choice"] = AnyCodable(userChoice)
        data["was_effective"] = AnyCodable(wasEffective)
        data["reward"] = AnyCodable(reward)

        addLog(type: .outcomeRecorded, data: data)
    }

    // MARK: - Public Methods - Export

    /// Export all logs as JSON string
    /// - Returns: JSON string of all logged events
    func exportLogs() async -> String {
        do {
            let data = try encoder.encode(logs)
            guard let jsonString = String(data: data, encoding: .utf8) else {
                return "{}"
            }
            return jsonString
        } catch {
            logDebug("Failed to export logs: \(error)")
            return "{}"
        }
    }

    /// Export logs of a specific type
    /// - Parameter type: Decision type to filter by
    /// - Returns: JSON string of filtered logs
    func exportLogs(type: DecisionType) async -> String {
        let filtered = logs.filter { $0.type == type }

        do {
            let data = try encoder.encode(filtered)
            guard let jsonString = String(data: data, encoding: .utf8) else {
                return "{}"
            }
            return jsonString
        } catch {
            logDebug("Failed to export logs: \(error)")
            return "{}"
        }
    }

    /// Get logs for a specific time range
    /// - Parameters:
    ///   - start: Start date
    ///   - end: End date
    /// - Returns: Array of logs in range
    func getLogsInRange(start: Date, end: Date) -> [DecisionEvent] {
        return logs.filter { event in
            event.timestamp >= start && event.timestamp <= end
        }
    }

    /// Get summary statistics
    /// - Returns: Summary of logged events
    func getSummary() async -> DecisionLogSummary {
        var typeCounts: [DecisionType: Int] = [:]

        for log in logs {
            typeCounts[log.type, default: 0] += 1
        }

        return DecisionLogSummary(
            totalLogs: logs.count,
            typeBreakdown: typeCounts,
            oldestLog: logs.first?.timestamp,
            newestLog: logs.last?.timestamp,
            timeRange: logs.isEmpty ? 0 : Int64((logs.last!.timestamp.timeIntervalSince(logs.first!.timestamp)))
        )
    }

    /// Clear all logs
    func clearLogs() {
        logs.removeAll()
        logCount = 0

        Task { @MainActor in
            recentLogs.removeAll()
        }

        savePersistedLogs()
        logInfo("Cleared all decision logs")
    }

    // MARK: - Private Methods

    private func addLog(type: DecisionType, data: [String: AnyCodable]) {
        let event = DecisionEvent(
            id: UUID(),
            timestamp: Date(),
            type: type,
            data: data
        )

        logs.append(event)

        // Trim if exceeding max
        if logs.count > maxLogs {
            logs.removeFirst(logs.count - maxLogs)
        }

        logCount = logs.count

        // Update recent logs
        Task { @MainActor in
            recentLogs.append(event)
            if recentLogs.count > maxRecentLogs {
                recentLogs.removeFirst(recentLogs.count - maxRecentLogs)
            }
        }

        // Persist periodically (not on every log for performance)
        if logs.count % 10 == 0 {
            savePersistedLogs()
        }

        logDebug("Logged \(type.rawValue): \(data.keys.joined(separator: ", "))")
    }

    private func savePersistedLogs() {
        // Only persist recent logs to avoid excessive storage
        let logsToSave = Array(logs.suffix(100))

        do {
            let data = try encoder.encode(logsToSave)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            logDebug("Failed to persist logs: \(error)")
        }
    }

    private func loadPersistedLogs() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else {
            return
        }

        do {
            let loadedLogs = try decoder.decode([DecisionEvent].self, from: data)
            logs = loadedLogs
            logCount = logs.count

            Task { @MainActor in
                recentLogs = Array(logs.suffix(maxRecentLogs))
            }

            logDebug("Loaded \(logs.count) persisted logs")
        } catch {
            logDebug("Failed to load persisted logs: \(error)")
        }
    }

    private func logDebug(_ message: String) {
        #if DEBUG
        print("[DecisionLogger] DEBUG: \(message)")
        #endif
    }

    private func logInfo(_ message: String) {
        print("[DecisionLogger] INFO: \(message)")
    }
}

// MARK: - Decision Event

struct DecisionEvent: Codable, Identifiable {
    let id: UUID
    let timestamp: Date
    let type: DecisionType
    let data: [String: AnyCodable]
}

// MARK: - Decision Type

enum DecisionType: String, Codable {
    case personaDetection = "persona_detection"
    case opportunityDetection = "opportunity_detection"
    case contentSelection = "content_selection"
    case rateLimitDecision = "rate_limit_decision"
    case interventionDelivered = "intervention_delivered"
    case outcomeRecorded = "outcome_recorded"
}

// MARK: - Decision Log Summary

struct DecisionLogSummary {
    let totalLogs: Int
    let typeBreakdown: [DecisionType: Int]
    let oldestLog: Date?
    let newestLog: Date?
    let timeRange: Int64  // Seconds between oldest and newest

    var formattedTimeRange: String {
        if timeRange < 60 {
            return "\(timeRange)s"
        } else if timeRange < 3600 {
            return "\(timeRange / 60)m"
        } else if timeRange < 86400 {
            return "\(timeRange / 3600)h"
        } else {
            return "\(timeRange / 86400)d"
        }
    }
}

// MARK: - AnyCodable Helper

/// Type-erased wrapper for Codable values
/// Enables encoding dictionaries with mixed value types
enum AnyCodable: Codable {
    case string(String)
    case int(Int)
    case double(Double)
    case float(Float)
    case bool(Bool)
    case null
    case array([AnyCodable])
    case dictionary([String: AnyCodable])

    init<T>(_ value: T?) {
        guard let value = value else {
            self = .null
            return
        }

        switch value {
        case let v as String:
            self = .string(v)
        case let v as Int:
            self = .int(v)
        case let v as Double:
            self = .double(v)
        case let v as Float:
            self = .float(v)
        case let v as Bool:
            self = .bool(v)
        case let v as [AnyCodable]:
            self = .array(v)
        case let v as [String: AnyCodable]:
            self = .dictionary(v)
        default:
            // For other types, try string representation
            if let describable = value as? CustomStringConvertible {
                self = .string(describable.description)
            } else {
                self = .null
            }
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            self = .null
        } else if let intValue = try? container.decode(Int.self) {
            self = .int(intValue)
        } else if let doubleValue = try? container.decode(Double.self) {
            self = .double(doubleValue)
        } else if let stringValue = try? container.decode(String.self) {
            self = .string(stringValue)
        } else if let boolValue = try? container.decode(Bool.self) {
            self = .bool(boolValue)
        } else if let arrayValue = try? container.decode([AnyCodable].self) {
            self = .array(arrayValue)
        } else if let dictValue = try? container.decode([String: AnyCodable].self) {
            self = .dictionary(dictValue)
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "AnyCodable value cannot be decoded"
            )
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch self {
        case .null:
            try container.encodeNil()
        case .string(let v):
            try container.encode(v)
        case .int(let v):
            try container.encode(v)
        case .double(let v):
            try container.encode(v)
        case .float(let v):
            try container.encode(v)
        case .bool(let v):
            try container.encode(v)
        case .array(let v):
            try container.encode(v)
        case .dictionary(let v):
            try container.encode(v)
        }
    }

    // Convenience accessors
    var stringValue: String? {
        if case .string(let v) = self { return v }
        return nil
    }

    var intValue: Int? {
        if case .int(let v) = self { return v }
        return nil
    }

    var doubleValue: Double? {
        if case .double(let v) = self { return v }
        return nil
    }

    var boolValue: Bool? {
        if case .bool(let v) = self { return v }
        return nil
    }
}
