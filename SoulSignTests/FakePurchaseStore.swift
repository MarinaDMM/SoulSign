//
//  FakePurchaseStore.swift
//  SoulSignTests
//
//  A scripted App Store for tests. It runs on any machine, with no StoreKit
//  test session, so subscription logic is checked on every CI run.
//
import Foundation
@testable import SoulSign

final class FakePurchaseStore: PurchaseStore {
    var productsToReturn: [StoreProduct] = []
    var entitlements: [StoreEntitlement] = []
    /// What the next purchase call reports. `.purchased` also grants an entitlement.
    var purchaseResult: PurchaseOutcome = .cancelled
    var productLoadError: Error?
    var purchaseError: Error?
    var syncError: Error?

    /// Created up front, so an event fired before the manager starts listening is kept.
    private let updates: AsyncStream<Void>
    private let continuation: AsyncStream<Void>.Continuation

    init() {
        (updates, continuation) = AsyncStream<Void>.makeStream()
    }

    func products(for ids: [String]) async throws -> [StoreProduct] {
        if let productLoadError { throw productLoadError }
        return productsToReturn.filter { ids.contains($0.id) }
    }

    func purchase(productID: String) async throws -> PurchaseOutcome {
        if let purchaseError { throw purchaseError }
        switch purchaseResult {
        case .purchased:
            entitlements.append(StoreEntitlement(productID: productID, expirationDate: nil, revocationDate: nil))
            return .purchased(productID: productID)
        case .cancelled, .pending:
            return purchaseResult
        }
    }

    func currentEntitlements() async -> [StoreEntitlement] {
        entitlements
    }

    func syncPurchases() async throws {
        if let syncError { throw syncError }
    }

    func entitlementUpdates() -> AsyncStream<Void> {
        updates
    }

    /// Simulates the store reporting a change outside a purchase, such as a renewal or refund.
    func emitEntitlementChange() {
        continuation.yield(())
    }

    static let sampleProducts: [StoreProduct] = [
        StoreProduct(id: PlusProduct.monthly.rawValue, displayPrice: "€6.99", price: Decimal(string: "6.99")!),
        StoreProduct(id: PlusProduct.yearly.rawValue, displayPrice: "€39.99", price: Decimal(string: "39.99")!),
    ]
}

enum FakeStoreError: Error { case boom }
