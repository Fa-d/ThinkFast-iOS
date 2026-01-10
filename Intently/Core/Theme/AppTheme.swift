//
//  AppTheme.swift
//  Intently
//
//  Created on 2025-01-01.
//

import SwiftUI

// MARK: - Color Extensions
extension Color {
    /// Primary brand color - Using blue as primary
    static let appPrimary = Color.blue

    /// Secondary accent color
    static let appSecondary = Color.purple

    /// Success color (for completed goals, streaks)
    static let appSuccess = Color.green

    /// Warning color (for approaching limits)
    static let appWarning = Color.orange

    /// Error color (for exceeded goals)
    static let appError = Color.red

    /// Background colors
    static let appBackground = Color(uiColor: .systemBackground)
    static let appSecondaryBackground = Color(uiColor: .secondarySystemBackground)
    static let appTertiaryBackground = Color(uiColor: .tertiarySystemBackground)

    /// Text colors
    static let appTextPrimary = Color(uiColor: .label)
    static let appTextSecondary = Color(uiColor: .secondaryLabel)
    static let appTextTertiary = Color(uiColor: .tertiaryLabel)

    /// Semantic colors
    static let appGreen = Color.green
    static let appOrange = Color.orange
    static let appRed = Color.red
}

// MARK: - App Theme
struct AppTheme {
    // MARK: - Spacing
    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }

    // MARK: - Corner Radius
    struct CornerRadius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let round: CGFloat = 9999
    }

    // MARK: - Font Sizes
    struct FontSize {
        static let caption: CGFloat = 12
        static let footnote: CGFloat = 13
        static let subheadline: CGFloat = 15
        static let body: CGFloat = 17
        static let headline: CGFloat = 17
        static let title3: CGFloat = 20
        static let title2: CGFloat = 22
        static let title1: CGFloat = 28
        static let largeTitle: CGFloat = 34
    }

    // MARK: - Icon Sizes
    struct IconSize {
        static let sm: CGFloat = 16
        static let md: CGFloat = 24
        static let lg: CGFloat = 32
        static let xl: CGFloat = 48
    }

    // MARK: - Animation
    struct Animation {
        static let fast = SwiftUI.Animation.easeInOut(duration: 0.2)
        static let normal = SwiftUI.Animation.easeInOut(duration: 0.3)
        static let slow = SwiftUI.Animation.easeInOut(duration: 0.5)
        static let spring = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.7)
    }
}

// MARK: - Gradient
extension LinearGradient {
    static func appPrimaryGradient() -> LinearGradient {
        LinearGradient(
            colors: [Color.blue.opacity(0.9), Color.purple.opacity(0.9)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static func appSuccessGradient() -> LinearGradient {
        LinearGradient(
            colors: [Color.green.opacity(0.8), Color.green],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static func appWarningGradient() -> LinearGradient {
        LinearGradient(
            colors: [Color.orange.opacity(0.8), Color.orange],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static func appErrorGradient() -> LinearGradient {
        LinearGradient(
            colors: [Color.red.opacity(0.8), Color.red],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
