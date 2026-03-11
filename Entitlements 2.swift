//
//  Entitlements.swift
//  WolfmoreGolf
//
//  Created by Tom BUTLER on 1/25/26.
//

import Foundation

/// Single place to answer: "Is this user Pro?"
final class Entitlements {

    static let shared = Entitlements()

    private init() {}

    // Temporary local flag (great for testing). Later you’ll replace this with StoreKit.
    private let proKey = "wm_isPro"

    var isPro: Bool {
        get { UserDefaults.standard.bool(forKey: proKey) }
        set { UserDefaults.standard.set(newValue, forKey: proKey) }
    }

    // Optional helper to flip Pro on/off for debugging
    func setProForDebug(_ on: Bool) {
        isPro = on
    }
}
