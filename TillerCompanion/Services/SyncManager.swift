//
//  SyncManager.swift
//  TillerCompanion
//
//  Manages data synchronization with backend
//

import Foundation
import SwiftUI

@MainActor
class SyncManager: ObservableObject {
    @Published var isSyncing = false
    @Published var lastSyncDate: Date?
    @Published var syncStatus: String = "Ready"
    @Published var syncProgress: Double = 0.0
    @Published var syncError: String?

    @Published var transactions: [Transaction] = []
    @Published var sheets: [SheetData] = []
    @Published var currentSheet: SheetData?

    private let apiClient = APIClient.shared

    init() {
        if let savedDate = UserDefaults.standard.object(forKey: "lastSyncDate") as? Date {
            lastSyncDate = savedDate
        }
    }

    func performSync() async {
        guard !isSyncing else { return }

        isSyncing = true
        syncStatus = "Syncing..."
        syncProgress = 0.0
        syncError = nil

        do {
            syncStatus = "Fetching sheets..."
            syncProgress = 0.2
            sheets = try await apiClient.getSheets()

            if currentSheet == nil, let first = sheets.first {
                currentSheet = first
            }

            syncStatus = "Fetching transactions..."
            syncProgress = 0.6
            if let sheetId = currentSheet?.stringId {
                transactions = try await apiClient.getTransactions(sheetId: sheetId)
            }

            syncProgress = 1.0
            syncStatus = "Sync complete"
            lastSyncDate = Date()
            UserDefaults.standard.set(lastSyncDate, forKey: "lastSyncDate")

        } catch {
            syncError = error.localizedDescription
            syncStatus = "Sync failed"
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.isSyncing = false
            if self.syncError == nil {
                self.syncStatus = "Ready"
            }
        }
    }

    func updateTransaction(_ transaction: Transaction, category: String? = nil, note: String? = nil, tags: String? = nil) async throws {
        if let index = transactions.firstIndex(where: { $0.id == transaction.id }) {
            let update = TransactionUpdate(
                category: category ?? transaction.category,
                note: note ?? transaction.note,
                tags: tags ?? transaction.tags
            )
            let updated = try await apiClient.updateTransaction(id: transaction.id, updates: update)
            transactions[index] = updated
        }
    }

    var formattedLastSync: String {
        guard let lastSyncDate = lastSyncDate else { return "Never synced" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: lastSyncDate, relativeTo: Date())
    }
}
