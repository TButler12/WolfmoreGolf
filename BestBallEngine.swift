import Foundation

// MARK: - Score input (shared with FieldSkinsEngine)

/// A player's score on one hole.
public enum HoleScore: Equatable {
    case notEntered   // hole not yet played / scored
    case pickedUp     // player lifted ball; partner's score counts for the team; excluded from skins
    case gross(Int)   // actual strokes taken
}

// MARK: - BestBallEngine

/// Pure scoring logic for 2-man best-ball team events.
/// No UIKit, no Supabase — safe to call from tests and background queues.
public enum BestBallEngine {

    // MARK: Inputs

    public struct PlayerInput {
        public let playerID: UUID
        public let courseHandicap: Int   // signed: negative = plus handicap
        public let scores: [HoleScore]   // exactly 18 elements
        public init(playerID: UUID, courseHandicap: Int, scores: [HoleScore]) {
            self.playerID = playerID; self.courseHandicap = courseHandicap; self.scores = scores
        }
    }

    public struct TeamInput {
        public let teamID: UUID
        public let teamName: String
        public let players: [PlayerInput]  // 1 or 2; solo = skins-only, no best-ball partner
        public init(teamID: UUID, teamName: String, players: [PlayerInput]) {
            self.teamID = teamID; self.teamName = teamName; self.players = players
        }
    }

    public struct GroupInput {
        public let teams: [TeamInput]
        public let holeHandicapRanks: [Int]       // 18 elements; rank 1 = hardest hole
        public let par: [Int]                      // 18 elements
        public let allowance: Double               // 1.0 = full HC; organizer-adjustable
        public let bothPickedUpMaxNetOverPar: Int  // cap when all partners pick up; default 2
        public init(teams: [TeamInput], holeHandicapRanks: [Int], par: [Int],
                    allowance: Double = 1.0, bothPickedUpMaxNetOverPar: Int = 2) {
            self.teams = teams; self.holeHandicapRanks = holeHandicapRanks; self.par = par
            self.allowance = allowance; self.bothPickedUpMaxNetOverPar = bothPickedUpMaxNetOverPar
        }
    }

    // MARK: Outputs

    public struct PlayerHoleResult {
        public let playerID: UUID
        public let score: HoleScore
        public let strokes: Int       // + = received; − = given away (plus handicap)
        public let net: Int?          // gross − strokes; nil if not entered or picked up
        public let countsForSkins: Bool
    }

    public struct TeamHoleResult {
        public let teamID: UUID
        public let playerResults: [PlayerHoleResult]
        public let bestGross: Int?
        public let bestGrossPlayerID: UUID?
        public let bestNet: Int?           // nil only when no player has scored (all notEntered)
        public let bestNetPlayerID: UUID?  // nil when bothPickedUp cap is used
        public let bothPickedUp: Bool
        public let netToPar: Int?          // bestNet − par; nil when bestNet is nil
        public let grossToPar: Int?
    }

    public struct HoleResult {
        public let holeNumber: Int  // 1-based
        public let par: Int
        public let teamResults: [TeamHoleResult]
    }

    public struct TeamTotal {
        public let teamID: UUID
        public let teamName: String
        public let front9NetToPar: Int?
        public let back9NetToPar: Int?
        public let totalNetToPar: Int?
        public let front9GrossToPar: Int?
        public let back9GrossToPar: Int?
        public let totalGrossToPar: Int?
        public let holesPlayed: Int
        // Per-hole net-to-par indexed 0…17 (index 0 = hole 1). Used for tiebreaks.
        // nil means that hole has not yet been scored.
        public let holeNetToPar: [Int?]
    }

    public struct LeaderboardEntry {
        public let rank: Int
        public let teamID: UUID
        public let teamName: String
        public let totalNetToPar: Int?
        public let totalGrossToPar: Int?
        public let holesPlayed: Int
        // Non-nil when this team shares totalNetToPar with at least one other team.
        public let tiebreakReason: TiebreakReason?
    }

    public enum TiebreakReason: Equatable {
        case back9    // separated on holes 10-18
        case back6    // separated on holes 13-18
        case back3    // separated on holes 16-18
        case hole18   // separated on hole 18 alone
        case stillTied
    }

