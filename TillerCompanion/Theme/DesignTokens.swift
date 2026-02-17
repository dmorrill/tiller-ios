//
//  DesignTokens.swift
//  TillerCompanion
//
//  Centralized design tokens for consistent styling
//

import SwiftUI

// MARK: - Color Tokens
enum TillerColors {
    // Brand
    static let primary = Color.blue
    static let primaryLight = Color.blue.opacity(0.1)
    static let accent = Color(red: 59/255, green: 130/255, blue: 246/255)

    // Semantic
    static let income = Color.green
    static let expense = Color(UIColor.label)
    static let warning = Color.orange
    static let error = Color.red
    static let success = Color.green
    static let info = Color.blue

    // Surfaces
    static let background = Color(UIColor.systemBackground)
    static let secondaryBackground = Color(UIColor.secondarySystemBackground)
    static let groupedBackground = Color(UIColor.systemGroupedBackground)
    static let cardBackground = Color(UIColor.secondarySystemGroupedBackground)

    // Text
    static let textPrimary = Color(UIColor.label)
    static let textSecondary = Color(UIColor.secondaryLabel)
    static let textTertiary = Color(UIColor.tertiaryLabel)

    // Category Colors
    static let categoryColors: [Color] = [
        Color(red: 255/255, green: 107/255, blue: 107/255),  // Red
        Color(red: 78/255, green: 205/255, blue: 196/255),   // Teal
        Color(red: 69/255, green: 183/255, blue: 209/255),   // Blue
        Color(red: 149/255, green: 231/255, blue: 126/255),  // Green
        Color(red: 255/255, green: 190/255, blue: 11/255),   // Yellow
        Color(red: 155/255, green: 89/255, blue: 182/255),   // Purple
        Color(red: 255/255, green: 159/255, blue: 67/255),   // Orange
        Color(red: 108/255, green: 92/255, blue: 231/255),   // Indigo
    ]
}

// MARK: - Spacing Tokens
enum TillerSpacing {
    static let xxs: CGFloat = 2
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
    static let xxxl: CGFloat = 48
}

// MARK: - Corner Radius Tokens
enum TillerRadius {
    static let sm: CGFloat = 4
    static let md: CGFloat = 8
    static let lg: CGFloat = 12
    static let xl: CGFloat = 16
    static let pill: CGFloat = 100
}

// MARK: - Typography Tokens
enum TillerFonts {
    static let largeTitle = Font.largeTitle.weight(.bold)
    static let title = Font.title2.weight(.semibold)
    static let headline = Font.headline
    static let body = Font.body
    static let caption = Font.caption
    static let mono = Font.system(.caption, design: .monospaced)
    static let amount = Font.system(.body, design: .rounded).weight(.medium)
    static let amountLarge = Font.system(.title3, design: .rounded).weight(.semibold)
}

// MARK: - Shadow Tokens
enum TillerShadows {
    static func card(_ scheme: ColorScheme = .light) -> some View {
        Color.black.opacity(scheme == .dark ? 0.3 : 0.08)
    }
    static let cardRadius: CGFloat = 8
    static let cardY: CGFloat = 2
}
