//
//  GoalProgressLineChart.swift
//  ThinkFast
//
//  Created on 2025-01-07.
//  Charts: Goal progress line chart over time
//

import SwiftUI

/// Goal Progress Line Chart
///
/// Shows usage trend over time with goal limit line.
/// Displays trend direction and statistics.
struct GoalProgressLineChart: View {

    let weeklyData: [DailyUsageData]
    let goalMinutes: Int?
    let period: ChartPeriod

    enum ChartPeriod: String, CaseIterable {
        case week = "7D"
        case twoWeeks = "14D"
        case month = "30D"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with trend
            HStack {
                Text("Usage Trend")
                    .font(.headline)
                    .foregroundColor(.primary)

                Spacer()

                if let trend = calculateTrend() {
                    HStack(spacing: 4) {
                        Image(systemName: trend.icon)
                            .font(.caption)
                            .foregroundColor(trend.color)

                        Text(trend.message)
                            .font(.caption)
                            .foregroundColor(trend.color)
                    }
                }
            }

            if weeklyData.isEmpty {
                // Empty state
                VStack(spacing: 12) {
                    Image(systemName: "chart.xyaxis.line")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)

                    Text("No data available")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 180)
            } else {
                // Line chart
                VStack(alignment: .leading, spacing: 8) {
                    // Y-axis labels (left side)
                    ZStack(alignment: .topLeading) {
                        // Chart area
                        GeometryReader { geometry in
                            let maxMinutes = maxDailyUsageForChart()
                            let chartHeight: CGFloat = geometry.size.height - 20

                            // Draw grid lines
                            VStack(spacing: 0) {
                                ForEach(0..<5) { i in
                                    Divider()
                                        .background(Color.gray.opacity(0.2))
                                }
                            }
                            .frame(maxHeight: .infinity)

                            // Draw goal line
                            if let goal = goalMinutes {
                                let goalY = calculateYPosition(minutes: goal, maxMinutes: maxMinutes, chartHeight: chartHeight)
                                Rectangle()
                                    .fill(Color.red.opacity(0.5))
                                    .frame(width: geometry.size.width, height: 1)
                                    .offset(y: goalY)
                            }

                            // Draw line chart
                            if weeklyData.count >= 2 {
                                Path { path in
                                    for (index, data) in weeklyData.enumerated() {
                                        let x = CGFloat(index) / CGFloat(weeklyData.count - 1) * geometry.size.width
                                        let y = calculateYPosition(minutes: data.minutes, maxMinutes: maxMinutes, chartHeight: chartHeight)

                                        if index == 0 {
                                            path.move(to: CGPoint(x: x, y: y))
                                        } else {
                                            path.addLine(to: CGPoint(x: x, y: y))
                                        }
                                    }
                                }
                                .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))

                                // Fill gradient under line
                                Path { path in
                                    for (index, data) in weeklyData.enumerated() {
                                        let x = CGFloat(index) / CGFloat(weeklyData.count - 1) * geometry.size.width
                                        let y = calculateYPosition(minutes: data.minutes, maxMinutes: maxMinutes, chartHeight: chartHeight)

                                        if index == 0 {
                                            path.move(to: CGPoint(x: x, y: y))
                                        } else {
                                            path.addLine(to: CGPoint(x: x, y: y))
                                        }
                                    }

                                    path.addLine(to: CGPoint(x: geometry.size.width, y: calculateYPosition(
                                        minutes: weeklyData.last?.minutes ?? 0,
                                        maxMinutes: maxMinutes,
                                        chartHeight: chartHeight
                                    )))
                                    path.addLine(to: CGPoint(x: 0, y: calculateYPosition(
                                        minutes: weeklyData[0].minutes,
                                        maxMinutes: maxMinutes,
                                        chartHeight: chartHeight
                                    )))
                                }
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.accentColor.opacity(0.3),
                                            Color.accentColor.opacity(0.05)
                                        ]),
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                            }

