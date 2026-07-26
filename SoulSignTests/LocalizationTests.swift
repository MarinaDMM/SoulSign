//
//  LocalizationTests.swift
//  SoulSignTests
//
import XCTest
@testable import SoulSign

final class LocalizationTests: XCTestCase {

    func testAllNineLanguagesPresent() {
        XCTAssertEqual(AppLanguage.allCases.count, 9)
        for lang in AppLanguage.allCases {
            XCTAssertNotNil(Translations.table[lang], "missing table for \(lang)")
        }
    }

    func testUkrainianShortCodeIsUA() {
        // Deliberate product choice: Ukrainian shows "UA", not the ISO "UK".
        XCTAssertEqual(AppLanguage.uk.shortCode, "UA")
    }

    func testEveryLanguageHasDisplayAndEnglishName() {
        for lang in AppLanguage.allCases {
            XCTAssertFalse(lang.shortCode.isEmpty)
            XCTAssertFalse(lang.displayName.isEmpty)
            XCTAssertFalse(lang.englishName.isEmpty)
        }
    }

    func testEveryLanguageHasSameKeysAsEnglish() {
        let englishKeys = Set(Translations.en.keys)
        XCTAssertFalse(englishKeys.isEmpty)
        for lang in AppLanguage.allCases {
            let keys = Set(Translations.table[lang]!.keys)
            XCTAssertEqual(keys, englishKeys,
                           "\(lang) is missing keys: \(englishKeys.subtracting(keys)) / extra: \(keys.subtracting(englishKeys))")
        }
    }

    func testNoEmptyTranslationValues() {
        for lang in AppLanguage.allCases {
            for (key, value) in Translations.table[lang]! {
                XCTAssertFalse(value.isEmpty, "\(lang) has empty value for \(key)")
            }
        }
    }

    func testFormatKeyHasPlaceholderInEveryLanguage() {
        // Keys that take an argument must keep the %@ placeholder.
        for key in ["reading_stars_of", "reading_title_of"] {
            for lang in AppLanguage.allCases {
                XCTAssertTrue(Translations.table[lang]![key]?.contains("%@") == true,
                              "\(lang) '\(key)' lost its %@ placeholder")
            }
        }
    }

    @MainActor
    func testManagerFallsBackToEnglishThenKey() {
        let mgr = LocalizationManager.shared
        mgr.language = .fr
        // A real key returns the French value.
        XCTAssertEqual(mgr.t("tarot_today"), Translations.fr["tarot_today"])
        // An unknown key falls back to the key itself.
        XCTAssertEqual(mgr.t("__nonexistent_key__"), "__nonexistent_key__")
    }

    @MainActor
    func testManagerFormatsArgument() {
        let mgr = LocalizationManager.shared
        mgr.language = .en
        let out = mgr.t("reading_title_of", "Luna")
        XCTAssertTrue(out.contains("Luna"))
        XCTAssertFalse(out.contains("%@"))
    }
}
