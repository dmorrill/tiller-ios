# Tiller iOS - Technical Implementation Plan

## Architecture Overview

We'll use a **Laravel API backend** + **iOS native app** architecture, similar to your other applications. The Laravel backend will handle Google Sheets API integration, while the iOS app provides the native UI.

```
┌─────────────────────┐
│   iOS App (Swift)   │
│      SwiftUI        │
└──────────┬──────────┘
           │ HTTPS/JSON
           │
┌──────────▼──────────┐
│   Laravel API       │
│   (tiller-api)      │
└──────────┬──────────┘
           │ Google API
           │
┌──────────▼──────────┐
│  Google Sheets      │
│  (User's Tiller)    │
└─────────────────────┘
```

## Phase 1: Laravel Backend Foundation (Week 1-2)

### 1.1 Laravel Project Setup

```bash
# Create new Laravel project
laravel new tiller-api
cd tiller-api

# Install required packages
composer require laravel/sanctum
composer require google/apiclient
composer require laravel/vapor-cli --dev
composer require laravel/horizon
```

### 1.2 Core Backend Structure

```
tiller-api/
├── app/
│   ├── Http/
│   │   ├── Controllers/
│   │   │   ├── AuthController.php
│   │   │   ├── SheetController.php
│   │   │   ├── TransactionController.php
│   │   │   └── CategoryController.php
│   │   └── Resources/
│   │       ├── TransactionResource.php
│   │       └── CategoryResource.php
│   ├── Models/
│   │   ├── User.php
│   │   ├── Sheet.php
│   │   └── SheetSchema.php
│   ├── Services/
│   │   ├── GoogleSheetsService.php
│   │   ├── SheetDetectionService.php
│   │   ├── SheetAdapterService.php
│   │   └── RowIdentityService.php
│   └── Jobs/
│       ├── SyncTransactions.php
│       └── ValidateSheetSchema.php
├── database/
│   └── migrations/
│       ├── create_users_table.php
│       ├── create_sheets_table.php
│       └── create_sheet_schemas_table.php
└── tests/
    ├── Feature/
    └── Unit/
```

### 1.3 Database Schema

```sql
-- users table
- id
- email
- google_id
- google_refresh_token (encrypted)
- settings (JSON)
- created_at
- updated_at

-- sheets table
- id
- user_id
- spreadsheet_id
- sheet_name
- sheet_type (transactions/categories/balances)
- last_synced_at
- schema_version
- created_at
- updated_at

-- sheet_schemas table
- id
- sheet_id
- columns (JSON - column mappings)
- detected_template
- has_mobile_id_column
- created_at
- updated_at
```

### 1.4 API Endpoints

```php
// Authentication
POST   /api/auth/google          // OAuth login with Google
POST   /api/auth/refresh         // Refresh token
POST   /api/auth/logout          // Logout

// Sheet Management
GET    /api/sheets               // List user's sheets
POST   /api/sheets/detect        // Auto-detect Tiller sheets
GET    /api/sheets/{id}          // Get sheet details
POST   /api/sheets/{id}/schema   // Update schema mapping
DELETE /api/sheets/{id}          // Remove sheet connection

// Transactions
GET    /api/transactions         // List transactions (paginated)
GET    /api/transactions/{id}    // Get single transaction
PATCH  /api/transactions/{id}    // Update transaction (category, note, tags)
POST   /api/transactions         // Create manual transaction

// Categories
GET    /api/categories           // List categories from sheet
POST   /api/categories/sync      // Sync categories from sheet

// Sync Operations
POST   /api/sync/transactions    // Trigger transaction sync
GET    /api/sync/status          // Get sync status
```

## Phase 2: Google Sheets Integration (Week 2-3)

### 2.1 Sheet Detection Service

