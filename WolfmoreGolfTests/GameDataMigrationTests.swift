import XCTest
@testable import WolfmoreGolf

/// Regression tests for the 3.1.5 → 3.2.1 migration bug.
///
/// Root cause: GameData uses Swift's synthesized Decodable, which treats every non-optional
/// stored property as a required JSON key — ignoring struct-body default values.
/// Any 3.1.5 save lacking "holeReversed" throws DecodingError.keyNotFound, causing the app
/// to fall back to startNewGame() (empty round, course reset to "WolfMore").
///
/// Each test below:
///   1. Builds a current GameData, encodes it, then strips the new field(s) to simulate a 3.1.5 save.
///   2. Asserts the raw data fails to decode WITHOUT migration (proving the bug exists).
///   3. Asserts GameData.migrate() + decode succeeds WITH the original field values intact.
final class GameDataMigrationTests: XCTestCase {

    // MARK: - Helpers

    /// Strip named keys from encoded GameData JSON to simulate an older save.
    private func strip(_ keys: [String], from data: Data) throws -> Data {
        var json = try XCTUnwrap(try? JSONSerialization.jsonObject(with: data) as? [String: Any])
        keys.forEach { json.removeValue(forKey: $0) }
        return try JSONSerialization.data(withJSONObject: json)
    }

    private let biltmorePars = Array(repeating: 4, count: STANDARD_HOLES)
    private let biltmoreHCs  = Array(1...STANDARD_HOLES)

    // MARK: - currentGame_v1 / tournamentGame_v1

    func testMigrate_currentGame_roundAndCourseIntact() throws {
        // Build a 3.2.0-era save then strip holeReversed to simulate 3.1.5.
        var g = GameData()
        g.course = Course(name: "Biltmore", pars: biltmorePars, holeHandicaps: biltmoreHCs)
        g.scores[0][0] = 4
        g.scores[0][1] = 3
        g.holeCommitted = { var a = Array(repeating: false, count: STANDARD_HOLES); a[0] = true; return a }()

        let encoded  = try JSONEncoder().encode(g)
        let legacy   = try strip(["holeReversed"], from: encoded)

        // Without migration: should fail.
        XCTAssertNil(try? JSONDecoder().decode(GameData.self, from: legacy),
                     "Legacy save missing holeReversed must not decode without migration")

        // With migration: round and course must survive intact.
        let decoded = try JSONDecoder().decode(GameData.self, from: GameData.migrate(legacy))
        XCTAssertEqual(decoded.course.name, "Biltmore")
        XCTAssertEqual(decoded.scores[0][0], 4)
        XCTAssertEqual(decoded.scores[0][1], 3)
        XCTAssertTrue(decoded.holeCommitted[0])
        XCTAssertEqual(decoded.holeReversed, Array(repeating: false, count: STANDARD_HOLES),
                       "Injected holeReversed must default to all-false")
    }

    func testMigrate_tournamentGame_codeAndCourseIntact() throws {
        var g = GameData()
        g.course          = Course(name: "Augusta National", pars: biltmorePars, holeHandicaps: biltmoreHCs)
        g.tournamentCode  = "SPRING"
        g.tournamentName  = "Spring Classic"
        g.scores[0][4]    = 5

        let encoded = try JSONEncoder().encode(g)
        let legacy  = try strip(["holeReversed"], from: encoded)

        XCTAssertNil(try? JSONDecoder().decode(GameData.self, from: legacy),
                     "Legacy tournament save must not decode without migration")

        let decoded = try JSONDecoder().decode(GameData.self, from: GameData.migrate(legacy))
        XCTAssertEqual(decoded.course.name, "Augusta National")
        XCTAssertEqual(decoded.tournamentCode, "SPRING")
        XCTAssertEqual(decoded.tournamentName, "Spring Classic")
        XCTAssertEqual(decoded.scores[0][4], 5)
        XCTAssertEqual(decoded.holeReversed, Array(repeating: false, count: STANDARD_HOLES))
    }

    // MARK: - resetGameSnapshots_v2

