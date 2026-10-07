import Foundation

enum RemoteHoleWinner: String, Codable {
    case playerA
    case playerB
    case tie
    case noResult
}

enum RemoteCompareMode: String, CaseIterable, Codable {
    case holeByHole = "Hole by Hole"
    case frontBackByHC = "Front / Back 9 by HC"
    case all18ByHC = "18 Holes by HC"
}

struct RemoteHoleResult: Codable {
    let holeNumberA: Int
    let holeNumberB: Int
    let holeHandicapA: Int
    let holeHandicapB: Int
    let grossA: Int?
    let grossB: Int?
    let netA: Int?
    let netB: Int?
    let parA: Int?
    let parB: Int?
    let strokesA: Int
    let strokesB: Int
    let winner: RemoteHoleWinner
}

struct RemoteNassauResult: Codable {
    let holeResults: [RemoteHoleResult]
    let frontScore: Int
    let backScore: Int
    let overallScore: Int
    let totalOutcome: Int
    let stakePerBet: Int
    let dollarOutcome: Int
}

enum RemoteNassauScorer {

    // +1 = owner/host wins, -1 = opponent wins, 0 = tie or missing scores.
    static func holeWinner(netHost: Int?, netOpp: Int?, parHost: Int?, parOpp: Int?) -> Int {
        guard let hn = netHost, let on = netOpp else { return 0 }
        if let ph = parHost, let po = parOpp {
            let relH = hn - ph
            let relO = on - po
            if relH < relO { return 1 }
            if relO < relH { return -1 }
            return 0
        }
        if hn < on { return 1 }
        if on < hn { return -1 }
        return 0
    }

    static func score(playerA: SharedRound, playerB: SharedRound, stakePerBet: Int, sameCourse: Bool) -> RemoteNassauResult {
        let slots = RemoteNassauPairing.buildSlots(a: playerA, b: playerB, sameCourse: sameCourse)
        let results: [RemoteHoleResult] = slots.map { slot in
            RemoteHoleResult(
                holeNumberA:   slot.indexA + 1,
                holeNumberB:   slot.indexB + 1,
                holeHandicapA: playerA.hcs[safe: slot.indexA] ?? STANDARD_HOLES,
                holeHandicapB: playerB.hcs[safe: slot.indexB] ?? STANDARD_HOLES,
                grossA:        slot.grossA,
                grossB:        slot.grossB,
                netA:          slot.netA,
                netB:          slot.netB,
                parA:          slot.parA,
                parB:          slot.parB,
                strokesA:      slot.strokesA,
                strokesB:      slot.strokesB,
                winner:        slot.winner
            )
        }
        let frontScore   = scoreSlice(Array(results.prefix(9)))
        let backScore    = scoreSlice(Array(results.suffix(9)))
        let overallScore = scoreSlice(results)
        let totalOutcome = frontScore + backScore + overallScore
        let dollarOutcome = totalOutcome * stakePerBet
        return RemoteNassauResult(
            holeResults:  results,
            frontScore:   frontScore,
            backScore:    backScore,
            overallScore: overallScore,
            totalOutcome: totalOutcome,
            stakePerBet:  stakePerBet,
            dollarOutcome: dollarOutcome
        )
    }

    static func scoreSlice(_ holes: [RemoteHoleResult]) -> Int {
        var total = 0
        for hole in holes {
            switch hole.winner {
            case .playerA:              total += 1
            case .playerB:              total -= 1
            case .tie, .noResult:       break
            }
        }
        if total > 0 { return 1 }
        if total < 0 { return -1 }
        return 0
    }
}
