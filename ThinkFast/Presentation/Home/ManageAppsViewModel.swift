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

    // MARK: - Private State
    private var initialSelectedApps: Set<String> = []

    // MARK: - Actions
    func loadData() async {
        isLoading = true
        defer { isLoading = false }

        print("📖 ManageAppsViewModel.loadData()")
        availableApps = (try? await trackedAppsRepository.getTrackedApps()) ?? []
        print("  📱 Available apps: \(availableApps.count)")

        // Load existing goals and mark those apps as selected
        let existingGoals = (try? await goalRepository.getAllGoals()) ?? []
        print("  🎯 Existing goals: \(existingGoals.count)")

        let trackedAppIds = Set(existingGoals.map { $0.targetApp })
        selectedApps = trackedAppIds
        initialSelectedApps = trackedAppIds
        print("  ✓ Marked \(selectedApps.count) apps as selected")
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

    // MARK: - Save Changes
    /// Synchronizes the selected apps with goals in the repository
    /// Creates goals for newly selected apps and deletes goals for deselected apps
    func saveChanges() async throws {
        // Determine which apps were added and which were removed
        let appsToAdd = selectedApps.subtracting(initialSelectedApps)
        let appsToRemove = initialSelectedApps.subtracting(selectedApps)

        print("🔄 ManageAppsViewModel.saveChanges()")
        print("  📱 Selected apps: \(selectedApps.count)")
        print("  ➕ Apps to add: \(appsToAdd.count)")
        print("  ➖ Apps to remove: \(appsToRemove.count)")

        // Delete goals for apps that are no longer selected
        for appId in appsToRemove {
            print("  🗑️ Deleting goal for: \(appId)")
            try? await goalRepository.deleteGoal(for: appId)
        }

        // Create goals for newly selected apps
        for appId in appsToAdd {
            // Find the app details
            guard let app = availableApps.first(where: { $0.id == appId }) else {
                print("  ⚠️ App not found in availableApps: \(appId)")
                continue
            }

            // Check if goal already exists (it shouldn't, but just in case)
            if let existingGoal = try? await goalRepository.getGoal(for: app.id) {
                print("  ♻️ Goal exists for \(app.name), enabling it")
                // Goal exists, just enable it if disabled
                if !existingGoal.isEnabled {
                    try? await goalRepository.toggleGoal(for: app.id, enabled: true)
                }
            } else {
                print("  ✅ Creating goal for \(app.name) (60 min)")
                // Create new goal with default 60 minute limit
                try? await goalRepository.setGoal(
                    for: app.id,
                    appName: app.name,
                    dailyLimitMinutes: 60
                )
            }
        }

        // Update the initial state to match current state
        initialSelectedApps = selectedApps
        print("  ✓ Save complete!")
    }

    // MARK: - Get Selected Apps
    /// Returns the list of TrackedApp objects for all selected app IDs
    func getSelectedApps() -> [TrackedApp] {
        return availableApps.filter { selectedApps.contains($0.id) }
    }

    // MARK: - Helper
    func isSelected(_ app: TrackedApp) -> Bool {
        selectedApps.contains(app.id)
    }
}
