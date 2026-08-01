//
//  SoulSignViewModel.swift
//  SoulSign
//
//  Created by Marina Dedikova on 09/05/2025.
//

import Foundation
import CoreLocation

enum ReadingDepth: String, Codable {
    case standard
    case deep
}

@MainActor
final class SoulSignViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var chartResult: String = ""
    @Published var errorMessage: String?
    @Published var birthDate: Date?

    private let claudeService: ClaudeService

    init(claudeService: ClaudeService = ClaudeService()) {
        self.claudeService = claudeService
    }

    func generateChart(for profile: UserProfile, language: AppLanguage, depth: ReadingDepth = .standard) async {
        await generateChart(
            fullName: profile.name,
            birthDate: profile.birthDate,
            birthTime: profile.birthTime,
            birthPlace: profile.birthPlace,
            coordinates: profile.coordinates,
            language: language,
            depth: depth
        )
    }

    func generateChart(
        fullName: String,
        birthDate: Date,
        birthTime: Date,
        birthPlace: String,
        coordinates: CLLocationCoordinate2D?,
        language: AppLanguage,
        depth: ReadingDepth = .standard
    ) async {
        self.birthDate = birthDate
        isLoading = true
        errorMessage = nil

        let prompt = Self.buildPrompt(
            fullName: fullName, birthDate: birthDate, birthTime: birthTime,
            birthPlace: birthPlace, coordinates: coordinates, language: language, depth: depth
        )

        do {
            let response = try await claudeService.send(messages: [ChatMessage(role: "user", content: prompt)])
            self.chartResult = response
        } catch {
            self.errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    /// Exposed for testing so prompt rules can be asserted without a network call.
    static func buildPrompt(
        fullName: String, birthDate: Date, birthTime: Date, birthPlace: String,
        coordinates: CLLocationCoordinate2D?, language: AppLanguage, depth: ReadingDepth
    ) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"

        let dateString = dateFormatter.string(from: birthDate)
        let timeString = timeFormatter.string(from: birthTime)

        var coordNote = ""
        if let coord = coordinates {
            coordNote = "\nCoordinates: \(coord.latitude), \(coord.longitude)"
        }

        let languageLine = language == .en ? "" : "\n• Write the entire reading in \(language.englishName). Every sentence must be in \(language.englishName), not English."

        let depthInstruction: String
        switch depth {
        case .standard:
            depthInstruction = "• Keep it tight, 4 paragraphs maximum. Each paragraph should feel alive, not exhaustive."
        case .deep:
            depthInstruction = """
            • This is the deep reading: write 8 to 9 unhurried paragraphs. Move through distinct facets of \(fullName)'s chart in turn: core identity and Sun sign, the emotional interior and Moon, how they love and connect with others, work and the shape of their ambition, the friction points and what tests them, a gift they may not fully see in themselves yet, and where this chart is quietly heading. Let each paragraph breathe as its own thought before moving to the next. Do not label, number, or title the sections; let the prose itself carry the shift from one facet to the next.
            """
        }

        return """
        You are a sharp, poetic astrologer. Write a natal chart reading for \(fullName), born \(dateString) at \(timeString) in \(birthPlace)\(coordNote).

        Rules, follow every one:\(languageLine)
        • Plain prose only. No markdown, no headers, no bullet points, no asterisks, no hashtags. Just flowing paragraphs. Never use the em dash character, it reads as machine written. Use commas, periods, or line breaks instead.
        \(depthInstruction)
        • Keep all words as words. Occasionally place a glyph or emoji right after a word to accent it visually, not to replace it. For example: "your Sun ☉ in Scorpio ♏ burns quietly" or "the Moon 🌙 here asks for stillness." Use this sparingly, only where it adds something. Planet glyphs: ☉ ☽ ☿ ♀ ♂ ♃ ♄. Sign glyphs: ♈♉♊♋♌♍♎♏♐♑♒♓. Occasional emoji: 🌙 🔥 ✨ 🌊 💫 🕯️, one or two per paragraph at most.
        • Make it feel like a secret someone left for \(fullName) specifically. Intriguing details they'll want to sit with, not a summary they'll skim.
        • Speak directly as "you." Intimate, a little mysterious, warm but never sentimental.
        • No closing offers, no questions, no AI references. End on one quiet sentence that lingers.
        """
    }
}
