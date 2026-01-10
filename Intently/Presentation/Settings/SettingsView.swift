//
//  SettingsView.swift
//  Intently
//
//  Created on 2025-01-01.
//

import SwiftUI

struct SettingsView: View {
    @State private var showingGoalManagement = false
    @State private var showingAppManagement = false
    @State private var showingAbout = false

    var body: some View {
        NavigationView {
            List {
                // Account Section
                Section {
                    NavigationLink(destination: AccountView()) {
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .foregroundColor(.appPrimary)
                            Text("Account")
                        }
                    }
                }

                // Goals & Apps Section
                Section {
                    NavigationLink(destination: GoalManagementView()) {
                        HStack {
                            Image(systemName: "target")
                                .foregroundColor(.appGreen)
                            Text("My Goals")
                        }
                    }

                    NavigationLink(destination: ManageAppsView { _ in
                        // Apps selected - refresh when returning
                    }) {
                        HStack {
                            Image(systemName: "app.badge")
                                .foregroundColor(.appOrange)
                            Text("Tracked Apps")
                        }
                    }
                }

                // Preferences Section
                Section {
                    NavigationLink(destination: NotificationsSettingsView()) {
                        HStack {
                            Image(systemName: "bell.fill")
                                .foregroundColor(.appPrimary)
                            Text("Notifications")
                        }
                    }

                    NavigationLink(destination: AppearanceSettingsView()) {
                        HStack {
                            Image(systemName: "moon.fill")
                                .foregroundColor(.purple)
                            Text("Appearance")
                        }
                    }

                    NavigationLink(destination: InterventionsSettingsView()) {
                        HStack {
                            Image(systemName: "hand.raised.fill")
                                .foregroundColor(.appRed)
                            Text("Intervention Settings")
                        }
                    }
                }

                // Data Section
                Section {
                    Button(action: {
                        // TODO: Implement export
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(.appPrimary)
                            Text("Export Data")
                        }
                    }

                    Button(action: {
                        // TODO: Implement delete
                    }) {
                        HStack {
                            Image(systemName: "trash")
                                .foregroundColor(.appRed)
                            Text("Delete All Data")
                        }
                    }
                }

                // Support Section
                Section {
                    NavigationLink(destination: HelpView()) {
                        HStack {
                            Image(systemName: "questionmark.circle.fill")
                                .foregroundColor(.appPrimary)
                            Text("Help & Support")
                        }
                    }

                    Button(action: { showingAbout = true }) {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.appPrimary)
                            Text("About")
                        }
                    }
                }

                // Version
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.appTextSecondary)
                    }
                }
            }
            .navigationTitle("Settings")
        }
        .sheet(isPresented: $showingAbout) {
            AboutView()
        }
    }
}

// MARK: - Account View
struct AccountView: View {
    @Environment(\.dependencies) private var dependencies
    @State private var currentUser: AuthUser?
    @State private var showingSignIn = false
    @State private var isLoading = true

