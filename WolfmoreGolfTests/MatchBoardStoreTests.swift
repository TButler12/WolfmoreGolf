import XCTest
@testable import WolfmoreGolf

final class MatchBoardStoreTests: XCTestCase {

    private let testKey = "createdMatchBoards"

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: testKey)
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: testKey)
        super.tearDown()
    }

    // MARK: - Remove

    func testRemove_removesTargetBoard() {
        MatchBoardStore.save(code: "EABC001", name: "Board A")
        MatchBoardStore.save(code: "EABC002", name: "Board B")
        MatchBoardStore.remove(code: "EABC001")
        let codes = MatchBoardStore.all().map(\.code)
        XCTAssertFalse(codes.contains("EABC001"))
        XCTAssertTrue(codes.contains("EABC002"))
    }

    func testRemove_doesNotAffectOtherBoards() {
        MatchBoardStore.save(code: "EABC001", name: "Board A")
        MatchBoardStore.save(code: "EABC002", name: "Board B")
        MatchBoardStore.save(code: "EABC003", name: "Board C")
        MatchBoardStore.remove(code: "EABC002")
        let codes = MatchBoardStore.all().map(\.code)
        XCTAssertEqual(codes.count, 2)
        XCTAssertTrue(codes.contains("EABC001"))
        XCTAssertTrue(codes.contains("EABC003"))
    }

    func testRemove_noOpWhenCodeNotFound() {
        MatchBoardStore.save(code: "EABC001", name: "Board A")
        MatchBoardStore.remove(code: "ENONE00")
        XCTAssertEqual(MatchBoardStore.all().count, 1)
    }

    func testRemove_emptyStoreNocrash() {
        XCTAssertTrue(MatchBoardStore.all().isEmpty)
        MatchBoardStore.remove(code: "EABC001")  // must not crash
        XCTAssertTrue(MatchBoardStore.all().isEmpty)
    }

    // MARK: - Recent (30-day filter)

    func testRecent_excludesBoardsOlderThan30Days() {
        let old = Date().addingTimeInterval(-31 * 86_400).timeIntervalSince1970
        let new = Date().addingTimeInterval(-1 * 86_400).timeIntervalSince1970
        // Manually insert two boards with different ages
        let boards = [
            SavedMatchBoard(code: "EOLD001", name: "Old",  createdAt: old, organizerToken: nil),
            SavedMatchBoard(code: "ENEW001", name: "New",  createdAt: new, organizerToken: nil),
        ]
        if let data = try? JSONEncoder().encode(boards) {
            UserDefaults.standard.set(data, forKey: testKey)
        }
        let recent = MatchBoardStore.recent()
        let codes = recent.map(\.code)
        XCTAssertFalse(codes.contains("EOLD001"), "31-day-old board should be excluded")
        XCTAssertTrue(codes.contains("ENEW001"),  "1-day-old board should be included")
    }

    func testRecent_includesBoardExactlyAt30Days() {
        let exactly30 = Date().addingTimeInterval(-30 * 86_400 + 60).timeIntervalSince1970 // 30d ago + 1min
        let boards = [SavedMatchBoard(code: "EBORD01", name: "Edge", createdAt: exactly30, organizerToken: nil)]
        if let data = try? JSONEncoder().encode(boards) {
            UserDefaults.standard.set(data, forKey: testKey)
        }
        XCTAssertFalse(MatchBoardStore.recent().isEmpty, "Board just inside 30 days should be included")
    }

    func testRecent_emptyWhenAllBoardsOld() {
        let old = Date().addingTimeInterval(-60 * 86_400).timeIntervalSince1970
        let boards = [SavedMatchBoard(code: "EOLD002", name: "Ancient", createdAt: old, organizerToken: nil)]
        if let data = try? JSONEncoder().encode(boards) {
            UserDefaults.standard.set(data, forKey: testKey)
        }
        XCTAssertTrue(MatchBoardStore.recent().isEmpty)
    }

    // MARK: - Creator (organizerToken)

    func testSave_storesOrganizerToken() {
        MatchBoardStore.save(code: "EABC001", name: "My Board", organizerToken: "tok-abc-123")
        let board = MatchBoardStore.all().first { $0.code == "EABC001" }
        XCTAssertEqual(board?.organizerToken, "tok-abc-123")
    }

    func testSave_nilTokenForJoinedBoards() {
        MatchBoardStore.save(code: "EABC002", name: "Joined Board")
        let board = MatchBoardStore.all().first { $0.code == "EABC002" }
        XCTAssertNil(board?.organizerToken, "No token means not the creator — Delete Board should not be shown")
    }

    // MARK: - Pre-fill cleared on remove

    func testTodaysBoard_returnsNilAfterRemove() {
        MatchBoardStore.save(code: "ETODAY1", name: "Today's Board")
        XCTAssertNotNil(MatchBoardStore.todaysBoard())
        MatchBoardStore.remove(code: "ETODAY1")
        XCTAssertNil(MatchBoardStore.todaysBoard(), "Removing today's board should clear Go Live pre-fill")
    }
}

// MARK: - HiddenMatchStore tests

final class HiddenMatchStoreTests: XCTestCase {

    private let testKey = "hiddenRemoteMatchIds"

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: testKey)
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: testKey)
        super.tearDown()
    }

    func testHide_matchAppearsInHiddenIds() {
        HiddenMatchStore.hide(id: "match-uuid-1")
        XCTAssertTrue(HiddenMatchStore.hiddenIds().contains("match-uuid-1"))
    }

    func testHide_localOnly_doesNotDuplicateOnMultipleHides() {
        HiddenMatchStore.hide(id: "match-uuid-2")
        HiddenMatchStore.hide(id: "match-uuid-2")
        XCTAssertEqual(HiddenMatchStore.hiddenIds().filter { $0 == "match-uuid-2" }.count, 1)
    }

    func testHide_multipleMatchesAllHidden() {
        HiddenMatchStore.hide(id: "m1")
        HiddenMatchStore.hide(id: "m2")
        HiddenMatchStore.hide(id: "m3")
        XCTAssertEqual(HiddenMatchStore.hiddenIds().count, 3)
    }

    func testHiddenIds_emptyByDefault() {
        XCTAssertTrue(HiddenMatchStore.hiddenIds().isEmpty)
    }
}
