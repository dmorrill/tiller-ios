//
//  UserPreferencesView.swift
//  TillerCompanion
//
//  User settings and preferences screen
//

import SwiftUI

class UserPreferences: ObservableObject {
    @AppStorage("autoSync") var autoSync = true
    @AppStorage("syncInterval") var syncInterval = 15
    @AppStorage("enableNotifications") var enableNotifications = true
    @AppStorage("defaultFilter") var defaultFilter = "uncategorized"
    @AppStorage("useBiometrics") var useBiometrics = false
    @AppStorage("hapticFeedback") var hapticFeedback = true
    @AppStorage("compactMode") var compactMode = false
    @AppStorage("currencyCode") var currencyCode = "USD"

    static let shared = UserPreferences()
}

struct UserPreferencesView: View {
    @StateObject private var preferences = UserPreferences.shared
    @Environment(\.dismiss) private var dismiss

    private let syncIntervals = [5, 10, 15, 30, 60]
    private let currencies = ["USD", "EUR", "GBP", "CAD", "AUD", "JPY"]
    private let filters = [
        ("all", "All Transactions"),
        ("uncategorized", "Uncategorized"),
        ("recent", "Recent")
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Sync") {
                    Toggle("Auto-Sync", isOn: $preferences.autoSync)
                    if preferences.autoSync {
                        Picker("Sync Interval", selection: $preferences.syncInterval) {
                            ForEach(syncIntervals, id: \.self) { interval in
                                Text("\(interval) min").tag(interval)
                            }
                        }
                    }
                }

                Section("Display") {
                    Picker("Currency", selection: $preferences.currencyCode) {
                        ForEach(currencies, id: \.self) { code in
                            Text(code).tag(code)
                        }
                    }
                    Picker("Default Filter", selection: $preferences.defaultFilter) {
                        ForEach(filters, id: \.0) { filter in
                            Text(filter.1).tag(filter.0)
                        }
                    }
                    Toggle("Compact Mode", isOn: $preferences.compactMode)
                }

                Section("Security") {
                    Toggle("Face ID / Touch ID", isOn: $preferences.useBiometrics)
                }

                Section("Feedback") {
                    Toggle("Haptic Feedback", isOn: $preferences.hapticFeedback)
                    Toggle("Notifications", isOn: $preferences.enableNotifications)
                }
            }
            .navigationTitle("Preferences")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    UserPreferencesView()
}
