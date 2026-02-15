//
//  TransactionListView.swift
//  TillerCompanion
//

import SwiftUI

struct TransactionListView: View {
    @EnvironmentObject var syncManager: SyncManager
    @State private var searchText = ""
    @State private var selectedFilter = TransactionFilter.all
    @State private var showingCategoryPicker = false
    @State private var selectedTransaction: Transaction?

    var filteredTransactions: [Transaction] {
        let base: [Transaction]
        switch selectedFilter {
        case .all:
            base = syncManager.transactions
        case .uncategorized:
            base = syncManager.transactions.filter { $0.category == nil }
        case .recent:
            let week = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
            base = syncManager.transactions.filter { $0.date > week }
        }
        if searchText.isEmpty { return base }
        return base.filter { $0.description.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                filterBar

                if syncManager.isSyncing && syncManager.transactions.isEmpty {
                    loadingView
                } else if syncManager.transactions.isEmpty {
                    emptyStateView
                } else {
                    transactionsList
                }
            }
            .navigationTitle("Transactions")
            .searchable(text: $searchText, prompt: "Search transactions")
            .refreshable {
                await syncManager.performSync()
            }
            .sheet(isPresented: $showingCategoryPicker) {
                if let transaction = selectedTransaction {
                    CategoryPickerView(transaction: transaction) { category in
                        Task {
                            try? await syncManager.updateTransaction(transaction, category: category)
                        }
                        showingCategoryPicker = false
                    }
                }
            }
            .task {
                if syncManager.transactions.isEmpty {
                    await syncManager.performSync()
                }
            }
        }
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(TransactionFilter.allCases, id: \.self) { filter in
                    FilterChip(title: filter.title, isSelected: selectedFilter == filter) {
                        selectedFilter = filter
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }

    private var transactionsList: some View {
        List {
            ForEach(filteredTransactions) { transaction in
                TransactionRowView(transaction: transaction)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button {
                            selectedTransaction = transaction
                            showingCategoryPicker = true
                        } label: {
                            Label("Categorize", systemImage: "tag")
                        }
                        .tint(.blue)
                    }
            }
        }
        .listStyle(.plain)
    }

    private var loadingView: some View {
        VStack { Spacer(); ProgressView("Loading transactions..."); Spacer() }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            Text("No transactions found")
                .font(.title2).fontWeight(.semibold)
            Text("Pull to refresh or adjust your filters")
                .font(.subheadline).foregroundColor(.secondary)
            Spacer()
        }
        .padding()
    }
}

// MARK: - Supporting Views
struct TransactionRowView: View {
    let transaction: Transaction

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.description)
                    .font(.headline).lineLimit(1)
                HStack {
                    Text(transaction.date.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption).foregroundColor(.secondary)
                    if let category = transaction.category {
                        Text("• \(category)")
                            .font(.caption).foregroundColor(.blue)
                    }
                }
            }
            Spacer()
            Text(transaction.displayAmount)
                .font(.system(.body, design: .rounded))
                .fontWeight(.medium)
                .foregroundColor(transaction.amount > 0 ? .green : .primary)
        }
        .padding(.vertical, 4)
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color.gray.opacity(0.2))
                .foregroundColor(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
    }
}

enum TransactionFilter: CaseIterable {
    case all, uncategorized, recent

    var title: String {
        switch self {
        case .all: return "All"
        case .uncategorized: return "Uncategorized"
        case .recent: return "Recent"
        }
    }
}
