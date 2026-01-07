//
//  TrackedAppsRepositoryImpl.swift
//  ThinkFast
//
//  Created on 2025-01-01.
//

import Foundation
import SwiftData

final class TrackedAppsRepositoryImpl: TrackedAppsRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func getTrackedApps() async throws -> [TrackedApp] {
        // Return predefined apps
        return getAvailableApps()
    }

    func addTrackedApp(_ app: TrackedApp) async throws {
        // TODO: Implement persistence
    }

    func removeTrackedApp(withId id: String) async throws {
        // TODO: Implement removal
    }

    func toggleApp(withId id: String, enabled: Bool) async throws {
        // TODO: Implement toggle
    }

    func selectApp(withId id: String, selected: Bool) async throws {
        // TODO: Implement selection
    }

    func getAvailableApps() -> [TrackedApp] {
        return [
            TrackedApp(id: "com.facebook.Facebook", name: "Facebook", icon: "facebook.fill", category: .social, isEnabled: true, isSelected: false, isRecommended: true),
            TrackedApp(id: "com.instagram.Instagram", name: "Instagram", icon: "instagram", category: .social, isEnabled: true, isSelected: false, isRecommended: true),
            TrackedApp(id: "com.zhiliaoapp.musically", name: "TikTok", icon: "music.note", category: .entertainment, isEnabled: true, isSelected: false, isRecommended: true),
            TrackedApp(id: "com.atebits.Tweetie2", name: "X (Twitter)", icon: "at", category: .social, isEnabled: true, isSelected: false, isRecommended: false),
            TrackedApp(id: "com.google.ios.youtube", name: "YouTube", icon: "play.rectangle.fill", category: .entertainment, isEnabled: true, isSelected: false, isRecommended: true),
            TrackedApp(id: "com.toyopagroup.picaboo", name: "Snapchat", icon: "camera.fill", category: .social, isEnabled: true, isSelected: false, isRecommended: false),
        ]
    }

    func getPopularApps() -> [TrackedApp] {
        return Array(getAvailableApps().prefix(3))
    }

    func getSelectedApps() async throws -> [TrackedApp] {
        return getAvailableApps().filter { $0.isSelected }
    }

    func setSelectedApps(_ apps: [TrackedApp]) async throws {
        // TODO: Implement persistence
    }
}
