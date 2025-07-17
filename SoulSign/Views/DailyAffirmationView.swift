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

    var body: some View {
        NavigationView {
            ZStack {
                NightSkyBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Daily Affirmations")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.bottom, 10)

                        if isLoading {
                            ProgressView("Loading Affirmations...")
                                .foregroundColor(.white)
                        } else if let affirmations = affirmations {
                            affirmationBlock(title: "💰 Finance", text: affirmations.Finance)
                            affirmationBlock(title: "❤️ Love", text: affirmations.Love)
                            affirmationBlock(title: "🧘 Mind & Spirit", text: affirmations.MindSpirit)
                            affirmationBlock(title: "💼 Career", text: affirmations.Career)
                            affirmationBlock(title: "🤝 Friendship", text: affirmations.Friendship)
                            affirmationBlock(title: "🩺 Health", text: affirmations.Health)
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
                        .background(Color.white.opacity(0.9))
                        .foregroundColor(.blue)
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
            Text("\"\(text)\"")
                .font(.body)
                .italic()
        }
        .padding()
        .background(Color.white.opacity(0.9))
        .cornerRadius(10)
        .shadow(radius: 2)
    }
}
