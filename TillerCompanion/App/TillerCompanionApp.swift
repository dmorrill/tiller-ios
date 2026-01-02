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

// Services are now defined in separate files:
// - Services/AuthService.swift
// - Services/SyncManager.swift
// - Models/Models.swift