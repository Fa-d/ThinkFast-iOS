//
//  AppBreakdownDonutChart.swift
//  Intently
//
//  Created on 2025-01-07.
//  Charts: App breakdown donut chart (iOS native styling)
//

import SwiftUI

/// App Breakdown Donut Chart
///
/// Shows usage distribution across apps using iOS-style donut chart.
/// Displays percentages with color-coded segments.
struct AppBreakdownDonutChart: View {

    let appData: [AppUsageBreakdown]
    let totalMinutes: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            Text("App Breakdown")
                .font(.headline)
                .foregroundColor(.primary)

            if appData.isEmpty {
                // Empty state
                VStack(spacing: 12) {
                    Image(systemName: "chart.pie")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    Text("No app usage data")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 180)
            } else {
                HStack(spacing: 20) {
                    // Donut chart
                    ZStack {
                        // Background circle
                        Circle()
                            .stroke(Color.gray.opacity(0.2), lineWidth: 20)
                            .frame(width: 120, height: 120)

                        // Segments
                        ForEach(Array(appData.enumerated()), id: \.element.id) { index, app in
                            let startAngle = startAngle(for: index)
                            let endAngle = endAngle(for: index)

                            Circle()
                                .trim(from: startAngle / 180, to: endAngle / 180)
                                .stroke(
                                    AngularGradient(
                                        gradient: Gradient(colors: [app.color, app.color.opacity(0.8)]),
                                        center: .center,
                                        startAngle: .degrees(startAngle),
                                        endAngle: .degrees(endAngle)
                                    ),
                                    style: StrokeStyle(lineWidth: 20, lineCap: .round)
                                )
                                .frame(width: 120, height: 120)
                                .rotationEffect(Angle(degrees: -90))
                        }

                        // Center text
                        VStack(spacing: 2) {
                            Text("\(totalMinutes)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)

                            Text("min")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    // Legend
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(appData.prefix(5), id: \.appName) { app in
                            HStack(spacing: 8) {
                                // Color indicator
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(app.color)
                                    .frame(width: 12, height: 12)

                                // App name
                                Text(app.appName)
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                                    .lineLimit(1)

                                Spacer()

                                // Percentage and time
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text("\(app.percentage)%")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.primary)

                                    Text("\(app.minutes)m")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }

                        if appData.count > 5 {
                            Text("+ \(appData.count - 5) more apps")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                // Insight
                if let topApp = appData.first {
                    HStack(spacing: 6) {
                        Image(systemName: "lightbulb")
                            .foregroundColor(.yellow)
                            .font(.caption)

                        Text("\(topApp.appName) is your most used app")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 4)
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }

    // MARK: - Helper Methods

    private func startAngle(for index: Int) -> Double {
        var accumulatedPercentage = 0.0
        for i in 0..<index {
            accumulatedPercentage += appData[i].percentage / 100.0
        }
        return accumulatedPercentage * 360
    }

    private func endAngle(for index: Int) -> Double {
        var accumulatedPercentage = 0.0
        for i in 0...index {
            accumulatedPercentage += appData[i].percentage / 100.0
        }
        return accumulatedPercentage * 360
    }
}

// MARK: - Data Model

/// App usage breakdown for donut chart
struct AppUsageBreakdown: Identifiable, Equatable {
    let id = UUID()
    let appName: String
    let minutes: Int
    let percentage: Double
    let color: Color

    /// Format percentage for display
    var formattedPercentage: String {
        return String(format: "%.0f%%", percentage)
    }

    /// Format minutes for display
    var formattedMinutes: String {
        return "\(minutes)m"
    }
}

// MARK: - Preview

#Preview("App Breakdown - 2 Apps") {
    let data = [
        AppUsageBreakdown(
            appName: "Instagram",
            minutes: 120,
            percentage: 65,
            color: .purple
        ),
        AppUsageBreakdown(
            appName: "Facebook",
            minutes: 65,
            percentage: 35,
            color: .blue
        )
    ]

    AppBreakdownDonutChart(
        appData: data,
        totalMinutes: 185
    )
    .padding()
}

#Preview("App Breakdown - Multiple Apps") {
    let data = [
        AppUsageBreakdown(appName: "Instagram", minutes: 90, percentage: 40, color: .purple),
        AppUsageBreakdown(appName: "Facebook", minutes: 60, percentage: 27, color: .blue),
        AppUsageBreakdown(appName: "TikTok", minutes: 40, percentage: 18, color: .pink),
        AppUsageBreakdown(appName: "Twitter", minutes: 20, percentage: 9, color: .cyan),
        AppUsageBreakdown(appName: "YouTube", minutes: 15, percentage: 6, color: .red)
    ]

    AppBreakdownDonutChart(
        appData: data,
        totalMinutes: 225
    )
    .padding()
}
