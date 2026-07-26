//
//  TarotCardView.swift
//  SoulSign
//
import SwiftUI

// MARK: - Card Face (real 1909 Rider-Waite-Smith scan, public domain)

struct TarotCardFace: View {
    let card: TarotCard

    // All 78 assets are normalized to this exact ratio (750x1298) so every
    // card's frame, corner radius, and border line up identically.
    private static let cardAspectRatio: CGFloat = 750.0 / 1298.0
    private static let cornerRadius: CGFloat = 7

    var body: some View {
        Image(card.imageName)
            .resizable()
            .aspectRatio(Self.cardAspectRatio, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: Self.cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Self.cornerRadius, style: .continuous)
                    .strokeBorder(.white.opacity(0.22), lineWidth: 1)
            )
    }
}

// MARK: - Main View

struct TarotCardView: View {
    @StateObject private var vm = TarotViewModel()
    @EnvironmentObject var loc: LocalizationManager
    @Environment(\.colorScheme) private var colorScheme
    private var theme: AppTheme { AppTheme(colorScheme: colorScheme) }

    var body: some View {
        ZStack {
            NightSkyBackground()

            if vm.isLoading && vm.reading.isEmpty {
                initialLoadingView
            } else if let error = vm.errorMessage, vm.reading.isEmpty {
                errorView(error)
            } else {
                contentView
            }
        }
        .navigationTitle(loc.t("tarot_today"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !vm.reading.isEmpty {
                ToolbarItem(placement: .navigationBarTrailing) {
                    ShareCardButton(previewTitle: vm.card.name) {
                        TarotShareCard(card: vm.card, reading: vm.reading, dateLabel: todayLabel)
                    }
                    .foregroundColor(theme.primaryText)
                }
            }
        }
        .task { await vm.loadReading(language: loc.language) }
    }

    // MARK: Content

    private var contentView: some View {
        ScrollView {
            VStack(spacing: 28) {
                Text(todayLabel)
                    .font(.system(size: 11, weight: .medium))
                    .tracking(2.5)
                    .foregroundColor(theme.primaryText.opacity(0.45))

                TarotCardFace(card: vm.card)
                    .frame(maxWidth: 220)
                    .padding(28)
                    .background(cardBackdrop)
                    .shadow(color: .black.opacity(0.35), radius: 18, x: 0, y: 10)
                    .shadow(color: Color(red: 1.0, green: 0.85, blue: 0.55).opacity(0.30), radius: 30)

                if vm.isLoading {
                    HStack(spacing: 12) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white.opacity(0.7)))
                        Text(loc.t("reading_the_cards"))
                            .font(.subheadline)
                            .foregroundColor(theme.primaryText.opacity(0.60))
                    }
                } else {
                    Text(vm.reading)
                        .foregroundColor(theme.primaryText)
                        .font(.body)
                        .lineSpacing(5)
                        .multilineTextAlignment(.leading)
                }

                if !vm.reading.isEmpty {
                    Text(loc.t("tarot_tomorrow_note"))
                        .font(.caption2)
                        .tracking(0.5)
                        .foregroundColor(theme.primaryText.opacity(0.32))
                        .multilineTextAlignment(.center)
                        .padding(.top, 4)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
    }

    // MARK: Backdrop

    private var cardBackdrop: some View {
        RadialGradient(
            colors: [
                Color(red: 0.98, green: 0.90, blue: 0.74).opacity(0.20),
                Color(red: 0.98, green: 0.90, blue: 0.74).opacity(0.06),
                .clear
            ],
            center: .center,
            startRadius: 20,
            endRadius: 190
        )
        .blur(radius: 6)
    }

    // MARK: Loading & Error

    private var initialLoadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(1.4)
            Text(loc.t("drawing_your_card"))
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.70))
        }
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Text("⚠️").font(.system(size: 48))
            Text(message)
                .foregroundColor(.red)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Button(loc.t("button_try_again")) {
                Task { await vm.loadReading(language: loc.language) }
            }
            .padding(.horizontal, 28).padding(.vertical, 12)
            .background(theme.primaryButtonBg)
            .foregroundColor(theme.primaryButtonText)
            .cornerRadius(12)
        }
        .padding()
    }

    // MARK: Helpers

    private var todayLabel: String {
        let f = DateFormatter()
        f.locale = loc.language.locale
        f.setLocalizedDateFormatFromTemplate("EEEE, MMMM d")
        return f.string(from: Date()).uppercased()
    }
}
