//
//  TillerCompanionApp.swift
//  TillerCompanion
//
//  Created on 12/29/24.
//

import SwiftUI

@main
struct TillerCompanionApp: App {
    // MARK: - Properties
    @StateObject private var authService = AuthService()
    @StateObject private var syncManager = SyncManager()

    // MARK: - Body
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authService)
                .environmentObject(syncManager)
                .onAppear {
                    setupApp()
                }
        }
    }

    // MARK: - Setup
    private func setupApp() {
        // Configure app settings
        configureAppearance()

        // Check authentication status
        Task {
            await authService.checkAuthStatus()
        }
    }

    private func configureAppearance() {
        // Set up global UI appearance
        UINavigationBar.appearance().prefersLargeTitles = true
    }
}

// MARK: - Placeholder Services (to be implemented)
class AuthService: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?

    func checkAuthStatus() async {
        // Check if user has valid auth token
        // This will connect to Laravel backend
    }
}

class SyncManager: ObservableObject {
    @Published var isSyncing = false
    @Published var lastSyncDate: Date?

    func performSync() async {
        // Sync with Google Sheets via Laravel API
    }
}

struct User {
    let id: String
    let email: String
    let googleId: String
}