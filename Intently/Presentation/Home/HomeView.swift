//
//  HomeView.swift
//  Intently
//
//  Created on 2025-01-01.
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dependencies) private var dependencies

    @State private var viewModel: HomeViewModel?
    @State private var showingManageApps = false

    init() {
        // ViewModel will be initialized in onAppear using environment dependencies
        _viewModel = State(initialValue: nil)
    }

    var body: some View {
        NavigationView {
            Group {
                if let viewModel = viewModel {
                    ScrollView {
                        VStack(spacing: AppTheme.Spacing.lg) {
                            // Header
                            headerSection

                            // Today's Progress Card
                            todayProgressCard

                            // Tracked Apps
                            if !viewModel.activeGoals.isEmpty {
                                trackedAppsSection
                            } else {
                                emptyStateSection
                            }
                        }
                        .padding(.vertical)
                    }
                    .background(Color.appBackground)
                    .navigationTitle("Intently")
                } else {
                    ProgressView("Loading...")
                }
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = HomeViewModel(
                    statsRepository: dependencies.statsRepository,
                    goalRepository: dependencies.goalRepository,
                    usageRepository: dependencies.usageRepository,
                    trackedAppsRepository: dependencies.trackedAppsRepository
                )
            }
        }
        .task {
            await viewModel?.loadData()
        }
        .refreshable {
            await viewModel?.loadData()
        }
        .sheet(isPresented: $showingManageApps) {
            ManageAppsView { selectedApps in
                handleAppsSelected(selectedApps)
            }
        }
    }

    // MARK: - Handle Selected Apps
    private func handleAppsSelected(_ apps: [TrackedApp]) {
        Task {
            // Goal synchronization is now handled by ManageAppsViewModel.saveChanges()
            // Just reload the data to show the updated goals
            await viewModel?.loadData()
        }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(greeting)
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Let's stay mindful today")
                    .font(.subheadline)
                    .foregroundColor(.appTextSecondary)
            }
            Spacer()

            if viewModel?.isLoading ?? false {
                ProgressView()
                    .scaleEffect(0.8)
            }
        }
        .padding(.horizontal)
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning!"
        case 12..<17: return "Good afternoon!"
        case 17..<21: return "Good evening!"
        default: return "Hello!"
        }
    }

    // MARK: - Today's Progress Card
    private var todayProgressCard: some View {
        CardView {
            VStack(spacing: AppTheme.Spacing.lg) {
                HStack {
                    Text("Today's Progress")
                        .font(.headline)

                    Spacer()

                    Text(viewModel?.formattedTodayUsage ?? "0m")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.appPrimary)
                }

                HStack(spacing: AppTheme.Spacing.xl) {
                    ZStack {
                        CircularProgress(
                            progress: viewModel?.goalProgress ?? 0,
                            size: 100
                        )

                        VStack(spacing: 2) {
                            Text("\(Int((viewModel?.goalProgress ?? 0) * 100))%")
                                .font(.title3)
                                .fontWeight(.bold)

                            Text("of goal")
                                .font(.caption2)
                                .foregroundColor(.appTextSecondary)
                        }
                    }

                    VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                        statRow(
                            icon: "clock.fill",
                            title: "Total",
                            value: viewModel?.formattedTodayUsage ?? "0m",
                            color: .appPrimary
                        )

                        statRow(
                            icon: "chart.bar.fill",
                            title: "Sessions",
                            value: "\(viewModel?.todayStats?.sessionsCount ?? 0)",
                            color: .appGreen
                        )

                        statRow(
                            icon: "flame.fill",
                            title: "Streak",
                            value: "\(viewModel?.activeGoals.first?.currentStreak ?? 0) days",
                            color: .appOrange
                        )
                    }
                }
            }
        }
        .padding(.horizontal)
    }

    private func statRow(icon: String, title: String, value: String, color: Color) -> some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.appTextSecondary)
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
        }
    }

    // MARK: - Tracked Apps Section
    private var trackedAppsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("Tracked Apps")
                .font(.headline)
                .padding(.horizontal)

            ForEach(viewModel?.activeGoals ?? [], id: \.targetApp) { goal in
                GoalRow(goal: goal)
            }
        }
    }

    // MARK: - Empty State
    private var emptyStateSection: some View {
        CardView {
            VStack(spacing: AppTheme.Spacing.md) {
                Image(systemName: "app.badge")
                    .font(.system(size: 40))
                    .foregroundColor(.appTextTertiary)

                Text("No apps tracked yet")
                    .font(.headline)

                Text("Start tracking your app usage to see progress here")
                    .font(.subheadline)
                    .foregroundColor(.appTextSecondary)
                    .multilineTextAlignment(.center)

                Button("Add Apps") {
                    showingManageApps = true
                }
                .buttonStyle(.bordered)
            }
            .padding(AppTheme.Spacing.lg)
        }
        .padding(.horizontal)
    }
}

// MARK: - Goal Row
struct GoalRow: View {
    let goal: Goal

    var body: some View {
        CardView(padding: AppTheme.Spacing.sm) {
            HStack(spacing: AppTheme.Spacing.md) {
                AppIconView(appName: goal.targetAppName ?? goal.targetApp, size: 45)

                VStack(alignment: .leading, spacing: 4) {
                    Text(goal.targetAppName ?? goal.targetApp)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Text("Streak: \(goal.streakLabel)")
                        .font(.caption)
                        .foregroundColor(streakColor)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(goal.formattedDailyLimit)
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Text("\(goal.currentStreak)🔥")
                        .font(.caption)
                }
            }
        }
        .padding(.horizontal)
    }

    private var streakColor: Color {
        switch goal.currentStreak {
        case 0: return .appTextSecondary
        case 1..<7: return .appPrimary
        case 7..<30: return .appOrange
        default: return .appGreen
        }
    }
}

#Preview {
    HomeView()
}
