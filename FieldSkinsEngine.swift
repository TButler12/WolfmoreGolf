import Foundation

// Uses HoleScore and BestBallEngine.rawStrokes from BestBallEngine.swift (same module).

/// Pure field-wide skins computation for club events.
/// All 40 players' scores go in; each hole's gross and net skin come out.
/// No UIKit, no Supabase.
public enum FieldSkinsEngine {

    // MARK: Inputs

    public struct PlayerInput {
        public let playerID: UUID
        public let courseHandicap: Int   // signed: negative = plus handicap
        public let scores: [HoleScore]   // exactly 18 elements
        /// true = this player's group has committed (posted) that hole.
        /// A picked-up player counts as posted for provisional purposes.
        public let groupPosted: [Bool]   // exactly 18 elements
        public init(playerID: UUID, courseHandicap: Int, scores: [HoleScore], groupPosted: [Bool]) {
            self.playerID = playerID; self.courseHandicap = courseHandicap
            self.scores = scores; self.groupPosted = groupPosted
        }
    }

    public struct Settings {
        public let holeHandicapRanks: [Int]  // 18 elements; rank 1 = hardest
        public let allowance: Double         // 1.0 = full HC; default 1.0
        public let carryoverEnabled: Bool    // tied hole carries pot to next; default false
        /// When false (default) a tie on hole 18 leaves the accumulated pot unawarded.
        /// When true the UI/payout layer should split the pot among tied players.
        /// The engine produces the same output either way (winner = nil, tied IDs listed).
        public let awardCarryoverOnLastHoleTie: Bool
        public let potGrossPerHole: Double
        public let potNetPerHole: Double
        public init(holeHandicapRanks: [Int], allowance: Double = 1.0,
                    carryoverEnabled: Bool = false, awardCarryoverOnLastHoleTie: Bool = false,
                    potGrossPerHole: Double = 0, potNetPerHole: Double = 0) {
            self.holeHandicapRanks = holeHandicapRanks; self.allowance = allowance
            self.carryoverEnabled = carryoverEnabled
            self.awardCarryoverOnLastHoleTie = awardCarryoverOnLastHoleTie
            self.potGrossPerHole = potGrossPerHole; self.potNetPerHole = potNetPerHole
        }
    }

    // MARK: Output

    public struct SkinResult {
        public let holeNumber: Int  // 1-based

        // Gross skin ─────────────────────────────────────────────────────────
        /// Non-nil = winner (may be provisional if isProvisional is true).
        public let grossWinner: UUID?
        /// Non-empty when two or more posted players are tied for the minimum gross score.
        public let grossTied: [UUID]
        /// True if at least one group has not yet posted this hole.
        /// A non-nil grossWinner + isProvisional = current leader, not yet confirmed.
        public let grossIsProvisional: Bool
        /// Total gross pot at stake on this hole, including any carried-over amounts.
        public let grossPot: Double
        /// Hole numbers whose pot carried forward into this hole's grossPot.
        public let grossCarriedFrom: [Int]

        // Net skin ───────────────────────────────────────────────────────────
        public let netWinner: UUID?
        public let netTied: [UUID]
        public let netIsProvisional: Bool
        public let netPot: Double
        public let netCarriedFrom: [Int]
    }

    // MARK: Computation

    public static func compute(players: [PlayerInput], settings: Settings) -> [SkinResult] {
        let holeCount = settings.holeHandicapRanks.count
        guard holeCount > 0 else { return [] }
        precondition(players.allSatisfy { $0.scores.count == holeCount && $0.groupPosted.count == holeCount })

        var results = [SkinResult]()
        var grossCarryPot: Double  = 0
        var grossCarryFrom: [Int]  = []
        var netCarryPot: Double    = 0
        var netCarryFrom: [Int]    = []

        for h in 0..<holeCount {
            let holeNumber = h + 1
            let rank       = settings.holeHandicapRanks[h]
            let isLastHole = h == holeCount - 1

            // Hole is fully posted when every player's group has posted it.
            let isFullyPosted = players.allSatisfy { $0.groupPosted[h] }

            // Collect scores from posted players who have an actual gross score.
            // Picked-up players: their group counts as posted, but they have no score.
            var grossScores: [(UUID, Int)] = []
            var netScores:   [(UUID, Int)] = []
            for player in players {
                guard player.groupPosted[h] else { continue }
                guard case .gross(let g) = player.scores[h] else { continue }
                let eff = Int((Double(player.courseHandicap) * settings.allowance).rounded())
                let s   = BestBallEngine.rawStrokes(effectiveHC: eff, holeRank: rank, holeCount: holeCount)
                grossScores.append((player.playerID, g))
                netScores.append((player.playerID, g - s))
            }

            let grossPotThisHole = settings.potGrossPerHole + grossCarryPot
            let netPotThisHole   = settings.potNetPerHole   + netCarryPot
            let grossCarriedIn   = grossCarryFrom
            let netCarriedIn     = netCarryFrom

            let (gWinner, gTied) = skinResult(scores: grossScores)
            let (nWinner, nTied) = skinResult(scores: netScores)

            // Update gross carryover for next hole
            if gWinner != nil {
                grossCarryPot = 0; grossCarryFrom = []
            } else if settings.carryoverEnabled && !isLastHole {
                grossCarryPot = grossPotThisHole
                grossCarryFrom = grossCarriedIn + [holeNumber]
            } else {
                grossCarryPot = 0; grossCarryFrom = []
            }

            // Update net carryover for next hole
            if nWinner != nil {
                netCarryPot = 0; netCarryFrom = []
            } else if settings.carryoverEnabled && !isLastHole {
                netCarryPot = netPotThisHole
                netCarryFrom = netCarriedIn + [holeNumber]
            } else {
                netCarryPot = 0; netCarryFrom = []
            }

            results.append(SkinResult(
                holeNumber: holeNumber,
                grossWinner: gWinner,
                grossTied: gTied,
                grossIsProvisional: !isFullyPosted,
                grossPot: grossPotThisHole,
                grossCarriedFrom: grossCarriedIn,
                netWinner: nWinner,
                netTied: nTied,
                netIsProvisional: !isFullyPosted,
                netPot: netPotThisHole,
                netCarriedFrom: netCarriedIn
            ))
        }

        return results
    }

    // MARK: Helper

    /// From a list of (playerID, score), return the unique winner or the tied IDs.
    /// - Exactly 1 player at the minimum → (winner, [])
    /// - 2+ players at the minimum       → (nil, all at minimum)
    /// - 0 players                        → (nil, [])
    private static func skinResult(scores: [(UUID, Int)]) -> (winner: UUID?, tied: [UUID]) {
        guard !scores.isEmpty else { return (nil, []) }
        let minScore = scores.map { $0.1 }.min()!
        let atMin = scores.filter { $0.1 == minScore }
        return atMin.count == 1 ? (atMin[0].0, []) : (nil, atMin.map { $0.0 })
    }
}
