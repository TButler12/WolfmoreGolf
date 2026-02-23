//
//  ProStore.swift
//  WolfmoreGolf
//
//  Created by Tom BUTLER on 2/3/26.
//
import Foundation
import StoreKit
@available(iOS 15.0, *)

@MainActor
final class ProStore {

    static let shared = ProStore()

    private let productID = "com.wolfmoregolf.pro.yearly"

    private(set) var yearlyProduct: Product?
    private(set) var isLoaded: Bool = false

    // Cache only (nice for fast UI startup), not the truth
    private let proKey = "isProCache"

    private(set) var isPro: Bool {
        get { UserDefaults.standard.bool(forKey: proKey) }
        set { UserDefaults.standard.set(newValue, forKey: proKey) }
    }


    private var updatesTask: Task<Void, Never>?

    // Call once at app start (e.g., in AppDelegate/SceneDelegate/Home VC)
    func start() {
        // Listen for any transaction updates (renewals, revocations, etc.)
        if updatesTask == nil {
            updatesTask = Task { [weak self] in
                guard let self else { return }
                for await update in Transaction.updates {
                    // We only care if it’s our product, but easiest is to refresh entitlements
                    _ = try? self.checkVerified(update)
                    await self.refreshEntitlement()
                }
            }
        }
    }

    func loadProducts() async {
        // Allow retry if previous attempt failed
        if isLoaded, yearlyProduct != nil { return }

        do {
            let products = try await Product.products(for: [productID])
            yearlyProduct = products.first
            isLoaded = true

            #if DEBUG
            print("✅ StoreKit returned:", products.map { $0.id })
            print("✅ Yearly product:", yearlyProduct?.id ?? "nil")
            #endif
        } catch {
            yearlyProduct = nil
            isLoaded = false   // allow retry
            #if DEBUG
            print("❌ Failed to load products:", error)
            #endif
        }
    }

    func purchaseYearly() async throws {
        guard let product = yearlyProduct else {
            throw NSError(domain: "ProStore", code: 1, userInfo: [NSLocalizedDescriptionKey: "Product not loaded"])
        }

        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)

            // Finish first (good hygiene)
            await transaction.finish()

            // Then refresh entitlement from StoreKit (truth)
            await refreshEntitlement()

        case .userCancelled:
            throw CancellationError()

        case .pending:
            // Payment auth, SCA, etc. - user can complete later
            // Don’t flip entitlement yet
            break

        @unknown default:
            break
        }
    }

    func restore() async throws {
        try await AppStore.sync()
        await refreshEntitlement()
    }

    /// Source of truth: StoreKit entitlements
    func refreshEntitlement() async {
        var hasPro = false

        for await result in Transaction.currentEntitlements {
            guard case .verified(let t) = result else { continue }
            guard t.productID == productID else { continue }

            // If it was revoked, don’t count it
            if t.revocationDate != nil { continue }

            // If it expired (should be nil for active subs, but safe)
            if let expiration = t.expirationDate, expiration <= Date() { continue }

            hasPro = true
            break
        }

        isPro = hasPro
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let safe):
            return safe
        }
    }
    
}
