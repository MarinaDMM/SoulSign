//
//  PurchaseStore.swift
//  SoulSign
//
//  The app's view of the App Store. SubscriptionManager talks only to this
//  protocol, so its logic can be tested with a fake store on any machine.
//  StoreKitPurchaseStore is the real implementation and the only file that
//  touches StoreKit.
//
import Foundation
import StoreKit

/// A product as the app sees it, independent of StoreKit.
struct StoreProduct: Equatable {
    let id: String
    /// Localised price for display, e.g. "€6.99".
    let displayPrice: String
    let price: Decimal
}

/// What happened when a purchase was attempted.
enum PurchaseOutcome: Equatable {
    case purchased(productID: String)
    case cancelled
    /// e.g. Ask to Buy. The entitlement may arrive later through entitlementUpdates().
    case pending
}

/// One entitlement the store reports as held by the user.
struct StoreEntitlement: Equatable {
    let productID: String
    let expirationDate: Date?
    let revocationDate: Date?
}

enum PurchaseError: LocalizedError {
    case unverified
    case productNotFound

    var errorDescription: String? {
        switch self {
        case .unverified:
            return NSLocalizedString("Purchase could not be verified.", comment: "")
        case .productNotFound:
            return NSLocalizedString("This plan is not available right now.", comment: "")
        }
    }
}

protocol PurchaseStore {
    func products(for ids: [String]) async throws -> [StoreProduct]
    func purchase(productID: String) async throws -> PurchaseOutcome
    func currentEntitlements() async -> [StoreEntitlement]
    /// Apple requires a user-visible restore. Syncs purchases with the App Store.
    func syncPurchases() async throws
    /// Emits whenever entitlements may have changed outside a purchase flow
    /// (renewal, refund, Ask to Buy approved, another device).
    func entitlementUpdates() -> AsyncStream<Void>
}

/// The real store, backed by StoreKit 2.
final class StoreKitPurchaseStore: PurchaseStore {
    private var cache: [String: Product] = [:]

    func products(for ids: [String]) async throws -> [StoreProduct] {
        let products = try await Product.products(for: ids)
        for product in products { cache[product.id] = product }
        return products.map {
            StoreProduct(id: $0.id, displayPrice: $0.displayPrice, price: $0.price)
        }
    }

    func purchase(productID: String) async throws -> PurchaseOutcome {
        if cache[productID] == nil {
            _ = try await products(for: [productID])
        }
        guard let product = cache[productID] else { throw PurchaseError.productNotFound }

        switch try await product.purchase() {
        case .success(let verification):
            guard case .verified(let transaction) = verification else {
                throw PurchaseError.unverified
            }
            await transaction.finish()
            return .purchased(productID: transaction.productID)
        case .userCancelled:
            return .cancelled
        case .pending:
            return .pending
        @unknown default:
            return .cancelled
        }
    }

    func currentEntitlements() async -> [StoreEntitlement] {
        var result: [StoreEntitlement] = []
        for await entitlement in Transaction.currentEntitlements {
            guard case .verified(let transaction) = entitlement else { continue }
            result.append(StoreEntitlement(
                productID: transaction.productID,
                expirationDate: transaction.expirationDate,
                revocationDate: transaction.revocationDate
            ))
        }
        return result
    }

    func syncPurchases() async throws {
        try await AppStore.sync()
    }

    func entitlementUpdates() -> AsyncStream<Void> {
        AsyncStream { continuation in
            let task = Task {
                for await update in Transaction.updates {
                    if case .verified(let transaction) = update {
                        await transaction.finish()
                    }
                    continuation.yield(())
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}
