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
    let rwsMeaning: String // traditional Rider-Waite-Smith upright meaning
    let imageName: String  // Rider-Waite-Smith (1909) scan, Assets.xcassets/TarotCards
}

// MARK: - Deck

enum TarotDeck {
    static let cards: [TarotCard] = majorArcana + wandsArcana + cupsArcana + swordsArcana + pentaclesArcana

    /// Returns the same card for any given calendar day. Deterministic per
    /// day (same date always yields the same card) but cycles through a
    /// full shuffled ordering of all 78 cards before any card repeats,
    /// rather than a short cycle.
    static func cardForToday(date: Date = Date()) -> TarotCard {
        let cal = Calendar.current
        let dayOfYear = cal.ordinality(of: .day, in: .year, for: date) ?? 1
        let year = cal.component(.year, from: date)
        let order = shuffledOrder(forYear: year)
        return cards[order[(dayOfYear - 1) % cards.count]]
    }

    /// A deterministic full-cycle permutation of every card index, reshuffled
    /// once per calendar year so the sequence also varies year to year.
    static func shuffledOrder(forYear year: Int) -> [Int] {
        var generator = SeededGenerator(seed: year)
        return Array(0..<cards.count).shuffled(using: &generator)
    }

    /// SplitMix64: a small, fast, deterministic PRNG. Not cryptographic,
    /// just needs to reshuffle the same way every time for a given seed.
    private struct SeededGenerator: RandomNumberGenerator {
        private var state: UInt64
        init(seed: Int) {
            state = UInt64(bitPattern: Int64(seed)) &+ 0x9E3779B97F4A7C15
        }
        mutating func next() -> UInt64 {
            state &+= 0x9E3779B97F4A7C15
            var z = state
            z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
            z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
            return z ^ (z >> 31)
        }
    }

