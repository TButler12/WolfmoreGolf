//
//  ReviewPrompter.swift
//  WolfmoreGolf
//

import StoreKit
import UIKit

enum ReviewPrompter {

    private static let key = "hasBeenPromptedForReview"

    static func maybeRequest(in scene: UIWindowScene) {
        guard !UserDefaults.standard.bool(forKey: key) else { return }
        let uniqueRounds = Set(RoundStore.shared.rounds.map(\.gameID)).count
        guard uniqueRounds >= 3 else { return }
        UserDefaults.standard.set(true, forKey: key)
        SKStoreReviewController.requestReview(in: scene)
    }
}
