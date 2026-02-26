//
//  PrivacyPolicyView.swift
//  TillerCompanion
//
//  In-app privacy policy display
//

import SwiftUI

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Group {
                    Text("Privacy Policy")
                        .font(.title)
                        .fontWeight(.bold)

                    Text("Last updated: February 2026")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                section("Overview",
                    "Tiller Companion is an open-source iOS app that provides a mobile interface to your Tiller spreadsheet. We are committed to protecting your privacy and being transparent about our practices."
                )

                section("Data We Access",
                    """
                    • **Transaction data** from your connected Google Sheet (read & write)
                    • **Account email** for authentication
                    • **Sheet structure** to detect your Tiller template

                    All data is accessed through our backend API which communicates with Google Sheets on your behalf.
                    """
                )

                section("Data We Do NOT Collect",
                    """
                    • We do not store your financial data on our servers beyond what's needed for sync
                    • We do not use analytics or tracking SDKs
                    • We do not collect device identifiers or usage telemetry
                    • We do not sell or share any data with third parties
                    """
                )

                section("Authentication",
                    "Your authentication token is stored securely in the iOS Keychain. We use token-based authentication (Laravel Sanctum) and never store your password on-device."
                )

                section("Google Sheets Access",
                    "The app accesses your Google Sheet through a service account you explicitly share your spreadsheet with. We only read and write to documented columns (Category, Note, Tags, and a mobile ID column)."
                )

                section("Open Source",
                    "This app is fully open source under the MIT License. You can audit every line of code at github.com/dmorrill/tiller-ios."
                )

                section("Contact",
                    "For privacy questions or concerns, please open an issue on our GitHub repository."
                )
            }
            .padding()
        }
        .navigationTitle("Privacy Policy")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func section(_ title: String, _ body: LocalizedStringKey) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            Text(body)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    NavigationStack {
        PrivacyPolicyView()
    }
}
