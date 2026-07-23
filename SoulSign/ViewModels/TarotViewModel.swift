//
//  TarotViewModel.swift
//  SoulSign
//
import Foundation

@MainActor
final class TarotViewModel: ObservableObject {
    @Published var card: TarotCard = TarotDeck.cardForToday()
    @Published var reading: String = ""
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let claude = ClaudeService()
    private let cacheKey = "tarot_daily_cache_v2"

    func loadReading() async {
        let today = todayKey()

        // Return cached reading if same card, same day
        if let cached = UserDefaults.standard.dictionary(forKey: cacheKey),
           cached["date"] as? String == today,
           let cardId   = cached["cardId"]  as? Int,
           let cachedText = cached["reading"] as? String,
           let cachedCard = TarotDeck.cards.first(where: { $0.id == cardId }) {
            self.card    = cachedCard
            self.reading = cachedText
            return
        }

        let todayCard = TarotDeck.cardForToday()
        self.card  = todayCard
        isLoading  = true
        errorMessage = nil

        let prompt = """
        Today is \(fullDateLabel()). The tarot card drawn for this day is "\(todayCard.name)" (\(todayCard.arcanaLabel)).

        Traditional Rider-Waite-Smith upright meaning of this card: \(todayCard.rwsMeaning)

        Write a tarot reading for today, grounded specifically in that traditional meaning above, not a generic horoscope. Speak directly to the reader as "you."

        Rules, follow every one:
        • Flowing prose, 3 paragraphs maximum. No markdown, no headers, no bullet points, no numbered lists.
        • Never use the em dash character. Use commas and periods instead.
        • Open by grounding the reading in what this specific card traditionally represents, then carry that meaning into how it might show up today.
        • Place an emoji or glyph right after a word occasionally to accent it (🌙 🔥 ✨ 🌊 💫 🕯️ ⭐). Two or three total across the whole reading, only where it adds something real.
        • Mystic and intimate, like quiet insight from someone who sees clearly.
        • End on one sentence that stays with the reader after they close the screen.
        • No sign-offs, no questions, no AI references.
        """

        do {
            let text = try await claude.send(messages: [ChatMessage(role: "user", content: prompt)])
            self.reading = text
            UserDefaults.standard.set(
                ["date": today, "cardId": todayCard.id, "reading": text],
                forKey: cacheKey
            )
        } catch {
            self.errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    private func todayKey() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }

    private func fullDateLabel() -> String {
        let f = DateFormatter()
        f.dateStyle = .full
        return f.string(from: Date())
    }
}
