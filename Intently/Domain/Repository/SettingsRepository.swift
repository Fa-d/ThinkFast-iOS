//
//  SettingsRepository.swift
//  Intently
//
//  Created on 2025-01-01.
//

import Foundation

protocol SettingsRepository {
    // MARK: - App Settings
    func getNotificationEnabled() async throws -> Bool
    func setNotificationEnabled(_ enabled: Bool) async throws

    func getReminderTime() async throws -> Date
    func setReminderTime(_ time: Date) async throws

    func getQuietModeEnabled() async throws -> Bool
    func setQuietModeEnabled(_ enabled: Bool) async throws

    // MARK: - Intervention Settings
    func getInterventionFrequency() async throws -> InterventionFrequency
    func setInterventionFrequency(_ frequency: InterventionFrequency) async throws

    func getInterventionTypes() async throws -> Set<SettingsInterventionType>
    func setInterventionTypes(_ types: Set<SettingsInterventionType>) async throws

    // MARK: - Appearance
    func getAppearanceMode() async throws -> AppearanceMode
    func setAppearanceMode(_ mode: AppearanceMode) async throws

    // MARK: - Data
    func exportData() async throws -> URL
    func deleteAllData() async throws
}

// MARK: - Supporting Types
enum InterventionFrequency: String, CaseIterable, Codable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"

    var description: String {
        switch self {
        case .low: return "Show interventions occasionally"
        case .medium: return "Show interventions regularly"
        case .high: return "Show interventions frequently"
        }
    }
}

enum AppearanceMode: String, CaseIterable, Codable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"
}

enum SettingsInterventionType: String, CaseIterable, Codable {
    case reflection = "Reflection Questions"
    case timeAlternative = "Time Alternatives"
    case breathing = "Breathing Exercises"
    case stats = "Usage Stats"
    case emotional = "Emotional Appeals"
    case activity = "Activity Suggestions"
}
