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
var proxEnabled: [Bool] = Array(repeating: false, count: 18)

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
        guard let g = currentGame, (0..<18).contains(hole) else {
            return Array(repeating: 0, count: 9)
        }

        // Seats shown on the Game screen
        let seatsRange = 0..<min(9, min(g.playerActivated.count, g.hcPlayers.count, g.playerNames.count))

        // Active seats with a non-empty name
        let activeSeats = seatsRange.filter {
            g.playerActivated[$0] && !g.playerNames[$0].trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        if activeSeats.isEmpty { return Array(repeating: 0, count: 9) }

        // Wolves for this hole (by seat)
        var wolfSeats = Set<Int>()
        if g.wolfButtonStatus.count >= 9, g.wolfButtonStatus.first?.count ?? 0 >= 18 {
            for s in activeSeats where g.wolfButtonStatus[s][hole] { wolfSeats.insert(s) }
        }

        // Teams
        let wolfTeam    = activeSeats.filter { wolfSeats.contains($0) }
        let nonWolfTeam = activeSeats.filter { !wolfSeats.contains($0) }
        let numWolf     = max(1, wolfTeam.count)
        let numNonWolf  = max(1, nonWolfTeam.count)

        // Hole constants
        let par         = hole < g.courseParToPass.count ? g.courseParToPass[hole] : 4
        let rawSI       = hole < g.courseHCToPass.count ? g.courseHCToPass[hole] : 18
        let si          = max(1, min(18, rawSI == 0 ? 18 : rawSI))        // 1…18 (0 → 18)
        let stake       = hole < g.gameHoleDollarsArray.count ? g.gameHoleDollarsArray[hole] : 2.0

        // House rule pops: ONE on hardest S holes only (+1 more on hardest S-18 if S>18)
        @inline(__always)
        func strokesGiven(delta S: Int, strokeIndex si: Int) -> Int {
            let d = max(0, S)
            if d <= 18 { return (si <= d) ? 1 : 0 }
            return 1 + ((si <= (d - 18)) ? 1 : 0)
        }

        // Baseline = lowest HC among ACTIVE players
        let baseHC = activeSeats.map { g.hcPlayers[$0] }.min() ?? 0

        // Gross & Net by seat (missing score -> 99 so it loses)
        var gross: [Int:Int] = [:]
        var net:   [Int:Int] = [:]
        for s in activeSeats {
            let gScore = (s < g.scores.count && hole < g.scores[s].count) ? (g.scores[s][hole] ?? 99) : 99
            gross[s] = gScore
            let S = max(0, g.hcPlayers[s] - baseHC)          // delta from low active HC
            let pops = strokesGiven(delta: S, strokeIndex: si)
            net[s] = (gScore < 99) ? (gScore - pops) : 99
        }

        // Prox (seat index 0…4)
        var wolfProx = 0, nonWolfProx = 0
        if hole < g.proxWinnerPerHole.count, let pxSeat = g.proxWinnerPerHole[hole], activeSeats.contains(pxSeat) {
            if wolfSeats.contains(pxSeat) { wolfProx = 1 } else { nonWolfProx = 1 }
        }

        // Helpers
        func teamHasBirdie(_ team: [Int]) -> Int { team.contains { (gross[$0] ?? 99) <= par - 1 } ? 1 : 0 }
        func teamHasEagle(_ team: [Int]) -> Int  { team.contains { (gross[$0] ?? 99) <= par - 2 } ? 1 : 0 }

        // Points
        let wolfBirdie = teamHasBirdie(wolfTeam)
        let wolfEagle  = teamHasEagle(wolfTeam)
        let nonBirdie  = teamHasBirdie(nonWolfTeam)
        let nonEagle   = teamHasEagle(nonWolfTeam)

        // Low Ball (2 to winner)
        let wolfMinNet = wolfTeam.map { net[$0] ?? 99 }.min() ?? 99
        let nonMinNet  = nonWolfTeam.map { net[$0] ?? 99 }.min() ?? 99
        var wolfLowBall = 0, nonLowBall = 0
        if wolfMinNet < nonMinNet { wolfLowBall = 2 }
        else if wolfMinNet > nonMinNet { nonLowBall = 2 }

        // includes alon calcualtion of lone + (lone + Float(par + 1)) / 2.0
        func twoBestSum(_ team: [Int]) -> Float {
            let arr = team.map { Float(net[$0] ?? 99) }.sorted()
            switch arr.count {
            case 0:
                return 999
            case 1:
                let lone = arr[0]                  // lone player's NET
                // Lone Total = lone + (lone + (par+1)) / 2
                return lone + (lone + Float(par + 1)) / 2.0
            default:
                return arr[0] + arr[1]
            }
        }

        let wolfTotal = twoBestSum(wolfTeam)
        let nonTotal  = twoBestSum(nonWolfTeam)
        var wolfLowTotal = 0, nonLowTotal = 0
        if wolfTotal < nonTotal { wolfLowTotal = 2 }
        else if wolfTotal > nonTotal { nonLowTotal = 2 }

        // Team tallies
        var wolfTeamScore = wolfProx + wolfLowTotal + wolfLowBall + wolfBirdie + wolfEagle
        var nonTeamScore  = nonWolfProx + nonLowTotal + nonLowBall + nonBirdie + nonEagle

        // Umbrella/double rule
        var diff = abs(wolfTeamScore - nonTeamScore)
        if !umbePressed, diff >= 6 { diff *= 2 }

        // Payouts
        var payouts = Array(repeating: 0.0, count: 9)
        guard diff != 0, !(wolfTeam.isEmpty && nonWolfTeam.isEmpty) else { return payouts }

        if wolfTeamScore > nonTeamScore {
            let wolfEach = Double(diff) * stake * (Double(numNonWolf) / Double(numWolf))
            let nonEach  = -Double(diff) * stake
            wolfTeam.forEach    { payouts[$0] = wolfEach }
            nonWolfTeam.forEach { payouts[$0] = nonEach  }
        } else {
            let nonEach  = Double(diff) * stake
            let wolfEach = -Double(diff) * stake * (Double(numNonWolf) / Double(numWolf))
            nonWolfTeam.forEach { payouts[$0] = nonEach  }
            wolfTeam.forEach    { payouts[$0] = wolfEach }
        }

        // --- WHOLE-DOLLAR PAYOUTS (extra $ to first Wolf) -------------------------
       
        guard diff != 0, !(wolfTeam.isEmpty && nonWolfTeam.isEmpty) else { return payouts }

        // Per non-Wolf seat transfer in dollars (rounded to nearest whole $)
        let perNonDollar = Int((Double(diff) * stake).rounded())
        guard perNonDollar != 0 else { return payouts }

        // Total dollars flowing from the losing side to the winning side
        let totalDollars = perNonDollar * numNonWolf

        // Split total across Wolves, whole dollars only
        let basePerWolf = totalDollars / numWolf        // even share
        let remainder   = totalDollars % numWolf        // 0…(numWolf-1)
        let primaryWolf = wolfTeam.min()                // first Wolf seat

        if wolfTeamScore > nonTeamScore {
            // Wolves win: Non-wolves each pay, Wolves split pot
            for s in nonWolfTeam { payouts[s] = Double(-perNonDollar) }
            for s in wolfTeam    { payouts[s] = Double(basePerWolf)   }
            if let p = primaryWolf { payouts[p] += Double(remainder) }   // extra $ to first Wolf
        } else {
            // Wolves lose: Non-wolves each receive, Wolves split what they owe
            for s in nonWolfTeam { payouts[s] = Double(+perNonDollar) }
            for s in wolfTeam    { payouts[s] = Double(-basePerWolf)  }
            if let p = primaryWolf { payouts[p] -= Double(remainder) }   // first Wolf pays the extra $
        }

        return payouts

    }

    
}


