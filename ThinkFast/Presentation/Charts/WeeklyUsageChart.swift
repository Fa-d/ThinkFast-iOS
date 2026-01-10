//
//  WeeklyUsageChart.swift
//  ThinkFast
//
//  Created on 2025-01-07.
//  Charts: Weekly usage bar chart
//

import SwiftUI

/// Weekly Usage Chart
///
/// Displays daily usage for the past week as bar charts.
/// Shows goal limit line for comparison.
struct WeeklyUsageChart: View {

    let dailyData: [DailyUsageData]
    let goalMinutes: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Chart title
            Text("Weekly Usage")
                .font(.headline)
                .foregroundColor(.primary)

            if dailyData.isEmpty {
                // Empty state
                VStack(spacing: 12) {
                    Image(systemName: "chart.bar")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)

                    Text("No data for this week")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 180)
            } else {
                // Chart
                HStack(alignment: .bottom, spacing: 8) {
                    ForEach(dailyData.indices, id: \.self) { index in
                        let data = dailyData[index]
                        let isToday = Calendar.current.isDateInToday(data.date)
                        let barHeight = calculateBarHeight(minutes: data.minutes, maxMinutes: maxDailyUsage())

                        VStack(spacing: 4) {
                            // Usage value
                            Text("\(data.minutes)")
                                .font(.caption2)
                                .foregroundColor(.secondary)

                            // Bar
                            ZStack(alignment: .top) {
                                // Background bar
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(width: 24, height: 120)

                                // Value bar
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(barColor(for: data, goal: goalMinutes))
                                    .frame(width: 24, height: barHeight)
                                    .animation(.easeInOut(duration: 0.3), value: barHeight)

                                // Goal line (if goal set)
                                if let goal = goalMinutes {
                                    let goalLineY = calculateGoalLineY(goalMinutes: goal, maxMinutes: maxDailyUsage())
                                    GeometryReader { geometry in
                                        Rectangle()
                                            .fill(Color.red)
                                            .frame(width: 28, height: 2)
                                            .offset(y: goalLineY)
                                    }
                                    .frame(height: 120)
                                }
                            }
                            .frame(height: 120)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(isToday ? Color.accentColor : Color.clear, lineWidth: 2)
                            )

                            // Day label
                            Text(dayLabel(data.date))
                                .font(.caption2)
                                .foregroundColor(isToday ? .accentColor : .secondary)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 4)

                // Legend
                HStack(spacing: 16) {
                    // Under goal legend
                    legendItem(color: .green, label: "Under Goal")

                    // Over goal legend
                    legendItem(color: .orange, label: "Over Goal")

                    // Goal line legend
                    if let goal = goalMinutes {
                        HStack(spacing: 4) {
                            Rectangle()
                                .fill(Color.red)
                                .frame(width: 20, height: 2)
                            Text("Goal (\(goal)m)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }

    // MARK: - Helper Methods

    private func maxDailyUsage() -> Int {
        let maxValue = dailyData.map { $0.minutes }.max() ?? 0
        return max(maxValue, 60) // Minimum scale of 60 minutes
    }

    private func calculateBarHeight(minutes: Int, maxMinutes: Int) -> CGFloat {
        let percentage = min(Double(minutes) / Double(maxMinutes), 1.0)
        return CGFloat(percentage) * 120
    }

    private func calculateGoalLineY(goalMinutes: Int, maxMinutes: Int) -> CGFloat {
        let percentage = min(Double(goalMinutes) / Double(maxMinutes), 1.0)
        return CGFloat(1.0 - percentage) * 120
    }

    private func barColor(for data: DailyUsageData, goal: Int?) -> Color {
        guard let goal = goal else {
            return .accentColor
        }
        return data.minutes <= goal ? .green : .orange
    }

    private func dayLabel(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "E"
            return formatter.string(from: date).prefix(3).uppercased()
        }
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 12, height: 12)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Preview

#Preview("Weekly Usage Chart - With Goal") {
    let today = Date()
    let calendar = Calendar.current

    let data = (0..<7).map { i in
        let date = calendar.date(byAdding: .day, value: -i, to: today) ?? today
        return DailyUsageData(
            date: date,
            minutes: Int.random(in: 30...90),
            sessions: Int.random(in: 2...8),
            goalMinutes: nil
        )
    }.reversed() as [DailyUsageData]

    WeeklyUsageChart(
        dailyData: data,
        goalMinutes: 60
    )
    .padding()
}

#Preview("Weekly Usage Chart - No Goal") {
    let today = Date()
    let calendar = Calendar.current

    let data = (0..<7).map { i in
        let date = calendar.date(byAdding: .day, value: -i, to: today) ?? today
        return DailyUsageData(
            date: date,
            minutes: Int.random(in: 20...70),
            sessions: Int.random(in: 1...5),
            goalMinutes: nil
        )
    }.reversed() as [DailyUsageData]

    WeeklyUsageChart(
        dailyData: data,
        goalMinutes: nil
    )
    .padding()
}
