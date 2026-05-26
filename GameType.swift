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
    case tournament    // Stableford individual scoring
}

extension GameType {
    var isWolf: Bool { self == .wolf || self == .wolfLowBall }
    var isScotch: Bool { self == .sixPointScotch }

    var displayName: String {
        switch self {
        case .wolf:           return "Wolf 2-Point"
        case .wolfLowBall:    return "Wolf LowBall"
        case .sixPointScotch: return "6-Point Scotch"
        case .hammer:         return "Hammer"
        case .tournament:     return "Tournament"
        }
    }
}

