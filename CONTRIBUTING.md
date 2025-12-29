# Contributing to Tiller iOS

First off, thank you for considering contributing to Tiller iOS! This open-source project exists because of contributors like you who help make financial data management more accessible and user-friendly.

## Code of Conduct

By participating in this project, you agree to abide by our Code of Conduct:

- **Be respectful**: We're all here to help each other
- **Be patient**: Remember that people contribute in their spare time
- **Be constructive**: Focus on improving the project
- **Be mindful**: Your code handles sensitive financial data

## How Can I Contribute?

### 🐛 Reporting Bugs

Before creating a bug report, please check existing issues to avoid duplicates.

**To report a bug:**
1. Use the issue template
2. Include iOS version and device model
3. Describe steps to reproduce
4. Include screenshots if applicable
5. **Never include real financial data in reports**

### 💡 Suggesting Features

We love feature ideas! When suggesting features, consider:

- Does it align with the "sheet-first" philosophy?
- Would it require writing to new spreadsheet columns?
- Is it something most users would benefit from?
- Could it potentially corrupt user data?

Create a feature request issue with:
- Clear use case
- Expected behavior
- Mockups/sketches (if applicable)
- Impact on existing sheets

### 📝 Improving Documentation

Documentation improvements are always welcome:
- Fix typos or clarify confusing sections
- Add examples
- Translate documentation
- Improve code comments

### 🔧 Contributing Code

Ready to code? Here's how to get started:

## Development Setup

### Prerequisites

- macOS 13+ with Xcode 15+
- iOS device or simulator running iOS 16+
- Google Cloud Console account (for Sheets API)
- CocoaPods or Swift Package Manager
- SwiftLint for code style

### Getting Started

1. **Fork the repository**
   ```bash
   git clone https://github.com/YOUR-USERNAME/tiller-ios.git
   cd tiller-ios
   ```

2. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Set up development environment**
   ```bash
   # Install dependencies
   pod install

   # Open in Xcode
   open TillerCompanion.xcworkspace
   ```

4. **Configure API keys**
   - Copy `Config.example.plist` to `Config.plist`
   - Add your Google Sheets API credentials
   - Never commit `Config.plist`

### Development Workflow

1. **Before starting work:**
   - Check existing issues and PRs
   - Comment on the issue you'll work on
   - Wait for feedback on significant changes

2. **While developing:**
   - Follow Swift style guide (enforced by SwiftLint)
   - Write unit tests for new functionality
   - Test with real Tiller sheets (safely!)
   - Update documentation as needed

3. **Testing checklist:**
   - [ ] Works with Foundation Template
   - [ ] Works with Budget Template
   - [ ] Handles missing columns gracefully
   - [ ] Doesn't overwrite formulas
   - [ ] Network failures handled
   - [ ] No memory leaks

## Code Guidelines

### Safety First

**Every PR must follow these safety rules:**

```swift
// ✅ GOOD: Defensive and safe
func updateTransaction(_ transaction: Transaction) async throws {
    // Verify we have permission
    guard hasWritePermission else {
        throw SheetError.insufficientPermissions
    }

    // Verify the column exists and is writable
    guard let column = schema.columns["Category"],
          column.isWritable else {
        throw SheetError.columnNotWritable
    }

    // Perform the update with error handling
    do {
        try await sheetAdapter.update(transaction)
    } catch {
        // Log error without exposing user data
        logger.error("Update failed for transaction: \(transaction.id)")
        throw error
    }
}

// ❌ BAD: Assumes everything will work
func updateTransaction(_ transaction: Transaction) {
    sheetAdapter.update(transaction)
}
```

### Style Guidelines

- Use SwiftUI and Combine for new features
- Async/await for all API calls
- Clear, descriptive variable names
- Comments for complex logic
- No force unwrapping in production code

### Commit Messages

Follow conventional commits:
```
feat: add bulk categorization support
fix: prevent formula overwrite in row updates
docs: update sheet detection documentation
test: add unit tests for transaction sync
refactor: simplify sheet adapter protocol
```

### Testing Requirements

All PRs must include:
- Unit tests for business logic
- UI tests for critical user paths
- Manual testing checklist completed
- Screenshots/recordings for UI changes

## Pull Request Process

1. **Before submitting:**
   - Rebase on latest main
   - Run all tests locally
   - Update documentation
   - Add changelog entry

2. **PR description should include:**
   - What changes were made and why
   - How it was tested
   - Screenshots (for UI changes)
   - Related issue number

3. **PR checklist:**
   ```markdown
   - [ ] Tests pass locally
   - [ ] Documentation updated
   - [ ] No sensitive data in code
   - [ ] Tested with real Tiller sheets
   - [ ] SwiftLint warnings resolved
   ```

4. **Review process:**
   - At least one maintainer review required
   - All CI checks must pass
   - No merge until feedback addressed

## Project Structure

```
TillerCompanion/
├── App/                 # App lifecycle and configuration
├── Core/
│   ├── Models/         # Data models
│   ├── Services/       # Business logic
│   └── Extensions/     # Swift extensions
├── Features/           # Feature modules
│   ├── Transactions/   # Transaction management
│   ├── Categories/     # Category picker
│   └── Settings/       # App settings
├── Shared/
│   ├── UI/            # Reusable UI components
│   └── Utils/         # Helper functions
└── Tests/             # Test files
```

## Safety Guidelines

### When Working with Sheets

**Always:**
- Validate schema before writes
- Use column names, not positions
- Check for formula cells
- Handle missing columns gracefully
- Test with sorted/filtered sheets

**Never:**
- Assume column positions
- Overwrite formulas
- Delete data without confirmation
- Cache sensitive data unnecessarily
- Log transaction amounts or details

### Data Privacy

- No analytics or tracking
- No third-party SDKs without review
- Clear data handling in code
- Secure credential storage only

## Getting Help

- 💬 [GitHub Discussions](https://github.com/dmorrill/tiller-ios/discussions) - Ask questions
- 📖 [Wiki](https://github.com/dmorrill/tiller-ios/wiki) - Development guides
- 🐛 [Issues](https://github.com/dmorrill/tiller-ios/issues) - Bug reports
- 💡 [Feature Requests](https://github.com/dmorrill/tiller-ios/issues/new?template=feature_request.md) - Ideas

## Recognition

Contributors will be:
- Listed in our README
- Credited in release notes
- Part of making financial management more accessible!

## Quick Commands

```bash
# Run tests
swift test

# Check code style
swiftlint

# Build for testing
xcodebuild -scheme TillerCompanion test

# Generate documentation
swift-doc generate Sources/
```

## Questions?

Feel free to:
- Open a discussion for general questions
- Comment on issues for clarification
- Reach out to maintainers

Thank you for helping make Tiller iOS better! 🎉

---

**Remember:** Every line of code you write will handle someone's financial data. Code accordingly.