    // MARK: Stroke calculation
    //
    // For effectiveHC ≥ 0:  floor(HC / 18) + (holeRank ≤ HC % 18 ? 1 : 0)
    //   HC  0: 0 strokes everywhere
    //   HC 18: 1 stroke everywhere (18/18=1, 18%18=0 → never +1)
    //   HC 20: 1 on all + extra on SI 1-2  (20/18=1, 20%18=2)
    //   HC 36: 2 strokes everywhere
    //   HC 38: 2 on all + extra on SI 1-2  (38/18=2, 38%18=2)
    //
    // For effectiveHC < 0 (plus handicap):
    //   −1 on the |HC| easiest holes (highest ranks), 0 elsewhere.
    //   e.g. +2 → give 1 stroke on SI 17 and 18.

    public static func strokes(courseHC: Int, holeRank: Int, allowance: Double = 1.0) -> Int {
        let eff = Int((Double(courseHC) * allowance).rounded())
        return rawStrokes(effectiveHC: eff, holeRank: holeRank)
    }

    public static func rawStrokes(effectiveHC: Int, holeRank: Int, holeCount: Int = 18) -> Int {
        guard effectiveHC >= 0 else {
            return holeRank >= (holeCount + 1 + effectiveHC) ? -1 : 0
        }
        return effectiveHC / holeCount + (holeRank <= effectiveHC % holeCount ? 1 : 0)
    }

    // MARK: Per-hole results

    public static func holeResults(for input: GroupInput) -> [HoleResult] {
        precondition(input.holeHandicapRanks.count == 18, "Need exactly 18 hole handicap ranks")
        precondition(input.par.count == 18, "Need exactly 18 pars")
        return (0..<18).map { h in
            let rank = input.holeHandicapRanks[h]
            let p    = input.par[h]
            return HoleResult(
                holeNumber: h + 1,
                par: p,
                teamResults: input.teams.map { buildTeamHoleResult($0, h: h, rank: rank, par: p, input: input) }
            )
        }
    }

    private static func buildTeamHoleResult(
        _ team: TeamInput, h: Int, rank: Int, par: Int, input: GroupInput
    ) -> TeamHoleResult {
        let playerResults: [PlayerHoleResult] = team.players.map { player in
            let eff = Int((Double(player.courseHandicap) * input.allowance).rounded())
            let s   = rawStrokes(effectiveHC: eff, holeRank: rank)
            switch player.scores[h] {
            case .notEntered:
                return PlayerHoleResult(playerID: player.playerID, score: .notEntered,
                                        strokes: s, net: nil, countsForSkins: false)
            case .pickedUp:
                return PlayerHoleResult(playerID: player.playerID, score: .pickedUp,
                                        strokes: s, net: nil, countsForSkins: false)
            case .gross(let g):
                return PlayerHoleResult(playerID: player.playerID, score: .gross(g),
                                        strokes: s, net: g - s, countsForSkins: true)
            }
        }

        let grossPairs: [(UUID, Int)] = playerResults.compactMap {
            if case .gross(let g) = $0.score { return ($0.playerID, g) } else { return nil }
        }
        let netPairs: [(UUID, Int)] = playerResults.compactMap {
            guard let n = $0.net else { return nil }; return ($0.playerID, n)
        }

        // Both-picked-up cap: applies only when ALL team players scored .pickedUp (not .notEntered)
        let bothPickedUp: Bool = {
            guard team.players.count >= 2 else { return false }
            return team.players.allSatisfy { p in
                if case .pickedUp = p.scores[h] { return true } else { return false }
            }
        }()

        let bestGrossPair = grossPairs.min(by: { $0.1 < $1.1 })
        let bestNetPair   = bothPickedUp ? nil : netPairs.min(by: { $0.1 < $1.1 })
        let bestNet: Int? = bothPickedUp ? (par + input.bothPickedUpMaxNetOverPar) : bestNetPair?.1

        return TeamHoleResult(
            teamID: team.teamID,
            playerResults: playerResults,
            bestGross: bestGrossPair?.1,
            bestGrossPlayerID: bestGrossPair?.0,
            bestNet: bestNet,
            bestNetPlayerID: bothPickedUp ? nil : bestNetPair?.0,
            bothPickedUp: bothPickedUp,
            netToPar: bestNet.map { $0 - par },
            grossToPar: bestGrossPair.map { $0.1 - par }
        )
    }

    // MARK: Team totals

