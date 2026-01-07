//
//  ManageAppsViewModel.swift
//  ThinkFast
//
//  Created on 2025-01-01.
//

import Foundation
import SwiftUI

@Observable
final class ManageAppsViewModel {
    // MARK: - Published Properties
    var isLoading = false
    var availableApps: [TrackedApp] = []
    var selectedApps: Set<String> = []
    var searchQuery = ""

    // MARK: - Filtered Apps
    var filteredApps: [TrackedApp] {
        if searchQuery.isEmpty {
            return availableApps
        } else {
            return availableApps.filter {
                $0.name.localizedCaseInsensitiveContains(searchQuery)
            }
        }
    }

    // MARK: - Categorized Apps
    var categorizedApps: [AppCategory: [TrackedApp]] {
        Dictionary(grouping: filteredApps) { $0.category }
    }

    // MARK: - Dependencies
    private let trackedAppsRepository: TrackedAppsRepository
    private let goalRepository: GoalRepository

    init(trackedAppsRepository: TrackedAppsRepository, goalRepository: GoalRepository) {
        self.trackedAppsRepository = trackedAppsRepository
        self.goalRepository = goalRepository
    }

    // MARK: - Actions
    func loadData() async {
        isLoading = true
        defer { isLoading = false }

        availableApps = (try? await trackedAppsRepository.getTrackedApps()) ?? []

        // Load existing goals and mark those apps as selected
        let existingGoals = (try? await goalRepository.getAllGoals()) ?? []
        let trackedAppIds = Set(existingGoals.map { $0.targetApp })
        selectedApps = trackedAppIds
    }

    // MARK: - Toggle Selection
    func toggleApp(_ app: TrackedApp) async {
        if selectedApps.contains(app.id) {
            selectedApps.remove(app.id)
        } else {
            selectedApps.insert(app.id)
        }
    }

    func selectAll() async {
        for app in filteredApps where !selectedApps.contains(app.id) {
            selectedApps.insert(app.id)
        }
    }

    func deselectAll() async {
        selectedApps.removeAll()
    }

    // MARK: - Helper
    func isSelected(_ app: TrackedApp) -> Bool {
        selectedApps.contains(app.id)
    }
}
