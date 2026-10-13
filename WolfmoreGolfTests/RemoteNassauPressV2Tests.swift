import XCTest
@testable import WolfmoreGolf

final class RemoteNassauPressV2Tests: XCTestCase {

    // MARK: - Helpers

    private func pair(net: Int) -> PairedHole {
        PairedHole(hcRank: 1, hostPhysicalHole: 1,
                   hostScore: 4, hostNetScore: 4, hostStrokes: 0, hostPar: nil,
                   opponentPhysicalHole: 1,
                   opponentScore: 4, opponentNetScore: 4, opponentStrokes: 0, opponentPar: nil,
                   netResult: net)
    }

    private func unscored() -> PairedHole {
        PairedHole(hcRank: 1, hostPhysicalHole: 1,
                   hostScore: nil, hostNetScore: nil, hostStrokes: 0, hostPar: nil,
                   opponentPhysicalHole: 1,
                   opponentScore: nil, opponentNetScore: nil, opponentStrokes: 0, opponentPar: nil,
                   netResult: 0)
    }

    private func hostOnly() -> PairedHole {
        PairedHole(hcRank: 1, hostPhysicalHole: 1,
                   hostScore: 4, hostNetScore: 4, hostStrokes: 0, hostPar: nil,
                   opponentPhysicalHole: 1,
                   opponentScore: nil, opponentNetScore: nil, opponentStrokes: 0, opponentPar: nil,
                   netResult: 0)
    }

    private func pairs(_ nets: [Int]) -> [PairedHole] { nets.map { pair(net: $0) } }

    // MARK: - Test 1: Multiple presses from original nine

    func testV2_OriginalNineTriggersTwice_TwoPresses() {
        // Original nine goes 2 down at H2 (cumulative: -1,-2), recovers, then 2 down again at H6.
        // Press 1's own score stays modest — no sub-press from it.
        // Net: [-1,-1, 0,+1, 0,-1,-1, 0, 0]
        // S0 cumulative: -1,-2,-2,-1,-1,-2,-3,-3,-3
        // S0 fires at idx=1 (cum=-2, prevAbs=1→2): Press 1 starts H3.
        // S0 fires at idx=5 (cum=-2, prevAbs=1→2): Press 2 starts H7.
        let nets = [-1, -1, 0, +1, 0, -1, -1, 0, 0]
        let presses = NassauPressDetector.detectV2(
            pairs: pairs(nets), holeOffset: 0, segmentEndPos: 9, trigger: 2, stake: 1.0)

        XCTAssertEqual(presses.count, 2, "Two presses from original nine crossing trigger twice")
        XCTAssertEqual(presses[0].startPos, 3, "Press 1 starts H3")
        XCTAssertEqual(presses[1].startPos, 7, "Press 2 starts H7")
        XCTAssertEqual(presses[0].endPos, 9)
        XCTAssertEqual(presses[1].endPos, 9)
    }

    // MARK: - Test 2: Press triggers sub-press

    func testV2_PressTriggersSubPress() {
        // Original nine goes 2 down at H2 → Press 1 starts H3.
        // Press 1's own score reaches +2 at H5 (opponent of Press 1 is 2 down) → Press 2 starts H6.
        // Net: [-1,-1, 0,+1,+1, 0, 0, 0, 0]
        let nets = [-1, -1, 0, +1, +1, 0, 0, 0, 0]
        let presses = NassauPressDetector.detectV2(
            pairs: pairs(nets), holeOffset: 0, segmentEndPos: 9, trigger: 2, stake: 1.0)

        XCTAssertEqual(presses.count, 2, "Original nine fires, then Press 1 fires a sub-press")
        XCTAssertEqual(presses[0].startPos, 3, "Press 1 from original nine, starts H3")
        XCTAssertEqual(presses[1].startPos, 6, "Press 2 triggered by Press 1 going 2 up, starts H6")
        // Press 2 covers H6–H9 (all net=0): running status is [0,0,0,0]
        XCTAssertEqual(presses[1].runningStatus, [0, 0, 0, 0])
    }

    // MARK: - Test 3: Trigger on last hole → no press; second-to-last → 1-hole press

    func testV2_TriggerOnLastHole_NoPress() {
        // Score reaches 2 down only on H9 (the last front hole). No room for a next hole.
        let nets = [0, 0, 0, 0, 0, 0, 0, 0, -2]
        let presses = NassauPressDetector.detectV2(
            pairs: pairs(nets), holeOffset: 0, segmentEndPos: 9, trigger: 2, stake: 1.0)
        XCTAssertTrue(presses.isEmpty, "No press when trigger is on the last hole of the nine")
    }

