//
//  SubscriptionManagerTests.swift
//  SoulSignTests
//
//  Uses StoreKitTest's SKTestSession to exercise the real StoreKit 2 flow
//  against the bundled SoulSign.storekit configuration, with no App Store
//  Connect setup and no real money involved.
//
import XCTest
import StoreKit
import StoreKitTest
@testable import SoulSign

@MainActor
final class SubscriptionManagerTests: XCTestCase {

    private var session: SKTestSession!

    override func setUpWithError() throws {
        try super.setUpWithError()
        session = try SKTestSession(configurationFileNamed: "SoulSign")
        session.resetToDefaultState()
        session.clearTransactions()
        session.disableDialogs = true
    }

    override func tearDownWithError() throws {
        session.clearTransactions()
        session = nil
        try super.tearDownWithError()
    }

    // MARK: Products

    func testLoadsBothPlans() async {
        let subs = SubscriptionManager()
        await subs.loadProducts()

        XCTAssertEqual(subs.products.count, 2, "expected a monthly and a yearly plan")
        XCTAssertNotNil(subs.monthly, "monthly product id must match the .storekit config")
        XCTAssertNotNil(subs.yearly, "yearly product id must match the .storekit config")
    }

    func testProductIdentifiersMatchConstants() async {
        let subs = SubscriptionManager()
        await subs.loadProducts()
        XCTAssertEqual(subs.monthly?.id, PlusProduct.monthly.rawValue)
        XCTAssertEqual(subs.yearly?.id, PlusProduct.yearly.rawValue)
    }

    func testYearlyIsCheaperThanTwelveMonths() async {
        let subs = SubscriptionManager()
        await subs.loadProducts()
        guard let m = subs.monthly, let y = subs.yearly else {
            return XCTFail("products did not load")
        }
        XCTAssertLessThan(y.price, m.price * 12,
                          "the annual plan must actually save money")
    }

    func testYearlySavingsIsAMeaningfulDiscount() async {
        let subs = SubscriptionManager()
        await subs.loadProducts()
        guard let percent = subs.yearlySavingsPercent else {
            return XCTFail("could not compute savings")
        }
        // 6.99/mo vs 39.99/yr is ~52%. Guard against pricing changes that
        // would quietly make the annual plan a weak offer again.
        XCTAssertGreaterThanOrEqual(percent, 30,
            "annual discount fell to \(percent)%, below the 30% that makes yearly worth committing to")
    }

    // MARK: Entitlement

    func testStartsWithoutEntitlement() async {
        let subs = SubscriptionManager()
        await subs.refreshEntitlement()
        XCTAssertFalse(subs.isPlus, "a fresh session must not be entitled")
    }

    func testPurchaseGrantsPlus() async throws {
        let subs = SubscriptionManager()
        await subs.loadProducts()
        guard let yearly = subs.yearly else { return XCTFail("no yearly product") }

        let ok = await subs.purchase(yearly)
        XCTAssertTrue(ok, "purchase should succeed against the test session")
        XCTAssertTrue(subs.isPlus, "entitlement should be granted after purchase")
    }

    func testEntitlementSurvivesAFreshManager() async throws {
        let first = SubscriptionManager()
        await first.loadProducts()
        guard let monthly = first.monthly else { return XCTFail("no monthly product") }
        _ = await first.purchase(monthly)
        XCTAssertTrue(first.isPlus)

        // A newly constructed manager (e.g. next app launch) should see it too.
        let second = SubscriptionManager()
        await second.refreshEntitlement()
        XCTAssertTrue(second.isPlus, "entitlement must be recovered from StoreKit, not held in memory")
    }

    // MARK: Entitlement rule (pure logic)
    //
    // SKTestSession's expireSubscription() does not rewrite the transaction's
    // expirationDate, so it can't simulate a lapsed subscription end-to-end.
    // The rule itself is tested directly instead.

    func testActiveSubscriptionGrantsPlus() {
        let future = Date().addingTimeInterval(60 * 60 * 24)
        XCTAssertTrue(SubscriptionManager.grantsPlus(
            productID: PlusProduct.monthly.rawValue,
            expirationDate: future, revocationDate: nil))
    }

    func testExpiredSubscriptionDoesNotGrantPlus() {
        let past = Date().addingTimeInterval(-60)
        XCTAssertFalse(SubscriptionManager.grantsPlus(
            productID: PlusProduct.yearly.rawValue,
            expirationDate: past, revocationDate: nil),
            "a lapsed subscription must re-lock Plus")
    }

    func testExpiryExactlyNowDoesNotGrantPlus() {
        let now = Date()
        XCTAssertFalse(SubscriptionManager.grantsPlus(
            productID: PlusProduct.monthly.rawValue,
            expirationDate: now, revocationDate: nil, now: now))
    }

    func testRefundedSubscriptionDoesNotGrantPlus() {
        let future = Date().addingTimeInterval(60 * 60 * 24 * 30)
        XCTAssertFalse(SubscriptionManager.grantsPlus(
            productID: PlusProduct.monthly.rawValue,
            expirationDate: future, revocationDate: Date()),
            "a refunded/revoked purchase must not keep Plus unlocked")
    }

    func testUnknownProductDoesNotGrantPlus() {
        XCTAssertFalse(SubscriptionManager.grantsPlus(
            productID: "com.someone.else.product",
            expirationDate: nil, revocationDate: nil))
    }

    func testNonExpiringEntitlementGrantsPlus() {
        // A nil expiration (e.g. a lifetime unlock) should not be treated as expired.
        XCTAssertTrue(SubscriptionManager.grantsPlus(
            productID: PlusProduct.yearly.rawValue,
            expirationDate: nil, revocationDate: nil))
    }

    // MARK: Free tier

    func testFreeTierCapIsPositive() {
        XCTAssertGreaterThan(FreeTier.maxSavedPeople, 0)
    }
}
