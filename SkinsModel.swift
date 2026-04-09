//
//  SkinsModel.swift
//  WolfmoreGolf
//
//  Created by Tom BUTLER on 4/3/26.
//

import Foundation

enum SkinsMode: String, Codable {
    case automatic
    case manual
}

/// Kept for backward compatibility with any already-saved games.
/// New logic forces skins to always use .net.
enum SkinsScoringMode: String, Codable {
    case gross
    case net
}

struct SkinsSettings: Codable {
    var isEnabled: Bool = true
    var mode: SkinsMode = .automatic
    var scoringMode: SkinsScoringMode = .net
    var skinValue: Double = 1.0
    var carryoversEnabled: Bool = true
}

struct ManualSkinsHoleDecision: Codable {
    /// Usually one winner, but array keeps it flexible and Codable-safe.
    var winnerIndexes: [Int] = []

    /// If no winner is chosen manually, user can choose carryover.
    var shouldCarryOver: Bool = false

    /// nil = use current pot
    var awardedSkinCount: Int? = nil
}

struct SkinsHoleResult: Codable {
    var holeIndex: Int
    var potValue: Int = 1
    var winningPlayerIndexes: [Int] = []
    var awardedSkinCount: Int = 0
    var carriedToNextHole: Bool = false
    var note: String? = nil
}

struct SkinsState: Codable {
    var settings: SkinsSettings = SkinsSettings()

    /// One result per hole
    var resultsByHole: [SkinsHoleResult] = (0..<18).map {
        SkinsHoleResult(holeIndex: $0)
    }

    /// Used only when skins mode is manual
    var manualOverridesByHole: [ManualSkinsHoleDecision?] = Array(repeating: nil, count: 18)

    /// Totals by player seat index
    var skinsWonByPlayer: [Int] = Array(repeating: 0, count: 5)
    var moneyWonByPlayer: [Double] = Array(repeating: 0.0, count: 5)

    /// Separate from gameData.playerActivated.
    /// A player can be active in the round but excluded from skins.
    var playerIncluded: [Bool] = Array(repeating: true, count: 5)
}
