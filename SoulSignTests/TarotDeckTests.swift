//
//  TarotDeckTests.swift
//  SoulSignTests
//
import XCTest
@testable import SoulSign

final class TarotDeckTests: XCTestCase {

    func testDeckHasExactly78Cards() {
        XCTAssertEqual(TarotDeck.cards.count, 78)
    }

    func testMajorAndMinorSplit() {
        let majors = TarotDeck.cards.filter { $0.arcanaLabel == "Major Arcana" }
        let minors = TarotDeck.cards.filter { $0.arcanaLabel.contains("Minor Arcana") }
        XCTAssertEqual(majors.count, 22)
        XCTAssertEqual(minors.count, 56)
    }

    func testEachSuitHas14Cards() {
        for suit in ["Wands", "Cups", "Swords", "Pentacles"] {
            let count = TarotDeck.cards.filter { $0.name.hasSuffix("of \(suit)") }.count
            XCTAssertEqual(count, 14, "\(suit) should have 14 cards")
        }
    }

    func testAllIdsUnique() {
        let ids = TarotDeck.cards.map { $0.id }
        XCTAssertEqual(Set(ids).count, 78, "card ids must be unique")
    }

    func testAllImageNamesUniqueAndPrefixed() {
        let names = TarotDeck.cards.map { $0.imageName }
        XCTAssertEqual(Set(names).count, 78, "image names must be unique")
        XCTAssertTrue(names.allSatisfy { $0.hasPrefix("tarot_") })
    }

    func testEveryCardHasContent() {
        for card in TarotDeck.cards {
            XCTAssertFalse(card.name.isEmpty, "card \(card.id) name")
            XCTAssertFalse(card.rwsMeaning.isEmpty, "card \(card.name) meaning")
            XCTAssertFalse(card.imageName.isEmpty, "card \(card.name) image")
            XCTAssertFalse(card.emoji.isEmpty, "card \(card.name) emoji")
        }
    }

    func testMinorMeaningsDifferAcrossSuits() {
        // Regression: Minor Arcana meanings used to be shared across suits,
        // so "Five of Cups" and "Five of Wands" had identical text.
        let fiveCups = TarotDeck.cards.first { $0.name == "Five of Cups" }!
        let fiveWands = TarotDeck.cards.first { $0.name == "Five of Wands" }!
        XCTAssertNotEqual(fiveCups.rwsMeaning, fiveWands.rwsMeaning)
    }

    func testCardForTodayIsInDeckAndStableWithinDay() {
        let a = TarotDeck.cardForToday()
        let b = TarotDeck.cardForToday()
        XCTAssertEqual(a.id, b.id, "same card for the same day")
        XCTAssertTrue(TarotDeck.cards.contains { $0.id == a.id })
    }
}
