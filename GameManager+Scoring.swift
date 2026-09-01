//
//  GameManager+Scoring.swift
//  Wolfmore-7Man
//
//  Created by Tom BUTLER on 10/6/25.
//
import Foundation
// GameData

import os

private let popsLog = Logger(subsystem: Bundle.main.bundleIdentifier ?? "app",
                             category: "POPS")
var proxEnabled: [Bool] = Array(repeating: false, count: STANDARD_HOLES)

var wolfCalledPerHole: [Bool] = Array(repeating: false, count: STANDARD_HOLES)
var wolfTeamWonPerHole: [Bool] = Array(repeating: false, count: STANDARD_HOLES)

extension GameManager {

    /// Returns a 9-element payout array for `hole`. Seats 0…4 are used; 5…8 = 0.
    /// - Parameters:
    ///   - hole: 0…17
    ///   - umbePressed: true if Umbrella is pressed (disables doubling at ≥6)
    /// Returns a 9-element payout array for `hole`. Seats 0…4 are used; 5…8 = 0.
    /// - Parameters:
    ///   - hole: 0…17
    ///   - umbePressed: true if Umbrella is pressed (disables doubling at ≥6)
    func computeHolePayout(hole: Int, umbePressed: Bool, modeOverride: GameType? = nil) -> [Double] {
        guard let g = currentGame, (0..<g.totalHoles).contains(hole) else {
            return Array(repeating: 0.0, count: MAX_PLAYERS)
        }

        let mode = modeOverride ?? g.resolvedGameType

        // Seats shown on the Game screen
        let seatsRange = 0..<min(MAX_PLAYERS, min(g.playerActivated.count, g.hcPlayers.count, g.playerNames.count))

        // Active seats with a non-empty name
        let activeSeats = seatsRange.filter {
            g.playerActivated[$0] && !g.playerNames[$0].trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        if activeSeats.isEmpty { return Array(repeating: 0.0, count: MAX_PLAYERS) }

        // Teams — matchPlay uses fixed assignments; other modes use per-hole wolfButtonStatus
        let wolfTeam:    [Int]
        let nonWolfTeam: [Int]

        if mode.isMatchPlay {
            let teamA = (g.matchPlayTeamA ?? []).filter { activeSeats.contains($0) }
            let teamB = (g.matchPlayTeamB ?? []).filter { activeSeats.contains($0) }
            wolfTeam    = teamA
            nonWolfTeam = teamB
        } else {
            var wolfSeats = Set<Int>()
            if g.wolfButtonStatus.count >= MAX_PLAYERS, (g.wolfButtonStatus.first?.count ?? 0) > hole {
                for s in activeSeats where g.wolfButtonStatus[s][hole] { wolfSeats.insert(s) }
            }
            wolfTeam    = activeSeats.filter { wolfSeats.contains($0) }
            nonWolfTeam = activeSeats.filter { !wolfSeats.contains($0) }
        }

        // Need both sides or money math becomes nonsense
        guard !wolfTeam.isEmpty, !nonWolfTeam.isEmpty else {
            return Array(repeating: 0.0, count: MAX_PLAYERS)
        }

        let numWolf    = wolfTeam.count
        let numNonWolf = nonWolfTeam.count

        // Hole constants — wrap index for 36-hole rounds (holes 19–36 mirror course holes 1–18)
        let courseH = hole % STANDARD_HOLES
        let par   = g.courseParToPass[safe: courseH] ?? 4

        // Stake — matchPlay uses flat stake (no hammer); all other modes include hammer multiplier
        let baseStake  = (g.gameHoleDollarsArray[safe: hole] ?? 2.0)
        let hammerMult = mode.isMatchPlay ? 1.0 : g.hammerMultiplier(for: hole)
        let stake      = baseStake * hammerMult

        // Point values by mode
        let lowBallPts: Int = mode.isScotch ? 2 : 1
        let lowTotalPts: Int = {
            switch mode {
            case .sixPointScotch: return 2
            case .wolf:           return 1
            case .wolfLowBall:    return 0   // low ball only
            case .matchPlay:      return 0   // low ball only
            case .bestBall:       return 0   // stroke total, no per-hole pts
            case .hammer:         return 2   // treat like scotch scoring
            case .tournament:     return 0   // tournament — no wolf payouts
            }
        }()

        // House rule pops: ONE on hardest S holes only (+1 more on hardest S-18 if S>18)
        @inline(__always)
        func strokesGiven(delta S: Int, strokeIndex si: Int) -> Int {
            let d = max(0, S)
            if d <= STANDARD_HOLES { return (si <= d) ? 1 : 0 }
            return 1 + ((si <= (d - STANDARD_HOLES)) ? 1 : 0)
        }

        // Baseline = lowest HC among ACTIVE players
        let baseHC = activeSeats.map { g.hcPlayers[$0] }.min() ?? 0

        // Gross & Net by seat (missing score -> 99 so it loses)
        var gross: [Int:Int] = [:]
        var net:   [Int:Int] = [:]
        for s in activeSeats {
            let gScore = (s < g.scores.count && hole < g.scores[s].count) ? (g.scores[s][hole] ?? 99) : 99
            gross[s] = gScore

            let playerSI = g.hcForHole(courseH, player: s)
            let S = max(0, g.hcPlayers[s] - baseHC)
            let pops = strokesGiven(delta: S, strokeIndex: playerSI)
            net[s] = (gScore < 99) ? (gScore - pops) : 99
        }

        // ---------------------------------------------------------
        //  DUAL MATCH: two independent matches scored simultaneously
        // ---------------------------------------------------------
        if mode.isMatchPlay, g.isDualMatch {
            if mode == .bestBall { return Array(repeating: 0.0, count: MAX_PLAYERS) }
            func oneMatch(teamA: [Int], teamB: [Int]) -> [Double] {
                let aMin = teamA.map { net[$0] ?? 99 }.min() ?? 99
                let bMin = teamB.map { net[$0] ?? 99 }.min() ?? 99
                var p = Array(repeating: 0.0, count: MAX_PLAYERS)
                guard aMin != bMin else { return p }
                let perPayer = Int(stake.rounded())
                guard perPayer != 0 else { return p }
                if aMin < bMin {
                    let totalIn = perPayer * teamB.count
                    let baseOut = totalIn / max(1, teamA.count)
                    let rem     = totalIn % max(1, teamA.count)
                    for s in teamB { p[s] = -Double(perPayer) }
                    for s in teamA { p[s] =  Double(baseOut) }
                    if rem > 0, let f = teamA.first { p[f] += Double(rem) }
                } else {
                    let totalIn = perPayer * teamA.count
                    let baseOut = totalIn / max(1, teamB.count)
                    let rem     = totalIn % max(1, teamB.count)
                    for s in teamA { p[s] = -Double(perPayer) }
                    for s in teamB { p[s] =  Double(baseOut) }
                    if rem > 0, let f = teamB.first { p[f] += Double(rem) }
                }
                return p
            }

            let a1 = (g.matchPlayTeamA  ?? []).filter { activeSeats.contains($0) }
            let b1 = (g.matchPlayTeamB  ?? []).filter { activeSeats.contains($0) }
            let a2 = (g.matchPlayTeamA2 ?? []).filter { activeSeats.contains($0) }
            let b2 = (g.matchPlayTeamB2 ?? []).filter { activeSeats.contains($0) }
            let p1 = oneMatch(teamA: a1, teamB: b1)
            let p2 = oneMatch(teamA: a2, teamB: b2)
            var combined = Array(repeating: 0.0, count: MAX_PLAYERS)
            for i in 0..<MAX_PLAYERS { combined[i] = p1[i] + p2[i] }
            return combined
        }

        // ---------------------------------------------------------
        //  6-POINT ONLY: Prox
        // ---------------------------------------------------------
        var wolfProx = 0, nonWolfProx = 0
        if mode.isScotch,
           hole < g.proxWinnerPerHole.count,
           let pxSeat = g.proxWinnerPerHole[hole],
           activeSeats.contains(pxSeat) {
            if wolfTeam.contains(pxSeat) { wolfProx = 1 } else { nonWolfProx = 1 }
        }

        // ---------------------------------------------------------
        //  6-POINT ONLY: Birdie / Eagle
        // ---------------------------------------------------------
        func teamHasBirdie(_ team: [Int]) -> Int { team.contains { (gross[$0] ?? 99) <= g.parForHole(courseH, player: $0) - 1 } ? 1 : 0 }
        func teamHasEagle(_ team: [Int]) -> Int  { team.contains { (gross[$0] ?? 99) <= g.parForHole(courseH, player: $0) - 2 } ? 1 : 0 }

        let wolfBirdie = mode.isScotch ? teamHasBirdie(wolfTeam) : 0
        let wolfEagle  = mode.isScotch ? teamHasEagle(wolfTeam)  : 0
        let nonBirdie  = mode.isScotch ? teamHasBirdie(nonWolfTeam) : 0
        let nonEagle   = mode.isScotch ? teamHasEagle(nonWolfTeam)  : 0

        // ---------------------------------------------------------
        //  Low Ball — used in ALL modes (points vary)
        // ---------------------------------------------------------
        let wolfMinNet = wolfTeam.map { net[$0] ?? 99 }.min() ?? 99
        let nonMinNet  = nonWolfTeam.map { net[$0] ?? 99 }.min() ?? 99

        var wolfLowBall = 0, nonLowBall = 0
        if wolfMinNet < nonMinNet { wolfLowBall = lowBallPts }
        else if wolfMinNet > nonMinNet { nonLowBall = lowBallPts }

        // ---------------------------------------------------------
        //  Low Total — scotch + wolf (points vary), NOT used in wolfLowBall
        // ---------------------------------------------------------
        var wolfLowTotal = 0, nonLowTotal = 0
        if lowTotalPts > 0 {
            // includes alone calc: lone + (lone + (par + 1)) / 2
            func twoBestSum(_ team: [Int]) -> Float {
                let arr = team.map { Float(net[$0] ?? 99) }.sorted()
                switch arr.count {
                case 0:
                    return 999
                case 1:
                    let lone = arr[0]
                    return lone + (lone + Float(par + 1)) / 2.0
                default:
                    return arr[0] + arr[1]
                }
            }

            let wolfTotal = twoBestSum(wolfTeam)
            let nonTotal  = twoBestSum(nonWolfTeam)

            if wolfTotal < nonTotal { wolfLowTotal = lowTotalPts }
            else if wolfTotal > nonTotal { nonLowTotal = lowTotalPts }
        }

        // ---------------------------------------------------------
        //  TEAM TALLIES BY MODE
        // ---------------------------------------------------------
        let wolfTeamScore: Int
        let nonTeamScore: Int

        switch mode {
        case .sixPointScotch, .hammer:
            wolfTeamScore = wolfProx + wolfLowTotal + wolfLowBall + wolfBirdie + wolfEagle
            nonTeamScore  = nonWolfProx + nonLowTotal + nonLowBall + nonBirdie + nonEagle

        case .wolf:
            // Wolf “2-point”: low ball + low total
            wolfTeamScore = wolfLowBall + wolfLowTotal
            nonTeamScore  = nonLowBall  + nonLowTotal

        case .wolfLowBall, .matchPlay, .bestBall:
            // Low ball only: 1 point max per hole
            wolfTeamScore = wolfLowBall
            nonTeamScore  = nonLowBall

        case .tournament:
            // Stableford points are per-player, not team-based; return zeros.
            wolfTeamScore = 0
            nonTeamScore  = 0
        }

        // ---------------------------------------------------------
        //  Umbrella/double rule — 6-POINT ONLY
        // ---------------------------------------------------------
        var diff = abs(wolfTeamScore - nonTeamScore)
        if mode.isScotch, !umbePressed, diff >= 6 { diff *= 2 }

        // ---------------------------------------------------------
        //  RECORD STATS
        // ---------------------------------------------------------
        let umbrellaHit     = mode.isScotch && (wolfTeamScore >= 6 || nonTeamScore >= 6)
        let wolfCalledNow   = !wolfTeam.isEmpty
        let wolfWonThisHole = (wolfTeamScore != nonTeamScore) && (wolfTeamScore > nonTeamScore)

        if var gameCopy = currentGame {
            if hole < gameCopy.umbieWonPerHole.count     { gameCopy.umbieWonPerHole[hole] = umbrellaHit }
            if hole < gameCopy.wolfCalledPerHole.count   { gameCopy.wolfCalledPerHole[hole] = wolfCalledNow }
            if hole < gameCopy.wolfTeamWonPerHole.count  { gameCopy.wolfTeamWonPerHole[hole] = wolfWonThisHole }
            currentGame = gameCopy
        }

        // ---------------------------------------------------------
        //  PAYOUTS (whole-dollar)
        // ---------------------------------------------------------
        if mode == .bestBall { return Array(repeating: 0.0, count: MAX_PLAYERS) }

        var payouts = Array(repeating: 0.0, count: MAX_PLAYERS)

        guard diff != 0 else { return payouts }

        // Per-seat transfer (rounded to nearest whole $)
        let perNonDollar = Int((Double(diff) * stake).rounded())
        guard perNonDollar != 0 else { return payouts }

        // Total dollars flowing between teams
        let totalDollars = perNonDollar * numNonWolf

        // Split total across Wolves (whole dollars)
        let basePerWolf = totalDollars / numWolf
        let remainder   = totalDollars % numWolf

        // The calling wolf (primary) always gets the larger absolute share of an odd split.
        // On hole h the calling wolf is activeSeats[h % count] — the standard rotation.
        let sortedWolfTeam = wolfTeam.sorted()
        let oddRecipient: Int? = {
            guard remainder > 0 else { return sortedWolfTeam.first }
            guard sortedWolfTeam.count > 1 else { return sortedWolfTeam.first }
            let callingWolfSeat = activeSeats[hole % activeSeats.count]
            if sortedWolfTeam.contains(callingWolfSeat) { return callingWolfSeat }
            // Calling wolf is always on the wolf team — if not, that is a separate bug.
            print("⚠️ computeHolePayout: calling wolf seat \(callingWolfSeat) not in wolfTeam \(sortedWolfTeam) on hole \(hole + 1)")
            return sortedWolfTeam.first
        }()

        if wolfTeamScore > nonTeamScore {
            for s in nonWolfTeam { payouts[s] = Double(-perNonDollar) }
            for s in wolfTeam    { payouts[s] = Double(basePerWolf) }
            if let p = oddRecipient { payouts[p] += Double(remainder) }
        } else {
            for s in nonWolfTeam { payouts[s] = Double(+perNonDollar) }
            for s in wolfTeam    { payouts[s] = Double(-basePerWolf) }
            if let p = oddRecipient { payouts[p] -= Double(remainder) }
        }

        return payouts
    }
    func proxPercent(seat: Int,
                     gameTypePerHole: [GameType],
                     proxWinnerSeatPerHole: [Int?]) -> Double {

        let eligibleHoles = (0..<min(gameTypePerHole.count, proxWinnerSeatPerHole.count))
            .filter { gameTypePerHole[$0].isScotch }   // ✅ excludes wolf + wolfLowBall

        let opp = eligibleHoles.count
        guard opp > 0 else { return 0 }

        let wins = eligibleHoles.filter { proxWinnerSeatPerHole[$0] == seat }.count
        return (Double(wins) / Double(opp)) * 100.0
    }

}