    func testV2_TriggerOnSecondToLastHole_OneholePressCreated() {
        // Score reaches 2 down on H8 → 1-hole press at H9 is valid.
        let nets = [0, 0, 0, 0, 0, 0, 0, -2, 0]
        let presses = NassauPressDetector.detectV2(
            pairs: pairs(nets), holeOffset: 0, segmentEndPos: 9, trigger: 2, stake: 1.0)
        XCTAssertEqual(presses.count, 1)
        XCTAssertEqual(presses[0].startPos, 9, "1-hole press correctly starts at H9")
        XCTAssertEqual(presses[0].endPos,   9)
    }

    // MARK: - Test 4: 18-hole bet money is exactly ±stake, independent of presses

    func testV2_EighteenHoleBet_MoneyIsExactlyStakeAndIndependentOfPresses() {
        // Front: host wins 2 up at H2, then even rest → presses fire on the front.
        // Back: all even → no presses.
        // Overall 18: host 2 up → overallMoney = +stake, regardless of press count.
        var frontNets = Array(repeating: 0, count: 9)
        frontNets[0]  = +1
        frontNets[1]  = +1
        let backNets  = Array(repeating: 0, count: 9)
        let stake     = 3.0

        let frontPairs = pairs(frontNets)
        let backPairs  = pairs(backNets)

        let frontPresses = NassauPressDetector.detectV2(
            pairs: frontPairs, holeOffset: 0, segmentEndPos: 9, trigger: 2, stake: stake)
        let backPresses  = NassauPressDetector.detectV2(
            pairs: backPairs, holeOffset: 9, segmentEndPos: 18, trigger: 2, stake: stake)

        // Presses exist on the front (reached +2 at H2)
        XCTAssertFalse(frontPresses.isEmpty, "Front presses should fire when score reaches trigger")
        XCTAssertTrue (backPresses.isEmpty,  "Back never reaches trigger")

        // All front presses are confined to the front nine
        for p in frontPresses {
            XCTAssertLessThanOrEqual(p.endPos, 9, "Front press endPos must be ≤ 9")
        }

        // 18-hole overall money is computed independently — always exactly ±stake
        let overallStatus = NassauPressDetector.runningStatus(from: frontPairs + backPairs)
        let overallMoney  = NassauPressDetector.segmentMoney(
            status: overallStatus, complete: true, stake: stake)
        XCTAssertEqual(overallStatus.last, 2, "Overall final: host 2 up")
        XCTAssertEqual(overallMoney, stake,
                       "18-hole bet pays exactly $\(Int(stake)), not multiplied by dominance or press count")

        // Confirm total money = front + back + overall + press components (presses add on top)
        let frontMoney = NassauPressDetector.segmentMoney(
            status: NassauPressDetector.runningStatus(from: frontPairs), complete: true, stake: stake)
        let backMoney  = NassauPressDetector.segmentMoney(
            status: NassauPressDetector.runningStatus(from: backPairs),  complete: true, stake: stake)
        XCTAssertEqual(frontMoney, stake, "Host wins front nine")
        XCTAssertEqual(backMoney, 0,      "Back nine is even")
        // overallMoney is the same whether presses exist or not
        XCTAssertEqual(overallMoney, stake)
    }

    // MARK: - Test 5: Same hole triggers two presses in fixed insertion order

    func testV2_SameHoleTrigger_TwoPressesInInsertionOrder() {
        // H2: original nine fires → Press 1 starts H3. S1 activates at H3.
        // H3: net=+2. S1 (Press 1) immediately goes +2 → Press 2 starts H4. S2 activates at H4.
        // H4: net=-2. S0 resets to 0 then drops to -2 (prevAbs=0 after H3) → Press 3 starts H5.
        //             S2 (from Press 2) also gets -2 → Press 4 starts H5.
        // Both Press 3 and 4 start at H5; Press 3 (from original nine) precedes Press 4 (from Press 2).
        let nets = [-1, -1, +2, -2, 0, 0, 0, 0, 0]
        let presses = NassauPressDetector.detectV2(
            pairs: pairs(nets), holeOffset: 0, segmentEndPos: 9, trigger: 2, stake: 1.0)

        XCTAssertEqual(presses.count, 4)
        XCTAssertEqual(presses[0].startPos, 3, "Press 1: original nine fires at H2 → H3")
        XCTAssertEqual(presses[1].startPos, 4, "Press 2: Press 1 fires at H3 → H4")
        XCTAssertEqual(presses[2].startPos, 5, "Press 3: original nine fires at H4 → H5")
        XCTAssertEqual(presses[3].startPos, 5, "Press 4: Press 2 fires at H4 → H5")
        // Both start at H5; the original nine's press (3) comes before Press 2's sub-press (4)
        // so both devices always show the same ordering.
    }

    // MARK: - Test 6: Unscored holes are skipped by all segments