    func testMigrate_snapshotStore_entriesSurvive() throws {
        // Build two 3.1.5-era snapshot entries.
        var g1 = GameData()
        g1.course      = Course(name: "Biltmore", pars: biltmorePars, holeHandicaps: biltmoreHCs)
        g1.scores[0][0] = 4

        var g2 = GameData()
        g2.course        = Course(name: "Pebble Beach", pars: biltmorePars, holeHandicaps: biltmoreHCs)
        g2.tournamentCode = "PEBBLE"

        // Encode entries array, strip holeReversed from each GameData.
        typealias EntryProxy = [String: Any]
        func makeEntry(_ game: GameData) throws -> EntryProxy {
            let gData = try JSONEncoder().encode(game)
            var gJson = try XCTUnwrap(try? JSONSerialization.jsonObject(with: gData) as? [String: Any])
            gJson.removeValue(forKey: "holeReversed")
            return [
                "id"       : UUID().uuidString,
                "gameData" : gJson,
                "savedAt"  : Date().timeIntervalSinceReferenceDate,
            ]
        }

        let arr     = try [makeEntry(g1), makeEntry(g2)]
        let rawData = try JSONSerialization.data(withJSONObject: arr)

        // Store the legacy snapshot bytes and verify ResetSnapshotStore recovers them.
        let key = "resetGameSnapshots_v2"
        let rescueKey = key + "_rescue"
        UserDefaults.standard.removeObject(forKey: key)
        UserDefaults.standard.removeObject(forKey: rescueKey)
        UserDefaults.standard.set(rawData, forKey: key)

        // Direct decode should fail (no migration applied yet).
        XCTAssertNil(try? JSONDecoder().decode([ResetSnapshotStore.Entry].self, from: rawData),
                     "Raw legacy snapshot array must not decode without migration")

        // ResetSnapshotStore.allEntries() must recover both entries via its slow-path migration.
        let entries = ResetSnapshotStore.shared.allEntries()
        XCTAssertEqual(entries.count, 2, "Both legacy entries must be recovered after migration")
        XCTAssertEqual(entries[0].gameData.course.name, "Biltmore")
        XCTAssertEqual(entries[0].gameData.scores[0][0], 4)
        XCTAssertEqual(entries[1].gameData.course.name, "Pebble Beach")
        XCTAssertEqual(entries[1].gameData.tournamentCode, "PEBBLE")

        // No rescue needed when migration succeeds — rescue key must stay absent.
        XCTAssertNil(UserDefaults.standard.data(forKey: rescueKey),
                     "Rescue key must not be written when migration successfully recovers entries")

        // Cleanup
        UserDefaults.standard.removeObject(forKey: key)
        UserDefaults.standard.removeObject(forKey: rescueKey)
    }

    // MARK: - Idempotency

    func testMigrate_alreadyMigratedData_isUnchanged() throws {
        // A current-era save already has holeReversed — migrate() must return identical bytes.
        var g = GameData()
        g.holeReversed[3] = true
        let data    = try JSONEncoder().encode(g)
        let patched = GameData.migrate(data)

        // Decode both; holeReversed[3] must still be true.
        let original = try JSONDecoder().decode(GameData.self, from: data)
        let migrated = try JSONDecoder().decode(GameData.self, from: patched)
        XCTAssertEqual(migrated.holeReversed, original.holeReversed,
                       "migrate() must not modify holeReversed when it already exists")
        XCTAssertTrue(migrated.holeReversed[3])
    }

    // MARK: - Rescue key

    func testLoadLastOpened_rescueKeyWrittenOnUnrecoverableData() {
        let localKey  = "currentGame_v1"
        let rescueKey = localKey + "_rescue"
        UserDefaults.standard.removeObject(forKey: localKey)
        UserDefaults.standard.removeObject(forKey: rescueKey)

        // Store garbage that cannot be decoded even after migration.
        let garbage = "not json at all".data(using: .utf8)!
        UserDefaults.standard.set(garbage, forKey: localKey)

        let loaded = GameManager.shared.loadLastOpened(notify: false)
        XCTAssertFalse(loaded, "Must return false for undecodable data")
        XCTAssertNotNil(UserDefaults.standard.data(forKey: rescueKey),
                        "Rescue key must be written before startNewGame() can overwrite the slot")
        XCTAssertEqual(UserDefaults.standard.data(forKey: rescueKey), garbage,
                       "Rescue key must contain the original raw bytes")

        // Cleanup
        UserDefaults.standard.removeObject(forKey: localKey)
        UserDefaults.standard.removeObject(forKey: rescueKey)
    }
}
