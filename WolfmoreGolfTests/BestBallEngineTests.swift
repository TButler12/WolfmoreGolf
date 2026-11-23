import XCTest
@testable import WolfmoreGolf

// ─── Helpers ─────────────────────────────────────────────────────────────────

private let stdRanks: [Int] = Array(1...18)   // SI 1 on hole 1, SI 2 on hole 2, etc.
private let stdPar:   [Int] = Array(repeating: 4, count: 18)  // all par-4s for easy math

private func notEnteredScores(_ count: Int = 18) -> [HoleScore] {
    Array(repeating: .notEntered, count: count)
}

private func grossScores(_ values: [Int]) -> [HoleScore] {
    precondition(values.count == 18)
    return values.map { .gross($0) }
}

/// Build a uniform 18-hole score array where all holes are `base` except the specified overrides.
private func scores18(base: HoleScore = .gross(5), overrides: [Int: HoleScore] = [:]) -> [HoleScore] {
    (0..<18).map { overrides[$0] ?? base }
}

// ─── Stroke Table Tests ───────────────────────────────────────────────────────

final class StrokeTableTests: XCTestCase {

    // HC 0: no strokes anywhere
    func testHC0() {
        for rank in 1...18 {
            XCTAssertEqual(BestBallEngine.rawStrokes(effectiveHC: 0, holeRank: rank), 0,
                           "HC 0 should give 0 strokes on SI \(rank)")
        }
    }

    // HC 1: exactly 1 stroke on SI 1 only
    func testHC1() {
        XCTAssertEqual(BestBallEngine.rawStrokes(effectiveHC: 1, holeRank: 1), 1)
        for rank in 2...18 {
            XCTAssertEqual(BestBallEngine.rawStrokes(effectiveHC: 1, holeRank: rank), 0)
        }
    }

    // HC 18: exactly 1 stroke on every hole (18/18=1, 18%18=0)
    func testHC18Full() {
        for rank in 1...18 {
            XCTAssertEqual(BestBallEngine.rawStrokes(effectiveHC: 18, holeRank: rank), 1,
                           "HC 18 should give exactly 1 stroke on every hole (SI \(rank))")
        }
    }

    // HC 19: 2 strokes on SI 1, 1 stroke everywhere else (19/18=1, 19%18=1)
    func testHC19() {
        XCTAssertEqual(BestBallEngine.rawStrokes(effectiveHC: 19, holeRank: 1), 2)
        for rank in 2...18 {
            XCTAssertEqual(BestBallEngine.rawStrokes(effectiveHC: 19, holeRank: rank), 1)
        }
    }

    // HC 20: 2 strokes on SI 1-2, 1 stroke on SI 3-18 (20/18=1, 20%18=2)
    func testHC20() {
        XCTAssertEqual(BestBallEngine.rawStrokes(effectiveHC: 20, holeRank: 1), 2)
        XCTAssertEqual(BestBallEngine.rawStrokes(effectiveHC: 20, holeRank: 2), 2)
        for rank in 3...18 {
            XCTAssertEqual(BestBallEngine.rawStrokes(effectiveHC: 20, holeRank: rank), 1,
                           "HC 20 SI \(rank) should be 1")
        }
    }

    // HC 36: 2 strokes on every hole (36/18=2, 36%18=0)
    func testHC36() {
        for rank in 1...18 {
            XCTAssertEqual(BestBallEngine.rawStrokes(effectiveHC: 36, holeRank: rank), 2)
        }
    }

    // HC 37: 3 strokes on SI 1, 2 strokes everywhere else (37/18=2, 37%18=1)
    func testHC37() {
        XCTAssertEqual(BestBallEngine.rawStrokes(effectiveHC: 37, holeRank: 1), 3)
        for rank in 2...18 {
            XCTAssertEqual(BestBallEngine.rawStrokes(effectiveHC: 37, holeRank: rank), 2)
        }
    }

    // HC 38: 3 strokes on SI 1-2, 2 strokes on SI 3-18 (38/18=2, 38%18=2)
    func testHC38() {
        XCTAssertEqual(BestBallEngine.rawStrokes(effectiveHC: 38, holeRank: 1), 3)
        XCTAssertEqual(BestBallEngine.rawStrokes(effectiveHC: 38, holeRank: 2), 3)
        for rank in 3...18 {
            XCTAssertEqual(BestBallEngine.rawStrokes(effectiveHC: 38, holeRank: rank), 2)
        }
    }

    // Plus handicap +1 (effectiveHC = -1): give 1 stroke on SI 18 only
    func testPlusHC1() {
        for rank in 1...17 {
            XCTAssertEqual(BestBallEngine.rawStrokes(effectiveHC: -1, holeRank: rank), 0)
        }
        XCTAssertEqual(BestBallEngine.rawStrokes(effectiveHC: -1, holeRank: 18), -1)
    }

    // Plus handicap +2 (effectiveHC = -2): give strokes on SI 17 and 18
    func testPlusHC2() {
        for rank in 1...16 {
            XCTAssertEqual(BestBallEngine.rawStrokes(effectiveHC: -2, holeRank: rank), 0)
        }
        XCTAssertEqual(BestBallEngine.rawStrokes(effectiveHC: -2, holeRank: 17), -1)
        XCTAssertEqual(BestBallEngine.rawStrokes(effectiveHC: -2, holeRank: 18), -1)
    }

    // 90% allowance: HC 18 × 0.9 = effectiveHC 16; 1 stroke on SI 1-16, 0 on SI 17-18
    func testAllowance90Percent() {
        for rank in 1...16 {
            XCTAssertEqual(BestBallEngine.strokes(courseHC: 18, holeRank: rank, allowance: 0.9), 1,
                           "HC 18 at 90% → 16 effective → 1 stroke on SI \(rank)")
        }
        XCTAssertEqual(BestBallEngine.strokes(courseHC: 18, holeRank: 17, allowance: 0.9), 0)
        XCTAssertEqual(BestBallEngine.strokes(courseHC: 18, holeRank: 18, allowance: 0.9), 0)
    }

