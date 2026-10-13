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

    // MARK: - Selected player name and HC are used, not the profile owner's

    func testSelectedPlayerName_IsUsedNotProfileOwner() {
        var g = GameData()
        g.playerNames = ["Test 5", "Tryer", "Alice", "Bob"]
        g.remoteNassauLocalSlotMap = ["m1": 1]  // Tryer at slot 1

        let slot = WolfActions.remoteNassauOwnerSlot(matchId: "m1", game: g, myPlayerIndex: 0)
        XCTAssertEqual(slot, 1)
        XCTAssertEqual(g.playerNames[slot], "Tryer",
                       "Selected player is Tryer (slot 1), not the profile owner at slot 0")
    }

    func testSelectedPlayerHC_IsUsedNotProfileOwnerHC() {
        var g = GameData()
        g.playerNames = ["Test 5", "Tryer", "Alice", "Bob"]
        g.hcPlayers   = [10, 18, 5, 12]
        g.remoteNassauLocalSlotMap = ["m1": 1]  // Tryer at slot 1, HC 18

        let slot = WolfActions.remoteNassauOwnerSlot(matchId: "m1", game: g, myPlayerIndex: 0)
        XCTAssertEqual(g.hcPlayers[safe: slot], 18,
                       "Match must use Tryer's HC (18), not Test 5's (10)")
        XCTAssertNotEqual(g.hcPlayers[safe: 0], g.hcPlayers[safe: slot])
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