    // MARK: Major Arcana
    private static let majorArcana: [TarotCard] = [
        .init(id: 0,  name: "The Fool",           emoji: "🌬️", hue: 0.58, arcanaLabel: "Major Arcana",  numeralString: "0",
              rwsMeaning: "New beginnings and innocence. A leap of faith into the unknown, trusting the journey before seeing the whole path.",
              imageName: "tarot_major_fool"),
        .init(id: 1,  name: "The Magician",        emoji: "🪄",  hue: 0.12, arcanaLabel: "Major Arcana",  numeralString: "I",
              rwsMeaning: "Manifestation and willpower. All the tools are already at hand; it is time to turn intention into action.",
              imageName: "tarot_major_magician"),
        .init(id: 2,  name: "The High Priestess",  emoji: "🌙",  hue: 0.68, arcanaLabel: "Major Arcana",  numeralString: "II",
              rwsMeaning: "Intuition and hidden knowledge. Sitting between the seen and unseen, sensing what has not yet been spoken.",
              imageName: "tarot_major_high_priestess"),
        .init(id: 3,  name: "The Empress",         emoji: "🌹",  hue: 0.33, arcanaLabel: "Major Arcana",  numeralString: "III",
              rwsMeaning: "Abundance and nurturing. Creativity, fertility, and a deep connection to nature and sensual pleasure.",
              imageName: "tarot_major_empress"),
        .init(id: 4,  name: "The Emperor",         emoji: "🏔️", hue: 0.03, arcanaLabel: "Major Arcana",  numeralString: "IV",
              rwsMeaning: "Authority and structure. Stability built through discipline, protection, and steady control.",
              imageName: "tarot_major_emperor"),
        .init(id: 5,  name: "The Hierophant",      emoji: "📿",  hue: 0.28, arcanaLabel: "Major Arcana",  numeralString: "V",
              rwsMeaning: "Tradition and spiritual guidance. Wisdom passed down through established teaching and shared belief.",
              imageName: "tarot_major_hierophant"),
        .init(id: 6,  name: "The Lovers",          emoji: "💞",  hue: 0.93, arcanaLabel: "Major Arcana",  numeralString: "VI",
              rwsMeaning: "Union and meaningful choice. Alignment of values, and a partnership built on true harmony.",
              imageName: "tarot_major_lovers"),
        .init(id: 7,  name: "The Chariot",         emoji: "🏆",  hue: 0.60, arcanaLabel: "Major Arcana",  numeralString: "VII",
              rwsMeaning: "Willpower and victory. Forward motion achieved by holding two opposing forces in balance and driving them as one.",
              imageName: "tarot_major_chariot"),
        .init(id: 8,  name: "Strength",            emoji: "🦁",  hue: 0.07, arcanaLabel: "Major Arcana",  numeralString: "VIII",
              rwsMeaning: "Courage and quiet power. Not force, but compassion and patience taming what is wild.",
              imageName: "tarot_major_strength"),
        .init(id: 9,  name: "The Hermit",          emoji: "🕯️", hue: 0.25, arcanaLabel: "Major Arcana",  numeralString: "IX",
              rwsMeaning: "Introspection and solitude. Wisdom found by stepping back from the crowd and listening inward.",
              imageName: "tarot_major_hermit"),
        .init(id: 10, name: "Wheel of Fortune",    emoji: "♾️",  hue: 0.10, arcanaLabel: "Major Arcana",  numeralString: "X",
              rwsMeaning: "Cycles and turning points. Change moving on its own timing, larger than any one choice.",
              imageName: "tarot_major_wheel_of_fortune"),
        .init(id: 11, name: "Justice",             emoji: "⚖️",  hue: 0.55, arcanaLabel: "Major Arcana",  numeralString: "XI",
              rwsMeaning: "Fairness and truth. Cause meeting effect, and balance restored through honest accounting.",
              imageName: "tarot_major_justice"),
        .init(id: 12, name: "The Hanged Man",      emoji: "🌀",  hue: 0.62, arcanaLabel: "Major Arcana",  numeralString: "XII",
              rwsMeaning: "Surrender and new perspective. Suspended action that reveals what pushing forward could not.",
              imageName: "tarot_major_hanged_man"),
        .init(id: 13, name: "Death",               emoji: "🥀",  hue: 0.72, arcanaLabel: "Major Arcana",  numeralString: "XIII",
              rwsMeaning: "Transformation and release. An ending that clears the ground for what comes next.",
              imageName: "tarot_major_death"),
        .init(id: 14, name: "Temperance",          emoji: "🌊",  hue: 0.57, arcanaLabel: "Major Arcana",  numeralString: "XIV",
              rwsMeaning: "Balance and patience. Opposites blended slowly into something whole.",
              imageName: "tarot_major_temperance"),
        .init(id: 15, name: "The Devil",           emoji: "🔮",  hue: 0.02, arcanaLabel: "Major Arcana",  numeralString: "XV",
              rwsMeaning: "Attachment and illusion. Facing what binds you, and recognizing the chain was never fully locked.",
              imageName: "tarot_major_devil"),
        .init(id: 16, name: "The Tower",           emoji: "⚡️", hue: 0.05, arcanaLabel: "Major Arcana",  numeralString: "XVI",
              rwsMeaning: "Sudden upheaval and revelation. A false structure giving way so something truer can be built.",
              imageName: "tarot_major_tower"),
        .init(id: 17, name: "The Star",            emoji: "⭐",  hue: 0.59, arcanaLabel: "Major Arcana",  numeralString: "XVII",
              rwsMeaning: "Hope and renewal. Quiet healing and faith returning after hardship.",
              imageName: "tarot_major_star"),
        .init(id: 18, name: "The Moon",            emoji: "🌕",  hue: 0.69, arcanaLabel: "Major Arcana",  numeralString: "XVIII",
              rwsMeaning: "Intuition and the unconscious. Moving through uncertainty where the path is not yet fully lit.",
              imageName: "tarot_major_moon"),
        .init(id: 19, name: "The Sun",             emoji: "☀️",  hue: 0.12, arcanaLabel: "Major Arcana",  numeralString: "XIX",
              rwsMeaning: "Joy and vitality. Clarity, warmth, and success plainly seen in the light.",
              imageName: "tarot_major_sun"),
        .init(id: 20, name: "Judgement",           emoji: "🎺",  hue: 0.08, arcanaLabel: "Major Arcana",  numeralString: "XX",
              rwsMeaning: "Awakening and reckoning. A call to rise, look honestly at the past, and answer it.",
              imageName: "tarot_major_judgement"),
        .init(id: 21, name: "The World",           emoji: "🌍",  hue: 0.35, arcanaLabel: "Major Arcana",  numeralString: "XXI",
              rwsMeaning: "Completion and wholeness. A cycle closing in full, with everything finally integrated.",
              imageName: "tarot_major_world"),
    ]

    // MARK: Minor Arcana helpers

    private static func minor(
        baseId: Int, suit: String, hue: Double,
        suitEmoji: String, courtEmoji: (page: String, knight: String, queen: String, king: String),
        meanings: [String]
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
        return ranks.enumerated().map { i, r in
            let suitSlug = suit.lowercased()
            let rankNumber = String(format: "%02d", i + 1)
            return TarotCard(id: baseId + i, name: "\(r.0) of \(suit)", emoji: r.2,
                      hue: hue, arcanaLabel: "\(suit) · Minor Arcana",
                      numeralString: r.1,
                      rwsMeaning: meanings[i],
                      imageName: "tarot_\(suitSlug)_\(rankNumber)")
        }
    }

