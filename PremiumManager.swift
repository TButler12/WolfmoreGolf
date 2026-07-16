import StoreKit

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
            case .liveWolf:     return 5
            }
        }

        // When true, usageKey is scoped to the current calendar month (YYYY-MM).
        // The key changes each month, so the counter resets automatically with no manual logic.
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
            switch self {
            case .aiSummary:
                return "You've used your \(freeLimit) free AI Summary sessions this month."
            default:
                return "You've used your \(freeLimit) free \(displayName) sessions."
            }
        }
    }

    // MARK: - Status

    private(set) var isPremium = false {
        didSet {
            if isPremium { markPremiumThisMonth() }
            NotificationCenter.default.post(name: .premiumStatusChanged, object: nil)
        }
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
            products = try await Product.products(for: [Self.monthlyProductID])
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
        try await AppStore.sync()
        await refreshPremiumStatus()
    }

    func refreshPremiumStatus() async {
        let premiumIDs: Set<String> = [
            Self.monthlyProductID,
            Self.yearlyProductID,
            Self.legacyProProductID,
        ]
        var found = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let tx) = result,
               premiumIDs.contains(tx.productID),
               tx.revocationDate == nil {
                found = true
                break
            }
        }
        isPremium = found
    }
}

extension Notification.Name {
    static let premiumStatusChanged = Notification.Name("premiumStatusChanged")
}
