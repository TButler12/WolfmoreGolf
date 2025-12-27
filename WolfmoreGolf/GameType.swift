//
//  GameType.swift
//  WolfmoreGolf
//
//  Created by Tom BUTLER on 12/22/25.
//

import Foundation

enum GameType: String, Codable {
    case sixPointScotch
    case wolf          // ✅ this remains your Wolf (2-point)
    case wolfLowBall   // ✅ NEW
    case hammer        // keep if you already used it; don’t use for new games
}

extension GameType {
    var isWolf: Bool { self == .wolf || self == .wolfLowBall }
    var isScotch: Bool { self == .sixPointScotch }
}

