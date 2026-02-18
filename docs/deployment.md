# Deployment

## Backend

The backend deploys to Laravel Forge / Vapor.

```bash
cd backend
vendor/bin/vapor deploy production
```

## iOS

1. Open Xcode
2. Increment version in project settings
3. Archive → Distribute → App Store Connect
4. Submit for review

## Environment Variables

See `backend/.env.example` for required configuration.
