import XCTest
@testable import WolfmoreGolf

// MARK: - Skins finality with 9-hole event and unassigned player

final class SkinsFinality9HoleTests: XCTestCase {

    // 2 groups (A: p1/p2, B: p3/p4), 9-hole event, all holes posted.
    // Unassigned roster player is excluded from the engine input (matches the fix
    // in ClubEventLeaderboardViewController.buildData that filters groupCode == "").
    // p1 makes gross 3 on hole 1; everyone else gross 5 → p1 wins skin on hole 1.
    // All holes must be Won (grossIsProvisional == false) since every group posted.
    func testSkinsAreFinalWhenAllGroupsPost_9HoleEvent() {
        let p1 = UUID(), p2 = UUID(), p3 = UUID(), p4 = UUID()
        let postedAll = Array(repeating: true, count: 9)

        func makeScores(birdieHole1: Bool) -> [HoleScore] {
            var s = Array(repeating: HoleScore.gross(5), count: 9)
            if birdieHole1 { s[0] = .gross(3) }
            return s
        }

        let settings = FieldSkinsEngine.Settings(
            holeHandicapRanks: Array(1...9),
            allowance: 1.0,
            carryoverEnabled: false,
            potGrossPerHole: 1.0,
            potNetPerHole: 0.0)

        let players: [FieldSkinsEngine.PlayerInput] = [
            .init(playerID: p1, courseHandicap: 0, scores: makeScores(birdieHole1: true),  groupPosted: postedAll),
            .init(playerID: p2, courseHandicap: 0, scores: makeScores(birdieHole1: false), groupPosted: postedAll),
            .init(playerID: p3, courseHandicap: 0, scores: makeScores(birdieHole1: false), groupPosted: postedAll),
            .init(playerID: p4, courseHandicap: 0, scores: makeScores(birdieHole1: false), groupPosted: postedAll),
        ]

        let results = FieldSkinsEngine.compute(players: players, settings: settings)
        XCTAssertEqual(results.count, 9)

        XCTAssertEqual(results[0].grossWinner, p1,
                       "p1 wins gross skin on hole 1 (gross 3 vs everyone else's 5)")
        XCTAssertFalse(results[0].grossIsProvisional,
                       "Hole 1 must be Won — all 2 groups posted, unassigned player not in input")

        for h in 1..<9 {
            XCTAssertFalse(results[h].grossIsProvisional,
                           "Hole \(h + 1): all groups posted → not provisional")
        }
    }

    // Demonstrates the root-cause bug: including an unassigned player (groupPosted=all-false)
    // makes every hole provisional even when all real groups have finished.
    func testUnassignedPlayerInInputCausesAllHolesToStayProvisional() {
        let p1 = UUID(), unassigned = UUID()
        let postedAll  = Array(repeating: true,  count: 9)
        let postedNone = Array(repeating: false, count: 9)

        let settings = FieldSkinsEngine.Settings(
            holeHandicapRanks: Array(1...9),
            allowance: 1.0,
            carryoverEnabled: false,
            potGrossPerHole: 1.0,
            potNetPerHole: 0.0)

        let results = FieldSkinsEngine.compute(players: [
            .init(playerID: p1,         courseHandicap: 0,
                  scores: Array(repeating: .gross(3), count: 9), groupPosted: postedAll),
            .init(playerID: unassigned, courseHandicap: 0,
                  scores: Array(repeating: .gross(5), count: 9), groupPosted: postedNone),
        ], settings: settings)

        for h in 0..<9 {
            XCTAssertTrue(results[h].grossIsProvisional,
                          "Hole \(h + 1) stays provisional when unassigned player is in engine input")
        }
    }
}

// MARK: - Par-7 hole

final class Par7Tests: XCTestCase {

    // BestBallEngine: hole 6 is par 7.
    // Player (HC 0) makes gross 5 (eagle on par 7).
    // netToPar = 5 − 0 strokes − 7 = −2.
    func testPar7_BestBallEngine_NetToParIsCorrect() {
        let playerID = UUID()
        var pars = Array(repeating: 4, count: 18)
        pars[5] = 7  // hole 6 par 7

        var scores = Array(repeating: HoleScore.gross(4), count: 18)
        scores[5] = .gross(5)  // gross 5 on par-7 hole

        let player = BestBallEngine.PlayerInput(playerID: playerID, courseHandicap: 0, scores: scores)
        let team   = BestBallEngine.TeamInput(teamID: UUID(), teamName: "T", players: [player])
        let input  = BestBallEngine.GroupInput(teams: [team],
                                               holeHandicapRanks: Array(1...18),
                                               par: pars)

        let results = BestBallEngine.holeResults(for: input)
        let h6 = results[5]

        XCTAssertEqual(h6.par, 7, "Hole 6 par must be 7")
        XCTAssertEqual(h6.teamResults[0].bestNet,     5, "Best net = gross 5 − 0 strokes")
        XCTAssertEqual(h6.teamResults[0].netToPar,   -2, "Net to par: 5 − 7 = −2 (eagle)")
        XCTAssertEqual(h6.teamResults[0].grossToPar, -2, "Gross to par: 5 − 7 = −2")
    }

