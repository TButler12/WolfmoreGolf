//
//  RoundStore.swift
//  WolfmoreGolf
//
//  Created by Tom BUTLER on 11/6/25.
//


import Foundation

final class RoundStore {
    static let shared = RoundStore()
    private let key = "round.store.v1"
    private(set) var rounds: [RoundSummary] = []

    private init() { load() }

    func recordFromCurrentGame() {
        // …the code I gave you earlier that reads GameManager.currentGame
        // and appends a RoundSummary, then prune+save
    }

    // load/save/prune helpers…
}