    var body: some View {
        Form {
            Section {
                if isLoading {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                } else if let user = currentUser {
                    // User Info
                    HStack {
                        Text("Name")
                        Spacer()
                        Text(user.displayName ?? "User")
                            .foregroundColor(.appTextSecondary)
                    }

                    if let email = user.email {
                        HStack {
                            Text("Email")
                            Spacer()
                            Text(email)
                                .foregroundColor(.appTextSecondary)
                        }
                    }

                    HStack {
                        Text("Signed in with")
                        Spacer()
                        HStack(spacing: 4) {
                            providerIcon(user.provider)
                            Text(providerName(user.provider))
                                .foregroundColor(.appTextSecondary)
                        }
                    }

                    HStack {
                        Text("Account Type")
                        Spacer()
                        Text(user.isAnonymous ? "Anonymous" : "Connected")
                            .foregroundColor(.appTextSecondary)
                    }
                } else {
                    // Sign In Prompt
                    VStack(spacing: AppTheme.Spacing.md) {
                        Image(systemName: "person.circle.badge.plus")
                            .font(.system(size: 50))
                            .foregroundColor(.appTextTertiary)

                        Text("Sign In to Intently")
                            .font(.headline)

                        Text("Sync your data across devices and never lose your progress")
                            .font(.caption)
                            .foregroundColor(.appTextSecondary)
                            .multilineTextAlignment(.center)

                        Button("Sign In") {
                            showingSignIn = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                }
            }

            if currentUser != nil {
                Section {
                    Button("Sign Out", role: .destructive) {
                        Task {
                            await signOut()
                        }
                    }
                } footer: {
                    Text("Your local data will be kept on this device")
                        .font(.caption)
                }
            }
        }
        .navigationTitle("Account")
        .sheet(isPresented: $showingSignIn) {
            SignInView()
        }
        .task {
            await loadUser()
        }
    }

    // MARK: - Load User
    private func loadUser() async {
        isLoading = true
        // Check if user is signed in
        let authRepository = dependencies.authRepository
        if authRepository.isSignedIn {
            // In a real implementation, we'd fetch the user details
            // For now, we'll simulate this
            currentUser = AuthUser(
                id: UUID().uuidString,
                email: "user@example.com",
                displayName: "User",
                photoURL: nil,
                provider: .apple,
                isAnonymous: false,
                createdAt: Date()
            )
        }
        isLoading = false
    }

    // MARK: - Sign Out
    private func signOut() async {
        try? await dependencies.authRepository.signOut()
        currentUser = nil
    }

    // MARK: - Provider Name
    private func providerName(_ provider: AuthProvider) -> String {
        switch provider {
        case .apple: return "Apple"
        case .facebook: return "Facebook"
        case .anonymous: return "Anonymous"
        }
    }

    // MARK: - Provider Icon
    private func providerIcon(_ provider: AuthProvider) -> some View {
        Image(systemName: iconName(for: provider))
            .foregroundColor(iconColor(for: provider))
            .frame(width: 20)
    }

    private func iconName(for provider: AuthProvider) -> String {
        switch provider {
        case .apple: return "applelogo"
        case .facebook: return "f.circle.fill"
        case .anonymous: return "person.fill"
        }
    }

    private func iconColor(for provider: AuthProvider) -> Color {
        switch provider {
        case .apple: return .primary
        case .facebook: return .blue
        case .anonymous: return .gray
        }
    }
}

// MARK: - Notifications Settings View
struct NotificationsSettingsView: View {
    @State private var notificationsEnabled = true
    @State private var reminderTime = Date()
    @State private var quietModeEnabled = false

    var body: some View {
        Form {
            Section {
                Toggle("Enable Notifications", isOn: $notificationsEnabled)
            } header: {
                Text("Notifications")
            } footer: {
                Text("Receive reminders about your usage goals and streak recovery")
            }

            if notificationsEnabled {
                Section {
                    DatePicker("Daily Reminder", selection: $reminderTime, displayedComponents: .hourAndMinute)

                    Toggle("Quiet Mode", isOn: $quietModeEnabled)
                } header: {
                    Text("Reminder Settings")
                }
            }
        }
        .navigationTitle("Notifications")
    }
}

// MARK: - Appearance Settings View
struct AppearanceSettingsView: View {
    @State private var selectedMode: AppearanceMode = .system

    var body: some View {
        Form {
            Section {
                Picker("Appearance", selection: $selectedMode) {
                    Text("System").tag(AppearanceMode.system)
                    Text("Light").tag(AppearanceMode.light)
                    Text("Dark").tag(AppearanceMode.dark)
                }
                .pickerStyle(.inline)
            } header: {
                Text("Theme")
            } footer: {
                Text("Choose how Intently appears")
            }
        }
        .navigationTitle("Appearance")
    }
}

// MARK: - Interventions Settings View
struct InterventionsSettingsView: View {
    @State private var selectedFrequency: InterventionFrequency = .medium
    @State private var selectedTypes: Set<String> = Set(SettingsInterventionType.allCases.map { $0.rawValue })

    var body: some View {
        Form {
            Section {
                Picker("Frequency", selection: $selectedFrequency) {
                    ForEach(InterventionFrequency.allCases, id: \.self) { frequency in
                        Text(frequency.rawValue).tag(frequency)
                    }
                }
            } header: {
                Text("How Often")
            } footer: {
                Text(selectedFrequency.description)
            }

            Section {
                ForEach(SettingsInterventionType.allCases, id: \.rawValue) { type in
                    Toggle(type.rawValue, isOn: Binding(
                        get: { selectedTypes.contains(type.rawValue) },
                        set: { newValue in
                            if newValue {
                                selectedTypes.insert(type.rawValue)
                            } else {
                                selectedTypes.remove(type.rawValue)
                            }
                        }
                    ))
                }
            } header: {
                Text("Intervention Types")
            } footer: {
                Text("Choose which types of interventions you want to see")
            }
        }
        .navigationTitle("Intervention Settings")
    }
}

// MARK: - Help View
struct HelpView: View {
    var body: some View {
        Form {
            Section("FAQ") {
                NavigationLink("How does Intently work?") {
                    Text("Intently helps you build healthier digital habits by tracking your app usage and showing gentle interventions when you exceed your goals.")
                        .padding()
                }

                NavigationLink("What are interventions?") {
                    Text("Interventions are gentle reminders that appear when you open a tracked app. They can be reflection questions, breathing exercises, or activity suggestions.")
                        .padding()
                }

                NavigationLink("How are streaks calculated?") {
                    Text("A streak is counted for each day you stay within your daily limit. If you exceed it, you can recover your streak by staying under the limit for 3 consecutive days.")
                        .padding()
                }
            }

            Section {
                Link("Privacy Policy", destination: URL(string: "https://example.com/privacy")!)
                Link("Terms of Service", destination: URL(string: "https://example.com/terms")!)
                Link("Contact Support", destination: URL(string: "mailto:support@thinkfast.app")!)
            }

            Section {
                Text("Intently v1.0.0")
                    .foregroundColor(.appTextSecondary)
            }
        }
        .navigationTitle("Help & Support")
    }
}

// MARK: - About View
struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: AppTheme.Spacing.xl) {
                // App Icon
                RoundedRectangle(cornerRadius: 20)
                    .fill(LinearGradient.appPrimaryGradient())
                    .frame(width: 100, height: 100)
                    .overlay {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 50))
                            .foregroundColor(.white)
                    }

                // App Name
                Text("Intently")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Build healthier digital habits")
                    .font(.subheadline)
                    .foregroundColor(.appTextSecondary)

                // Info
                VStack(spacing: AppTheme.Spacing.sm) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.appTextSecondary)
                    }

                    HStack {
                        Text("Build")
                        Spacer()
                        Text("1")
                            .foregroundColor(.appTextSecondary)
                    }
                }
                .padding()
                .background(Color.appSecondaryBackground)
                .cornerRadius(AppTheme.CornerRadius.md)

                Spacer()

                // Credits
                Text("Made with ❤️ for mindful tech usage")
                    .font(.caption)
                    .foregroundColor(.appTextTertiary)
            }
            .padding()
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Sign In View
struct SignInView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dependencies) private var dependencies

    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showAnonymousAlert = false

    var body: some View {
        NavigationView {
            VStack(spacing: AppTheme.Spacing.xl) {
                Spacer()

                // Logo and Title
                VStack(spacing: AppTheme.Spacing.md) {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(LinearGradient.appPrimaryGradient())
                        .frame(width: 100, height: 100)
                        .overlay {
                            Image(systemName: "brain.head.profile")
                                .font(.system(size: 50))
                                .foregroundColor(.white)
                        }

                    Text("Intently")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("Build healthier digital habits")
                        .font(.subheadline)
                        .foregroundColor(.appTextSecondary)
                }

                Spacer()

                // Sign In Options
                VStack(spacing: AppTheme.Spacing.md) {
                    // Simple button placeholder for Apple sign in
                    Button(action: { Task { await signInWithApple() } }) {
                        HStack {
                            Image(systemName: "applelogo")
                            Text("Sign in with Apple")
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.black)
                        .cornerRadius(AppTheme.CornerRadius.md)
                    }
                    .disabled(isLoading)

                    // Sign in anonymously
                    Button(action: { showAnonymousAlert = true }) {
                        HStack {
                            Image(systemName: "person.fill")
                                .foregroundColor(.appTextSecondary)
                            Text("Continue without account")
                                .font(.subheadline)
                                .foregroundColor(.appTextSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.appSecondaryBackground)
                        .cornerRadius(AppTheme.CornerRadius.md)
                    }
                    .disabled(isLoading)
                }
                .padding(.horizontal)

                // Error message
                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.appRed)
                        .padding(.horizontal)
                        .multilineTextAlignment(.center)
                }

                Spacer()
            }
            .navigationTitle("Sign In")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.appPrimary)
                }
            }
            .overlay {
                if isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                        .shadow(radius: 5)
                }
            }
            .alert("Continue Anonymously", isPresented: $showAnonymousAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Continue") {
                    Task {
                        await signInAnonymously()
                    }
                }
            } message: {
                Text("Your data will only be stored on this device. You won't be able to sync across devices.")
            }
        }
    }

    private func signInWithApple() async {
        await MainActor.run { isLoading = true }
        do {
            _ = try await dependencies.authRepository.signInWithApple()
            await MainActor.run {
                isLoading = false
                dismiss()
            }
        } catch {
            await showError("Failed to sign in: \(error.localizedDescription)")
        }
    }

    private func signInAnonymously() async {
        await MainActor.run { isLoading = true }
        do {
            _ = try await dependencies.authRepository.signInAnonymously()
            await MainActor.run {
                isLoading = false
                dismiss()
            }
        } catch {
            await showError("Failed to continue: \(error.localizedDescription)")
        }
    }

    private func showError(_ message: String) async {
        await MainActor.run {
            errorMessage = message
            isLoading = false
        }
    }
}

#Preview {
    SettingsView()
}
