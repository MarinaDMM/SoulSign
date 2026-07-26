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
    @EnvironmentObject var loc: LocalizationManager
    @Environment(\.colorScheme) private var colorScheme
    private var theme: AppTheme { AppTheme(colorScheme: colorScheme) }

    var body: some View {
        NavigationView {
            ZStack {
                NightSkyBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text(loc.t("daily_affirmations_title"))
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(theme.primaryText)
                            .padding(.bottom, 10)

                        if isLoading {
                            ProgressView(loc.t("loading_affirmations"))
                                .foregroundColor(theme.primaryText)
                        } else if let affirmations = affirmations {
                            affirmationBlock(title: loc.t("category_finance"),     text: affirmations.Finance)
                            affirmationBlock(title: loc.t("category_love"),        text: affirmations.Love)
                            affirmationBlock(title: loc.t("category_mind_spirit"), text: affirmations.MindSpirit)
                            affirmationBlock(title: loc.t("category_career"),      text: affirmations.Career)
                            affirmationBlock(title: loc.t("category_friendship"),  text: affirmations.Friendship)
                            affirmationBlock(title: loc.t("category_health"),      text: affirmations.Health)
                        } else if let errorMessage = errorMessage {
                            Text(errorMessage)
                                .foregroundColor(.red)
                        }

                        Button(loc.t("button_refresh_affirmations")) {
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

        if !forceRefresh, let cached = AffirmationService.loadStoredAffirmations(language: loc.language) {
            self.affirmations = cached
            self.isLoading = false
        } else {
            AffirmationService.fetchAndStoreAffirmations(language: loc.language) { result in
                self.isLoading = false
                self.affirmations = result
                if result == nil {
                    self.errorMessage = loc.t("affirmations_failed")
                }
                self.forceRefresh = false
            }
        }
    }

    private func affirmationBlock(title: String, text: String) -> some View {
        VStack(alignment: .leading) {
            HStack(alignment: .top) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(theme.cardText)
                Spacer()
                ShareCardButton(previewTitle: title) {
                    AffirmationShareCard(categoryTitle: title, text: text)
                }
                .font(.subheadline)
                .foregroundColor(theme.cardText.opacity(0.55))
            }
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
