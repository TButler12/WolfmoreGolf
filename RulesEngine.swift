//
//  RulesEngine.swift
//  Wolfmore-5Man
//
//  Created by Tom BUTLER on 9/30/25.
// RulesEngine.swift
// Wolfmore-5Man
//
// Central place for all game rule calculations: strokes, pops, money.
import Foundation

enum RulesEngine {
    static func computePopsTable(players: [Player], holeHc: [Int]) -> [[Int]] {
        guard !players.isEmpty, holeHc.count == 18 else { return [] }
        let minHC = players.compactMap { $0.handicap ?? 0 }.min() ?? 0
        let diffs = players.map { max(0, ($0.handicap ?? 0) - minHC) }
        var table = Array(repeating: Array(repeating: 0, count: players.count), count: 18)
        for h in 0..<18 {
            let idx = holeHc[h] // 1..18
            for p in players.indices {
                let base = diffs[p] / 18
                let rem  = diffs[p] % 18
                table[h][p] = base + ((idx <= rem) ? 1 : 0)
            }
        }
        return table
    }
}
