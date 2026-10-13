import Foundation

/// Pure-function helpers extracted from WolfSpectatorViewController so the format
/// detection and team best-net math can be unit tested independently of UIKit.
enum SpectatorScoring {

    // MARK: - Format detection

    struct Format {
        let isBestBall: Bool
        let isFourball: Bool
        var isTeamMatch: Bool { isBestBall || isFourball }
    }

    /// Determines the game format from a set of hole results.
    ///
    /// Fourball is identified by `decision == "matchplay"` with `partnerSlot` set.
    /// That combination is produced only by `GameType.fourball` in GameViewController;
    /// Singles match play has the same decision value but always has `partnerSlot == nil`.
    /// Wolf results never carry `decision == "matchplay"` regardless of partner status.
    static func detect(results: [WolfHoleResult]) -> Format {
        let isBestBall = results.contains { $0.decision == "bestball" }
        let isFourball = !isBestBall && results.contains {
            $0.decision == "matchplay" && $0.partnerSlot != nil
        }
        return Format(isBestBall: isBestBall, isFourball: isFourball)
    }

    // MARK: - Team best-net running totals

    /// Accumulates each team's best-net-vs-par score through `matchPos`.
    ///
    /// - Parameters:
    ///   - results: All hole results for the session (any order; keyed by `hole`).
    ///   - teamASeats: 0-based player indices on Team A (e.g. `[0, 1]` for Fourball).
    ///   - playerCount: Total number of players; used to derive Team B seats.
    ///   - matchPos: Include holes 1…matchPos (1-based match position).
    ///   - coursePars: 18-element par array (0-based course index).
    ///   - courseHCs: 18-element stroke-index array (0-based course index).
    ///   - playerHandicaps: Course handicaps for each seat (0-based).
    ///   - courseHoleIndex: Converts 1-based match position → 0-based course array index.
    ///     Default `(h-1) % STANDARD_HOLES` is correct for standard 18-hole sessions.
    /// - Returns: `(aSum, bSum)` where each is cumulative best-net-vs-par (negative = under par).
    static func teamBestNetSums(
        results: [WolfHoleResult],
        teamASeats: [Int],
        playerCount: Int,
        upThrough matchPos: Int,
        coursePars: [Int],
        courseHCs: [Int],
        playerHandicaps: [Int],
        courseHoleIndex: (Int) -> Int = { h in (h - 1) % STANDARD_HOLES }
    ) -> (aSum: Int, bSum: Int) {
        guard matchPos >= 1 else { return (0, 0) }
        let teamBSeats = (0..<playerCount).filter { !teamASeats.contains($0) }
        let baseHC = playerHandicaps.isEmpty ? 0 : (playerHandicaps.min() ?? 0)

        func pops(seat: Int, si: Int) -> Int {
            guard !playerHandicaps.isEmpty, seat < playerHandicaps.count else { return 0 }
            let delta = max(0, playerHandicaps[seat] - baseHC)
            if delta <= STANDARD_HOLES { return si <= delta ? 1 : 0 }
            return 1 + (si <= delta - STANDARD_HOLES ? 1 : 0)
        }

        let byHole = Dictionary(results.map { ($0.hole, $0) }, uniquingKeysWith: { a, _ in a })
        var aSum = 0, bSum = 0
        for h in 1...matchPos {
            guard let r = byHole[h], let scores = r.scores else { continue }
            let courseH = courseHoleIndex(h)
            let par = courseH < coursePars.count ? coursePars[courseH] : 4
            let si  = courseH < courseHCs.count  ? max(1, courseHCs[courseH]) : STANDARD_HOLES
            let aBest = teamASeats.compactMap { seat -> Int? in
                guard seat < scores.count, scores[seat] > 0 else { return nil }
                return scores[seat] - pops(seat: seat, si: si)
            }.min()
            let bBest = teamBSeats.compactMap { seat -> Int? in
                guard seat < scores.count, scores[seat] > 0 else { return nil }
                return scores[seat] - pops(seat: seat, si: si)
            }.min()
            if let a = aBest { aSum += a - par }
            if let b = bBest { bSum += b - par }
        }
        return (aSum, bSum)
    }
}
