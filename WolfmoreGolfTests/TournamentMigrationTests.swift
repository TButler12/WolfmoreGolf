import XCTest
@testable import WolfmoreGolf

final class TournamentMigrationTests: XCTestCase {

    private let localKey      = "currentGame_v1"
    private let tournamentKey = "tournamentGame_v1"
    private let migrationKey  = "tournamentToLocalMigration_v1"

    override func setUp() {
        super.setUp()
        // Reset migration flag so the function runs each time
        UserDefaults.standard.removeObject(forKey: migrationKey)
        UserDefaults.standard.removeObject(forKey: localKey)
        UserDefaults.standard.removeObject(forKey: tournamentKey)
        // Reset ResetSnapshotStore
        UserDefaults.standard.removeObject(forKey: "resetGameSnapshots_v2")
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: migrationKey)
        UserDefaults.standard.removeObject(forKey: localKey)
        UserDefaults.standard.removeObject(forKey: tournamentKey)
        UserDefaults.standard.removeObject(forKey: "resetGameSnapshots_v2")
        super.tearDown()
    }

    // MARK: - Case 1: local slot empty -> move tournament game into local slot

    func testMigration_localEmpty_movesTournamentToLocal() throws {
        // Arrange: only tournament slot has data
        var tournamentGame = GameData()
        tournamentGame.tournamentCode = "ABCDEF"
        tournamentGame.tournamentName = "Spring Classic"
        let data = try JSONEncoder().encode(tournamentGame)
        UserDefaults.standard.set(data, forKey: tournamentKey)

        // Act
        GameManager.shared.performTournamentToLocalMigrationIfNeeded()

        // Assert: local slot now has the tournament game
        let localData = UserDefaults.standard.data(forKey: localKey)
        XCTAssertNotNil(localData, "Local slot should have been populated")
        let decoded = try JSONDecoder().decode(GameData.self, from: localData!)
        XCTAssertEqual(decoded.tournamentCode, "ABCDEF")
        XCTAssertEqual(decoded.tournamentName, "Spring Classic")

        // Tournament slot should be cleared
        XCTAssertNil(UserDefaults.standard.data(forKey: tournamentKey),
                     "Tournament slot should be cleared after migration")

        // Nothing saved to Restore
        XCTAssertTrue(ResetSnapshotStore.shared.allEntries().isEmpty,
                      "Restore store should be empty when local was empty")
    }

    // MARK: - Case 2a: local has round, tournament has committed holes -> save tournament to Restore

    func testMigration_localHasRound_tournamentHasProgress_savesToRestore() throws {
        var localGame = GameData()
        localGame.tournamentCode = nil
        localGame.holeCommitted = Array(repeating: false, count: 18)
        let localData = try JSONEncoder().encode(localGame)
        UserDefaults.standard.set(localData, forKey: localKey)

        var tournamentGame = GameData()
        tournamentGame.tournamentCode = "XYZXYZ"
        tournamentGame.tournamentName = "Fall Cup"
        var committed = Array(repeating: false, count: 18)
        committed[0] = true
        tournamentGame.holeCommitted = committed
        let tData = try JSONEncoder().encode(tournamentGame)
        UserDefaults.standard.set(tData, forKey: tournamentKey)

        GameManager.shared.performTournamentToLocalMigrationIfNeeded()

        // Local slot unchanged
        let newLocalData = UserDefaults.standard.data(forKey: localKey)
        XCTAssertNotNil(newLocalData)
        let decodedLocal = try JSONDecoder().decode(GameData.self, from: newLocalData!)
        XCTAssertNil(decodedLocal.tournamentCode, "Local game should be unchanged")

        // Tournament game saved to Restore
        let restoreEntries = ResetSnapshotStore.shared.allEntries()
        XCTAssertEqual(restoreEntries.count, 1, "Tournament game with progress should be saved to Restore")
        XCTAssertEqual(restoreEntries.first?.gameData.tournamentCode, "XYZXYZ")

        XCTAssertNil(UserDefaults.standard.data(forKey: tournamentKey))
    }

    // MARK: - Case 2b: local has round, tournament has NO committed holes -> discard silently

    func testMigration_localHasRound_tournamentNoProgress_discardsSilently() throws {
        var localGame = GameData()
        localGame.tournamentCode = nil
        localGame.holeCommitted = Array(repeating: false, count: 18)
        let localData = try JSONEncoder().encode(localGame)
        UserDefaults.standard.set(localData, forKey: localKey)

        var tournamentGame = GameData()
        tournamentGame.tournamentCode = "STALE1"
        tournamentGame.tournamentName = "Stale Tournament"
        tournamentGame.holeCommitted = Array(repeating: false, count: 18)
        let tData = try JSONEncoder().encode(tournamentGame)
        UserDefaults.standard.set(tData, forKey: tournamentKey)

        GameManager.shared.performTournamentToLocalMigrationIfNeeded()

        // Local slot unchanged
        let newLocalData = UserDefaults.standard.data(forKey: localKey)
        XCTAssertNotNil(newLocalData)

        // Nothing saved to Restore (no spurious banner)
        XCTAssertTrue(ResetSnapshotStore.shared.allEntries().isEmpty,
                      "Stale tournament with no progress should not create a Restore entry")

        // Tournament slot cleared
        XCTAssertNil(UserDefaults.standard.data(forKey: tournamentKey))
    }

    // MARK: - Idempotent: running twice doesn't double-migrate

    func testMigration_idempotent() throws {
        var tournamentGame = GameData()
        tournamentGame.tournamentCode = "TESTTT"
        let data = try JSONEncoder().encode(tournamentGame)
        UserDefaults.standard.set(data, forKey: tournamentKey)

        GameManager.shared.performTournamentToLocalMigrationIfNeeded()
        GameManager.shared.performTournamentToLocalMigrationIfNeeded()  // second call should be no-op

        let localData = UserDefaults.standard.data(forKey: localKey)
        XCTAssertNotNil(localData)
        // Only one copy should exist
        XCTAssertNil(UserDefaults.standard.data(forKey: tournamentKey))
    }
}
