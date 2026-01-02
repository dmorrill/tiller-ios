//
//  AuthService.swift
//  TillerCompanion
//
//  Authentication service for Google OAuth
//

import Foundation
import AuthenticationServices
import SwiftUI

@MainActor
class AuthService: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let apiClient = APIClient.shared

    init() {
        // Check for existing auth token on init
        Task {
            await checkAuthStatus()
        }
    }

    // MARK: - Authentication Status
    func checkAuthStatus() async {
        // If we have a token, try to validate it
        guard apiClient.authToken != nil else {
            isAuthenticated = false
            currentUser = nil
            return
        }

        do {
            // Try to refresh the token
            let response = try await apiClient.refreshToken()
            apiClient.setAuthToken(response.token)
            currentUser = response.user
            isAuthenticated = true
        } catch {
            // Token is invalid, clear it
            print("Failed to refresh token: \(error)")
            await signOut()
        }
    }

    // MARK: - Sign In
    func signInWithGoogle() async {
        isLoading = true
        errorMessage = nil

        do {
            // In a real app, this would trigger the Google Sign-In SDK
            // For now, we'll simulate with a web-based flow

            // This would be replaced with actual Google Sign-In SDK code:
            // let signInResult = try await GIDSignIn.sharedInstance.signIn(...)
            // let authCode = signInResult.serverAuthCode

            // For testing, we'll need to implement the web OAuth flow
            // or wait until Google credentials are set up

            throw APIError.unknown // Placeholder until Google OAuth is configured
        } catch {
            errorMessage = error.localizedDescription
            isAuthenticated = false
        }

        isLoading = false
    }

    // MARK: - Sign In with Auth Code
    func signInWithAuthCode(_ authCode: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let response = try await apiClient.signInWithGoogle(authCode: authCode)
            apiClient.setAuthToken(response.token)
            currentUser = response.user
            isAuthenticated = true
        } catch {
            errorMessage = error.localizedDescription
            isAuthenticated = false
        }

        isLoading = false
    }

    // MARK: - Sign Out
    func signOut() async {
        isLoading = true

        do {
            try await apiClient.signOut()
        } catch {
            print("Sign out error: \(error)")
            // Even if sign out fails on server, clear local state
        }

        // Clear local state
        apiClient.setAuthToken(nil)
        currentUser = nil
        isAuthenticated = false
        isLoading = false
    }

    // MARK: - Web-based OAuth Flow (Temporary)
    func initiateWebOAuth() {
        // Open the Laravel backend OAuth URL in Safari
        // This is a temporary solution until we integrate Google Sign-In SDK
        if let url = URL(string: "\(APIConfig.baseURL)/auth/google") {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - ASWebAuthenticationSession Helper
extension AuthService {
    func authenticateWithWebSession() async {
        // This method uses ASWebAuthenticationSession for in-app OAuth
        let authURL = URL(string: "\(APIConfig.baseURL)/auth/google")!
        let callbackScheme = "tillercompanion" // This needs to be configured in your app

        let session = ASWebAuthenticationPresentationContextProvider()

        do {
            let webAuthSession = ASWebAuthenticationSession(
                url: authURL,
                callbackURLScheme: callbackScheme
            ) { callbackURL, error in
                guard error == nil,
                      let callbackURL = callbackURL,
                      let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false),
                      let token = components.queryItems?.first(where: { $0.name == "token" })?.value else {
                    self.errorMessage = error?.localizedDescription ?? "Authentication failed"
                    return
                }

                // Set the token and mark as authenticated
                self.apiClient.setAuthToken(token)
                Task {
                    await self.checkAuthStatus()
                }
            }

            webAuthSession.presentationContextProvider = session
            webAuthSession.prefersEphemeralWebBrowserSession = false

            webAuthSession.start()
        }
    }
}

// MARK: - Presentation Context Provider
class ASWebAuthenticationPresentationContextProvider: NSObject, ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            fatalError("No window found")
        }
        return window
    }
}