import XCTest
@testable import WolfmoreGolf

/// UI-level tests for ClubEventGroupSetupViewController team assignment rules.
/// All pure-Swift — no network, no simulator display needed.
final class ClubEventGroupSetupTests: XCTestCase {

    private func makePlayer(_ name: String, hc: Double = 10) -> ClubEventPlayer {
        ClubEventPlayer(id: UUID(), tournamentId: UUID(), playerName: name, handicap: hc, groupCode: nil)
    }

    private func makeVC(allowDualTeam: Bool = false) -> ClubEventGroupSetupViewController {
        let event = ClubEventRecord(id: UUID(), code: "TEST01", name: "Test",
                                    organizerDeviceId: "x", courseName: nil, numDays: 1, status: "active")
        let vc = ClubEventGroupSetupViewController(event: event)
        vc.skipNetworkLoad = true
        vc.allowDualTeam   = allowDualTeam
        vc.loadViewIfNeeded()
        return vc
    }

    // MARK: - 4 players, 2 per team → Confirm enabled

    func testConfirmEnabledWithTwoPerTeam() {
        let vc = makeVC()
        let p  = (0..<4).map { makePlayer("P\($0)") }
        vc.selected = [
            (.roster(p[0]), ["A"]),
            (.roster(p[1]), ["A"]),
            (.roster(p[2]), ["B"]),
            (.roster(p[3]), ["B"]),
        ]
        vc.updateConfirmState()
        XCTAssertTrue(vc.isConfirmEnabled, "2+2 split must enable Confirm")
    }

    // MARK: - Shared player on both teams counts for each

    func testSharedPlayerCountsForBothTeams() {
        let vc = makeVC(allowDualTeam: true)
        let p  = (0..<3).map { makePlayer("P\($0)") }
        // P0 on A+B, P1 on A, P2 on B → teamA=2, teamB=2
        vc.selected = [
            (.roster(p[0]), ["A", "B"]),
            (.roster(p[1]), ["A"]),
            (.roster(p[2]), ["B"]),
        ]
        vc.updateConfirmState()
        XCTAssertTrue(vc.isConfirmEnabled, "Shared player + 1 per team = 2+2, must enable Confirm")
    }

    // MARK: - Full team button: enabled, shows "Full", fires swap callback

    func testFullTeamButtonTappableAndFiresSwapCallback() {
        var swapTeamFired: String? = nil
        let cell = SelectedPlayerCell(style: .default, reuseIdentifier: "Selected")
        cell.configure(name: "P2", handicap: "HC 10", teams: ["B"],
                       allowDual: false, teamACount: 2, teamBCount: 1) { _ in }
        cell.onFullTeamTap = { team in swapTeamFired = team }
        XCTAssertTrue(cell.teamABtn.isEnabled, "Full button must be enabled to allow swap offer")
        XCTAssertEqual(cell.teamABtn.title(for: .normal), "Full", "Button title must read 'Full'")
        XCTAssertTrue(cell.teamBBtn.isEnabled, "Team B must remain enabled")
        cell.teamABtn.sendActions(for: .touchUpInside)
        XCTAssertEqual(swapTeamFired, "A", "Tapping Full must fire onFullTeamTap with team A")
    }

    func testPlayerOnFullTeamCanRemoveThemselves() {
        // Player IS on Team A and Team A has 2 players — their own button must stay enabled.
        let cell = SelectedPlayerCell(style: .default, reuseIdentifier: "Selected")
        cell.configure(name: "P0", handicap: "HC 10", teams: ["A"],
                       allowDual: false, teamACount: 2, teamBCount: 1) { _ in }
        XCTAssertTrue(cell.teamABtn.isEnabled,
                      "Player on the full team must be able to tap to remove themselves")
        XCTAssertEqual(cell.teamABtn.title(for: .normal), "Team A")
    }

    // MARK: - Single-team group (Team B empty) is valid

    func testConfirmEnabledWithSingleTeamOfTwo() {
        let vc = makeVC()
        let p  = (0..<2).map { makePlayer("P\($0)") }
        vc.selected = [
            (.roster(p[0]), ["A"]),
            (.roster(p[1]), ["A"]),
        ]
        vc.updateConfirmState()
        XCTAssertTrue(vc.isConfirmEnabled, "2 players on Team A, Team B empty → single-team group is valid")
    }

    func testConfirmEnabledWithSingleTeamOfOne() {
        let vc = makeVC()
        vc.selected = [(.roster(makePlayer("Solo")), ["A"])]
        vc.updateConfirmState()
        XCTAssertTrue(vc.isConfirmEnabled, "1 player on Team A, Team B empty → valid")
    }

