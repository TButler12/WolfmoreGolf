import XCTest
@testable import WolfmoreGolf

final class NassauScorecardTests: XCTestCase {

    // MARK: - Helpers

    private func pair(net: Int, yourGross: Int = 4, oppGross: Int = 4,
                      yourStrokes: Int = 0, oppStrokes: Int = 0) -> PairedHole {
        PairedHole(hcRank: 1, hostPhysicalHole: 1,
                   hostScore: yourGross, hostNetScore: yourGross - yourStrokes, hostStrokes: yourStrokes, hostPar: 4,
                   opponentPhysicalHole: 1,
                   opponentScore: oppGross, opponentNetScore: oppGross - oppStrokes, opponentStrokes: oppStrokes, opponentPar: 4,
                   netResult: net)
    }

    private func waitingPair(yourScored: Bool) -> PairedHole {
        PairedHole(hcRank: 1, hostPhysicalHole: 1,
                   hostScore: yourScored ? 4 : nil, hostNetScore: yourScored ? 4 : nil, hostStrokes: 0, hostPar: 4,
                   opponentPhysicalHole: 1,
                   opponentScore: yourScored ? nil : 4, opponentNetScore: yourScored ? nil : 4, opponentStrokes: 0, opponentPar: 4,
                   netResult: 0)
    }

    private func mirrorPair(_ ph: PairedHole) -> PairedHole {
        PairedHole(hcRank: ph.hcRank, hostPhysicalHole: ph.opponentPhysicalHole,
                   hostScore: ph.opponentScore, hostNetScore: ph.opponentNetScore,
                   hostStrokes: ph.opponentStrokes, hostPar: ph.opponentPar,
                   opponentPhysicalHole: ph.hostPhysicalHole,
                   opponentScore: ph.hostScore, opponentNetScore: ph.hostNetScore,
                   opponentStrokes: ph.hostStrokes, opponentPar: ph.hostPar,
                   netResult: -ph.netResult)
    }

    private func noPressConfig(pairs: [PairedHole], owner: String = "Tom", opp: String = "Mike") -> ScorecardConfig {
        ScorecardConfig(ownerName: owner, opponentName: opp, ownerCourse: "", opponentCourse: "",
                        pairs: pairs, stake: 5, trigger: 2, pressMode: .off, isV2: false,
                        isSameCourse: true, posLabel: "H", title: "Test")
    }

    private func v2Config(pairs: [PairedHole], owner: String = "Tom", opp: String = "Mike") -> ScorecardConfig {
        ScorecardConfig(ownerName: owner, opponentName: opp, ownerCourse: "", opponentCourse: "",
                        pairs: pairs, stake: 5, trigger: 2, pressMode: .auto, isV2: true,
                        isSameCourse: true, posLabel: "H", title: "Test")
    }

    // MARK: - Test 1: Row count matches pairedHoles

    func testBuild_RowCountMatchesPairedHoles_FrontNine() {
        // 9 pairs → 1 header + 9 hole rows + 1 subtotal = 11 items (no presses)
        let pairs = Array(repeating: pair(net: 0), count: 9)
        let items = ScorecardBuilder.build(config: noPressConfig(pairs: pairs))
        XCTAssertEqual(items.count, 11)
        guard case .header = items[0] else { XCTFail("First item must be header"); return }
        // items 1–9 are hole rows
        for i in 1...9 {
            guard case .hole = items[i] else { XCTFail("Item \(i) must be .hole"); return }
        }
        guard case .subtotal = items[10] else { XCTFail("Last item must be subtotal"); return }
    }

    func testBuild_RowCountMatchesPairedHoles_FullEighteen() {
        // 18 pairs → 1 header + 18 hole rows + 3 subtotals (Front 9, Back 9, 18 Holes) = 22 items (no presses)
        let pairs = Array(repeating: pair(net: 0), count: 18)
        let items = ScorecardBuilder.build(config: noPressConfig(pairs: pairs))
        XCTAssertEqual(items.count, 22)
        let holeCount = items.filter { if case .hole = $0 { return true }; return false }.count
        let subtotalCount = items.filter { if case .subtotal = $0 { return true }; return false }.count
        XCTAssertEqual(holeCount, 18)
        XCTAssertEqual(subtotalCount, 3)
    }

    // MARK: - Test 2: Mirrored results (host view vs joiner view)

    func testBuild_MirroredResults_RunningNetIsOpposite() {
        // nets = [+1, -1, +1, 0, 0, 0, 0, 0, 0]
        // Host: running = [+1, 0, +1, +1, +1, +1, +1, +1, +1]
        // Joiner (mirror): running = [-1, 0, -1, -1, -1, -1, -1, -1, -1]
        let nets = [1, -1, 1, 0, 0, 0, 0, 0, 0]
        let hostPairs  = nets.map { pair(net: $0) }
        let joinPairs  = hostPairs.map { mirrorPair($0) }

        let hostItems = ScorecardBuilder.build(config: noPressConfig(pairs: hostPairs, owner: "Tom", opp: "Mike"))
        let joinItems = ScorecardBuilder.build(config: noPressConfig(pairs: joinPairs, owner: "Mike", opp: "Tom"))

        // Extract hole running nets
        var hostNets: [Int?] = []; var joinNets: [Int?] = []
        for item in hostItems { if case .hole(let hd) = item { hostNets.append(hd.runningNet) } }
        for item in joinItems { if case .hole(let hd) = item { joinNets.append(hd.runningNet) } }

        XCTAssertEqual(hostNets.count, joinNets.count)
        for (h, j) in zip(hostNets, joinNets) {
            XCTAssertEqual((h ?? 0), -(j ?? 0), "Host runningNet must equal negative of joiner runningNet")
        }
    }

