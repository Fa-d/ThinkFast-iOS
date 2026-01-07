//
//  PersistenceManager.swift
//  ThinkFast
//
//  Created on 2025-01-01.
//

import Foundation

final class PersistenceManager {
    static let shared = PersistenceManager()

    private let userDefaults = UserDefaults.standard
    private let keychain = KeychainHelper()

    // MARK: - Keys
    private enum Keys {
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let selectedApps = "selectedApps"
        static let notificationEnabled = "notificationEnabled"
        static let dailyReminderTime = "dailyReminderTime"
        static let quietModeEnabled = "quietModeEnabled"
        static let interventionFrequency = "interventionFrequency"
        static let selectedInterventionTypes = "selectedInterventionTypes"
        static let appearanceMode = "appearanceMode"
        static let userId = "userId"
        static let userSessionToken = "userSessionToken"
    }

    private init() {}

    // MARK: - Onboarding
    var hasCompletedOnboarding: Bool {
        get { userDefaults.bool(forKey: Keys.hasCompletedOnboarding) }
        set { userDefaults.set(newValue, forKey: Keys.hasCompletedOnboarding) }
    }

    // MARK: - Selected Apps
    var selectedApps: [String] {
        get { userDefaults.stringArray(forKey: Keys.selectedApps) ?? [] }
        set { userDefaults.set(newValue, forKey: Keys.selectedApps) }
    }

    // MARK: - Notification Settings
    var notificationEnabled: Bool {
        get { userDefaults.bool(forKey: Keys.notificationEnabled) }
        set { userDefaults.set(newValue, forKey: Keys.notificationEnabled) }
    }

    var dailyReminderTime: Date? {
        get {
            guard let interval = userDefaults.object(forKey: Keys.dailyReminderTime) as? TimeInterval else {
                return nil
            }
            return Date(timeIntervalSince1970: interval)
        }
        set {
            userDefaults.set(newValue?.timeIntervalSince1970, forKey: Keys.dailyReminderTime)
        }
    }

    var quietModeEnabled: Bool {
        get { userDefaults.bool(forKey: Keys.quietModeEnabled) }
        set { userDefaults.set(newValue, forKey: Keys.quietModeEnabled) }
    }

    // MARK: - Intervention Settings
    var interventionFrequency: String {
        get { userDefaults.string(forKey: Keys.interventionFrequency) ?? "medium" }
        set { userDefaults.set(newValue, forKey: Keys.interventionFrequency) }
    }

    var selectedInterventionTypes: [String] {
        get { userDefaults.stringArray(forKey: Keys.selectedInterventionTypes) ?? [] }
        set { userDefaults.set(newValue, forKey: Keys.selectedInterventionTypes) }
    }

    // MARK: - Appearance
    var appearanceMode: String {
        get { userDefaults.string(forKey: Keys.appearanceMode) ?? "system" }
        set { userDefaults.set(newValue, forKey: Keys.appearanceMode) }
    }

    // MARK: - Authentication
    var userId: String? {
        get { userDefaults.string(forKey: Keys.userId) }
        set { userDefaults.set(newValue, forKey: Keys.userId) }
    }

    var userSessionToken: String? {
        get { keychain.get(key: Keys.userSessionToken) }
        set {
            if let token = newValue {
                keychain.set(key: Keys.userSessionToken, value: token)
            } else {
                keychain.delete(key: Keys.userSessionToken)
            }
        }
    }

    // MARK: - Clear All
    func clearAll() {
        let dictionary = userDefaults.dictionaryRepresentation()
        dictionary.keys.forEach { key in
            userDefaults.removeObject(forKey: key)
        }
        keychain.clearAll()
    }
}

// MARK: - Keychain Helper
private class KeychainHelper {
    func get(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)

        if status == errSecSuccess, let data = dataTypeRef as? Data {
            return String(data: data, encoding: .utf8)
        }

        return nil
    }

    func set(key: String, value: String) {
        let data = value.data(using: .utf8)!

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]

        // First delete existing
        SecItemDelete(query as CFDictionary)

        // Then add new
        SecItemAdd(query as CFDictionary, nil)
    }

    func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]

        SecItemDelete(query as CFDictionary)
    }

    func clearAll() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword
        ]

        SecItemDelete(query as CFDictionary)
    }
}
