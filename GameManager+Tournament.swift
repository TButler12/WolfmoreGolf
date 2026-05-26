//
//  GameManager+Tournament.swift
//  WolfmoreGolf
//

import Foundation

extension GameManager {

    // MARK: - Stableford helpers

    /// Returns handicap strokes received on a hole for Stableford.
    /// Uses the player's absolute handicap (not delta vs. field).
    func absoluteStrokesGiven(playerHC: Int, strokeIndex: Int) -> Int {
        let hc = max(0, playerHC)
        if hc <= 18 { return (strokeIndex <= hc) ? 1 : 0 }
        return 1 + ((strokeIndex <= (hc - 18)) ? 1 : 0)
    }

    /// Returns Stableford points for one player on one hole.
    /// Returns nil if gross score is nil (hole not yet played).
    func stablefordPoints(
        grossScore: Int?,
        par: Int,
        playerHC: Int,
        strokeIndex: Int
    ) -> Int? {
        guard let gross = grossScore else { return nil }
        let strokes = absoluteStrokesGiven(playerHC: playerHC, strokeIndex: strokeIndex)
        let net = gross - strokes
        return max(0, 1 - (net - par))
    }

    /// Returns total Stableford points for a player across all played holes.
    /// Unplayed holes (nil score) are excluded.
    func totalStablefordPoints(playerIndex: Int, game: GameData) -> Int {
        var total = 0
        for hole in 0..<STANDARD_HOLES {
            let par = game.courseParToPass[safe: hole] ?? 4
            let si  = game.courseHCToPass[safe: hole] ?? (hole + 1)
            let hc  = game.hcPlayers[safe: playerIndex] ?? 0
            let gross = (playerIndex < game.scores.count) ? game.scores[playerIndex][hole] : nil
            if let pts = stablefordPoints(
                grossScore: gross,
                par: par,
                playerHC: hc,
                strokeIndex: si
            ) { total += pts }
        }
        return total
    }

    /// Top-3 Stableford points for one hole across all active players.
    func teamHoleScore(hole: Int, game: GameData) -> Int {
        let capacity = min(game.playerNames.count, game.playerActivated.count)
        let activeSeats = (0..<capacity).filter {
            game.playerActivated[$0] &&
            !game.playerNames[$0].trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        let pts: [Int] = activeSeats.compactMap { seat in
            let par   = game.courseParToPass[safe: hole] ?? 4
            let si    = game.courseHCToPass[safe: hole] ?? (hole + 1)
            let hc    = game.hcPlayers[safe: seat] ?? 0
            let gross = (seat < game.scores.count) ? game.scores[seat][hole] : nil
            return stablefordPoints(grossScore: gross, par: par, playerHC: hc, strokeIndex: si)
        }
        return pts.sorted(by: >).prefix(3).reduce(0, +)
    }

    /// Sum of teamHoleScore across all 18 holes (only scored holes contribute).
    func runningTeamStablefordTotal(game: GameData) -> Int {
        (0..<STANDARD_HOLES).reduce(0) { $0 + teamHoleScore(hole: $1, game: game) }
    }
}
