//
//  UsageEvent.swift
//  ThinkFast
//
//  Created on 2025-01-01.
//

import Foundation
import SwiftData

@Model
final class UsageEvent {
    // MARK: - Core Properties
    var id: UUID = UUID()
    var sessionId: UUID = UUID()
    var eventType: String = "" // "app_open", "app_close", "intervention_shown", "intervention_responded", "goal_exceeded"
    var timestamp: Date = Date()
    var metadata: String? // JSON string for flexible metadata storage

    // MARK: - Sync Properties
    var userId: String?
    var syncStatus: String = "pending"
    var lastModified: Date = Date()
    var cloudId: String?

    // MARK: - Relationships
    var session: UsageSession?

    // MARK: - Initializer
    init(
        id: UUID = UUID(),
        sessionId: UUID = UUID(),
        eventType: String = "",
        timestamp: Date = Date(),
        metadata: String? = nil,
        userId: String? = nil,
        syncStatus: String = "pending",
        lastModified: Date = Date(),
        cloudId: String? = nil
    ) {
        self.id = id
        self.sessionId = sessionId
        self.eventType = eventType
        self.timestamp = timestamp
        self.metadata = metadata
        self.userId = userId
        self.syncStatus = syncStatus
        self.lastModified = lastModified
        self.cloudId = cloudId
    }
}

// MARK: - Event Types
extension UsageEvent {
    enum EventType: String {
        case appOpen = "app_open"
        case appClose = "app_close"
        case interventionShown = "intervention_shown"
        case interventionResponded = "intervention_responded"
        case interventionDismissed = "intervention_dismissed"
        case goalExceeded = "goal_exceeded"
        case goalCompleted = "goal_completed"
        case streakAchieved = "streak_achieved"
        case streakBroken = "streak_broken"
    }
}
