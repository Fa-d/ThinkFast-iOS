//
//  UsageSession.swift
//  ThinkFast
//
//  Created on 2025-01-01.
//

import Foundation
import SwiftData

@Model
final class UsageSession {
    // MARK: - Core Properties
    var id: UUID = UUID()
    var targetApp: String = ""
    var targetAppName: String?
    var startTimestamp: Date = Date()
    var endTimestamp: Date?
    var duration: TimeInterval = 0
    var wasInterrupted: Bool = false
    var interruptionType: String?
    var date: Date = Date()

    // MARK: - Sync Properties
    var userId: String?
    var syncStatus: String = "pending" // pending, synced, conflict
    var lastModified: Date = Date()
    var cloudId: String?

    // MARK: - Relationships
    @Relationship(deleteRule: .cascade, inverse: \UsageEvent.session)
    var events: [UsageEvent]?

    // MARK: - Initializer
    init(
        id: UUID = UUID(),
        targetApp: String = "",
        targetAppName: String? = nil,
        startTimestamp: Date = Date(),
        endTimestamp: Date? = nil,
        duration: TimeInterval = 0,
        wasInterrupted: Bool = false,
        interruptionType: String? = nil,
        date: Date = Date(),
        userId: String? = nil,
        syncStatus: String = "pending",
        lastModified: Date = Date(),
        cloudId: String? = nil
    ) {
        self.id = id
        self.targetApp = targetApp
        self.targetAppName = targetAppName
        self.startTimestamp = startTimestamp
        self.endTimestamp = endTimestamp
        self.duration = duration
        self.wasInterrupted = wasInterrupted
        self.interruptionType = interruptionType
        self.date = date
        self.userId = userId
        self.syncStatus = syncStatus
        self.lastModified = lastModified
        self.cloudId = cloudId
    }
}

// MARK: - Computed Properties
extension UsageSession {
    var isCompleted: Bool {
        endTimestamp != nil
    }

    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return "\(minutes)m \(seconds)s"
    }
}
