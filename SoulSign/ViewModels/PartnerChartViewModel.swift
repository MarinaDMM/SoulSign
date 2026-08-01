//
//  PartnerChartViewModel.swift
//  SoulSign
//
import Foundation

@MainActor
final class PartnerChartViewModel: ObservableObject {
    @Published var reading: String = ""
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let claude: ClaudeService
    private let defaults: UserDefaults
    private let cachePrefix = "partner_reading_v1"

    /// Injectable for tests; defaults to production behaviour.
    init(claude: ClaudeService = ClaudeService(), defaults: UserDefaults = .standard) {
        self.claude = claude
        self.defaults = defaults
    }

    /// Cache key is order-independent, so (A,B) and (B,A) share one reading.
    func cacheKey(_ a: UserProfile, _ b: UserProfile, language: AppLanguage) -> String {
        let ids = [a.id.uuidString, b.id.uuidString].sorted()
        return "\(cachePrefix).\(ids[0])_\(ids[1]).\(language.rawValue)"
    }

    func loadReading(for a: UserProfile, and b: UserProfile, language: AppLanguage) async {
        let key = cacheKey(a, b, language: language)
        if let cached = defaults.string(forKey: key), !cached.isEmpty {
            reading = cached
            return
        }
        await generate(for: a, and: b, language: language)
    }

    func regenerate(for a: UserProfile, and b: UserProfile, language: AppLanguage) async {
        reading = ""
        await generate(for: a, and: b, language: language)
    }

    private func generate(for a: UserProfile, and b: UserProfile, language: AppLanguage) async {
        isLoading = true
        errorMessage = nil

        let prompt = Self.buildPrompt(a: a, b: b, language: language)
        do {
            let text = try await claude.send(messages: [ChatMessage(role: "user", content: prompt)])
            reading = text
            defaults.set(text, forKey: cacheKey(a, b, language: language))
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    /// Exposed for testing so prompt rules can be asserted without a network call.
    static func buildPrompt(a: UserProfile, b: UserProfile, language: AppLanguage) -> String {
        let df = DateFormatter(); df.dateFormat = "yyyy-MM-dd"
        let tf = DateFormatter(); tf.dateFormat = "HH:mm"

        func line(_ p: UserProfile) -> String {
            var s = "\(p.name), born \(df.string(from: p.birthDate)) at \(tf.string(from: p.birthTime)) in \(p.birthPlace)"
            if let c = p.coordinates {
                s += " (\(c.latitude), \(c.longitude))"
            }
            return s
        }

        let languageLine = language == .en ? "" :
            "\n• Write the entire reading in \(language.englishName). Every sentence must be in \(language.englishName), not English."

        return """
        You are a sharp, poetic astrologer writing a synastry reading, the astrology of a relationship between two people.

        Person one: \(line(a))
        Person two: \(line(b))

        Write about what happens between these two charts: where they meet easily, where they grate, what each person quietly asks of the other, and what this pairing is actually for.

        Rules, follow every one:\(languageLine)
        • Plain prose only. No markdown, no headers, no bullet points, no asterisks. Just flowing paragraphs. Never use the em dash character, it reads as machine written. Use commas, periods, or line breaks instead.
        • 4 paragraphs maximum.
        • Name both people by their first names, \(a.firstName) and \(b.firstName), throughout, not "person one," "the first chart," "you two," or "between you." Write "\(a.firstName) meets \(b.firstName) easily here" rather than "you two meet easily here."
        • Intimate, a little mysterious, warm but never sentimental.
        • Keep all words as words. Occasionally place a glyph or emoji right after a word to accent it, not to replace it. For example "her Moon 🌙 in Cancer ♋ softens." Planet glyphs: ☉ ☽ ☿ ♀ ♂ ♃ ♄. Sign glyphs: ♈♉♊♋♌♍♎♏♐♑♒♓. One or two per paragraph at most.
        • Be honest about friction as well as harmony. A reading that is only flattering is not useful.
        • No closing offers, no questions, no AI references. End on one quiet sentence that lingers.
        """
    }
}
