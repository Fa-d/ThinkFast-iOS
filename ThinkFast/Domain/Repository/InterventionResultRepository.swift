//
//  InterventionResultRepository.swift
//  ThinkFast
//
//  Created on 2025-01-01.
//

import Foundation

protocol InterventionResultRepository {
    // MARK: - Result Management
    func saveResult(_ result: InterventionResult) async throws
    func getResults(for sessionId: UUID) async throws -> [InterventionResult]
    func getResults(for app: String, dateRange: ClosedRange<Date>) async throws -> [InterventionResult]
    func getAllResults() async throws -> [InterventionResult]

    // MARK: - JITAI Support
    func getResultsInRange(startTimestamp: Int64, endTimestamp: Int64) async throws -> [InterventionResult]
    func getRecentResultsForApp(targetApp: String, limit: Int) async throws -> [InterventionResult]

    // MARK: - Effectiveness
    func getEffectivenessMetrics(for app: String?) async throws -> EffectivenessData
    func getSuccessRate(for interventionType: String) async throws -> Double
    func getMostEffectiveIntervention() async throws -> String?

    // MARK: - Analytics
    func getAverageResponseTime() async throws -> TimeInterval
    func getQuitRate() async throws -> Double
}

// MARK: - Supporting Types
struct EffectivenessData {
    let totalInterventions: Int
    let successfulInterventions: Int
    let quitRate: Double
    let skipRate: Double
    let continueRate: Double
    let typeBreakdown: [String: TypeMetrics]
    let bestTimeOfDay: String
}

struct TypeMetrics {
    let totalShown: Int
    let successCount: Int
    let successRate: Double
}
