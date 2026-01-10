//
//  SignInView.swift
//  Intently
//
//  Created on 2025-01-07.
//  Sign In with Apple authentication
//

import SwiftUI
import AuthenticationServices

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
                    // Sign in with Apple
                    SignInWithAppleButton(
                        .signIn,
                        onRequest: configureRequest,
                        onCompletion: handleCompletion
                    )
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 50)
                    .cornerRadius(AppTheme.CornerRadius.md)
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

                // Terms text
                VStack(spacing: AppTheme.Spacing.xs) {
                    Text("By continuing, you agree to our")
                        .font(.caption)
                        .foregroundColor(.appTextSecondary)

                    HStack(spacing: AppTheme.Spacing.xs) {
                        Link("Terms of Service", destination: URL(string: "https://example.com/terms")!)
                            .font(.caption)
                            .foregroundColor(.appPrimary)

                        Text("and")
                            .font(.caption)
                            .foregroundColor(.appTextSecondary)

                        Link("Privacy Policy", destination: URL(string: "https://example.com/privacy")!)
                            .font(.caption)
                            .foregroundColor(.appPrimary)
                    }
                }
                .padding(.bottom)

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
                Text("Your data will only be stored on this device. You won't be able to sync across devices or recover your account if you lose access.")
            }
        }
    }

    // MARK: - Sign in with Apple Configuration
    private func configureRequest(_ request: ASAuthorizationAppleIDRequest) {
        request.requestedScopes = [.fullName, .email]
    }

    // MARK: - Handle Completion
    private func handleCompletion(_ result: Result<ASAuthorization, Error>) {
        Task {
            await MainActor.run {
                isLoading = true
            }

            switch result {
            case .success(let authorization):
                guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                    await showError("Invalid credential")
                    return
                }

                let user = AuthUser(
                    id: credential.user,
                    email: credential.email,
                    displayName: credential.fullName?.formatted(),
                    photoURL: nil,
                    provider: .apple,
                    isAnonymous: false,
                    createdAt: Date()
                )

                // Save user
                do {
                    _ = try await dependencies.authRepository.signInWithApple()
                    // TODO: Save the actual user data
                    await MainActor.run {
                        isLoading = false
                        dismiss()
                    }
                } catch {
                    await showError("Failed to sign in: \(error.localizedDescription)")
                }

            case .failure(let error):
                await showError(error.localizedDescription)
            }
        }
    }

    // MARK: - Sign In Anonymously
    private func signInAnonymously() async {
        await MainActor.run {
            isLoading = true
        }

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

    // MARK: - Show Error
    private func showError(_ message: String) async {
        await MainActor.run {
            errorMessage = message
            isLoading = false
        }
    }
}

// MARK: - Preview
#Preview {
    SignInView()
}
