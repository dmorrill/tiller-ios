# Tiller iOS - Claude Development Guidelines

This file contains project-specific guidelines for AI-assisted development on the Tiller iOS companion app.

## Project Context

**What we're building**: An open-source iOS companion app for Tiller that allows users to manage their financial spreadsheets on the go.

**Core principle**: Sheet-first, not app-first. The Google Sheet is always the source of truth.

## Critical Safety Rules

### Data Integrity is Paramount

1. **Never write code that could corrupt user spreadsheets**
   - Always validate column positions before writes
   - Never overwrite formula cells
   - Check for schema changes on every sync
   - Use immutable row IDs for updates

2. **Conservative by default**
   - When uncertain, read-only
   - Require explicit user action for any destructive operation
   - Log all write operations for debugging
   - Implement rollback capabilities where possible

3. **Test with production-like data**
   - Use realistic Tiller templates in tests
   - Test with sorted, filtered, and customized sheets
   - Verify behavior with formulas and pivot tables

## Architecture Guidelines

### iOS App Structure

```
TillerCompanion/
├── App/
│   ├── TillerCompanionApp.swift
│   └── Configuration/
├── Core/
│   ├── Models/
│   ├── Services/
│   └── Extensions/
├── Features/
│   ├── Transactions/
│   ├── Categories/
│   ├── Budgets/
│   └── Settings/
├── Shared/
│   ├── UI/
│   ├── Utils/
│   └── Resources/
└── Tests/
```

### Key Technical Decisions

1. **SwiftUI + Combine**
   - Use SwiftUI for all UI (iOS 16+ minimum)
   - Combine for reactive data flow
   - async/await for API calls

2. **Local Storage**
   - Core Data for transaction cache
   - UserDefaults for settings
   - Keychain for OAuth tokens

3. **Sheet Adapter Pattern**
   ```swift
   protocol SheetAdapter {
       func detectSchema() async throws -> SheetSchema
       func readTransactions() async throws -> [Transaction]
       func updateTransaction(_ transaction: Transaction) async throws
       func validateWritePermissions() async throws -> Bool
   }
   ```

## Development Workflow

### Before Starting Any Feature

1. **Understand the sheet impact**
   - What columns will be read?
   - What columns will be written?
   - How does this interact with formulas?

2. **Design for failure**
   - What if the network fails mid-write?
   - What if the schema changed?
   - What if the user lacks permissions?

3. **Consider template variations**
   - Foundation Template
   - Budget Template
   - Custom user modifications

### Code Standards

#### Swift Style
```swift
// GOOD: Clear, safe, defensive
func updateCategory(for transaction: Transaction, to category: Category) async throws {
    guard let rowId = transaction.mobileAppId else {
        throw SheetError.missingRowIdentifier
    }

    // Verify schema hasn't changed
    let currentSchema = try await adapter.detectSchema()
    guard currentSchema.version == cachedSchema.version else {
        throw SheetError.schemaChanged
    }

    try await adapter.updateField(
        rowId: rowId,
        column: currentSchema.categoryColumn,
        value: category.name
    )
}

// BAD: Assumptions and no error handling
func updateCategory(transaction: Transaction, category: String) {
    adapter.updateCell(row: transaction.row, column: "D", value: category)
}
```

#### Error Handling
- Use typed errors for sheet operations
- Provide user-actionable error messages
- Never fail silently on write operations
- Log errors with context for debugging

#### Testing Requirements
- Unit tests for all sheet operations
- Integration tests with mock Google Sheets API
- UI tests for critical paths (categorization, sync)
- Manual testing with real Tiller sheets before release

## Sheet Interaction Rules

### Safe Columns to Write
```swift
enum WritableColumn: String {
    case category = "Category"
    case note = "Note"
    case tags = "Tags"
    case mobileAppId = "__mobile_app_id"
}
```

### Detection Logic
1. Find sheet with "Transactions" in name
2. Look for Tiller signature columns:
   - Date, Description, Amount, Account
3. Map columns by header, not position
4. Cache mapping, but revalidate on each session

### Write-Back Protocol
1. Acquire row lock (optimistic)
2. Verify row still exists
3. Check column is writable
4. Perform atomic update
5. Verify write succeeded
6. Update local cache

