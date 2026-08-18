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

    func testCardForTodayIsDeterministicForAGivenDate() {
        let date = dateFor(year: 2026, dayOfYear: 100)
        XCTAssertEqual(TarotDeck.cardForToday(date: date).id, TarotDeck.cardForToday(date: date).id)
    }

    func testAllSeventyEightCardsAppearBeforeAnyRepeatWithinAYear() {
        // Regression: cardForToday used to multiply the day by 13, and since
        // gcd(13, 78) == 13, that only ever produced 6 distinct indices, so
        // the deck degenerated into a 6-day repeating cycle instead of 78.
        var seenOnDay: [Int: Int] = [:]
        for day in 1...78 {
            let card = TarotDeck.cardForToday(date: dateFor(year: 2026, dayOfYear: day))
            if let firstSeen = seenOnDay[card.id] {
                XCTFail("card \(card.id) repeated on day \(day), first seen on day \(firstSeen); " +
                       "expected all 78 cards to appear once before any repeat")
                return
            }
            seenOnDay[card.id] = day
        }
        XCTAssertEqual(seenOnDay.count, TarotDeck.cards.count, "all 78 cards should have appeared exactly once")
    }

    func testShuffledOrderIsAPermutationOfAllCards() {
        let order = TarotDeck.shuffledOrder(forYear: 2026)
        XCTAssertEqual(Set(order).count, TarotDeck.cards.count, "no duplicate or missing indices")
        XCTAssertEqual(Set(order), Set(0..<TarotDeck.cards.count))
    }

    func testShuffledOrderIsStableForTheSameYear() {
        XCTAssertEqual(TarotDeck.shuffledOrder(forYear: 2026), TarotDeck.shuffledOrder(forYear: 2026))
    }

    func testShuffledOrderDiffersAcrossYears() {
        XCTAssertNotEqual(TarotDeck.shuffledOrder(forYear: 2026), TarotDeck.shuffledOrder(forYear: 2027))
    }

    private func dateFor(year: Int, dayOfYear: Int) -> Date {
        Calendar.current.date(from: DateComponents(year: year))!
            .addingTimeInterval(TimeInterval(dayOfYear - 1) * 86400)
    }
}
