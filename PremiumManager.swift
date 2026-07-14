import StoreKit

@MainActor
final class PremiumManager {
    static let shared = PremiumManager()
    private init() {}

    static let monthlyProductID   = "com.wolfmoregolf.pro.monthly"
    static let legacyProProductID = "com.wolfmoregolf.pro"
    // MARK: - Feature

    enum Feature {
        case aiSummary, remoteNassau, liveWolf

        var freeLimit: Int {
            switch self {
            case .aiSummary:    return 20
            case .remoteNassau: return 5
            case .liveWolf:     return 5
            }
        }

        var usageKey: String {
            switch self {
            case .aiSummary:    return "aiSummaryUsageCount"
            case .remoteNassau: return "remoteNassauUsageCount"
            case .liveWolf:     return "liveWolfUsageCount"
            }
        }

        var displayName: String {
            switch self {
            case .aiSummary:    return "AI Summary"
            case .remoteNassau: return "Remote Nassau"
            case .liveWolf:     return "Live Wolf"
            }
        }
    }

    // MARK: - Status

    private(set) var isPremium = false {
        didSet { NotificationCenter.default.post(name: .premiumStatusChanged, object: nil) }
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

    func restorePurchases() async {
        try? await AppStore.sync()
        await refreshPremiumStatus()
    }

    func refreshPremiumStatus() async {
        let premiumIDs: Set<String> = [
            Self.monthlyProductID,
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
