//
//  AccessibilityModifiers.swift
//  TillerCompanion
//
//  Accessibility helpers and view extensions
//

import SwiftUI

// MARK: - Transaction Accessibility
extension TransactionRowView {
    var accessibilityDescription: String {
        let amount = transaction.isIncome ? "income" : "expense"
        let category = transaction.category ?? "uncategorized"
        return "\(transaction.description), \(transaction.displayAmount) \(amount), \(category), \(transaction.displayDate)"
    }
}

// MARK: - Reusable Accessibility Modifiers
struct AccessibleCardModifier: ViewModifier {
    let label: String
    let hint: String?

    func body(content: Content) -> some View {
        content
            .accessibilityElement(children: .combine)
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
    }
}

struct AccessibleButtonModifier: ViewModifier {
    let label: String
    let hint: String

    func body(content: Content) -> some View {
        content
            .accessibilityLabel(label)
            .accessibilityHint(hint)
            .accessibilityAddTraits(.isButton)
    }
}

extension View {
    func accessibleCard(_ label: String, hint: String? = nil) -> some View {
        modifier(AccessibleCardModifier(label: label, hint: hint))
    }

    func accessibleButton(_ label: String, hint: String) -> some View {
        modifier(AccessibleButtonModifier(label: label, hint: hint))
    }
}

// MARK: - Accessibility Labels for Common Elements
enum A11yLabels {
    // Navigation
    static let transactions = "Transactions tab"
    static let budget = "Budget tab"
    static let settings = "Settings tab"

    // Actions
    static let sync = "Sync now"
    static let signOut = "Sign out"
    static let categorize = "Categorize transaction"
    static let refresh = "Pull to refresh"

    // Status
    static func syncStatus(_ status: String) -> String {
        "Sync status: \(status)"
    }

    static func transactionCount(_ count: Int) -> String {
        "\(count) transaction\(count == 1 ? "" : "s")"
    }

    static func balance(_ amount: String, account: String) -> String {
        "\(account) balance: \(amount)"
    }

    static func budgetProgress(_ category: String, spent: String, budget: String) -> String {
        "\(category): \(spent) spent of \(budget) budget"
    }
}