    // 100% allowance (default): HC 18 → 1 stroke on every hole
    func testAllowance100Percent() {
        for rank in 1...18 {
            XCTAssertEqual(BestBallEngine.strokes(courseHC: 18, holeRank: rank, allowance: 1.0), 1)
        }
    }

    // Plus handicap with 90% allowance: +2 × 0.9 = -1.8 → rounds to -2
    func testPlusHCWithAllowance() {
        // round(-2 × 0.9) = round(-1.8) = -2
        XCTAssertEqual(BestBallEngine.strokes(courseHC: -2, holeRank: 17, allowance: 0.9), -1)
        XCTAssertEqual(BestBallEngine.strokes(courseHC: -2, holeRank: 18, allowance: 0.9), -1)
        XCTAssertEqual(BestBallEngine.strokes(courseHC: -2, holeRank: 16, allowance: 0.9), 0)
    }
}

// ─── Best-Ball Hole Result Tests ──────────────────────────────────────────────

final class BestBallHoleResultTests: XCTestCase {

    private let aID = UUID()
    private let bID = UUID()
    private let teamID = UUID()

    private func twoPlayerInput(hcA: Int, hcB: Int, scoresA: [HoleScore], scoresB: [HoleScore],
                                 allowance: Double = 1.0) -> BestBallEngine.GroupInput {
        let pA = BestBallEngine.PlayerInput(playerID: aID, courseHandicap: hcA, scores: scoresA)
        let pB = BestBallEngine.PlayerInput(playerID: bID, courseHandicap: hcB, scores: scoresB)
        let team = BestBallEngine.TeamInput(teamID: teamID, teamName: "T", players: [pA, pB])
        return BestBallEngine.GroupInput(teams: [team], holeHandicapRanks: stdRanks, par: stdPar,
                                         allowance: allowance)
    }

    // Basic best-net: HC 18 player (1 stroke everywhere) and HC 0 player.
    // Hole 1 par 4, SI 1. A gross 5 → net 4. B gross 4 → net 4. Best net = 4.
    func testBasicBestNet() {
        var scoresA = Array(repeating: HoleScore.gross(5), count: 18)
        var scoresB = Array(repeating: HoleScore.gross(5), count: 18)
        scoresA[0] = .gross(5)   // hole 1: A gross 5, net 4 (HC 18 → 1 stroke on every SI)
        scoresB[0] = .gross(4)   // hole 1: B gross 4, net 4 (HC 0 → no strokes)
        let input = twoPlayerInput(hcA: 18, hcB: 0, scoresA: scoresA, scoresB: scoresB)
        let results = BestBallEngine.holeResults(for: input)
        let h1 = results[0].teamResults[0]
        XCTAssertEqual(h1.bestNet, 4)
        XCTAssertEqual(h1.bestGross, 4)   // B's gross 4 is best
        XCTAssertEqual(h1.bestGrossPlayerID, bID)
        XCTAssertEqual(h1.netToPar, 0)    // 4 - 4 = even
    }

    // HC 20 player: 2 strokes on SI 1-2, 1 stroke on SI 3-18.
    // Hole 1 par 4 (SI 1): gross 6 → net 4. Hole 3 par 4 (SI 3): gross 5 → net 4.
    func testHC20NetComputation() {
        var scores = Array(repeating: HoleScore.gross(5), count: 18)
        scores[0] = .gross(6)   // hole 1 SI 1: 2 strokes, net = 4
        scores[1] = .gross(5)   // hole 2 SI 2: 2 strokes, net = 3  ← birdie net
        scores[2] = .gross(5)   // hole 3 SI 3: 1 stroke,  net = 4
        let pA = BestBallEngine.PlayerInput(playerID: aID, courseHandicap: 20, scores: scores)
        let pB = BestBallEngine.PlayerInput(playerID: bID, courseHandicap: 0,
                                             scores: Array(repeating: .notEntered, count: 18))
        let team = BestBallEngine.TeamInput(teamID: teamID, teamName: "T", players: [pA, pB])
        let input = BestBallEngine.GroupInput(teams: [team], holeHandicapRanks: stdRanks, par: stdPar)
        let results = BestBallEngine.holeResults(for: input)
        XCTAssertEqual(results[0].teamResults[0].bestNet, 4)   // gross 6 - 2 strokes
        XCTAssertEqual(results[1].teamResults[0].bestNet, 3)   // gross 5 - 2 strokes (birdie net)
        XCTAssertEqual(results[2].teamResults[0].bestNet, 4)   // gross 5 - 1 stroke
    }

    // HC 38 player: 3 strokes on SI 1-2, 2 strokes on SI 3-18.
    func testHC38NetComputation() {
        var scores = Array(repeating: HoleScore.gross(6), count: 18)
        scores[0] = .gross(7)   // SI 1: 3 strokes → net 4 (par)
        scores[1] = .gross(7)   // SI 2: 3 strokes → net 4
        scores[2] = .gross(6)   // SI 3: 2 strokes → net 4
        let pA = BestBallEngine.PlayerInput(playerID: aID, courseHandicap: 38, scores: scores)
        let pB = BestBallEngine.PlayerInput(playerID: bID, courseHandicap: 0,
                                             scores: Array(repeating: .notEntered, count: 18))
        let team = BestBallEngine.TeamInput(teamID: teamID, teamName: "T", players: [pA, pB])
        let input = BestBallEngine.GroupInput(teams: [team], holeHandicapRanks: stdRanks, par: stdPar)
        let results = BestBallEngine.holeResults(for: input)
        XCTAssertEqual(results[0].teamResults[0].playerResults[0].strokes, 3)
        XCTAssertEqual(results[0].teamResults[0].bestNet, 4)
        XCTAssertEqual(results[1].teamResults[0].playerResults[0].strokes, 3)
        XCTAssertEqual(results[2].teamResults[0].playerResults[0].strokes, 2)
        XCTAssertEqual(results[2].teamResults[0].bestNet, 4)
    }

