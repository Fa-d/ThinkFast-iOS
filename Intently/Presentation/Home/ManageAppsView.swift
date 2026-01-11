//
//  ManageAppsView.swift
//  Intently
//
//  Created on 2025-01-01.
//

import SwiftUI
import FamilyControls

struct ManageAppsView: View {
    @Environment(\.dependencies) private var dependencies
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var viewModel: ManageAppsViewModel?
    @State private var showingPopularOnly = false
    @State private var showingGoalSetup = false
    @State private var showingAppPicker = false
    @State private var familyActivitySelection = FamilyActivitySelection()
    @State private var isAuthorized = false
    @State private var showingAuthorizationSheet = false
    @State private var authorizationError: String?

    var onAppsSelected: (([TrackedApp]) -> Void)? = nil

    init(onAppsSelected: (([TrackedApp]) -> Void)? = nil) {
        // ViewModel will be initialized in onAppear using environment dependencies
        _viewModel = State(initialValue: nil)
        self.onAppsSelected = onAppsSelected
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Info header
                VStack(spacing: AppTheme.Spacing.md) {
                    Image(systemName: "app.badge.checkmark.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.appPrimary)
                        .padding(.top, AppTheme.Spacing.lg)

                    Text("Select Apps to Track")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Choose the apps you want to set daily usage goals for. You'll be able to set specific time limits after selection.")
                        .font(.subheadline)
                        .foregroundColor(.appTextSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, AppTheme.Spacing.xl)
                        .padding(.bottom, AppTheme.Spacing.sm)

                    // Help text
                    HStack(spacing: AppTheme.Spacing.sm) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.appPrimary)
                            .font(.caption)

                        Text("Default goal: 60 minutes per day")
                            .font(.caption)
                            .foregroundColor(.appTextSecondary)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, AppTheme.Spacing.xs)
                    .background(Color.appSecondaryBackground.opacity(0.5))
                    .cornerRadius(AppTheme.CornerRadius.md)
                    .padding(.bottom, AppTheme.Spacing.md)
                }
                .padding(.horizontal)

                Divider()

