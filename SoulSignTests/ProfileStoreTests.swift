//
//  ProfileStoreTests.swift
//  SoulSignTests
//
import XCTest
@testable import SoulSign

final class ProfileStoreTests: XCTestCase {

    private let suiteName = "SoulSignTests.ProfileStore"
    private let key = "test_profiles"
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        // Isolated suite so tests never touch the shared app defaults.
        defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        super.tearDown()
    }

    private func makeStore() -> ProfileStore {
        ProfileStore(defaults: defaults, key: key)
    }

    private func makeProfile(_ name: String) -> UserProfile {
        UserProfile(name: name, birthDate: Date(), birthTime: Date(), birthPlace: "Paris")
    }

    func testStartsEmpty() {
        XCTAssertTrue(makeStore().profiles.isEmpty)
    }

    func testAddPersists() {
        let store = makeStore()
        store.add(makeProfile("Luna"))
        XCTAssertEqual(store.profiles.count, 1)

        let reloaded = makeStore()
        XCTAssertEqual(reloaded.profiles.count, 1)
        XCTAssertEqual(reloaded.profiles.first?.name, "Luna")
    }

    func testUpdateReplacesMatchingProfile() {
        let store = makeStore()
        var p = makeProfile("Luna")
        store.add(p)
        p.cachedReading = "the stars say hi"
        store.update(p)

        let reloaded = makeStore()
        XCTAssertEqual(reloaded.profiles.count, 1)
        XCTAssertEqual(reloaded.profiles.first?.cachedReading, "the stars say hi")
    }

    func testUpdateUnknownProfileIsNoOp() {
        let store = makeStore()
        store.add(makeProfile("Luna"))
        store.update(makeProfile("Ghost")) // different id, not present
        XCTAssertEqual(store.profiles.count, 1)
    }

    func testRemoveAtOffsets() {
        let store = makeStore()
        store.add(makeProfile("Luna"))
        store.add(makeProfile("Teo"))
        store.remove(at: IndexSet(integer: 0))
        XCTAssertEqual(store.profiles.map(\.name), ["Teo"])

        let reloaded = makeStore()
        XCTAssertEqual(reloaded.profiles.map(\.name), ["Teo"])
    }
}
