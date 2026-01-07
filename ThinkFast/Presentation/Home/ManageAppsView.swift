//
//  ManageAppsView.swift
//  ThinkFast
//
//  Created on 2025-01-01.
//

import SwiftUI

struct ManageAppsView: View {
    @Environment(\.dependencies) private var dependencies
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var viewModel: ManageAppsViewModel?
    @State private var showingPopularOnly = false
    @State private var showingGoalSetup = false

    var onAppsSelected: (([TrackedApp]) -> Void)? = nil

    init(onAppsSelected: (([TrackedApp]) -> Void)? = nil) {
        // ViewModel will be initialized in onAppear using environment dependencies
        _viewModel = State(initialValue: nil)
        self.onAppsSelected = onAppsSelected
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                searchBar

                Divider()

                if let viewModel = viewModel {
                    if viewModel.isLoading {
                        Spacer()
                        ProgressView("Loading apps...")
                        Spacer()
                    } else if viewModel.filteredApps.isEmpty {
                        emptyState
                    } else {
                        appsContent

                        // Help text at bottom
                        helpText
                    }
                } else {
                    ProgressView("Loading...")
                }
            }
            .navigationTitle("Tracked Apps")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    if let viewModel = viewModel {
                        Button("\(viewModel.selectedApps.count) Done") {
                            saveAndDismiss()
                        }
                        .fontWeight(.semibold)
                        .disabled(viewModel.selectedApps.isEmpty)
                    } else {
                        Button("Done") {
                            saveAndDismiss()
                        }
                        .fontWeight(.semibold)
                        .disabled(true)
                    }
                }
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = ManageAppsViewModel(
                    trackedAppsRepository: dependencies.trackedAppsRepository,
                    goalRepository: dependencies.goalRepository
                )
            }
        }
        .task {
            await viewModel?.loadData()
        }
    }

    // MARK: - Save and Dismiss
    private func saveAndDismiss() {
        guard let viewModel = viewModel else { return }

        // Get the selected apps
        let selectedApps = viewModel.availableApps.filter { app in
            viewModel.selectedApps.contains(app.id)
        }

        // Notify callback with selected apps
        onAppsSelected?(selectedApps)

        dismiss()
    }

    // MARK: - Search Bar
    private var searchBar: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.appTextSecondary)

            TextField("Search apps", text: Binding(
                get: { viewModel?.searchQuery ?? "" },
                set: { viewModel?.searchQuery = $0 }
            ))
                .textFieldStyle(.plain)

            if !(viewModel?.searchQuery.isEmpty ?? true) {
                Button(action: { viewModel?.searchQuery = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.appTextSecondary)
                }
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(Color.appSecondaryBackground)
    }

    // MARK: - Apps Content
    private var appsContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                // Popular Apps Section
                if !(viewModel?.searchQuery.isEmpty ?? true) {
                    popularAppsSection
                }

                // All Apps by Category
                ForEach(AppCategory.allCases, id: \.self) { category in
                    if let apps = viewModel?.categorizedApps[category], !apps.isEmpty {
                        categorySection(category, apps: apps)
                    }
                }
            }
            .padding()
        }
    }

    // MARK: - Popular Apps
    private var popularAppsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("Popular")
                .font(.headline)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTheme.Spacing.md) {
                    ForEach(viewModel?.availableApps.filter { $0.isRecommended } ?? [], id: \.id) { app in
                        let isAppSelected = viewModel?.selectedApps.contains(app.id) ?? false
                        PopularAppCard(
                            app: app,
                            isSelected: isAppSelected
                        ) {
                            Task {
                                await viewModel?.toggleApp(app)
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Category Section
    private func categorySection(_ category: AppCategory, apps: [TrackedApp]) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text(category.rawValue)
                .font(.headline)
                .foregroundColor(.appTextSecondary)

            VStack(spacing: AppTheme.Spacing.sm) {
                ForEach(apps, id: \.id) { app in
                    let isAppSelected = viewModel?.selectedApps.contains(app.id) ?? false
                    AppListRow(
                        app: app,
                        isSelected: isAppSelected
                    ) {
                        Task {
                            await viewModel?.toggleApp(app)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.appTextTertiary)

            Text("No apps found")
                .font(.headline)

            Text("Try a different search term")
                .font(.subheadline)
                .foregroundColor(.appTextSecondary)
        }
        .padding()
    }

    // MARK: - Help Text
    private var helpText: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            Divider()

            HStack(spacing: AppTheme.Spacing.sm) {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.appPrimary)
                    .font(.caption)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Deselect apps to remove them from tracking")
                        .font(.caption)
                        .foregroundColor(.appTextSecondary)

                    Text("Your goals will be updated when you tap Done")
                        .font(.caption2)
                        .foregroundColor(.appTextTertiary)
                }

                Spacer()
            }
            .padding(AppTheme.Spacing.md)
        }
        .background(Color.appSecondaryBackground.opacity(0.5))
    }
}

// MARK: - App List Row
struct AppListRow: View {
    let app: TrackedApp
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: AppTheme.Spacing.md) {
                AppIconView(appName: app.name, size: 45)

                VStack(alignment: .leading, spacing: 4) {
                    Text(app.name)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    if app.isRecommended {
                        Text("Recommended")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.appSecondary.opacity(0.3))
                            .foregroundColor(.appPrimary)
                            .cornerRadius(4)
                    }
                }

                Spacer()

                ZStack {
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.appPrimary)
                            .font(.title3)
                    } else {
                        Image(systemName: "circle")
                            .foregroundColor(.appTextTertiary)
                            .font(.title3)
                    }
                }
            }
            .padding(AppTheme.Spacing.sm)
            .background(Color.appSecondaryBackground.opacity(isSelected ? 0.5 : 0.1))
            .cornerRadius(AppTheme.CornerRadius.md)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Popular App Card
struct PopularAppCard: View {
    let app: TrackedApp
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            VStack(spacing: AppTheme.Spacing.sm) {
                ZStack(alignment: .topTrailing) {
                    AppIconView(appName: app.name, size: 60)

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.appPrimary)
                            .font(.title3)
                            .padding(-4)
                    }
                }

                Text(app.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)
            }
            .frame(width: 90)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ManageAppsView { _ in }
}
