//
//  UserBaselineRepository.swift
//  ThinkFast
//
//  Created on 2025-01-01.
//

import Foundation

protocol UserBaselineRepository {
    // MARK: - Baseline Management
    func calculateBaseline() async throws -> UserBaseline
    func getBaseline() async throws -> UserBaseline?
    func updateBaseline(_ baseline: UserBaseline) async throws
    func deleteBaseline() async throws

    // MARK: - Status
    func isBaselineComplete() async throws -> Bool
    func getBaselineProgress() async throws -> BaselineProgress

    // MARK: - Data Collection
    func addBaselineData(session: UsageSession) async throws
    func getBaselineDays() async throws -> Int
}

// MARK: - Supporting Types
struct BaselineProgress {
    let daysCollected: Int
    let requiredDays: Int
    let isComplete: Bool
    let currentAverage: Double
    let projectedAverage: Double

    var progressPercentage: Double {
        Double(daysCollected) / Double(requiredDays)
    }
}
