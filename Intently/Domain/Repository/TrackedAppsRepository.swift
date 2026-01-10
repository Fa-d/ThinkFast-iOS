//
//  TrackedAppsRepository.swift
//  Intently
//
//  Created on 2025-01-01.
//

import Foundation

struct TrackedApp: Identifiable, Codable {
    let id: String // Bundle identifier
    let name: String
    let icon: String? // Asset name or system symbol
    let category: AppCategory
    let isEnabled: Bool
    let isSelected: Bool
    let isRecommended: Bool
}

enum AppCategory: String, CaseIterable, Codable {
    case social = "Social Media"
    case entertainment = "Entertainment"
    case games = "Games"
    case productivity = "Productivity"
    case news = "News"
    case shopping = "Shopping"
    case other = "Other"
}

protocol TrackedAppsRepository {
    // MARK: - App Management
    func getTrackedApps() async throws -> [TrackedApp]
    func addTrackedApp(_ app: TrackedApp) async throws
    func removeTrackedApp(withId id: String) async throws
    func toggleApp(withId id: String, enabled: Bool) async throws
    func selectApp(withId id: String, selected: Bool) async throws

    // MARK: - Predefined Apps
    func getAvailableApps() -> [TrackedApp]
    func getPopularApps() -> [TrackedApp]

    // MARK: - Selection
    func getSelectedApps() async throws -> [TrackedApp]
    func setSelectedApps(_ apps: [TrackedApp]) async throws
}