```php
class SheetDetectionService
{
    public function detectTillerSheets($spreadsheetId)
    {
        // 1. Get all sheets in spreadsheet
        // 2. Look for Tiller signature columns
        // 3. Return candidate sheets with confidence scores
    }

    public function detectSchema($sheet)
    {
        // Map header names to column positions
        // Identify writable vs formula columns
        // Detect template type (Foundation, Budget, etc)
    }

    public function validateWritePermissions($sheet, $columns)
    {
        // Ensure columns are writable
        // Check for formulas
        // Verify column types
    }
}
```

### 2.2 Row Identity Management

```php
class RowIdentityService
{
    const MOBILE_ID_COLUMN = '__mobile_app_id';

    public function ensureIdentityColumn($sheet)
    {
        // Check if ID column exists
        // If not, add it (with user permission)
        // Populate existing rows with UUIDs
    }

    public function findRowById($sheet, $mobileId)
    {
        // Locate row by mobile ID
        // Handle missing IDs gracefully
    }

    public function generateCompositeKey($transaction)
    {
        // Fallback: Account + Date + Amount + Description
        // Used when ID column not available
    }
}
```

### 2.3 Safe Write Operations

```php
class SheetAdapterService
{
    public function updateTransaction($transaction, $updates)
    {
        // Validate schema hasn't changed
        // Lock row (optimistic)
        // Update only safe columns
        // Verify write succeeded
        // Return updated data
    }

    private function safeColumns()
    {
        return ['Category', 'Note', 'Tags'];
    }
}
```

## Phase 3: iOS App Foundation (Week 3-4)

### 3.1 iOS Project Structure

```
TillerCompanion/
├── App/
│   ├── TillerCompanionApp.swift
│   ├── AppDelegate.swift
│   └── Configuration/
│       ├── Config.plist
│       └── Environment.swift
├── Core/
│   ├── Models/
│   │   ├── Transaction.swift
│   │   ├── Category.swift
│   │   ├── Sheet.swift
│   │   └── User.swift
│   ├── Services/
│   │   ├── APIClient.swift
│   │   ├── AuthService.swift
│   │   ├── TransactionService.swift
│   │   └── SyncManager.swift
│   ├── Storage/
│   │   ├── CoreDataStack.swift
│   │   └── KeychainService.swift
│   └── Extensions/
│       ├── Date+Extensions.swift
│       └── Currency+Extensions.swift
├── Features/
│   ├── Auth/
│   │   ├── GoogleSignInView.swift
│   │   └── AuthViewModel.swift
│   ├── Transactions/
│   │   ├── TransactionListView.swift
│   │   ├── TransactionDetailView.swift
│   │   ├── TransactionRowView.swift
│   │   └── TransactionsViewModel.swift
│   ├── Categories/
│   │   ├── CategoryPickerView.swift
│   │   └── CategoriesViewModel.swift
│   └── Settings/
│       ├── SettingsView.swift
│       └── SheetSelectionView.swift
└── Shared/
    ├── UI/
    │   ├── LoadingView.swift
    │   ├── ErrorView.swift
    │   └── SyncIndicator.swift
    └── Utils/
        ├── NetworkMonitor.swift
        └── Logger.swift
```

### 3.2 Core iOS Components

```swift
// API Client
class APIClient {
    private let baseURL = "https://api.tiller-companion.app"
    private let session = URLSession.shared

    func request<T: Codable>(_ endpoint: Endpoint) async throws -> T
    func authenticatedRequest<T: Codable>(_ endpoint: Endpoint) async throws -> T
}

// Transaction Service
class TransactionService: ObservableObject {
    @Published var transactions: [Transaction] = []
    @Published var syncState: SyncState = .idle

    func loadTransactions() async
    func updateTransaction(_ transaction: Transaction) async throws
    func syncWithSheet() async throws
}

// Sync Manager
class SyncManager {
    func performIncrementalSync() async
    func handleOfflineChanges() async
    func resolveConflicts(_ conflicts: [SyncConflict]) async
}
```

### 3.3 SwiftUI Views

