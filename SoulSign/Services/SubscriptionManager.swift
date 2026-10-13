//
//  SubscriptionManager.swift
//  SoulSign
//
//  Subscription state for "SoulSign Plus". All App Store access goes through
//  a PurchaseStore, so this logic is tested with a fake store.
//
import Foundation

enum PlusProduct: String, CaseIterable {
    // ".v2" because the original IDs (without suffix) were claimed by an
    // earlier, abandoned App Store Connect attempt — Apple permanently
    // reserves a Product ID for an app once created, even after deletion,
    // so those originals can never be reused.
    case monthly = "com.marinad.SoulSign.plus.monthly.v2"
    case yearly  = "com.marinad.SoulSign.plus.yearly.v2"
}

/// Free-tier limits. Plus removes them.
enum FreeTier {
    static let maxSavedPeople = 3
}

@MainActor
final class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()

    @Published private(set) var products: [StoreProduct] = []
    @Published private(set) var isPlus = false
    @Published private(set) var isLoadingProducts = false
    @Published var purchaseError: String?

    private let store: PurchaseStore
    private var updatesTask: Task<Void, Never>?

    init(store: PurchaseStore = StoreKitPurchaseStore()) {
        self.store = store
        // Keep entitlement in sync with changes that arrive outside a purchase
        // flow (renewals, refunds, Ask to Buy, another device).
        updatesTask = Task { [weak self] in
            for await _ in store.entitlementUpdates() {
                guard let self else { return }
                await self.refreshEntitlement()
            }
        }
    }

    deinit { updatesTask?.cancel() }

    var monthly: StoreProduct? { products.first { $0.id == PlusProduct.monthly.rawValue } }
    var yearly:  StoreProduct? { products.first { $0.id == PlusProduct.yearly.rawValue } }

    // MARK: - Loading

    func loadProducts() async {
        guard products.isEmpty else { return }
        isLoadingProducts = true
        defer { isLoadingProducts = false }
        do {
            let ids = PlusProduct.allCases.map(\.rawValue)
            products = try await store.products(for: ids).sorted { $0.price < $1.price }
        } catch {
            purchaseError = error.localizedDescription
        }
    }

    // MARK: - Entitlement

    func refreshEntitlement() async {
        let entitlements = await store.currentEntitlements()
        isPlus = entitlements.contains { entitlement in
            Self.grantsPlus(productID: entitlement.productID,
                            expirationDate: entitlement.expirationDate,
                            revocationDate: entitlement.revocationDate)
        }
    }

    /// Pure entitlement rule. Rejects revoked entitlements, expired ones, and
    /// product IDs that aren't ours. A nil expiry is not treated as expired.
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
    func purchase(_ product: StoreProduct) async -> Bool {
        purchaseError = nil
        do {
            switch try await store.purchase(productID: product.id) {
            case .purchased:
                await refreshEntitlement()
                return isPlus
            case .cancelled, .pending:
                // Pending (e.g. Ask to Buy) arrives later through entitlementUpdates().
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
            try await store.syncPurchases()
            await refreshEntitlement()
        } catch {
            purchaseError = error.localizedDescription
        }
    }

    // MARK: - Display helpers

    /// Percentage saved by the yearly plan versus paying monthly for a year.
    var yearlySavingsPercent: Int? {
        guard let m = monthly, let y = yearly else { return nil }
        let twelveMonths = m.price * 12
        guard twelveMonths > 0 else { return nil }
        let saved = (twelveMonths - y.price) / twelveMonths
        return Int((saved as NSDecimalNumber).doubleValue * 100)
    }
}