    // Plus handicap +2: gives 1 stroke on SI 17 and 18 (net = gross + 1 on those holes).
    func testPlusHandicapInHoleResult() {
        // Hole at SI 17 (index 16 in stdRanks array → hole 17): +2 player gives stroke
        var scores = Array(repeating: HoleScore.gross(4), count: 18)
        scores[16] = .gross(4)  // hole 17, SI 17: +2 player net = 4 - (-1) = 5
        let pA = BestBallEngine.PlayerInput(playerID: aID, courseHandicap: -2, scores: scores)
        let pB = BestBallEngine.PlayerInput(playerID: bID, courseHandicap: 0,
                                             scores: Array(repeating: .notEntered, count: 18))
        let team = BestBallEngine.TeamInput(teamID: teamID, teamName: "T", players: [pA, pB])
        let input = BestBallEngine.GroupInput(teams: [team], holeHandicapRanks: stdRanks, par: stdPar)
        let results = BestBallEngine.holeResults(for: input)
        let h17 = results[16].teamResults[0].playerResults[0]
        XCTAssertEqual(h17.strokes, -1)   // gives 1 stroke
        XCTAssertEqual(h17.net, 5)        // gross 4 - (-1) = 5
        // A hole where +2 gives no stroke (SI 1 → index 0)
        XCTAssertEqual(results[0].teamResults[0].playerResults[0].strokes, 0)
        XCTAssertEqual(results[0].teamResults[0].playerResults[0].net, 4)
    }

    // Pick-up: A picks up, B scores 4. Best gross = B's 4, best net = B's net.
    func testOnePlayerPickedUp() {
        var scoresA = Array(repeating: HoleScore.gross(5), count: 18)
        scoresA[0] = .pickedUp
        let scoresB = Array(repeating: HoleScore.gross(4), count: 18)
        let input = twoPlayerInput(hcA: 18, hcB: 0, scoresA: scoresA, scoresB: scoresB)
        let results = BestBallEngine.holeResults(for: input)
        let h1 = results[0].teamResults[0]
        XCTAssertFalse(h1.bothPickedUp)
        XCTAssertEqual(h1.bestGross, 4)
        XCTAssertEqual(h1.bestGrossPlayerID, bID)
        XCTAssertEqual(h1.bestNet, 4)
        XCTAssertEqual(h1.bestNetPlayerID, bID)
        // A's picked-up result
        let pA = h1.playerResults.first { $0.playerID == aID }!
        XCTAssertFalse(pA.countsForSkins)
    }

    // Both players pick up: team takes net double bogey (par + 2 = 6 on par 4).
    func testBothPickedUp() {
        var scoresA = Array(repeating: HoleScore.gross(5), count: 18)
        var scoresB = Array(repeating: HoleScore.gross(5), count: 18)
        scoresA[0] = .pickedUp
        scoresB[0] = .pickedUp
        let input = twoPlayerInput(hcA: 18, hcB: 0, scoresA: scoresA, scoresB: scoresB,
                                    allowance: 1.0)
        let results = BestBallEngine.holeResults(for: input)
        let h1 = results[0].teamResults[0]
        XCTAssertTrue(h1.bothPickedUp)
        XCTAssertNil(h1.bestGross)
        XCTAssertNil(h1.bestGrossPlayerID)
        XCTAssertEqual(h1.bestNet, 6)       // par 4 + 2 = 6
        XCTAssertNil(h1.bestNetPlayerID)    // cap applied, no specific player
        XCTAssertEqual(h1.netToPar, 2)      // double bogey
    }

    // notEntered ≠ pickedUp: one notEntered + one pickedUp → NOT both-picked-up
    func testNotEnteredIsNotPickedUp() {
        var scoresA = Array(repeating: HoleScore.gross(5), count: 18)
        var scoresB = Array(repeating: HoleScore.gross(5), count: 18)
        scoresA[0] = .pickedUp
        scoresB[0] = .notEntered
        let input = twoPlayerInput(hcA: 0, hcB: 0, scoresA: scoresA, scoresB: scoresB)
        let results = BestBallEngine.holeResults(for: input)
        let h1 = results[0].teamResults[0]
        XCTAssertFalse(h1.bothPickedUp)
        XCTAssertNil(h1.bestNet)   // no gross score available, net stays nil
    }

    // Configurable cap: bothPickedUpMaxNetOverPar = 3 (triple bogey)
    func testConfigurableBothPickedUpCap() {
        var scoresA = Array(repeating: HoleScore.gross(5), count: 18)
        var scoresB = Array(repeating: HoleScore.gross(5), count: 18)
        scoresA[0] = .pickedUp; scoresB[0] = .pickedUp
        let pA = BestBallEngine.PlayerInput(playerID: aID, courseHandicap: 0, scores: scoresA)
        let pB = BestBallEngine.PlayerInput(playerID: bID, courseHandicap: 0, scores: scoresB)
        let team = BestBallEngine.TeamInput(teamID: teamID, teamName: "T", players: [pA, pB])
        let input = BestBallEngine.GroupInput(teams: [team], holeHandicapRanks: stdRanks,
                                              par: stdPar, bothPickedUpMaxNetOverPar: 3)
        let results = BestBallEngine.holeResults(for: input)
        XCTAssertEqual(results[0].teamResults[0].bestNet, 7)  // par 4 + 3
    }
}

// ─── Team Totals and Net-to-Par Tests ─────────────────────────────────────────

final class TeamTotalsTests: XCTestCase {

    // 18 HC player, all bogeys (gross 5 on par 4), alone in team.
    // Net = 5 - 1 = 4 = par on every hole. Net-to-par = 0 for all 18 holes.
    func testEvenNetEveryHole() {
        let pID = UUID()
        let tID = UUID()
        let scores = Array(repeating: HoleScore.gross(5), count: 18)
        let pA = BestBallEngine.PlayerInput(playerID: pID, courseHandicap: 18, scores: scores)
        let team = BestBallEngine.TeamInput(teamID: tID, teamName: "Solo", players: [pA])
        let input = BestBallEngine.GroupInput(teams: [team], holeHandicapRanks: stdRanks, par: stdPar)
        let holeResults = BestBallEngine.holeResults(for: input)
        let totals = BestBallEngine.teamTotals(from: holeResults, teams: [team])
        let t = totals[0]
        XCTAssertEqual(t.totalNetToPar, 0)
        XCTAssertEqual(t.front9NetToPar, 0)
        XCTAssertEqual(t.back9NetToPar, 0)
        XCTAssertEqual(t.holesPlayed, 18)
    }

