//
//  SoulSignViewModelTests.swift
//  SoulSignTests
//
import XCTest
@testable import SoulSign

@MainActor
final class SoulSignViewModelTests: XCTestCase {

    private func prompt(depth: ReadingDepth, language: AppLanguage = .en) -> String {
        SoulSignViewModel.buildPrompt(
            fullName: "Luna Rivers", birthDate: Date(timeIntervalSince1970: 0),
            birthTime: Date(timeIntervalSince1970: 0), birthPlace: "Paris, France",
            coordinates: nil, language: language, depth: depth
        )
    }

    func testStandardPromptCapsAtFourParagraphs() {
        XCTAssertTrue(prompt(depth: .standard).contains("4 paragraphs maximum"))
    }

    func testDeepPromptAsksForMoreParagraphsThanStandard() {
        let deep = prompt(depth: .deep)
        XCTAssertTrue(deep.contains("8 to 9"), "deep reading should ask for materially more paragraphs")
        XCTAssertFalse(deep.contains("4 paragraphs maximum"),
                       "deep prompt must not also carry the standard paragraph cap")
    }

    func testDeepPromptCoversMultipleLifeFacets() {
        let deep = prompt(depth: .deep)
        for facet in ["Sun sign", "Moon", "love", "ambition"] {
            XCTAssertTrue(deep.contains(facet), "deep prompt missing facet: \(facet)")
        }
    }

    func testBothDepthsForbidEmDashAndHeaders() {
        for depth in [ReadingDepth.standard, .deep] {
            let p = prompt(depth: depth)
            XCTAssertTrue(p.contains("No closing offers"))
            XCTAssertTrue(p.contains("no headers"))
            XCTAssertFalse(p.contains("\u{2014}"))
        }
    }

    func testBothDepthsNameTheSubject() {
        for depth in [ReadingDepth.standard, .deep] {
            XCTAssertTrue(prompt(depth: depth).contains("Luna Rivers"))
        }
    }

    func testNonEnglishPromptNamesTheLanguageAtBothDepths() {
        for depth in [ReadingDepth.standard, .deep] {
            let p = prompt(depth: depth, language: .fr)
            XCTAssertTrue(p.contains("French"))
        }
    }
}
