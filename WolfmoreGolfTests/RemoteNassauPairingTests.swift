import XCTest
@testable import WolfmoreGolf

final class RemoteNassauPairingTests: XCTestCase {

    // Two 9-hole HC arrays where HC ranks differ per player.
    // Player A front: HC order is holes 3,1,7,5,2,6,8,4,0 (HC values 1..9)
    //   hcs = [9,3,1,7,5,2,6,8,4] meaning hole 0→HC9, hole 1→HC3, hole 2→HC1, ...
    // Player B front: HC order is holes 0,4,2,6,1,8,3,7,5 (HC values 1..9)
    //   hcs = [1,5,3,7,9,2,4,8,6]
    // So rank-1 (hardest) pairs: A-hole 2 (HC1) vs B-hole 0 (HC1)

    private func makeRound(name: String, courseId: String, hcs: [Int], scores: [Int?]) -> SharedRound {
        let pars = Array(repeating: 4, count: STANDARD_HOLES)
        return SharedRound(
            playerName:     name,
            courseName:     name + "Course",
            courseId:       courseId,
            pars:           pars,
            hcs:            hcs,
            scores:         scores,
            fairways:       Array(repeating: nil, count: STANDARD_HOLES),
            girs:           Array(repeating: nil, count: STANDARD_HOLES),
            putts:          Array(repeating: nil, count: STANDARD_HOLES),
            courseHandicap: 0
        )
    }

    // MARK: - Test 1: Different courses — slots are always HC-rank ordered

    func testDifferentCoursesFixedSlotOrder() {
        // Front nine HC arrays (indices 0-8):
        // A: hole 0→HC9, hole 1→HC3, hole 2→HC1, hole 3→HC7, hole 4→HC5,
        //    hole 5→HC2, hole 6→HC6, hole 7→HC8, hole 8→HC4
        let hcsA = [9, 3, 1, 7, 5, 2, 6, 8, 4,  10, 12, 14, 16, 11, 13, 15, 17, 18]
        // B: hole 0→HC1, hole 1→HC5, hole 2→HC3, hole 3→HC7, hole 4→HC9,
        //    hole 5→HC2, hole 6→HC4, hole 7→HC8, hole 8→HC6
        let hcsB = [1, 5, 3, 7, 9, 2, 4, 8, 6,  10, 12, 14, 16, 11, 13, 15, 17, 18]

        // All holes played, equal scores (ties on every hole)
        let scoresA: [Int?] = Array(repeating: 4, count: STANDARD_HOLES)
        let scoresB: [Int?] = Array(repeating: 4, count: STANDARD_HOLES)

        let a = makeRound(name: "Alice", courseId: "course-A", hcs: hcsA, scores: scoresA)
        let b = makeRound(name: "Bob",   courseId: "course-B", hcs: hcsB, scores: scoresB)

        let slots = RemoteNassauPairing.buildSlots(a: a, b: b, sameCourse: false)
        XCTAssertEqual(slots.count, 18)

        // Front rank 1 (hardest): A-hole 2 (HC1) vs B-hole 0 (HC1)
        XCTAssertEqual(slots[0].hcRank, 1)
        XCTAssertEqual(slots[0].indexA, 2, "A front rank-1 should be hole 2 (HC1)")
        XCTAssertEqual(slots[0].indexB, 0, "B front rank-1 should be hole 0 (HC1)")

        // Front rank 2: A-hole 5 (HC2) vs B-hole 5 (HC2)
        XCTAssertEqual(slots[1].hcRank, 2)
        XCTAssertEqual(slots[1].indexA, 5, "A front rank-2 should be hole 5 (HC2)")
        XCTAssertEqual(slots[1].indexB, 5, "B front rank-2 should be hole 5 (HC2)")

        // Scorer with sameCourse: false should give same result
        let result = RemoteNassauScorer.score(playerA: a, playerB: b, stakePerBet: 10, sameCourse: false)
        XCTAssertEqual(result.holeResults.count, 18)
        XCTAssertEqual(result.holeResults[0].holeNumberA, slots[0].indexA + 1)
        XCTAssertEqual(result.holeResults[0].holeNumberB, slots[0].indexB + 1)

        // All ties → all scores 0
        XCTAssertEqual(result.frontScore, 0)
        XCTAssertEqual(result.backScore, 0)
        XCTAssertEqual(result.overallScore, 0)
    }

    // MARK: - Test 2: Stroke allocation — CH15 vs CH10 gives 5 strokes on HC≤5 holes

