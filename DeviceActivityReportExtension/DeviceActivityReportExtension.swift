//
//  DeviceActivityReportExtension.swift
//  DeviceActivityReportExtension
//
//  Created on 2025-01-02.
//

import DeviceActivity
import DeviceActivityReport
import FamilyControls
import os.log

// MARK: - Device Activity Report Extension
class DeviceActivityReportExtension: DeviceActivityReportExtension {
    func createReport(with configuration: DeviceActivityReportConfiguration) async throws -> DeviceActivityReport {
        logger.debug("Creating device activity report")
        return IntentlyUsageReport(configuration: configuration)
    }

    private let logger = Logger(subsystem: "dev.sadakat.intently.extension", category: "Report")
}

// MARK: - Think Fast Usage Report
struct IntentlyUsageReport: DeviceActivityReport {
    let configuration: DeviceActivityReportConfiguration

    func renderReport(context: DeviceActivityReportContext) async throws -> String {
        logger.debug("Rendering report")

        var report = "Intently Usage Report\n"
        report += "========================\n\n"

        let dataSegments = await context.dataSegments

        for segment in dataSegments {
            let startDate = segment.activityStartDate
            let endDate = segment.activityEndDate

            report += "Period: \(startDate) to \(endDate)\n"

            let totalUsage = segment.applicationUsages.reduce(0.0) { $0 + $1.totalActivityDuration }

            report += "Total Screen Time: \(formatDuration(totalUsage))\n"
            report += "Applications: \(segment.applicationUsages.count)\n\n"

            for usage in segment.applicationUsages {
                let appName = usage.application.localizedizedName ?? "Unknown"
                let bundleId = usage.application.bundleIdentifier ?? "Unknown"
                let duration = usage.totalActivityDuration

                report += "- \(appName)\n"
                report += "  Bundle: \(bundleId)\n"
                report += "  Time: \(formatDuration(duration))\n\n"

                // Update shared defaults
                if let sharedDefaults = UserDefaults(suiteName: "group.dev.sadakat.intently") {
                    let key = "usage_\(bundleId)"
                    let minutes = duration / 60
                    sharedDefaults.set(minutes, forKey: key)
                }
            }

            report += "---\n\n"
        }

        return report
    }

    private let logger = Logger(subsystem: "dev.sadakat.intently.extension", category: "Report")

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration / 60)
        let seconds = Int(duration.truncatingRemainder(dividingBy: 60))

        if minutes > 60 {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            return "\(hours)h \(remainingMinutes)m"
        }

        return "\(minutes)m \(seconds)s"
    }
}
