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
    case matchPlay     // Individual: holes-won/lost, per-hole stake, 1v1 (or Dual 1v1+1v1)
    case fourball      // Fourball: team best-ball wins each hole, hole-by-hole stake
    case bestBall      // FB Stroke Play: accumulate team-best-net stroke totals, no per-hole stake
    case hammer        // keep if you already used it; don’t use for new games
    case tournament    // Stableford individual scoring
}

extension GameType {
    var isWolf: Bool { self == .wolf || self == .wolfLowBall }
    /// True for Individual, Fourball, and FB Stroke Play (all fixed-team formats).
    var isMatchPlay: Bool { self == .matchPlay || self == .fourball || self == .bestBall }
    var isBestBall:  Bool { self == .bestBall }
    var isFourball:  Bool { self == .fourball }
    var isScotch: Bool { self == .sixPointScotch }

    var displayName: String {
        switch self {
        case .wolf:           return "Wolf 2-Point"
        case .wolfLowBall:    return "Wolf LowBall"
        case .matchPlay:      return "Individual"
        case .fourball:       return "Fourball"
        case .bestBall:       return "FB Stroke Play"
        case .sixPointScotch: return "6-Point Scotch"
        case .hammer:         return "Hammer"
        case .tournament:     return "Tournament"
        }
    }
}

