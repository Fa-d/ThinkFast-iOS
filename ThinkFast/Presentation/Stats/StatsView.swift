//
//  StatsView.swift
//  ThinkFast
//
//  Created on 2025-01-01.
//

import SwiftUI

struct StatsView: View {
    @Environment(\.dependencies) private var dependencies
    @State private var viewModel: StatsViewModel?

    init() {
        // ViewModel will be initialized in onAppear using environment dependencies
        _viewModel = State(initialValue: nil)
    }

    var body: some View {
        NavigationView {
            Group {
                if let viewModel = viewModel {
                    ScrollView {
                        VStack(spacing: AppTheme.Spacing.xl) {
                            // Period Selector
                            periodSelector

                            if viewModel.isLoading {
                                ProgressView("Loading...")
                            } else if viewModel.dailyStats.isEmpty {
                                emptyState
                            } else {
                                // Charts
                                chartsSection

                                // Stats Cards
                                statsCards

                                // Trend Indicator
                                if let trend = viewModel.trend {
                                    trendCard(trend)
                                }
                            }
                        }
                        .padding(.vertical)
                    }
                    .background(Color.appBackground)
                    .navigationTitle("Statistics")
                } else {
                    ProgressView("Loading...")
                }
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = StatsViewModel(
                    statsRepository: dependencies.statsRepository
                )
            }
        }
        .task {
            await viewModel?.loadData()
        }
    }

    // MARK: - Charts Section
    private var chartsSection: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            // TODO: Re-enable charts after adding chart files to Xcode project
            EmptyView()
        }
    }

    // MARK: - Period Selector
    private var periodSelector: some View {
        Picker("Period", selection: Binding(
            get: { viewModel?.selectedPeriod ?? .week },
            set: { viewModel?.selectedPeriod = $0 }
        )) {
            ForEach(StatsPeriod.allCases, id: \.self) { period in
                Text(period.rawValue).tag(period)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
        .onChange(of: viewModel?.selectedPeriod ?? .week) { _, _ in
            Task {
                await viewModel?.loadData()
            }
        }
    }

    // MARK: - Stats Cards
    private var statsCards: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            StatCard(
                title: "Total Usage",
                value: viewModel?.totalUsage ?? "0m",
                subtitle: viewModel?.selectedPeriod.rawValue.lowercased() ?? "week",
                icon: "clock.fill",
                color: .appPrimary
            )

            StatCard(
                title: "Average Per Day",
                value: viewModel?.averageDaily ?? "0m",
                subtitle: "Session length",
                icon: "chart.line.uptrend.xyaxis",
                color: .appGreen
            )

            StatCard(
                title: "Longest Session",
                value: viewModel?.longestSession ?? "0m",
                subtitle: "Single session",
                icon: "flame.fill",
                color: .appOrange
            )

            // Sessions Count
            StatCard(
                title: "Total Sessions",
                value: "\(viewModel?.dailyStats.reduce(0) { $0 + $1.sessionsCount } ?? 0)",
                subtitle: viewModel?.selectedPeriod.rawValue.lowercased() ?? "week",
                icon: "app.fill",
                color: .purple
            )
        }
        .padding(.horizontal)
    }

    // MARK: - Trend Card
    private func trendCard(_ trend: StatsTrend) -> some View {
        CardView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                HStack {
                    Text("Usage Trend")
                        .font(.headline)

                    Spacer()

                    Image(systemName: trendIcon(for: trend.trendDirection))
                        .foregroundColor(trendColor(for: trend.trendDirection))
                }

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(Int(trend.averageDailyMinutes))m")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("avg daily")
                        .font(.caption)
                        .foregroundColor(.appTextSecondary)
                }

                HStack(spacing: AppTheme.Spacing.sm) {
                    if trend.percentageChange != 0 {
                        Text(trend.percentageChange >= 0 ? "+" : "")
                            .font(.caption) +
                        Text("\(Int(trend.percentageChange))%")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }

                    Text(trend.trendDirection == .down ? "less than last period" : "more than last period")
                        .font(.caption)
                        .foregroundColor(.appTextSecondary)
                }
            }
        }
        .padding(.horizontal)
    }

    private func trendIcon(for direction: TrendDirection) -> String {
        switch direction {
        case .up: return "arrow.up.right"
        case .down: return "arrow.down.right"
        case .stable: return "minus"
        }
    }

    private func trendColor(for direction: TrendDirection) -> Color {
        switch direction {
        case .up: return .appRed
        case .down: return .appGreen
        case .stable: return .appTextSecondary
        }
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            Image(systemName: "chart.bar")
                .font(.system(size: 60))
                .foregroundColor(.appTextTertiary)

            Text("No data yet")
                .font(.headline)

            Text("Use your tracked apps to see statistics here")
                .font(.subheadline)
                .foregroundColor(.appTextSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(AppTheme.Spacing.xl)
    }
}

#Preview {
    StatsView()
}