```swift
// Main Transaction List
struct TransactionListView: View {
    @StateObject private var viewModel = TransactionsViewModel()
    @State private var filter = TransactionFilter.uncategorized

    var body: some View {
        List {
            ForEach(viewModel.filteredTransactions) { transaction in
                TransactionRowView(transaction: transaction)
                    .swipeActions {
                        Button("Categorize") {
                            viewModel.showCategoryPicker(for: transaction)
                        }
                    }
            }
        }
        .refreshable {
            await viewModel.sync()
        }
    }
}
```

## Phase 4: Core Features Implementation (Week 4-6)

### 4.1 Transaction Management

**Priority 1: View & Filter**
- [ ] Display transaction list
- [ ] Filter by uncategorized
- [ ] Search transactions
- [ ] Sort options

**Priority 2: Categorization**
- [ ] Quick category assignment
- [ ] Category picker with search
- [ ] Bulk categorization
- [ ] Recent categories

**Priority 3: Details**
- [ ] Add/edit notes
- [ ] Manage tags
- [ ] View account details
- [ ] Transaction history

### 4.2 Sync Engine

```php
// Laravel Job
class SyncTransactions implements ShouldQueue
{
    public function handle()
    {
        // 1. Fetch latest from sheet
        // 2. Compare with cached data
        // 3. Identify changes
        // 4. Update local cache
        // 5. Send push notification if needed
    }
}
```

```swift
// iOS Sync
class SyncEngine {
    func sync() async throws {
        // 1. Send pending local changes
        // 2. Fetch remote updates
        // 3. Merge changes
        // 4. Update UI
        // 5. Handle conflicts
    }
}
```

### 4.3 Offline Support

```swift
// Core Data Models
@Model
class TransactionEntity {
    @Attribute var transactionId: String
    @Attribute var amount: Decimal
    @Attribute var date: Date
    @Attribute var description: String
    @Attribute var category: String?
    @Attribute var note: String?
    @Attribute var tags: String?
    @Attribute var pendingChanges: Data?
    @Attribute var lastSynced: Date
}

// Offline Queue
class OfflineQueue {
    func enqueue(_ operation: SyncOperation)
    func processPendingOperations() async
    func handleNetworkReconnection()
}
```

## Phase 5: Safety & Testing (Week 6-7)

### 5.1 Testing Strategy

**Laravel Backend Tests**
```php
// Feature Tests
- Test Google OAuth flow
- Test sheet detection with various templates
- Test transaction updates
- Test schema change handling
- Test concurrent updates

// Unit Tests
- Test row identity generation
- Test column mapping
- Test safe write validation
- Test formula detection
```

**iOS App Tests**
```swift
// Unit Tests
- Test data models
- Test sync logic
- Test offline queue
- Test conflict resolution

// UI Tests
- Test transaction categorization flow
- Test offline mode
- Test sync indicators
- Test error states
```

### 5.2 Safety Validations

```php
class SafetyValidator
{
    public function beforeWrite($sheet, $column, $value)
    {
        $this->ensureNoFormula($sheet, $column);
        $this->ensureColumnExists($sheet, $column);
        $this->ensureCorrectType($column, $value);
        $this->ensureNoDataLoss($sheet, $column, $value);
    }
}
```

## Phase 6: Beta Release (Week 7-8)

### 6.1 TestFlight Setup
- [ ] App Store Connect configuration
- [ ] TestFlight build upload
- [ ] Beta tester recruitment
- [ ] Feedback collection system

### 6.2 Monitoring & Analytics

```php
// Laravel monitoring
- Laravel Horizon for queues
- Laravel Telescope for debugging
- Sentry for error tracking
- Custom metrics for sheet operations
```

```swift
// iOS monitoring
- Crash reporting (Sentry)
- Performance monitoring
- Sync success rates
- User flow analytics (privacy-friendly)
```

### 6.3 Production Infrastructure

