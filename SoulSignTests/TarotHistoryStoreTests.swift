//
//  TarotHistoryStoreTests.swift
//  SoulSignTests
//
import XCTest
@testable import SoulSign

final class TarotHistoryStoreTests: XCTestCase {

    private let suiteName = "SoulSignTests.TarotHistory"
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

    private func makeStore() -> TarotHistoryStore {
        TarotHistoryStore(defaults: defaults, key: "test_tarot_history")
    }

    private func date(_ y: Int, _ m: Int, _ d: Int) -> Date {
        var c = DateComponents()
        c.year = y; c.month = m; c.day = d; c.hour = 12
        return Calendar(identifier: .gregorian).date(from: c)!
    }

    func testDayKeyFormat() {
        XCTAssertEqual(TarotHistoryStore.dayKey(for: date(2026, 3, 5)), "2026-03-05")
    }

    func testSaveAndRetrieveRoundTrip() {
        let store = makeStore()
        let entry = TarotHistoryEntry(cardId: 4, reading: "steady authority", lang: "en", isRedraw: false)
        store.save(entry, for: date(2026, 1, 10))

        let fetched = store.entry(for: date(2026, 1, 10))
        XCTAssertEqual(fetched?.cardId, 4)
        XCTAssertEqual(fetched?.reading, "steady authority")
        XCTAssertFalse(fetched?.isRedraw ?? true)
    }

    func testRedrawOverwritesSameDayRatherThanDuplicating() {
        let store = makeStore()
        store.save(TarotHistoryEntry(cardId: 0, reading: "first", lang: "en", isRedraw: false), for: date(2026, 1, 10))
        store.save(TarotHistoryEntry(cardId: 7, reading: "second", lang: "en", isRedraw: true), for: date(2026, 1, 10))

        XCTAssertEqual(store.allSorted().count, 1, "a redraw must replace, not add, that day's entry")
        XCTAssertEqual(store.entry(for: date(2026, 1, 10))?.cardId, 7)
        XCTAssertTrue(store.entry(for: date(2026, 1, 10))?.isRedraw ?? false)
    }

    func testMissingDayReturnsNil() {
        let store = makeStore()
        XCTAssertNil(store.entry(for: date(2026, 6, 1)))
    }

    func testAllSortedIsMostRecentFirst() {
        let store = makeStore()
        store.save(TarotHistoryEntry(cardId: 1, reading: "a", lang: "en", isRedraw: false), for: date(2026, 1, 1))
        store.save(TarotHistoryEntry(cardId: 2, reading: "b", lang: "en", isRedraw: false), for: date(2026, 3, 1))
        store.save(TarotHistoryEntry(cardId: 3, reading: "c", lang: "en", isRedraw: false), for: date(2026, 2, 1))

        let keys = store.allSorted().map(\.dateKey)
        XCTAssertEqual(keys, ["2026-03-01", "2026-02-01", "2026-01-01"])
    }

    func testHistoryIsPrunedBeyondNinetyEntries() {
        let store = makeStore()
        let calendar = Calendar(identifier: .gregorian)
        let base = date(2026, 1, 1)
        for offset in 0..<100 {
            let d = calendar.date(byAdding: .day, value: offset, to: base)!
            store.save(TarotHistoryEntry(cardId: offset % 78, reading: "r\(offset)", lang: "en", isRedraw: false), for: d)
        }
        XCTAssertLessThanOrEqual(store.allSorted().count, 90,
            "history must be capped, not grow without bound")
    }
}
