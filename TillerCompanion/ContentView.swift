//
//  ContentView.swift
//  TillerCompanion
//
//  Created on 12/29/24.
//

import SwiftUI

struct ContentView: View {
    // MARK: - Properties
    @EnvironmentObject var authService: AuthService
    @State private var selectedTab = 0

    // MARK: - Body
    var body: some View {
        if authService.isAuthenticated {
            mainTabView
        } else {
            AuthenticationView()
        }
    }

    // MARK: - Views
    private var mainTabView: some View {
        TabView(selection: $selectedTab) {
            TransactionListView()
                .tabItem {
                    Label("Transactions", systemImage: "list.bullet.rectangle")
                }
                .tag(0)

            BudgetSnapshotView()
                .tabItem {
                    Label("Budget", systemImage: "chart.pie")
                }
                .tag(1)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(2)
        }
    }
}

// MARK: - Placeholder Views
struct AuthenticationView: View {
    @EnvironmentObject var authService: AuthService

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 16) {
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)

                Text("Tiller Companion")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Manage your Tiller spreadsheet on the go")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            VStack(spacing: 16) {
                Button {
                    // TODO: Implement Google Sign In
                    Task {
                        await signInWithGoogle()
                    }
                } label: {
                    HStack {
                        Image(systemName: "globe")
                        Text("Sign in with Google")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }

                Text("Your data stays in your Google Sheet")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 32)

            Spacer()
        }
    }

    private func signInWithGoogle() async {
        // This will trigger Google OAuth flow
        // Connected to Laravel backend
        authService.isAuthenticated = true // Temporary for testing
    }
}

struct BudgetSnapshotView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Account Balances
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Account Balances")
                            .font(.headline)
                            .padding(.horizontal)

                        VStack(spacing: 8) {
                            AccountBalanceRow(name: "Checking", balance: 5432.10)
                            AccountBalanceRow(name: "Savings", balance: 12500.00)
                            AccountBalanceRow(name: "Credit Card", balance: -1234.56)
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)

                    // Budget Status
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Budget Status")
                            .font(.headline)
                            .padding(.horizontal)

                        VStack(spacing: 8) {
                            BudgetCategoryRow(name: "Food & Dining", spent: 450, budget: 600)
                            BudgetCategoryRow(name: "Shopping", spent: 280, budget: 300)
                            BudgetCategoryRow(name: "Transportation", spent: 150, budget: 200)
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Budget Snapshot")
        }
    }
}

struct AccountBalanceRow: View {
    let name: String
    let balance: Double

    var body: some View {
        HStack {
            Text(name)
                .font(.subheadline)
            Spacer()
            Text(balance.formatted(.currency(code: "USD")))
                .font(.system(.subheadline, design: .rounded))
                .fontWeight(.medium)
                .foregroundColor(balance < 0 ? .red : .primary)
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(8)
    }
}

struct BudgetCategoryRow: View {
    let name: String
    let spent: Double
    let budget: Double

    private var percentage: Double {
        budget > 0 ? spent / budget : 0
    }

    private var color: Color {
        if percentage > 1.0 { return .red }
        if percentage > 0.8 { return .orange }
        return .green
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(name)
                    .font(.subheadline)
                Spacer()
                Text("\(spent.formatted(.currency(code: "USD"))) / \(budget.formatted(.currency(code: "USD")))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color(UIColor.systemGray5))
                        .frame(height: 8)
                        .cornerRadius(4)

                    Rectangle()
                        .fill(color)
                        .frame(width: min(geometry.size.width * percentage, geometry.size.width), height: 8)
                        .cornerRadius(4)
                }
            }
            .frame(height: 8)
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(8)
    }
}

struct SettingsView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var syncManager: SyncManager

    var body: some View {
        NavigationStack {
            Form {
                Section("Account") {
                    if let user = authService.currentUser {
                        Label(user.email, systemImage: "person.circle")
                    }

                    Button("Sign Out") {
                        authService.isAuthenticated = false
                        authService.currentUser = nil
                    }
                    .foregroundColor(.red)
                }

                Section("Sync") {
                    HStack {
                        Text("Last Sync")
                        Spacer()
                        if let date = syncManager.lastSyncDate {
                            Text(date.formatted(date: .abbreviated, time: .shortened))
                                .foregroundColor(.secondary)
                        } else {
                            Text("Never")
                                .foregroundColor(.secondary)
                        }
                    }

                    Button("Sync Now") {
                        Task {
                            await syncManager.performSync()
                        }
                    }
                }

                Section("Sheet Settings") {
                    NavigationLink("Select Sheet") {
                        Text("Sheet Selection View")
                    }

                    NavigationLink("Column Mapping") {
                        Text("Column Mapping View")
                    }
                }

                Section("About") {
                    Link("Documentation", destination: URL(string: "https://github.com/dmorrill/tiller-ios")!)
                    Link("Privacy Policy", destination: URL(string: "https://github.com/dmorrill/tiller-ios/blob/main/PRIVACY.md")!)
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AuthService())
            .environmentObject(SyncManager())
    }
}