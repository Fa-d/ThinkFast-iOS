//
//  HapticFeedback.swift
//  ThinkFast
//
//  Created on 2025-01-01.
//

import UIKit

enum HapticFeedback {
    case success
    case warning
    case error
    case light
    case medium
    case heavy
    case selectionChanged
    case soft

    func feedback() {
        switch self {
        case .success:
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        case .warning:
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.warning)
        case .error:
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
        case .light:
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        case .medium:
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        case .heavy:
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.impactOccurred()
        case .selectionChanged:
            let generator = UISelectionFeedbackGenerator()
            generator.selectionChanged()
        case .soft:
            let generator = UIImpactFeedbackGenerator(style: .soft)
            generator.impactOccurred()
        }
    }
}

// MARK: - Convenience Extensions
extension HapticFeedback {
    /// Trigger feedback for goal completion
    static func goalCompleted() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)

        // Follow up with impact
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
            impactGenerator.impactOccurred()
        }
    }

    /// Trigger feedback for streak achievement
    static func streakAchieved() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)

        // Triple tap pattern
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            let impact = UIImpactFeedbackGenerator(style: .heavy)
            impact.impactOccurred()
        }
    }

    /// Trigger feedback for goal exceeded
    static func goalExceeded() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)

        // Two pulses
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            generator.notificationOccurred(.warning)
        }
    }

    /// Trigger feedback for intervention shown
    static func interventionShown() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }

    /// Trigger feedback for button press
    static func buttonPress() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }

    /// Trigger feedback for toggle switch
    static func toggleSwitch() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    /// Trigger feedback for delete action
    static func deleteAction() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()

        let notification = UINotificationFeedbackGenerator()
        notification.notificationOccurred(.warning)
    }

    /// Trigger feedback for app icon tap
    static func appIconTap() {
        let generator = UIImpactFeedbackGenerator(style: .soft)
        generator.impactOccurred()
    }
}
