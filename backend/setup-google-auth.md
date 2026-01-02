# Google OAuth Setup Checklist

Follow these steps to set up Google OAuth for your Tiller iOS Companion app.

## Quick Setup Guide

### Step 1: Create Google Cloud Project

1. **Open Google Cloud Console**
   ```
   https://console.cloud.google.com
   ```

2. **Create New Project**
   - Click "Select a project" → "NEW PROJECT"
   - Name: `Tiller iOS Companion`
   - Click "CREATE"

### Step 2: Enable APIs

Once in your project, enable these APIs:

1. **Google Sheets API**
   ```
   https://console.cloud.google.com/apis/library/sheets.googleapis.com
   ```
   Click "ENABLE"

2. **Google Drive API**
   ```
   https://console.cloud.google.com/apis/library/drive.googleapis.com
   ```
   Click "ENABLE"

### Step 3: Configure OAuth Consent Screen

1. **Go to OAuth consent screen**
   ```
   https://console.cloud.google.com/apis/credentials/consent
   ```

2. **Choose User Type**
   - Select "External" (for open source)
   - Click "CREATE"

3. **Fill App Information**
   - App name: `Tiller Companion`
   - User support email: [Your email]
   - Developer contact: [Your email]

4. **Add Scopes**
   Click "ADD OR REMOVE SCOPES" and select:
   - `userinfo.email`
   - `userinfo.profile`
   - `spreadsheets` (Google Sheets API)
   - `drive.file` (Google Drive API)

5. **Add Test Users** (if using External type)
   - Add your email
   - Click "SAVE AND CONTINUE"

### Step 4: Create OAuth Credentials

1. **Go to Credentials**
   ```
   https://console.cloud.google.com/apis/credentials
   ```

2. **Create Web OAuth Client**
   - Click "CREATE CREDENTIALS" → "OAuth client ID"
   - Application type: "Web application"
   - Name: `Tiller Companion Web`

   **Add Authorized JavaScript origins:**
   ```
   http://localhost:8000
   ```

   **Add Authorized redirect URIs:**
   ```
   http://localhost:8000/api/auth/google/callback
   ```

   - Click "CREATE"
   - **SAVE THE CLIENT ID AND SECRET!**

3. **Create iOS OAuth Client** (for later)
   - Click "CREATE CREDENTIALS" → "OAuth client ID"
   - Application type: "iOS"
   - Name: `Tiller Companion iOS`
   - Bundle ID: `com.tiller.companion`
   - Click "CREATE"
   - **SAVE THE CLIENT ID!**

### Step 5: Update Laravel Backend

1. **Copy your credentials to the .env file:**

```bash
# Edit the .env file and replace the placeholders:
GOOGLE_CLIENT_ID=YOUR_ACTUAL_CLIENT_ID.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=YOUR_ACTUAL_CLIENT_SECRET
```

2. **The server should auto-reload with the new credentials**

### Step 6: Test Authentication

1. **Test the OAuth flow in your browser:**
   ```
   http://localhost:8000/api/auth/google
   ```

2. **You should see:**
   - Google login screen
   - Permission request for Tiller Companion
   - Redirect back to your app

## Quick Copy Commands

Once you have your credentials, run these to update .env:

```bash
# Replace with your actual values
export GOOGLE_CLIENT_ID="your-actual-client-id.apps.googleusercontent.com"
export GOOGLE_CLIENT_SECRET="your-actual-client-secret"

# Update the .env file (backup first!)
cp backend/.env backend/.env.backup
sed -i '' "s/your-client-id-here.apps.googleusercontent.com/$GOOGLE_CLIENT_ID/" backend/.env
sed -i '' "s/your-client-secret-here/$GOOGLE_CLIENT_SECRET/" backend/.env
```

## Verification Checklist

- [ ] Google Cloud Project created
- [ ] Google Sheets API enabled
- [ ] Google Drive API enabled
- [ ] OAuth consent screen configured
- [ ] Web OAuth client created
- [ ] iOS OAuth client created (for later)
- [ ] Credentials added to .env
- [ ] Test authentication working

## Troubleshooting

If you get errors:

1. **"Access blocked"** - Make sure your email is in test users
2. **"Invalid client"** - Check CLIENT_ID and SECRET are correct
3. **"Redirect URI mismatch"** - Ensure callback URL matches exactly
4. **Server doesn't reload** - Restart with `php artisan serve`

## Ready?

Once you've completed the checklist above, we can test the authentication flow!