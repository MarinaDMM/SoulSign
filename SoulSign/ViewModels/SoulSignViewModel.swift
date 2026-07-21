//
//  SoulSignViewModel.swift
//  SoulSign
//
//  Created by Marina Dedikova on 09/05/2025.
//

import Foundation
import CoreLocation

@MainActor
final class SoulSignViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var chartResult: String = ""
    @Published var errorMessage: String?
    @Published var birthDate: Date?

    private let claudeService = ClaudeService()

    func generateChart(for profile: UserProfile) async {
        await generateChart(
            fullName: profile.name,
            birthDate: profile.birthDate,
            birthTime: profile.birthTime,
            birthPlace: profile.birthPlace,
            coordinates: profile.coordinates
        )
    }

    func generateChart(
        fullName: String,
        birthDate: Date,
        birthTime: Date,
        birthPlace: String,
        coordinates: CLLocationCoordinate2D?
    ) async {
        self.birthDate = birthDate
        isLoading = true
        errorMessage = nil

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

        let prompt = """
        You are a sharp, poetic astrologer. Write a natal chart reading for \(fullName), born \(dateString) at \(timeString) in \(birthPlace)\(coordNote).

        Rules — follow every one:
        • Plain prose only. No markdown, no headers, no bullet points, no asterisks, no hashtags. Just flowing paragraphs. Never use the em dash "—" — it reads as machine-written. Use commas, periods, or line breaks instead.
        • Keep it tight — 4 paragraphs maximum. Each paragraph should feel alive, not exhaustive.
        • Keep all words as words. Occasionally place a glyph or emoji right after a word to accent it visually, not to replace it. For example: "your Sun ☉ in Scorpio ♏ burns quietly" or "the Moon 🌙 here asks for stillness." Use this sparingly, only where it adds something. Planet glyphs: ☉ ☽ ☿ ♀ ♂ ♃ ♄. Sign glyphs: ♈♉♊♋♌♍♎♏♐♑♒♓. Occasional emoji: 🌙 🔥 ✨ 🌊 💫 🕯️ — one or two per paragraph at most.
        • Make it feel like a secret someone left for \(fullName) specifically. Intriguing details they'll want to sit with, not a summary they'll skim.
        • Speak directly as "you." Intimate, a little mysterious, warm but never sentimental.
        • No closing offers, no questions, no AI references. End on one quiet sentence that lingers.
        """

        let messages = [
            ChatMessage(role: "user", content: prompt)
        ]

        do {
            let response = try await claudeService.send(messages: messages)
            self.chartResult = response
        } catch {
            self.errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}

