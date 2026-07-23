//
//  TarotCard.swift
//  SoulSign
//
import Foundation

struct TarotCard: Identifiable, Hashable {
    let id: Int
    let name: String
    let emoji: String
    let hue: Double        // colour identity (0-1)
    let arcanaLabel: String
    let numeralString: String
    let keywords: String
    let imageName: String  // Rider-Waite-Smith (1909) scan, Assets.xcassets/TarotCards
}

// MARK: - Deck

enum TarotDeck {
    static let cards: [TarotCard] = majorArcana + wandsArcana + cupsArcana + swordsArcana + pentaclesArcana

    // Returns the same card for any given calendar day
    static func cardForToday() -> TarotCard {
        let cal = Calendar.current
        let day  = cal.ordinality(of: .day, in: .year, for: Date()) ?? 1
        let year = cal.component(.year, from: Date())
        let idx  = ((day * 13) + (year % cards.count)) % cards.count
        return cards[idx]
    }

    // MARK: Major Arcana
    private static let majorArcana: [TarotCard] = [
        .init(id: 0,  name: "The Fool",           emoji: "🌬️", hue: 0.58, arcanaLabel: "Major Arcana",  numeralString: "0",    keywords: "beginnings, spontaneity, leap of faith",       imageName: "tarot_major_fool"),
        .init(id: 1,  name: "The Magician",        emoji: "🪄",  hue: 0.12, arcanaLabel: "Major Arcana",  numeralString: "I",    keywords: "willpower, skill, manifestation",               imageName: "tarot_major_magician"),
        .init(id: 2,  name: "The High Priestess",  emoji: "🌙",  hue: 0.68, arcanaLabel: "Major Arcana",  numeralString: "II",   keywords: "intuition, mystery, subconscious",              imageName: "tarot_major_high_priestess"),
        .init(id: 3,  name: "The Empress",         emoji: "🌹",  hue: 0.33, arcanaLabel: "Major Arcana",  numeralString: "III",  keywords: "abundance, fertility, nurturing",               imageName: "tarot_major_empress"),
        .init(id: 4,  name: "The Emperor",         emoji: "🏔️", hue: 0.03, arcanaLabel: "Major Arcana",  numeralString: "IV",   keywords: "authority, structure, stability",               imageName: "tarot_major_emperor"),
        .init(id: 5,  name: "The Hierophant",      emoji: "📿",  hue: 0.28, arcanaLabel: "Major Arcana",  numeralString: "V",    keywords: "tradition, wisdom, guidance",                   imageName: "tarot_major_hierophant"),
        .init(id: 6,  name: "The Lovers",          emoji: "💞",  hue: 0.93, arcanaLabel: "Major Arcana",  numeralString: "VI",   keywords: "love, choice, alignment",                       imageName: "tarot_major_lovers"),
        .init(id: 7,  name: "The Chariot",         emoji: "🏆",  hue: 0.60, arcanaLabel: "Major Arcana",  numeralString: "VII",  keywords: "victory, control, determination",               imageName: "tarot_major_chariot"),
        .init(id: 8,  name: "Strength",            emoji: "🦁",  hue: 0.07, arcanaLabel: "Major Arcana",  numeralString: "VIII", keywords: "courage, patience, inner power",                imageName: "tarot_major_strength"),
        .init(id: 9,  name: "The Hermit",          emoji: "🕯️", hue: 0.25, arcanaLabel: "Major Arcana",  numeralString: "IX",   keywords: "solitude, introspection, guidance",             imageName: "tarot_major_hermit"),
        .init(id: 10, name: "Wheel of Fortune",    emoji: "♾️",  hue: 0.10, arcanaLabel: "Major Arcana",  numeralString: "X",    keywords: "cycles, destiny, turning point",                imageName: "tarot_major_wheel_of_fortune"),
        .init(id: 11, name: "Justice",             emoji: "⚖️",  hue: 0.55, arcanaLabel: "Major Arcana",  numeralString: "XI",   keywords: "fairness, truth, cause and effect",             imageName: "tarot_major_justice"),
        .init(id: 12, name: "The Hanged Man",      emoji: "🌀",  hue: 0.62, arcanaLabel: "Major Arcana",  numeralString: "XII",  keywords: "surrender, new perspective, pause",             imageName: "tarot_major_hanged_man"),
        .init(id: 13, name: "Death",               emoji: "🥀",  hue: 0.72, arcanaLabel: "Major Arcana",  numeralString: "XIII", keywords: "transformation, endings, rebirth",              imageName: "tarot_major_death"),
        .init(id: 14, name: "Temperance",          emoji: "🌊",  hue: 0.57, arcanaLabel: "Major Arcana",  numeralString: "XIV",  keywords: "balance, patience, moderation",                 imageName: "tarot_major_temperance"),
        .init(id: 15, name: "The Devil",           emoji: "🔮",  hue: 0.02, arcanaLabel: "Major Arcana",  numeralString: "XV",   keywords: "shadow self, attachment, materialism",          imageName: "tarot_major_devil"),
        .init(id: 16, name: "The Tower",           emoji: "⚡️", hue: 0.05, arcanaLabel: "Major Arcana",  numeralString: "XVI",  keywords: "upheaval, sudden change, revelation",           imageName: "tarot_major_tower"),
        .init(id: 17, name: "The Star",            emoji: "⭐",  hue: 0.59, arcanaLabel: "Major Arcana",  numeralString: "XVII", keywords: "hope, renewal, calm after storm",               imageName: "tarot_major_star"),
        .init(id: 18, name: "The Moon",            emoji: "🌕",  hue: 0.69, arcanaLabel: "Major Arcana",  numeralString: "XVIII",keywords: "illusion, dreams, the unconscious",             imageName: "tarot_major_moon"),
        .init(id: 19, name: "The Sun",             emoji: "☀️",  hue: 0.12, arcanaLabel: "Major Arcana",  numeralString: "XIX",  keywords: "joy, vitality, clarity, success",               imageName: "tarot_major_sun"),
        .init(id: 20, name: "Judgement",           emoji: "🎺",  hue: 0.08, arcanaLabel: "Major Arcana",  numeralString: "XX",   keywords: "awakening, reckoning, absolution",              imageName: "tarot_major_judgement"),
        .init(id: 21, name: "The World",           emoji: "🌍",  hue: 0.35, arcanaLabel: "Major Arcana",  numeralString: "XXI",  keywords: "completion, integration, wholeness",            imageName: "tarot_major_world"),
    ]

