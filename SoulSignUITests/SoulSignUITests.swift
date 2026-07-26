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

    func testHomeShowsAllFeatureTiles() {
        let app = launchApp()
        XCTAssertTrue(app.staticTexts["SoulSign"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Natal Chart"].exists)
        XCTAssertTrue(app.staticTexts["Tarot Today"].exists)
        XCTAssertTrue(app.staticTexts["Partner Chart"].exists)
        XCTAssertTrue(app.staticTexts["Affirmations"].exists)
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

    func testNatalChartNavigatesToPeople() {
        let app = launchApp()
        app.staticTexts["Natal Chart"].firstMatch.tap()
        // Tapping Natal Chart opens the People screen. With -uitest-reset the
        // list is empty and shows the CTA; either way the People nav bar must
        // appear, proving navigation and rendering succeeded.
        let peopleNav = app.navigationBars["People"].waitForExistence(timeout: 10)
        let emptyCTA = app.staticTexts["Add Your First Person"].exists
                    || app.buttons["Add Your First Person"].exists
        XCTAssertTrue(peopleNav || emptyCTA, "expected the People screen to appear")
    }
}
