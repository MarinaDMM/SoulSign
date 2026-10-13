//
//  PersonNotesTests.swift
//  SoulSignTests
//
import XCTest
import CoreLocation
@testable import SoulSign

final class PersonNotesTests: XCTestCase {

    private let suiteName = "SoulSignTests.PersonNotes"
    private var defaults: UserDefaults!
    private let key = "test_profiles"

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

    private func makeProfile(_ name: String = "Luna Rivers") -> UserProfile {
        UserProfile(name: name, birthDate: Date(timeIntervalSince1970: 0),
                    birthTime: Date(timeIntervalSince1970: 0), birthPlace: "Paris, France",
                    latitude: nil, longitude: nil)
    }

    private func makeStore() -> ProfileStore {
        ProfileStore(defaults: defaults, key: key)
    }

    // MARK: Backwards compatibility

    func testProfileWithoutNotesFieldStillDecodes() throws {
        // A profile encoded before notes existed has no "notes" key at all.
        let profile = makeProfile()
        XCTAssertNil(profile.notes)
        let data = try JSONEncoder().encode(profile)
        XCTAssertFalse(String(decoding: data, as: UTF8.self).contains("\"notes\""),
                       "a profile with no notes should not write a notes key")

        let decoded = try JSONDecoder().decode(UserProfile.self, from: data)
        XCTAssertEqual(decoded.id, profile.id)
        XCTAssertNil(decoded.notes)
    }

    // MARK: Adding

    func testAddNoteStoresTrimmedTextNewestFirst() {
        let store = makeStore()
        let person = makeProfile()
        store.add(person)

        store.addNote("  first thought  ", to: person.id, now: Date(timeIntervalSince1970: 100))
        store.addNote("second thought", to: person.id, now: Date(timeIntervalSince1970: 200))

        let notes = store.profiles.first { $0.id == person.id }?.notes ?? []
        XCTAssertEqual(notes.map(\.text), ["second thought", "first thought"],
                       "notes should be newest first and trimmed")
    }

    func testBlankNoteIsIgnored() {
        let store = makeStore()
        let person = makeProfile()
        store.add(person)

        store.addNote("   \n  ", to: person.id)

        XCTAssertTrue((store.profiles.first { $0.id == person.id }?.notes ?? []).isEmpty)
    }

    func testNoteForUnknownPersonIsIgnored() {
        let store = makeStore()
        store.add(makeProfile())

        store.addNote("nobody to attach to", to: UUID())

        XCTAssertTrue(store.profiles.allSatisfy { ($0.notes ?? []).isEmpty })
    }

    func testNotesStayWithTheirOwnPerson() {
        let store = makeStore()
        let luna = makeProfile("Luna Rivers")
        let teo = makeProfile("Teo Marin")
        store.add(luna)
        store.add(teo)

        store.addNote("about Luna", to: luna.id)

        XCTAssertEqual(store.profiles.first { $0.id == luna.id }?.notes?.first?.text, "about Luna")
        XCTAssertTrue((store.profiles.first { $0.id == teo.id }?.notes ?? []).isEmpty,
                      "a note on one person must not appear on another")
    }

    // MARK: Removing

    func testRemoveNoteDeletesOnlyThatNote() {
        let store = makeStore()
        let person = makeProfile()
        store.add(person)
        store.addNote("keep me", to: person.id)
        store.addNote("delete me", to: person.id)
        let toDelete = store.profiles.first { $0.id == person.id }!.notes!
            .first { $0.text == "delete me" }!.id

        store.removeNote(toDelete, from: person.id)

        let remaining = store.profiles.first { $0.id == person.id }?.notes ?? []
        XCTAssertEqual(remaining.map(\.text), ["keep me"])
    }

    // MARK: Persistence

    func testNotesSurviveANewStoreInstance() {
        let person = makeProfile()
        let first = makeStore()
        first.add(person)
        first.addNote("written before relaunch", to: person.id)

        let relaunched = makeStore()

        XCTAssertEqual(relaunched.profiles.first { $0.id == person.id }?.notes?.first?.text,
                       "written before relaunch")
    }

    // MARK: Birth details

    func testUpdatingBirthDetailsSavesAllFieldsAndClearsReadings() {
        let store = makeStore()
        var person = makeProfile()
        person.cachedReading = "written from the old details"
        person.cachedReadingLanguage = "en"
        person.cachedDeepReading = "deep, old details"
        person.cachedDeepReadingLanguage = "en"
        person.isMe = true
        store.add(person)
        store.addNote("still here", to: person.id)

        let newDate = Date(timeIntervalSince1970: 500_000_000)
        let newTime = Date(timeIntervalSince1970: 600_000_000)
        store.updateBirthDetails(for: person.id, date: newDate, time: newTime,
                                 place: "Berlin, Germany",
                                 coordinates: CLLocationCoordinate2D(latitude: 52.52, longitude: 13.405))

        let updated = store.profiles.first { $0.id == person.id }!
        XCTAssertEqual(updated.birthDate, newDate)
        XCTAssertEqual(updated.birthTime, newTime)
        XCTAssertEqual(updated.birthPlace, "Berlin, Germany")
        XCTAssertEqual(updated.latitude ?? 0, 52.52, accuracy: 0.0001)
        XCTAssertEqual(updated.longitude ?? 0, 13.405, accuracy: 0.0001)
        XCTAssertNil(updated.cachedReading)
        XCTAssertNil(updated.cachedReadingLanguage)
        XCTAssertNil(updated.cachedDeepReading)
        XCTAssertNil(updated.cachedDeepReadingLanguage)
        XCTAssertEqual(updated.notes?.first?.text, "still here")
        XCTAssertEqual(updated.isMe, true)
    }

    func testUpdatingBirthDetailsForUnknownPersonDoesNothing() {
        let store = makeStore()
        let person = makeProfile()
        store.add(person)
        let before = store.profiles

        store.updateBirthDetails(for: UUID(), date: Date(), time: Date(), place: "Nowhere", coordinates: nil)

        XCTAssertEqual(store.profiles, before)
    }

    func testPlacePrefillKeepsExistingPlaceWithoutSearching() {
        let vm = PlaceSearchViewModel()
        vm.prefill(placeName: "Paris, France", coordinates: CLLocationCoordinate2D(latitude: 48.85, longitude: 2.35))

        XCTAssertEqual(vm.searchText, "Paris, France")
        XCTAssertEqual(vm.selectedPlaceName, "Paris, France")
        XCTAssertEqual(vm.selectedCoordinates?.latitude ?? 0, 48.85, accuracy: 0.0001)
    }

    func testTypingANewPlaceClearsTheOldSelection() async {
        let vm = PlaceSearchViewModel()
        vm.prefill(placeName: "Paris, France", coordinates: CLLocationCoordinate2D(latitude: 48.85, longitude: 2.35))

        vm.searchText = "Ber"
        try? await Task.sleep(nanoseconds: 700_000_000)

        XCTAssertEqual(vm.selectedPlaceName, "")
        XCTAssertNil(vm.selectedCoordinates)
    }
}