    private static let wandsArcana = minor(
        baseId: 22, suit: "Wands", hue: 0.06,
        suitEmoji: "🪄",
        courtEmoji: (page: "🌱", knight: "🔥", queen: "🦚", king: "🦅"),
        meanings: [
            "A spark of inspiration. New creative energy and potential ready to grow.",
            "Planning and personal power. Looking ahead to what could be built next.",
            "Expansion and foresight. Waiting on results already set in motion.",
            "Celebration and homecoming. A stable foundation worth honoring.",
            "Competition and creative tension. Differing views clashing before they align.",
            "Victory and recognition. Public success after real effort.",
            "Defending your position. Perseverance and standing your ground under pressure.",
            "Swift movement. Rapid progress, news, or momentum arriving quickly.",
            "Resilience. Guarded strength, one more push before rest.",
            "A heavy load. Responsibility carried further than feels sustainable.",
            "Enthusiasm and exploration. A new idea arriving with excitement.",
            "Bold, impulsive action. Adventure chasing a passion without waiting.",
            "Confidence and warmth. Vibrant independence that draws others in.",
            "Visionary leadership. Bold confidence that inspires others to act.",
        ]
    )
    private static let cupsArcana = minor(
        baseId: 36, suit: "Cups", hue: 0.60,
        suitEmoji: "🏺",
        courtEmoji: (page: "🐟", knight: "🦢", queen: "🌊", king: "🐋"),
        meanings: [
            "New emotional beginnings. An open heart, ready to receive.",
            "Connection and mutual attraction. Two people meeting each other clearly.",
            "Celebration and friendship. Joy shared within community.",
            "Contemplation, even apathy. Something worth noticing is being overlooked.",
            "Loss and grief. Mourning what spilled while missing what still stands.",
            "Nostalgia and memory. Innocence revisited, reconnecting with the past.",
            "Too many choices. Fantasy and options clouding real clarity.",
            "Walking away. Seeking something deeper than what currently satisfies.",
            "Contentment. Emotional wishes quietly fulfilled.",
            "Lasting harmony. Emotional fulfillment within family or home.",
            "A tender message. Creative sensitivity and curiosity of the heart.",
            "Romance and idealism. Following the heart toward a dream.",
            "Compassion and emotional depth. Intuitive, steady nurturing.",
            "Emotional balance. Calm wisdom and mastery over feeling.",
        ]
    )
    private static let swordsArcana = minor(
        baseId: 50, suit: "Swords", hue: 0.54,
        suitEmoji: "🌬️",
        courtEmoji: (page: "🦋", knight: "⚔️", queen: "🌪️", king: "🦉"),
        meanings: [
            "Clarity and breakthrough. A new idea cutting cleanly through confusion.",
            "Indecision. A standoff, avoiding a choice that still needs making.",
            "Heartbreak. Sorrow met honestly rather than pushed aside.",
            "Rest and recovery. Stepping back on purpose to recuperate.",
            "Unresolved conflict. A hollow victory that leaves tension behind.",
            "Transition. Moving toward calmer waters, leaving difficulty behind.",
            "Strategy, or quiet deception. Acting alone, under the radar.",
            "Restriction. Feeling trapped less by circumstance than by one's own thoughts.",
            "Anxiety and worry. Sleepless nights, fear louder than fact.",
            "A painful ending. Rock bottom, and release that follows collapse.",
            "Curiosity and vigilance. A quick, inquisitive mind testing the air.",
            "Fast, direct action. Charging ahead with sharp, unambiguous intent.",
            "Clear perception. Honesty and independence of thought.",
            "Authority through logic. Clear judgment, intellectual command.",
        ]
    )
    private static let pentaclesArcana = minor(
        baseId: 64, suit: "Pentacles", hue: 0.33,
        suitEmoji: "🌿",
        courtEmoji: (page: "🐢", knight: "🦌", queen: "🌺", king: "🐂"),
        meanings: [
            "A tangible new beginning. The first seed of prosperity in hand.",
            "Balance and adaptability. Juggling priorities without dropping either.",
            "Collaboration. Skilled work, building something together, brick by brick.",
            "Security, held tightly. Control over what has already been earned.",
            "Hardship and scarcity. Feeling left out in the cold, if only for now.",
            "Generosity. A fair exchange of resources, giving and receiving in turn.",
            "Patience. Assessing progress, tending what has already been planted.",
            "Diligence. Mastery built through quiet repetition and dedication to craft.",
            "Self-sufficiency. Refinement, and enjoying what one's own labor has earned.",
            "Legacy and abundance. Long-term security carried across a family line.",
            "Ambition and study. A practical opportunity just beginning to take root.",
            "Steady progress. Reliability and methodical, unglamorous effort.",
            "Grounded abundance. Nurturing practicality, comfort well tended.",
            "Material mastery. Generosity paired with steady, worldly success.",
        ]
    )
}
