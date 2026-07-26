//
//  NatalChartReadingView.swift
//  SoulSign
//
import SwiftUI

struct NatalChartReadingView: View {
    let profile: UserProfile
    @EnvironmentObject var profileStore: ProfileStore
    @EnvironmentObject var loc: LocalizationManager
    @StateObject private var viewModel = SoulSignViewModel()
    @Environment(\.colorScheme) private var colorScheme
    private var theme: AppTheme { AppTheme(colorScheme: colorScheme) }

    var body: some View {
        ZStack {
            NightSkyBackground()

            if viewModel.isLoading {
                loadingView
            } else if !viewModel.chartResult.isEmpty {
                readingView
            } else if let error = viewModel.errorMessage {
                errorView(error)
            }
        }
        .navigationTitle(profile.firstName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !viewModel.chartResult.isEmpty {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NatalChartPDFShareButton(
                        firstName: profile.firstName,
                        matrix: DestinyMatrix.compute(from: profile.birthDate),
                        reading: viewModel.chartResult
                    )
                    .foregroundColor(theme.primaryText)
                }
            }
        }
        .task { await loadReading() }
    }

    // MARK: - Sub-views

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(1.4)
            Text(loc.t("reading_stars_of", profile.firstName))
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.70))
        }
    }

    private var readingView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(loc.t("reading_title_of", profile.firstName))
                    .font(.title2.bold())
                    .foregroundColor(theme.primaryText)

                NatalChartView(matrix: DestinyMatrix.compute(from: profile.birthDate))
                    .frame(maxWidth: .infinity)

                Text(viewModel.chartResult)
                    .foregroundColor(theme.primaryText)
                    .font(.body)
                    .lineSpacing(5)

                Button {
                    Task { await regenerate() }
                } label: {
                    Label(loc.t("button_regenerate_reading"), systemImage: "arrow.clockwise")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(theme.secondaryButtonBg)
                        .foregroundColor(theme.secondaryButtonText)
                        .cornerRadius(12)
                }
            }
            .padding()
        }
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Text("⚠️").font(.system(size: 48))
            Text(message)
                .foregroundColor(.red)
                .multilineTextAlignment(.center)
            Button(loc.t("button_try_again")) {
                Task { await loadReading() }
            }
            .padding(.horizontal, 28).padding(.vertical, 12)
            .background(theme.primaryButtonBg)
            .foregroundColor(theme.primaryButtonText)
            .cornerRadius(12)
        }
        .padding()
    }

    // MARK: - Logic

    private func loadReading() async {
        if let cached = profile.cachedReading, !cached.isEmpty,
           profile.cachedReadingLanguage == loc.language.rawValue {
            viewModel.chartResult = cached
            viewModel.birthDate   = profile.birthDate
        } else {
            await viewModel.generateChart(for: profile, language: loc.language)
            saveReading()
        }
    }

    private func regenerate() async {
        viewModel.chartResult = ""
        await viewModel.generateChart(for: profile, language: loc.language)
        saveReading()
    }

    private func saveReading() {
        guard !viewModel.chartResult.isEmpty else { return }
        var updated = profile
        updated.cachedReading = viewModel.chartResult
        updated.readingDate   = Date()
        updated.cachedReadingLanguage = loc.language.rawValue
        profileStore.update(updated)
    }
}
