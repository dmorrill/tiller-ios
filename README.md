# Tiller iOS - Open Source Mobile Companion for Tiller Spreadsheets

An open-source iOS app that lets you manage your Tiller spreadsheet on the go — without ever taking ownership of your data.

## Overview

Tiller iOS is a **sheet-first** mobile companion app for [Tiller](https://www.tillerhq.com) users. It provides a fast, native iOS interface for the most common on-the-go financial tasks while keeping your Google Sheets spreadsheet as the single source of truth.

### What This App Does
- ✅ View recent transactions in a clean mobile interface
- ✅ Quickly categorize uncategorized transactions
- ✅ Add notes and tags to transactions
- ✅ Add simple manual (cash) transactions
- ✅ View account balances and budget snapshots
- ✅ Sync changes directly back to your Google Sheet

### What This App Doesn't Do
- ❌ Replace your spreadsheet (it enhances it)
- ❌ Store your financial data (everything stays in your sheet)
- ❌ Modify formulas or restructure templates
- ❌ Trigger bank feed refreshes
- ❌ Run Tiller add-ons (AutoCat, etc.)

## Key Principles

### 🔐 Open Source = Trust
Every line of code that touches your financial data is open, auditable, and transparent. We believe that when you grant an app access to your personal finances, you should be able to see exactly what it does.

### 📊 Sheet-First Architecture
Your Google Sheet remains the source of truth. The app adapts to your existing sheet structure, never the other way around. We write only to fields you already expect to edit (Category, Note, Tags).

### 🛡️ Safe by Default
The app follows strict write-back rules:
- Never overwrites formulas
- Never deletes rows without explicit action
- Never reorders your data
- Only writes to explicitly documented columns
- Maintains immutable row IDs for safe updates

## Repository Structure

This is a monorepo containing both the iOS app and Laravel API backend:

```
tiller-ios/
├── TillerCompanion/     # iOS app (Swift/SwiftUI)
├── backend/             # Laravel API backend
├── docs/                # Documentation
└── scripts/             # Build and deployment scripts
```

## Getting Started

### Prerequisites
- iOS 16.0 or later
- Active Tiller subscription with Google Sheets
- Google account with appropriate sheet permissions

### Installation

#### From TestFlight (Coming Soon)
1. Join our TestFlight beta program
2. Install the app on your iOS device
3. Authorize Google Sheets access
4. Select your Tiller spreadsheet

#### Building from Source

**1. Google Cloud Service Account (required):**

The backend uses a Google service account to read/write your Tiller spreadsheet on your behalf.

1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Create a new project (e.g., "Tiller iOS")
3. Enable the **Google Sheets API**: APIs & Services → Library → search "Google Sheets API" → Enable
4. Create a service account: APIs & Services → Credentials → Create Credentials → Service Account
   - Name: `tiller-ios-backend`
   - Skip the optional permissions steps
5. Create a key: Click on the service account → Keys tab → Add Key → Create new key → JSON
6. Save the downloaded JSON file — you'll need the path for your `.env`
7. **Share your Tiller spreadsheet** with the service account email (e.g., `tiller-ios-backend@your-project.iam.gserviceaccount.com`) and give it **Editor** access

**2. Backend Setup:**
```bash
# Clone the repository
git clone https://github.com/dmorrill/tiller-ios.git
cd tiller-ios/backend

# Install dependencies (requires PHP 8.4+ and Composer)
composer install

# Configure environment
cp .env.example .env
php artisan key:generate

# Add your service account config to .env:
# GOOGLE_SERVICE_ACCOUNT_KEY_PATH=/path/to/your-service-account-key.json
# GOOGLE_SERVICE_ACCOUNT_EMAIL=tiller-ios-backend@your-project.iam.gserviceaccount.com

# Run migrations
php artisan migrate

# Start the development server
php artisan serve
```

> **Template requirement:** Your Tiller spreadsheet must use the **Foundation Template** (the default). The app detects and validates the expected column structure on first connection. Custom templates are not yet supported.

**3. iOS App Setup:**
```bash
cd tiller-ios

# Open the Xcode project (requires Xcode 15+, iOS 16+ target)
open TillerCompanion.xcodeproj

# Configure the API URL in the app:
# - For local development: http://localhost:8000/api
# - For production: your deployed backend URL

# Build and run on your device or simulator
```

## Architecture Overview

```
┌─────────────────┐
│   iOS Client    │
│  (Swift/SwiftUI)│
└────────┬────────┘
         │
    OAuth + API
         │
┌────────▼────────┐
│ Backend Service │
│   (Optional)    │
└────────┬────────┘
         │
   Sheets API
         │
┌────────▼────────┐
│  Google Sheet   │
│ (Your Tiller    │
│   Spreadsheet)  │
└─────────────────┘
```

### Components

#### iOS Client
- Native Swift/SwiftUI implementation
- Local caching for offline viewing
- Optimistic UI updates with sync indicators
- Face ID/Touch ID for app security

#### Backend Service (Thin Layer)
- Google OAuth token handling
- Sheets API coordination
- Schema detection and mapping
- Safe write-back orchestration

> **Note**: The backend is designed to be replaceable. Advanced users can self-host or implement alternatives.

#### Sheet Adapter
- Detects Tiller transaction tables
- Maps columns by header names
- Maintains row identity for safe updates
- Handles schema variations gracefully

## Data Safety

### What We Access
- **Read**: Transaction data, categories, account balances
- **Write**: Category, Note, Tags fields, and one app-owned ID column

### What We Never Touch
- Formula cells
- Pivot tables
- Charts
- Custom columns (unless explicitly mapped)
- Other sheets in your spreadsheet

### Row Identity System
To safely update rows even when sheets are sorted/filtered, the app adds a single column:
- Column name: `__mobile_app_id`
- Purpose: Immutable row identifier
- When added: On first app connection (with your permission)
- Can be hidden: Yes, without affecting functionality

## Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for detailed information on:
- How to report bugs and suggest features
- Development setup and workflow
- Code style and safety guidelines
- Testing requirements
- Pull request process

### Quick Start for Contributors
1. Fork the repository
2. Read [CONTRIBUTING.md](CONTRIBUTING.md)
3. Check [open issues](https://github.com/dmorrill/tiller-ios/issues) for something to work on
4. Comment on an issue before starting work
5. Submit a PR with tests

### Priority Areas
- Transaction categorization improvements
- Additional Tiller template support
- Accessibility enhancements
- Performance optimizations
- Test coverage

## Privacy & Security

### Our Commitments
- **No data collection**: We don't store or transmit your financial data
- **No analytics**: No tracking, no telemetry, no third-party SDKs
- **Token security**: OAuth tokens are stored in iOS Keychain
- **Open source**: Every line of code is auditable

### Permissions Required
- Google Sheets API: Read/write access to selected spreadsheets
- Face ID/Touch ID: Optional app lock
- Network: Sync with Google Sheets

## Support

### Getting Help
- 📖 [Documentation Wiki](https://github.com/dmorrill/tiller-ios/wiki)
- 💬 [Discussions](https://github.com/dmorrill/tiller-ios/discussions)
- 🐛 [Report Issues](https://github.com/dmorrill/tiller-ios/issues)

### Community
- [Tiller Community Forum](https://community.tillerhq.com)
- [r/TillerHQ](https://reddit.com/r/tillerhq)

## Roadmap

### V1.0 - Foundation (Current)
- ✅ Core transaction management
- ✅ Safe sheet synchronization
- ✅ Basic budget snapshots
- 🚧 TestFlight beta

### V1.1 - Polish
- Enhanced category picker
- Bulk categorization
- Transaction search
- Widget support

### V2.0 - Expansion
- iPad optimization
- Multiple sheet support
- Custom template detection
- Offline mode improvements

### Future Considerations
- Android companion
- Web interface
- Apple Watch app
- Shortcuts integration

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- [Tiller](https://www.tillerhq.com) for creating the best spreadsheet-based finance platform
- The Tiller community for inspiration and feedback
- Contributors who help make this app better

## Disclaimer

This is an independent open-source project and is not officially affiliated with or endorsed by Tiller. Tiller is a trademark of Tiller Inc.

---

**Remember**: Your spreadsheet is your data. This app is just a friendly mobile interface to it.