//
//  InterventionResult.swift
//  ThinkFast
//
//  Created on 2025-01-01.
//

import Foundation
import SwiftData

@Model
final class InterventionResult {
    // MARK: - Core Properties
    var sessionId: UUID = UUID()
    var targetApp: String = ""
    var interventionType: String = "" // reflection, time_alternative, breathing, stats, emotional, activity
    var contentType: String = "" // Specific content shown
    var userChoice: String = "" // continue, quit, skip
    var feedbackTimestamp: Date = Date()
    var sessionDuration: TimeInterval = 0
    var wasEffective: Bool?

    // MARK: - Context
    var timeOfDay: String = "" // morning, afternoon, evening, night
    var hourOfDay: Int = 0 // Hour of day (0-23) for JITAI analysis
    var streakAtTime: Int = 0
    var goalProgressAtTime: Int? // Percentage of daily limit used

    // MARK: - JITAI Properties
    var quickReopen: Bool = false // Was this a quick reopen (< 2 min)
    var opportunityScore: Int = 0 // Opportunity score (0-100)
    var opportunityLevel: String = "" // EXCELLENT, GOOD, MODERATE, POOR
    var persona: String = "" // Detected persona at intervention time
    var decisionSource: String = "" // What approved/blocked this intervention

    // MARK: - Sync Properties
    var userId: String?
    var syncStatus: String = "pending"
    var lastModified: Date = Date()
    var cloudId: String?

    // MARK: - Initializer
    init(
        sessionId: UUID = UUID(),
        targetApp: String = "",
        interventionType: String = "",
        contentType: String = "",
        userChoice: String = "",
        feedbackTimestamp: Date = Date(),
        sessionDuration: TimeInterval = 0,
        wasEffective: Bool? = nil,
        timeOfDay: String = "",
        hourOfDay: Int = 0,
        streakAtTime: Int = 0,
        goalProgressAtTime: Int? = nil,
        quickReopen: Bool = false,
        opportunityScore: Int = 0,
        opportunityLevel: String = "",
        persona: String = "",
        decisionSource: String = "",
        userId: String? = nil,
        syncStatus: String = "pending",
        lastModified: Date = Date(),
        cloudId: String? = nil
    ) {
        self.sessionId = sessionId
        self.targetApp = targetApp
        self.interventionType = interventionType
        self.contentType = contentType
        self.userChoice = userChoice
        self.feedbackTimestamp = feedbackTimestamp
        self.sessionDuration = sessionDuration
        self.wasEffective = wasEffective
        self.timeOfDay = timeOfDay
        self.hourOfDay = hourOfDay
        self.streakAtTime = streakAtTime
        self.goalProgressAtTime = goalProgressAtTime
        self.quickReopen = quickReopen
        self.opportunityScore = opportunityScore
        self.opportunityLevel = opportunityLevel
        self.persona = persona
        self.decisionSource = decisionSource
        self.userId = userId
        self.syncStatus = syncStatus
        self.lastModified = lastModified
        self.cloudId = cloudId
    }
}

// MARK: - Intervention Types
extension InterventionResult {
    enum InterventionType: String {
        case reflection = "reflection"
        case timeAlternative = "time_alternative"
        case breathing = "breathing"
        case stats = "stats"
        case emotional = "emotional"
        case activity = "activity"
    }

    enum UserChoice: String {
        case `continue` = "continue" // User chose to continue using app
        case quit = "quit" // User chose to quit
        case skip = "skip" // User dismissed intervention
    }
}
