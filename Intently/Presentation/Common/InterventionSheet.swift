//
//  InterventionSheet.swift
//  Intently
//
//  Created on 2025-01-11.
//  Sheet wrapper for JitAI intervention display
//

import SwiftUI

/// Intervention Sheet
/// Connects the JitaiInterventionManager with the InterventionView UI
struct InterventionSheet: View {
    @Environment(\.dependencies) private var dependencies
    @Environment(\.dismiss) private var dismiss

    // MARK: - State
    @State private var interventionContent: InterventionContent?
    @State private var frictionLevel: FrictionLevel = .gentle

    // MARK: - Body
    var body: some View {
        Group {
            if let content = interventionContent {
                InterventionView(
                    content: content,
                    frictionLevel: frictionLevel,
                    onContinue: {
                        handleChoice("continue")
                    },
                    onQuit: {
                        handleChoice("quit")
                    },
                    onDismiss: {
                        handleChoice("dismiss")
                    }
                )
            } else {
                ProgressView("Loading...")
            }
        }
        .onAppear {
            loadInterventionContent()
        }
    }

    // MARK: - Private Methods

    private func loadInterventionContent() {
        guard let interventionModel = dependencies.jitaiInterventionManager.currentIntervention else {
            dismiss()
            return
        }

        // Convert InterventionContentModel to InterventionContent
        interventionContent = InterventionContent(
            type: mapContentType(interventionModel.type),
            content: interventionModel.content,
            title: interventionModel.title,
            actionLabel: interventionModel.actionLabel,
            dismissLabel: interventionModel.dismissLabel
        )

        // Determine friction level based on burden
        frictionLevel = determineFrictionLevel()
    }

    private func mapContentType(_ type: ContentType) -> InterventionType {
        switch type {
        case .reflection, .quote:
            return .reflection
        case .timeAlternative:
            return .timeAlternative
        case .breathing:
            return .breathing
        case .stats:
            return .stats
        case .emotionalAppeal:
            return .emotional
        case .gamification, .activitySuggestion:
            return .activity
        }
    }

    private func determineFrictionLevel() -> FrictionLevel {
        // Get decision context to determine appropriate friction
        guard let decision = dependencies.jitaiInterventionManager.currentDecision else {
            return .gentle
        }

        switch decision.burdenLevel {
        case .low:
            return .gentle
        case .moderate:
            return .gentle
        case .high:
            return .moderate
        case .critical:
            return .firm
        }
    }

    private func handleChoice(_ choice: String) {
        Task {
            await dependencies.jitaiInterventionManager.handleResponse(
                choice: choice,
                sessionDuration: 0
            )

            await MainActor.run {
                dismiss()
            }
        }
    }
}
