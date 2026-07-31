//
//  SubscriptionManager.swift
//  SoulSign
//
//  StoreKit 2 subscription handling for "SoulSign Plus".
//
import Foundation
import StoreKit

enum PlusProduct: String, CaseIterable {
    case monthly = "com.marinad.SoulSign.plus.monthly"
    case yearly  = "com.marinad.SoulSign.plus.yearly"
}

/// Free-tier limits. Plus removes them.
enum FreeTier {
    static let maxSavedPeople = 3
}

@MainActor
final class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()

    @Published private(set) var products: [Product] = []
    @Published private(set) var isPlus = false
    @Published private(set) var isLoadingProducts = false
    @Published var purchaseError: String?

    private var updatesTask: Task<Void, Never>?

    /// Not private so tests can create isolated instances against an
    /// SKTestSession instead of mutating the shared singleton.
    init() {
        // Keep entitlement in sync with transactions that arrive outside a
        // purchase flow (renewals, refunds, Ask to Buy, another device).
        updatesTask = Task { [weak self] in
            for await update in Transaction.updates {
                guard let self else { return }
                if case .verified(let transaction) = update {
                    await transaction.finish()
                }
                await self.refreshEntitlement()
            }
        }
    }

    deinit { updatesTask?.cancel() }

    var monthly: Product? { products.first { $0.id == PlusProduct.monthly.rawValue } }
    var yearly:  Product? { products.first { $0.id == PlusProduct.yearly.rawValue } }

    // MARK: - Loading

    func loadProducts() async {
        guard products.isEmpty else { return }
        isLoadingProducts = true
        defer { isLoadingProducts = false }
        do {
            let ids = PlusProduct.allCases.map(\.rawValue)
            products = try await Product.products(for: ids)
                .sorted { $0.price < $1.price }
        } catch {
            purchaseError = error.localizedDescription
        }
    }

    // MARK: - Entitlement

    func refreshEntitlement() async {
        for await entitlement in Transaction.currentEntitlements {
            guard case .verified(let transaction) = entitlement else { continue }
            if Self.grantsPlus(productID: transaction.productID,
                               expirationDate: transaction.expirationDate,
                               revocationDate: transaction.revocationDate) {
                isPlus = true
                return
            }
        }
        isPlus = false
    }

    /// Pure entitlement rule, extracted so it can be unit tested directly
    /// without constructing StoreKit transactions.
    ///
    /// `Transaction.currentEntitlements` already filters expired and revoked
    /// entitlements in production; these checks are a belt-and-braces guard
    /// and also reject product IDs that aren't ours.
    static func grantsPlus(productID: String,
                           expirationDate: Date?,
                           revocationDate: Date?,
                           now: Date = Date()) -> Bool {
        guard PlusProduct(rawValue: productID) != nil else { return false }
        guard revocationDate == nil else { return false }
        if let expirationDate, expirationDate <= now { return false }
        return true
    }

    // MARK: - Purchase / restore

    @discardableResult
    func purchase(_ product: Product) async -> Bool {
        purchaseError = nil
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    await transaction.finish()
                    await refreshEntitlement()
                    return isPlus
                }
                purchaseError = NSLocalizedString("Purchase could not be verified.", comment: "")
                return false
            case .userCancelled:
                return false
            case .pending:
                // e.g. Ask to Buy; entitlement arrives later via Transaction.updates
                return false
            @unknown default:
                return false
            }
        } catch {
            purchaseError = error.localizedDescription
            return false
        }
    }

    /// Apple requires a user-visible way to restore purchases.
    func restore() async {
        purchaseError = nil
        do {
            try await AppStore.sync()
            await refreshEntitlement()
        } catch {
            purchaseError = error.localizedDescription
        }
    }

    // MARK: - Display helpers

    /// Localised price, e.g. "€6.99".
    func displayPrice(_ product: Product) -> String { product.displayPrice }

    /// Percentage saved by the yearly plan versus paying monthly for a year.
    var yearlySavingsPercent: Int? {
        guard let m = monthly, let y = yearly else { return nil }
        let twelveMonths = m.price * 12
        guard twelveMonths > 0 else { return nil }
        let saved = (twelveMonths - y.price) / twelveMonths
        return Int((saved as NSDecimalNumber).doubleValue * 100)
    }
}
