//
//  EmptyStateView.swift
//  TillerCompanion
//
//  Reusable empty state view for lists and collections
//

import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: icon)
                .font(.system(size: 64))
                .foregroundColor(.secondary.opacity(0.6))

            Text(title)
                .font(.title2)
                .fontWeight(.semibold)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.top, 8)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Preset Empty States
extension EmptyStateView {
    static var noTransactions: EmptyStateView {
        EmptyStateView(
            icon: "doc.text.magnifyingglass",
            title: "No Transactions",
            message: "Pull to refresh or adjust your filters to see transactions."
        )
    }

    static var noCategories: EmptyStateView {
        EmptyStateView(
            icon: "tag",
            title: "No Categories",
            message: "Categories will appear once your sheet is synced."
        )
    }

    static var noSheets: EmptyStateView {
        EmptyStateView(
            icon: "tablecells",
            title: "No Sheets Connected",
            message: "Connect your Tiller spreadsheet to get started."
        )
    }

    static var noSearchResults: EmptyStateView {
        EmptyStateView(
            icon: "magnifyingglass",
            title: "No Results",
            message: "Try a different search term."
        )
    }
}

#Preview {
    EmptyStateView.noTransactions
}
