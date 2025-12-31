# Google Cloud Setup for Tiller iOS Companion

This guide walks you through setting up Google Cloud Console for the Tiller iOS companion app.

## Prerequisites

- Google Cloud account (free tier is sufficient)
- Access to Google Cloud Console
- A Tiller spreadsheet in Google Sheets

## Step 1: Create a Google Cloud Project

1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Click "Select a project" dropdown
3. Click "NEW PROJECT"
4. Enter project details:
   - **Project name**: `Tiller iOS Companion` (or your preference)
   - **Project ID**: Auto-generated (you can customize)
   - **Location**: Your organization (or "No organization")
5. Click "CREATE"

## Step 2: Enable Required APIs

1. In your project, go to "APIs & Services" > "Library"
2. Search for and enable these APIs:
   - **Google Sheets API**
   - **Google Drive API**
   - **Google Identity Platform** (for OAuth)

For each API:
- Click on the API name
- Click "ENABLE"
- Wait for activation

## Step 3: Configure OAuth Consent Screen

1. Go to "APIs & Services" > "OAuth consent screen"
2. Choose user type:
   - **External** for public app (recommended for open source)
   - **Internal** if only for your organization
3. Click "CREATE"
4. Fill in app information:
   - **App name**: `Tiller Companion`
   - **User support email**: Your email
   - **Developer contact**: Your email
   - **App logo**: Optional (can add later)

5. Add scopes:
   - Click "ADD OR REMOVE SCOPES"
   - Select these scopes:
     - `userinfo.email`
     - `userinfo.profile`
     - `spreadsheets` (Google Sheets API)
     - `drive.file` (Google Drive API - file access only)
   - Click "UPDATE"

6. Test users (if External):
   - Add your email and any beta testers
   - Click "ADD USERS"

7. Review and click "BACK TO DASHBOARD"

## Step 4: Create OAuth 2.0 Credentials

### For Web Application (Laravel Backend)

1. Go to "APIs & Services" > "Credentials"
2. Click "CREATE CREDENTIALS" > "OAuth client ID"
3. Choose "Web application"
4. Configure:
   - **Name**: `Tiller Companion Web`
   - **Authorized JavaScript origins**:
     - `http://localhost:8000` (development)
     - `https://your-domain.com` (production)
   - **Authorized redirect URIs**:
     - `http://localhost:8000/api/auth/google/callback` (development)
     - `https://your-domain.com/api/auth/google/callback` (production)
5. Click "CREATE"
6. **Save the Client ID and Client Secret**

### For iOS Application

1. Click "CREATE CREDENTIALS" > "OAuth client ID" again
2. Choose "iOS"
3. Configure:
   - **Name**: `Tiller Companion iOS`
   - **Bundle ID**: `com.tiller.companion`
4. Click "CREATE"
5. **Save the Client ID**

## Step 5: Download Credentials

1. In the credentials list, click the download icon next to your Web OAuth 2.0 client
2. Save as `google-credentials.json` (keep this secure!)
3. For iOS, you'll receive a configuration file to add to your Xcode project

## Step 6: Configure Laravel Backend

1. Copy credentials to your `.env` file:
```env
GOOGLE_CLIENT_ID=your-client-id-here.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=your-client-secret-here
GOOGLE_REDIRECT_URI="${APP_URL}/api/auth/google/callback"
```

2. Update `config/services.php`:
```php
'google' => [
    'client_id' => env('GOOGLE_CLIENT_ID'),
    'client_secret' => env('GOOGLE_CLIENT_SECRET'),
    'redirect' => env('GOOGLE_REDIRECT_URI'),
],
```

## Step 7: Configure iOS App

1. Add the iOS client ID to your `Info.plist`:
```xml
<key>GIDClientID</key>
<string>your-ios-client-id.apps.googleusercontent.com</string>
```

2. Add URL scheme for OAuth callback:
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>com.googleusercontent.apps.your-ios-client-id</string>
        </array>
    </dict>
</array>
```

## Step 8: Test Authentication Flow

### Backend Test
```bash
# Start Laravel server
php artisan serve

# Visit in browser
http://localhost:8000/api/auth/google
```

### iOS Test
1. Run app in Xcode
2. Tap "Sign in with Google"
3. Complete OAuth flow
4. Verify token exchange with backend

## Security Best Practices

### Never Commit Credentials
- Add to `.gitignore`:
  ```
  .env
  google-credentials.json
  GoogleService-Info.plist
  ```

### Restrict API Keys (Production)
1. Go to "APIs & Services" > "Credentials"
2. Click on your API key
3. Under "Application restrictions":
   - Choose "iOS apps" for iOS key
   - Add bundle ID
4. Under "API restrictions":
   - Choose "Restrict key"
   - Select only needed APIs

### Monitor Usage
1. Go to "APIs & Services" > "Metrics"
2. Set up alerts for unusual activity
3. Review quotas regularly

## Quotas and Limits

Google Sheets API default quotas:
- **Read requests**: 500 per 100 seconds per user
- **Write requests**: 500 per 100 seconds per user
- **Daily limit**: 1,000,000,000 requests

For most users, these limits are more than sufficient.

## Troubleshooting

### "Access blocked" Error
- Ensure app is in testing mode or published
- Add user to test users list
- Check OAuth consent screen configuration

### "Invalid client" Error
- Verify client ID matches environment
- Check redirect URI exactly matches
- Ensure secrets are correctly copied

### "Insufficient permission" Error
- Check requested scopes in OAuth flow
- Verify APIs are enabled in Cloud Console
- User may need to reauthorize with new scopes

### Rate Limiting
- Implement exponential backoff
- Cache frequently accessed data
- Batch operations when possible

## Publishing Your App

When ready for production:

1. **Verify OAuth consent screen**
   - Complete all required fields
   - Add privacy policy URL
   - Add terms of service URL

2. **Submit for verification** (if using sensitive scopes)
   - Google will review your app
   - May take several days/weeks
   - Required for >100 users

3. **Monitor and maintain**
   - Keep credentials secure
   - Rotate secrets periodically
   - Monitor API usage

## Additional Resources

- [Google Sheets API Documentation](https://developers.google.com/sheets/api)
- [Google OAuth 2.0 Documentation](https://developers.google.com/identity/protocols/oauth2)
- [Google Cloud Console](https://console.cloud.google.com)
- [API Explorer](https://developers.google.com/apis-explorer)

---

**Important**: Keep all credentials secure and never commit them to version control. Use environment variables for all sensitive configuration.