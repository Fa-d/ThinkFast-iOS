//
//  TimePatternHeatmap.swift
//  Intently
//
//  Created on 2025-01-07.
//  Charts: Usage pattern heatmap (iOS native styling)
//

import SwiftUI

/// Time Pattern Heatmap
///
/// Shows usage intensity by hour of day using iOS-style heatmap grid.
/// Helps users identify their peak usage times.
struct TimePatternHeatmap: View {

    let hourlyData: [HourlyUsage]
    let goalMinutes: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("Usage Pattern")
                    .font(.headline)
                    .foregroundColor(.primary)

                Spacer()

                if let peakHour = findPeakHour() {
                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                        Text("Peak: \(peakHour.hour):00")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            if hourlyData.isEmpty {
                // Empty state
                VStack(spacing: 12) {
                    Image(systemName: "clock")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    Text("No hourly data")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 120)
            } else {
                // Heatmap grid
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 6),
                    spacing: 8
                ) {
                    // Hour labels (0, 4, 8, 12, 16, 20)
                    ForEach([0, 4, 8, 12, 16, 20], id: \.self) { hour in
                        Text("\(hour)h")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    // Heatmap cells
                    ForEach(0..<24) { hour in
                        let hourData = hourlyData.first { $0.hour == hour }
                        HeatmapCell(
                            hour: hour,
                            minutes: hourData?.minutes ?? 0,
                            goal: goalMinutes
                        )
                    }

                    // Empty cells to complete grid
                    ForEach(0..<((24 + 6) % 6), id: \.self) { _ in
                        Color.clear
                            .frame(height: 40)
                    }
                }

                // Legend
                HStack(spacing: 16) {
                    // Low
                    legendItem(intensity: .low, label: "Low")

                    // Medium
                    legendItem(intensity: .medium, label: "Medium")

                    // High
                    legendItem(intensity: .high, label: "High")

                    // Very High
                    legendItem(intensity: .veryHigh, label: "Very High")
                }

                // Insights
                if let peakHour = findPeakHour(), let offPeak = findLowestHour() {
                    VStack(alignment: .leading, spacing: 6) {
                        insightItem(
                            icon: "flame.fill",
                            color: .orange,
                            text: "Peak usage around \(peakHour.hour):00"
                        )

                        insightItem(
                            icon: "leaf.fill",
                            color: .green,
                            text: "Quietest around \(offPeak.hour):00"
                        )
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }

    // MARK: - Helper Methods

    private func findPeakHour() -> HourlyUsage? {
        return hourlyData.max { $0.minutes < $1.minutes }
    }

    private func findLowestHour() -> HourlyUsage? {
        return hourlyData.min { $0.minutes < $1.minutes }
    }

    private func legendItem(intensity: HeatmapIntensity, label: String) -> some View {
        HStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 3)
                .fill(intensity.color)
                .frame(width: 16, height: 16)

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private func insightItem(icon: String, color: Color, text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.caption)
                .frame(width: 16)

            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()
        }
    }
}

// MARK: - Heatmap Cell

/// Individual heatmap cell for hourly usage
private struct HeatmapCell: View {
    let hour: Int
    let minutes: Int
    let goal: Int?

    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(intensity.color)
            .frame(height: 40)
            .overlay(
                Text("\(hour)")
                    .font(.caption2)
                    .foregroundColor(isDark ? .white : .white.opacity(0.7))
            )
            .accessibilityLabel("Hour \(hour): \(minutes) minutes")
    }

    private var intensity: HeatmapIntensity {
        // If goal is set, calculate intensity relative to goal
        if let goal = goal {
            let percentage = Double(minutes) / Double(goal)
            if percentage == 0 {
                return .none
            } else if percentage <= 0.25 {
                return .low
            } else if percentage <= 0.5 {
                return .medium
            } else if percentage <= 1.0 {
                return .high
            } else {
                return .veryHigh
            }
        } else {
            // No goal set, use absolute values
            if minutes == 0 {
                return .none
            } else if minutes <= 15 {
                return .low
            } else if minutes <= 30 {
                return .medium
            } else if minutes <= 60 {
                return .high
            } else {
                return .veryHigh
            }
        }
    }

    private var isDark: Bool {
        intensity == .high || intensity == .veryHigh
    }
}

// MARK: - Supporting Types

/// Heatmap intensity levels
enum HeatmapIntensity {
    case none
    case low
    case medium
    case high
    case veryHigh

    var color: Color {
        switch self {
        case .none:
            return Color.gray.opacity(0.1)
        case .low:
            return Color.green.opacity(0.3)
        case .medium:
            return Color.yellow.opacity(0.5)
        case .high:
            return Color.orange.opacity(0.7)
        case .veryHigh:
            return Color.red.opacity(0.8)
        }
    }
}

/// Hourly usage data
struct HourlyUsage: Identifiable, Equatable {
    let id = UUID()
    let hour: Int
    let minutes: Int
    let sessions: Int

    /// Format hour for display
    var formattedTime: String {
        return String(format: "%02d:00", hour)
    }

    /// Get period of day
    var period: String {
        switch hour {
        case 0..<6: return "Night"
        case 6..<12: return "Morning"
        case 12..<18: return "Afternoon"
        default: return "Evening"
        }
    }
}

// MARK: - Preview

#Preview("Time Pattern Heatmap - With Goal") {
    let data = (0..<24).map { hour in
        // Simulate realistic usage pattern
        let baseUsage: Double
        switch hour {
        case 7..<11: baseUsage = 30  // Morning
        case 11..<14: baseUsage = 20  // Midday dip
        case 14..<18: baseUsage = 45  // Afternoon
        case 18..<22: baseUsage = 70  // Evening peak
        case 22..<24: baseUsage = 40  // Late night
        default: baseUsage = 5  // Night
        }
        let variance = Double.random(in: -10...10)
        return HourlyUsage(
            hour: hour,
            minutes: Int(max(0, baseUsage + variance)),
            sessions: Int.random(in: 0...5)
        )
    }

    return TimePatternHeatmap(
        hourlyData: data,
        goalMinutes: 60
    )
    .padding()
}

#Preview("Time Pattern Heatmap - No Goal") {
    let data = (0..<24).map { hour in
        let baseUsage = hour >= 8 && hour <= 22 ? Double.random(in: 20...60) : 0.0
        return HourlyUsage(
            hour: hour,
            minutes: Int(baseUsage),
            sessions: Int.random(in: 0...4)
        )
    }

    return TimePatternHeatmap(
        hourlyData: data,
        goalMinutes: nil
    )
    .padding()
}
