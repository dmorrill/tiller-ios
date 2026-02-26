//
//  LoadingIndicator.swift
//  TillerCompanion
//
//  Reusable loading indicator components
//

import SwiftUI

// MARK: - Full Screen Loading
struct FullScreenLoadingView: View {
    let message: String

    init(_ message: String = "Loading...") {
        self.message = message
    }

    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            ProgressView()
                .scaleEffect(1.2)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityLabel(message)
    }
}

// MARK: - Inline Loading
struct InlineLoadingView: View {
    let message: String

    init(_ message: String = "Loading...") {
        self.message = message
    }

    var body: some View {
        HStack(spacing: 10) {
            ProgressView()
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .accessibilityLabel(message)
    }
}

// MARK: - Overlay Loading Modifier
struct LoadingOverlayModifier: ViewModifier {
    let isLoading: Bool
    let message: String

    func body(content: Content) -> some View {
        content
            .overlay {
                if isLoading {
                    ZStack {
                        Color.black.opacity(0.2)
                            .ignoresSafeArea()
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.3)
                                .tint(.white)
                            Text(message)
                                .font(.subheadline)
                                .foregroundColor(.white)
                        }
                        .padding(24)
                        .background(.ultraThinMaterial)
                        .cornerRadius(16)
                    }
                    .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: isLoading)
    }
}

// MARK: - Sync Progress View
struct SyncProgressView: View {
    let progress: Double
    let status: String

    var body: some View {
        VStack(spacing: 8) {
            ProgressView(value: progress)
                .tint(.blue)
            Text(status)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
        .accessibilityLabel(A11yLabels.syncStatus(status))
    }
}

extension View {
    func loadingOverlay(isLoading: Bool, message: String = "Loading...") -> some View {
        modifier(LoadingOverlayModifier(isLoading: isLoading, message: message))
    }
}

#Preview {
    VStack(spacing: 30) {
        FullScreenLoadingView("Fetching transactions...")
        SyncProgressView(progress: 0.6, status: "Syncing transactions...")
    }
}
