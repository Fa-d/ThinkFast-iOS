//
//  CommonViews.swift
//  Intently
//
//  Created on 2025-01-01.
//

import SwiftUI

// MARK: - Primary Button
struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    var isLoading: Bool = false
    var isDisabled: Bool = false

    var body: some View {
        Button(action: action) {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .padding(.trailing, 8)
                }
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppTheme.Spacing.md)
            .background(
                LinearGradient.appPrimaryGradient()
            )
            .foregroundColor(.white)
            .cornerRadius(AppTheme.CornerRadius.md)
        }
        .disabled(isDisabled || isLoading)
        .opacity(isDisabled || isLoading ? 0.6 : 1)
    }
}

// MARK: - Secondary Button
struct SecondaryButton: View {
    let title: String
    let action: () -> Void
    var isDestructive: Bool = false

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .fontWeight(.medium)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppTheme.Spacing.md)
                .background(isDestructive ? Color.appError.opacity(0.1) : Color.appSecondaryBackground)
                .foregroundColor(isDestructive ? Color.appError : Color.appPrimary)
                .cornerRadius(AppTheme.CornerRadius.md)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md)
                        .stroke(isDestructive ? Color.appError : Color.appPrimary, lineWidth: 1)
                )
        }
    }
}

// MARK: - Card View
struct CardView<Content: View>: View {
    let content: Content
    var padding: CGFloat = AppTheme.Spacing.md

    init(@ViewBuilder content: () -> Content, padding: CGFloat = AppTheme.Spacing.md) {
        self.content = content()
        self.padding = padding
    }

    var body: some View {
        content
            .padding(padding)
            .background(Color.appSecondaryBackground)
            .cornerRadius(AppTheme.CornerRadius.lg)
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Progress Bar
struct ProgressBar: View {
    let progress: Double // 0.0 to 1.0
    var color: Color = .appPrimary

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.sm)
                    .fill(Color.appTertiaryBackground)
                    .frame(height: 8)

                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.sm)
                    .fill(color)
                    .frame(width: geometry.size.width * CGFloat(progress), height: 8)
            }
        }
        .frame(height: 8)
    }
}

// MARK: - Circular Progress
struct CircularProgress: View {
    let progress: Double // 0.0 to 1.0
    var size: CGFloat = 80
    var lineWidth: CGFloat = 8
    var color: Color = .appPrimary

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.appTertiaryBackground, lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    color,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(), value: progress)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String?
    var icon: String?
    var color: Color = .appPrimary

    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                HStack {
                    if let icon = icon {
                        Image(systemName: icon)
                            .foregroundColor(color)
                            .font(.title3)
                    }
                    Text(title)
                        .font(.subheadline)
                        .foregroundColor(.appTextSecondary)
                    Spacer()
                }

                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.appTextPrimary)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.appTextTertiary)
                }
            }
        }
    }
}

// MARK: - App Icon View
struct AppIconView: View {
    let appName: String
    var systemImage: String = "app.fill"
    var size: CGFloat = 50

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md)
                .fill(
                    LinearGradient(
                        colors: [.appPrimary.opacity(0.8), .appSecondary.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)

            Image(systemName: systemImage)
                .font(.system(size: size * 0.4))
                .foregroundColor(.white)
        }
    }
}

// MARK: - Empty State
struct EmptyState: View {
    let image: String
    let title: String
    let subtitle: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            Image(systemName: image)
                .font(.system(size: 60))
                .foregroundColor(.appTextTertiary)

            VStack(spacing: AppTheme.Spacing.xs) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.appTextPrimary)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.appTextSecondary)
                    .multilineTextAlignment(.center)
            }

            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.headline)
                        .foregroundColor(.appPrimary)
                }
            }
        }
        .padding(AppTheme.Spacing.xl)
    }
}

// MARK: - Previews
#Preview("Buttons") {
    VStack(spacing: AppTheme.Spacing.md) {
        PrimaryButton(title: "Get Started", action: {})
        PrimaryButton(title: "Loading...", action: {}, isLoading: true)
        PrimaryButton(title: "Disabled", action: {}, isDisabled: true)
        SecondaryButton(title: "Cancel", action: {})
        SecondaryButton(title: "Delete", action: {}, isDestructive: true)
    }
    .padding()
}

#Preview("Cards") {
    VStack(spacing: AppTheme.Spacing.md) {
        StatCard(
            title: "Today's Usage",
            value: "2h 15m",
            subtitle: "15m under goal",
            icon: "chart.bar.fill",
            color: .appGreen
        )

        CardView {
            Text("Custom content card")
                .font(.body)
        }
    }
    .padding()
}

#Preview("Progress") {
    VStack(spacing: AppTheme.Spacing.lg) {
        ProgressBar(progress: 0.7, color: .appGreen)
        CircularProgress(progress: 0.65, size: 100)
    }
    .padding()
}
