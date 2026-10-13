import XCTest
@testable import WolfmoreGolf

final class SpectatorScoringTests: XCTestCase {

    // MARK: - Helpers

    /// Build a WolfHoleResult using JSON so we don't need a memberwise init.
    private func makeResult(
        hole: Int,
        decision: String? = nil,
        wolfSlot: Int? = nil,
        partnerSlot: Int? = nil,
        scores: [Int]? = nil,
        mpSeats: String? = nil
    ) -> WolfHoleResult {
        var d: [String: Any] = ["id": "t-\(hole)", "session_id": "sess", "hole": hole]
        if let v = decision    { d["decision"]     = v }
        if let v = wolfSlot    { d["wolf_slot"]    = v }
        if let v = partnerSlot { d["partner_slot"] = v }
        if let v = scores      { d["scores"]       = v }
        if let v = mpSeats     { d["mp_seats"]     = v }
        let data = try! JSONSerialization.data(withJSONObject: d)
        return try! JSONDecoder().decode(WolfHoleResult.self, from: data)
    }

    // MARK: - Format detection

    func testDetect_Fourball() {
        // Fourball: decision="matchplay" AND partnerSlot set
        let results = [makeResult(hole: 1, decision: "matchplay", wolfSlot: 0, partnerSlot: 1)]
        let fmt = SpectatorScoring.detect(results: results)
        XCTAssertFalse(fmt.isBestBall)
        XCTAssertTrue(fmt.isFourball)
        XCTAssertTrue(fmt.isTeamMatch)
    }

    func testDetect_Singles() {
        // Singles match play: decision="matchplay", no partnerSlot
        let results = [makeResult(hole: 1, decision: "matchplay", wolfSlot: 0)]
        let fmt = SpectatorScoring.detect(results: results)
        XCTAssertFalse(fmt.isBestBall)
        XCTAssertFalse(fmt.isFourball, "Singles must not be detected as Fourball")
        XCTAssertFalse(fmt.isTeamMatch)
    }

    func testDetect_BestBall() {
        // Best Ball: decision="bestball" AND partnerSlot set
        let results = [makeResult(hole: 1, decision: "bestball", wolfSlot: 0, partnerSlot: 1)]
        let fmt = SpectatorScoring.detect(results: results)
        XCTAssertTrue(fmt.isBestBall)
        XCTAssertFalse(fmt.isFourball, "BestBall must not also flag isFourball")
        XCTAssertTrue(fmt.isTeamMatch)
    }

    func testDetect_WolfWithPartner_NotFourball() {
        // Wolf picking a partner: decision=nil, partnerSlot set — NOT fourball
        let results = [makeResult(hole: 1, wolfSlot: 0, partnerSlot: 1)]
        let fmt = SpectatorScoring.detect(results: results)
        XCTAssertFalse(fmt.isBestBall)
        XCTAssertFalse(fmt.isFourball, "Wolf-with-partner must not be detected as Fourball")
        XCTAssertFalse(fmt.isTeamMatch)
    }

    func testDetect_EmptyResults() {
        let fmt = SpectatorScoring.detect(results: [])
        XCTAssertFalse(fmt.isBestBall)
        XCTAssertFalse(fmt.isFourball)
        XCTAssertFalse(fmt.isTeamMatch)
    }

    func testDetect_FourballAcrossMultipleHoles() {
        // All holes have consistent Fourball signals
        let results = (1...3).map { makeResult(hole: $0, decision: "matchplay", wolfSlot: 0, partnerSlot: 1) }
        let fmt = SpectatorScoring.detect(results: results)
        XCTAssertTrue(fmt.isFourball)
        XCTAssertTrue(fmt.isTeamMatch)
    }

    func testDetect_Fourball_WhenOnlyLaterHoleHasPartnerSlot() {
        // Hole 1 was written without partnerSlot (e.g. data not yet propagated at 9:41),
        // hole 2 has partnerSlot set (data available by 9:42). Must detect as Fourball
        // on the next refresh so the spectator shows the correct current format.
        let results = [
            makeResult(hole: 1, decision: "matchplay", wolfSlot: 0),               // no partnerSlot
            makeResult(hole: 2, decision: "matchplay", wolfSlot: 0, partnerSlot: 1),
        ]
        let fmt = SpectatorScoring.detect(results: results)
        XCTAssertTrue(fmt.isFourball, "Any hole with partnerSlot should flip detection to Fourball")
        XCTAssertFalse(fmt.isBestBall)
        XCTAssertTrue(fmt.isTeamMatch)
    }

    func testDetect_ReadsCurrentData_SinglesThenFourball() {
        // Simulates a session that started appearing as Singles (no partnerSlot anywhere)
        // and later appeared as Fourball once partnerSlot propagated.
        let singlesSnapshot = [makeResult(hole: 1, decision: "matchplay", wolfSlot: 0)]
        XCTAssertFalse(SpectatorScoring.detect(results: singlesSnapshot).isFourball,
                       "Without partnerSlot, should detect Singles")

        let fourballSnapshot = [makeResult(hole: 1, decision: "matchplay", wolfSlot: 0, partnerSlot: 1)]
        XCTAssertTrue(SpectatorScoring.detect(results: fourballSnapshot).isFourball,
                      "With partnerSlot present, next refresh should detect Fourball")
    }

    // MARK: - Team best-net sums

    // Scenario setup: 4 players, all par-4, standard HC 1-18.
    // teamA = [0,1], teamB = [2,3]
    // Equal HCs → no strokes → pops=0 for everyone.
    private let equalHCs = Array(repeating: 8, count: 4)  // all HC 8 → baseHC 8 → delta 0
    private let pars4    = Array(repeating: 4, count: STANDARD_HOLES)
    private let stdHCs   = Array(1...STANDARD_HOLES)

