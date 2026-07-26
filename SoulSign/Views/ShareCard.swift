//
//  ShareCard.swift
//  SoulSign
//
//  Branded, shareable image cards for affirmations and natal charts.
//  Rendered off-screen to a PNG so they work with Instagram, TikTok,
//  Facebook, and messaging apps via the native share sheet.
//
import SwiftUI
import UIKit

// MARK: - Rendering helpers

@MainActor
enum ShareCardRenderer {
    static func render<Content: View>(_ view: Content, size: CGSize) -> UIImage? {
        let renderer = ImageRenderer(content: view.frame(width: size.width, height: size.height))
        renderer.scale = 2
        return renderer.uiImage
    }

    static func writeTempPNG(_ image: UIImage, name: String) -> URL? {
        guard let data = image.pngData() else { return nil }
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(name)-\(UUID().uuidString).png")
        do {
            try data.write(to: url)
            return url
        } catch {
            return nil
        }
    }
}

// MARK: - Shared branding

private struct ShareCardBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(hue: 0.70, saturation: 0.55, brightness: 0.16),
                    Color(hue: 0.75, saturation: 0.60, brightness: 0.10),
                    Color(hue: 0.80, saturation: 0.55, brightness: 0.06),
                ],
                startPoint: .top, endPoint: .bottom
            )
            RadialGradient(
                colors: [Color(hue: 0.75, saturation: 0.5, brightness: 0.28).opacity(0.5), .clear],
                center: .init(x: 0.5, y: 0.32), startRadius: 40, endRadius: 520
            )
        }
    }
}

private struct ShareCardFooter: View {
    @EnvironmentObject var loc: LocalizationManager

    var body: some View {
        VStack(spacing: 10) {
            Text("✨ SoulSign")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Text(loc.t("share_tagline"))
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white.opacity(0.65))
            Text("apps.apple.com/app/id6794421639")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.45))
        }
    }
}

// MARK: - Affirmation share card

struct AffirmationShareCard: View {
    let categoryTitle: String   // already includes emoji, e.g. "💰 Finance"
    let text: String

    var body: some View {
        ZStack {
            ShareCardBackground()
            VStack(spacing: 0) {
                Spacer(minLength: 200)

                Text(categoryTitle.uppercased())
                    .font(.system(size: 30, weight: .semibold))
                    .tracking(3)
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.bottom, 50)

                Text("\u{201C}\(text)\u{201D}")
                    .font(.system(size: 48, weight: .medium, design: .serif))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(12)
                    .padding(.horizontal, 90)

                Spacer(minLength: 200)

                ShareCardFooter()
                    .padding(.bottom, 110)
            }
        }
        .frame(width: 1080, height: 1920)
    }
}

// MARK: - Natal chart share card

struct NatalChartShareCard: View {
    let firstName: String
    let matrix: DestinyMatrix
    @EnvironmentObject var loc: LocalizationManager

    var body: some View {
        ZStack {
            ShareCardBackground()
            VStack(spacing: 0) {
                Spacer(minLength: 150)

                Text(loc.t("reading_title_of", firstName))
                    .font(.system(size: 44, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 60)
                    .padding(.bottom, 70)

                NatalChartView(matrix: matrix)
                    .frame(width: 820, height: 900)

                Spacer(minLength: 130)

                ShareCardFooter()
                    .padding(.bottom, 110)
            }
        }
        .frame(width: 1080, height: 1920)
    }
}

// MARK: - Reusable share button

struct ShareCardButton<CardContent: View>: View {
    let fileName: String
    let previewTitle: String
    let card: CardContent
    @EnvironmentObject var loc: LocalizationManager
    @State private var fileURL: URL?
    @State private var renderedImage: UIImage?

    init(fileName: String, previewTitle: String, @ViewBuilder card: () -> CardContent) {
        self.fileName = fileName
        self.previewTitle = previewTitle
        self.card = card()
    }

    var body: some View {
        Group {
            if let fileURL, let renderedImage {
                ShareLink(
                    item: fileURL,
                    preview: SharePreview(previewTitle, image: Image(uiImage: renderedImage))
                ) {
                    Image(systemName: "square.and.arrow.up")
                }
            } else {
                Image(systemName: "square.and.arrow.up")
                    .foregroundColor(.white.opacity(0.25))
            }
        }
        .onAppear {
            if fileURL == nil { generate() }
        }
    }

    private func generate() {
        guard let uiImage = ShareCardRenderer.render(
            card.environmentObject(loc),
            size: CGSize(width: 1080, height: 1920)
        ) else { return }
        renderedImage = uiImage
        fileURL = ShareCardRenderer.writeTempPNG(uiImage, name: fileName)
    }
}
