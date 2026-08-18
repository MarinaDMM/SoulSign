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
    @Published var isRedrawnToday = false
    @Published var errorMessage: String?
    @Published var historyEntries: [(dateKey: String, card: TarotCard, entry: TarotHistoryEntry)] = []
    /// Today's private reflection draft, bound directly to the on-screen editor.
    @Published var reflectionDraft: String = ""

    private let claude: ClaudeService
    private let store: TarotHistoryStore

    init(claude: ClaudeService = ClaudeService(), store: TarotHistoryStore = TarotHistoryStore()) {
        self.claude = claude
        self.store = store
    }

    func loadReading(language: AppLanguage) async {
        let today = Date()
        if let existing = store.entry(for: today),
           existing.lang == language.rawValue,
           let existingCard = TarotDeck.cards.first(where: { $0.id == existing.cardId }) {
            self.card = existingCard
            self.reading = existing.reading
            self.isRedrawnToday = existing.isRedraw
            self.reflectionDraft = existing.reflection ?? ""
            return
        }
        await generate(card: TarotDeck.cardForToday(), language: language, isRedraw: false)
    }

    /// Plus-only: replaces today's card with a different random one and
    /// generates a fresh reading, overwriting today's history entry.
    func redraw(language: AppLanguage) async {
        let next = Self.pickRedrawCard(excluding: card.id)
        await generate(card: next, language: language, isRedraw: true)
    }

    func loadHistory() {
        historyEntries = store.allSorted().compactMap { key, entry in
            guard let matchedCard = TarotDeck.cards.first(where: { $0.id == entry.cardId }) else { return nil }
            return (dateKey: key, card: matchedCard, entry: entry)
        }
    }

    private func generate(card: TarotCard, language: AppLanguage, isRedraw: Bool) async {
        self.card = card
        isLoading = true
        errorMessage = nil

        let prompt = Self.buildPrompt(card: card, language: language, dateLabel: Self.fullDateLabel(language: language))

        do {
            let text = try await claude.send(messages: [ChatMessage(role: "user", content: prompt)])
            self.reading = text
            self.isRedrawnToday = isRedraw
            // A redraw replaces the card and reading, but a reflection the
            // user already wrote for today belongs to the day, not the draw,
            // so it must survive.
            let existingReflection = store.entry(for: Date())?.reflection
            store.save(TarotHistoryEntry(cardId: card.id, reading: text, lang: language.rawValue,
                                         isRedraw: isRedraw, reflection: existingReflection),
                      for: Date())
            self.reflectionDraft = existingReflection ?? ""
        } catch {
            self.errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    /// Saves a private reflection for today. Not shared, not exported.
    func saveReflection(_ text: String, language: AppLanguage) {
        saveReflection(text, language: language, for: Date())
    }

    /// Saves a private reflection for an arbitrary past day (used when
    /// editing from History) and refreshes the history list so the change
    /// is visible immediately.
    func saveReflection(_ text: String, language: AppLanguage, dateKey: String) {
        guard let date = TarotHistoryStore.date(fromDayKey: dateKey) else { return }
        saveReflection(text, language: language, for: date)
        loadHistory()
    }

    private func saveReflection(_ text: String, language: AppLanguage, for date: Date) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        var entry = store.entry(for: date) ?? TarotHistoryEntry(
            cardId: card.id, reading: reading, lang: language.rawValue, isRedraw: isRedrawnToday, reflection: nil
        )
        entry.reflection = trimmed.isEmpty ? nil : trimmed
        store.save(entry, for: date)
        if TarotHistoryStore.dayKey(for: date) == TarotHistoryStore.dayKey(for: Date()) {
            reflectionDraft = text
        }
    }

    /// Picks a card other than `cardID`. Pure and deterministic-to-test:
    /// the loop structurally guarantees the result never equals the exclusion.
    static func pickRedrawCard(excluding cardID: Int) -> TarotCard {
        var candidate = TarotDeck.cards.randomElement()!
        while candidate.id == cardID {
            candidate = TarotDeck.cards.randomElement()!
        }
        return candidate
    }

    /// Exposed for testing so prompt rules can be asserted without a network call.
    static func buildPrompt(card: TarotCard, language: AppLanguage, dateLabel: String) -> String {
        let languageLine = language == .en ? "" :
            "\nWrite the entire reading in \(language.englishName). Every sentence must be in \(language.englishName), not English.\n"

        return """
        Today is \(dateLabel). The tarot card drawn for this day is "\(card.name)" (\(card.arcanaLabel)).

        Traditional Rider-Waite-Smith upright meaning of this card: \(card.rwsMeaning)
        \(languageLine)
        Write a tarot reading for today, grounded specifically in that traditional meaning above, not a generic horoscope.

        Rules, follow every one:
        • Flowing prose, 3 paragraphs maximum. No markdown, no headers, no bullet points, no numbered lists.
        • Never use the em dash character. Use commas and periods instead.
        • Make the card itself the subject of most sentences, by name, for example "\(card.name) leaps without looking" or "\(card.name) rules through logic," rather than making "you" the subject. Refer to the card by name at least two or three times across the reading, not only in the opening.
        • Open by grounding the reading in what this specific card traditionally represents, then carry that meaning into how it might show up today. It is fine to address the reader occasionally, but the card's name should carry the sentence, not a generic "you."
        • Place an emoji or glyph right after a word occasionally to accent it (🌙 🔥 ✨ 🌊 💫 🕯️ ⭐). Two or three total across the whole reading, only where it adds something real.
        • Mystic and intimate, like quiet insight from someone who sees clearly.
        • End on one sentence that stays with the reader after they close the screen.
        • No sign-offs, no questions, no AI references.
        """
    }

    private static func fullDateLabel(language: AppLanguage) -> String {
        let f = DateFormatter()
        f.locale = language.locale
        f.dateStyle = .full
        return f.string(from: Date())
    }
}
