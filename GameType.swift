//
//  GameType.swift
//  WolfmoreGolf
//
//  Created by Tom BUTLER on 12/22/25.
//

import Foundation

enum GameType: String, Codable {
    case sixPointScotch
    case wolf          // Wolf (2-point)
    case wolfLowBall   // Wolf LowBall
    case matchPlay     // Fixed-team: holes-won/lost comparison, per-hole stake
    case bestBall      // Fixed-team: accumulate team-best-net stroke totals, no per-hole stake
    case hammer        // keep if you already used it; don’t use for new games
    case tournament    // Stableford individual scoring
}

extension GameType {
    var isWolf: Bool { self == .wolf || self == .wolfLowBall }
    /// True for both Match Play (holes up/down) and Best Ball (stroke total).
    var isMatchPlay: Bool { self == .matchPlay || self == .bestBall }
    var isBestBall:  Bool { self == .bestBall }
    var isScotch: Bool { self == .sixPointScotch }

    var displayName: String {
        switch self {
        case .wolf:           return "Wolf 2-Point"
        case .wolfLowBall:    return "Wolf LowBall"
        case .matchPlay:      return "Match Play"
        case .bestBall:       return "Best Ball"
        case .sixPointScotch: return "6-Point Scotch"
        case .hammer:         return "Hammer"
        case .tournament:     return "Tournament"
        }
    }
}

