//
//  TarotViewModelTests.swift
//  SoulSignTests
//
import XCTest
@testable import SoulSign

@MainActor
final class TarotViewModelTests: XCTestCase {

    private let suiteName = "SoulSignTests.TarotViewModel"
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

    private func makeVM() -> (TarotViewModel, TarotHistoryStore) {
        let store = TarotHistoryStore(defaults: defaults, key: "test_tarot_history")
        return (TarotViewModel(store: store), store)
    }

    // MARK: reflections

    func testSaveReflectionPersistsForToday() {
        let (vm, store) = makeVM()
        store.save(TarotHistoryEntry(cardId: vm.card.id, reading: "seeded", lang: "en", isRedraw: false), for: Date())

        vm.saveReflection("This felt honest.", language: .en)

        XCTAssertEqual(store.entry(for: Date())?.reflection, "This felt honest.")
        XCTAssertEqual(vm.reflectionDraft, "This felt honest.")
    }

    func testSaveReflectionCreatesEntryWhenNoneExistsYet() {
        let (vm, store) = makeVM()
        XCTAssertNil(store.entry(for: Date()), "precondition: nothing seeded yet")

        vm.saveReflection("First thought of the day.", language: .en)

        let saved = store.entry(for: Date())
        XCTAssertEqual(saved?.reflection, "First thought of the day.")
        XCTAssertEqual(saved?.cardId, vm.card.id)
    }

    func testSaveReflectionForPastDayUpdatesThatDayOnly() {
        let (vm, store) = makeVM()
        var cal = DateComponents(); cal.year = 2026; cal.month = 1; cal.day = 5; cal.hour = 12
        let pastDate = Calendar(identifier: .gregorian).date(from: cal)!
        let pastKey = TarotHistoryStore.dayKey(for: pastDate)
        store.save(TarotHistoryEntry(cardId: 3, reading: "old", lang: "en", isRedraw: false), for: pastDate)

        vm.reflectionDraft = "unrelated draft for today"
        vm.saveReflection("Looking back on this one.", language: .en, dateKey: pastKey)

        XCTAssertEqual(store.entry(for: pastDate)?.reflection, "Looking back on this one.")
        XCTAssertEqual(vm.reflectionDraft, "unrelated draft for today",
                       "editing a past day must not overwrite today's in-progress draft")
    }

    func testSaveReflectionForPastDayRefreshesHistoryList() {
        let (vm, store) = makeVM()
        var cal = DateComponents(); cal.year = 2026; cal.month = 1; cal.day = 5; cal.hour = 12
        let pastDate = Calendar(identifier: .gregorian).date(from: cal)!
        let pastKey = TarotHistoryStore.dayKey(for: pastDate)
        store.save(TarotHistoryEntry(cardId: 3, reading: "old", lang: "en", isRedraw: false), for: pastDate)

        vm.saveReflection("Noted.", language: .en, dateKey: pastKey)

        XCTAssertEqual(vm.historyEntries.first(where: { $0.dateKey == pastKey })?.entry.reflection, "Noted.")
    }

    func testSaveReflectionTrimsWhitespaceToNil() {
        let (vm, store) = makeVM()
        store.save(TarotHistoryEntry(cardId: vm.card.id, reading: "seeded", lang: "en", isRedraw: false, reflection: "old note"), for: Date())

        vm.saveReflection("   \n  ", language: .en)

        XCTAssertNil(store.entry(for: Date())?.reflection, "whitespace-only reflection should clear the note")
    }

    // MARK: pickRedrawCard

    func testRedrawNeverReturnsTheExcludedCard() {
        // The exclusion is structural (a while loop), not probabilistic, so a
        // small fixed number of calls is enough to catch a regression.
        for _ in 0..<50 {
            let excluded = TarotDeck.cards.randomElement()!.id
            let result = TarotViewModel.pickRedrawCard(excluding: excluded)
            XCTAssertNotEqual(result.id, excluded)
        }
    }

    func testRedrawReturnsAValidDeckCard() {
        let result = TarotViewModel.pickRedrawCard(excluding: -1)
        XCTAssertTrue(TarotDeck.cards.contains(where: { $0.id == result.id }))
    }

    // MARK: buildPrompt

    func testPromptGroundedInCardMeaning() {
        let card = TarotDeck.cards.first(where: { $0.name == "The Hermit" })!
        let prompt = TarotViewModel.buildPrompt(card: card, language: .en, dateLabel: "Monday, March 5")
        XCTAssertTrue(prompt.contains("The Hermit"))
        XCTAssertTrue(prompt.contains(card.rwsMeaning))
    }

    func testPromptInstructsCardNameAsSubjectNotYou() {
        let card = TarotDeck.cards.first(where: { $0.name == "The Hermit" })!
        let prompt = TarotViewModel.buildPrompt(card: card, language: .en, dateLabel: "today")
        XCTAssertTrue(prompt.contains("The Hermit"))
        XCTAssertFalse(prompt.contains("Speak directly to the reader as \"you.\""),
                       "should no longer instruct blanket \"you\" address")
        XCTAssertTrue(prompt.contains("subject"), "should instruct the card's name to carry sentences")
    }

    func testEnglishPromptHasNoLanguageInstruction() {
        let card = TarotDeck.cards[0]
        let prompt = TarotViewModel.buildPrompt(card: card, language: .en, dateLabel: "today")
        XCTAssertFalse(prompt.contains("Write the entire reading in"))
    }

    func testNonEnglishPromptNamesTheLanguage() {
        let card = TarotDeck.cards[0]
        for lang in AppLanguage.allCases where lang != .en {
            let prompt = TarotViewModel.buildPrompt(card: card, language: lang, dateLabel: "today")
            XCTAssertTrue(prompt.contains(lang.englishName))
        }
    }

    func testPromptForbidsEmDash() {
        let card = TarotDeck.cards[0]
        let prompt = TarotViewModel.buildPrompt(card: card, language: .en, dateLabel: "today")
        XCTAssertTrue(prompt.contains("Never use the em dash"))
        XCTAssertFalse(prompt.contains("\u{2014}"))
    }
}
