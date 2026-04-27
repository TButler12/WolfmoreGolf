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
        guard !players.isEmpty, holeHc.count == STANDARD_HOLES else { return [] }
        let minHC = players.compactMap { $0.handicap ?? 0 }.min() ?? 0
        let diffs = players.map { max(0, ($0.handicap ?? 0) - minHC) }
        var table = Array(repeating: Array(repeating: 0, count: players.count), count: STANDARD_HOLES)
        for h in 0..<STANDARD_HOLES {
            let idx = holeHc[h] // 1..18
            for p in players.indices {
                let base = diffs[p] / STANDARD_HOLES
                let rem  = diffs[p] % STANDARD_HOLES
                table[h][p] = base + ((idx <= rem) ? 1 : 0)
            }
        }
        return table
    }
}