    public static func teamTotals(from holeResults: [HoleResult], teams: [TeamInput]) -> [TeamTotal] {
        teams.map { team in
            var holeNetToPar   = [Int?](repeating: nil, count: 18)
            var holeGrossToPar = [Int?](repeating: nil, count: 18)
            var played = 0
            for hole in holeResults {
                guard let tr = hole.teamResults.first(where: { $0.teamID == team.teamID }) else { continue }
                let idx = hole.holeNumber - 1
                holeNetToPar[idx]   = tr.netToPar
                holeGrossToPar[idx] = tr.grossToPar
                if tr.netToPar != nil { played += 1 }
            }
            func sum(_ s: ArraySlice<Int?>) -> Int? {
                let vs = s.compactMap { $0 }; return vs.isEmpty ? nil : vs.reduce(0, +)
            }
            return TeamTotal(
                teamID: team.teamID, teamName: team.teamName,
                front9NetToPar:   sum(holeNetToPar[0..<9]),
                back9NetToPar:    sum(holeNetToPar[9..<18]),
                totalNetToPar:    sum(holeNetToPar[0..<18]),
                front9GrossToPar: sum(holeGrossToPar[0..<9]),
                back9GrossToPar:  sum(holeGrossToPar[9..<18]),
                totalGrossToPar:  sum(holeGrossToPar[0..<18]),
                holesPlayed: played,
                holeNetToPar: holeNetToPar
            )
        }
    }

    // MARK: Leaderboard
    // Ranked by totalNetToPar ascending; nil (not started) last.
    // Tiebreaks: back 9 → back 6 → back 3 → hole 18 (all by hole number, shotgun-safe).

    public static func leaderboard(from totals: [TeamTotal]) -> [LeaderboardEntry] {
        let sorted = totals.sorted { a, b in
            switch (a.totalNetToPar, b.totalNetToPar) {
            case (nil, nil):       return false
            case (nil, _):         return false
            case (_, nil):         return true
            case (let va?, let vb?):
                if va != vb { return va < vb }
                return tiebreakOrder(a, b) == .ascending
            }
        }

        var entries = [LeaderboardEntry]()
        var rank = 1
        for (i, total) in sorted.enumerated() {
            if i > 0 {
                let prev = sorted[i - 1]
                let separated = total.totalNetToPar != prev.totalNetToPar
                              || tiebreakOrder(total, prev) != .same
                if separated { rank = i + 1 }
            }
            let peers = sorted.filter { $0.teamID != total.teamID && $0.totalNetToPar == total.totalNetToPar }
            entries.append(LeaderboardEntry(
                rank: rank,
                teamID: total.teamID, teamName: total.teamName,
                totalNetToPar: total.totalNetToPar, totalGrossToPar: total.totalGrossToPar,
                holesPlayed: total.holesPlayed,
                tiebreakReason: peers.isEmpty ? nil : tiebreakReason(for: total, peers: peers)
            ))
        }
        return entries
    }

    // MARK: Tiebreak helpers

    private enum Order { case ascending, same, descending }

    private static func tiebreakOrder(_ a: TeamTotal, _ b: TeamTotal) -> Order {
        for indices: Range<Int> in [9..<18, 12..<18, 15..<18] {
            if let va = subtotal(a.holeNetToPar, indices: indices),
               let vb = subtotal(b.holeNetToPar, indices: indices),
               va != vb { return va < vb ? .ascending : .descending }
        }
        if let va = a.holeNetToPar[17], let vb = b.holeNetToPar[17], va != vb {
            return va < vb ? .ascending : .descending
        }
        return .same
    }

    // Returns the tiebreak level at which this team is separated from at least one peer.
    private static func tiebreakReason(for total: TeamTotal, peers: [TeamTotal]) -> TiebreakReason {
        for (indices, reason): (Range<Int>, TiebreakReason) in [(9..<18, .back9), (12..<18, .back6), (15..<18, .back3)] {
            if let myVal = subtotal(total.holeNetToPar, indices: indices),
               peers.contains(where: { subtotal($0.holeNetToPar, indices: indices).map { $0 != myVal } ?? false }) {
                return reason
            }
        }
        if let h18 = total.holeNetToPar[17],
           peers.contains(where: { $0.holeNetToPar[17].map { $0 != h18 } ?? false }) {
            return .hole18
        }
        return .stillTied
    }

    private static func subtotal(_ vals: [Int?], indices: Range<Int>) -> Int? {
        let vs = indices.compactMap { vals[$0] }
        return vs.isEmpty ? nil : vs.reduce(0, +)
    }
}