    func testStrokeAllocation() {
        // Standard HC 1-18 (each hole gets its HC index+1)
        let hcs = Array(1...STANDARD_HOLES)
        let pars = Array(repeating: 4, count: STANDARD_HOLES)

        let aScores: [Int?] = Array(repeating: 5, count: STANDARD_HOLES)  // bogey every hole
        let bScores: [Int?] = Array(repeating: 5, count: STANDARD_HOLES)

        let a = SharedRound(
            playerName: "Alice", courseName: "Course", courseId: "course-X",
            pars: pars, hcs: hcs,
            scores: aScores, fairways: Array(repeating: nil, count: STANDARD_HOLES),
            girs: Array(repeating: nil, count: STANDARD_HOLES),
            putts: Array(repeating: nil, count: STANDARD_HOLES),
            courseHandicap: 15
        )
        let b = SharedRound(
            playerName: "Bob", courseName: "Course", courseId: "course-X",
            pars: pars, hcs: hcs,
            scores: bScores, fairways: Array(repeating: nil, count: STANDARD_HOLES),
            girs: Array(repeating: nil, count: STANDARD_HOLES),
            putts: Array(repeating: nil, count: STANDARD_HOLES),
            courseHandicap: 10
        )

        // A gets 5 strokes (CH15 - CH10 = 5), B gets 0
        let slots = RemoteNassauPairing.buildSlots(a: a, b: b, sameCourse: true)

        // HC1 hole (index 0, strokeIndex=1): A gets a pop (1 ≤ 5), B gets 0
        let hc1Slot = slots.first { $0.indexA == 0 }!
        XCTAssertEqual(hc1Slot.strokesA, 1, "A should get 1 stroke on HC1 hole")
        XCTAssertEqual(hc1Slot.strokesB, 0)

        // HC5 hole (index 4, strokeIndex=5): A gets a pop (5 ≤ 5)
        let hc5Slot = slots.first { $0.indexA == 4 }!
        XCTAssertEqual(hc5Slot.strokesA, 1, "A should get 1 stroke on HC5 hole")

        // HC6 hole (index 5, strokeIndex=6): A gets 0 (6 > 5)
        let hc6Slot = slots.first { $0.indexA == 5 }!
        XCTAssertEqual(hc6Slot.strokesA, 0, "A should NOT get a stroke on HC6 hole")

        // Total strokes A receives = 5 (holes with HC 1-5)
        let totalStrokesA = slots.reduce(0) { $0 + $1.strokesA }
        XCTAssertEqual(totalStrokesA, 5)
        let totalStrokesB = slots.reduce(0) { $0 + $1.strokesB }
        XCTAssertEqual(totalStrokesB, 0)
    }

    // MARK: - Test 3: Partial round — slot order stays fixed as holes are entered

    func testPartialRoundSlotsAreStable() {
        // Different courses. A plays holes out of order; B plays a different subset.
        let hcsA = [3, 7, 1, 9, 5, 2, 8, 6, 4,  10, 12, 14, 16, 11, 13, 15, 17, 18]
        let hcsB = [1, 9, 5, 7, 3, 6, 2, 8, 4,  10, 12, 14, 16, 11, 13, 15, 17, 18]

        let noScores: [Int?] = Array(repeating: nil, count: STANDARD_HOLES)

        // Round with no scores yet
        let a0 = makeRound(name: "Alice", courseId: "A", hcs: hcsA, scores: noScores)
        let b0 = makeRound(name: "Bob",   courseId: "B", hcs: hcsB, scores: noScores)
        let slotsEmpty = RemoteNassauPairing.buildSlots(a: a0, b: b0, sameCourse: false)

        // A plays hole 2 (HC1 for A), B plays hole 0 (HC1 for B) — rank-1 slot should pair them
        var aScores = noScores
        var bScores = noScores
        aScores[2] = 5  // A's hardest hole
        bScores[0] = 4  // B's hardest hole

        let a1 = makeRound(name: "Alice", courseId: "A", hcs: hcsA, scores: aScores)
        let b1 = makeRound(name: "Bob",   courseId: "B", hcs: hcsB, scores: bScores)
        let slots1 = RemoteNassauPairing.buildSlots(a: a1, b: b1, sameCourse: false)

        // A plays hole 5 (HC2 for A), B plays hole 6 (HC2 for B)
        aScores[5] = 3
        bScores[6] = 4

        let a2 = makeRound(name: "Alice", courseId: "A", hcs: hcsA, scores: aScores)
        let b2 = makeRound(name: "Bob",   courseId: "B", hcs: hcsB, scores: bScores)
        let slots2 = RemoteNassauPairing.buildSlots(a: a2, b: b2, sameCourse: false)

        // Slot ordering must be identical across all three snapshots
        for rank in 0..<9 {
            XCTAssertEqual(slotsEmpty[rank].indexA, slots1[rank].indexA,
                           "Front slot \(rank) indexA must not shift when holes are added")
            XCTAssertEqual(slotsEmpty[rank].indexB, slots1[rank].indexB,
                           "Front slot \(rank) indexB must not shift when holes are added")
            XCTAssertEqual(slots1[rank].indexA, slots2[rank].indexA,
                           "Front slot \(rank) indexA must not shift on second add")
            XCTAssertEqual(slots1[rank].indexB, slots2[rank].indexB,
                           "Front slot \(rank) indexB must not shift on second add")
        }

        // Rank-1 slot: A-hole 2 vs B-hole 0
        XCTAssertEqual(slots2[0].indexA, 2, "rank-1 should always point to A's HC1 hole")
        XCTAssertEqual(slots2[0].indexB, 0, "rank-1 should always point to B's HC1 hole")

        // Winner for rank-1 should be playerB (B scored 4, A scored 5, same pars)
        XCTAssertEqual(slots2[0].winner, .playerB)

        // Rank-2 slot: A-hole 5 vs B-hole 6 — must still be rank-2 after adding rank-1
        XCTAssertEqual(slots2[1].indexA, 5)
        XCTAssertEqual(slots2[1].indexB, 6)

        // Winner for rank-2: A=3, B=4, same pars → playerA wins
        XCTAssertEqual(slots2[1].winner, .playerA)

        // Rank-3 slot must still be unplayed (noResult)
        XCTAssertEqual(slots2[2].winner, .noResult)
    }
}
