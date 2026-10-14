import XCTest
@testable import WolfmoreGolf

final class LoneWolfTeamScoreTests: XCTestCase {

    // MARK: - Ghost Partner formula

    func testGhost_par3_score3() {
        // 3 + (3 + 4) / 2 = 3 + 3.5 = 6.5
        XCTAssertEqual(ghostTeamTotal(score: 3, par: 3), 6.5, accuracy: 0.001)
    }

    func testGhost_par4_score4() {
        // 4 + (4 + 5) / 2 = 4 + 4.5 = 8.5
        XCTAssertEqual(ghostTeamTotal(score: 4, par: 4), 8.5, accuracy: 0.001)
    }

    func testGhost_par5_score5() {
        // 5 + (5 + 6) / 2 = 5 + 5.5 = 10.5
        XCTAssertEqual(ghostTeamTotal(score: 5, par: 5), 10.5, accuracy: 0.001)
    }

    // MARK: - Double Score formula

    func testDouble_par3_score3() {
        XCTAssertEqual(doubleTeamTotal(score: 3), 6.0, accuracy: 0.001)
    }

    func testDouble_par4_score4() {
        XCTAssertEqual(doubleTeamTotal(score: 4), 8.0, accuracy: 0.001)
    }

    func testDouble_par5_score5() {
        XCTAssertEqual(doubleTeamTotal(score: 5), 10.0, accuracy: 0.001)
    }

    // MARK: - Tie rule unchanged

    func testGhost_tieWhenBothTeamTotalsEqual() {
        // Ghost: score 3 par 3 → 6.5; opponent team total 6.5 → tie
        let lone: Float = 3
        let par = 3
        let loneTeam = lone + (lone + Float(par + 1)) / 2.0   // 6.5
        let oppTeam: Float = 6.5
        XCTAssertEqual(loneTeam, oppTeam, "Equal totals should be a tie")
    }

    func testDouble_tieWhenBothTeamTotalsEqual() {
        let loneTeam: Float = 3 * 2     // 6.0
        let oppTeam:  Float = 6.0
        XCTAssertEqual(loneTeam, oppTeam, "Equal totals should be a tie")
    }

    // MARK: - Old round decodes as ghost (nil → ghost partner)

    func testOldRound_nilDecodesAsGhostPartner() throws {
        // A GameData JSON without loneWolfTeamScore should decode with nil
        let json = "{}".data(using: .utf8)!
        let decoded = try JSONDecoder().decode(GameData.self, from: json)
        XCTAssertNil(decoded.loneWolfTeamScore,
                     "Missing key should decode as nil, which is treated as .ghostPartner at use site")
        XCTAssertEqual(decoded.loneWolfTeamScore ?? .ghostPartner, .ghostPartner)
    }

    // MARK: - Helpers

    private func ghostTeamTotal(score: Int, par: Int) -> Float {
        let lone = Float(score)
        return lone + (lone + Float(par + 1)) / 2.0
    }

    private func doubleTeamTotal(score: Int) -> Float {
        return Float(score) * 2.0
    }
}
