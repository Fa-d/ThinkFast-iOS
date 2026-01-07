//
//  DeviceActivityManager.swift
//  ThinkFast
//
//  Created on 2025-01-02.
//

import DeviceActivity
import FamilyControls
import SwiftUI
import os.log

// MARK: - Device Activity Manager
@MainActor
class DeviceActivityManager: NSObject, ObservableObject {
    private let logger = Logger(subsystem: "dev.sadakat.thinkfast", category: "DeviceActivity")

    @Published var isAuthorized = false
    @Published var isMonitoring = false
    @Published var authorizationError: String?

    // MARK: - Authorization
    func requestAuthorization() async -> Bool {
        logger.log("Requesting DeviceActivity authorization")

        let center = AuthorizationCenter.shared
        do {
            try await center.requestAuthorization(for: .child)
            await MainActor.run {
                self.isAuthorized = center.authorizationStatus == .approved
                if !self.isAuthorized {
                    self.authorizationError = "Authorization was not approved"
                }
            }
            logger.log("Authorization status: \(center.authorizationStatus.rawValue)")
            return isAuthorized
        } catch {
            await MainActor.run {
                self.authorizationError = error.localizedDescription
                self.isAuthorized = false
            }
            logger.error("Authorization failed: \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - Check Authorization
    func checkAuthorizationStatus() {
        let center = AuthorizationCenter.shared
        isAuthorized = center.authorizationStatus == .approved

        if case .notDetermined = center.authorizationStatus {
            logger.log("Authorization status: not determined")
        } else if case .approved = center.authorizationStatus {
            logger.log("Authorization status: approved")
        } else if case .denied = center.authorizationStatus {
            logger.log("Authorization status: denied")
        }
    }

    // MARK: - Get App Usage (from UserDefaults/Extension)
    func getAppUsage(for bundleIdentifier: String) async -> TimeInterval {
        // The DeviceActivity extension stores usage data in shared UserDefaults
        guard let sharedDefaults = UserDefaults(suiteName: "group.dev.sadakat.thinkfast") else {
            return 0
        }

        let key = "usage_\(bundleIdentifier)"
        return TimeInterval(sharedDefaults.double(forKey: key))
    }

    // MARK: - Set App Usage (called by extension)
    func setAppUsage(for bundleIdentifier: String, minutes: TimeInterval) {
        guard let sharedDefaults = UserDefaults(suiteName: "group.dev.sadakat.thinkfast") else {
            return
        }

        let key = "usage_\(bundleIdentifier)"
        sharedDefaults.set(minutes, forKey: key)
        sharedDefaults.synchronize()
    }

    // MARK: - Get All Tracked Apps Usage
    func getAllTrackedAppsUsage(bundleIdentifiers: [String]) async -> [String: TimeInterval] {
        var usage: [String: TimeInterval] = [:]

        for bundleId in bundleIdentifiers {
            usage[bundleId] = await getAppUsage(for: bundleId)
        }

        return usage
    }

    // MARK: - Update Total Usage
    func updateTodayUsage(_ minutes: Int) {
        guard let sharedDefaults = UserDefaults(suiteName: "group.dev.sadakat.thinkfast") else {
            return
        }

        sharedDefaults.set(minutes, forKey: "todayUsage")
        sharedDefaults.set(Date(), forKey: "lastUpdate")
        sharedDefaults.synchronize()

        logger.log("Updated today's usage: \(minutes) minutes")
    }

    // MARK: - Get Today's Usage
    func getTodayUsage() -> Int {
        guard let sharedDefaults = UserDefaults(suiteName: "group.dev.sadakat.thinkfast") else {
            return 0
        }

        return sharedDefaults.integer(forKey: "todayUsage")
    }
}

// MARK: - Device Activity Error
enum DeviceActivityError: LocalizedError {
    case notAuthorized
    case monitoringFailed(String)
    case fetchFailed(String)

    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Not authorized to access Screen Time data"
        case .monitoringFailed(let message):
            return "Failed to start monitoring: \(message)"
        case .fetchFailed(let message):
            return "Failed to fetch usage data: \(message)"
        }
    }
}

// MARK: - Authorization View
struct DeviceActivityAuthorizationView: View {
    @StateObject private var deviceActivityManager = DeviceActivityManager()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "chart.bar.fill")
                .font(.system(size: 60))
                .foregroundColor(.appPrimary)

            Text("Screen Time Access")
                .font(.title)
                .fontWeight(.bold)

            Text("ThinkFast needs access to Screen Time data to track your app usage and help you achieve your goals.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.appTextSecondary)
                .padding(.horizontal)

            VStack(alignment: .leading, spacing: 12) {
                AuthorizationFeatureRow(icon: "lock.shield", title: "Privacy First", description: "Your data stays on your device")
                AuthorizationFeatureRow(icon: "chart.line.uptrend.xyaxis", title: "Track Usage", description: "See how much time you spend")
                AuthorizationFeatureRow(icon: "target", title: "Set Goals", description: "Achieve your daily limits")
            }
            .padding()

            Spacer()

            VStack(spacing: 12) {
                Button {
                    Task {
                        if await deviceActivityManager.requestAuthorization() {
                            dismiss()
                        }
                    }
                } label: {
                    Text("Authorize Screen Time")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.appPrimary)
                        .cornerRadius(12)
                }

                Button("Cancel") {
                    dismiss()
                }
                .foregroundColor(.appTextSecondary)
            }
            .padding()
        }
        .padding()
    }
}

struct AuthorizationFeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.appPrimary)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.appTextSecondary)
            }
        }
    }
}
