//
//  TransactionListView.swift
//  TillerCompanion
//
//  Created on 12/29/24.
//

import SwiftUI

struct TransactionListView: View {
    // MARK: - Properties
    @EnvironmentObject var syncManager: SyncManager
    @StateObject private var viewModel = TransactionsViewModel()
    @State private var searchText = ""
    @State private var selectedFilter = TransactionFilter.uncategorized
    @State private var showingCategoryPicker = false
    @State private var selectedTransaction: Transaction?

    // MARK: - Body
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                filterBar

                if viewModel.isLoading {
                    loadingView
                } else if viewModel.transactions.isEmpty {
                    emptyStateView
                } else {
                    transactionsList
                }
            }
            .navigationTitle("Transactions")
            .searchable(text: $searchText, prompt: "Search transactions")
            .refreshable {
                await viewModel.refreshTransactions()
            }
            .sheet(isPresented: $showingCategoryPicker) {
                if let transaction = selectedTransaction {
                    CategoryPickerView(transaction: transaction) { category in
                        Task {
                            await viewModel.categorizeTransaction(transaction, category: category)
                        }
                        showingCategoryPicker = false
                    }
                }
            }
        }
    }

    // MARK: - Views
    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(TransactionFilter.allCases, id: \.self) { filter in
                    FilterChip(
                        title: filter.title,
                        isSelected: selectedFilter == filter
                    ) {
                        selectedFilter = filter
                        viewModel.applyFilter(filter)
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }

    private var transactionsList: some View {
        List {
            ForEach(viewModel.filteredTransactions) { transaction in
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
        .listStyle(PlainListStyle())
    }

    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView("Loading transactions...")
                .progressViewStyle(CircularProgressViewStyle())
            Spacer()
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            Text("No transactions found")
                .font(.title2)
                .fontWeight(.semibold)
            Text("Pull to refresh or adjust your filters")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
        }
        .padding()
    }
}

// MARK: - Transaction Row View
struct TransactionRowView: View {
    let transaction: Transaction

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.description)
                    .font(.headline)
                    .lineLimit(1)

                HStack {
                    Text(transaction.date.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if let category = transaction.category {
                        Text("• \(category)")
                            .font(.caption)
                            .foregroundColor(.blue)
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

// MARK: - Filter Chip
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

// MARK: - View Model
@MainActor
class TransactionsViewModel: ObservableObject {
    @Published var transactions: [Transaction] = []
    @Published var filteredTransactions: [Transaction] = []
    @Published var isLoading = false
    @Published var error: Error?

    private let syncManager: SyncManager

    init(syncManager: SyncManager = SyncManager()) {
        self.syncManager = syncManager
        loadTransactions()
    }

    func loadTransactions() {
        self.transactions = syncManager.transactions
        applyFilter(.all)
    }

    func refreshTransactions() async {
        isLoading = true
        await syncManager.performSync()
        loadTransactions()
        isLoading = false
    }

    func applyFilter(_ filter: TransactionFilter) {
        switch filter {
        case .all:
            filteredTransactions = transactions
        case .uncategorized:
            filteredTransactions = transactions.filter { $0.category == nil }
        case .recent:
            let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
            filteredTransactions = transactions.filter { $0.date > sevenDaysAgo }
        }
    }

    func categorizeTransaction(_ transaction: Transaction, category: String) async {
        do {
            try await syncManager.updateTransaction(transaction, category: category)
            loadTransactions()
        } catch {
            self.error = error
            print("Error categorizing transaction: \(error)")
        }
    }
}

enum TransactionFilter: CaseIterable {
    case all
    case uncategorized
    case recent

    var title: String {
        switch self {
        case .all: return "All"
        case .uncategorized: return "Uncategorized"
        case .recent: return "Recent"
        }
    }
}