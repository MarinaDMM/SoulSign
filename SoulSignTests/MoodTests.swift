//
//  MoodTests.swift
//  SoulSignTests
//
import XCTest
@testable import SoulSign

final class MoodTests: XCTestCase {

    private var calendar: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "Europe/Amsterdam")!
        return c
    }

    private func date(_ y: Int, _ m: Int, _ d: Int, hour: Int = 12) -> Date {
        var c = DateComponents()
        c.year = y; c.month = m; c.day = d; c.hour = hour
        return calendar.date(from: c)!
    }

    // MARK: Mood model

    func testEveryMoodHasAnEmojiAndALabelKey() {
        for mood in Mood.allCases {
            XCTAssertFalse(mood.emoji.isEmpty)
            XCTAssertEqual(mood.labelKey, "mood_\(mood.rawValue)")
        }
    }

    func testMoodRoundTripsThroughCodable() throws {
        let data = try JSONEncoder().encode(Mood.grateful)
        XCTAssertEqual(try JSONDecoder().decode(Mood.self, from: data), .grateful)
    }

    func testMoodLabelsExistInEveryLanguage() {
        let keys = Mood.allCases.map(\.labelKey) + [
            "mood_title", "breathe_intro", "breathe_in", "breathe_out",
            "button_breathe", "week_title", "safety_footer"
        ]
        for lang in AppLanguage.allCases {
            let table = Translations.table[lang] ?? [:]
            for key in keys {
                XCTAssertFalse((table[key] ?? "").isEmpty, "\(lang) is missing \(key)")
            }
        }
    }

    // MARK: Week strip

    func testWeekHasSevenDaysOldestFirstEndingToday() {
        let today = date(2026, 8, 18)
        let week = MoodWeek.build(moodsByDay: [:], today: today, calendar: calendar)

        XCTAssertEqual(week.count, 7)
        XCTAssertEqual(calendar.component(.day, from: week.first!.day), 12)
        XCTAssertEqual(calendar.component(.day, from: week.last!.day), 18)
    }

    func testWeekPlacesMoodsOnTheirOwnDay() {
        let today = date(2026, 8, 18)
        let week = MoodWeek.build(
            moodsByDay: ["2026-08-18": .calm, "2026-08-15": .tired],
            today: today, calendar: calendar)

        XCTAssertEqual(week.last?.mood, .calm)
        XCTAssertEqual(week[3].mood, .tired)          // 15th
        XCTAssertNil(week[0].mood)                    // 12th had no mood
    }

    func testWeekIgnoresMoodsOutsideTheSevenDays() {
        let today = date(2026, 8, 18)
        let week = MoodWeek.build(
            moodsByDay: ["2026-08-01": .sad], today: today, calendar: calendar)

        XCTAssertTrue(week.allSatisfy { $0.mood == nil })
    }

    // MARK: Stored moods

    func testTarotEntryWithoutMoodStillDecodes() throws {
        // Entries saved before moods existed have no "mood" key.
        let legacy = #"{"cardId":4,"reading":"steady","lang":"en","isRedraw":false}"#
        let entry = try JSONDecoder().decode(TarotHistoryEntry.self, from: Data(legacy.utf8))
        XCTAssertNil(entry.mood)
        XCTAssertEqual(entry.cardId, 4)
    }

    func testTarotEntryMoodRoundTrips() throws {
        var entry = TarotHistoryEntry(cardId: 1, reading: "a", lang: "en", isRedraw: false)
        entry.mood = .hopeful
        let data = try JSONEncoder().encode(entry)
        XCTAssertEqual(try JSONDecoder().decode(TarotHistoryEntry.self, from: data).mood, .hopeful)
    }

    func testPersonNoteKeepsItsMood() {
        let suite = "SoulSignTests.Mood"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        defer { defaults.removePersistentDomain(forName: suite) }

        let store = ProfileStore(defaults: defaults, key: "mood_profiles")
        let person = UserProfile(name: "Teo", birthDate: Date(timeIntervalSince1970: 0),
                                 birthTime: Date(timeIntervalSince1970: 0),
                                 birthPlace: "Rome", latitude: nil, longitude: nil)
        store.add(person)

        store.addNote("a quiet walk helped", to: person.id, mood: .calm)
        store.addNote("no mood on this one", to: person.id)

        let notes = store.profiles.first { $0.id == person.id }?.notes ?? []
        XCTAssertEqual(notes.map(\.mood), [nil, .calm], "newest first, mood kept per note")
    }
}