## Open Source Considerations

### Documentation Requirements
Every PR must include:
- Update to README if user-facing
- Code comments for complex logic
- Test coverage for new features
- Schema assumptions documented

### Privacy First
- No analytics or tracking code
- No third-party SDKs without review
- Clear data flow documentation
- Explicit permission requests

### Community Friendly
- Clear error messages
- Helpful logging (but no PII)
- Extensible architecture
- Well-documented APIs

## Common Patterns

### Transaction List
```swift
// Always show sync state
enum SyncState {
    case idle
    case syncing
    case error(Error)
    case lastSynced(Date)
}

// Optimistic updates
func categorizeTransaction(_ transaction: Transaction, as category: Category) {
    // 1. Update UI immediately
    updateLocalTransaction(transaction, category: category)

    // 2. Queue for sync
    syncQueue.add(.categorize(transaction.id, category.id))

    // 3. Show sync indicator
    syncState = .syncing

    // 4. Handle success/failure
    Task {
        do {
            try await syncQueue.process()
            syncState = .lastSynced(Date())
        } catch {
            // Revert UI and show error
            revertLocalTransaction(transaction)
            syncState = .error(error)
        }
    }
}
```

### Sheet Detection
```swift
// Flexible detection with fallbacks
func detectTransactionSheet() async throws -> Sheet {
    // 1. Try cached sheet ID
    if let cachedId = UserDefaults.standard.string(forKey: "lastSheetId") {
        if let sheet = try? await validateSheet(id: cachedId) {
            return sheet
        }
    }

    // 2. Search by name patterns
    let candidates = try await findSheets(matching: ["Transactions", "Register", "Tiller"])

    // 3. Validate schema
    for candidate in candidates {
        if try await hasValidSchema(candidate) {
            return candidate
        }
    }

    // 4. Ask user to select
    throw SheetError.manualSelectionRequired
}
```

## Debugging & Logging

### Logging Levels
```swift
enum LogLevel {
    case verbose  // Development only
    case debug    // Sheet operations
    case info     // User actions
    case warning  // Recoverable issues
    case error    // Failures requiring user action
}
```

### What to Log
- ✅ Sheet operations (sans data)
- ✅ Sync timestamps
- ✅ Error conditions
- ✅ Schema detection results
- ❌ Transaction amounts
- ❌ Category names
- ❌ User credentials

## Release Checklist

Before any release:

1. **Test with real sheets**
   - [ ] Foundation Template
   - [ ] Budget Template
   - [ ] Customized sheet
   - [ ] Sheet with formulas
   - [ ] Sorted/filtered sheet

2. **Verify safety**
   - [ ] No formula overwrites
   - [ ] Row IDs persist
   - [ ] Sync conflicts handled
   - [ ] Network failures graceful
   - [ ] Schema changes detected

3. **Documentation**
   - [ ] README updated
   - [ ] CHANGELOG entry
   - [ ] Migration notes (if needed)
   - [ ] Column usage documented

## AI Assistant Notes

When working on this project:

1. **Always prioritize data safety** - It's better to fail than corrupt user data
2. **Think defensively** - Assume schemas will change, networks will fail, and users will customize everything
3. **Test with realistic data** - Don't just test happy paths
4. **Document assumptions** - Future contributors need to understand why decisions were made
5. **Keep it simple** - This is a companion app, not a full Tiller replacement

## Quick Commands

```bash
# Run tests
swift test

# Build for device
xcodebuild -scheme TillerCompanion -destination 'platform=iOS Simulator,name=iPhone 15'

# Check for unsafe patterns
grep -r "force unwrap\|try!" --include="*.swift" .

# Generate documentation
swift-doc generate Sources/ --module-name TillerCompanion

# Lint code
swiftlint
```

## Resources

- [Tiller API Documentation](https://api.tillerhq.com/docs)
- [Google Sheets API](https://developers.google.com/sheets/api)
- [Tiller Community Templates](https://community.tillerhq.com/c/templates)
- [iOS Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)

---

Remember: Users are trusting us with their financial data. Every line of code should respect that trust.