    func testV2_UnscoredHoles_SkippedByAllSegments() {
        // Net: [-1,-1, unscored, -1] — unscored at H3 should not advance any segment's score.
        // Original nine fires at H2 (idx=1) → Press 1 starts H3 (idx=2 = unscored, skipped).
        // Press 1 starts accumulating at H3, but H3 is unscored so it starts at H4.
        let pairedHoles: [PairedHole] = [
            pair(net: -1),
            pair(net: -1),
            unscored(),
            pair(net: -1),
            pair(net: -1),
            pair(net: 0),
            pair(net: 0),
            pair(net: 0),
            pair(net: 0)
        ]
        let presses = NassauPressDetector.detectV2(
            pairs: pairedHoles, holeOffset: 0, segmentEndPos: 9, trigger: 2, stake: 1.0)

        // S0 at idx=0: cum=-1, No. idx=1: cum=-2, fire → Press 1 starts pos=3. idx=2: unscored, skip.
        // idx=3: S0.cum=-3, prevAbs=2→No. S1(start=2, but idx=2 unscored, so first activation at idx=3): cum=-1.
        // idx=4: S0.cum=-4. S1.cum=-2, prevAbs=1→2, fire! Press 2 starts pos=6.
        XCTAssertEqual(presses.count, 2)
        XCTAssertEqual(presses[0].startPos, 3)
        XCTAssertEqual(presses[1].startPos, 6, "Press 1 fires at H5 (idx=4) → H6")
    }

    // MARK: - Test 7: Partially scored hole (host only) is skipped; press updates when opponent scores

    func testV2_PartiallyScored_HostOnlySkipped_UpdatesWhenOpponentScores() {
        // H1=−1, H2=−1 → original nine fires, press starts H3.
        // State A — H3: host scored (4), opponent not yet (opponentScore=nil).
        //   The guard skips H3 for all segments. Press running status starts from H4.
        // State B — opponent scores H3 (net=−1): H3 is now complete.
        //   Press running status now includes H3 as its first entry.

        let holesPartialH3: [PairedHole] = [
            pair(net: -1),  // H1
            pair(net: -1),  // H2 → original nine crosses trigger, press starts H3
            hostOnly(),     // H3: host scored, opponent hasn't
            pair(net: 0),   // H4
            pair(net: 0),   // H5
            pair(net: 0),   // H6
            pair(net: 0),   // H7
            pair(net: 0),   // H8
            pair(net: 0),   // H9
        ]
        let holesFullyScored: [PairedHole] = [
            pair(net: -1),
            pair(net: -1),
            pair(net: -1),  // H3 now fully scored, net=−1
            pair(net: 0),
            pair(net: 0),
            pair(net: 0),
            pair(net: 0),
            pair(net: 0),
            pair(net: 0),
        ]

        let pressesA = NassauPressDetector.detectV2(
            pairs: holesPartialH3, holeOffset: 0, segmentEndPos: 9, trigger: 2, stake: 1.0)
        let pressesB = NassauPressDetector.detectV2(
            pairs: holesFullyScored, holeOffset: 0, segmentEndPos: 9, trigger: 2, stake: 1.0)

        // One press in both states; it starts at H3 regardless
        XCTAssertEqual(pressesA.count, 1)
        XCTAssertEqual(pressesA[0].startPos, 3)
        XCTAssertEqual(pressesB.count, 1)
        XCTAssertEqual(pressesB[0].startPos, 3)

        // State A: H3 excluded — press running status covers only H4–H9 (6 zeros)
        XCTAssertEqual(pressesA[0].runningStatus.count, 6,
                       "H3 skipped: only H4–H9 count toward press running status")

        // State B: H3 now included — press covers H3–H9 (7 entries, first is −1)
        XCTAssertEqual(pressesB[0].runningStatus.count, 7,
                       "H3 now complete: press running status includes it")
        XCTAssertEqual(pressesB[0].runningStatus.first, -1,
                       "H3 net=−1 appears as the first press entry once opponent scores")
    }

    // MARK: - detectLegacy compatibility tests

    func testLegacy_SinglePress_Trigger2() {
        // Original nine goes 2 down at H2 → one press at H3. Nothing more.
        let nets = [-1, -1, 0, 0, 0, 0, 0, 0, 0]
        let presses = NassauPressDetector.detectLegacy(
            pairs: pairs(nets), holeOffset: 0, segmentEndPos: 9, trigger: 2, stake: 1.0)
        XCTAssertEqual(presses.count, 1)
        XCTAssertEqual(presses[0].startPos, 3)
        XCTAssertEqual(presses[0].endPos, 9)
    }

