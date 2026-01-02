//
//  SyncManager.swift
//  TillerCompanion
//
//  Manages data synchronization with Google Sheets via Laravel backend
//

import Foundation
import SwiftUI

@MainActor
class SyncManager: ObservableObject {
    @Published var isSyncing = false
    @Published var lastSyncDate: Date?
    @Published var syncStatus: String = "Ready"
    @Published var syncProgress: Double = 0.0
    @Published var hasUnsyncedChanges = false
    @Published var syncError: String?

    // Cached data
    @Published var transactions: [Transaction] = []
    @Published var categories: [Category] = []
    @Published var sheets: [Sheet] = []
    @Published var currentSheet: Sheet?

    private let apiClient = APIClient.shared

    init() {
        // Load last sync date from UserDefaults
        if let savedDate = UserDefaults.standard.object(forKey: "lastSyncDate") as? Date {
            lastSyncDate = savedDate
        }

        // Load cached data
        loadCachedData()
    }

    // MARK: - Sync Operations
    func performSync() async {
        guard !isSyncing else { return }

        isSyncing = true
        syncStatus = "Syncing..."
        syncProgress = 0.0
        syncError = nil

        do {
            // Step 1: Fetch sheets
            syncStatus = "Fetching sheets..."
            syncProgress = 0.2
            sheets = try await apiClient.getSheets()

            // Set current sheet if not set
            if currentSheet == nil, let firstSheet = sheets.first {
                currentSheet = firstSheet
            }

            // Step 2: Fetch categories
            syncStatus = "Fetching categories..."
            syncProgress = 0.4
            categories = try await apiClient.getCategories()

            // Step 3: Fetch transactions
            if let sheetId = currentSheet?.id {
                syncStatus = "Fetching transactions..."
                syncProgress = 0.6
                transactions = try await apiClient.getTransactions(sheetId: sheetId)
            }

            // Step 4: Process any pending local changes
            syncStatus = "Uploading changes..."
            syncProgress = 0.8
            await uploadPendingChanges()

            // Step 5: Complete
            syncProgress = 1.0
            syncStatus = "Sync complete"
            lastSyncDate = Date()
            hasUnsyncedChanges = false

            // Save to cache
            saveCachedData()

            // Save sync date
            UserDefaults.standard.set(lastSyncDate, forKey: "lastSyncDate")

        } catch {
            syncError = error.localizedDescription
            syncStatus = "Sync failed"
            print("Sync error: \(error)")
        }

        // Reset after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.isSyncing = false
            if self.syncError == nil {
                self.syncStatus = "Ready"
            }
        }
    }

    // MARK: - Sheet Management
    func selectSheet(_ sheet: Sheet) {
        currentSheet = sheet
        UserDefaults.standard.set(sheet.id, forKey: "currentSheetId")

        // Trigger a sync for the new sheet
        Task {
            await performSync()
        }
    }

    func connectNewSheet(spreadsheetId: String) async throws {
        let newSheet = try await apiClient.connectSheet(spreadsheetId: spreadsheetId)
        sheets.append(newSheet)
        currentSheet = newSheet
        await performSync()
    }

    func disconnectSheet(_ sheet: Sheet) async throws {
        try await apiClient.disconnectSheet(id: sheet.id)
        sheets.removeAll { $0.id == sheet.id }

        if currentSheet?.id == sheet.id {
            currentSheet = sheets.first
        }
    }

    // MARK: - Transaction Management
    func updateTransaction(_ transaction: Transaction, category: String? = nil, note: String? = nil, tags: String? = nil) async throws {
        // Update locally first for immediate UI response
        if let index = transactions.firstIndex(where: { $0.id == transaction.id }) {
            var updatedTransaction = transaction

            // Create a mutable copy with updates
            let update = TransactionUpdate(
                category: category ?? transaction.category,
                note: note ?? transaction.note,
                tags: tags ?? transaction.tags
            )

            // Mark as pending sync
            markAsUnsynced()

            // Update on server
            let serverTransaction = try await apiClient.updateTransaction(id: transaction.id, updates: update)

            // Update local copy with server response
            transactions[index] = serverTransaction
        }
    }

    // MARK: - Category Management
    func createCategory(name: String, group: String? = nil) async throws {
        let newCategory = try await apiClient.createCategory(name: name, group: group)
        categories.append(newCategory)
        saveCachedData()
    }

    // MARK: - Local Change Tracking
    private func markAsUnsynced() {
        hasUnsyncedChanges = true
    }

    private func uploadPendingChanges() async {
        // This would handle uploading any local changes
        // For now, we're doing immediate sync to server
        // In a production app, you might batch changes
    }

    // MARK: - Caching
    private func loadCachedData() {
        // Load from UserDefaults or Core Data
        if let currentSheetId = UserDefaults.standard.string(forKey: "currentSheetId") {
            // In a real app, fetch from Core Data or cache
        }
    }

    private func saveCachedData() {
        // Save to UserDefaults or Core Data
        // This is a simplified implementation
        // In production, use Core Data for better performance
    }

    // MARK: - Auto-sync
    func startAutoSync(interval: TimeInterval = 300) { // 5 minutes default
        Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            Task {
                await self.performSync()
            }
        }
    }

    // MARK: - Utilities
    var syncStatusColor: Color {
        switch syncStatus {
        case "Ready":
            return .green
        case "Syncing...":
            return .blue
        case "Sync complete":
            return .green
        case "Sync failed":
            return .red
        default:
            return .gray
        }
    }

    var formattedLastSync: String {
        guard let lastSyncDate = lastSyncDate else {
            return "Never synced"
        }

        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: lastSyncDate, relativeTo: Date())
    }
}