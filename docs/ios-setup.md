# iOS Development Setup

## Prerequisites
- Xcode 16+
- macOS Sequoia or later
- Apple Developer account (for device testing)

## Setup

1. Open `TillerCompanion.xcodeproj` in Xcode
2. Select your development team in Signing & Capabilities
3. Build and run on simulator or device

## Architecture

- **SwiftUI** — declarative UI framework
- **Models/** — data models and persistence
- **Features/** — feature modules (habits, streaks, settings)
- **Services/** — API client, notifications, storage

## Backend API

The companion backend is a Laravel API in `backend/`. See `backend/README.md` for setup.
