//
//  BaselineComparisonCard.swift
//  Intently
//
//  Created on 2025-01-07.
//  First-Week Retention: Baseline comparison card UI
//

import SwiftUI

/// Baseline Comparison Card
///
/// Shows user's current usage compared to their baseline.
/// Displays today vs baseline and baseline vs population average.
struct BaselineComparisonCard: View {

    // MARK: - Properties
    let baseline: BaselineComparisonInfo
    let todayMinutes: Int

    // MARK: - Body
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.accentColor)

                Text("Your Baseline")
                    .font(.headline)
                    .foregroundColor(.primary)
            }

            // Today vs Baseline
            comparisonRow(
                title: "Today",
                value: "\(todayMinutes) min",
                baselineValue: "\(baseline.averageDailyMinutes) min",
                difference: todayMinutes - baseline.averageDailyMinutes,
                lowerIsBetter: true
            )

            Divider()

            // Baseline vs Population
            comparisonRow(
                title: "Your Baseline",
                value: "\(baseline.averageDailyMinutes) min",
                baselineValue: "\(BaselineComparisonInfo.populationAverageMinutes) min",
                difference: baseline.averageDailyMinutes - BaselineComparisonInfo.populationAverageMinutes,
                lowerIsBetter: true
            )

            // Motivational message
            Text(baseline.comparisonMessage())
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 4)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.accentColor.opacity(0.2), lineWidth: 1)
        )
    }

    // MARK: - Comparison Row
    @ViewBuilder
    private func comparisonRow(
        title: String,
        value: String,
        baselineValue: String,
        difference: Int,
        lowerIsBetter: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)

            HStack {
                Text(value)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                Spacer()

                // Trend indicator
                HStack(spacing: 4) {
                    Image(systemName: trendIcon(difference: difference, lowerIsBetter: lowerIsBetter))
                        .font(.caption)
                        .foregroundColor(trendColor(difference: difference, lowerIsBetter: lowerIsBetter))

                    Text(trendText(difference: difference, lowerIsBetter: lowerIsBetter))
                        .font(.caption)
                        .foregroundColor(trendColor(difference: difference, lowerIsBetter: lowerIsBetter))
                }
            }
        }
    }

    // MARK: - Trend Helpers

    private func trendIcon(difference: Int, lowerIsBetter: Bool) -> String {
        if difference == 0 {
            return "minus"
        }

        let isImproving = lowerIsBetter ? difference < 0 : difference > 0
        return isImproving ? "arrow.down" : "arrow.up"
    }

    private func trendColor(difference: Int, lowerIsBetter: Bool) -> Color {
        if difference == 0 {
            return .secondary
        }

        let isImproving = lowerIsBetter ? difference < 0 : difference > 0
        return isImproving ? .green : .red
    }

    private func trendText(difference: Int, lowerIsBetter: Bool) -> String {
        if difference == 0 {
            return "At baseline"
        }

        let absDiff = abs(difference)
        let isImproving = lowerIsBetter ? difference < 0 : difference > 0

        if isImproving {
            return "\(absDiff) min below"
        } else {
            return "\(absDiff) min above"
        }
    }
}

// MARK: - Minimal Baseline Card

/// Minimal Baseline Card
///
/// Simpler version showing just the baseline info.
struct MinimalBaselineCard: View {

    let baseline: BaselineComparisonInfo

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.accentColor)

                Text("Based on your first week")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text("\(baseline.averageDailyMinutes)")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                Text("min/day average")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // Population comparison
            HStack(spacing: 4) {
                let diff = baseline.comparisonToPopulation()

                if diff > 0 {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("\(diff) min below population avg")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else if diff < 0 {
                    Image(systemName: "info.circle")
                        .foregroundColor(.orange)
                    Text("\(abs(diff)) min above population avg")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Image(systemName: "equal.circle")
                        .foregroundColor(.secondary)
                    Text("At population average")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.accentColor.opacity(0.1))
        )
    }
}

// MARK: - Preview

#Preview("Full Card - Good Day") {
    let baseline = BaselineComparisonInfo(
        firstWeekStartDate: "2025-01-01",
        firstWeekEndDate: "2025-01-07",
        averageDailyMinutes: 60,
        facebookAverageMinutes: 35,
        instagramAverageMinutes: 25
    )

    return VStack {
        BaselineComparisonCard(
            baseline: baseline,
            todayMinutes: 45  // Better than baseline
        )

        Spacer()
    }
    .padding()
}

#Preview("Full Card - Bad Day") {
    let baseline = BaselineComparisonInfo(
        firstWeekStartDate: "2025-01-01",
        firstWeekEndDate: "2025-01-07",
        averageDailyMinutes: 45,
        facebookAverageMinutes: 25,
        instagramAverageMinutes: 20
    )

    return VStack {
        BaselineComparisonCard(
            baseline: baseline,
            todayMinutes: 75  // Worse than baseline
        )

        Spacer()
    }
    .padding()
}

#Preview("Minimal Card") {
    let baseline = BaselineComparisonInfo(
        firstWeekStartDate: "2025-01-01",
        firstWeekEndDate: "2025-01-07",
        averageDailyMinutes: 45,
        facebookAverageMinutes: 25,
        instagramAverageMinutes: 20
    )

    return VStack {
        MinimalBaselineCard(baseline: baseline)
        Spacer()
    }
    .padding()
}
