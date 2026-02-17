//
//  AppTheme.swift
//  TillerCompanion
//
//  Dark mode support and adaptive color definitions
//

import SwiftUI

// MARK: - Appearance Manager
class AppearanceManager: ObservableObject {
    @AppStorage("appearanceMode") var appearanceMode: AppearanceMode = .system

    enum AppearanceMode: String, CaseIterable {
        case system = "System"
        case light = "Light"
        case dark = "Dark"

        var colorScheme: ColorScheme? {
            switch self {
            case .system: return nil
            case .light: return .light
            case .dark: return .dark
            }
        }

        var icon: String {
            switch self {
            case .system: return "circle.lefthalf.filled"
            case .light: return "sun.max.fill"
            case .dark: return "moon.fill"
            }
        }
    }
}

// MARK: - Adaptive Colors
extension Color {
    static let tillerBackground = Color("TillerBackground", bundle: nil)
    static let tillerCardBackground = Color(UIColor.secondarySystemGroupedBackground)
    static let tillerSeparator = Color(UIColor.separator)
    static let tillerSecondaryText = Color(UIColor.secondaryLabel)

    // Semantic colors that adapt to dark mode
    static let incomeGreen = Color.green
    static let expenseColor = Color(UIColor.label)
    static let warningOrange = Color.orange
    static let errorRed = Color.red
    static let syncBlue = Color.blue
}

// MARK: - Preferred Color Scheme Modifier
struct PreferredAppearanceModifier: ViewModifier {
    @ObservedObject var manager: AppearanceManager

    func body(content: Content) -> some View {
        if let scheme = manager.appearanceMode.colorScheme {
            content.preferredColorScheme(scheme)
        } else {
            content
        }
    }
}

extension View {
    func preferredAppearance(_ manager: AppearanceManager) -> some View {
        modifier(PreferredAppearanceModifier(manager: manager))
    }
}
