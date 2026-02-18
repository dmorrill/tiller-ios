# Tiller iOS Architecture

## Overview

SwiftUI app with a Laravel backend. The iOS app syncs habit data via REST API.

## Structure

```
TillerCompanion/
├── App/           — App entry point, navigation
├── Features/      — Feature modules
│   ├── Habits/    — Habit tracking views
│   ├── Streaks/   — Streak visualization
│   └── Settings/  — User preferences
├── Models/        — Data models
├── Services/      — API client, notifications
└── Assets/        — Images, colors
```

## Data Flow

1. User creates habits in the app
2. Habits sync to backend via REST API
3. Backend stores in Google Sheets (via Tiller integration)
4. Streaks and analytics computed locally + backend

## Dependencies

- SwiftUI (UI framework)
- Foundation (networking, data)
- No third-party dependencies (intentional)
