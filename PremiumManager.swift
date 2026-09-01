import StoreKit
import UIKit

@MainActor
final class PremiumManager {
    static let shared = PremiumManager()
    private init() {}

    static let monthlyProductID   = "com.wolfmoregolf.pro.monthly"
    static let yearlyProductID    = "com.wolfmoregolf.pro.yearly"
    static let legacyProProductID = "com.wolfmoregolf.pro"        // bare ID kept for historical receipts
    // MARK: - Feature

    enum Feature {
        case aiSummary, remoteNassau, liveWolf

        var freeLimit: Int {
            switch self {
            case .aiSummary:    return 5
            case .remoteNassau: return 5
            case .liveWolf:     return 10
            }
        }

        // When true, usageKey is scoped to the current calendar month (YYYY-MM).
        // The key changes each month, so the counter resets automatically with no manual logic.
        // AI Summary resets monthly (real API cost per call). Nassau/LiveWolf are lifetime caps.
        var resetsMonthly: Bool {
            switch self {
            case .aiSummary: return true
            default:         return false
            }
        }

        var usageKey: String {
            let base: String
            switch self {
            case .aiSummary:    base = "aiSummaryUsageCount"
            case .remoteNassau: base = "remoteNassauUsageCount"
            case .liveWolf:     base = "liveWolfUsageCount"
            }
            guard resetsMonthly else { return base }
            let fmt = DateFormatter()
            fmt.dateFormat = "yyyy-MM"
            return "\(base)_\(fmt.string(from: Date()))"
        }

        var displayName: String {
            switch self {
            case .aiSummary:    return "AI Summary"
            case .remoteNassau: return "Remote Nassau"
            case .liveWolf:     return "Live Wolf"
            }
        }

        // Used by PaywallViewController limit label.
        var limitMessage: String {
            resetsMonthly
                ? "You've used your \(freeLimit) free \(displayName) sessions this month."
                : "You've used your \(freeLimit) free \(displayName) sessions."
        }
    }

    // MARK: - Status

    // All product IDs returned by Transaction.currentEntitlements on last refresh (for diagnostics)
    private(set) var lastSeenEntitlementIDs: [String] = []

    private var _isPremium = false {
        didSet {
            if _isPremium { markPremiumThisMonth() }
            NotificationCenter.default.post(name: .premiumStatusChanged, object: nil)
        }
    }

    var isPremium: Bool {
        #if DEBUG
        return _isPremium || debugForcePremiumActive
        #else
        return _isPremium
        #endif
    }

    // Persists a month-keyed flag so was_premium_this_month can be read reliably
    // even after a downgrade, without inferring from usage counts.
    private func markPremiumThisMonth() {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM"
        UserDefaults.standard.set(true, forKey: "wasPremiumInMonth_\(fmt.string(from: Date()))")
    }

    static func wasPremiumThisMonth() -> Bool {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM"
        return UserDefaults.standard.bool(forKey: "wasPremiumInMonth_\(fmt.string(from: Date()))")
    }

    private(set) var products: [Product] = []
    private var listenerTask: Task<Void, Never>?

    // MARK: - Usage

    func usageCount(for feature: Feature) -> Int {
        UserDefaults.standard.integer(forKey: feature.usageKey)
    }

    func remainingFreeUses(for feature: Feature) -> Int {
        max(0, feature.freeLimit - usageCount(for: feature))
    }

    func canUse(_ feature: Feature) -> Bool {
        isPremium || usageCount(for: feature) < feature.freeLimit
    }

    func recordUse(_ feature: Feature) {
        let key = feature.usageKey
        UserDefaults.standard.set(UserDefaults.standard.integer(forKey: key) + 1, forKey: key)
        NotificationCenter.default.post(name: .premiumStatusChanged, object: nil)
    }