                            // Draw data points
                            ForEach(weeklyData.indices, id: \.self) { index in
                                let data = weeklyData[index]
                                let x = CGFloat(index) / CGFloat(weeklyData.count - 1) * geometry.size.width
                                let y = calculateYPosition(minutes: data.minutes, maxMinutes: maxMinutes, chartHeight: chartHeight)

                                Circle()
                                    .fill(pointColor(for: data, goal: goalMinutes))
                                    .frame(width: 8, height: 8)
                                    .offset(x: x - 4, y: y - 4)
                            }
                        }
                        .frame(height: 180)

                        // Y-axis labels
                        VStack {
                            Text("\(maxDailyUsageForChart())m")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(maxDailyUsageForChart() / 2)m")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text("0m")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .offset(x: 25, y: 10)
                    }
                }

                // X-axis labels
                if weeklyData.count <= 7 {
                    HStack {
                        ForEach(weeklyData, id: \.id) { data in
                            if data == weeklyData.first || data == weeklyData.last || weeklyData.count <= 4 {
                                Text(dayLabel(data.date))
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    Spacer()
                            } else {
                                Spacer()
                            }
                        }
                    }
                    .padding(.leading, 20)
                }

                // Statistics
                HStack(spacing: 20) {
                    StatItem(value: "\(averageUsage())m", label: "Avg/day")
                    StatItem(value: "\(maxDailyUsage())m", label: "Highest")
                    StatItem(value: "\(underGoalCount())/\(weeklyData.count)", label: "Under goal")
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }

    // MARK: - Helper Methods

    private func maxDailyUsageForChart() -> Int {
        let maxValue = weeklyData.map { $0.minutes }.max() ?? 0
        let roundedMax = ((maxValue / 10) + 1) * 10 // Round up to nearest 10
        return max(roundedMax, 60)
    }

    private func maxDailyUsage() -> Int {
        return weeklyData.map { $0.minutes }.max() ?? 0
    }

    private func averageUsage() -> Int {
        guard !weeklyData.isEmpty else { return 0 }
        let total = weeklyData.reduce(0) { $0 + $1.minutes }
        return total / weeklyData.count
    }

    private func underGoalCount() -> Int {
        guard let goal = goalMinutes else { return 0 }
        return weeklyData.filter { $0.minutes <= goal }.count
    }

    private func calculateYPosition(minutes: Int, maxMinutes: Int, chartHeight: CGFloat) -> CGFloat {
        let percentage = min(Double(minutes) / Double(maxMinutes), 1.0)
        return CGFloat(1.0 - percentage) * chartHeight
    }

    private func pointColor(for data: DailyUsageData, goal: Int?) -> Color {
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

    private func calculateTrend() -> TrendInfo? {
        guard weeklyData.count >= 2 else { return nil }

        let firstHalf = weeklyData.prefix(weeklyData.count / 2)
        let secondHalf = weeklyData.suffix(weeklyData.count / 2)

        let firstAvg = firstHalf.reduce(0) { $0 + $1.minutes } / firstHalf.count
        let secondAvg = secondHalf.reduce(0) { $0 + $1.minutes } / secondHalf.count

        let difference = secondAvg - firstAvg

        if difference > 10 {
            return TrendInfo(icon: "arrow.up", message: "Increasing", color: .red)
        } else if difference > 0 {
            return TrendInfo(icon: "arrow.up.right", message: "Slight up", color: .orange)
        } else if difference < -10 {
            return TrendInfo(icon: "arrow.down", message: "Improving", color: .green)
        } else if difference < 0 {
            return TrendInfo(icon: "arrow.down.right", message: "Stable", color: .secondary)
        } else {
            return TrendInfo(icon: "minus", message: "Flat", color: .secondary)
        }
    }
}

// MARK: - Supporting Types

struct TrendInfo {
    let icon: String
    let message: String
    let color: Color
}

struct StatItem: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)

            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Preview

#Preview("Goal Progress - Week") {
    let today = Date()
    let calendar = Calendar.current

    let data = (0..<7).map { i in
        let date = calendar.date(byAdding: .day, value: -i, to: today) ?? today
        return DailyUsageData(
            date: date,
            minutes: Int.random(in: 30...80),
            sessions: Int.random(in: 2...6),
            goalMinutes: nil
        )
    }.reversed() as [DailyUsageData]

    GoalProgressLineChart(
        weeklyData: data,
        goalMinutes: 60,
        period: .week
    )
    .padding()
}

#Preview("Goal Progress - Month") {
    let today = Date()
    let calendar = Calendar.current

    let data = (0..<30).map { i in
        let date = calendar.date(byAdding: .day, value: -i, to: today) ?? today
        return DailyUsageData(
            date: date,
            minutes: Int.random(in: 20...70),
            sessions: Int.random(in: 1...5),
            goalMinutes: nil
        )
    }.reversed() as [DailyUsageData]

    GoalProgressLineChart(
        weeklyData: data,
        goalMinutes: 60,
        period: .month
    )
    .padding()
}
