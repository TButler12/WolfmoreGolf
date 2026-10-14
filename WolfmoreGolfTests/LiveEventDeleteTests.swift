import XCTest
@testable import WolfmoreGolf

// Integration test — hits the real Supabase project.
// Skipped by default. Set RUN_LIVE_TESTS=1 in the scheme's environment variables to run.
final class LiveEventDeleteTests: XCTestCase {

    override func setUpWithError() throws {
        try XCTSkipUnless(
            ProcessInfo.processInfo.environment["RUN_LIVE_TESTS"] == "1",
            "Skipping live server tests — set RUN_LIVE_TESTS=1 to run"
        )
    }

    func testDeleteForEveryone_creatorTokenDeletesBoard() async throws {
        // 1. Create a real board on the server
        let code   = "T44\(Int.random(in: 1000...9999))"   // unique enough for a test run
        let result = try await SupabaseService.shared.createLiveEvent(name: "test 44", code: code)
        let token  = result.organizerToken

        XCTAssertFalse(result.eventCode.isEmpty, "Server should return a board code")
        XCTAssertFalse(token.isEmpty,            "Server should return an organizer token")

        // 2. Confirm it exists
        let fetched = try await SupabaseService.shared.fetchLiveEvent(code: result.eventCode)
        XCTAssertEqual(fetched.name, "test 44")

        // 3. Delete via the RPC (the same call the UI makes)
        try await SupabaseService.shared.deleteLiveEvent(code: result.eventCode, organizerToken: token)

        // 4. Board must be gone — fetchLiveEvent should throw
        do {
            _ = try await SupabaseService.shared.fetchLiveEvent(code: result.eventCode)
            XCTFail("fetchLiveEvent should throw after delete")
        } catch {
            // Expected: "JSON value not found" / no rows returned
        }
    }

    func testDeleteForEveryone_wrongTokenIsRejected() async throws {
        let code   = "T44W\(Int.random(in: 1000...9999))"
        let result = try await SupabaseService.shared.createLiveEvent(name: "test 44 wrong", code: code)

        let wrongToken = UUID().uuidString   // not the real organizer token

        do {
            try await SupabaseService.shared.deleteLiveEvent(code: result.eventCode, organizerToken: wrongToken)
            XCTFail("Should have thrown with wrong token")
        } catch {
            // Expected: "Invalid board code or organizer token."
            XCTAssertTrue(
                error.localizedDescription.contains("Invalid") || error.localizedDescription.contains("invalid"),
                "Error should mention invalid token, got: \(error.localizedDescription)"
            )
        }

        // Cleanup: delete with correct token so we don't leave test data behind
        try? await SupabaseService.shared.deleteLiveEvent(
            code: result.eventCode, organizerToken: result.organizerToken)
    }
}
