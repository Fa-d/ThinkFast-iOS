//
//  StopTrackingUseCase.swift
//  ThinkFast
//
//  Created on 2025-01-01.
//

import Foundation

struct StopTrackingUseCase {
    private let usageRepository: UsageRepository
    private let statsRepository: StatsRepository

    init(usageRepository: UsageRepository, statsRepository: StatsRepository) {
        self.usageRepository = usageRepository
        self.statsRepository = statsRepository
    }

    func execute(session: UsageSession) async throws {
        // End the session
        try await usageRepository.endSession(session)

        // Update daily stats
        let today = Date()
        if let existingStats = try? await statsRepository.getDailyStats(for: today) {
            // Update existing stats
            var updated = existingStats
            updated.totalMinutes += Int(session.duration / 60)
            updated.sessionsCount += 1
            updated.averageSessionMinutes = Double(updated.totalMinutes) / Double(updated.sessionsCount)
            try await statsRepository.saveDailyStats(updated)
        } else {
            // Create new stats
            let newStats = DailyStats(
                date: today,
                totalMinutes: Int(session.duration / 60),
                averageSessionMinutes: session.duration / 60,
                sessionsCount: 1,
                longestSessionMinutes: Int(session.duration / 60)
            )
            try await statsRepository.saveDailyStats(newStats)
        }
    }
}