    // Partial round (thru 9): back9NetToPar should be nil, totalNetToPar = front9 only.
    func testPartialRoundThru9() {
        let pID = UUID()
        let tID = UUID()
        var scores = Array(repeating: HoleScore.notEntered, count: 18)
        for i in 0..<9 { scores[i] = .gross(3) }  // birdie (par 4 - 1) on holes 1-9
        let pA = BestBallEngine.PlayerInput(playerID: pID, courseHandicap: 0, scores: scores)
        let team = BestBallEngine.TeamInput(teamID: tID, teamName: "T", players: [pA])
        let input = BestBallEngine.GroupInput(teams: [team], holeHandicapRanks: stdRanks, par: stdPar)
        let holeResults = BestBallEngine.holeResults(for: input)
        let totals = BestBallEngine.teamTotals(from: holeResults, teams: [team])
        let t = totals[0]
        XCTAssertEqual(t.holesPlayed, 9)
        XCTAssertEqual(t.front9NetToPar, -9)   // -1 per hole × 9 holes
        XCTAssertNil(t.back9NetToPar)
        XCTAssertEqual(t.totalNetToPar, -9)
    }
}

// ─── Leaderboard and Tiebreak Tests ───────────────────────────────────────────

final class LeaderboardTests: XCTestCase {

    private func makeTotal(teamID: UUID, name: String, holeNets: [Int?]) -> BestBallEngine.TeamTotal {
        func sum(_ s: ArraySlice<Int?>) -> Int? {
            let vs = s.compactMap { $0 }; return vs.isEmpty ? nil : vs.reduce(0, +)
        }
        return BestBallEngine.TeamTotal(
            teamID: teamID, teamName: name,
            front9NetToPar: sum(holeNets[0..<9]), back9NetToPar: sum(holeNets[9..<18]),
            totalNetToPar: sum(holeNets[0..<18]),
            front9GrossToPar: nil, back9GrossToPar: nil, totalGrossToPar: nil,
            holesPlayed: holeNets.compactMap { $0 }.count,
            holeNetToPar: holeNets
        )
    }

    // A team thru 9 at -3 must NOT outrank a team thru 17 at -4.
    func testThru9DoesNotOutrankBetterTeamThru17() {
        let aID = UUID(); let bID = UUID()
        // Team A: thru 9, -3 (3 birdies on front, back all notEntered)
        var aNets = [Int?](repeating: nil, count: 18)
        for i in 0..<9 { aNets[i] = (i < 3) ? -1 : 0 }   // 3 birdies → -3 thru 9
        // Team B: thru 17, -4 (better score)
        var bNets = [Int?](repeating: 0, count: 18)
        bNets[17] = nil  // hole 18 not played
        bNets[0] = -4    // -4 on hole 1 makes total -4
        let tA = makeTotal(teamID: aID, name: "A", holeNets: aNets)
        let tB = makeTotal(teamID: bID, name: "B", holeNets: bNets)
        let board = BestBallEngine.leaderboard(from: [tA, tB])
        let rankA = board.first { $0.teamID == aID }!.rank
        let rankB = board.first { $0.teamID == bID }!.rank
        XCTAssertLessThan(rankB, rankA, "Team B at -4 thru 17 should rank above Team A at -3 thru 9")
    }

    // Simple ranking: 3 teams at -4, -2, E; expect 1st, 2nd, 3rd.
    func testBasicRanking() {
        let ids = (UUID(), UUID(), UUID())
        let netsA = [Int?](repeating: 0, count: 17) + [-4]   // -4 total
        let netsB = [Int?](repeating: 0, count: 17) + [-2]
        let netsC = [Int?](repeating: 0, count: 18)           // even
        let tA = makeTotal(teamID: ids.0, name: "A", holeNets: netsA)
        let tB = makeTotal(teamID: ids.1, name: "B", holeNets: netsB)
        let tC = makeTotal(teamID: ids.2, name: "C", holeNets: netsC)
        let board = BestBallEngine.leaderboard(from: [tA, tB, tC])
        XCTAssertEqual(board.first { $0.teamID == ids.0 }!.rank, 1)
        XCTAssertEqual(board.first { $0.teamID == ids.1 }!.rank, 2)
        XCTAssertEqual(board.first { $0.teamID == ids.2 }!.rank, 3)
    }

    // Tiebreak on back 9: two teams at -4 total; one has -3 on back 9.
    func testTiebreakBack9() {
        let aID = UUID(); let bID = UUID()
        // Both total -4; A is -3 back nine, B is -1 back nine.
        var aNets = [Int?](repeating: 0, count: 18)
        aNets[0] = -1; aNets[9] = -3    // A: -1 front, -3 back
        var bNets = [Int?](repeating: 0, count: 18)
        bNets[0] = -3; bNets[9] = -1    // B: -3 front, -1 back
        let tA = makeTotal(teamID: aID, name: "A", holeNets: aNets)
        let tB = makeTotal(teamID: bID, name: "B", holeNets: bNets)
        let board = BestBallEngine.leaderboard(from: [tA, tB])
        XCTAssertEqual(board.first { $0.teamID == aID }!.rank, 1, "A wins back-9 tiebreak (-3 vs -1)")
        XCTAssertEqual(board.first { $0.teamID == aID }!.tiebreakReason, .back9)
        XCTAssertEqual(board.first { $0.teamID == bID }!.tiebreakReason, .back9)
    }

