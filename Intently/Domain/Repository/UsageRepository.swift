//
//  UsageRepository.swift
//  Intently
//
//  Created on 2025-01-01.
//

import Foundation

protocol UsageRepository {
    // MARK: - Session Management
    func startSession(for app: String, appName: String?) async throws -> UsageSession
    func endSession(_ session: UsageSession) async throws
    func getSession(id: UUID) async throws -> UsageSession?
    func getSessions(for dateRange: ClosedRange<Date>) async throws -> [UsageSession]
    func getSessions(for app: String, dateRange: ClosedRange<Date>) async throws -> [UsageSession]

    // MARK: - JITAI Support
    func getSessionsInRange(startDate: String, endDate: String) async throws -> [UsageSession]

    // MARK: - Event Management
    func recordEvent(_ event: UsageEvent) async throws
    func getEvents(for session: UsageSession) async throws -> [UsageEvent]

    // MARK: - Active Session
    func getActiveSession() async throws -> UsageSession?
    func hasActiveSession(for app: String) async throws -> Bool
}