    func testTeamBestNet_AllTied() {
        // Scores: all four score 4, par-4, equal HCs → no pops, each team nets 0 → aSum=bSum=0
        let results = [makeResult(hole: 1, scores: [4, 4, 4, 4])]
        let (a, b) = SpectatorScoring.teamBestNetSums(
            results: results, teamASeats: [0, 1], playerCount: 4,
            upThrough: 1, coursePars: pars4, courseHCs: stdHCs,
            playerHandicaps: equalHCs)
        XCTAssertEqual(a, 0)
        XCTAssertEqual(b, 0)
    }

    func testTeamBestNet_TeamALeads() {
        // Seat 0 birdies (score 3), seats 1/2/3 par (4). HC all equal → no pops.
        // aBest = min(3,4) = 3 → aSum += 3-4 = -1; bBest = min(4,4) = 4 → bSum += 0
        let results = [makeResult(hole: 1, scores: [3, 4, 4, 4])]
        let (a, b) = SpectatorScoring.teamBestNetSums(
            results: results, teamASeats: [0, 1], playerCount: 4,
            upThrough: 1, coursePars: pars4, courseHCs: stdHCs,
            playerHandicaps: equalHCs)
        XCTAssertEqual(a, -1, "Team A leads by 1 after seat-0 birdie")
        XCTAssertEqual(b,  0)
        XCTAssertLessThan(a - b, 0, "Negative diff means A leads")
    }

    func testTeamBestNet_StrokeHelpsTeam() {
        // Seat 0 HC=10, rest HC=8. baseHC=8, seat-0 delta=2.
        // HC1 hole (SI=1): seat 0 gets a pop (1≤2). Score 5 → net 5-1=4 = par → no gain.
        // HC1 hole: seats 1,2,3 score 5 → net 5-0=5 → all over par.
        // aBest = min(4, 5) = 4 → aSum += 4-4 = 0
        // bBest = min(5, 5) = 5 → bSum += 5-4 = +1
        let hcs = [10, 8, 8, 8]  // seat-0 gets 2 extra strokes vs base
        let results = [makeResult(hole: 1, scores: [5, 5, 5, 5])]
        let (a, b) = SpectatorScoring.teamBestNetSums(
            results: results, teamASeats: [0, 1], playerCount: 4,
            upThrough: 1, coursePars: pars4, courseHCs: stdHCs,
            playerHandicaps: hcs)
        XCTAssertEqual(a, 0,  "Team A nets even on HC1 hole thanks to seat-0 stroke")
        XCTAssertEqual(b, 1,  "Team B bogeys net (no strokes given)")
        XCTAssertLessThan(a, b, "Stroke advantage means A leads")
    }

    func testTeamBestNet_PartialRound_OnlyCountsUpToMatchPos() {
        // 3 holes of results but matchPos = 2 → only first 2 holes counted
        let results = [
            makeResult(hole: 1, scores: [3, 4, 4, 4]),  // A birdie → -1
            makeResult(hole: 2, scores: [4, 4, 4, 4]),  // even
            makeResult(hole: 3, scores: [3, 3, 3, 3]),  // would make aSum=-2 if included
        ]
        let (a, b) = SpectatorScoring.teamBestNetSums(
            results: results, teamASeats: [0, 1], playerCount: 4,
            upThrough: 2, coursePars: pars4, courseHCs: stdHCs,
            playerHandicaps: equalHCs)
        XCTAssertEqual(a, -1, "Only holes 1-2 counted; hole 3 excluded by matchPos")
        XCTAssertEqual(b,  0)
    }

    func testTeamBestNet_CumulativeTwoHoles() {
        // Seat 0 birdies hole 1 AND hole 2 (A leads by 2 through hole 2)
        let results = [
            makeResult(hole: 1, scores: [3, 4, 4, 4]),
            makeResult(hole: 2, scores: [3, 4, 4, 4]),
        ]
        let (a, b) = SpectatorScoring.teamBestNetSums(
            results: results, teamASeats: [0, 1], playerCount: 4,
            upThrough: 2, coursePars: pars4, courseHCs: stdHCs,
            playerHandicaps: equalHCs)
        XCTAssertEqual(a, -2)
        XCTAssertEqual(b,  0)
    }

    func testTeamBestNet_ZeroScoreIgnored() {
        // Score of 0 means the player hasn't posted — should not count
        // Seat 0 score=0 (not posted), seat 1 score=4 → aBest should be 4 (not 0)
        let results = [makeResult(hole: 1, scores: [0, 4, 4, 4])]
        let (a, b) = SpectatorScoring.teamBestNetSums(
            results: results, teamASeats: [0, 1], playerCount: 4,
            upThrough: 1, coursePars: pars4, courseHCs: stdHCs,
            playerHandicaps: equalHCs)
        XCTAssertEqual(a, 0, "Unposted score (0) should not lower team net")
        XCTAssertEqual(b, 0)
    }

    func testTeamBestNet_MissingHoleSkipped() {
        // matchPos=2 but only hole 1 has a result — hole 2 missing → counted as skip
        let results = [makeResult(hole: 1, scores: [3, 4, 4, 4])]
        let (a, b) = SpectatorScoring.teamBestNetSums(
            results: results, teamASeats: [0, 1], playerCount: 4,
            upThrough: 2, coursePars: pars4, courseHCs: stdHCs,
            playerHandicaps: equalHCs)
        XCTAssertEqual(a, -1, "Only hole 1 counted; hole 2 not in results → skip")
        XCTAssertEqual(b,  0)
    }
}
