//
//  PartnerChartReadingView.swift
//  SoulSign
//
import SwiftUI

struct PartnerChartReadingView: View {
    let personA: UserProfile
    let personB: UserProfile

    @EnvironmentObject var loc: LocalizationManager
    @StateObject private var viewModel = PartnerChartViewModel()
    @Environment(\.colorScheme) private var colorScheme
    private var theme: AppTheme { AppTheme(colorScheme: colorScheme) }

    var body: some View {
        ZStack {
            NightSkyBackground()

            if viewModel.isLoading {
                loadingView
            } else if !viewModel.reading.isEmpty {
                readingView
            } else if let error = viewModel.errorMessage {
                errorView(error)
            }
        }
        .navigationTitle("\(personA.firstName) & \(personB.firstName)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !viewModel.reading.isEmpty {
                ToolbarItem(placement: .navigationBarTrailing) {
                    ShareCardButton(previewTitle: "\(personA.firstName) & \(personB.firstName)") {
                        PartnerShareCard(
                            nameA: personA.firstName,
                            nameB: personB.firstName,
                            reading: viewModel.reading
                        )
                    }
                    .foregroundColor(theme.primaryText)
                }
            }
        }
        .task {
            await viewModel.loadReading(for: personA, and: personB, language: loc.language)
        }
    }

    // MARK: - Sub-views

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(1.4)
            Text(loc.t("partner_reading_loading"))
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.70))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }

    private var readingView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                pairHeader

                Text(viewModel.reading)
                    .foregroundColor(theme.primaryText)
                    .font(.body)
                    .lineSpacing(5)

                Button {
                    Task {
                        await viewModel.regenerate(for: personA, and: personB, language: loc.language)
                    }
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
            .frame(maxWidth: 700, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
    }

    private var pairHeader: some View {
        HStack(spacing: 16) {
            avatar(personA)
            Text("♥")
                .font(.system(size: 22))
                .foregroundColor(.pink.opacity(0.75))
            avatar(personB)
            Spacer()
        }
    }

    private func avatar(_ p: UserProfile) -> some View {
        VStack(spacing: 6) {
            Circle()
                .fill(LinearGradient(
                    colors: [Color(hue: 0.75, saturation: 0.55, brightness: 0.65),
                             Color(hue: 0.65, saturation: 0.65, brightness: 0.50)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ))
                .frame(width: 50, height: 50)
                .overlay(
                    Text(p.initials)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                )
            Text(p.firstName)
                .font(.caption)
                .foregroundColor(theme.primaryText.opacity(0.80))
                .lineLimit(1)
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
                Task {
                    await viewModel.loadReading(for: personA, and: personB, language: loc.language)
                }
            }
            .padding(.horizontal, 28).padding(.vertical, 12)
            .background(theme.primaryButtonBg)
            .foregroundColor(theme.primaryButtonText)
            .cornerRadius(12)
        }
        .padding()
    }
}
