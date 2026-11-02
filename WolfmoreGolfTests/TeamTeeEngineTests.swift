import XCTest
@testable import WolfmoreGolf

// Verifies that TeamTeeEngine uses absolute handicap strokes (same helper used when
// storing netScore in Supabase), so the scoring-page "Team Net" and the leaderboard
// "Team Net" can never disagree.
//
// Setup: 4 players · 6 holes committed · 4-3-2 by par
//
//   Course pars:    [4, 3, 5, 4, 3, 5]
//   Stroke indices: [2, 6, 4, 8,10,12]
//   Player HCs:     P0=4, P1=10, P2=14, P3=20
//   Gross (all):    [5, 4, 6, 5, 4, 6]  (bogey on every hole)
//
//   Absolute nets (= what absoluteStrokesGiven produces = what Supabase stores):
//     P0 HC=4  → strokes on si≤4 only  → nets [4,4,5,5,4,6]
//     P1 HC=10 → strokes on si≤10      → nets [4,3,5,4,3,6]
//     P2 HC=14 → strokes on all 6      → nets [4,3,5,4,3,5]
//     P3 HC=20 → 2 strokes on si=2, 1 elsewhere → nets [3,3,5,4,3,5]
//
//   4-3-2 by par: par-3 counts 4, par-4 counts 3, par-5 counts 2
//     H0 par4 cnt3: [4,4,4,3] → 3+4+4 = 11
//     H1 par3 cnt4: [4,3,3,3] → 4+3+3+3 = 13
//     H2 par5 cnt2: [5,5,5,5] → 5+5 = 10
//     H3 par4 cnt3: [5,4,4,4] → 4+4+4 = 12
//     H4 par3 cnt4: [4,3,3,3] → 4+3+3+3 = 13
//     H5 par5 cnt2: [6,6,5,5] → 5+5 = 10
//                               Total = 69
//
//   Old (wrong) relative approach would give 73 because P0 (the low player,
//   delta=0) received no strokes — the leaderboard gave him 2, producing a
//   4-stroke gap (73 vs 69).
final class TeamTeeEngineTests: XCTestCase {

    func testAbsoluteHCProducesCorrectTeamNet() {
        let result = TeamTeeEngine.recalculate(gameData: makeGame())
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.holesCompleted, 6)
        XCTAssertEqual(result!.runningTotal, 69,
            "Expected 69 (absolute HC); old relative approach produced 73")
    }

    // Simulates what the leaderboard does: compute absolute net per player per hole
    // using the same absoluteStrokesGiven helper, then apply count-by-par.
    // The engine total must equal the leaderboard total.
    func testEngineMatchesLeaderboardCalculation() {
        let g = makeGame()
        let engineTotal = TeamTeeEngine.recalculate(gameData: g)?.runningTotal ?? -1
        let leaderboardTotal = simulateLeaderboard(game: g)
        XCTAssertEqual(engineTotal, leaderboardTotal,
            "Scoring-page engine and leaderboard must produce the same team net")
    }

    // MARK: - Helpers

    private func makeGame() -> GameData {
        var g = GameData()
        g.course = Course(
            name: "Test",
            pars: [4,3,5,4,3,5] + Array(repeating: 4, count: 12),
            holeHandicaps: [2,6,4,8,10,12] + Array(7...18)
        )

        let hcs = [4, 10, 14, 20]
        for seat in 0..<4 {
            g.playerNames[seat]    = "P\(seat)"
            g.playerActivated[seat] = true
            g.hcPlayers[seat]      = hcs[seat]
        }

        let gross = [5, 4, 6, 5, 4, 6]
        for seat in 0..<4 {
            for h in 0..<6 { g.scores[seat][h] = gross[h] }
        }

        g.holeCommitted = [true,true,true,true,true,true] + Array(repeating: false, count: 12)

        var settings = TeamTeeSettings()
        settings.isEnabled  = true
        settings.countMode  = .byPar
        settings.par3Count  = 4
        settings.par4Count  = 3
        settings.par5Count  = 2
        g.teamTeeSettings = settings

        return g
    }

    // Mirrors TournamentLeaderboardViewController's calculation:
    // read absolute net (= gross - absoluteStrokesGiven) for each player per hole,
    // then take the lowest N by par.
    private func simulateLeaderboard(game g: GameData) -> Int {
        guard let settings = g.teamTeeSettings, settings.isEnabled else { return 0 }
        let gm = GameManager.shared
        var total = 0
        for h in 0..<6 {
            guard g.holeCommitted[safe: h] == true else { continue }
            let par = g.course.pars[safe: h] ?? 4
            let si  = g.course.holeHandicaps[safe: h] ?? h + 1
            let nets: [Int] = (0..<4).compactMap { seat -> Int? in
                guard let gross = g.scores[seat][safe: h] ?? nil else { return nil }
                let pops = gm.absoluteStrokesGiven(playerHC: g.hcPlayers[seat], strokeIndex: si)
                return gross - pops
            }
            let countN = settings.count(forPar: par)
            total += nets.sorted().prefix(countN).reduce(0, +)
        }
        return total
    }
}
