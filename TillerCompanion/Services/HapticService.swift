//
//  HapticService.swift
//  TillerCompanion
//
//  Centralized haptic feedback service
//

import UIKit

enum HapticService {
    private static var isEnabled: Bool {
        UserDefaults.standard.object(forKey: "hapticFeedback") as? Bool ?? true
    }

    // MARK: - Impact
    static func light() {
        guard isEnabled else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func medium() {
        guard isEnabled else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    static func heavy() {
        guard isEnabled else { return }
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
    }

    // MARK: - Notification
    static func success() {
        guard isEnabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func warning() {
        guard isEnabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }

    static func error() {
        guard isEnabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }

    // MARK: - Selection
    static func selection() {
        guard isEnabled else { return }
        UISelectionFeedbackGenerator().selectionChanged()
    }

    // MARK: - Semantic Actions
    static func categorized() { success() }
    static func synced() { success() }
    static func syncFailed() { error() }
    static func tabChanged() { selection() }
    static func buttonTapped() { light() }
    static func swipeAction() { medium() }
}
