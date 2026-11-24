import XCTest
@testable import WolfmoreGolf

/// Unit tests verifying that withdrawn players:
///  1. Compete for skins on holes they played (FieldSkinsEngine).
///  2. Do not compete for skins on holes they didn't play (FieldSkinsEngine).
///  3. Leave their partner as the sole best-ball contributor on unplayed holes
///     without triggering the both-picked-up cap (BestBallEngine).

// MARK: - FieldSkinsEngine

final class FieldSkinsWithdrawTests: XCTestCase {

    private let wdID  = UUID()   // withdrawn player
    private let oppID = UUID()   // opponent / field player

    private func settings() -> FieldSkinsEngine.Settings {
        FieldSkinsEngine.Settings(
            holeHandicapRanks: Array(1...18),
            allowance: 1.0,
            carryoverEnabled: false,
            potGrossPerHole: 1.0,
            potNetPerHole: 0.0)
    }

    // WD player birdies hole 1 (gross 3) on front 9; holes 10-18 are .notEntered.
    // Opponent is 5 on every hole.
    // Expected: WD player wins gross skin on hole 1, opponent wins holes 10-18.
    func testWDPlayerWinsSkinsOnPlayedHoles() {
        var wdScores  = Array(repeating: HoleScore.gross(5), count: 18)
        var oppScores = Array(repeating: HoleScore.gross(5), count: 18)
        let posted    = Array(repeating: true, count: 18)

        wdScores[0]  = .gross(3)   // birdie hole 1 — WD player wins this skin
        // WD player didn't play holes 10-18
        for i in 9..<18 { wdScores[i] = .notEntered }

        let results = FieldSkinsEngine.compute(players: [
            FieldSkinsEngine.PlayerInput(playerID: wdID,  courseHandicap: 10,
                                         scores: wdScores,  groupPosted: posted),
            FieldSkinsEngine.PlayerInput(playerID: oppID, courseHandicap: 10,
                                         scores: oppScores, groupPosted: posted),
        ], settings: settings())

        XCTAssertEqual(results[0].grossWinner, wdID,
                       "WD player wins skin on hole 1 — played and had the best score")
        XCTAssertTrue(results[0].grossTied.isEmpty,
                      "No tie on hole 1")
    }

    // WD player has .notEntered on holes 10-18; opponent scores normally.
    // Opponent should win solo skins on those holes (no competition from WD player).
    func testWDPlayerExcludedFromUnplayedHoles() {
        var wdScores  = Array(repeating: HoleScore.gross(4), count: 18)
        let oppScores = Array(repeating: HoleScore.gross(5), count: 18)
        let posted    = Array(repeating: true, count: 18)

        for i in 9..<18 { wdScores[i] = .notEntered }

        let results = FieldSkinsEngine.compute(players: [
            FieldSkinsEngine.PlayerInput(playerID: wdID,  courseHandicap: 0,
                                         scores: wdScores,  groupPosted: posted),
            FieldSkinsEngine.PlayerInput(playerID: oppID, courseHandicap: 0,
                                         scores: oppScores, groupPosted: posted),
        ], settings: settings())

        // Opponent wins holes 10-18 as the only player who scored them
        for h in 9..<18 {
            XCTAssertEqual(results[h].grossWinner, oppID,
                           "Opponent wins gross skin on hole \(h+1) — WD player not entered")
            XCTAssertTrue(results[h].grossTied.isEmpty,
                          "No tie on hole \(h+1) — WD player excluded")
        }
    }
}

// MARK: - BestBallEngine

final class BestBallWithdrawTests: XCTestCase {

    private let wdID   = UUID()
    private let partID = UUID()
    private let teamID = UUID()

    // WD player has .notEntered on holes 10-18.
    // Partner scores holes 10-18 at gross 4 (par-4s).
    // Team best-ball for holes 10-18 should be partner's 4,
    // and bothPickedUp cap must NOT trigger (WD = .notEntered, not .pickedUp).
    func testWDPartnerAloneOnBackNine() {
        var wdScores   = Array(repeating: HoleScore.gross(5), count: 18)
        let partScores = Array(repeating: HoleScore.gross(4), count: 18)

        for i in 9..<18 { wdScores[i] = .notEntered }

        let pWD   = BestBallEngine.PlayerInput(playerID: wdID,   courseHandicap: 0,  scores: wdScores)
        let pPart = BestBallEngine.PlayerInput(playerID: partID, courseHandicap: 0,  scores: partScores)
        let team  = BestBallEngine.TeamInput(teamID: teamID, teamName: "T", players: [pWD, pPart])
        let input = BestBallEngine.GroupInput(teams: [team], holeHandicapRanks: Array(1...18),
                                              par: Array(repeating: 4, count: 18))

        let results = BestBallEngine.holeResults(for: input)

        for h in 9..<18 {
            let tr = results[h].teamResults[0]
            XCTAssertFalse(tr.bothPickedUp,
                           "Hole \(h+1): .notEntered ≠ .pickedUp — both-picked-up cap must not apply")
            XCTAssertEqual(tr.bestNet, 4,
                           "Hole \(h+1): partner's gross 4 (HC 0 = 0 strokes) is team best-ball net")
            XCTAssertEqual(tr.bestNetPlayerID, partID,
                           "Hole \(h+1): partner contributes the team score, not WD player")
        }
    }

    // WD player picks up on hole 2; partner also picks up on hole 2.
    // Both-picked-up cap SHOULD fire here (both are .pickedUp, not .notEntered).
    func testBothPickedUpCapStillFiresWhenBothPickUp() {
        var wdScores   = Array(repeating: HoleScore.gross(5), count: 18)
        var partScores = Array(repeating: HoleScore.gross(5), count: 18)
        wdScores[1]   = .pickedUp
        partScores[1] = .pickedUp

        let pWD   = BestBallEngine.PlayerInput(playerID: wdID,   courseHandicap: 0,  scores: wdScores)
        let pPart = BestBallEngine.PlayerInput(playerID: partID, courseHandicap: 0,  scores: partScores)
        let team  = BestBallEngine.TeamInput(teamID: teamID, teamName: "T", players: [pWD, pPart])
        let input = BestBallEngine.GroupInput(teams: [team], holeHandicapRanks: Array(1...18),
                                              par: Array(repeating: 4, count: 18),
                                              bothPickedUpMaxNetOverPar: 2)

        let results = BestBallEngine.holeResults(for: input)
        let h2 = results[1].teamResults[0]

        XCTAssertTrue(h2.bothPickedUp, "Hole 2: both .pickedUp → bothPickedUp must be true")
        XCTAssertEqual(h2.bestNet, 4 + 2, "Hole 2: cap = par(4) + 2 = 6")
    }
}