    // Tiebreak on back 6 (holes 13-18): two teams tied on total and back-9 but A is better on back-6.
    // Equalizer lives in holes 10-12 (indices 9-11), outside the back-6 window, so it cannot
    // accidentally make back-6 equal.
    //
    //   aN: hole 1 = -3, hole 10 = +2, hole 13 = -3  → total -4; back-9 = +2-3 = -1; back-6 = -3
    //   bN: hole 1 = -3, hole 10 =  0, hole 13 = -1  → total -4; back-9 =  0-1 = -1; back-6 = -1
    func testTiebreakBack6() {
        let aID = UUID(); let bID = UUID()
        var aN = [Int?](repeating: 0, count: 18)
        var bN = [Int?](repeating: 0, count: 18)
        aN[0] = -3; bN[0] = -3   // equal front contribution; total so far -3 each
        aN[9] = 2;  bN[9] = 0    // hole 10 (outside back-6): A +2, B 0 — equalizes back-9
        aN[12] = -3; bN[12] = -1 // hole 13 (back-6): A -3, B -1 — A better on back-6
        // A total = -3+2+(-3) = -4 ✓   B total = -3+0+(-1) = -4 ✓
        // back-9 A = 2+(-3) = -1       back-9 B = 0+(-1) = -1  ✓ (equal)
        // back-6 A = -3                back-6 B = -1            ✓ (A wins)
        let tA = makeTotal(teamID: aID, name: "A", holeNets: aN)
        let tB = makeTotal(teamID: bID, name: "B", holeNets: bN)
        let board = BestBallEngine.leaderboard(from: [tA, tB])
        XCTAssertEqual(board.first { $0.teamID == aID }!.rank, 1, "A wins back-6 tiebreak")
        XCTAssertEqual(board.first { $0.teamID == aID }!.tiebreakReason, .back6)
        XCTAssertEqual(board.first { $0.teamID == bID }!.tiebreakReason, .back6)
    }

    // Tiebreak on back 3 (holes 16-18): teams tied on total, back-9, and back-6, but A is better
    // on holes 16-18. Equalizer lives in holes 13-15 (indices 12-14), outside back-3 but inside
    // back-6, so back-6 stays equal while back-3 differs.
    //
    //   aN: hole 1 = -2, hole 13 = +1, hole 16 = -3  → total -4; back-9 = +1-3 = -2; back-6 = -2; back-3 = -3
    //   bN: hole 1 = -2, hole 13 = -1, hole 16 = -1  → total -4; back-9 = -1-1 = -2; back-6 = -2; back-3 = -1
    func testTiebreakBack3() {
        let aID = UUID(); let bID = UUID()
        var aN = [Int?](repeating: 0, count: 18)
        var bN = [Int?](repeating: 0, count: 18)
        aN[0] = -2; bN[0] = -2   // equal front contribution
        aN[12] = 1;  bN[12] = -1  // hole 13 (back-6, NOT back-3): A +1, B -1 — equalizes back-6
        aN[15] = -3; bN[15] = -1  // hole 16 (back-3): A -3, B -1 — A better on back-3
        // A total = -2+1+(-3) = -4 ✓   B total = -2+(-1)+(-1) = -4 ✓
        // back-9 A = 1+(-3) = -2       back-9 B = (-1)+(-1) = -2  ✓ (equal)
        // back-6 A = 1+(-3) = -2       back-6 B = (-1)+(-1) = -2  ✓ (equal)
        // back-3 A = -3                back-3 B = -1               ✓ (A wins)
        let tA = makeTotal(teamID: aID, name: "A", holeNets: aN)
        let tB = makeTotal(teamID: bID, name: "B", holeNets: bN)
        let board = BestBallEngine.leaderboard(from: [tA, tB])
        XCTAssertEqual(board.first { $0.teamID == aID }!.rank, 1, "A wins back-3 tiebreak")
        XCTAssertEqual(board.first { $0.teamID == aID }!.tiebreakReason, .back3)
        XCTAssertEqual(board.first { $0.teamID == bID }!.tiebreakReason, .back3)
    }

    // Tiebreak on hole 18 alone.
    func testTiebreakHole18() {
        let aID = UUID(); let bID = UUID()
        var aN = [Int?](repeating: 0, count: 18)
        var bN = [Int?](repeating: 0, count: 18)
        aN[0] = -4; bN[0] = -4
        // Equal through back 3; A birdies 18 (-1), B pars 18 (0)
        aN[17] = -1; bN[17] = 0
        // Compensate so totals remain equal:
        aN[16] = 1; bN[16] = 0
        let tA = makeTotal(teamID: aID, name: "A", holeNets: aN)
        let tB = makeTotal(teamID: bID, name: "B", holeNets: bN)
        let board = BestBallEngine.leaderboard(from: [tA, tB])
        XCTAssertEqual(board.first { $0.teamID == aID }!.rank, 1)
        XCTAssertEqual(board.first { $0.teamID == aID }!.tiebreakReason, .hole18)
    }

    // Still tied after all tiebreaks.
    func testStillTied() {
        let aID = UUID(); let bID = UUID()
        let nets = [Int?](repeating: 0, count: 18)
        let tA = makeTotal(teamID: aID, name: "A", holeNets: nets)
        let tB = makeTotal(teamID: bID, name: "B", holeNets: nets)
        let board = BestBallEngine.leaderboard(from: [tA, tB])
        XCTAssertEqual(board[0].rank, 1)
        XCTAssertEqual(board[1].rank, 1)   // same rank
        XCTAssertEqual(board[0].tiebreakReason, .stillTied)
        XCTAssertEqual(board[1].tiebreakReason, .stillTied)
    }

    // No-score teams (not started) go to the bottom.
    func testNotStartedGoesLast() {
        let aID = UUID(); let bID = UUID()
        var aN = [Int?](repeating: 0, count: 18); aN[0] = -1   // -1 total
        let bN = [Int?](repeating: nil, count: 18)              // not started
        let tA = makeTotal(teamID: aID, name: "A", holeNets: aN)
        let tB = makeTotal(teamID: bID, name: "B", holeNets: bN)
        let board = BestBallEngine.leaderboard(from: [tB, tA])  // shuffle input order
        XCTAssertEqual(board.first { $0.teamID == aID }!.rank, 1)
        XCTAssertEqual(board.first { $0.teamID == bID }!.rank, 2)
    }
}

// ─── Field Skins Tests ────────────────────────────────────────────────────────

final class FieldSkinsTests: XCTestCase {

    private let aID = UUID()
    private let bID = UUID()
    private let cID = UUID()
    private let dID = UUID()

    private func posted18() -> [Bool] { Array(repeating: true, count: 18) }

