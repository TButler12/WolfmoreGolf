//
import Foundation

/// All features are available to all users — no Pro gating.
final class Entitlements {
    static let shared = Entitlements()
    private init() {}

    var isPro: Bool { true }

    func canAccessStats(freeRoundsUsed: Int) -> Bool { true }
    func canAccess(feature: ProFeature, freeRoundsUsed: Int) -> Bool { true }
    func canUseStats(freeRoundsUsed: Int) -> Bool { true }

    enum ProFeature { case stats, texting, history }
}
