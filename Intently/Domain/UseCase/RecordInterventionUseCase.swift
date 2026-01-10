//
//  RecordInterventionUseCase.swift
//  Intently
//
//  Created on 2025-01-01.
//

import Foundation

struct RecordInterventionUseCase {
    private let interventionResultRepository: InterventionResultRepository

    init(interventionResultRepository: InterventionResultRepository) {
        self.interventionResultRepository = interventionResultRepository
    }

    func execute(
        sessionId: UUID,
        targetApp: String,
        interventionType: String,
        contentType: String,
        userChoice: String,
        sessionDuration: TimeInterval
    ) async throws {
        let result = InterventionResult(
            sessionId: sessionId,
            targetApp: targetApp,
            interventionType: interventionType,
            contentType: contentType,
            userChoice: userChoice,
            sessionDuration: sessionDuration,
            wasEffective: userChoice == "quit",
            timeOfDay: getTimeOfDay(),
            streakAtTime: 0,
            goalProgressAtTime: nil
        )

        try await interventionResultRepository.saveResult(result)
    }

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
