//
import Foundation

/// Single place to answer: "Is this user Pro?"
final class Entitlements {

    static let shared = Entitlements()
    private init() {}

    // Optional local override for DEBUG builds only
    private let debugProKey = "wm_debug_isPro_override"

    var isPro: Bool {
        #if DEBUG
        // If you set an override, use it
        if let raw = UserDefaults.standard.object(forKey: debugProKey) as? Bool {
            return raw
        }
        #endif

        // ✅ Real source of truth
        return ProStore.shared.isPro
    }

    #if DEBUG
    func setProForDebug(_ on: Bool?) {
        // Pass nil to clear override and go back to ProStore
        if let on {
            UserDefaults.standard.set(on, forKey: debugProKey)
        } else {
            UserDefaults.standard.removeObject(forKey: debugProKey)
        }
    }
    #endif
}
extension Entitlements {

    /// Free tier: allow advanced stats until user has logged 10 completed rounds.
    func canAccessStats(freeRoundsUsed: Int) -> Bool {
        return isPro || freeRoundsUsed < 10
    }

    /// Generic helper if you want to reuse elsewhere.
    func canAccess(feature: ProFeature, freeRoundsUsed: Int) -> Bool {
        switch feature {
        case .stats:
            return isPro || freeRoundsUsed < 10
        case .texting:
            return isPro // no free use
        case .history:
            return isPro || freeRoundsUsed < 10 // or change as you like
        }
    }

    enum ProFeature {
        case stats
        case texting
        case history
    }
}
extension Entitlements {
    func canUseStats(freeRoundsUsed: Int) -> Bool {
        return isPro || freeRoundsUsed < 10
    }
}
