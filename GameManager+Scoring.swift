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
    func computeHolePayout(hole: Int, umbePressed: Bool) -> [Double] {
        guard let g = currentGame, (0..<STANDARD_HOLES).contains(hole) else {
            return Array(repeating: 0.0, count: MAX_PLAYERS)
        }

        let mode = g.resolvedGameType

        // Seats shown on the Game screen
        let seatsRange = 0..<min(MAX_PLAYERS, min(g.playerActivated.count, g.hcPlayers.count, g.playerNames.count))

        // Active seats with a non-empty name
        let activeSeats = seatsRange.filter {
            g.playerActivated[$0] && !g.playerNames[$0].trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        if activeSeats.isEmpty { return Array(repeating: 0.0, count: MAX_PLAYERS) }

        // Wolves for this hole (by seat)
        var wolfSeats = Set<Int>()
        if g.wolfButtonStatus.count >= MAX_PLAYERS, (g.wolfButtonStatus.first?.count ?? 0) >= STANDARD_HOLES {
            for s in activeSeats where g.wolfButtonStatus[s][hole] { wolfSeats.insert(s) }
        }

        // Teams
        let wolfTeam    = activeSeats.filter { wolfSeats.contains($0) }
        let nonWolfTeam = activeSeats.filter { !wolfSeats.contains($0) }

        // ✅ Need both sides or money math becomes nonsense
        guard !wolfTeam.isEmpty, !nonWolfTeam.isEmpty else {
            return Array(repeating: 0.0, count: MAX_PLAYERS)
        }

        let numWolf    = wolfTeam.count
        let numNonWolf = nonWolfTeam.count

        // Hole constants
        let par   = g.courseParToPass[safe: hole] ?? 4
        let rawSI = g.courseHCToPass[safe: hole] ?? STANDARD_HOLES
        let si    = max(1, min(STANDARD_HOLES, rawSI == 0 ? STANDARD_HOLES : rawSI)) // 1…18 (0 → 18)

        // Stake (includes hammer multiplier)
        let baseStake = (g.gameHoleDollarsArray[safe: hole] ?? 2.0)
        let hammerC   = g.hammerCountPerHole?[safe: hole] ?? 0
        let hammerMult = Double(1 << max(0, hammerC)) // 1,2,4,8...
        let stake = baseStake * hammerMult

        // ✅ Point values by mode
        let lowBallPts: Int = mode.isScotch ? 2 : 1
        let lowTotalPts: Int = {
            switch mode {
            case .sixPointScotch: return 2
            case .wolf:           return 1
            case .wolfLowBall:    return 0   // low ball only
            case .hammer:         return 2   // treat like scotch scoring
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

            let S = max(0, g.hcPlayers[s] - baseHC)
            let pops = strokesGiven(delta: S, strokeIndex: si)
            net[s] = (gScore < 99) ? (gScore - pops) : 99
        }

        // ---------------------------------------------------------
        //  6-POINT ONLY: Prox
        // ---------------------------------------------------------
        var wolfProx = 0, nonWolfProx = 0
        if mode.isScotch,
           hole < g.proxWinnerPerHole.count,
           let pxSeat = g.proxWinnerPerHole[hole],
           activeSeats.contains(pxSeat) {
            if wolfSeats.contains(pxSeat) { wolfProx = 1 } else { nonWolfProx = 1 }
        }

        // ---------------------------------------------------------
        //  6-POINT ONLY: Birdie / Eagle
        // ---------------------------------------------------------
        func teamHasBirdie(_ team: [Int]) -> Int { team.contains { (gross[$0] ?? 99) <= par - 1 } ? 1 : 0 }
        func teamHasEagle(_ team: [Int]) -> Int  { team.contains { (gross[$0] ?? 99) <= par - 2 } ? 1 : 0 }

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
            // ✅ Wolf “2-point” now means 1 + 1
            wolfTeamScore = wolfLowBall + wolfLowTotal
            nonTeamScore  = nonLowBall  + nonLowTotal

        case .wolfLowBall:
            // ✅ Wolf Low Ball only: 1 point max
            wolfTeamScore = wolfLowBall
            nonTeamScore  = nonLowBall
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

        // Determine who receives the odd dollar (when remainder > 0 and wolf team has 2+ players).
        // Alternates fairly across holes: the player who did NOT receive it last time gets it next.
        // Uses lastOddDollarHole to avoid re-advancing the tracker on repeated calls for the same hole.
        let sortedWolfTeam = wolfTeam.sorted()
        let oddRecipient: Int? = {
            guard remainder > 0, sortedWolfTeam.count > 1 else { return sortedWolfTeam.first }
            let recipient: Int
            if let last = lastOddDollarRecipient, sortedWolfTeam.contains(last) {
                recipient = sortedWolfTeam.first(where: { $0 != last }) ?? sortedWolfTeam[0]
            } else {
                recipient = sortedWolfTeam[0]
            }
            if hole != lastOddDollarHole {
                lastOddDollarRecipient = recipient
                lastOddDollarHole = hole
            }
            return recipient
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


