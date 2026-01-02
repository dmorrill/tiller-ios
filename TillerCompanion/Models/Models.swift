//
//  Models.swift
//  TillerCompanion
//
//  Data models for the Tiller Companion app
//

import Foundation

// MARK: - User Model
struct User: Codable, Identifiable {
    let id: String
    let email: String
    let name: String?
    let googleId: String?
    let avatar: String?
    let settings: UserSettings?

    private enum CodingKeys: String, CodingKey {
        case id
        case email
        case name
        case googleId = "google_id"
        case avatar
        case settings
    }
}

struct UserSettings: Codable {
    let defaultSheetId: String?
    let autoSync: Bool
    let syncInterval: Int // in minutes

    private enum CodingKeys: String, CodingKey {
        case defaultSheetId = "default_sheet_id"
        case autoSync = "auto_sync"
        case syncInterval = "sync_interval"
    }
}

// MARK: - Sheet Model
struct Sheet: Codable, Identifiable {
    let id: String
    let userId: String
    let spreadsheetId: String
    let name: String
    let detectedTemplate: SheetTemplate?
    let confidence: Double
    let isConnected: Bool
    let lastSyncAt: Date?
    let schema: SheetSchema?

    private enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case spreadsheetId = "spreadsheet_id"
        case name
        case detectedTemplate = "detected_template"
        case confidence
        case isConnected = "is_connected"
        case lastSyncAt = "last_sync_at"
        case schema
    }
}

enum SheetTemplate: String, Codable, CaseIterable {
    case foundation = "foundation"
    case monthlyBudget = "monthly_budget"
    case yearlyBudget = "yearly_budget"
    case businessDashboard = "business_dashboard"
    case unknown = "unknown"

    var displayName: String {
        switch self {
        case .foundation:
            return "Foundation Template"
        case .monthlyBudget:
            return "Monthly Budget"
        case .yearlyBudget:
            return "Yearly Budget"
        case .businessDashboard:
            return "Business Dashboard"
        case .unknown:
            return "Custom Sheet"
        }
    }

    var description: String {
        switch self {
        case .foundation:
            return "Basic transaction tracking and categorization"
        case .monthlyBudget:
            return "Monthly budget planning and tracking"
        case .yearlyBudget:
            return "Annual budget planning with monthly breakdowns"
        case .businessDashboard:
            return "Business income and expense tracking"
        case .unknown:
            return "Custom or unrecognized sheet structure"
        }
    }
}

// MARK: - Sheet Schema
struct SheetSchema: Codable {
    let columns: [ColumnMapping]
    let hasMobileIdColumn: Bool

    private enum CodingKeys: String, CodingKey {
        case columns
        case hasMobileIdColumn = "has_mobile_id_column"
    }
}

struct ColumnMapping: Codable {
    let index: Int
    let name: String
    let type: ColumnType
    let isEditable: Bool

    private enum CodingKeys: String, CodingKey {
        case index
        case name
        case type
        case isEditable = "is_editable"
    }
}

enum ColumnType: String, Codable {
    case date
    case description
    case amount
    case account
    case category
    case note
    case tags
    case mobileId = "mobile_id"
    case other
}

// MARK: - Transaction Model
struct Transaction: Codable, Identifiable {
    let id: String
    let date: Date
    let description: String
    let amount: Double
    let account: String
    let category: String?
    let note: String?
    let tags: String?
    let mobileAppId: String?
    let rowNumber: Int?
    let isPending: Bool
    let syncStatus: SyncStatus

    private enum CodingKeys: String, CodingKey {
        case id
        case date
        case description
        case amount
        case account
        case category
        case note
        case tags
        case mobileAppId = "mobile_app_id"
        case rowNumber = "row_number"
        case isPending = "is_pending"
        case syncStatus = "sync_status"
    }

    // Computed properties
    var isIncome: Bool {
        amount > 0
    }

    var displayAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: abs(amount))) ?? "$0.00"
    }

    var displayDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

enum SyncStatus: String, Codable {
    case synced
    case pending
    case conflict
    case error
}

// MARK: - Category Model
struct Category: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let group: String?
    let type: CategoryType
    let isCustom: Bool
    let color: String?
    let icon: String?
    let budgetAmount: Double?

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case group
        case type
        case isCustom = "is_custom"
        case color
        case icon
        case budgetAmount = "budget_amount"
    }

    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Category, rhs: Category) -> Bool {
        lhs.id == rhs.id
    }
}

enum CategoryType: String, Codable {
    case income
    case expense
    case transfer
    case hidden
}

// MARK: - Budget Model
struct Budget: Codable, Identifiable {
    let id: String
    let categoryId: String
    let amount: Double
    let period: BudgetPeriod
    let startDate: Date
    let endDate: Date?

    private enum CodingKeys: String, CodingKey {
        case id
        case categoryId = "category_id"
        case amount
        case period
        case startDate = "start_date"
        case endDate = "end_date"
    }
}

enum BudgetPeriod: String, Codable {
    case monthly
    case quarterly
    case yearly
    case custom
}

// MARK: - Account Model
struct Account: Codable, Identifiable {
    let id: String
    let name: String
    let type: AccountType
    let balance: Double?
    let lastUpdated: Date?
    let institution: String?
    let isActive: Bool

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case type
        case balance
        case lastUpdated = "last_updated"
        case institution
        case isActive = "is_active"
    }
}

enum AccountType: String, Codable {
    case checking
    case savings
    case creditCard = "credit_card"
    case loan
    case investment
    case other
}

// MARK: - Sync Models
struct SyncOperation: Codable {
    let id: String
    let type: SyncType
    let status: SyncOperationStatus
    let startedAt: Date
    let completedAt: Date?
    let recordsProcessed: Int
    let errors: [SyncError]?

    private enum CodingKeys: String, CodingKey {
        case id
        case type
        case status
        case startedAt = "started_at"
        case completedAt = "completed_at"
        case recordsProcessed = "records_processed"
        case errors
    }
}

enum SyncType: String, Codable {
    case full
    case incremental
    case manual
}

enum SyncOperationStatus: String, Codable {
    case pending
    case inProgress = "in_progress"
    case completed
    case failed
}

struct SyncError: Codable {
    let code: String
    let message: String
    let details: String?
}

// MARK: - Helper Extensions
extension Transaction {
    static var sample: Transaction {
        Transaction(
            id: "1",
            date: Date(),
            description: "Sample Transaction",
            amount: -25.99,
            account: "Checking",
            category: "Food & Dining",
            note: nil,
            tags: nil,
            mobileAppId: nil,
            rowNumber: 1,
            isPending: false,
            syncStatus: .synced
        )
    }
}

extension Category {
    static var sampleCategories: [Category] {
        [
            Category(id: "1", name: "Food & Dining", group: "Daily Living", type: .expense, isCustom: false, color: "#FF6B6B", icon: "fork.knife", budgetAmount: 600),
            Category(id: "2", name: "Transportation", group: "Daily Living", type: .expense, isCustom: false, color: "#4ECDC4", icon: "car", budgetAmount: 200),
            Category(id: "3", name: "Shopping", group: "Lifestyle", type: .expense, isCustom: false, color: "#45B7D1", icon: "cart", budgetAmount: 300),
            Category(id: "4", name: "Salary", group: "Income", type: .income, isCustom: false, color: "#95E77E", icon: "briefcase", budgetAmount: nil)
        ]
    }
}