    // Both-picked-up cap on a par-7 hole = par + defaultOverPar = 7 + 2 = 9.
    func testPar7_BothPickedUpCap_UsesActualPar() {
        let p1 = UUID(), p2 = UUID()
        var pars = Array(repeating: 4, count: 18)
        pars[5] = 7  // hole 6 par 7

        var s1 = Array(repeating: HoleScore.gross(4), count: 18)
        var s2 = Array(repeating: HoleScore.gross(4), count: 18)
        s1[5] = .pickedUp
        s2[5] = .pickedUp

        let player1 = BestBallEngine.PlayerInput(playerID: p1, courseHandicap: 0, scores: s1)
        let player2 = BestBallEngine.PlayerInput(playerID: p2, courseHandicap: 0, scores: s2)
        let team    = BestBallEngine.TeamInput(teamID: UUID(), teamName: "T", players: [player1, player2])
        let input   = BestBallEngine.GroupInput(teams: [team],
                                                holeHandicapRanks: Array(1...18),
                                                par: pars,
                                                bothPickedUpMaxNetOverPar: 2)

        let results = BestBallEngine.holeResults(for: input)
        let h6 = results[5]

        XCTAssertTrue(h6.teamResults[0].bothPickedUp,
                      "Both picked up on par-7 hole")
        XCTAssertEqual(h6.teamResults[0].bestNet, 7 + 2,
                       "Both-picked-up cap: par(7) + 2 = 9")
    }
}

// MARK: - Skins summary stability (gross→net→gross produces identical order)

final class SkinsSummaryStabilityTests: XCTestCase {

    // 4 players: p1 wins 2 gross skins; p2, p3, p4 win 1 gross skin each.
    // Build winner list for gross, flip to net, flip back to gross.
    // UUIDs and counts must be identical on both gross passes, in stable name order.
    func testSkinsSummaryOrderIsStableAcrossGrossNetFlip() {
        let p1 = UUID(), p2 = UUID(), p3 = UUID(), p4 = UUID()
        // Names chosen so alphabetical order differs from UUID hash order
        let names: [UUID: String] = [p1: "Aaron", p2: "Charlie", p3: "Bob", p4: "Dave"]

        let postedAll = Array(repeating: true, count: 9)
        func scores(for id: UUID) -> [HoleScore] {
            var s = Array(repeating: HoleScore.gross(5), count: 9)
            if id == p1 { s[0] = .gross(3); s[1] = .gross(3) }
            if id == p2 { s[2] = .gross(3) }
            if id == p3 { s[3] = .gross(3) }
            if id == p4 { s[4] = .gross(3) }
            return s
        }
        let players: [FieldSkinsEngine.PlayerInput] = [p1, p2, p3, p4].map {
            .init(playerID: $0, courseHandicap: 0, scores: scores(for: $0), groupPosted: postedAll)
        }
        let settings = FieldSkinsEngine.Settings(
            holeHandicapRanks: Array(1...9),
            allowance: 1.0, carryoverEnabled: false,
            potGrossPerHole: 1.0, potNetPerHole: 0.0)
        let results = FieldSkinsEngine.compute(players: players, settings: settings)

        // Replicate the fixed finalSkinsWinners sort: count desc, name asc, UUID asc
        func buildWinners(gross: Bool) -> [(uuid: UUID, count: Int)] {
            var counts: [UUID: Int] = [:]
            for r in results {
                let winner = gross ? r.grossWinner : r.netWinner
                let prov   = gross ? r.grossIsProvisional : r.netIsProvisional
                if let w = winner, !prov { counts[w, default: 0] += 1 }
            }
            return counts
                .map { ($0.key, $0.value) }
                .sorted {
                    if $0.1 != $1.1 { return $0.1 > $1.1 }
                    let na = names[$0.0] ?? ""; let nb = names[$1.0] ?? ""
                    if na != nb { return na < nb }
                    return $0.0.uuidString < $1.0.uuidString
                }
        }

        let gross1 = buildWinners(gross: true)
        let _      = buildWinners(gross: false)   // simulate net tab
        let gross2 = buildWinners(gross: true)    // flip back to gross

        XCTAssertEqual(gross1.count, 4, "4 players should have skins")
        XCTAssertEqual(gross1.count, gross2.count, "Same count on both gross passes")

        for (a, b) in zip(gross1, gross2) {
            XCTAssertEqual(a.uuid,  b.uuid,  "UUID identical across gross→net→gross")
            XCTAssertEqual(a.count, b.count, "Count identical across gross→net→gross")
        }

        // Expected stable order: p1 (2 skins), then 1-skin players by name: Bob(p3), Charlie(p2), Dave(p4)
        XCTAssertEqual(gross1[0].uuid,  p1, "Aaron/p1: 2 skins → first")
        XCTAssertEqual(gross1[0].count, 2)
        XCTAssertEqual(gross1[1].uuid,  p3, "Bob/p3: 1 skin → alphabetically first among 1-skin players")
        XCTAssertEqual(gross1[1].count, 1)
        XCTAssertEqual(gross1[2].uuid,  p2, "Charlie/p2: 1 skin")
        XCTAssertEqual(gross1[2].count, 1)
        XCTAssertEqual(gross1[3].uuid,  p4, "Dave/p4: 1 skin")
        XCTAssertEqual(gross1[3].count, 1)
    }
}

