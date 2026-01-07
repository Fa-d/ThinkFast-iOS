//
//  StartTrackingUseCase.swift
//  ThinkFast
//
//  Created on 2025-01-01.
//

import Foundation

struct StartTrackingUseCase {
    private let usageRepository: UsageRepository

    init(usageRepository: UsageRepository) {
        self.usageRepository = usageRepository
    }

    func execute(app: String, appName: String?) async throws -> UsageSession {
        // Check if there's already an active session for this app
        let hasActive = try await usageRepository.hasActiveSession(for: app)

        if hasActive {
            throw TrackingError.sessionAlreadyActive
        }

        return try await usageRepository.startSession(for: app, appName: appName)
    }
}

enum TrackingError: LocalizedError {
    case sessionAlreadyActive
    case appNotTracked
    case permissionDenied

    var errorDescription: String? {
        switch self {
        case .sessionAlreadyActive:
            return "A session is already active for this app"
        case .appNotTracked:
            return "This app is not being tracked"
        case .permissionDenied:
            return "Screen time permission is required"
        }
    }
}
