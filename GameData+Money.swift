//
//  GameData+Money.swift
//  Wolfmore-7Man
//
//  Created by Tom BUTLER on 10/9/25.
//

import Foundation


extension GameData {
    mutating func setMoneyForCurrentHole(player seat: Int, amount: Double) {
        guard (0..<Self.capacity).contains(seat),
              (0..<Self.holes).contains(hole) else { return }
        playerMoney[seat][hole] = amount
    }

    func moneyFor(hole h: Int, player seat: Int) -> Double {
        playerMoney[safe: seat]?[safe: h] ?? 0.0
    }
}
extension GameData {
    static let holes = STANDARD_HOLES
    static let capacity = MAX_PLAYERS
}


