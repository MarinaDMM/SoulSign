//
//  TarotCardView.swift
//  SoulSign
//
import SwiftUI

// MARK: - Card Face

struct TarotCardFace: View {
    let card: TarotCard

    private var gradient: LinearGradient {
        let h = card.hue
        return LinearGradient(
            stops: [
                .init(color: Color(hue: h,        saturation: 0.65, brightness: 0.32), location: 0),
                .init(color: Color(hue: h,        saturation: 0.55, brightness: 0.20), location: 0.55),
                .init(color: Color(hue: h + 0.04, saturation: 0.45, brightness: 0.12), location: 1),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var glowColor: Color {
        Color(hue: card.hue, saturation: 0.9, brightness: 0.85)
    }

    // Deterministic star positions per card
    private var stars: [(x: Double, y: Double, r: Double)] {
        var seed = UInt64(bitPattern: Int64(card.id) &* 1664525 &+ 1013904223)
        func rng() -> Double {
            seed = seed &* 6364136223846793005 &+ 1442695040888963407
            return Double(seed >> 33) / Double(1 << 31)
        }
        return (0..<30).map { _ in (rng(), rng(), rng() * 1.1 + 0.4) }
    }

    var body: some View {
        ZStack {
            // Background gradient
            RoundedRectangle(cornerRadius: 14)
                .fill(gradient)

            // Star texture
            Canvas { ctx, size in
                for star in stars {
                    let r = star.r
                    let rect = CGRect(
                        x: star.x * size.width  - r,
                        y: star.y * size.height - r,
                        width: r * 2, height: r * 2
                    )
                    ctx.fill(Path(ellipseIn: rect), with: .color(.white.opacity(0.15)))
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 14))

            // Inner border
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(.white.opacity(0.18), lineWidth: 0.8)
                .padding(9)

            // Card content
            VStack(spacing: 0) {
                Spacer().frame(height: 20)

                Text(card.numeralString)
                    .font(.system(size: 12, weight: .light, design: .serif))
                    .tracking(3.5)
                    .foregroundColor(.white.opacity(0.50))

                Spacer()

                Text(card.emoji)
                    .font(.system(size: 58))
                    .shadow(color: glowColor.opacity(0.55), radius: 16)

                Spacer()

                Text(card.name.uppercased())
                    .font(.system(size: 10.5, weight: .semibold))
                    .tracking(2.5)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)

                Text(card.arcanaLabel.uppercased())
                    .font(.system(size: 8, weight: .regular))
                    .tracking(1.8)
                    .foregroundColor(.white.opacity(0.42))
                    .padding(.top, 5)

                Spacer().frame(height: 20)
            }
            .padding(.horizontal, 14)

            // Corner ornaments
            VStack {
                HStack {
                    Text("◆").font(.system(size: 7)).foregroundColor(.white.opacity(0.28))
                    Spacer()
                    Text("◆").font(.system(size: 7)).foregroundColor(.white.opacity(0.28))
                }
                Spacer()
                HStack {
                    Text("◆").font(.system(size: 7)).foregroundColor(.white.opacity(0.28))
                    Spacer()
                    Text("◆").font(.system(size: 7)).foregroundColor(.white.opacity(0.28))
                }
            }
            .padding(15)

            // Outer border
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(
                    LinearGradient(
                        colors: [.white.opacity(0.55), .white.opacity(0.10), .white.opacity(0.38)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.2
                )
        }
        .aspectRatio(0.62, contentMode: .fit)
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
                    .shadow(
                        color: Color(hue: vm.card.hue, saturation: 0.8, brightness: 0.6).opacity(0.45),
                        radius: 32
                    )

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