    func testLegacy_MaxThreeCapBlocksFourthPress() {
        // Alternating -1/+1 at trigger=1: fires at H2, H4, H6 (indices 0, 2, 4),
        // then index 6 would fire a fourth but is capped at 3.
        let nets = [-1, +1, -1, +1, -1, +1, -1, +1, 0]
        let presses = NassauPressDetector.detectLegacy(
            pairs: pairs(nets), holeOffset: 0, segmentEndPos: 9, trigger: 1, stake: 1.0)
        XCTAssertEqual(presses.count, 3, "Legacy caps at 3 presses")
        XCTAssertEqual(presses[0].startPos, 2)
        XCTAssertEqual(presses[1].startPos, 4)
        XCTAssertEqual(presses[2].startPos, 6)
    }

    func testLegacy_Trigger1_FirstHoleFiresPress() {
        // Going 1 down on the very first hole fires a press starting H2.
        let nets = [-1, 0, 0, 0, 0, 0, 0, 0, 0]
        let presses = NassauPressDetector.detectLegacy(
            pairs: pairs(nets), holeOffset: 0, segmentEndPos: 9, trigger: 1, stake: 1.0)
        XCTAssertEqual(presses.count, 1)
        XCTAssertEqual(presses[0].startPos, 2)
    }

    func testLegacy_PressOwnScoreDoesNotTriggerSubPress() {
        // nets = [-1,-1,0,+1,+1,0,0,0,0] — same as testV2_PressTriggersSubPress.
        // Legacy fires one press (original nine hits −2 at H2).
        // Press 1's own score reaching +2 at H5 does NOT trigger a sub-press in legacy.
        // V2 would fire two presses for comparison.
        let nets = [-1, -1, 0, +1, +1, 0, 0, 0, 0]
        let legacyPresses = NassauPressDetector.detectLegacy(
            pairs: pairs(nets), holeOffset: 0, segmentEndPos: 9, trigger: 2, stake: 1.0)
        let v2Presses = NassauPressDetector.detectV2(
            pairs: pairs(nets), holeOffset: 0, segmentEndPos: 9, trigger: 2, stake: 1.0)
        XCTAssertEqual(legacyPresses.count, 1, "Legacy: no sub-press from Press 1's own score")
        XCTAssertEqual(v2Presses.count,     2, "V2: Press 1 going 2 up triggers sub-press")
        XCTAssertEqual(legacyPresses[0].startPos, 3)
    }

    func testLegacy_SinglePress_MoneyMatchesSegmentMoney() {
        // nets=[+1,+1,0,0,0,0,0,0,0], trigger=2, stake=5.
        // One press from H3 to H9 with all nets=0 → press money=0.
        let nets = [+1, +1, 0, 0, 0, 0, 0, 0, 0]
        let stake = 5.0
        let allPairs = pairs(nets)
        let presses = NassauPressDetector.detectLegacy(
            pairs: allPairs, holeOffset: 0, segmentEndPos: 9, trigger: 2, stake: stake)
        XCTAssertEqual(presses.count, 1)
        let pressMoney = NassauPressDetector.segmentMoney(
            status: presses[0].runningStatus, complete: true, stake: stake)
        XCTAssertEqual(pressMoney, 0, "Press covering all-even holes pays nothing")
        let nineStatus = NassauPressDetector.runningStatus(from: allPairs)
        let nineMoney  = NassauPressDetector.segmentMoney(status: nineStatus, complete: true, stake: stake)
        XCTAssertEqual(nineMoney, stake, "Host wins the nine")
    }

    func testLegacy_BackNinePressUsesCorrectHoleNumbers() {
        // holeOffset=9: holes on the back are positions 10–18.
        // nets=[0,0,-1,-1,0,0,0,0,0] (H10=0,H11=0,H12=−1,H13=−1 → 2 down at H13 → press at H14).
        let nets = [0, 0, -1, -1, 0, 0, 0, 0, 0]
        let presses = NassauPressDetector.detectLegacy(
            pairs: pairs(nets), holeOffset: 9, segmentEndPos: 18, trigger: 2, stake: 1.0)
        XCTAssertEqual(presses.count, 1)
        XCTAssertEqual(presses[0].startPos, 14, "Back nine press starts at H14")
        XCTAssertEqual(presses[0].endPos,   18)
    }

    // MARK: - rulesDescription v2 format

    func testRulesDescription_V2_AutoPress() {
        XCTAssertEqual(
            WolfActions.rulesDescription(stake: 5, pressMode: .auto, trigger: 3, isV2: true),
            "Unlimited auto presses at 3 down · $5 per bet")
    }

    func testRulesDescription_V2_Off() {
        XCTAssertEqual(
            WolfActions.rulesDescription(stake: 5, pressMode: .off, trigger: 3, isV2: true),
            "$5 · No press")
    }

    func testRulesDescription_V2_ManualTreatedAsAuto() {
        XCTAssertEqual(
            WolfActions.rulesDescription(stake: 2, pressMode: .manual, trigger: 2, isV2: true),
            "Unlimited auto presses at 2 down · $2 per bet")
    }
}
