//
//  ConnectSheetView.swift
//  TillerCompanion
//
//  Onboarding view to connect a Tiller Google Sheet via service account sharing
//

import SwiftUI

struct ConnectSheetView: View {
    @EnvironmentObject var authService: AuthService
    @State private var serviceAccountEmail: String = ""
    @State private var sheetURL = ""
    @State private var isConnecting = false
    @State private var errorMessage: String?
    @State private var copied = false

    private let apiClient = APIClient.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Connect Your Tiller Sheet")
                            .font(.title)
                            .fontWeight(.bold)
                        Text("Follow the steps below to connect your Tiller spreadsheet.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    // Step 1
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Step 1: Share your spreadsheet", systemImage: "1.circle.fill")
                            .font(.headline)

                        Text("Open your Tiller spreadsheet in Google Sheets, click Share, and add this email as an Editor:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        HStack {
                            Text(serviceAccountEmail.isEmpty ? "Loading..." : serviceAccountEmail)
                                .font(.system(.caption, design: .monospaced))
                                .lineLimit(1)
                                .truncationMode(.middle)

                            Spacer()

                            Button {
                                UIPasteboard.general.string = serviceAccountEmail
                                copied = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) { copied = false }
                            } label: {
                                Image(systemName: copied ? "checkmark" : "doc.on.doc")
                                    .foregroundColor(copied ? .green : .blue)
                            }
                            .disabled(serviceAccountEmail.isEmpty)
                        }
                        .padding()
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(8)
                    }

                    // Step 2
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Step 2: Paste the spreadsheet URL", systemImage: "2.circle.fill")
                            .font(.headline)

                        TextField("https://docs.google.com/spreadsheets/d/...", text: $sheetURL)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.URL)
                            .autocapitalization(.none)

                        if let error = errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                        }

                        Button {
                            Task { await connectSheet() }
                        } label: {
                            if isConnecting {
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                                    .padding()
                            } else {
                                Text("Connect Sheet")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                            }
                        }
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .disabled(sheetURL.isEmpty || isConnecting)
                    }
                }
                .padding()
            }
            .navigationTitle("Setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Sign Out") {
                        Task { await authService.signOut() }
                    }
                    .font(.subheadline)
                }
            }
            .task {
                await loadServiceAccountEmail()
            }
        }
    }

    private func loadServiceAccountEmail() async {
        // Use cached value from auth if available
        if let email = authService.serviceAccountEmail {
            serviceAccountEmail = email
            return
        }
        do {
            let resp = try await apiClient.getServiceAccountEmail()
            serviceAccountEmail = resp.email
        } catch {
            serviceAccountEmail = "Error loading email"
        }
    }

    private func connectSheet() async {
        isConnecting = true
        errorMessage = nil

        do {
            _ = try await apiClient.connectSheet(url: sheetURL)
            authService.markSheetConnected()
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }

        isConnecting = false
    }
}