    #if DEBUG
    var debugForcePremiumActive: Bool {
        get {
            // Default ON in DEBUG — explicit tap to OFF required to test real paywall flows.
            guard UserDefaults.standard.object(forKey: "debugForcePremium") != nil else { return true }
            return UserDefaults.standard.bool(forKey: "debugForcePremium")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "debugForcePremium")
            NotificationCenter.default.post(name: .premiumStatusChanged, object: nil)
        }
    }

    func debugToggleForcePremium() {
        debugForcePremiumActive = !debugForcePremiumActive
    }

    func debugResetAllUsage() {
        for feature in [Feature.aiSummary, .remoteNassau, .liveWolf] {
            UserDefaults.standard.set(0, forKey: feature.usageKey)
        }
        NotificationCenter.default.post(name: .premiumStatusChanged, object: nil)
    }
    #endif

    // Shows a non-blocking usage reminder after a free-tier session completes.
    func nudgeIfNeeded(for feature: Feature, from presenter: UIViewController) {
        guard !isPremium else { return }
        let remaining = remainingFreeUses(for: feature)
        let message: String
        switch remaining {
        case 0:
            message = "That was your last free \(feature.displayName) session this month. Upgrade for unlimited access."
        case 1:
            message = "Heads up — 1 free \(feature.displayName) session left this month."
        default:
            message = "\(remaining) free \(feature.displayName) sessions remaining this month."
        }
        showToast(message, from: presenter)
    }

    private func showToast(_ message: String, from presenter: UIViewController) {
        guard let view = presenter.viewIfLoaded else { return }

        let toast = UIView()
        toast.backgroundColor = UIColor.black.withAlphaComponent(0.80)
        toast.layer.cornerRadius = 12
        toast.translatesAutoresizingMaskIntoConstraints = false

        let label = UILabel()
        label.text = message
        label.font = .systemFont(ofSize: 13, weight: .medium)
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        toast.addSubview(label)
        view.addSubview(toast)

        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: toast.topAnchor, constant: 10),
            label.leadingAnchor.constraint(equalTo: toast.leadingAnchor, constant: 14),
            label.trailingAnchor.constraint(equalTo: toast.trailingAnchor, constant: -14),
            label.bottomAnchor.constraint(equalTo: toast.bottomAnchor, constant: -10),
            toast.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            toast.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            toast.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
        ])

        toast.alpha = 0
        UIView.animate(withDuration: 0.3) { toast.alpha = 1 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            UIView.animate(withDuration: 0.4, animations: { toast.alpha = 0 }) { _ in
                toast.removeFromSuperview()
            }
        }
    }

    // MARK: - Lifecycle

    func start() {
        listenerTask = Task { [weak self] in
            for await result in Transaction.updates {
                if case .verified(let tx) = result {
                    await tx.finish()
                    await self?.refreshPremiumStatus()
                }
            }
        }
        Task { await refreshPremiumStatus() }
        Task { await loadProducts() }
    }

    // MARK: - StoreKit

    func loadProducts() async {
        do {
            products = try await Product.products(for: [Self.monthlyProductID, Self.yearlyProductID])
                .sorted { $0.price < $1.price }
        } catch {
            // Products unavailable in this environment (e.g. simulator without StoreKit config)
        }
    }

    func purchase(_ product: Product) async throws -> Bool {
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            guard case .verified(let tx) = verification else { return false }
            await tx.finish()
            await refreshPremiumStatus()
            return isPremium
        case .userCancelled, .pending:
            return false
        @unknown default:
            return false
        }
    }

    func restorePurchases() async throws {
        print("[PremiumManager] AppStore.sync() starting…")
        try await AppStore.sync()
        print("[PremiumManager] AppStore.sync() completed")
        await refreshPremiumStatus()
        lastRestoreDiagnostic = isPremium ? nil : buildRestoreDiagnostic()
    }

    // Set by restorePurchases() when restore does not yield premium access.
    private(set) var lastRestoreDiagnostic: String? = nil

    private func buildRestoreDiagnostic() -> String {
        if lastSeenEntitlementIDs.isEmpty {
            return "No WolfMore purchases were found for the Apple ID signed in on this device. Make sure you're signed in with the same Apple ID used to purchase WolfMore Premium."
        }
        // Past WolfMore transactions exist but none are currently active — subscription has lapsed.
        return "A past WolfMore subscription was found but it is no longer active. To re-enable premium features, subscribe again from the upgrade options above."
    }

    func refreshPremiumStatus() async {
        var found = false
        var seenIDs: [String] = []

        // Pass 1: currentEntitlements covers active auto-renewable subscriptions
        // (monthly and yearly). The legacy product is a Non-Renewing Subscription and
        // is explicitly excluded from this API by Apple — handled in Pass 2.
        let subscriptionIDs: Set<String> = [Self.monthlyProductID, Self.yearlyProductID]
        for await result in Transaction.currentEntitlements {
            switch result {
            case .verified(let tx):
                let expired = tx.expirationDate.map { $0 < Date() } ?? false
                seenIDs.append(tx.productID)
                print("[PremiumManager] entitlement: \(tx.productID) revoked=\(tx.revocationDate != nil) expires=\(String(describing: tx.expirationDate)) isExpired=\(expired)")
                if subscriptionIDs.contains(tx.productID), tx.revocationDate == nil {
                    found = true
                }
            case .unverified(let tx, let error):
                seenIDs.append("UNVERIFIED:\(tx.productID)")
                print("[PremiumManager] UNVERIFIED entitlement: \(tx.productID) error=\(error)")
            }
        }

        // Pass 2: scan Transaction.all for the legacy Non-Renewing Subscription.
        // com.wolfmoregolf.pro is explicitly excluded from Transaction.currentEntitlements by
        // Apple (NRS products never appear there). Any verified, unrevoked purchase grants
        // permanent access — NRS products have no expiration date.
        //
        // This runs unconditionally so it always produces diagnostic output. Every item
        // Transaction.all yields is logged, regardless of product ID, so we can distinguish
        // between "sequence is empty" (wrong Apple ID / nothing synced) and
        // "sequence has items but none matched" (product ID mismatch).
        let knownIDs: Set<String> = [Self.monthlyProductID, Self.yearlyProductID, Self.legacyProProductID]
        print("[PremiumManager] Pass 2 — scanning Transaction.all (all items logged)…")
        var allTxCount = 0
        for await result in Transaction.all {
            allTxCount += 1
            switch result {
            case .verified(let tx):
                let isKnown   = knownIDs.contains(tx.productID)
                let isRevoked = tx.revocationDate != nil
                print("[PremiumManager] tx[\(allTxCount)]: id=\(tx.productID) purchased=\(tx.purchaseDate) expires=\(String(describing: tx.expirationDate)) revoked=\(isRevoked) wolfmore=\(isKnown)")
                if isKnown {
                    // Record in seenIDs for all known WolfMore products so buildRestoreDiagnostic()
                    // can distinguish "nothing found" from "found but expired/inactive".
                    seenIDs.append(tx.productID)
                }
                if tx.productID == Self.legacyProProductID && !isRevoked {
                    // Legacy Non-Renewing Subscription: any unrevoked purchase grants permanent access.
                    found = true
                }
            case .unverified(let tx, let error):
                print("[PremiumManager] tx[\(allTxCount)] UNVERIFIED: id=\(tx.productID) error=\(error)")
            }
        }
        print("[PremiumManager] Pass 2 complete — \(allTxCount) total tx in Transaction.all")

        lastSeenEntitlementIDs = seenIDs
        print("[PremiumManager] refreshPremiumStatus complete — isPremium=\(found), seenIDs=\(seenIDs)")
        _isPremium = found
    }
}

extension Notification.Name {
    static let premiumStatusChanged = Notification.Name("premiumStatusChanged")
}
