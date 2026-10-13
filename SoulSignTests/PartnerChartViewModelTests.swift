//
//  PartnerChartViewModelTests.swift
//  SoulSignTests
//
import XCTest
@testable import SoulSign

@MainActor
final class PartnerChartViewModelTests: XCTestCase {

    private let suiteName = "SoulSignTests.PartnerChart"
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        MockURLProtocol.reset()
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        MockURLProtocol.reset()
        super.tearDown()
    }

    private func person(_ name: String) -> UserProfile {
        UserProfile(name: name, birthDate: Date(timeIntervalSince1970: 0),
                    birthTime: Date(timeIntervalSince1970: 0),
                    birthPlace: "Paris, France", latitude: 48.85, longitude: 2.35)
    }

    private func makeVM() -> PartnerChartViewModel {
        PartnerChartViewModel(claude: ClaudeService(session: MockURLProtocol.makeSession()),
                              defaults: defaults)
    }

    // MARK: Cache key

    func testCacheKeyIsOrderIndependent() {
        let vm = makeVM()
        let a = person("Luna Rivers")
        let b = person("Teo Marin")
        XCTAssertEqual(vm.cacheKey(a, b, language: .en),
                       vm.cacheKey(b, a, language: .en),
                       "(A,B) and (B,A) must share one cached reading")
    }

    func testCacheKeyDiffersByLanguage() {
        let vm = makeVM()
        let a = person("Luna"), b = person("Teo")
        XCTAssertNotEqual(vm.cacheKey(a, b, language: .en),
                          vm.cacheKey(a, b, language: .fr))
    }

    func testCacheKeyDiffersByPair() {
        let vm = makeVM()
        let a = person("Luna"), b = person("Teo"), c = person("Mira")
        XCTAssertNotEqual(vm.cacheKey(a, b, language: .en),
                          vm.cacheKey(a, c, language: .en))
    }

    // MARK: Birth details

    private func date(_ y: Int, _ m: Int, _ d: Int, hour: Int = 0, minute: Int = 0) -> Date {
        Calendar.current.date(from: DateComponents(year: y, month: m, day: d, hour: hour, minute: minute))!
    }

    private func personWithBirth(_ name: String, date birthDate: Date, time birthTime: Date, place: String) -> UserProfile {
        UserProfile(name: name, birthDate: birthDate, birthTime: birthTime,
                    birthPlace: place, latitude: nil, longitude: nil)
    }

    func testPromptUsesEachPersonsStoredBirthDateTimeAndPlace() {
        let luna = personWithBirth("Luna", date: date(1990, 5, 14), time: date(2000, 1, 1, hour: 8, minute: 30), place: "Paris, France")
        let teo = personWithBirth("Teo", date: date(1988, 11, 2), time: date(2000, 1, 1, hour: 21, minute: 5), place: "Rome, Italy")

        let prompt = PartnerChartViewModel.buildPrompt(a: luna, b: teo, language: .en)

        XCTAssertTrue(prompt.contains("Luna, born 1990-05-14 at 08:30 in Paris, France"))
        XCTAssertTrue(prompt.contains("Teo, born 1988-11-02 at 21:05 in Rome, Italy"))
    }

    func testCacheKeyChangesWhenBirthDateChanges() {
        let suite = "SoulSignTests.PartnerBirth"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        defer { defaults.removePersistentDomain(forName: suite) }
        let vm = PartnerChartViewModel(claude: ClaudeService(session: MockURLProtocol.makeSession()), defaults: defaults)

        var luna = person("Luna")
        let teo = person("Teo")
        let before = vm.cacheKey(luna, teo, language: .en)
        luna.birthDate = date(1991, 6, 15)

        XCTAssertNotEqual(before, vm.cacheKey(luna, teo, language: .en),
                          "changing a birth date must not reuse the old reading")
    }

    func testCacheKeyChangesWhenBirthTimeOrPlaceChanges() {
        let suite = "SoulSignTests.PartnerBirthTP"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        defer { defaults.removePersistentDomain(forName: suite) }
        let vm = PartnerChartViewModel(claude: ClaudeService(session: MockURLProtocol.makeSession()), defaults: defaults)

        var luna = person("Luna")
        let teo = person("Teo")
        let before = vm.cacheKey(luna, teo, language: .en)
        luna.birthTime = date(2000, 1, 1, hour: 7, minute: 0)
        let afterTime = vm.cacheKey(luna, teo, language: .en)
        luna.birthPlace = "Berlin, Germany"
        let afterPlace = vm.cacheKey(luna, teo, language: .en)

        XCTAssertNotEqual(before, afterTime)
        XCTAssertNotEqual(afterTime, afterPlace)
    }

    func testCacheKeyStillSharedForSamePairAndDetails() {
        let suite = "SoulSignTests.PartnerSame"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        defer { defaults.removePersistentDomain(forName: suite) }
        let vm = PartnerChartViewModel(claude: ClaudeService(session: MockURLProtocol.makeSession()), defaults: defaults)

        let luna = person("Luna")
        let teo = person("Teo")

        XCTAssertEqual(vm.cacheKey(luna, teo, language: .en), vm.cacheKey(teo, luna, language: .en))
    }

    // MARK: Prompt

    func testPromptNamesBothPeople() {
        let prompt = PartnerChartViewModel.buildPrompt(
            a: person("Luna Rivers"), b: person("Teo Marin"), language: .en)
        XCTAssertTrue(prompt.contains("Luna Rivers"))
        XCTAssertTrue(prompt.contains("Teo Marin"))
        XCTAssertTrue(prompt.contains("Luna") && prompt.contains("Teo"),
                      "first names are referenced for the writing instruction")
    }

    func testPromptAddressesByNameNotPronoun() {
        let prompt = PartnerChartViewModel.buildPrompt(
            a: person("Luna Rivers"), b: person("Teo Marin"), language: .en)
        XCTAssertFalse(prompt.contains("Speak to them as a pair, using \"you two\""),
                       "should no longer instruct pronoun-pair address as the default")
        XCTAssertTrue(prompt.contains("Luna meets Teo") || prompt.contains("throughout"),
                      "should model naming both people as the sentence subject")
    }

    func testPromptIncludesBirthPlacesAndCoordinates() {
        let prompt = PartnerChartViewModel.buildPrompt(
            a: person("Luna"), b: person("Teo"), language: .en)
        XCTAssertTrue(prompt.contains("Paris, France"))
        XCTAssertTrue(prompt.contains("48.85"))
    }

    func testEnglishPromptHasNoLanguageInstruction() {
        let prompt = PartnerChartViewModel.buildPrompt(
            a: person("Luna"), b: person("Teo"), language: .en)
        XCTAssertFalse(prompt.contains("Write the entire reading in"))
    }

    func testNonEnglishPromptRequestsThatLanguage() {
        for lang in AppLanguage.allCases where lang != .en {
            let prompt = PartnerChartViewModel.buildPrompt(
                a: person("Luna"), b: person("Teo"), language: lang)
            XCTAssertTrue(prompt.contains(lang.englishName),
                          "\(lang) prompt should name \(lang.englishName)")
        }
    }

    func testPromptForbidsEmDash() {
        let prompt = PartnerChartViewModel.buildPrompt(
            a: person("Luna"), b: person("Teo"), language: .en)
        XCTAssertTrue(prompt.contains("Never use the em dash"))
        XCTAssertFalse(prompt.contains("\u{2014}"), "the prompt itself must not contain an em dash")
    }

    // MARK: Loading + caching

    func testLoadReadingCachesResult() async {
        MockURLProtocol.requestHandler = { request in
            let body = #"{"content":[{"type":"text","text":"you two orbit each other"}]}"#
            return (HTTPURLResponse(url: request.url!, statusCode: 200,
                                    httpVersion: nil, headerFields: nil)!, Data(body.utf8))
        }
        let vm = makeVM()
        let a = person("Luna"), b = person("Teo")
        await vm.loadReading(for: a, and: b, language: .en)

        XCTAssertEqual(vm.reading, "you two orbit each other")
        XCTAssertEqual(defaults.string(forKey: vm.cacheKey(a, b, language: .en)),
                       "you two orbit each other")
    }

    func testCachedReadingSkipsNetwork() async {
        let vm = makeVM()
        let a = person("Luna"), b = person("Teo")
        defaults.set("previously saved", forKey: vm.cacheKey(a, b, language: .en))

        // No requestHandler set: any network call would fail the request.
        await vm.loadReading(for: a, and: b, language: .en)
        XCTAssertEqual(vm.reading, "previously saved")
        XCTAssertNil(vm.errorMessage)
    }

    func testFailureSurfacesError() async {
        MockURLProtocol.requestHandler = { request in
            (HTTPURLResponse(url: request.url!, statusCode: 500,
                             httpVersion: nil, headerFields: nil)!, Data("boom".utf8))
        }
        let vm = makeVM()
        await vm.loadReading(for: person("Luna"), and: person("Teo"), language: .en)
        XCTAssertTrue(vm.reading.isEmpty)
        XCTAssertNotNil(vm.errorMessage)
    }
}
