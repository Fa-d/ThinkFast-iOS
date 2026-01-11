//
//  ThompsonSamplingEngine.swift
//  Intently
//
//  Created on 2025-01-11.
//  JITAI Phase 3: Reinforcement learning for optimal content selection
//

import Foundation

/// Thompson Sampling Engine
/// Phase 3 JITAI: Multi-armed bandit using Thompson Sampling
///
/// Implements a contextual bandit algorithm using Thompson Sampling with
/// Beta conjugate priors for optimal content type selection.
///
/// Each content type (arm) maintains a Beta(α, β) distribution:
/// - α (alpha) = successes + prior (default 1)
/// - β (beta) = failures + prior (default 1)
///
/// The algorithm:
/// 1. For each arm, sample from Beta(α+1, β+1)
/// 2. Select arm with highest sample
/// 3. Observe reward and update arm's α, β
///
/// Storage: Persists state to UserDefaults with atomic updates
final class ThompsonSamplingEngine: ObservableObject {

    // MARK: - Published Properties
    @Published var hasSufficientData: Bool = false

    // MARK: - Constants
    private let storageKey = "thompson_sampling_arms"
    private let minPullsForSufficientData = 20  // Total pulls needed
    private let optimisticPrior: Float = 1.0    // Beta(1, 1) = uniform prior

    // Minimum data threshold per arm before it can be selected
    private let minArmPulls = 3

    // Reward thresholds
    private let rewardThreshold: Float = 0.3
    private let penaltyThreshold: Float = -0.3

    // MARK: - Dependencies
    private let userDefaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    // MARK: - State
    private var arms: [String: ThompsonSamplingState] = [:]
    private var armSelectionCount: [String: Int] = [:]
    private var totalPulls: Int = 0

    // MARK: - Initialization
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        loadState()
        updateSufficientDataStatus()
    }

    // MARK: - Public Methods

    /// Select an arm using Thompson Sampling
    /// - Parameter excludedArms: Arms to exclude from selection
    /// - Returns: Selection result with arm ID and metadata
    func selectArm(excludedArms: Set<String> = []) async -> ArmSelection {
        let availableArms = getAllArmIds().filter { !excludedArms.contains($0) }

        guard !availableArms.isEmpty else {
            logDebug("No arms available for selection")
            return createDefaultSelection()
        }

        // Sample from each arm's Beta distribution
        var bestArmId: String?
        var bestSample: Float = -1

        for armId in availableArms {
            let state = arms[armId] ?? ThompsonSamplingState()
            let sample = state.sample()

            if sample > bestSample {
                bestSample = sample
                bestArmId = armId
            }
        }

        guard let armId = bestArmId else {
            return createDefaultSelection()
        }

        // Update selection count
        armSelectionCount[armId, default: 0] += 1
        totalPulls += 1

        let state = arms[armId] ?? ThompsonSamplingState()
        let pullCount = armSelectionCount[armId] ?? 0

        // Determine strategy
        let strategy: String
        if pullCount < minArmPulls {
            strategy = "exploration"
        } else if Float.random(in: 0...1) < 0.1 {
            // 10% exploration rate
            strategy = "exploration"
        } else {
            strategy = "exploitation"
        }

        // Calculate confidence based on pull count
        let confidence = min(Float(pullCount) / Float(minPullsForSufficientData), 1.0)

        let selection = ArmSelection(
            armId: armId,
            confidence: confidence,
            strategy: strategy,
            sampledValue: bestSample,
            totalPulls: pullCount
        )

        logInfo("Selected arm: \(armId) (\(strategy)), sample: \(bestSample)")
        saveState()

        return selection
    }

    /// Update an arm with observed reward
    /// - Parameters:
    ///   - armId: The arm that was selected
    ///   - reward: Observed reward (-1.0 to 1.0)
    func updateArm(armId: String, reward: Float) async {
        var state = arms[armId] ?? ThompsonSamplingState()

        // Update alpha/beta based on reward
        // Positive reward -> increase alpha (success)
        // Negative reward -> increase beta (failure)
        if reward > rewardThreshold {
            state.alpha += 1
        } else if reward < penaltyThreshold {
            state.beta += 1
        } else {
            // Neutral reward - slight update to both
            state.alpha += 0.5
            state.beta += 0.5
        }

        arms[armId] = state
        updateSufficientDataStatus()

        logInfo("Updated arm \(armId): α=\(state.alpha), β=\(state.beta), reward=\(reward)")
        saveState()
    }

    /// Get statistics for a specific arm
    /// - Parameter armId: The arm to query
    /// - Returns: Arm statistics or nil if arm doesn't exist
    func getArmStats(armId: String) async -> ArmStats? {
        guard let state = arms[armId] else { return nil }

        let pullCount = armSelectionCount[armId] ?? 0
        let successRate = state.expectedValue

        return ArmStats(
            armId: armId,
            alpha: Int(state.alpha) - 1,  // Remove prior
            beta: Int(state.beta) - 1,    // Remove prior
            pullCount: pullCount,
            successRate: successRate,
            sampleMean: successRate,
            lastUpdated: Date()
        )
    }

    /// Get statistics for all arms
    /// - Returns: Array of arm statistics
    func getAllArmStats() async -> [ArmStats] {
        var stats: [ArmStats] = []

        for armId in getAllArmIds() {
            if let stat = await getArmStats(armId: armId) {
                stats.append(stat)
            }
        }

        // Sort by success rate descending
        stats.sort { $0.successRate > $1.successRate }

        return stats
    }

    /// Check if we have sufficient data to rely on Thompson Sampling
    /// - Returns: True if total pulls exceed threshold
    func hasSufficientDataForExploration() async -> Bool {
        return totalPulls >= minPullsForSufficientData
    }

    /// Reset an arm's statistics (e.g., if content type changes significantly)
    /// - Parameter armId: The arm to reset
    func resetArm(armId: String) async {
        arms[armId] = ThompsonSamplingState()
        armSelectionCount[armId] = 0
        updateSufficientDataStatus()
        saveState()
        logInfo("Reset arm: \(armId)")
    }

    /// Reset all arms (use with caution)
    func resetAllArms() async {
        arms.removeAll()
        armSelectionCount.removeAll()
        totalPulls = 0
        updateSufficientDataStatus()
        saveState()
        logInfo("Reset all arms")
    }

    // MARK: - Private Methods

    /// Get all valid arm IDs (content types)
    private func getAllArmIds() -> [String] {
        return ContentType.allCases.map { $0.rawValue }
    }

    /// Create a default selection when no data is available
    private func createDefaultSelection() -> ArmSelection {
        // Default to reflection as it's generally most effective
        return ArmSelection(
            armId: ContentType.reflection.rawValue,
            confidence: 0.0,
            strategy: "default",
            sampledValue: Float.random(in: 0...1),
            totalPulls: 0
        )
    }

    /// Update sufficient data status
    private func updateSufficientDataStatus() {
        hasSufficientData = totalPulls >= minPullsForSufficientData
    }

    // MARK: - State Persistence

    /// Load state from UserDefaults
    private func loadState() {
        guard let data = userDefaults.data(forKey: storageKey) else {
            initializeDefaultArms()
            return
        }

        do {
            let savedState = try decoder.decode(ThompsonSamplingStateStorage.self, from: data)
            self.arms = savedState.arms
            self.armSelectionCount = savedState.selectionCounts
            self.totalPulls = savedState.totalPulls
            logDebug("Loaded state with \(arms.count) arms, \(totalPulls) total pulls")
        } catch {
            logDebug("Failed to load state: \(error)")
            initializeDefaultArms()
        }
    }

    /// Save state to UserDefaults
    private func saveState() {
        let state = ThompsonSamplingStateStorage(
            arms: arms,
            selectionCounts: armSelectionCount,
            totalPulls: totalPulls
        )

        do {
            let data = try encoder.encode(state)
            userDefaults.set(data, forKey: storageKey)
            userDefaults.synchronize()
        } catch {
            logDebug("Failed to save state: \(error)")
        }
    }

    /// Initialize default arms with uniform priors
    private func initializeDefaultArms() {
        for contentType in ContentType.allCases {
            arms[contentType.rawValue] = ThompsonSamplingState()
            armSelectionCount[contentType.rawValue] = 0
        }
        logDebug("Initialized \(arms.count) default arms")
    }

    // MARK: - Logging

    private func logDebug(_ message: String) {
        #if DEBUG
        print("[ThompsonSamplingEngine] DEBUG: \(message)")
        #endif
    }

    private func logInfo(_ message: String) {
        print("[ThompsonSamplingEngine] INFO: \(message)")
    }
}