    // MARK: Minor Arcana helpers

    private static func minor(
        baseId: Int, suit: String, hue: Double,
        suitEmoji: String, courtEmoji: (page: String, knight: String, queen: String, king: String)
    ) -> [TarotCard] {
        let ranks: [(String, String, String)] = [
            // (name, numeral, emoji)
            ("Ace",    "A",    suitEmoji),
            ("Two",    "II",   suitEmoji),
            ("Three",  "III",  suitEmoji),
            ("Four",   "IV",   suitEmoji),
            ("Five",   "V",    suitEmoji),
            ("Six",    "VI",   suitEmoji),
            ("Seven",  "VII",  suitEmoji),
            ("Eight",  "VIII", suitEmoji),
            ("Nine",   "IX",   suitEmoji),
            ("Ten",    "X",    suitEmoji),
            ("Page",   "P",    courtEmoji.page),
            ("Knight", "Kn",   courtEmoji.knight),
            ("Queen",  "Q",    courtEmoji.queen),
            ("King",   "K",    courtEmoji.king),
        ]
        let rankKeywords = [
            "pure potential, new spark, raw energy",
            "balance, duality, early decision",
            "growth, collaboration, first fruits",
            "stability, rest, consolidation",
            "conflict, struggle, change",
            "harmony, exchange, generosity",
            "reflection, strategy, persistence",
            "momentum, movement, effort",
            "near completion, fulfillment, endurance",
            "culmination, completion, carrying a load",
            "curiosity, messages, new student of life",
            "action, quest, headstrong movement",
            "intuitive mastery, nurturing, emotional depth",
            "mature authority, leadership, command",
        ]
        return ranks.enumerated().map { i, r in
            let suitSlug = suit.lowercased()
            let rankNumber = String(format: "%02d", i + 1)
            return TarotCard(id: baseId + i, name: "\(r.0) of \(suit)", emoji: r.2,
                      hue: hue, arcanaLabel: "\(suit) · Minor Arcana",
                      numeralString: r.1,
                      keywords: rankKeywords[i] + ", \(suit.lowercased()) energy",
                      imageName: "tarot_\(suitSlug)_\(rankNumber)")
        }
    }

    private static let wandsArcana = minor(
        baseId: 22, suit: "Wands", hue: 0.06,
        suitEmoji: "🪄",
        courtEmoji: (page: "🌱", knight: "🔥", queen: "🦚", king: "🦅")
    )
    private static let cupsArcana = minor(
        baseId: 36, suit: "Cups", hue: 0.60,
        suitEmoji: "🏺",
        courtEmoji: (page: "🐟", knight: "🦢", queen: "🌊", king: "🐋")
    )
    private static let swordsArcana = minor(
        baseId: 50, suit: "Swords", hue: 0.54,
        suitEmoji: "🌬️",
        courtEmoji: (page: "🦋", knight: "⚔️", queen: "🌪️", king: "🦉")
    )
    private static let pentaclesArcana = minor(
        baseId: 64, suit: "Pentacles", hue: 0.33,
        suitEmoji: "🌿",
        courtEmoji: (page: "🐢", knight: "🦌", queen: "🌺", king: "🐂")
    )
}
