//
//  AuthRepositoryImpl.swift
//  Intently
//
//  Created on 2025-01-01.
//

import Foundation
import Combine
import AuthenticationServices

final class AuthRepositoryImpl: AuthRepository {

    // MARK: - Properties
    private(set) var currentUser: AuthUser?
    var isSignedIn: Bool { currentUser != nil }

    private let authStateSubject = CurrentValueSubject<AuthState, Never>(.signedOut)

    var authStateChanges: AsyncStream<AuthState> {
        AsyncStream<AuthState> { continuation in
            let cancellable = authStateSubject.sink { state in
                continuation.yield(state)
            }
            continuation.onTermination = { _ in
                cancellable.cancel()
            }
        }
    }

    // MARK: - Initializer
    init() {
        // TODO: Load saved user from UserDefaults/Keychain
    }

    // MARK: - Sign In
    func signInWithApple() async throws -> AuthUser {
        // TODO: Implement Sign in with Apple
        let user = AuthUser(
            id: UUID().uuidString,
            email: nil,
            displayName: "User",
            photoURL: nil,
            provider: .apple,
            isAnonymous: false,
            createdAt: Date()
        )
        currentUser = user
        authStateSubject.send(.signedIn(user))
        return user
    }

    func signInWithFacebook() async throws -> AuthUser {
        // TODO: Implement Sign in with Facebook
        let user = AuthUser(
            id: UUID().uuidString,
            email: nil,
            displayName: "User",
            photoURL: nil,
            provider: .facebook,
            isAnonymous: false,
            createdAt: Date()
        )
        currentUser = user
        authStateSubject.send(.signedIn(user))
        return user
    }

    func signInAnonymously() async throws -> AuthUser {
        let user = AuthUser(
            id: UUID().uuidString,
            email: nil,
            displayName: nil,
            photoURL: nil,
            provider: .anonymous,
            isAnonymous: true,
            createdAt: Date()
        )
        currentUser = user
        authStateSubject.send(.signedIn(user))
        return user
    }

    // MARK: - Sign Out
    func signOut() async throws {
        currentUser = nil
        authStateSubject.send(.signedOut)
    }

    // MARK: - Account Management
    func deleteAccount() async throws {
        // TODO: Implement account deletion
        currentUser = nil
        authStateSubject.send(.signedOut)
    }

    func updateUserProfile(_ profile: UserProfile) async throws {
        // TODO: Implement profile update
    }

    // MARK: - Linking
    func linkAppleAccount() async throws {
        // TODO: Implement Apple account linking
    }

    func linkFacebookAccount() async throws {
        // TODO: Implement Facebook account linking
    }
}
