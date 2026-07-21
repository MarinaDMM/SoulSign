//
//  NatalChartReadingView.swift
//  SoulSign
//
import SwiftUI

struct NatalChartReadingView: View {
    let profile: UserProfile
    @EnvironmentObject var profileStore: ProfileStore
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
        .task { await loadReading() }
    }

    // MARK: - Sub-views

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(1.4)
            Text("Reading \(profile.firstName)'s stars...")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.70))
        }
    }

    private var readingView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("✨ \(profile.firstName)'s Reading")
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
                    Label("Regenerate Reading", systemImage: "arrow.clockwise")
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
            Button("Try Again") {
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
        if let cached = profile.cachedReading, !cached.isEmpty {
            viewModel.chartResult = cached
            viewModel.birthDate   = profile.birthDate
        } else {
            await viewModel.generateChart(for: profile)
            saveReading()
        }
    }

    private func regenerate() async {
        viewModel.chartResult = ""
        await viewModel.generateChart(for: profile)
        saveReading()
    }

    private func saveReading() {
        guard !viewModel.chartResult.isEmpty else { return }
        var updated = profile
        updated.cachedReading = viewModel.chartResult
        updated.readingDate   = Date()
        profileStore.update(updated)
    }
}
