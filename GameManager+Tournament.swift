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
    /// Par mode: eagle=3, birdie=2, par=1, bogey+=0.
    /// Bogey mode: birdie+=3, par=2, bogey=1, double+=0. Both modes cap at 3.
    func stablefordPoints(
        grossScore: Int?,
        par: Int,
        playerHC: Int,
        strokeIndex: Int,
        baseline: StablefordBaseline = .par
    ) -> Int? {
        guard let gross = grossScore else { return nil }
        let strokes = absoluteStrokesGiven(playerHC: playerHC, strokeIndex: strokeIndex)
        let net = gross - strokes
        let offset = baseline == .bogey ? 1 : 0
        return min(3, max(0, 1 + offset - (net - par)))
    }

    /// Returns total Stableford points for a player across all played holes.
    /// Unplayed holes (nil score) are excluded.
    func totalStablefordPoints(playerIndex: Int, game: GameData, upThrough: Int? = nil) -> Int {
        let holesToSum = committedHoles(game: game, upThrough: upThrough)
        var total = 0
        for hole in holesToSum {
            let par   = game.parForHole(hole, player: playerIndex)
            let si    = game.hcForHole(hole, player: playerIndex)
            let hc    = game.hcPlayers[safe: playerIndex] ?? 0
            let gross = (playerIndex < game.scores.count) ? game.scores[playerIndex][hole] : nil
            if let pts = stablefordPoints(grossScore: gross, par: par, playerHC: hc,
                                          strokeIndex: si, baseline: game.stablefordBaseline) {
                total += pts
            }
        }
        return total
    }

    /// Holes from startHole through upThrough (or through the last hole if nil), wrapping for back-9 starts.
    private func committedHoles(game: GameData, upThrough: Int?) -> [Int] {
        let end     = max(0, min(17, upThrough ?? (STANDARD_HOLES - 1)))
        let start   = max(0, min(17, game.startHole ?? end))
        return start <= end
            ? Array(start...end)
            : Array(start..<STANDARD_HOLES) + Array(0...end)
    }

    /// Best-N Stableford points for one hole across all active players.
    /// N is set by game.stablefordCountingPlayers (2, 3, or 4).
    func teamHoleScore(hole: Int, game: GameData) -> Int {
        let capacity = min(game.playerNames.count, game.playerActivated.count)
        let activeSeats = (0..<capacity).filter {
            game.playerActivated[$0] &&
            !game.playerNames[$0].trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        let pts: [Int] = activeSeats.compactMap { seat in
            let par   = game.parForHole(hole, player: seat)
            let si    = game.hcForHole(hole, player: seat)
            let hc    = game.hcPlayers[safe: seat] ?? 0
            let gross = (seat < game.scores.count) ? game.scores[seat][hole] : nil
            return stablefordPoints(grossScore: gross, par: par, playerHC: hc, strokeIndex: si,
                                    baseline: game.stablefordBaseline)
        }
        let n = max(1, min(game.stablefordCountingPlayers, pts.count))
        return pts.sorted(by: >).prefix(n).reduce(0, +)
    }

    /// Sum of teamHoleScore across committed holes (start through upThrough, or all holes if nil).
    func runningTeamStablefordTotal(game: GameData, upThrough: Int? = nil) -> Int {
        committedHoles(game: game, upThrough: upThrough).reduce(0) { $0 + teamHoleScore(hole: $1, game: game) }
    }
}
