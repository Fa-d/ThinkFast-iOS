//
//  ThinkFastApp.swift
//  ThinkFast
//
//  Created on 2025-01-01.
//

import SwiftUI
import SwiftData

@main
struct ThinkFastApp: App {
    // MARK: - Properties
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    // MARK: - SwiftData Container
    let sharedModelContainer: ModelContainer = {
        let schema = Schema([
            UsageSession.self,
            UsageEvent.self,
            DailyStats.self,
            Goal.self,
            InterventionResult.self,
            StreakRecovery.self,
            UserBaseline.self
        ])

        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    // MARK: - Body
    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                MainTabView()
                    .tint(.appPrimary)
            } else {
                OnboardingView()
                    .tint(.appPrimary)
            }
        }
        .modelContainer(sharedModelContainer)
    }
}

// MARK: - Preview
#Preview {
    OnboardingView()
}
