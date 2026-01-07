//
//  UsageRepositoryImpl.swift
//  ThinkFast
//
//  Created on 2025-01-01.
//

import Foundation
import SwiftData

final class UsageRepositoryImpl: UsageRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func startSession(for app: String, appName: String?) async throws -> UsageSession {
        let session = UsageSession(
            targetApp: app,
            targetAppName: appName,
            startTimestamp: Date(),
            date: Date()
        )
        context.insert(session)
        try context.save()
        return session
    }

    func endSession(_ session: UsageSession) async throws {
        session.endTimestamp = Date()
        session.duration = session.endTimestamp!.timeIntervalSince(session.startTimestamp)
        try context.save()
    }

    func getSession(id: UUID) async throws -> UsageSession? {
        let descriptor = FetchDescriptor<UsageSession>(
            predicate: #Predicate { $0.id == id }
        )
        return try context.fetch(descriptor).first
    }

    func getSessions(for dateRange: ClosedRange<Date>) async throws -> [UsageSession] {
        let descriptor = FetchDescriptor<UsageSession>(
            predicate: #Predicate { $0.date >= dateRange.lowerBound && $0.date <= dateRange.upperBound }
        )
        return try context.fetch(descriptor)
    }

    func getSessions(for app: String, dateRange: ClosedRange<Date>) async throws -> [UsageSession] {
        let descriptor = FetchDescriptor<UsageSession>(
            predicate: #Predicate { $0.targetApp == app && $0.date >= dateRange.lowerBound && $0.date <= dateRange.upperBound }
        )
        return try context.fetch(descriptor)
    }

    // MARK: - JITAI Support
    func getSessionsInRange(startDate: String, endDate: String) async throws -> [UsageSession] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        guard let start = dateFormatter.date(from: startDate),
              let end = dateFormatter.date(from: endDate) else {
            return []
        }

        let descriptor = FetchDescriptor<UsageSession>(
            predicate: #Predicate { $0.date >= start && $0.date <= end }
        )
        return try context.fetch(descriptor)
    }

    func recordEvent(_ event: UsageEvent) async throws {
        context.insert(event)
        try context.save()
    }

    func getEvents(for session: UsageSession) async throws -> [UsageEvent] {
        let descriptor = FetchDescriptor<UsageEvent>()
        let allEvents = try context.fetch(descriptor)
        return allEvents.filter { $0.sessionId == session.id }
    }

    func getActiveSession() async throws -> UsageSession? {
        let descriptor = FetchDescriptor<UsageSession>(
            predicate: #Predicate { $0.endTimestamp == nil }
        )
        return try context.fetch(descriptor).first
    }

    func hasActiveSession(for app: String) async throws -> Bool {
        let descriptor = FetchDescriptor<UsageSession>(
            predicate: #Predicate { $0.targetApp == app && $0.endTimestamp == nil }
        )
        return try context.fetch(descriptor).first != nil
    }
}