// MARK: - State Storage

/// Codable wrapper for persisting Thompson Sampling state
private struct ThompsonSamplingStateStorage: Codable {
    let arms: [String: ThompsonSamplingState]
    let selectionCounts: [String: Int]
    let totalPulls: Int

    enum CodingKeys: String, CodingKey {
        case arms
        case selectionCounts = "counts"
        case totalPulls = "total"
    }

    init(arms: [String: ThompsonSamplingState], selectionCounts: [String: Int], totalPulls: Int) {
        self.arms = arms
        self.selectionCounts = selectionCounts
        self.totalPulls = totalPulls
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.arms = try container.decode([String: ThompsonSamplingState].self, forKey: .arms)
        self.selectionCounts = try container.decode([String: Int].self, forKey: .selectionCounts)
        self.totalPulls = try container.decode(Int.self, forKey: .totalPulls)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(arms, forKey: .arms)
        try container.encode(selectionCounts, forKey: .selectionCounts)
        try container.encode(totalPulls, forKey: .totalPulls)
    }
}

// MARK: - Convenience Extensions

extension ThompsonSamplingEngine {

    /// Get the best performing content type
    /// - Returns: Best content type or nil if no data
    func getBestContentType() async -> ContentType? {
        let stats = await getAllArmStats()

        guard let best = stats.first,
              best.pullCount >= minArmPulls else {
            return nil
        }

        return ContentType(rawValue: best.armId)
    }

    /// Get the worst performing content type
    /// - Returns: Worst content type or nil if no data
    func getWorstContentType() async -> ContentType? {
        let stats = await getAllArmStats()

        guard let worst = stats.last,
              worst.pullCount >= minArmPulls else {
            return nil
        }

        return ContentType(rawValue: worst.armId)
    }

    /// Get exploration/exploitation ratio
    /// - Returns: Ratio of exploration to exploitation (0-1)
    func getExplorationRatio() async -> Float {
        guard totalPulls > 0 else { return 0 }

        let explorationCount = armSelectionCount.values.filter { $0 < minArmPulls }.count
        return Float(explorationCount) / Float(totalPulls)
    }
}
