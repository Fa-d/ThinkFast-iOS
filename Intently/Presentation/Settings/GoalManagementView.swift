//
//  GoalManagementView.swift
//  Intently
//
//  Created on 2025-01-01.
//

import SwiftUI

struct GoalManagementView: View {
    @Environment(\.dependencies) private var dependencies
    @State private var viewModel: GoalViewModel?
    @State private var showingAddSheet = false
    @State private var selectedApp: TrackedApp?

    init() {
        // ViewModel will be initialized in onAppear using environment dependencies
        _viewModel = State(initialValue: nil)
    }

    var body: some View {
        NavigationView {
            ZStack {
                if let viewModel = viewModel {
                    if viewModel.isLoading {
                        ProgressView("Loading...")
                    } else if viewModel.goals.isEmpty {
                        emptyState
                    } else {
                        goalsList
                    }
                } else {
                    ProgressView("Loading...")
                }
            }
            .navigationTitle("My Goals")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddSheet = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                if let viewModel = viewModel {
                    AddGoalSheet(
                        availableApps: viewModel.trackedApps.filter { app in
                            !viewModel.goals.contains { $0.targetApp == app.id }
                        },
                        onAdd: { app in
                            selectedApp = app
                        }
                    )
                }
            }
            .sheet(item: $selectedApp) { app in
                GoalEditorSheet(
                    app: app,
                    currentGoal: viewModel?.getGoal(for: app.id),
                    onSave: { minutes in
                        Task {
                            await viewModel?.setGoal(for: app, dailyLimitMinutes: minutes)
                        }
                    }
                )
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = GoalViewModel(
                    goalRepository: dependencies.goalRepository,
                    trackedAppsRepository: dependencies.trackedAppsRepository
                )
            }
        }
        .task {
            await viewModel?.loadData()
        }
    }

    // MARK: - Goals List
    private var goalsList: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.md) {
                ForEach(viewModel?.goals.sorted(by: { $0.targetAppName ?? $0.targetApp < $1.targetAppName ?? $1.targetApp }) ?? [], id: \.targetApp) { goal in
                    GoalCard(goal: goal) {
                        Task {
                            await viewModel?.deleteGoal(for: goal.targetApp)
                        }
                    }
                }
            }
            .padding()
        }
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            Image(systemName: "target")
                .font(.system(size: 60))
                .foregroundColor(.appTextTertiary)

            Text("No Goals Set")
                .font(.headline)

            Text("Set daily usage limits for apps you want to monitor")
                .font(.subheadline)
                .foregroundColor(.appTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppTheme.Spacing.xl)

            Button("Add Your First Goal") {
                showingAddSheet = true
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

// MARK: - Goal Card
struct GoalCard: View {
    let goal: Goal
    let onDelete: () -> Void

    var body: some View {
        CardView {
            VStack(spacing: AppTheme.Spacing.md) {
                HStack {
                    AppIconView(appName: goal.targetAppName ?? goal.targetApp, size: 50)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(goal.targetAppName ?? goal.targetApp)
                            .font(.headline)

                        Text(goal.formattedDailyLimit)
                            .font(.subheadline)
                            .foregroundColor(.appPrimary)
                    }

                    Spacer()

                    Toggle("", isOn: Binding(
                        get: { goal.isEnabled },
                        set: { _ in }
                    ))
                    .disabled(true)
                }

                Divider()

                HStack(spacing: AppTheme.Spacing.xl) {
                    stat(
                        icon: "flame.fill",
                        label: "Current Streak",
                        value: "\(goal.currentStreak) days",
                        color: .appOrange
                    )

                    stat(
                        icon: "trophy.fill",
                        label: "Best Streak",
                        value: "\(goal.longestStreak) days",
                        color: .appGreen
                    )

                    Spacer()
                }

                if !goal.isEnabled {
                    HStack {
                        Image(systemName: "pause.circle.fill")
                            .foregroundColor(.appTextSecondary)
                        Text("Goal is paused")
                            .font(.caption)
                            .foregroundColor(.appTextSecondary)
                        Spacer()
                    }
                }
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private func stat(icon: String, label: String, value: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(label)
                    .font(.caption2)
                    .foregroundColor(.appTextSecondary)
            }
        }
    }
}

// MARK: - Add Goal Sheet
struct AddGoalSheet: View {
    let availableApps: [TrackedApp]
    var onAdd: (TrackedApp) -> Void

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.sm) {
                    ForEach(availableApps, id: \.id) { app in
                        Button(action: { onAdd(app) }) {
                            HStack(spacing: AppTheme.Spacing.md) {
                                AppIconView(appName: app.name, size: 40)

                                Text(app.name)
                                    .font(.subheadline)
                                    .foregroundColor(.appTextPrimary)

                                Spacer()

                                if app.category != .other {
                                    Text(app.category.rawValue)
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.appSecondaryBackground)
                                        .foregroundColor(.appTextSecondary)
                                        .cornerRadius(8)
                                }

                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.appTextTertiary)
                            }
                            .padding()
                            .background(Color.appSecondaryBackground)
                            .cornerRadius(AppTheme.CornerRadius.md)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding()
            }
            .navigationTitle("Add Goal")
        }
    }
}

// MARK: - Goal Editor Sheet
struct GoalEditorSheet: View {
    let app: TrackedApp
    let currentGoal: Goal?
    let onSave: (Int) -> Void

    @State private var dailyLimit: Int = 60
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: AppTheme.Spacing.xl) {
                // App Icon
                VStack(spacing: AppTheme.Spacing.sm) {
                    AppIconView(appName: app.name, size: 80)

                    Text(app.name)
                        .font(.headline)
                }

                // Time Picker
                VStack(spacing: AppTheme.Spacing.lg) {
                    Text("Daily Limit")
                        .font(.headline)

                    VStack(spacing: AppTheme.Spacing.md) {
                        Text("\(dailyLimit)")
                            .font(.system(size: 60, weight: .bold, design: .rounded))
                            .foregroundColor(.appPrimary)

                        Text("minutes per day")
                            .font(.title3)
                            .foregroundColor(.appTextSecondary)

                        Slider(
                            value: Binding(
                                get: { Double(dailyLimit) },
                                set: { dailyLimit = Int($0) }
                            ),
                            in: 15...240,
                            step: 15
                        )

                        HStack {
                            Text("15m")
                                .font(.caption)
                                .foregroundColor(.appTextTertiary)
                            Spacer()
                            Text("4h")
                                .font(.caption)
                                .foregroundColor(.appTextTertiary)
                        }
                        .font(.caption)
                    }
                    .padding()
                    .background(Color.appSecondaryBackground)
                    .cornerRadius(AppTheme.CornerRadius.lg)
                }

                Spacer()

                PrimaryButton(
                    title: "Save Goal",
                    action: {
                        onSave(dailyLimit)
                        dismiss()
                    }
                )
            }
            .padding()
            .navigationTitle("Set Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                if let goal = currentGoal {
                    dailyLimit = goal.dailyLimitMinutes
                }
            }
        }
    }
}

#Preview {
    GoalManagementView()
}
