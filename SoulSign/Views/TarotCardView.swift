//
//  TarotCardView.swift
//  SoulSign
//
import SwiftUI

// MARK: - Card Face (real 1909 Rider-Waite-Smith scan, public domain)

struct TarotCardFace: View {
    let card: TarotCard

    var body: some View {
        Image(card.imageName)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(.white.opacity(0.25), lineWidth: 0.8)
            )
    }
}

// MARK: - Main View

struct TarotCardView: View {
    @StateObject private var vm = TarotViewModel()
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
        .navigationTitle("Tarot Today")
        .navigationBarTitleDisplayMode(.inline)
        .task { await vm.loadReading() }
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
                    .shadow(color: .black.opacity(0.35), radius: 18, x: 0, y: 10)
                    .shadow(color: Color(red: 1.0, green: 0.85, blue: 0.55).opacity(0.30), radius: 30)

                if vm.isLoading {
                    HStack(spacing: 12) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white.opacity(0.7)))
                        Text("Reading the cards...")
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
                    Text("A new card rises tomorrow at midnight.")
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

    // MARK: Loading & Error

    private var initialLoadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(1.4)
            Text("Drawing your card...")
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
            Button("Try Again") {
                Task { await vm.loadReading() }
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
        f.dateFormat = "EEEE, MMMM d"
        return f.string(from: Date()).uppercased()
    }
}
