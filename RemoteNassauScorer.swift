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

    static func score(playerA: SharedRound, playerB: SharedRound, stakePerBet: Int) -> RemoteNassauResult {
        var results: [RemoteHoleResult] = []

        let lowerCH = min(playerA.courseHandicap, playerB.courseHandicap)
        let aStrokesToApply = max(0, playerA.courseHandicap - lowerCH)
        let bStrokesToApply = max(0, playerB.courseHandicap - lowerCH)

        for i in 0..<18 {
            let grossA: Int? = i < playerA.scores.count ? playerA.scores[i] : nil
            let grossB: Int? = i < playerB.scores.count ? playerB.scores[i] : nil

            let holeHCA = playerA.hcs[safe: i] ?? 18
            let holeHCB = playerB.hcs[safe: i] ?? 18

            let aPops = strokesReceived(strokesToApply: aStrokesToApply, holeHandicap: holeHCA)
            let bPops = strokesReceived(strokesToApply: bStrokesToApply, holeHandicap: holeHCB)

            let netA = grossA.map { $0 - aPops }
            let netB = grossB.map { $0 - bPops }

            let winner: RemoteHoleWinner
            if let netA, let netB {
                if netA < netB {
                    winner = .playerA
                } else if netB < netA {
                    winner = .playerB
                } else {
                    winner = .tie
                }
            } else {
                winner = .noResult
            }

            results.append(
                RemoteHoleResult(
                    holeNumberA: i + 1,
                    holeNumberB: i + 1,
                    holeHandicapA: holeHCA,
                    holeHandicapB: holeHCB,
                    grossA: grossA,
                    grossB: grossB,
                    netA: netA,
                    netB: netB,
                    strokesA: aPops,
                    strokesB: bPops,
                    winner: winner
                )
            )
        }

        let frontScore = scoreSlice(Array(results.prefix(9)))
        let backScore = scoreSlice(Array(results.suffix(9)))
        let overallScore = scoreSlice(results)
        let totalOutcome = frontScore + backScore + overallScore
        let dollarOutcome = totalOutcome * stakePerBet

        return RemoteNassauResult(
            holeResults: results,
            frontScore: frontScore,
            backScore: backScore,
            overallScore: overallScore,
            totalOutcome: totalOutcome,
            stakePerBet: stakePerBet,
            dollarOutcome: dollarOutcome
        )
    }

    static func sortedAll18ByHCA(playerA: SharedRound, playerB: SharedRound) -> [RemoteHoleResult] {
        let lowerCH = min(playerA.courseHandicap, playerB.courseHandicap)
        let aStrokesToApply = max(0, playerA.courseHandicap - lowerCH)
        let bStrokesToApply = max(0, playerB.courseHandicap - lowerCH)

        let aOrder = (0..<18).sorted {
            let hc0 = playerA.hcs[safe: $0] ?? 18
            let hc1 = playerA.hcs[safe: $1] ?? 18
            if hc0 == hc1 { return $0 < $1 }
            return hc0 < hc1
        }

        let bOrder = (0..<18).sorted {
            let hc0 = playerB.hcs[safe: $0] ?? 18
            let hc1 = playerB.hcs[safe: $1] ?? 18
            if hc0 == hc1 { return $0 < $1 }
            return hc0 < hc1
        }

        return zip(aOrder, bOrder).map { aIndex, bIndex in
            makeHoleResult(
                playerA: playerA,
                playerB: playerB,
                aIndex: aIndex,
                bIndex: bIndex,
                aStrokesToApply: aStrokesToApply,
                bStrokesToApply: bStrokesToApply
            )
        }
    }
    static func sortedFront9ByHCA(playerA: SharedRound, playerB: SharedRound) -> [RemoteHoleResult] {
        let lowerCH = min(playerA.courseHandicap, playerB.courseHandicap)
        let aStrokesToApply = max(0, playerA.courseHandicap - lowerCH)
        let bStrokesToApply = max(0, playerB.courseHandicap - lowerCH)

        let aFront = (0..<9).sorted {
            let hc0 = playerA.hcs[safe: $0] ?? 9
            let hc1 = playerA.hcs[safe: $1] ?? 9
            if hc0 == hc1 { return $0 < $1 }
            return hc0 < hc1
        }

        let bFront = (0..<9).sorted {
            let hc0 = playerB.hcs[safe: $0] ?? 9
            let hc1 = playerB.hcs[safe: $1] ?? 9
            if hc0 == hc1 { return $0 < $1 }
            return hc0 < hc1
        }

        return zip(aFront, bFront).map { aIndex, bIndex in
            makeHoleResult(
                playerA: playerA,
                playerB: playerB,
                aIndex: aIndex,
                bIndex: bIndex,
                aStrokesToApply: aStrokesToApply,
                bStrokesToApply: bStrokesToApply
            )
        }
    }

    static func sortedBack9ByHCA(playerA: SharedRound, playerB: SharedRound) -> [RemoteHoleResult] {
        let lowerCH = min(playerA.courseHandicap, playerB.courseHandicap)
        let aStrokesToApply = max(0, playerA.courseHandicap - lowerCH)
        let bStrokesToApply = max(0, playerB.courseHandicap - lowerCH)

        let aBack = (9..<18).sorted {
            let hc0 = playerA.hcs[safe: $0] ?? 9
            let hc1 = playerA.hcs[safe: $1] ?? 9
            if hc0 == hc1 { return $0 < $1 }
            return hc0 < hc1
        }

        let bBack = (9..<18).sorted {
            let hc0 = playerB.hcs[safe: $0] ?? 9
            let hc1 = playerB.hcs[safe: $1] ?? 9
            if hc0 == hc1 { return $0 < $1 }
            return hc0 < hc1
        }

        return zip(aBack, bBack).map { aIndex, bIndex in
            makeHoleResult(
                playerA: playerA,
                playerB: playerB,
                aIndex: aIndex,
                bIndex: bIndex,
                aStrokesToApply: aStrokesToApply,
                bStrokesToApply: bStrokesToApply
            )
        }
    }

    private static func makeHoleResult(
        playerA: SharedRound,
        playerB: SharedRound,
        aIndex: Int,
        bIndex: Int,
        aStrokesToApply: Int,
        bStrokesToApply: Int
    ) -> RemoteHoleResult {
        let grossA = aIndex < playerA.scores.count ? playerA.scores[aIndex] : nil
        let grossB = bIndex < playerB.scores.count ? playerB.scores[bIndex] : nil

        let holeHCA = playerA.hcs[safe: aIndex] ?? 18
        let holeHCB = playerB.hcs[safe: bIndex] ?? 18

        let aPops = strokesReceived(strokesToApply: aStrokesToApply, holeHandicap: holeHCA)
        let bPops = strokesReceived(strokesToApply: bStrokesToApply, holeHandicap: holeHCB)

        let netA = grossA.map { $0 - aPops }
        let netB = grossB.map { $0 - bPops }

        let winner: RemoteHoleWinner
        if let netA, let netB {
            if netA < netB {
                winner = .playerA
            } else if netB < netA {
                winner = .playerB
            } else {
                winner = .tie
            }
        } else {
            winner = .noResult
        }

        return RemoteHoleResult(
            holeNumberA: aIndex + 1,
            holeNumberB: bIndex + 1,
            holeHandicapA: holeHCA,
            holeHandicapB: holeHCB,
            grossA: grossA,
            grossB: grossB,
            netA: netA,
            netB: netB,
            strokesA: aPops,
            strokesB: bPops,
            winner: winner
        )
    }

    private static func strokesReceived(strokesToApply: Int, holeHandicap: Int) -> Int {
        guard strokesToApply > 0 else { return 0 }

        let fullRounds = strokesToApply / 18
        let remainder = strokesToApply % 18

        return fullRounds + (holeHandicap <= remainder ? 1 : 0)
    }

    private static func scoreSlice(_ holes: [RemoteHoleResult]) -> Int {
        var total = 0

        for hole in holes {
            switch hole.winner {
            case .playerA:
                total += 1
            case .playerB:
                total -= 1
            case .tie, .noResult:
                break
            }
        }

        if total > 0 { return 1 }
        if total < 0 { return -1 }
        return 0
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        guard indices.contains(index) else { return nil }
        return self[index]
    }
}
