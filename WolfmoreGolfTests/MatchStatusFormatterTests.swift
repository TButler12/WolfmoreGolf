import XCTest
@testable import WolfmoreGolf

final class MatchStatusFormatterTests: XCTestCase {

    private func line(diff: Int, played: Int, total: Int = 18,
                      a: String = "McTommy", b: String = "Pat") -> MatchStatusFormatter.MatchScoreLine {
        MatchStatusFormatter.MatchScoreLine(
            diff: diff, played: played, remaining: total - played,
            aLabel: a, bLabel: b)
    }

    // MARK: - singleMatchStatus

    func testSingle_AllSquare() {
        XCTAssertEqual(
            MatchStatusFormatter.singleMatchStatus(line(diff: 0, played: 2)),
            "All Square · thru 2")
    }

    func testSingle_ALeads() {
        XCTAssertEqual(
            MatchStatusFormatter.singleMatchStatus(line(diff: 2, played: 2)),
            "McTommy 2 UP vs Pat · thru 2")
    }

    func testSingle_BLeads() {
        XCTAssertEqual(
            MatchStatusFormatter.singleMatchStatus(line(diff: -1, played: 3)),
            "Pat 1 UP vs McTommy · thru 3")
    }

    func testSingle_ADormie() {
        // 2 up with 2 to play
        XCTAssertEqual(
            MatchStatusFormatter.singleMatchStatus(line(diff: 2, played: 16)),
            "McTommy Dormie")
    }

    func testSingle_BDormie() {
        XCTAssertEqual(
            MatchStatusFormatter.singleMatchStatus(line(diff: -3, played: 15)),
            "Pat Dormie")
    }

    func testSingle_AClinch_WithHolesLeft() {
        // 4 up with 3 to play → won 4&3
        XCTAssertEqual(
            MatchStatusFormatter.singleMatchStatus(line(diff: 4, played: 15)),
            "McTommy won 4&3 · Final")
    }

    func testSingle_BClinch_WithHolesLeft() {
        XCTAssertEqual(
            MatchStatusFormatter.singleMatchStatus(line(diff: -3, played: 16)),
            "Pat won 3&2 · Final")
    }

    func testSingle_Halved() {
        XCTAssertEqual(
            MatchStatusFormatter.singleMatchStatus(line(diff: 0, played: 18)),
            "Halved · Final")
    }

    func testSingle_AWon_19thHole() {
        // All 18 played, A up by 1 → won on 18
        XCTAssertEqual(
            MatchStatusFormatter.singleMatchStatus(line(diff: 1, played: 18)),
            "McTommy won 1 · Final")
    }

    func testSingle_BWon_19thHole() {
        XCTAssertEqual(
            MatchStatusFormatter.singleMatchStatus(line(diff: -2, played: 18)),
            "Pat won 2 · Final")
    }

    // MARK: - dualMatchStatus

    func testDual_BothLeading() {
        let m1 = line(diff: 2, played: 2, a: "McTommy", b: "Pat")
        let m2 = line(diff: 2, played: 2, a: "Ray",     b: "Doug")
        XCTAssertEqual(
            MatchStatusFormatter.dualMatchStatus(m1: m1, m2: m2),
            "McTommy 2 UP vs Pat · Ray 2 UP vs Doug · thru 2")
    }

    func testDual_OneAllSquare() {
        let m1 = line(diff: 1, played: 4, a: "McTommy", b: "Pat")
        let m2 = line(diff: 0, played: 4, a: "Ray",     b: "Doug")
        XCTAssertEqual(
            MatchStatusFormatter.dualMatchStatus(m1: m1, m2: m2),
            "McTommy 1 UP vs Pat · All Square · thru 4")
    }

    func testDual_BothFinal_BothWon() {
        // McTommy wins 4&3; Doug wins 4&3 — both clinched on hole 15
        let m1 = line(diff: 4, played: 15, a: "McTommy", b: "Pat")
        let m2 = line(diff: -4, played: 15, a: "Ray",    b: "Doug")
        XCTAssertEqual(
            MatchStatusFormatter.dualMatchStatus(m1: m1, m2: m2),
            "McTommy won 4&3 · Doug won 4&3 · Final")
    }

    func testDual_BothHalved() {
        let m1 = line(diff: 0, played: 18, a: "McTommy", b: "Pat")
        let m2 = line(diff: 0, played: 18, a: "Ray",     b: "Doug")
        XCTAssertEqual(
            MatchStatusFormatter.dualMatchStatus(m1: m1, m2: m2),
            "Halved · Halved · Final")
    }

    func testDual_GoshScenario_Hole2() {
        // gosh round: McTommy 2↑, Ray 2↑ after hole 2
        let m1 = line(diff: 2, played: 2, a: "McTommy", b: "Pat")
        let m2 = line(diff: 2, played: 2, a: "Ray",     b: "Doug")
        XCTAssertEqual(
            MatchStatusFormatter.dualMatchStatus(m1: m1, m2: m2),
            "McTommy 2 UP vs Pat · Ray 2 UP vs Doug · thru 2")
    }
}
