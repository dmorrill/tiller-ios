//
//  ContentView.swift
//  TillerCompanion
//
//  Created on 12/29/24.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authService: AuthService
    @State private var selectedTab = 0

    var body: some View {
        Group {
            if !authService.isAuthenticated {
                LoginView()
            } else if !authService.hasSheet {
                ConnectSheetView()
            } else {
                mainTabView
            }
        }
    }

    private var mainTabView: some View {
        TabView(selection: $selectedTab) {
            TransactionListView()
                .tabItem {
                    Label("Transactions", systemImage: "list.bullet.rectangle")
                }
                .tag(0)
                .accessibilityLabel(A11yLabels.transactions)

            BudgetSnapshotView()
                .tabItem {
                    Label("Budget", systemImage: "chart.pie")
                }
                .tag(1)
                .accessibilityLabel(A11yLabels.budget)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(2)
                .accessibilityLabel(A11yLabels.settings)
        }
    }
}

// MARK: - Budget Snapshot (placeholder)
struct BudgetSnapshotView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
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
            .refreshable {
                // TODO: Refresh budget data from sync manager
                try? await Task.sleep(nanoseconds: 500_000_000)
            }
        }
    }
}

struct AccountBalanceRow: View {
    let name: String
    let balance: Double

    var body: some View {
        HStack {
            Text(name).font(.subheadline)
            Spacer()
            Text(balance.formatted(.currency(code: "USD")))
                .font(.system(.subheadline, design: .rounded))
                .fontWeight(.medium)
                .foregroundColor(balance < 0 ? .red : .primary)
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(8)
        .accessibilityLabel(A11yLabels.balance(balance.formatted(.currency(code: "USD")), account: name))
    }
}

struct BudgetCategoryRow: View {
    let name: String
    let spent: Double
    let budget: Double

    private var percentage: Double { budget > 0 ? spent / budget : 0 }
    private var color: Color {
        percentage > 1.0 ? .red : percentage > 0.8 ? .orange : .green
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(name).font(.subheadline)
                Spacer()
                Text("\(spent.formatted(.currency(code: "USD"))) / \(budget.formatted(.currency(code: "USD")))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle().fill(Color(UIColor.systemGray5)).frame(height: 8).cornerRadius(4)
                    Rectangle().fill(color)
                        .frame(width: min(geo.size.width * percentage, geo.size.width), height: 8)
                        .cornerRadius(4)
                }
            }
            .frame(height: 8)
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(8)
        .accessibilityLabel(A11yLabels.budgetProgress(name, spent: spent.formatted(.currency(code: "USD")), budget: budget.formatted(.currency(code: "USD"))))
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
                        Task { await authService.signOut() }
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
                            Text("Never").foregroundColor(.secondary)
                        }
                    }
                    Button("Sync Now") {
                        Task { await syncManager.performSync() }
                    }
                }

                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0").foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AuthService())
            .environmentObject(SyncManager())
    }
}
