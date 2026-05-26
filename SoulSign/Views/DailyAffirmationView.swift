//
//  DailyAffirmationView.swift
//  SoulSign
//
//  Created by Marina Dedikova on 16/07/2025.
//
import SwiftUI

struct DailyAffirmationView: View {
    @State private var affirmations: AffirmationResponse?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var forceRefresh = false
    @Environment(\.colorScheme) private var colorScheme
    private var theme: AppTheme { AppTheme(colorScheme: colorScheme) }

    var body: some View {
        NavigationView {
            ZStack {
                NightSkyBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Daily Affirmations")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(theme.primaryText)
                            .padding(.bottom, 10)

                        if isLoading {
                            ProgressView("Loading Affirmations...")
                                .foregroundColor(theme.primaryText)
                        } else if let affirmations = affirmations {
                            affirmationBlock(title: "💰 Finance",     text: affirmations.Finance)
                            affirmationBlock(title: "❤️ Love",        text: affirmations.Love)
                            affirmationBlock(title: "🧘 Mind & Spirit", text: affirmations.MindSpirit)
                            affirmationBlock(title: "💼 Career",      text: affirmations.Career)
                            affirmationBlock(title: "🤝 Friendship",  text: affirmations.Friendship)
                            affirmationBlock(title: "🩺 Health",      text: affirmations.Health)
                        } else if let errorMessage = errorMessage {
                            Text(errorMessage)
                                .foregroundColor(.red)
                        }

                        Button("🔁 Refresh Affirmations") {
                            forceRefresh = true
                            fetchAffirmations()
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(theme.secondaryButtonBg)
                        .foregroundColor(theme.secondaryButtonText)
                        .cornerRadius(12)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear { fetchAffirmations() }
    }

    private func fetchAffirmations() {
        isLoading = true
        errorMessage = nil

        if !forceRefresh, let cached = AffirmationService.loadStoredAffirmations() {
            self.affirmations = cached
            self.isLoading = false
        } else {
            AffirmationService.fetchAndStoreAffirmations { result in
                self.isLoading = false
                self.affirmations = result
                if result == nil {
                    self.errorMessage = "Failed to load affirmations. Try again later."
                }
                self.forceRefresh = false
            }
        }
    }

    private func affirmationBlock(title: String, text: String) -> some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.headline)
                .foregroundColor(theme.cardText)
            Text("\"\(text)\"")
                .font(.body)
                .italic()
                .foregroundColor(theme.cardText)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.cardBackground)
        .cornerRadius(10)
        .shadow(color: .black.opacity(0.1), radius: 2)
    }
}