```yaml
# Laravel Vapor Configuration
environments:
  production:
    memory: 1024
    cli-memory: 512
    runtime: 'php-8.2:al2'
    database: tiller-db
    cache: tiller-cache
    queue-timeout: 90

# Required Services
- Redis for caching/queues
- PostgreSQL for data
- S3 for temporary storage
- CloudWatch for monitoring
```

## Implementation Milestones

### Milestone 1: Authentication & Sheet Detection (Week 1-2)
- [ ] Laravel backend with Google OAuth
- [ ] Sheet detection algorithm
- [ ] Basic iOS app with login
- [ ] Sheet selection UI

### Milestone 2: Read-Only Transactions (Week 3-4)
- [ ] Fetch transactions from sheet
- [ ] Display in iOS app
- [ ] Filtering and search
- [ ] Category list from sheet

### Milestone 3: Safe Write Operations (Week 5-6)
- [ ] Update category in sheet
- [ ] Add notes and tags
- [ ] Row identity system
- [ ] Conflict resolution

### Milestone 4: Beta Release (Week 7-8)
- [ ] TestFlight deployment
- [ ] User onboarding flow
- [ ] Error handling and recovery
- [ ] Performance optimization

### Milestone 5: Public Launch (Week 9-10)
- [ ] App Store submission
- [ ] Production deployment
- [ ] Documentation site
- [ ] Community setup

## Risk Mitigation

### Technical Risks

1. **Google Sheets API Rate Limits**
   - Mitigation: Implement caching, batch operations, exponential backoff

2. **Schema Changes**
   - Mitigation: Version schemas, detect changes, graceful degradation

3. **Data Corruption**
   - Mitigation: Comprehensive testing, row locks, audit logs

4. **Network Failures**
   - Mitigation: Offline queue, retry logic, clear sync states

### Security Considerations

1. **OAuth Token Storage**
   - iOS: Keychain Services
   - Laravel: Encrypted in database

2. **API Security**
   - Laravel Sanctum for API tokens
   - Rate limiting per user
   - Request signing for critical operations

3. **Data Privacy**
   - No analytics on financial data
   - Minimal data retention
   - Clear audit logs

## Development Environment Setup

### Backend (Laravel)

```bash
# Clone and setup
git clone github.com:dmorrill/tiller-api.git
cd tiller-api
composer install
cp .env.example .env
php artisan key:generate

# Configure .env
GOOGLE_CLIENT_ID=xxx
GOOGLE_CLIENT_SECRET=xxx
GOOGLE_REDIRECT_URI=xxx

# Database
php artisan migrate
php artisan db:seed

# Start development
php artisan serve
php artisan horizon
```

### iOS (Xcode)

```bash
# Clone and setup
git clone github.com:dmorrill/tiller-ios.git
cd tiller-ios
pod install

# Configure Config.plist
API_BASE_URL=http://localhost:8000
GOOGLE_CLIENT_ID=xxx

# Open in Xcode
open TillerCompanion.xcworkspace
```

## Success Metrics

### Technical Metrics
- API response time < 200ms (p95)
- Sync success rate > 99%
- Zero data corruption incidents
- App crash rate < 0.1%

### User Metrics
- Daily active users categorizing transactions
- Average time to categorize < 5 seconds
- User retention after 30 days
- TestFlight feedback score > 4.5

## Next Steps

1. **Immediate Actions**
   - Set up Laravel API repository
   - Create Google Cloud project for Sheets API
   - Initialize iOS project with SwiftUI
   - Set up CI/CD pipelines

2. **Week 1 Goals**
   - Complete Laravel backend setup
   - Implement Google OAuth
   - Create basic iOS app structure
   - Test sheet detection logic

3. **Communication**
   - Weekly progress updates
   - Beta tester recruitment post
   - Documentation as we build

---

This plan provides a solid foundation using Laravel (matching your existing stack) while maintaining the core principles of being sheet-first, safe, and transparent.