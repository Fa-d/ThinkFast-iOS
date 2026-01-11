//
//  IntentlyApp.swift
//  Intently
//
//  Created on 2025-01-01.
//

import SwiftUI
import SwiftData

@main
struct IntentlyApp: App {
    // MARK: - Properties
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    // MARK: - SwiftData Container
    // Use static to ensure only one instance is created, preventing CloudKit duplicate registration warnings
    static let sharedModelContainer: ModelContainer = {
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
        .modelContainer(Self.sharedModelContainer)
    }
}

// MARK: - Preview
#Preview {
    OnboardingView()
}
