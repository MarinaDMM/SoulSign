//
//  SubscriptionManagerTests.swift
//  SoulSignTests
//
//  Subscription logic checked against a fake App Store. No StoreKit test
//  session is used, so these run on any machine, including CI.
//
import XCTest
@testable import SoulSign

@MainActor
final class SubscriptionManagerTests: XCTestCase {

    private func makeManager(_ store: FakePurchaseStore) -> SubscriptionManager {
        SubscriptionManager(store: store)
    }

    /// Waits until the condition holds, for async updates delivered through the stream.
    private func waitUntil(_ condition: () -> Bool, timeoutNanoseconds: UInt64 = 2_000_000_000) async {
        let start = DispatchTime.now().uptimeNanoseconds
        while !condition() {
            if DispatchTime.now().uptimeNanoseconds - start > timeoutNanoseconds { return }
            try? await Task.sleep(nanoseconds: 10_000_000)
        }
    }

    // MARK: Products

    func testLoadsBothPlans() async {
        let store = FakePurchaseStore()
        store.productsToReturn = FakePurchaseStore.sampleProducts
        let subs = makeManager(store)

        await subs.loadProducts()

        XCTAssertEqual(subs.products.count, 2)
        XCTAssertEqual(subs.monthly?.id, PlusProduct.monthly.rawValue)
        XCTAssertEqual(subs.yearly?.id, PlusProduct.yearly.rawValue)
    }

    func testYearlyIsCheaperThanTwelveMonths() async {
        let store = FakePurchaseStore()
        store.productsToReturn = FakePurchaseStore.sampleProducts
        let subs = makeManager(store)
        await subs.loadProducts()

        guard let m = subs.monthly, let y = subs.yearly else { return XCTFail("products did not load") }
        XCTAssertLessThan(y.price, m.price * 12)
    }

    func testYearlySavingsIsAMeaningfulDiscount() async {
        let store = FakePurchaseStore()
        store.productsToReturn = FakePurchaseStore.sampleProducts
        let subs = makeManager(store)
        await subs.loadProducts()

        // 6.99/mo vs 39.99/yr is 52%. Guard against pricing changes that would
        // make the annual plan a weak offer.
        XCTAssertEqual(subs.yearlySavingsPercent, 52)
    }

    func testProductLoadFailureSurfacesAnError() async {
        let store = FakePurchaseStore()
        store.productLoadError = FakeStoreError.boom
        let subs = makeManager(store)

        await subs.loadProducts()

        XCTAssertTrue(subs.products.isEmpty)
        XCTAssertNotNil(subs.purchaseError)
    }

    // MARK: Purchase

    func testStartsWithoutEntitlement() async {
        let subs = makeManager(FakePurchaseStore())
        await subs.refreshEntitlement()
        XCTAssertFalse(subs.isPlus)
    }

    func testPurchaseGrantsPlus() async {
        let store = FakePurchaseStore()
        store.productsToReturn = FakePurchaseStore.sampleProducts
        store.purchaseResult = .purchased(productID: PlusProduct.yearly.rawValue)
        let subs = makeManager(store)
        await subs.loadProducts()
        guard let yearly = subs.yearly else { return XCTFail("no yearly product") }

        let ok = await subs.purchase(yearly)

        XCTAssertTrue(ok)
        XCTAssertTrue(subs.isPlus)
        XCTAssertNil(subs.purchaseError)
    }

    func testCancelledPurchaseDoesNotGrantPlusAndShowsNoError() async {
        let store = FakePurchaseStore()
        store.productsToReturn = FakePurchaseStore.sampleProducts
        store.purchaseResult = .cancelled
        let subs = makeManager(store)
        await subs.loadProducts()
        guard let monthly = subs.monthly else { return XCTFail("no monthly product") }

        let ok = await subs.purchase(monthly)

        XCTAssertFalse(ok)
        XCTAssertFalse(subs.isPlus)
        XCTAssertNil(subs.purchaseError, "cancelling is not an error")
    }

    func testPendingPurchaseDoesNotGrantPlusYet() async {
        let store = FakePurchaseStore()
        store.productsToReturn = FakePurchaseStore.sampleProducts
        store.purchaseResult = .pending
        let subs = makeManager(store)
        await subs.loadProducts()
        guard let monthly = subs.monthly else { return XCTFail("no monthly product") }

        let ok = await subs.purchase(monthly)

        XCTAssertFalse(ok)
        XCTAssertFalse(subs.isPlus)
    }

