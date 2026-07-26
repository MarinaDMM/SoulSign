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

    /// Renders a view into a single-page PDF, drawing directly into the PDF's
    /// CGContext (not a flattened raster), so the page stays crisp regardless
    /// of length.
    static func renderPDF<Content: View>(_ view: Content, pageSize: CGSize) -> Data? {
        let renderer = ImageRenderer(content: view.frame(width: pageSize.width, height: pageSize.height))
        let pdfRenderer = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: pageSize))
        return pdfRenderer.pdfData { context in
            context.beginPage()
            renderer.render { _, drawInContext in
                drawInContext(context.cgContext)
            }
        }
    }

    /// Precisely measures the height a block of text will need, so a PDF
    /// page can be sized to fit the full, untruncated text with no clipping.
    static func measuredTextHeight(_ text: String, fontName: String, fontSize: CGFloat, lineSpacing: CGFloat, width: CGFloat) -> CGFloat {
        let font = UIFont(name: fontName, size: fontSize) ?? .systemFont(ofSize: fontSize)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = lineSpacing
        let attrs: [NSAttributedString.Key: Any] = [.font: font, .paragraphStyle: paragraphStyle]
        let bounding = (text as NSString).boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: attrs,
            context: nil
        )
        return ceil(bounding.height)
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

    static func writeTempPDF(_ data: Data, name: String) -> URL? {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(name)-\(UUID().uuidString).pdf")
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
        }
    }
}

/// Takes the first paragraph of a reading and trims it to a card-friendly
/// length, breaking on a word boundary rather than mid-word.
private func shareExcerpt(from text: String, maxChars: Int) -> String {
    let firstParagraph = text.components(separatedBy: "\n\n").first ?? text
    let trimmed = firstParagraph.trimmingCharacters(in: .whitespacesAndNewlines)
    guard trimmed.count > maxChars else { return trimmed }
    let cutIndex = trimmed.index(trimmed.startIndex, offsetBy: maxChars)
    let truncated = trimmed[..<cutIndex]
    if let lastSpace = truncated.lastIndex(of: " ") {
        return String(truncated[..<lastSpace]) + "…"
    }
    return String(truncated) + "…"
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

// MARK: - Natal chart PDF share

/// Layout constants shared between the PDF content view and its height
/// calculation, so the two never drift out of sync.
@MainActor
private enum NatalPDFLayout {
    static let pageWidth: CGFloat = 900
    static let topPadding: CGFloat = 80
    static let titleFontSize: CGFloat = 38
    static let titleBlockHeight: CGFloat = 130   // generous, covers 1-2 line names
    static let chartWidth: CGFloat = 680
    static let chartHeight: CGFloat = 740
    static let chartBottomSpacing: CGFloat = 70
    static let textSideMargin: CGFloat = 90
    static let textFontName = "Georgia"
    static let textFontSize: CGFloat = 27
    static let textLineSpacing: CGFloat = 11
    static let textBottomSpacing: CGFloat = 80
    static let footerHeight: CGFloat = 140
    static let bottomPadding: CGFloat = 90

    static var textWidth: CGFloat { pageWidth - 2 * textSideMargin }

    static func pageHeight(forReading reading: String) -> CGFloat {
        let textHeight = ShareCardRenderer.measuredTextHeight(
            reading, fontName: textFontName, fontSize: textFontSize,
            lineSpacing: textLineSpacing, width: textWidth
        )
        return topPadding + titleBlockHeight + chartHeight + chartBottomSpacing
             + textHeight + textBottomSpacing + footerHeight + bottomPadding
    }
}

struct NatalChartPDFPage: View {
    let firstName: String
    let matrix: DestinyMatrix
    let reading: String
    @EnvironmentObject var loc: LocalizationManager

    var body: some View {
        ZStack(alignment: .top) {
            ShareCardBackground()
            VStack(spacing: 0) {
                Spacer().frame(height: NatalPDFLayout.topPadding)

                Text(loc.t("reading_title_of", firstName))
                    .font(.system(size: NatalPDFLayout.titleFontSize, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 60)
                    .frame(height: NatalPDFLayout.titleBlockHeight)

                NatalChartView(matrix: matrix)
                    .frame(width: NatalPDFLayout.chartWidth, height: NatalPDFLayout.chartHeight)
                    .padding(.bottom, NatalPDFLayout.chartBottomSpacing)

                Text(reading)
                    .font(.custom(NatalPDFLayout.textFontName, size: NatalPDFLayout.textFontSize))
                    .foregroundColor(.white.opacity(0.92))
                    .multilineTextAlignment(.leading)
                    .lineSpacing(NatalPDFLayout.textLineSpacing)
                    .frame(width: NatalPDFLayout.textWidth, alignment: .leading)
                    .padding(.bottom, NatalPDFLayout.textBottomSpacing)

                ShareCardFooter()
            }
        }
        .frame(width: NatalPDFLayout.pageWidth)
    }
}

struct NatalChartPDFShareButton: View {
    let firstName: String
    let matrix: DestinyMatrix
    let reading: String
    @EnvironmentObject var loc: LocalizationManager
    @State private var fileURL: URL?
    @State private var previewImage: UIImage?

    var body: some View {
        Group {
            if let fileURL, let previewImage {
                ShareLink(
                    item: fileURL,
                    preview: SharePreview(loc.t("reading_title_of", firstName), image: Image(uiImage: previewImage))
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
        let pageHeight = NatalPDFLayout.pageHeight(forReading: reading)
        let content = NatalChartPDFPage(firstName: firstName, matrix: matrix, reading: reading)
            .environmentObject(loc)

        guard let pdfData = ShareCardRenderer.renderPDF(
            content, pageSize: CGSize(width: NatalPDFLayout.pageWidth, height: pageHeight)
        ) else { return }
        fileURL = ShareCardRenderer.writeTempPDF(pdfData, name: "natal-chart")

        // A shorter raster crop (top portion) as the share-sheet thumbnail.
        let previewHeight = min(pageHeight, 1400)
        previewImage = ShareCardRenderer.render(
            content, size: CGSize(width: NatalPDFLayout.pageWidth, height: previewHeight)
        )
    }
}

// MARK: - Tarot share card

struct TarotShareCard: View {
    let card: TarotCard
    let reading: String
    let dateLabel: String

    private static let cardAspectRatio: CGFloat = 750.0 / 1298.0

    var body: some View {
        ZStack {
            ShareCardBackground()
            VStack(spacing: 0) {
                Spacer(minLength: 80)

                Text(dateLabel)
                    .font(.system(size: 22, weight: .medium))
                    .tracking(3)
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.bottom, 40)

                Image(card.imageName)
                    .resizable()
                    .aspectRatio(Self.cardAspectRatio, contentMode: .fit)
                    .frame(width: 340)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .strokeBorder(.white.opacity(0.25), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.4), radius: 20, y: 10)
                    .padding(.bottom, 46)

                Text(card.name.uppercased())
                    .font(.system(size: 34, weight: .bold))
                    .tracking(2)
                    .foregroundColor(.white)
                    .padding(.bottom, 34)

                Text(shareExcerpt(from: reading, maxChars: 260))
                    .font(.system(size: 28, weight: .medium, design: .serif))
                    .foregroundColor(.white.opacity(0.92))
                    .multilineTextAlignment(.center)
                    .lineSpacing(8)
                    .padding(.horizontal, 100)

                Spacer(minLength: 60)

                ShareCardFooter()
                    .padding(.bottom, 90)
            }
        }
        .frame(width: 1080, height: 1920)
        .clipped()
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
