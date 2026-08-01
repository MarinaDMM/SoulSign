//
//  TarotViewModelTests.swift
//  SoulSignTests
//
import XCTest
@testable import SoulSign

@MainActor
final class TarotViewModelTests: XCTestCase {

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
