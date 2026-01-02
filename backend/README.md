# Tiller iOS Companion - Laravel Backend

This is the Laravel API backend for the Tiller iOS Companion app.

## ✅ Current Status

The Laravel backend is set up and ready for development with:

- **API Structure**: RESTful API with proper routing and middleware
- **Authentication**: Google OAuth integration (credentials needed)
- **Database**: SQLite configured with migrations for users, sheets, and sheet schemas
- **Security**: Sanctum for API authentication, proper CORS handling
- **Services**: Sheet detection and adapter services for safe data operations

## 🚀 Quick Start

1. **Install Dependencies**
   ```bash
   composer install
   ```

2. **Configure Environment**
   ```bash
   cp .env.example .env
   php artisan key:generate
   ```

3. **Run Migrations**
   ```bash
   php artisan migrate
   ```

4. **Start Development Server**
   ```bash
   php artisan serve
   ```

5. **Test API Endpoints**
   ```bash
   ./test-api.sh
   ```

## 📝 API Endpoints

### Public Endpoints
- `GET /api/health` - Health check endpoint

### Authentication
- `GET /api/auth/google` - Initiate Google OAuth flow
- `GET /api/auth/google/callback` - OAuth callback handler
- `POST /api/auth/mobile` - Mobile app authentication
- `POST /api/auth/refresh` - Refresh authentication token
- `POST /api/auth/logout` - Logout user

### Protected Endpoints (Require Authentication)
- `GET /api/sheets` - List user's sheets
- `POST /api/sheets` - Connect a new sheet
- `GET /api/sheets/{id}` - Get sheet details
- `DELETE /api/sheets/{id}` - Disconnect a sheet
- `GET /api/transactions` - List transactions
- `PATCH /api/transactions/{id}` - Update transaction
- `GET /api/categories` - List categories
- `POST /api/categories` - Create category

## 🔐 Google OAuth Setup

To enable authentication, you need to set up Google Cloud credentials:

1. Follow the guide in `docs/GOOGLE_CLOUD_SETUP.md`
2. Add credentials to `.env`:
   ```env
   GOOGLE_CLIENT_ID=your-client-id.apps.googleusercontent.com
   GOOGLE_CLIENT_SECRET=your-client-secret
   GOOGLE_REDIRECT_URI="${APP_URL}/api/auth/google/callback"
   ```

## 🏗️ Architecture

### Models
- **User**: Stores user information and Google OAuth tokens
- **Sheet**: Represents connected Google Sheets
- **SheetSchema**: Stores detected sheet structure and column mappings

### Services
- **GoogleSheetsService**: Handles Google Sheets API operations
- **SheetDetectionService**: Auto-detects Tiller sheet templates
- **SheetAdapterService**: Ensures safe data operations (only writes to allowed columns)

### Security Features
- Row identity management using `__mobile_app_id` column
- Safe write operations limited to: Category, Note, Tags
- Confidence scoring for sheet detection
- Token refresh handling for long-lived sessions

## 🧪 Testing

Run the API test script to verify all endpoints:
```bash
./test-api.sh
```

This will test:
- Health endpoint availability
- Authentication flow readiness
- Protected endpoint security (401 responses)
- JSON response formatting

## 📚 Documentation

- Main documentation: `../README.md`
- Development guidelines: `../CLAUDE.md`
- Google Cloud setup: `../docs/GOOGLE_CLOUD_SETUP.md`
- API test script: `./test-api.sh`

## 🔄 Next Steps

1. **Set up Google Cloud Project**
   - Create project in Google Cloud Console
   - Enable Google Sheets and Drive APIs
   - Configure OAuth consent screen
   - Generate credentials

2. **Test Authentication Flow**
   - Add real Google credentials to `.env`
   - Test OAuth flow with browser
   - Verify token storage and refresh

3. **Connect iOS App**
   - Configure iOS app with backend URL
   - Implement API client in Swift
   - Test end-to-end flow

4. **Deploy to Production**
   - Set up hosting (Laravel Forge, Vapor, etc.)
   - Configure production database
   - Set up SSL certificates
   - Update OAuth redirect URLs

## 🛠️ Development

The backend follows Laravel best practices:
- RESTful API design
- Service layer for business logic
- Repository pattern for data access
- Proper error handling and validation
- Comprehensive logging

For development guidelines specific to this project, see `../CLAUDE.md`.