                #if targetEnvironment(simulator)
                // Simulator fallback - show predefined apps
                simulatorAppsList
                #else
                // Real device - use FamilyActivityPicker
                if isAuthorized {
                    FamilyActivityPicker(selection: $familyActivitySelection)
                        .edgesIgnoringSafeArea(.bottom)
                } else {
                    authorizationPromptView
                }
                #endif
            }
            .navigationTitle("Track Apps")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        saveAndDismiss()
                    }
                    .fontWeight(.semibold)
                    #if targetEnvironment(simulator)
                    .disabled(viewModel?.selectedApps.isEmpty ?? true)
                    #else
                    .disabled(familyActivitySelection.applicationTokens.isEmpty &&
                             familyActivitySelection.categoryTokens.isEmpty)
                    #endif
                }
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = ManageAppsViewModel(
                    trackedAppsRepository: dependencies.trackedAppsRepository,
                    goalRepository: dependencies.goalRepository
                )
            }
            loadCurrentSelection()
            checkAuthorizationStatus()
        }
        .task {
            // Load existing goals and mark apps as selected
            await viewModel?.loadData()
        }
    }

    // MARK: - Load Current Selection
    private func loadCurrentSelection() {
        // Note: FamilyActivitySelection is automatically persisted by the system
        // We don't need to manually save/load it
    }

    // MARK: - Save and Dismiss
    private func saveAndDismiss() {
        Task {
            #if targetEnvironment(simulator)
            // Simulator: Use ManageAppsViewModel to save changes
            try? await viewModel?.saveChanges()

            // Get selected apps for callback
            let selectedApps = viewModel?.getSelectedApps() ?? []
            onAppsSelected?(selectedApps)
            #else
            // Real device: Convert FamilyActivityPicker tokens to goals
            await saveSelectedAppsAsGoals()
            onAppsSelected?([])
            #endif

            // Dismiss the view
            await MainActor.run {
                dismiss()
            }
        }
    }

    // MARK: - Simulator Apps List
    private var simulatorAppsList: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.sm) {
                ForEach(simulatorApps, id: \.id) { app in
                    SimulatorAppRow(
                        app: app,
                        isSelected: viewModel?.selectedApps.contains(app.id) ?? false
                    ) {
                        Task {
                            await viewModel?.toggleApp(app)
                        }
                    }
                }
            }
            .padding()
        }
    }

    private var simulatorApps: [TrackedApp] {
        return [
            TrackedApp(id: "com.facebook.Facebook", name: "Facebook", icon: "facebook.fill", category: .social, isEnabled: true, isSelected: false, isRecommended: true),
            TrackedApp(id: "com.instagram.Instagram", name: "Instagram", icon: "instagram", category: .social, isEnabled: true, isSelected: false, isRecommended: true),
            TrackedApp(id: "com.zhiliaoapp.musically", name: "TikTok", icon: "music.note", category: .entertainment, isEnabled: true, isSelected: false, isRecommended: true),
            TrackedApp(id: "com.atebits.Tweetie2", name: "X (Twitter)", icon: "at", category: .social, isEnabled: true, isSelected: false, isRecommended: false),
            TrackedApp(id: "com.google.ios.youtube", name: "YouTube", icon: "play.rectangle.fill", category: .entertainment, isEnabled: true, isSelected: false, isRecommended: true),
            TrackedApp(id: "com.toyopagroup.picaboo", name: "Snapchat", icon: "camera.fill", category: .social, isEnabled: true, isSelected: false, isRecommended: false),
            TrackedApp(id: "com.reddit.Reddit", name: "Reddit", icon: "arrow.up.circle", category: .social, isEnabled: true, isSelected: false, isRecommended: false),
            TrackedApp(id: "com.netflix.Netflix", name: "Netflix", icon: "tv.fill", category: .entertainment, isEnabled: true, isSelected: false, isRecommended: false),
        ]
    }

    // MARK: - Authorization
    private func checkAuthorizationStatus() {
        #if !targetEnvironment(simulator)
        let center = AuthorizationCenter.shared
        isAuthorized = center.authorizationStatus == .approved

        if !isAuthorized {
            // Request authorization immediately
            Task {
                await requestAuthorization()
            }
        }
        #endif
    }

    private func requestAuthorization() async {
        #if !targetEnvironment(simulator)
        let center = AuthorizationCenter.shared
        do {
            try await center.requestAuthorization(for: .individual)
            await MainActor.run {
                isAuthorized = center.authorizationStatus == .approved
                if !isAuthorized {
                    authorizationError = "Authorization was not approved. Please go to Settings > Screen Time to grant access."
                }
            }
        } catch {
            await MainActor.run {
                authorizationError = error.localizedDescription
                isAuthorized = false
            }
        }
        #endif
    }

    // MARK: - Authorization Prompt View
    private var authorizationPromptView: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            Spacer()

            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.appOrange)

            Text("Authorization Required")
                .font(.title2)
                .fontWeight(.bold)

            if let error = authorizationError {
                Text(error)
                    .font(.body)
                    .foregroundColor(.appTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            } else {
                Text("Intently needs permission to access your installed apps to track usage.")
                    .font(.body)
                    .foregroundColor(.appTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Button {
                Task {
                    await requestAuthorization()
                }
            } label: {
                Text("Grant Access")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.appPrimary)
                    .cornerRadius(AppTheme.CornerRadius.md)
            }
            .padding(.horizontal)

            Spacer()
        }
    }

    // MARK: - Save Selected Apps as Goals
    private func saveSelectedAppsAsGoals() async {
        let goalRepository = dependencies.goalRepository

        // Get all existing goals
        let existingGoals = (try? await goalRepository.getAllGoals()) ?? []

        // Create a set of bundle IDs from selected apps
        let selectedBundleIds = Set(familyActivitySelection.applicationTokens.map { token in
            // Note: ApplicationToken doesn't directly expose bundle ID for privacy
            // We'll use the token's hash as a unique identifier
            "app_\(token.hashValue)"
        })

        // Delete goals for apps that are no longer selected
        for goal in existingGoals {
            if goal.targetApp.starts(with: "app_") && !selectedBundleIds.contains(goal.targetApp) {
                try? await goalRepository.deleteGoal(for: goal.targetApp)
            }
        }

        // Create goals for newly selected apps
        for token in familyActivitySelection.applicationTokens {
            let appId = "app_\(token.hashValue)"

            // Check if goal already exists
            if (try? await goalRepository.getGoal(for: appId)) == nil {
                // Create new goal with default 60 minute limit
                // Note: We use the hash as the name since we can't get the app name directly
                try? await goalRepository.setGoal(
                    for: appId,
                    appName: "App \(abs(token.hashValue) % 1000)", // Temporary name
                    dailyLimitMinutes: 60
                )
            }
        }
    }

}

// MARK: - Simulator App Row
struct SimulatorAppRow: View {
    let app: TrackedApp
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: AppTheme.Spacing.md) {
                AppIconView(appName: app.name, size: 45)

                VStack(alignment: .leading, spacing: 4) {
                    Text(app.name)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    if app.isRecommended {
                        Text("Recommended")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.appSecondary.opacity(0.3))
                            .foregroundColor(.appPrimary)
                            .cornerRadius(4)
                    }
                }

                Spacer()

                ZStack {
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.appPrimary)
                            .font(.title3)
                    } else {
                        Image(systemName: "circle")
                            .foregroundColor(.appTextTertiary)
                            .font(.title3)
                    }
                }
            }
            .padding(AppTheme.Spacing.sm)
            .background(Color.appSecondaryBackground.opacity(isSelected ? 0.5 : 0.1))
            .cornerRadius(AppTheme.CornerRadius.md)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ManageAppsView { _ in }
}
