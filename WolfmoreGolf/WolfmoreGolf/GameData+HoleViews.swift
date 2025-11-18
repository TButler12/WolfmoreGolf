//
//  GameData+HoleViews.swift
// 
//
//  Created by Tom BUTLER on 10/8/25.
//

import Foundation
// MARK: - GameData hole-first views (keep storage unchanged)
extension GameData {
    // Generic transpose for rectangular matrices (your arrays are rectangular)
    private func transpose<T>(_ m: [[T]]) -> [[T]] {
        guard let cols = m.first?.count else { return [] }
        return (0..<cols).map { c in m.map { $0[c] } }
    }

    // [hole][player] view of scores (backed by scores [player][hole])
    var scoresByHole: [[Int?]] {
        get { transpose(scores) }
        set { scores = transpose(newValue) }
    }

    // [hole][player] view of dollars (backed by playerMoney [player][hole])
    var moneyByHole: [[Double]] {
        get { transpose(playerMoney) }
        set { playerMoney = transpose(newValue) }
    }

    // Wolf: your storage is wolfButtonStatus [player][hole] with 9 players.
    var wolfMaskByHole: [[Bool]] {
        get { transpose(wolfButtonStatus) }            // -> [18][9]
        set { wolfButtonStatus = transpose(newValue.map { Array($0.prefix(wolfButtonStatus.count)) }) }
    }

    // Single-wolf index per hole (nil if none or >1)
    var wolfIndexPerHole: [Int?] {
        get {
            wolfMaskByHole.map { row in
                let idxs = row.enumerated().compactMap { $0.element ? $0.offset : nil }
                return idxs.count == 1 ? idxs.first : nil
            }
        }
        // Setter for: var wolfIndexPerHole: [Int?]
        set {
            var mask = wolfMaskByHole                  // [hole][player]
            let upper = min(Self.holes, newValue.count)

            for h in 0..<upper {
                // clear existing wolf for this hole
                for p in 0..<mask[h].count { mask[h][p] = false }

                // set new wolf if provided and in range
                if let s = newValue[h], s >= 0, s < mask[h].count {
                    mask[h][s] = true
                }
                // if newValue[h] == nil, leave the hole with no wolf
            }

            // (Optional) clear wolves for holes beyond newValue.count:
            // for h in upper..<mask.count { for p in 0..<mask[h].count { mask[h][p] = false } }

            wolfMaskByHole = mask
        }

    }

    // MARK: Setters for the *current* hole (no press touched)
    mutating func setScoreForCurrentHole(player seat: Int, _ value: Int?) {
        guard (0..<Self.capacity).contains(seat), (0..<Self.holes).contains(hole) else { return }
        scores[seat][hole] = value
    }

    mutating func setMoneyForCurrentHole(player seat: Int, _ value: Double) {
        guard (0..<Self.capacity).contains(seat), (0..<Self.holes).contains(hole) else { return }
        playerMoney[seat][hole] = value
    }

    mutating func toggleProxForCurrentHole(player seat: Int) {
        guard (0..<Self.holes).contains(hole) else { return }
        proxWinnerPerHole[hole] = (proxWinnerPerHole[hole] == seat) ? nil : seat
    }

    mutating func setWolfForCurrentHole(player seat: Int?) {
        var arr = wolfIndexPerHole
        arr[hole] = seat
        wolfIndexPerHole = arr
    }
}

