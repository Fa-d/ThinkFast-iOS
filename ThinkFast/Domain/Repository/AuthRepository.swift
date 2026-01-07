//
//  AuthRepository.swift
//  ThinkFast
//
//  Created on 2025-01-01.
//

import Foundation

protocol AuthRepository {
    // MARK: - Authentication State
    var currentUser: AuthUser? { get }
    var isSignedIn: Bool { get }
    var authStateChanges: AsyncStream<AuthState> { get }

    // MARK: - Sign In
    func signInWithApple() async throws -> AuthUser
    func signInWithFacebook() async throws -> AuthUser
    func signInAnonymously() async throws -> AuthUser

    // MARK: - Sign Out
    func signOut() async throws

    // MARK: - Account Management
    func deleteAccount() async throws
    func updateUserProfile(_ profile: UserProfile) async throws

    // MARK: - Linking
    func linkAppleAccount() async throws
    func linkFacebookAccount() async throws
}

// MARK: - Supporting Types
struct AuthUser: Identifiable, Codable {
    let id: String
    let email: String?
    let displayName: String?
    let photoURL: String?
    let provider: AuthProvider
    let isAnonymous: Bool
    let createdAt: Date
}

enum AuthProvider: String, Codable {
    case apple = "apple.com"
    case facebook = "facebook.com"
    case anonymous = "anonymous"
}

enum AuthState {
    case signedIn(AuthUser)
    case signedOut
    case error(Error)
}

struct UserProfile: Codable {
    let displayName: String?
    let photoURL: String?
    let preferences: UserPreferences?
}

struct UserPreferences: Codable {
    let notificationEnabled: Bool
    let quietHours: QuietHours?
}

struct QuietHours: Codable {
    let startHour: Int
    let endHour: Int
}
