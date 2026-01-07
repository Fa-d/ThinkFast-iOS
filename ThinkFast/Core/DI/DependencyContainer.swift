//
//  DependencyContainer.swift
//  ThinkFast
//
//  Created on 2025-01-01.
//

import Foundation
import SwiftData

/// Protocol for dependency container
protocol DependencyContainer {
    var modelContext: ModelContext { get }
    var usageRepository: UsageRepository { get }
    var goalRepository: GoalRepository { get }
    var statsRepository: StatsRepository { get }
    var trackedAppsRepository: TrackedAppsRepository { get }
    var interventionResultRepository: InterventionResultRepository { get }
    var streakRecoveryRepository: StreakRecoveryRepository { get }
    var userBaselineRepository: UserBaselineRepository { get }
    var settingsRepository: SettingsRepository { get }
    var authRepository: AuthRepository { get }

    // JITAI Components
    var personaDetector: PersonaDetector { get }
    var opportunityDetector: OpportunityDetector { get }
    var contentSelector: ContentSelector { get }
    var personaAwareContentSelector: PersonaAwareContentSelector { get }
    var adaptiveInterventionRateLimiter: AdaptiveInterventionRateLimiter { get }
    var jitaiInterventionManager: JitaiInterventionManager { get }
}

/// Main dependency container implementation
final class AppDependencyContainer: DependencyContainer {
    // MARK: - Singleton
    static let shared = AppDependencyContainer()

    // MARK: - Properties
    let modelContext: ModelContext

    // MARK: - Repositories (Lazy)
    lazy var usageRepository: UsageRepository = UsageRepositoryImpl(context: modelContext)
    lazy var goalRepository: GoalRepository = GoalRepositoryImpl(context: modelContext)
    lazy var statsRepository: StatsRepository = StatsRepositoryImpl(context: modelContext)
    lazy var trackedAppsRepository: TrackedAppsRepository = TrackedAppsRepositoryImpl(context: modelContext)
    lazy var interventionResultRepository: InterventionResultRepository = InterventionResultRepositoryImpl(context: modelContext)
    lazy var streakRecoveryRepository: StreakRecoveryRepository = StreakRecoveryRepositoryImpl(context: modelContext)
    lazy var userBaselineRepository: UserBaselineRepository = UserBaselineRepositoryImpl(context: modelContext)
    lazy var settingsRepository: SettingsRepository = SettingsRepositoryImpl()
    lazy var authRepository: AuthRepository = AuthRepositoryImpl()

    // MARK: - JITAI Components (Lazy)
    lazy var personaDetector: PersonaDetector = PersonaDetector(
        interventionResultRepository: interventionResultRepository,
        usageRepository: usageRepository
    )

    lazy var opportunityDetector: OpportunityDetector = OpportunityDetector(
        interventionResultRepository: interventionResultRepository
    )

    lazy var contentSelector: ContentSelector = ContentSelector()

    lazy var personaAwareContentSelector: PersonaAwareContentSelector = PersonaAwareContentSelector(
        personaDetector: personaDetector,
        contentSelector: contentSelector
    )

    lazy var adaptiveInterventionRateLimiter: AdaptiveInterventionRateLimiter = AdaptiveInterventionRateLimiter(
        interventionPreferences: UserDefaults.standard,
        personaDetector: personaDetector,
        opportunityDetector: opportunityDetector
    )

    lazy var jitaiInterventionManager: JitaiInterventionManager = JitaiInterventionManager(
        personaDetector: personaDetector,
        opportunityDetector: opportunityDetector,
        personaAwareContentSelector: personaAwareContentSelector,
        adaptiveRateLimiter: adaptiveInterventionRateLimiter,
        interventionResultRepository: interventionResultRepository,
        goalRepository: goalRepository,
        usageRepository: usageRepository
    )

    // MARK: - Initializer
    private init(modelContext: ModelContext? = nil) {
        if let context = modelContext {
            self.modelContext = context
        } else {
            // Create a temporary container with all models
            let schema = Schema([
                UsageSession.self,
                UsageEvent.self,
                DailyStats.self,
                Goal.self,
                InterventionResult.self,
                StreakRecovery.self,
                UserBaseline.self
            ])
            let container = try! ModelContainer(for: schema, configurations: [ModelConfiguration()])
            self.modelContext = ModelContext(container)
        }
    }

    // MARK: - Convenience Initializer
    static func create(with modelContext: ModelContext) -> AppDependencyContainer {
        return AppDependencyContainer(modelContext: modelContext)
    }
}

// MARK: - Environment Key
import SwiftUI

struct DependencyContainerKey: EnvironmentKey {
    static let defaultValue: DependencyContainer = AppDependencyContainer.shared
}

extension EnvironmentValues {
    var dependencies: DependencyContainer {
        get { self[DependencyContainerKey.self] }
        set { self[DependencyContainerKey.self] = newValue }
    }
}
