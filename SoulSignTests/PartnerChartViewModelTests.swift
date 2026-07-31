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

    // MARK: Prompt

    func testPromptNamesBothPeople() {
        let prompt = PartnerChartViewModel.buildPrompt(
            a: person("Luna Rivers"), b: person("Teo Marin"), language: .en)
        XCTAssertTrue(prompt.contains("Luna Rivers"))
        XCTAssertTrue(prompt.contains("Teo Marin"))
        XCTAssertTrue(prompt.contains("Luna") && prompt.contains("Teo"),
                      "first names are referenced for the writing instruction")
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