    func testBuild_MirroredResults_HoleResultIsFlipped() {
        let hostPairs = [pair(net: 1), pair(net: -1), pair(net: 0)]
        let joinPairs = hostPairs.map { mirrorPair($0) }
        let hostItems = ScorecardBuilder.build(config: noPressConfig(pairs: hostPairs))
        let joinItems = ScorecardBuilder.build(config: noPressConfig(pairs: joinPairs))

        var hostResults: [Int] = []; var joinResults: [Int] = []
        for item in hostItems { if case .hole(let hd) = item { hostResults.append(hd.holeResult) } }
        for item in joinItems { if case .hole(let hd) = item { joinResults.append(hd.holeResult) } }

        for (h, j) in zip(hostResults, joinResults) {
            XCTAssertEqual(h, -j, "holeResult must be negated in mirrored view")
        }
    }

    // MARK: - Test 3: Waiting rows

    func testBuild_WaitingForOpp_WhenYouScoredOppHasnt() {
        // You scored H1, opp hasn't → waitingForName = opp name
        let holes = [waitingPair(yourScored: true), pair(net: 0)]
        let items = ScorecardBuilder.build(config: noPressConfig(pairs: holes, opp: "Mike"))
        guard case .hole(let hd) = items[1] else { XCTFail("items[1] should be hole"); return }
        XCTAssertEqual(hd.waitingForName, "Mike", "waitingForName is opponent's name when opponent hasn't scored")
        XCTAssertFalse(hd.bothScored)
        XCTAssertNil(hd.runningNet, "Incomplete hole must not contribute to running status")
    }

    func testBuild_WaitingForYou_WhenOppScoredYouHavent() {
        let holes = [waitingPair(yourScored: false), pair(net: 0)]
        let items = ScorecardBuilder.build(config: noPressConfig(pairs: holes, owner: "Tom"))
        guard case .hole(let hd) = items[1] else { XCTFail("items[1] should be hole"); return }
        XCTAssertEqual(hd.waitingForName, "Tom")
        XCTAssertNil(hd.runningNet)
    }

    func testBuild_WaitingHoleDoesNotCountTowardRunningNet() {
        // H1 = waiting, H2 = fully scored +1 → running net at H2 = +1 (H1 skipped)
        let holes = [waitingPair(yourScored: true), pair(net: 1)]
        let items = ScorecardBuilder.build(config: noPressConfig(pairs: holes))
        let holeItems = items.compactMap { if case .hole(let hd) = $0 { return hd } else { return nil } }
        XCTAssertNil(holeItems[0].runningNet, "Waiting hole has no running net")
        XCTAssertEqual(holeItems[1].runningNet, 1, "Scored hole after waiting gets correct running net")
    }

    // MARK: - Test 4: Press markers align with press list

    func testBuild_PressMarkers_AlignWithPressList() {
        // nets = [-1,-1,0,0,0,0,0,0,0] with trigger 2 → 1 press starting at H3
        let nets = [-1, -1, 0, 0, 0, 0, 0, 0, 0]
        let pairs = nets.map { pair(net: $0) }
        let config = v2Config(pairs: pairs)
        let items  = ScorecardBuilder.build(config: config)
        let presses = ScorecardBuilder.presses(config: config)

        XCTAssertEqual(presses.count, 1)
        XCTAssertEqual(presses[0].startPos, 3)

        // Find the pressStart item and check it precedes the hole for match position 3
        var pressMarkerIdx: Int? = nil
        var hole3Idx: Int? = nil
        for (i, item) in items.enumerated() {
            if case .pressStart(let n) = item, n == 1 { pressMarkerIdx = i }
            if case .hole(let hd) = item, hd.matchPos == 3 { hole3Idx = i }
        }
        XCTAssertNotNil(pressMarkerIdx, "P1 marker must appear in items")
        XCTAssertNotNil(hole3Idx, "Hole at matchPos 3 must appear in items")
        if let pm = pressMarkerIdx, let h3 = hole3Idx {
            XCTAssertEqual(pm, h3 - 1, "P1 marker must immediately precede match hole 3")
        }
    }

    func testBuild_MultiplePressMarkers_SameHoleInOrder() {
        // nets=[-1,-1,+2,...] with V2 trigger=2 → P1 at H3, P2 at H4 (from P1 going +2 at H3)
        let nets = [-1, -1, 2, 0, 0, 0, 0, 0, 0]
        let pairs = nets.map { pair(net: $0) }
        let config = v2Config(pairs: pairs)
        let items  = ScorecardBuilder.build(config: config)

        let pressStartItems = items.compactMap { item -> Int? in
            if case .pressStart(let n) = item { return n } else { return nil }
        }
        // P1 starts H3, P2 starts H4 — two separate markers
        XCTAssertEqual(pressStartItems.count, 2)
    }

    func testBuild_NoPressMarkers_WhenPressModeOff() {
        let nets = [-1, -1, 0, 0, 0, 0, 0, 0, 0]
        let pairs = nets.map { pair(net: $0) }
        let config = noPressConfig(pairs: pairs)
        let items  = ScorecardBuilder.build(config: config)
        let markers = items.filter { if case .pressStart = $0 { return true }; return false }
        XCTAssertTrue(markers.isEmpty, "No press markers when pressMode is .off")
    }
}
