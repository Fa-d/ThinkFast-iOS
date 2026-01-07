//
//  SettingsRepositoryImpl.swift
//  ThinkFast
//
//  Created on 2025-01-01.
//

import Foundation

final class SettingsRepositoryImpl: SettingsRepository {

    private let userDefaults = UserDefaults.standard

    private enum Keys {
        static let notificationEnabled = "notificationEnabled"
        static let reminderTime = "reminderTime"
        static let quietModeEnabled = "quietModeEnabled"
        static let interventionFrequency = "interventionFrequency"
        static let interventionTypes = "interventionTypes"
        static let appearanceMode = "appearanceMode"
    }

    init() {}

    func getNotificationEnabled() async throws -> Bool {
        return userDefaults.bool(forKey: Keys.notificationEnabled)
    }

    func setNotificationEnabled(_ enabled: Bool) async throws {
        userDefaults.set(enabled, forKey: Keys.notificationEnabled)
    }

    func getReminderTime() async throws -> Date {
        // TODO: Implement proper date storage
        return Date()
    }

    func setReminderTime(_ time: Date) async throws {
        // TODO: Implement proper date storage
    }

    func getQuietModeEnabled() async throws -> Bool {
        return userDefaults.bool(forKey: Keys.quietModeEnabled)
    }

    func setQuietModeEnabled(_ enabled: Bool) async throws {
        userDefaults.set(enabled, forKey: Keys.quietModeEnabled)
    }

    func getInterventionFrequency() async throws -> InterventionFrequency {
        let rawValue = userDefaults.string(forKey: Keys.interventionFrequency) ?? InterventionFrequency.medium.rawValue
        return InterventionFrequency(rawValue: rawValue) ?? .medium
    }

    func setInterventionFrequency(_ frequency: InterventionFrequency) async throws {
        userDefaults.set(frequency.rawValue, forKey: Keys.interventionFrequency)
    }

    func getInterventionTypes() async throws -> Set<SettingsInterventionType> {
        // TODO: Implement proper storage
        return Set(SettingsInterventionType.allCases)
    }

    func setInterventionTypes(_ types: Set<SettingsInterventionType>) async throws {
        // TODO: Implement proper storage
    }

    func getAppearanceMode() async throws -> AppearanceMode {
        let rawValue = userDefaults.string(forKey: Keys.appearanceMode) ?? AppearanceMode.system.rawValue
        return AppearanceMode(rawValue: rawValue) ?? .system
    }

    func setAppearanceMode(_ mode: AppearanceMode) async throws {
        userDefaults.set(mode.rawValue, forKey: Keys.appearanceMode)
    }

    func exportData() async throws -> URL {
        // TODO: Implement data export
        throw RepositoryError.notFound
    }

    func deleteAllData() async throws {
        // TODO: Implement data deletion
    }
}
