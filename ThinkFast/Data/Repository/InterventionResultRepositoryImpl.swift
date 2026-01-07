//
//  InterventionResultRepositoryImpl.swift
//  ThinkFast
//
//  Created on 2025-01-01.
//

import Foundation
import SwiftData

final class InterventionResultRepositoryImpl: InterventionResultRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func saveResult(_ result: InterventionResult) async throws {
        context.insert(result)
        try context.save()
    }

    func getResults(for sessionId: UUID) async throws -> [InterventionResult] {
        let descriptor = FetchDescriptor<InterventionResult>(
            predicate: #Predicate { $0.sessionId == sessionId }
        )
        return try context.fetch(descriptor)
    }

    func getResults(for app: String, dateRange: ClosedRange<Date>) async throws -> [InterventionResult] {
        let descriptor = FetchDescriptor<InterventionResult>(
            predicate: #Predicate { $0.targetApp == app && $0.feedbackTimestamp >= dateRange.lowerBound && $0.feedbackTimestamp <= dateRange.upperBound }
        )
        return try context.fetch(descriptor)
    }

    func getAllResults() async throws -> [InterventionResult] {
        let descriptor = FetchDescriptor<InterventionResult>()
        return try context.fetch(descriptor)
    }

    func getEffectivenessMetrics(for app: String?) async throws -> EffectivenessData {
        // TODO: Implement actual calculation
        return EffectivenessData(
            totalInterventions: 0,
            successfulInterventions: 0,
            quitRate: 0.0,
            skipRate: 0.0,
            continueRate: 0.0,
            typeBreakdown: [:],
            bestTimeOfDay: "morning"
        )
    }

    func getSuccessRate(for interventionType: String) async throws -> Double {
        // TODO: Implement actual calculation
        return 0.5
    }

    func getMostEffectiveIntervention() async throws -> String? {
        // TODO: Implement actual logic
        return "reflection"
    }

    func getAverageResponseTime() async throws -> TimeInterval {
        // TODO: Implement actual calculation
        return 5.0
    }

    func getQuitRate() async throws -> Double {
        // TODO: Implement actual calculation
        return 0.3
    }
}
