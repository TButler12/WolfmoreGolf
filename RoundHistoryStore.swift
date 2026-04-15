//
//  RoundHistoryStore.swift
//  WolfmoreGolf
//
//  Created by Tom BUTLER on 4/14/26.
//

import Foundation

struct CompletedRound: Codable {
    let date: Date
    let courseName: String
    let playerName: String

    let holeScores: [Int?]
    let pars: [Int]

    let fairwaysHit: [Bool?]
    let girs: [Bool?]
    let putts: [Int?]

    let totalScore: Int
    let totalPutts: Int
    let fairwaysHitCount: Int
    let girCount: Int
}

final class RoundHistoryStore {

    static let shared = RoundHistoryStore()
    private init() {}

    private let lastRoundKey = "lastCompletedRound"

    // SAVE
    func saveLastRound(_ round: CompletedRound) {
        do {
            let data = try JSONEncoder().encode(round)
            UserDefaults.standard.set(data, forKey: lastRoundKey)
            print("✅ Saved last round")
        } catch {
            print("❌ Failed to save last round: \(error)")
        }
    }

    // LOAD
    func loadLastRound() -> CompletedRound? {
        guard let data = UserDefaults.standard.data(forKey: lastRoundKey) else {
            return nil
        }

        do {
            return try JSONDecoder().decode(CompletedRound.self, from: data)
        } catch {
            print("❌ Failed to load last round: \(error)")
            return nil
        }
    }

    // OPTIONAL CLEAR
    func clearLastRound() {
        UserDefaults.standard.removeObject(forKey: lastRoundKey)
    }
}