// MARK: - Dual-team / duplicate player deduplication

final class DualTeamSkinsTests: XCTestCase {

    private let tourneyID = UUID()

    // Fred is a dual-team player: one roster entry, one UUID, group "A".
    // Fred appears TWICE in the players array (simulating a duplicate tournament_player row).
    // buildClubEventSkinInputs must deduplicate by UUID so Fred competes only once.
    func testDuplicateRosterRow_DeduplicatedByUUID() {
        let fredID  = UUID()
        let harryID = UUID()
        let fred  = ClubEventPlayer(id: fredID,  tournamentId: tourneyID,
                                    playerName: "Fred",  handicap: 0, groupCode: "A")
        let harry = ClubEventPlayer(id: harryID, tournamentId: tourneyID,
                                    playerName: "Harry", handicap: 0, groupCode: "A")

        // Fred appears twice (duplicate DB row scenario)
        let rosterWithDuplicate = [fred, harry, fred]

        let scoresByPlayer: [UUID: [Int: (gross: Int, pickedUp: Bool)]] = [
            fredID:  [1: (gross: 3, pickedUp: false)],
            harryID: [1: (gross: 5, pickedUp: false)],
        ]
        let postedByGroup: [String: Set<Int>] = ["A": Set(1...9)]

        let inputs = buildClubEventSkinInputs(
            players: rosterWithDuplicate,
            scoresByPlayer: scoresByPlayer,
            postedByGroup: postedByGroup,
            holeCount: 9)

        XCTAssertEqual(inputs.count, 2,
                       "Should have 2 inputs (Fred + Harry) — Fred's duplicate must be removed")
        XCTAssertEqual(inputs.filter { $0.playerID == fredID }.count, 1,
                       "Fred appears exactly once in skin inputs despite duplicate roster row")

        // Fred (3) beats Harry (5) on hole 1; hole is final (all 2 unique players posted)
        let settings = FieldSkinsEngine.Settings(
            holeHandicapRanks: Array(1...9),
            allowance: 1.0, carryoverEnabled: false,
            potGrossPerHole: 1.0, potNetPerHole: 0.0)

        let results = FieldSkinsEngine.compute(players: inputs, settings: settings)

        XCTAssertEqual(results[0].grossWinner, fredID,
                       "Fred (gross 3) beats Harry (gross 5) on hole 1")
        XCTAssertFalse(results[0].grossIsProvisional,
                       "Hole 1 must be Won — both unique players posted")
    }

    // A dual-team player (one UUID, two teams) feeds into the engine once.
    // Their skins count is the same regardless of how many teams they're on.
    func testDualTeamPlayer_OneUUID_AppearsOnce() {
        let fredID  = UUID()
        let harryID = UUID()
        // Fred is on two teams but has ONE roster entry
        let fred  = ClubEventPlayer(id: fredID,  tournamentId: tourneyID,
                                    playerName: "Fred",  handicap: 0, groupCode: "A")
        let harry = ClubEventPlayer(id: harryID, tournamentId: tourneyID,
                                    playerName: "Harry", handicap: 0, groupCode: "A")

        let scoresByPlayer: [UUID: [Int: (gross: Int, pickedUp: Bool)]] = [
            fredID:  [1: (gross: 3, pickedUp: false), 2: (gross: 3, pickedUp: false)],
            harryID: [1: (gross: 5, pickedUp: false), 2: (gross: 5, pickedUp: false)],
        ]
        let postedByGroup: [String: Set<Int>] = ["A": Set(1...9)]

        let inputs = buildClubEventSkinInputs(
            players: [fred, harry], scoresByPlayer: scoresByPlayer,
            postedByGroup: postedByGroup, holeCount: 9)

        XCTAssertEqual(inputs.count, 2)

        let settings = FieldSkinsEngine.Settings(
            holeHandicapRanks: Array(1...9),
            allowance: 1.0, carryoverEnabled: false,
            potGrossPerHole: 1.0, potNetPerHole: 0.0)

        let results = FieldSkinsEngine.compute(players: inputs, settings: settings)

        // Fred wins holes 1 and 2; must appear once with count=2 in winners
        let fredWins = results.filter { $0.grossWinner == fredID && !$0.grossIsProvisional }
        XCTAssertEqual(fredWins.count, 2, "Fred wins exactly 2 holes")

        // Verify engine returns Fred's UUID for both — no duplication
        for r in fredWins {
            XCTAssertEqual(r.grossWinner, fredID, "Winner UUID is Fred's single UUID")
        }
    }
}
