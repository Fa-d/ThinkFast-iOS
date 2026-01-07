//
//  ThinkFastWidget.swift
//  ThinkFastWidget
//
//  Created on 2025-01-01.
//

import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), totalMinutes: 0, goalLimit: 60, appName: "ThinkFast")
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), totalMinutes: 45, goalLimit: 60, appName: "ThinkFast")
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [SimpleEntry] = []

        // Generate entries for the next few hours
        let currentDate = Date()
        for hourOffset in 0..<8 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let totalMinutes = Int.random(in: 0...90)
            let entry = SimpleEntry(
                date: entryDate,
                totalMinutes: totalMinutes,
                goalLimit: 60,
                appName: "ThinkFast"
            )
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let totalMinutes: Int
    let goalLimit: Int
    let appName: String
}

struct ThinkFastWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        VStack(spacing: 4) {
            Text(entry.appName)
                .font(.caption2)
                .foregroundColor(.secondary)

            HStack(spacing: 8) {
                CircularProgress(
                    progress: min(Double(entry.totalMinutes) / Double(entry.goalLimit), 1.0),
                    size: 40
                )

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(entry.totalMinutes)m")
                        .font(.title3)
                        .bold()
                    Text("of \(entry.goalLimit)m")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Text(progressText)
                .font(.caption)
                .foregroundColor(progressColor)
        }
        .padding()
    }

    private var progressText: String {
        let percentage = Double(entry.totalMinutes) / Double(entry.goalLimit)
        if percentage >= 1.0 {
            return "Goal exceeded"
        } else if percentage >= 0.8 {
            return "Almost there!"
        } else {
            return "On track"
        }
    }

    private var progressColor: Color {
        let percentage = Double(entry.totalMinutes) / Double(entry.goalLimit)
        if percentage >= 1.0 {
            return .red
        } else if percentage >= 0.8 {
            return .orange
        } else {
            return .green
        }
    }
}

struct ThinkFastWidget: Widget {
    let kind: String = "ThinkFastWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            ThinkFastWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary)
        }
        .configurationDisplayName("ThinkFast")
        .description("Track your daily app usage progress")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// Minimal widget for iOS 17+
@available(iOS 17.0, *)
struct ThinkFastMinimalWidget: Widget {
    let kind: String = "ThinkFastMinimalWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            VStack(spacing: 0) {
                Text("\(entry.totalMinutes)m")
                    .font(.title)
                    .bold()

                Text("of \(entry.goalLimit)m")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .containerBackground(.fill.tertiary)
        }
        .configurationDisplayName("ThinkFast Mini")
        .description("Minimal usage widget")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular])
    }
}

#Preview(as: .systemSmall) {
    ThinkFastWidgetEntryView(entry: SimpleEntry(date: Date(), totalMinutes: 45, goalLimit: 60, appName: "ThinkFast"))
        .containerBackground(.fill.tertiary)
}