    func testFailedPurchaseSurfacesAnError() async {
        let store = FakePurchaseStore()
        store.productsToReturn = FakePurchaseStore.sampleProducts
        store.purchaseError = FakeStoreError.boom
        let subs = makeManager(store)
        await subs.loadProducts()
        guard let monthly = subs.monthly else { return XCTFail("no monthly product") }

        let ok = await subs.purchase(monthly)

        XCTAssertFalse(ok)
        XCTAssertFalse(subs.isPlus)
        XCTAssertNotNil(subs.purchaseError)
    }

    // MARK: Persistence and changes outside a purchase

    func testEntitlementSurvivesAFreshManager() async {
        let store = FakePurchaseStore()
        store.productsToReturn = FakePurchaseStore.sampleProducts
        store.purchaseResult = .purchased(productID: PlusProduct.monthly.rawValue)
        let first = makeManager(store)
        await first.loadProducts()
        guard let monthly = first.monthly else { return XCTFail("no monthly product") }
        _ = await first.purchase(monthly)

        // A newly constructed manager (e.g. the next app launch) reads the same store.
        let second = makeManager(store)
        await second.refreshEntitlement()

        XCTAssertTrue(second.isPlus)
    }

    func testRefundRemovesPlus() async {
        let store = FakePurchaseStore()
        store.entitlements = [StoreEntitlement(productID: PlusProduct.yearly.rawValue,
                                               expirationDate: nil, revocationDate: nil)]
        let subs = makeManager(store)
        await subs.refreshEntitlement()
        XCTAssertTrue(subs.isPlus)

        store.entitlements = [StoreEntitlement(productID: PlusProduct.yearly.rawValue,
                                               expirationDate: nil, revocationDate: Date())]
        await subs.refreshEntitlement()

        XCTAssertFalse(subs.isPlus, "a refunded purchase must not keep Plus unlocked")
    }

    func testEntitlementChangeFromStoreRefreshesPlus() async {
        let store = FakePurchaseStore()
        let subs = makeManager(store)
        XCTAssertFalse(subs.isPlus)

        // A renewal or purchase on another device arrives outside the purchase flow.
        store.entitlements = [StoreEntitlement(productID: PlusProduct.monthly.rawValue,
                                               expirationDate: nil, revocationDate: nil)]
        store.emitEntitlementChange()
        await waitUntil { subs.isPlus }

        XCTAssertTrue(subs.isPlus)
    }

    func testRestoreRefreshesEntitlement() async {
        let store = FakePurchaseStore()
        store.entitlements = [StoreEntitlement(productID: PlusProduct.yearly.rawValue,
                                               expirationDate: nil, revocationDate: nil)]
        let subs = makeManager(store)

        await subs.restore()

        XCTAssertTrue(subs.isPlus)
        XCTAssertNil(subs.purchaseError)
    }

    func testRestoreFailureSurfacesAnError() async {
        let store = FakePurchaseStore()
        store.syncError = FakeStoreError.boom
        let subs = makeManager(store)

        await subs.restore()

        XCTAssertFalse(subs.isPlus)
        XCTAssertNotNil(subs.purchaseError)
    }

    // MARK: Entitlement rule (pure logic)

    func testActiveSubscriptionGrantsPlus() {
        let future = Date().addingTimeInterval(60 * 60 * 24)
        XCTAssertTrue(SubscriptionManager.grantsPlus(
            productID: PlusProduct.monthly.rawValue, expirationDate: future, revocationDate: nil))
    }

    func testExpiredSubscriptionDoesNotGrantPlus() {
        let past = Date().addingTimeInterval(-60)
        XCTAssertFalse(SubscriptionManager.grantsPlus(
            productID: PlusProduct.yearly.rawValue, expirationDate: past, revocationDate: nil))
    }

    func testExpiryExactlyNowDoesNotGrantPlus() {
        let now = Date()
        XCTAssertFalse(SubscriptionManager.grantsPlus(
            productID: PlusProduct.monthly.rawValue, expirationDate: now, revocationDate: nil, now: now))
    }

    func testRevokedSubscriptionDoesNotGrantPlus() {
        let future = Date().addingTimeInterval(60 * 60 * 24 * 30)
        XCTAssertFalse(SubscriptionManager.grantsPlus(
            productID: PlusProduct.monthly.rawValue, expirationDate: future, revocationDate: Date()))
    }

    func testUnknownProductDoesNotGrantPlus() {
        XCTAssertFalse(SubscriptionManager.grantsPlus(
            productID: "com.someone.else.product", expirationDate: nil, revocationDate: nil))
    }

    func testNonExpiringEntitlementGrantsPlus() {
        XCTAssertTrue(SubscriptionManager.grantsPlus(
            productID: PlusProduct.yearly.rawValue, expirationDate: nil, revocationDate: nil))
    }

    // MARK: Free tier

    func testFreeTierCapIsPositive() {
        XCTAssertGreaterThan(FreeTier.maxSavedPeople, 0)
    }
}
