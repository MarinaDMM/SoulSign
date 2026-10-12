//
//  SoulSignUITests.swift
//  SoulSignUITests
//
//  End-to-end smoke tests driving the real app through the main flows.
//
import XCTest

final class SoulSignUITests: XCTestCase {

    private func launchApp() -> XCUIApplication {
        let app = XCUIApplication()
        // Skip the welcome screen and force English so labels are deterministic.
        app.launchArguments += [
            "-hasSeenWelcome", "YES",
            "-soulsign_language_v1", "en",
            "-uitest-reset"   // start from an empty, deterministic profile list
        ]
        app.launch()
        return app
    }

    func testHomeShowsTodayAndPeopleSections() {
        let app = launchApp()
        XCTAssertTrue(app.staticTexts["SoulSign"].waitForExistence(timeout: 10))
        // Today leads with the card as a writing prompt, then Affirmations.
        XCTAssertTrue(app.staticTexts["Today"].exists)
        XCTAssertTrue(app.staticTexts["Tarot Today"].exists)
        XCTAssertTrue(app.staticTexts["Affirmations"].exists)
        // People comes second. Natal and Partner charts now live on each person's page.
        XCTAssertTrue(app.staticTexts["Your People"].exists)
        XCTAssertFalse(app.staticTexts["Natal Chart"].exists)
        XCTAssertFalse(app.staticTexts["Partner Chart"].exists)
    }

    func testNavigateToTarot() {
        let app = launchApp()
        app.staticTexts["Tarot Today"].firstMatch.tap()
        // The Tarot screen has a navigation title and a Back button.
        XCTAssertTrue(app.navigationBars["Tarot Today"].waitForExistence(timeout: 10))
    }

    func testNavigateToAffirmations() {
        let app = launchApp()
        app.staticTexts["Affirmations"].firstMatch.tap()
        // Regression guard for the iPad blank-screen bug: a Back button must
        // appear, proving the destination actually pushed and rendered.
        XCTAssertTrue(app.buttons["Back"].waitForExistence(timeout: 10))
    }

    func testLanguagePickerOpens() {
        let app = launchApp()
        // The picker button shows the current language short code.
        let picker = app.buttons.containing(NSPredicate(format: "label CONTAINS 'EN'")).firstMatch
        XCTAssertTrue(picker.waitForExistence(timeout: 10))
        picker.tap()
        // The menu lists languages by native name.
        XCTAssertTrue(app.buttons["Français"].waitForExistence(timeout: 5)
                      || app.staticTexts["Français"].waitForExistence(timeout: 5))
    }

    func testAddPersonChipOpensFormOrPaywall() {
        let app = launchApp()
        // The Add chip either opens the new-person form (under the free cap) or
        // the Plus paywall (at the cap). Which one depends on how many people the
        // simulator already has, so accept either correct outcome.
        app.staticTexts["Add"].firstMatch.tap()
        let form = app.navigationBars["New Person"].waitForExistence(timeout: 10)
        let paywall = app.navigationBars["SoulSign Plus"].waitForExistence(timeout: 2)
        XCTAssertTrue(form || paywall, "Add should open the new-person form or the paywall")
    }
}
