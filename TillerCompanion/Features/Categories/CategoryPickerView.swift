//
//  CategoryPickerView.swift
//  TillerCompanion
//
//  Created on 12/29/24.
//

import SwiftUI

struct CategoryPickerView: View {
    // MARK: - Properties
    let transaction: Transaction
    let onSelect: (String) -> Void

    @StateObject private var viewModel = CategoriesViewModel()
    @State private var searchText = ""
    @Environment(\.dismiss) private var dismiss

    // MARK: - Body
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                transactionHeader

                if viewModel.isLoading {
                    ProgressView("Loading categories...")
                        .frame(maxHeight: .infinity)
                } else {
                    categoriesList
                }
            }
            .navigationTitle("Select Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search categories")
            .task {
                await viewModel.loadCategories()
            }
        }
    }

    // MARK: - Views
    private var transactionHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(transaction.description)
                .font(.headline)

            HStack {
                Text(transaction.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Spacer()

                Text(transaction.amount.formatted(.currency(code: "USD")))
                    .font(.system(.title3, design: .rounded))
                    .fontWeight(.semibold)
            }
        }
        .padding()
        .background(Color(UIColor.systemGray6))
    }

    private var categoriesList: some View {
        List {
            if !viewModel.recentCategories.isEmpty {
                Section("Recent") {
                    ForEach(viewModel.recentCategories, id: \.self) { category in
                        CategoryRow(name: category) {
                            onSelect(category)
                            dismiss()
                        }
                    }
                }
            }

            Section("All Categories") {
                ForEach(filteredCategories, id: \.self) { category in
                    CategoryRow(name: category) {
                        onSelect(category)
                        dismiss()
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
    }

    private var filteredCategories: [String] {
        if searchText.isEmpty {
            return viewModel.allCategories
        } else {
            return viewModel.allCategories.filter {
                $0.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
}

// MARK: - Category Row
struct CategoryRow: View {
    let name: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Label(name, systemImage: "folder")
                    .foregroundColor(.primary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - View Model
class CategoriesViewModel: ObservableObject {
    @Published var allCategories: [String] = []
    @Published var recentCategories: [String] = []
    @Published var isLoading = false

    func loadCategories() async {
        isLoading = true

        // TODO: Fetch from API
        // Simulated categories for now
        allCategories = [
            "Auto & Transport",
            "Bills & Utilities",
            "Business Services",
            "Education",
            "Entertainment",
            "Fees & Charges",
            "Food & Dining",
            "Gifts & Donations",
            "Health & Fitness",
            "Home",
            "Income",
            "Investments",
            "Kids",
            "Personal Care",
            "Pets",
            "Shopping",
            "Taxes",
            "Transfer",
            "Travel",
            "Uncategorized"
        ].sorted()

        recentCategories = ["Food & Dining", "Shopping", "Auto & Transport"]

        isLoading = false
    }
}