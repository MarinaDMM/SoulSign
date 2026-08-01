//
//  NatalChartReadingView.swift
//  SoulSign
//
import SwiftUI

struct NatalChartReadingView: View {
    let profile: UserProfile
    @EnvironmentObject var profileStore: ProfileStore
    @EnvironmentObject var loc: LocalizationManager
    @EnvironmentObject var subs: SubscriptionManager
    @StateObject private var viewModel = SoulSignViewModel()
    @Environment(\.colorScheme) private var colorScheme
    private var theme: AppTheme { AppTheme(colorScheme: colorScheme) }

    @State private var depth: ReadingDepth = .standard
    @State private var showPaywall = false

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
        .sheet(isPresented: $showPaywall) {
            NavigationStack {
                PaywallView()
                    .environmentObject(subs)
                    .environmentObject(loc)
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

                depthPicker

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

    private var depthPicker: some View {
        HStack(spacing: 10) {
            depthButton(.standard, label: loc.t("reading_standard"), locked: false)
            depthButton(.deep, label: loc.t("reading_deep"), locked: !subs.isPlus)
        }
    }

    private func depthButton(_ target: ReadingDepth, label: String, locked: Bool) -> some View {
        let isSelected = depth == target
        return Button {
            if locked {
                showPaywall = true
            } else if depth != target {
                depth = target
                Task { await loadReading() }
            }
        } label: {
            HStack(spacing: 5) {
                Text(label)
                if locked {
                    Image(systemName: "lock.fill").font(.caption2)
                }
            }
            .font(.subheadline.weight(isSelected ? .semibold : .regular))
            .padding(.horizontal, 14).padding(.vertical, 8)
            .background(
                Capsule().fill(isSelected ? .white.opacity(0.20) : .white.opacity(0.07))
            )
            .overlay(
                Capsule().strokeBorder(isSelected ? .white.opacity(0.5) : .white.opacity(0.12), lineWidth: 1)
            )
            .foregroundColor(theme.primaryText.opacity(isSelected ? 1 : 0.75))
        }
        .buttonStyle(.plain)
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
        if let cached = cachedReading(for: depth), !cached.isEmpty,
           cachedLanguage(for: depth) == loc.language.rawValue {
            viewModel.chartResult = cached
            viewModel.birthDate   = profile.birthDate
        } else {
            viewModel.chartResult = ""
            await viewModel.generateChart(for: profile, language: loc.language, depth: depth)
            saveReading()
        }
    }

    private func regenerate() async {
        viewModel.chartResult = ""
        await viewModel.generateChart(for: profile, language: loc.language, depth: depth)
        saveReading()
    }

    private func cachedReading(for depth: ReadingDepth) -> String? {
        depth == .standard ? profile.cachedReading : profile.cachedDeepReading
    }

    private func cachedLanguage(for depth: ReadingDepth) -> String? {
        depth == .standard ? profile.cachedReadingLanguage : profile.cachedDeepReadingLanguage
    }

    private func saveReading() {
        guard !viewModel.chartResult.isEmpty else { return }
        var updated = profile
        switch depth {
        case .standard:
            updated.cachedReading = viewModel.chartResult
            updated.readingDate   = Date()
            updated.cachedReadingLanguage = loc.language.rawValue
        case .deep:
            updated.cachedDeepReading = viewModel.chartResult
            updated.deepReadingDate   = Date()
            updated.cachedDeepReadingLanguage = loc.language.rawValue
        }
        profileStore.update(updated)
    }
}
