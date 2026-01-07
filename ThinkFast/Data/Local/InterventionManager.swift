//
//  InterventionManager.swift
//  ThinkFast
//
//  Created on 2025-01-01.
//

import Foundation
import SwiftUI

final class InterventionManager: ObservableObject {
    // MARK: - Properties
    @Published var currentIntervention: InterventionContent?
    @Published var isShowingIntervention = false

    private let interventionResultRepository: InterventionResultRepository
    private let goalRepository: GoalRepository

    // MARK: - Intervention Types with Weights
    private let interventionTypes: [(type: InterventionType, weight: Double)] = [
        (.reflection, 0.40),
        (.timeAlternative, 0.30),
        (.breathing, 0.20),
        (.stats, 0.10),
        (.emotional, 0.15),
        (.activity, 0.15)
    ]

    // MARK: - Content Store
    private let contentStore = InterventionContentStore()

    init(
        interventionResultRepository: InterventionResultRepository,
        goalRepository: GoalRepository
    ) {
        self.interventionResultRepository = interventionResultRepository
        self.goalRepository = goalRepository
    }

    // MARK: - Decision Logic
    func shouldShowIntervention(for app: String, currentUsage: TimeInterval) async -> Bool {
        guard let goal = try? await goalRepository.getGoal(for: app) else {
            return false
        }

        let goalLimit = TimeInterval(goal.dailyLimitMinutes * 60)
        let threshold = goalLimit * 0.8 // Show at 80% of limit

        return currentUsage >= threshold && currentUsage < goalLimit
    }

    // MARK: - Get Intervention Content
    func getInterventionContent(for app: String) -> InterventionContent {
        let type = selectInterventionType()
        return contentStore.getContent(for: type, app: app)
    }

    // MARK: - Select Intervention Type (weighted random)
    private func selectInterventionType() -> InterventionType {
        let totalWeight = interventionTypes.reduce(0) { $0 + $1.weight }
        let random = Double.random(in: 0..<totalWeight)

        var cumulativeWeight = 0.0
        for (type, weight) in interventionTypes {
            cumulativeWeight += weight
            if random < cumulativeWeight {
                return type
            }
        }

        return .reflection
    }

    // MARK: - Show Intervention
    func showIntervention(for app: String, sessionId: UUID, currentUsage: TimeInterval) {
        Task { @MainActor in
            let content = getInterventionContent(for: app)
            currentIntervention = content
            isShowingIntervention = true
        }
    }

    // MARK: - Handle User Response
    func handleResponse(
        choice: String,
        sessionId: UUID,
        targetApp: String,
        sessionDuration: TimeInterval
    ) async {
        guard let intervention = currentIntervention else { return }

        let result = InterventionResult(
            sessionId: sessionId,
            targetApp: targetApp,
            interventionType: intervention.type.rawValue,
            contentType: intervention.content,
            userChoice: choice,
            sessionDuration: sessionDuration,
            wasEffective: choice == "quit",
            timeOfDay: getTimeOfDay(),
            streakAtTime: 0,
            goalProgressAtTime: nil
        )

        try? await interventionResultRepository.saveResult(result)

        Task { @MainActor in
            isShowingIntervention = false
            currentIntervention = nil
        }
    }

    // MARK: - Helper
    private func getTimeOfDay() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "morning"
        case 12..<17: return "afternoon"
        case 17..<21: return "evening"
        default: return "night"
        }
    }
}

// MARK: - Intervention Content
struct InterventionContent: Identifiable {
    let id = UUID()
    let type: InterventionType
    let content: String
    let title: String
    let actionLabel: String
    let dismissLabel: String
}

// MARK: - Intervention Type Enum
enum InterventionType: String, CaseIterable {
    case reflection = "Reflection Questions"
    case timeAlternative = "Time Alternatives"
    case breathing = "Breathing Exercises"
    case stats = "Usage Stats"
    case emotional = "Emotional Appeals"
    case activity = "Activity Suggestions"
}

// MARK: - Content Store
class InterventionContentStore {
    private let reflectionQuestions = [
        "Do you really need to use this app right now?",
        "What specific task do you want to accomplish?",
        "How will you feel after spending time here?",
        "Is there a better use of your time right now?",
        "What would your future self say?"
    ]

    private let timeAlternatives = [
        "Read a book for 10 minutes",
        "Take a short walk outside",
        "Call a friend or family member",
        "Work on a hobby",
        "Try cooking something new",
        "Exercise or stretch"
    ]

    private let breathingExercises = [
        "Take 5 deep breaths",
        "4-7-8 breathing: Inhale 4s, hold 7s, exhale 8s",
        "Box breathing: 4s in, 4s hold, 4s out, 4s hold"
    ]

    private let statsMessages = [
        "You've already spent X minutes here today",
        "This is your Yth visit today",
        "Your daily average is Z minutes"
    ]

    private let emotionalAppeals = [
        "Your time is valuable - spend it wisely",
        "Think of all the things you could achieve",
        "Don't let this app control your day",
        "You're stronger than the urge to scroll",
        "Every minute counts - make them matter"
    ]

    private let activitySuggestions = [
        "How about a quick meditation?",
        "Time to water your plants",
        "Organize one small space",
        "Write down tomorrow's goals",
        "Listen to a new podcast"
    ]

    func getContent(for type: InterventionType, app: String) -> InterventionContent {
        switch type {
        case .reflection:
            return InterventionContent(
                type: type,
                content: reflectionQuestions.randomElement() ?? "Take a moment to reflect",
                title: "Quick Reflection",
                actionLabel: "I'll Think About It",
                dismissLabel: "Continue Anyway"
            )
        case .timeAlternative:
            return InterventionContent(
                type: type,
                content: timeAlternatives.randomElement() ?? "Try something else",
                title: "Better Alternatives",
                actionLabel: "Sounds Good",
                dismissLabel: "Not Now"
            )
        case .breathing:
            return InterventionContent(
                type: type,
                content: breathingExercises.randomElement() ?? "Breathe deeply",
                title: "Pause & Breathe",
                actionLabel: "Start Breathing",
                dismissLabel: "Skip"
            )
        case .stats:
            return InterventionContent(
                type: type,
                content: "You've spent time here today. Is it worth it?",
                title: "Your Usage",
                actionLabel: "I See",
                dismissLabel: "Continue"
            )
        case .emotional:
            return InterventionContent(
                type: type,
                content: emotionalAppeals.randomElement() ?? "Your time matters",
                title: "Remember Your Goals",
                actionLabel: "You're Right",
                dismissLabel: "Continue"
            )
        case .activity:
            return InterventionContent(
                type: type,
                content: activitySuggestions.randomElement() ?? "Try something new",
                title: "Activity Idea",
                actionLabel: "Let's Do It",
                dismissLabel: "Maybe Later"
            )
        }
    }
}