    private func settings(carryover: Bool = false) -> FieldSkinsEngine.Settings {
        FieldSkinsEngine.Settings(holeHandicapRanks: stdRanks, allowance: 1.0,
                                   carryoverEnabled: carryover, potGrossPerHole: 10, potNetPerHole: 10)
    }

    // Basic win: player A gross 3 on hole 1, everyone else 4 — A wins gross skin.
    func testBasicGrossWin() {
        let scores = { (_ h: HoleScore) in (0..<18).map { $0 == 0 ? h : .gross(5) } }
        let players = [
            FieldSkinsEngine.PlayerInput(playerID: aID, courseHandicap: 0,
                                          scores: scores(.gross(3)), groupPosted: posted18()),
            FieldSkinsEngine.PlayerInput(playerID: bID, courseHandicap: 0,
                                          scores: scores(.gross(4)), groupPosted: posted18()),
        ]
        let results = FieldSkinsEngine.compute(players: players, settings: settings())
        XCTAssertEqual(results[0].grossWinner, aID)
        XCTAssertTrue(results[0].grossTied.isEmpty)
        XCTAssertFalse(results[0].grossIsProvisional)
    }

    // Tie cancels: A and B both gross 3 on hole 1 — no gross winner.
    func testTieCancels() {
        let scores3 = Array(repeating: HoleScore.gross(4), count: 18).with(0, .gross(3))
        let players = [
            FieldSkinsEngine.PlayerInput(playerID: aID, courseHandicap: 0,
                                          scores: scores3, groupPosted: posted18()),
            FieldSkinsEngine.PlayerInput(playerID: bID, courseHandicap: 0,
                                          scores: scores3, groupPosted: posted18()),
        ]
        let results = FieldSkinsEngine.compute(players: players, settings: settings())
        XCTAssertNil(results[0].grossWinner)
        XCTAssertEqual(results[0].grossTied.sorted { $0.uuidString < $1.uuidString },
                       [aID, bID].sorted { $0.uuidString < $1.uuidString })
    }

    // Win gross and net on same hole: A scores gross 2 on par 4 (SI 1), HC 18 (1 stroke, net 1).
    // B scores gross 3, HC 0 (net 3). A wins both gross (2 < 3) and net (1 < 3).
    func testWinBothGrossAndNetSameHole() {
        var aScores = Array(repeating: HoleScore.gross(4), count: 18)
        var bScores = Array(repeating: HoleScore.gross(4), count: 18)
        aScores[0] = .gross(2)   // hole 1 (SI 1): A gross 2, net 2 - 1 = 1
        bScores[0] = .gross(3)   // hole 1: B gross 3, net 3 - 0 = 3
        let players = [
            FieldSkinsEngine.PlayerInput(playerID: aID, courseHandicap: 18,
                                          scores: aScores, groupPosted: posted18()),
            FieldSkinsEngine.PlayerInput(playerID: bID, courseHandicap: 0,
                                          scores: bScores, groupPosted: posted18()),
        ]
        let results = FieldSkinsEngine.compute(players: players, settings: settings())
        XCTAssertEqual(results[0].grossWinner, aID)
        XCTAssertEqual(results[0].netWinner, aID)
    }

    // Players from different teams in the same group compete against each other for skins.
    func testCrossTeamSameGroupSkins() {
        // A and B are on different teams but in the same group (same groupPosted).
        // A gross 3 on hole 1, B gross 4. A should win.
        var aScores = Array(repeating: HoleScore.gross(4), count: 18); aScores[0] = .gross(3)
        let bScores = Array(repeating: HoleScore.gross(4), count: 18)
        let players = [
            FieldSkinsEngine.PlayerInput(playerID: aID, courseHandicap: 0,
                                          scores: aScores, groupPosted: posted18()),
            FieldSkinsEngine.PlayerInput(playerID: bID, courseHandicap: 0,
                                          scores: bScores, groupPosted: posted18()),
        ]
        let results = FieldSkinsEngine.compute(players: players, settings: settings())
        XCTAssertEqual(results[0].grossWinner, aID)
    }

    // Duplicate names, different UUIDs: keyed by player ID, not name.
    // Two players named "Mike" (different IDs) tie on hole 1 → no skin.
    func testDuplicateNamesDifferentIDs() {
        let mike1 = UUID(); let mike2 = UUID()
        let scores = Array(repeating: HoleScore.gross(4), count: 18).with(0, .gross(3))
        let players = [
            FieldSkinsEngine.PlayerInput(playerID: mike1, courseHandicap: 0,
                                          scores: scores, groupPosted: posted18()),
            FieldSkinsEngine.PlayerInput(playerID: mike2, courseHandicap: 0,
                                          scores: scores, groupPosted: posted18()),
        ]
        let results = FieldSkinsEngine.compute(players: players, settings: settings())
        XCTAssertNil(results[0].grossWinner)   // tie — no skin, even though "different Mikes"
        XCTAssertEqual(results[0].grossTied.count, 2)
    }

    // Provisional: group B hasn't posted hole 1; A is leading; grossWinner is set but isProvisional.
    func testProvisionalCurrentLeader() {
        var aPosted = Array(repeating: true, count: 18)
        var bPosted = Array(repeating: true, count: 18)
        aPosted[0] = true; bPosted[0] = false  // group B hasn't posted hole 1

        var aScores = Array(repeating: HoleScore.gross(4), count: 18); aScores[0] = .gross(3)
        let bScores = Array(repeating: HoleScore.notEntered, count: 18)  // not entered

        let players = [
            FieldSkinsEngine.PlayerInput(playerID: aID, courseHandicap: 0,
                                          scores: aScores, groupPosted: aPosted),
            FieldSkinsEngine.PlayerInput(playerID: bID, courseHandicap: 0,
                                          scores: bScores, groupPosted: bPosted),
        ]
        let results = FieldSkinsEngine.compute(players: players, settings: settings())
        // A is the current leader — shown as provisional winner, not nil
        XCTAssertEqual(results[0].grossWinner, aID, "Current leader shown even when provisional")
        XCTAssertTrue(results[0].grossIsProvisional, "Should be provisional — not all groups posted")
    }

