//
//  YouTests.swift
//  SoulSignTests
//
import XCTest
@testable import SoulSign

@MainActor
final class YouTests: XCTestCase {

    private let suiteName = "SoulSignTests.You"
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        super.tearDown()
    }

    private func makeStore() -> ProfileStore {
        ProfileStore(defaults: defaults, key: "you_profiles")
    }

    private func person(_ name: String) -> UserProfile {
        UserProfile(name: name, birthDate: Date(timeIntervalSince1970: 0),
                    birthTime: Date(timeIntervalSince1970: 0), birthPlace: "Paris",
                    latitude: nil, longitude: nil)
    }

    // MARK: Only one "you"

    func testOnlyOnePersonCanBeYou() {
        let store = makeStore()
        let luna = person("Luna"), teo = person("Teo")
        store.add(luna); store.add(teo)

        store.setMe(luna.id)
        store.setMe(teo.id)

        XCTAssertEqual(store.me?.id, teo.id)
        XCTAssertNil(store.profiles.first { $0.id == luna.id }?.isMe, "switching you must clear the previous person")
        XCTAssertEqual(store.profiles.filter { $0.isMe == true }.count, 1)
    }

    func testClearingYouLeavesNobodyAsYou() {
        let store = makeStore()
        let luna = person("Luna")
        store.add(luna)
        store.setMe(luna.id)

        store.setMe(nil)

        XCTAssertNil(store.me)
    }

    func testChangingYouClearsCachedReadings() {
        let store = makeStore()
        var luna = person("Luna")
        luna.cachedReading = "old by-name reading"
        luna.cachedReadingLanguage = "en"
        store.add(luna)

        store.setMe(luna.id)

        let updated = store.profiles.first { $0.id == luna.id }
        XCTAssertNil(updated?.cachedReading, "the cached reading was written in the old voice and must regenerate")
        XCTAssertNil(updated?.cachedReadingLanguage)
    }

    func testYouFlagSurvivesARelaunch() {
        let luna = person("Luna")
        let first = makeStore()
        first.add(luna)
        first.setMe(luna.id)

        XCTAssertEqual(makeStore().me?.id, luna.id)
    }

    // MARK: "This is you" visibility

    func testYouSectionShownOnEveryoneWhileNobodyIsYou() {
        let store = makeStore()
        let luna = person("Luna"), teo = person("Teo")
        store.add(luna); store.add(teo)

        XCTAssertTrue(store.showsYouSection(for: luna))
        XCTAssertTrue(store.showsYouSection(for: teo))
    }

    func testYouSectionHiddenOnOthersOnceSomeoneIsYou() {
        let store = makeStore()
        let luna = person("Luna"), teo = person("Teo")
        store.add(luna); store.add(teo)
        store.setMe(luna.id)

        let lunaUpdated = store.profiles.first { $0.id == luna.id }!
        let teoUpdated = store.profiles.first { $0.id == teo.id }!
        XCTAssertTrue(store.showsYouSection(for: lunaUpdated), "the chosen person keeps the switch to turn it off")
        XCTAssertFalse(store.showsYouSection(for: teoUpdated), "everyone else hides the switch and its note")
    }

    // MARK: Prompt voice

    func testNatalPromptSpeaksAsYouWhenYou() {
        let p = SoulSignViewModel.buildPrompt(
            fullName: "Luna Rivers", birthDate: Date(timeIntervalSince1970: 0),
            birthTime: Date(timeIntervalSince1970: 0), birthPlace: "Paris",
            coordinates: nil, language: .en, depth: .standard, forYou: true)
        XCTAssertTrue(p.contains("as \"you\""))
        XCTAssertFalse(p.contains("Address Luna by name"))
    }

    func testNatalPromptStillUsesNameForOthers() {
        let p = SoulSignViewModel.buildPrompt(
            fullName: "Luna Rivers", birthDate: Date(timeIntervalSince1970: 0),
            birthTime: Date(timeIntervalSince1970: 0), birthPlace: "Paris",
            coordinates: nil, language: .en, depth: .standard, forYou: false)
        XCTAssertTrue(p.contains("Address Luna by name"))
    }

    func testTarotPromptSpeaksAsYouWhenYou() {
        let card = TarotDeck.cards[0]
        let p = TarotViewModel.buildPrompt(card: card, language: .en, dateLabel: "today", forYou: true)
        XCTAssertTrue(p.contains("as \"you\""))
        XCTAssertFalse(p.contains("Make the card itself the subject"))
    }

    func testTarotPromptKeepsCardAsSubjectByDefault() {
        let card = TarotDeck.cards[0]
        let p = TarotViewModel.buildPrompt(card: card, language: .en, dateLabel: "today")
        XCTAssertTrue(p.contains("Make the card itself the subject"))
    }

    func testAffirmationPromptSpeaksAsYouOnlyWhenAsked() {
        let personal = AffirmationService.buildPrompt(language: .en, forYou: true)
        let general = AffirmationService.buildPrompt(language: .en, forYou: false)
        XCTAssertTrue(personal.contains("as \"you\""))
        XCTAssertFalse(general.contains("as \"you\""))
    }

    func testAffirmationPromptContainsNoPersonalData() {
        // The request goes to Claude. It must carry only an instruction, never a name.
        let p = AffirmationService.buildPrompt(language: .en, forYou: true)
        XCTAssertFalse(p.contains("Luna"))
    }

    // MARK: Translations

    func testYouStringsExistInEveryLanguage() {
        for lang in AppLanguage.allCases {
            let table = Translations.table[lang] ?? [:]
            for key in ["me_title", "me_note", "me_badge"] {
                XCTAssertFalse((table[key] ?? "").isEmpty, "\(lang) is missing \(key)")
            }
        }
    }
}
