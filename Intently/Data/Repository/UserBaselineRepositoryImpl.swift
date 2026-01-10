//
//  UserBaselineRepositoryImpl.swift
//  Intently
//
//  Created on 2025-01-01.
//

import Foundation
import SwiftData

final class UserBaselineRepositoryImpl: UserBaselineRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func calculateBaseline() async throws -> UserBaseline {
        // TODO: Implement actual baseline calculation
        let startDate = Date()
        return UserBaseline(
            firstWeekStartDate: startDate,
            totalUsageMinutes: 0,
            averageDailyMinutes: 0.0,
            facebookAverageMinutes: 0.0,
            instagramAverageMinutes: 0.0,
            isBaselineComplete: false,
            calculationDate: Date()
        )
    }

    func getBaseline() async throws -> UserBaseline? {
        let descriptor = FetchDescriptor<UserBaseline>()
        let baselines = try context.fetch(descriptor)
        return baselines.first
    }

    func updateBaseline(_ baseline: UserBaseline) async throws {
        baseline.lastModified = Date()
        try context.save()
    }

    func deleteBaseline() async throws {
        let descriptor = FetchDescriptor<UserBaseline>()
        guard let baseline = try context.fetch(descriptor).first else { return }
        context.delete(baseline)
        try context.save()
    }

    func isBaselineComplete() async throws -> Bool {
        guard let baseline = try await getBaseline() else { return false }
        return baseline.isBaselineComplete
    }

    func getBaselineProgress() async throws -> BaselineProgress {
        // TODO: Implement actual progress calculation
        return BaselineProgress(
            daysCollected: 0,
            requiredDays: 7,
            isComplete: false,
            currentAverage: 0.0,
            projectedAverage: 0.0
        )
    }

    func addBaselineData(session: UsageSession) async throws {
        // TODO: Implement data collection
    }

    func getBaselineDays() async throws -> Int {
        // TODO: Implement actual calculation
        return 0
    }
}