    // Provisional clears once all groups post.
    func testProvisionalClearsWhenFullyPosted() {
        var aScores = Array(repeating: HoleScore.gross(4), count: 18); aScores[0] = .gross(3)
        let bScores = Array(repeating: HoleScore.gross(4), count: 18)
        let players = [
            FieldSkinsEngine.PlayerInput(playerID: aID, courseHandicap: 0,
                                          scores: aScores, groupPosted: posted18()),
            FieldSkinsEngine.PlayerInput(playerID: bID, courseHandicap: 0,
                                          scores: bScores, groupPosted: posted18()),
        ]
        let results = FieldSkinsEngine.compute(players: players, settings: settings())
        XCTAssertFalse(results[0].grossIsProvisional)
        XCTAssertEqual(results[0].grossWinner, aID)
    }

    // Picked-up player: excluded from skins, but group counts as posted.
    func testPickedUpExcludedFromSkins() {
        var aScores = Array(repeating: HoleScore.gross(4), count: 18); aScores[0] = .pickedUp
        let bScores = Array(repeating: HoleScore.gross(4), count: 18)
        let players = [
            FieldSkinsEngine.PlayerInput(playerID: aID, courseHandicap: 0,
                                          scores: aScores, groupPosted: posted18()),
            FieldSkinsEngine.PlayerInput(playerID: bID, courseHandicap: 0,
                                          scores: bScores, groupPosted: posted18()),
        ]
        let results = FieldSkinsEngine.compute(players: players, settings: settings())
        // A picked up — not in contention. B pars alone — B wins (unique lowest).
        XCTAssertEqual(results[0].grossWinner, bID)
        XCTAssertFalse(results[0].grossIsProvisional)   // group was posted (pick-up = posted)
    }

    // Carryover: hole 1 tie carries to hole 2 where A wins.
    func testCarryover() {
        var aScores = Array(repeating: HoleScore.gross(4), count: 18)
        var bScores = Array(repeating: HoleScore.gross(4), count: 18)
        bScores[0] = .gross(4)   // hole 1 tie
        aScores[1] = .gross(3)   // hole 2: A wins
        let players = [
            FieldSkinsEngine.PlayerInput(playerID: aID, courseHandicap: 0,
                                          scores: aScores, groupPosted: posted18()),
            FieldSkinsEngine.PlayerInput(playerID: bID, courseHandicap: 0,
                                          scores: bScores, groupPosted: posted18()),
        ]
        let s = FieldSkinsEngine.Settings(holeHandicapRanks: stdRanks, allowance: 1.0,
                                           carryoverEnabled: true, potGrossPerHole: 10)
        let results = FieldSkinsEngine.compute(players: players, settings: s)
        XCTAssertNil(results[0].grossWinner)                  // hole 1 tied
        XCTAssertEqual(results[0].grossPot, 10)
        XCTAssertEqual(results[1].grossWinner, aID)           // A wins hole 2
        XCTAssertEqual(results[1].grossPot, 20)               // $10 + $10 carryover
        XCTAssertEqual(results[1].grossCarriedFrom, [1])
    }

    // Last-hole tie with carryover: pot stays unawarded, winner = nil.
    func testLastHoleTieWithCarryoverUnawarded() {
        // Tie on every hole — by hole 18, gross pot = 18 × $10 = $180 unawarded.
        let scores = Array(repeating: HoleScore.gross(4), count: 18)
        let players = [
            FieldSkinsEngine.PlayerInput(playerID: aID, courseHandicap: 0,
                                          scores: scores, groupPosted: posted18()),
            FieldSkinsEngine.PlayerInput(playerID: bID, courseHandicap: 0,
                                          scores: scores, groupPosted: posted18()),
        ]
        let s = FieldSkinsEngine.Settings(holeHandicapRanks: stdRanks, allowance: 1.0,
                                           carryoverEnabled: true,
                                           awardCarryoverOnLastHoleTie: false,
                                           potGrossPerHole: 10)
        let results = FieldSkinsEngine.compute(players: players, settings: s)
        XCTAssertNil(results[17].grossWinner)
        XCTAssertEqual(results[17].grossPot, 180)   // all 18 holes' pots accumulated
    }

    // Score edit: change A's hole-15 gross from 5 to 3, verify skins recompute.
    func testScoreEditRecomputesSkins() {
        // Initial: A scores 5 on hole 15 (SI 15, index 14), B scores 4 → B wins gross.
        var aScoresV1 = Array(repeating: HoleScore.gross(5), count: 18)
        let bScores   = Array(repeating: HoleScore.gross(4), count: 18)
        let players1 = [
            FieldSkinsEngine.PlayerInput(playerID: aID, courseHandicap: 0,
                                          scores: aScoresV1, groupPosted: posted18()),
            FieldSkinsEngine.PlayerInput(playerID: bID, courseHandicap: 0,
                                          scores: bScores, groupPosted: posted18()),
        ]
        let r1 = FieldSkinsEngine.compute(players: players1, settings: settings())
        XCTAssertEqual(r1[14].grossWinner, bID, "Before edit: B wins hole 15 gross skin")

        // After edit: A's hole 15 becomes gross 3 (eagle) → A now wins.
        var aScoresV2 = aScoresV1; aScoresV2[14] = .gross(3)
        let players2 = [
            FieldSkinsEngine.PlayerInput(playerID: aID, courseHandicap: 0,
                                          scores: aScoresV2, groupPosted: posted18()),
            FieldSkinsEngine.PlayerInput(playerID: bID, courseHandicap: 0,
                                          scores: bScores, groupPosted: posted18()),
        ]
        let r2 = FieldSkinsEngine.compute(players: players2, settings: settings())
        XCTAssertEqual(r2[14].grossWinner, aID, "After edit: A wins hole 15 gross skin")
    }

