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
    case matchPlay     // Fixed-team variant: teams set once, lowball scoring
    case hammer        // keep if you already used it; don’t use for new games
    case tournament    // Stableford individual scoring
}

extension GameType {
    var isWolf: Bool { self == .wolf || self == .wolfLowBall }
    var isMatchPlay: Bool { self == .matchPlay }
    var isScotch: Bool { self == .sixPointScotch }

    var displayName: String {
        switch self {
        case .wolf:           return "Wolf 2-Point"
        case .wolfLowBall:    return "Wolf LowBall"
        case .matchPlay:      return "Match Play"
        case .sixPointScotch: return "6-Point Scotch"
        case .hammer:         return "Hammer"
        case .tournament:     return "Tournament"
        }
    }
}