    // MARK: - Confirm disabled when a team has no players

    func testConfirmDisabledWhenTeamAEmpty() {
        let vc = makeVC()
        let p  = (0..<2).map { makePlayer("P\($0)") }
        vc.selected = [
            (.roster(p[0]), ["B"]),
            (.roster(p[1]), ["B"]),
        ]
        vc.updateConfirmState()
        XCTAssertFalse(vc.isConfirmEnabled, "Team A empty → Confirm must be disabled")
    }

    // MARK: - Both buttons always visible (no hidden Team B)

    func testBothButtonsAlwaysVisible() {
        let cell = SelectedPlayerCell(style: .default, reuseIdentifier: "Selected")
        // dual-team off, player on Team A — Team B button must NOT be hidden
        cell.configure(name: "P0", handicap: "HC 10", teams: ["A"],
                       allowDual: false, teamACount: 1, teamBCount: 0) { _ in }
        XCTAssertFalse(cell.teamABtn.isHidden, "Team A button must never be hidden")
        XCTAssertFalse(cell.teamBBtn.isHidden, "Team B button must never be hidden")
    }

    // MARK: - Dual-team on: tapping second team adds (checkbox)

    func testDualTeamToggleAddsPlayerToBothTeams() {
        var capturedTeams: [String] = []
        let cell = SelectedPlayerCell(style: .default, reuseIdentifier: "Selected")
        // Player on A, dual ON, neither team full → tapping B adds to both
        cell.configure(name: "P0", handicap: "HC 10", teams: ["A"],
                       allowDual: true, teamACount: 1, teamBCount: 1) { capturedTeams = $0 }
        cell.teamBBtn.sendActions(for: .touchUpInside)
        XCTAssertEqual(Set(capturedTeams), ["A", "B"], "Dual-team on: tapping B adds to both teams")
    }

    // MARK: - Dual-team off: tapping second team moves (radio)

    func testNoDualTeamMovesPlayerRadioMode() {
        var capturedTeams: [String] = []
        let cell = SelectedPlayerCell(style: .default, reuseIdentifier: "Selected")
        // Player on A, dual OFF → tapping B replaces A with B
        cell.configure(name: "P0", handicap: "HC 10", teams: ["A"],
                       allowDual: false, teamACount: 1, teamBCount: 0) { capturedTeams = $0 }
        cell.teamBBtn.sendActions(for: .touchUpInside)
        XCTAssertEqual(capturedTeams, ["B"], "Dual-team off: tapping B replaces A (radio mode)")
    }
}

// MARK: - 9-hole stroke allocation

/// HC 20 on a 9-hole course → HC9 = round(20/2) = 10.
/// Rank 1 gets 2 strokes (base 1 + extra); ranks 2–9 get 1 stroke each; total = 10.
final class ClubEvent9HoleStrokeTests: XCTestCase {

    func testHC20NineHoleRank1Gets2Strokes() {
        XCTAssertEqual(
            ClubEventScoringViewController.strokesOnHole(playerHC: 20, holeHCRank: 1, holeCount: 9), 2,
            "HC 20 nine-hole rank 1: base 1 + extra 1 = 2")
    }

    func testHC20NineHoleRank2Gets1Stroke() {
        XCTAssertEqual(
            ClubEventScoringViewController.strokesOnHole(playerHC: 20, holeHCRank: 2, holeCount: 9), 1,
            "HC 20 nine-hole rank 2: base 1 only (extra only on rank 1)")
    }

    func testHC20NineHoleTotalStrokesEqualsHC9() {
        // Sum over all 9 ranks must equal HC9 = 10
        let total = (1...9).reduce(0) {
            $0 + ClubEventScoringViewController.strokesOnHole(playerHC: 20, holeHCRank: $1, holeCount: 9)
        }
        XCTAssertEqual(total, 10, "HC 20 on 9-hole: total strokes must equal HC9 = 10")
    }

    func testHC20EighteenHoleTotalStrokesUnchanged() {
        // 18-hole: 20/18=1, 20%18=2 → ranks 1-2 get 2, rest get 1 (total=20)
        let total = (1...18).reduce(0) {
            $0 + ClubEventScoringViewController.strokesOnHole(playerHC: 20, holeHCRank: $1, holeCount: 18)
        }
        XCTAssertEqual(total, 20, "HC 20 on 18-hole: total strokes must still be 20")
    }

    func testScratchNineHoleGetsZeroStrokes() {
        for rank in 1...9 {
            XCTAssertEqual(
                ClubEventScoringViewController.strokesOnHole(playerHC: 0, holeHCRank: rank, holeCount: 9), 0,
                "Scratch nine-hole: 0 strokes on every hole")
        }
    }
}
