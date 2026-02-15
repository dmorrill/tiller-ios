//
//  AuthService.swift
//  TillerCompanion
//
//  Email/password authentication via Laravel Sanctum
//

import Foundation
import SwiftUI

@MainActor
class AuthService: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var hasSheet = false
    @Published var serviceAccountEmail: String?

    private let apiClient = APIClient.shared

    init() {
        // Restore token from Keychain
        if let token = KeychainService.getToken() {
            apiClient.setAuthToken(token)
            Task { await checkAuthStatus() }
        }
    }

    // MARK: - Check Auth Status
    func checkAuthStatus() async {
        guard apiClient.authToken != nil else {
            isAuthenticated = false
            return
        }

        do {
            let userInfo = try await apiClient.fetchUser()
            currentUser = userInfo.user
            hasSheet = userInfo.hasSheet
            serviceAccountEmail = userInfo.serviceAccountEmail
            isAuthenticated = true
        } catch {
            // Token invalid
            await signOut()
        }
    }

    // MARK: - Register
    func register(name: String, email: String, password: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let response = try await apiClient.register(name: name, email: email, password: password)
            KeychainService.saveToken(response.accessToken)
            apiClient.setAuthToken(response.accessToken)
            currentUser = response.user
            hasSheet = false
            isAuthenticated = true
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Login
    func login(email: String, password: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let response = try await apiClient.login(email: email, password: password)
            KeychainService.saveToken(response.accessToken)
            apiClient.setAuthToken(response.accessToken)
            currentUser = response.user
            // Fetch full user info to get hasSheet
            await checkAuthStatus()
        } catch let error as APIError {
            errorMessage = error.errorDescription
            isAuthenticated = false
        } catch {
            errorMessage = error.localizedDescription
            isAuthenticated = false
        }

        isLoading = false
    }

    // MARK: - Sign Out
    func signOut() async {
        do {
            try await apiClient.signOut()
        } catch {
            // Ignore server errors on logout
        }

        KeychainService.deleteToken()
        apiClient.setAuthToken(nil)
        currentUser = nil
        hasSheet = false
        isAuthenticated = false
    }

    // MARK: - Sheet Connected
    func markSheetConnected() {
        hasSheet = true
    }
}
