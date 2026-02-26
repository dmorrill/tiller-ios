//
//  OnboardingView.swift
//  TillerCompanion
//
//  Welcome onboarding flow for new users
//

import SwiftUI

struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    @State private var currentPage = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "doc.text.fill",
            title: "Welcome to Tiller Companion",
            description: "Manage your Tiller spreadsheet on the go with a fast, native iOS experience.",
            color: .blue
        ),
        OnboardingPage(
            icon: "arrow.triangle.2.circlepath",
            title: "Sync with Your Sheet",
            description: "Your Google Sheet stays the source of truth. We read and write only what you need.",
            color: .green
        ),
        OnboardingPage(
            icon: "tag.fill",
            title: "Quick Categorization",
            description: "Swipe to categorize transactions in seconds. Add notes and tags on the fly.",
            color: .orange
        ),
        OnboardingPage(
            icon: "lock.shield.fill",
            title: "Private & Secure",
            description: "Open source, no tracking, no data collection. Your finances stay yours.",
            color: .purple
        )
    ]

    var body: some View {
        VStack {
            TabView(selection: $currentPage) {
                ForEach(pages.indices, id: \.self) { index in
                    OnboardingPageView(page: pages[index])
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            Button {
                if currentPage < pages.count - 1 {
                    withAnimation { currentPage += 1 }
                } else {
                    hasCompletedOnboarding = true
                }
            } label: {
                Text(currentPage < pages.count - 1 ? "Next" : "Get Started")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(14)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 16)

            if currentPage < pages.count - 1 {
                Button("Skip") {
                    hasCompletedOnboarding = true
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.bottom, 24)
            } else {
                Spacer().frame(height: 48)
            }
        }
    }
}

struct OnboardingPage {
    let icon: String
    let title: String
    let description: String
    let color: Color
}

struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: page.icon)
                .font(.system(size: 80))
                .foregroundColor(page.color)

            Text(page.title)
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            Text(page.description)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()
        }
    }
}

#Preview {
    OnboardingView(hasCompletedOnboarding: .constant(false))
}
