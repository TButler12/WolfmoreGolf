import XCTest
@testable import WolfmoreGolf

// Characterization test for local Nassau with auto-presses and dollar stakes.
// Values were captured from a live engine run and locked in here.
// DO NOT edit these assertions without re-running the characterization print
// and confirming the new values match intended local Nassau behavior.
//
// Scenario:
//   Alice (team 1, HC 0): bogeys (5) front 9, pars (4) back 9
//   Bob   (team 2, HC 0): pars  (4) front 9, bogeys (5) back 9
//   Course: all par-4, stroke index 1–18 in order
//   Stake $10, auto-press at 2-down, nextHole start rule
//
// Expected:
//   Front — Bob wins 9-up; auto-press fires after hole 2 (Bob 2-up),
//            press runs holes 3–9, Bob wins press 7-up
//   Back  — Alice wins 9-up; auto-press fires after hole 11 (Alice 2-up),
//            press runs holes 12–18, Alice wins press 7-up
//   Overall — exactly even (front 9 cancel back 9)
//   Money   — front −$10 + press −$10 + back +$10 + press +$10 = Even
final class LocalNassauCharacterizationTests: XCTestCase {

    func testLocalNassauAutoPressCharacterization() {
        var g = GameData()
        g.course = Course(
            name: "Test",
            pars: Array(repeating: 4, count: STANDARD_HOLES),
            holeHandicaps: Array(1...STANDARD_HOLES)
        )
        g.playerNames[0] = "Alice"
        g.playerNames[1] = "Bob"
        g.playerActivated[0] = true
        g.playerActivated[1] = true
        g.hcPlayers[0] = 0
        g.hcPlayers[1] = 0

        for h in 0..<9  { g.scores[0][h] = 5 }   // Alice: bogeys front
        for h in 9..<18 { g.scores[0][h] = 4 }   // Alice: pars back
        for h in 0..<9  { g.scores[1][h] = 4 }   // Bob: pars front
        for h in 9..<18 { g.scores[1][h] = 5 }   // Bob: bogeys back

        g.holeCommitted = Array(repeating: true, count: STANDARD_HOLES)

        var settings = NassauSettings()
        settings.baseStake            = 10.0
        settings.pressMode            = .auto
        settings.autoPressTriggerDown = 2
        settings.pressStartRule       = .nextHole
        settings.pressAmountMode      = .sameAsBase

        var match = NassauMatch(
            title: "Alice vs Bob",
            format: .oneVsOne,
            team1PlayerIndexes: [0],
            team2PlayerIndexes: [1]
        )
        match.stake = 10.0

        var state = NassauState(
            settings: settings,
            oneVsOneMatches: [match]
        )
        NassauEngine.recalculate(state: &state, gameData: g)
        let r = state.oneVsOneMatches[0]

        // Running status arrays
        XCTAssertEqual(r.frontStatusByHole,   [-1, -2, -3, -4, -5, -6, -7, -8, -9])
        XCTAssertEqual(r.backStatusByHole,    [1, 2, 3, 4, 5, 6, 7, 8, 9])
        XCTAssertEqual(r.overallStatusByHole,
                       [-1, -2, -3, -4, -5, -6, -7, -8, -9, -8, -7, -6, -5, -4, -3, -2, -1, 0])

        // Two auto-presses: one front, one back
        XCTAssertEqual(r.presses.count, 2)

        let front = r.presses[0]
        XCTAssertEqual(front.segment,       .front)
        XCTAssertEqual(front.startHole,     3)
        XCTAssertEqual(front.endHole,       9)
        XCTAssertEqual(front.stake,         10.0)
        XCTAssertEqual(front.runningStatus, [-1, -2, -3, -4, -5, -6, -7])

        let back = r.presses[1]
        XCTAssertEqual(back.segment,        .back)
        XCTAssertEqual(back.startHole,      12)
        XCTAssertEqual(back.endHole,        18)
        XCTAssertEqual(back.stake,          10.0)
        XCTAssertEqual(back.runningStatus,  [1, 2, 3, 4, 5, 6, 7])

        // Dollar outcome: front and presses cancel → Even
        let money = NassauEngine.netNassauMoneyText(
            for: r,
            playerNames: g.playerNames,
            gameData: g
        )
        XCTAssertEqual(money, "Even")
    }
}