    // Scorer handoff: holes 1-9 from device 1, holes 10-18 from device 2.
    // Scores from both devices merged produce correct skins across all 18 holes.
    func testScorerHandoff() {
        // A's group: holes 1-9 posted (front); B's group: holes 10-18 posted (back).
        var aPosted = Array(repeating: false, count: 18)
        var bPosted = Array(repeating: false, count: 18)
        for i in 0..<9 { aPosted[i] = true; bPosted[i] = true }     // both groups post front
        for i in 9..<18 { aPosted[i] = true; bPosted[i] = true }    // both groups post back
        // After handoff, both groups have all 18 posted.
        // A birdies hole 1 (3), B birdies hole 10 (3), all other holes par (4).
        var aScores = Array(repeating: HoleScore.gross(4), count: 18); aScores[0] = .gross(3)
        var bScores = Array(repeating: HoleScore.gross(4), count: 18); bScores[9] = .gross(3)
        let players = [
            FieldSkinsEngine.PlayerInput(playerID: aID, courseHandicap: 0,
                                          scores: aScores, groupPosted: aPosted),
            FieldSkinsEngine.PlayerInput(playerID: bID, courseHandicap: 0,
                                          scores: bScores, groupPosted: bPosted),
        ]
        let results = FieldSkinsEngine.compute(players: players, settings: settings())
        XCTAssertEqual(results[0].grossWinner, aID,  "A wins gross skin on hole 1")
        XCTAssertEqual(results[9].grossWinner, bID,  "B wins gross skin on hole 10")
        XCTAssertFalse(results[0].grossIsProvisional, "Hole 1 fully posted after handoff")
        XCTAssertFalse(results[9].grossIsProvisional)
    }
}

// ─── Simulated 20-Team Event ──────────────────────────────────────────────────

final class SimulatedEventTests: XCTestCase {

    // 20 teams, 40 players, 10 foursomes, 18 holes, made-up scores.
    // Verifies: net-to-par leaderboard is correctly ordered, one field skins winner per hole.
    func testSimulated20TeamEvent() {
        let holeRanks = Array(1...18)
        let par = Array(repeating: 4, count: 18)

        // 40 players across 10 foursomes (each foursome = 2 teams of 2).
        // Player HC cycles 0, 9, 18, 27 across foursomes.
        // Gross scores: player p on hole h = 4 + (p % 3) − (h % 2) clamped to [1,10].
        var allPlayers: [FieldSkinsEngine.PlayerInput] = []
        var allTeams:   [BestBallEngine.TeamInput] = []
        var teamInputsByGroup: [[BestBallEngine.TeamInput]] = []

        var playerIDs = (0..<40).map { _ in UUID() }
        var teamIDs   = (0..<20).map { _ in UUID() }

        for foursome in 0..<10 {
            var foursomeTeams: [BestBallEngine.TeamInput] = []
            for t in 0..<2 {
                let teamIndex = foursome * 2 + t
                var teamPlayers: [BestBallEngine.PlayerInput] = []
                for slot in 0..<2 {
                    let pIdx = teamIndex * 2 + slot
                    let hc   = (pIdx % 4) * 9    // 0, 9, 18, 27
                    let scores: [HoleScore] = (0..<18).map { h in
                        let raw = 4 + (pIdx % 3) - (h % 2)
                        return .gross(max(1, min(10, raw)))
                    }
                    let pInput = BestBallEngine.PlayerInput(
                        playerID: playerIDs[pIdx], courseHandicap: hc, scores: scores)
                    teamPlayers.append(pInput)

                    let fsInput = FieldSkinsEngine.PlayerInput(
                        playerID: playerIDs[pIdx], courseHandicap: hc,
                        scores: scores, groupPosted: Array(repeating: true, count: 18))
                    allPlayers.append(fsInput)
                }
                let team = BestBallEngine.TeamInput(teamID: teamIDs[teamIndex],
                                                    teamName: "Team \(teamIndex + 1)",
                                                    players: teamPlayers)
                teamPlayers.forEach { _ in }
                foursomeTeams.append(team)
                allTeams.append(team)
            }
            teamInputsByGroup.append(foursomeTeams)
        }

        // Compute best-ball results for each foursome and collect totals.
        var allTotals: [BestBallEngine.TeamTotal] = []
        for (foursome, teams) in teamInputsByGroup.enumerated() {
            let group = BestBallEngine.GroupInput(teams: teams, holeHandicapRanks: holeRanks, par: par)
            let holeResults = BestBallEngine.holeResults(for: group)
            let totals = BestBallEngine.teamTotals(from: holeResults, teams: teams)
            allTotals.append(contentsOf: totals)
        }

        let board = BestBallEngine.leaderboard(from: allTotals)
        XCTAssertEqual(board.count, 20, "20 teams in the leaderboard")
        XCTAssertEqual(board.map { $0.rank }.min(), 1, "Minimum rank is 1")

        // Leaderboard is sorted: totalNetToPar of entry N ≤ entry N+1 (ascending, nil last).
        for i in 1..<board.count {
            let prev = board[i - 1]
            let curr = board[i]
            if let vPrev = prev.totalNetToPar, let vCurr = curr.totalNetToPar {
                XCTAssertLessThanOrEqual(vPrev, vCurr,
                    "Leaderboard out of order at positions \(i-1) and \(i)")
            }
        }

        // Field-wide skins: 18 results, each hole has at most one gross and net winner.
        let fsSettings = FieldSkinsEngine.Settings(holeHandicapRanks: holeRanks, allowance: 1.0,
                                                    carryoverEnabled: false,
                                                    potGrossPerHole: 5, potNetPerHole: 5)
        let skinResults = FieldSkinsEngine.compute(players: allPlayers, settings: fsSettings)
        XCTAssertEqual(skinResults.count, 18)
        for skin in skinResults {
            // A winner and a tie list are mutually exclusive.
            if skin.grossWinner != nil { XCTAssertTrue(skin.grossTied.isEmpty) }
            if skin.netWinner != nil   { XCTAssertTrue(skin.netTied.isEmpty) }
            // Fully posted (all groups have all holes = true).
            XCTAssertFalse(skin.grossIsProvisional)
            XCTAssertFalse(skin.netIsProvisional)
        }
    }
}

// ─── Array helper ─────────────────────────────────────────────────────────────

private extension Array {
    /// Returns a copy with the element at `index` replaced by `value`.
    func with(_ index: Int, _ value: Element) -> [Element] {
        var copy = self; copy[index] = value; return copy
    }
}
