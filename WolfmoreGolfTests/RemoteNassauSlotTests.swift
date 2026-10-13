import XCTest
@testable import WolfmoreGolf

final class RemoteNassauSlotTests: XCTestCase {

    // MARK: - remoteNassauOwnerSlot

    func testOwnerSlot_UsesStoredSlot() {
        var g = GameData()
        g.remoteNassauLocalSlotMap = ["match1": 2]
        XCTAssertEqual(WolfActions.remoteNassauOwnerSlot(matchId: "match1", game: g, myPlayerIndex: 0), 2,
                       "Stored slot 2 should override myPlayerIndex 0")
    }

    func testOwnerSlot_FallsBackToMyPlayerIndex_WhenNoMapEntry() {
        var g = GameData()
        g.remoteNassauLocalSlotMap = ["otherMatch": 3]
        XCTAssertEqual(WolfActions.remoteNassauOwnerSlot(matchId: "match1", game: g, myPlayerIndex: 1), 1,
                       "No entry for match1 → should use myPlayerIndex")
    }

    func testOwnerSlot_FallsBackToZero_WhenNoMapAndNoPlayerIndex() {
        let g = GameData()
        XCTAssertEqual(WolfActions.remoteNassauOwnerSlot(matchId: "match1", game: g, myPlayerIndex: nil), 0,
                       "No stored slot, no myPlayerIndex → default to 0")
    }

    func testOwnerSlot_FallsBackToZero_WhenMapIsNil() {
        let g = GameData()  // remoteNassauLocalSlotMap is nil on a fresh GameData
        XCTAssertEqual(WolfActions.remoteNassauOwnerSlot(matchId: "match1", game: g, myPlayerIndex: nil), 0)
    }

    func testOwnerSlot_DifferentMatchesCanUseDifferentSlots() {
        var g = GameData()
        g.remoteNassauLocalSlotMap = ["matchA": 0, "matchB": 3]
        XCTAssertEqual(WolfActions.remoteNassauOwnerSlot(matchId: "matchA", game: g, myPlayerIndex: 1), 0)
        XCTAssertEqual(WolfActions.remoteNassauOwnerSlot(matchId: "matchB", game: g, myPlayerIndex: 1), 3)
    }

    // MARK: - Only the selected player's scores feed the match

    func testOnlySelectedPlayerScores_NotOtherSeats() {
        var g = GameData()
        g.remoteNassauLocalSlotMap = ["m1": 2]
        // Seat 2 has a score; seat 0 (myPlayerIndex) has a different score
        g.scores = Array(repeating: Array(repeating: nil, count: 18), count: 4)
        g.scores[0][0] = 4   // myPlayerIndex's score (should NOT be used)
        g.scores[2][0] = 3   // selected player's score (should be used)

        let slot = WolfActions.remoteNassauOwnerSlot(matchId: "m1", game: g, myPlayerIndex: 0)
        XCTAssertEqual(slot, 2)
        XCTAssertEqual(g.scores[slot][0], 3, "Slot 2 score should be 3")
        XCTAssertNotEqual(g.scores[0][0], g.scores[slot][0],
                          "The selected player's score must differ from seat 0 in this scenario")
    }
}
