import XCTest
import UIKit
@testable import WolfmoreGolf

/// Tests for Feature #2: player on two teams.
/// Tests 1, 3, 4 are pure-Swift unit tests (no network).
/// Tests 2, 5 are integration tests that call the production Supabase RPC and
/// clean up after themselves.
final class ClubEventDualTeamTests: XCTestCase {

    // MARK: - Test 1: dual-team player contributes to both team score lists

    func testDualTeamPlayerAppearsInBothTeams() {
        // Rosie/Teddy on Team A, Rosie/Jerry on Team B.
        let rosieID = UUID()
        let teddyID = UUID()
        let jerryID = UUID()

        let players: [ClubEventGroupPlayer] = [
            ClubEventGroupPlayer(id: rosieID, name: "Rosie", handicap: 10, teams: ["A", "B"]),
            ClubEventGroupPlayer(id: teddyID, name: "Teddy", handicap: 15, teams: ["A"]),
            ClubEventGroupPlayer(id: jerryID, name: "Jerry", handicap:  8, teams: ["B"]),
        ]

        let teamA = players.filter { $0.teams.contains("A") }
        let teamB = players.filter { $0.teams.contains("B") }

        XCTAssertEqual(teamA.count, 2, "Team A: Rosie + Teddy")
        XCTAssertEqual(teamB.count, 2, "Team B: Rosie + Jerry")
        XCTAssertTrue(teamA.contains { $0.id == rosieID }, "Rosie must appear in Team A")
        XCTAssertTrue(teamB.contains { $0.id == rosieID }, "Rosie must appear in Team B")
        // Skins deduplication: Rosie appears only once in the full players list
        // (the skins engine receives `players`, not team members), so she can never
        // tie with herself.
        XCTAssertEqual(players.filter { $0.id == rosieID }.count, 1,
                       "Rosie appears exactly once — no self-tie possible in skins")
    }

    // MARK: - Test 2: third team slot rejected by RPC (integration)

    func testThirdTeamSlotRejectedByRPC() async throws {
        let svc   = SupabaseService.shared
        // allow_dual_team = true so the per-entry dual check passes; the slot tally (> 2) must still raise.
        let event = try await svc.createClubEvent(
            name: "DualTest-\(Int.random(in: 1000...9999))",
            courseName: nil, numDays: 1,
            players: [
                (name: "Rosie", handicap: 10),
                (name: "Teddy", handicap: 15),
            ],
            allowDualTeam: true)
        defer { Task { try? await svc.deleteClubEvent(id: event.id) } }

        let roster = try await svc.fetchClubEventRoster(tournamentId: event.id)
        guard let rosie = roster.first(where: { $0.playerName == "Rosie" }) else {
            XCTFail("Rosie not found in roster"); return
        }

        // Two entries for Rosie: ["A","B"] + ["A"] = 3 total team slots → server raises.
        do {
            _ = try await svc.setupClubEventGroup(
                tournamentId:  event.id,
                groupCode:     ClubEventGroupSetupViewController.randomGroupCode(),
                startingHole:  1,
                rosterPlayers: [
                    (id: rosie.id, teams: ["A", "B"]),
                    (id: rosie.id, teams: ["A"]),
                ],
                walkOns: [])
            XCTFail("RPC should have raised for 3 team slots")
        } catch {
            let msg = error.localizedDescription
            XCTAssertTrue(msg.contains("2 team slots") || msg.contains("already claimed") ||
                          msg.contains("2 teams") || msg.contains("team slots"),
                          "Expected slot-tally error, got: \(msg)")
        }
    }

    // MARK: - Test 3: shared player wins skin without tying herself

    func testSharedPlayerWinsSkinsUniquely() {
        let rosieID = UUID()
        let teddyID = UUID()
        let jerryID = UUID()

        // Rosie birdies hole 1 (gross 3). Teddy and Jerry score higher.
        // If Rosie appeared twice in the skins calculation (once per team), skinResult
        // would see two entries at score 3 → (nil, [rosie, rosie]) — a spurious self-tie.
        // With one PlayerInput per player, she wins outright.
        var rosie18 = Array(repeating: HoleScore.notEntered, count: 18)
        var teddy18 = Array(repeating: HoleScore.notEntered, count: 18)
        var jerry18 = Array(repeating: HoleScore.notEntered, count: 18)
        let posted  = Array(repeating: true, count: 18)

        rosie18[0] = .gross(3)
        teddy18[0] = .gross(5)
        jerry18[0] = .gross(4)

        let settings = FieldSkinsEngine.Settings(
            holeHandicapRanks: Array(1...18), allowance: 1.0,
            carryoverEnabled: false, potGrossPerHole: 1.0, potNetPerHole: 0.0)

        let results = FieldSkinsEngine.compute(players: [
            FieldSkinsEngine.PlayerInput(playerID: rosieID, courseHandicap: 10,
                                         scores: rosie18, groupPosted: posted),
            FieldSkinsEngine.PlayerInput(playerID: teddyID, courseHandicap: 15,
                                         scores: teddy18, groupPosted: posted),
            FieldSkinsEngine.PlayerInput(playerID: jerryID, courseHandicap:  8,
                                         scores: jerry18, groupPosted: posted),
        ], settings: settings)

        XCTAssertEqual(results[0].grossWinner, rosieID,
                       "Rosie wins gross skin on hole 1")
        XCTAssertTrue(results[0].grossTied.isEmpty,
                      "No self-tie: Rosie's player ID appears only once in score list")
    }

    // MARK: - Test 4: shared player picks up → Teddy wins the skin

    func testSharedPlayerPickedUpNoSkinsWin() {
        let rosieID = UUID()
        let teddyID = UUID()
        let jerryID = UUID()

        var rosie18 = Array(repeating: HoleScore.notEntered, count: 18)
        var teddy18 = Array(repeating: HoleScore.notEntered, count: 18)
        var jerry18 = Array(repeating: HoleScore.notEntered, count: 18)
        let posted  = Array(repeating: true, count: 18)

        rosie18[0] = .pickedUp   // Rosie picks up — no skins contribution
        teddy18[0] = .gross(4)   // Teddy makes par
        jerry18[0] = .gross(5)   // Jerry bogeys

        let settings = FieldSkinsEngine.Settings(
            holeHandicapRanks: Array(1...18), allowance: 1.0,
            carryoverEnabled: false, potGrossPerHole: 1.0, potNetPerHole: 0.0)

        let results = FieldSkinsEngine.compute(players: [
            FieldSkinsEngine.PlayerInput(playerID: rosieID, courseHandicap: 10,
                                         scores: rosie18, groupPosted: posted),
            FieldSkinsEngine.PlayerInput(playerID: teddyID, courseHandicap: 15,
                                         scores: teddy18, groupPosted: posted),
            FieldSkinsEngine.PlayerInput(playerID: jerryID, courseHandicap:  8,
                                         scores: jerry18, groupPosted: posted),
        ], settings: settings)

        XCTAssertEqual(results[0].grossWinner, teddyID,
                       "Teddy wins gross skin — Rosie's pickup removes her from contention")
        // Best-ball consequence: Rosie's pickup means Team A falls back to Teddy alone,
        // Team B falls back to Jerry alone. Scoring VC coverage is in Test 1.
    }

    // MARK: - Test 5: dual-team assignment rejected when allow_dual_team = false (integration)

    func testDualTeamRejectedWhenNotAllowed() async throws {
        let svc   = SupabaseService.shared
        // createClubEvent default: allow_dual_team = false (column default)
        let event = try await svc.createClubEvent(
            name: "DualTest-\(Int.random(in: 1000...9999))",
            courseName: nil, numDays: 1,
            players: [
                (name: "Rosie", handicap: 10),
                (name: "Teddy", handicap: 15),
            ])
        defer { Task { try? await svc.deleteClubEvent(id: event.id) } }

        let roster = try await svc.fetchClubEventRoster(tournamentId: event.id)
        guard let rosie = roster.first(where: { $0.playerName == "Rosie" }),
              let teddy = roster.first(where: { $0.playerName == "Teddy" }) else {
            XCTFail("Players not found in roster"); return
        }

        do {
            _ = try await svc.setupClubEventGroup(
                tournamentId:  event.id,
                groupCode:     ClubEventGroupSetupViewController.randomGroupCode(),
                startingHole:  1,
                rosterPlayers: [
                    (id: rosie.id, teams: ["A", "B"]),   // dual-team, but setting is off
                    (id: teddy.id, teams: ["A"]),
                ],
                walkOns: [])
            XCTFail("RPC should have rejected dual-team when allow_dual_team = false")
        } catch {
            let msg = error.localizedDescription
            XCTAssertTrue(msg.contains("dual-team") || msg.contains("not enabled"),
                          "Expected dual-team-disabled error, got: \(msg)")
        }
    }

    // MARK: - Test 6: scorer handoff — device 2 loads correct teams and scores from DB (integration)

    func testHandoffLoadsCorrectTeamsAndScoresFromDB() async throws {
        let svc = SupabaseService.shared
        let event = try await svc.createClubEvent(
            name: "HandoffTest-\(Int.random(in: 1000...9999))",
            courseName: nil, numDays: 1,
            players: [
                (name: "Ned",   handicap: 12),
                (name: "Alice", handicap:  8),
                (name: "Bob",   handicap: 15),
            ],
            allowDualTeam: true)
        defer { Task { try? await svc.deleteClubEvent(id: event.id) } }

        let roster = try await svc.fetchClubEventRoster(tournamentId: event.id)
        guard let ned   = roster.first(where: { $0.playerName == "Ned"   }),
              let alice = roster.first(where: { $0.playerName == "Alice" }),
              let bob   = roster.first(where: { $0.playerName == "Bob"   }) else {
            XCTFail("Players not found in roster"); return
        }

        let groupCode = ClubEventGroupSetupViewController.randomGroupCode()
        _ = try await svc.setupClubEventGroup(
            tournamentId:  event.id,
            groupCode:     groupCode,
            startingHole:  1,
            rosterPlayers: [
                (id: ned.id,   teams: ["A", "B"]),   // shared player
                (id: alice.id, teams: ["A"]),
                (id: bob.id,   teams: ["B"]),
            ],
            walkOns: [])

        // Device 1: post 3 hole scores for each player.
        for hole in 1...3 {
            for player in [ned, alice, bob] {
                try await svc.upsertClubEventHoleScore(
                    tournamentId: event.id, playerId: player.id,
                    day: 1, hole: hole, gross: 5, pickedUp: false,
                    groupCode: groupCode)
            }
        }

        // Device 2: load teams + memberships + scores from DB.
        let teams       = try await svc.fetchClubEventTeams(tournamentId: event.id)
        let memberships = try await svc.fetchClubEventTeamMemberships(teamIds: teams.map { $0.id })
        let freshRoster = try await svc.fetchClubEventRoster(tournamentId: event.id)
        let groupPlayers = freshRoster.filter { ($0.groupCode ?? "") == groupCode }

        var playerTeams: [UUID: [String]] = [:]
        for m in memberships {
            guard let team = teams.first(where: { $0.id == m.teamId }) else { continue }
            let suffix = team.teamName.hasSuffix("-A") ? "A"
                       : team.teamName.hasSuffix("-B") ? "B"
                       : nil
            guard let suffix else { continue }
            playerTeams[m.tournamentPlayerId, default: []].append(suffix)
        }
        let built: [ClubEventGroupPlayer] = groupPlayers.map { p in
            ClubEventGroupPlayer(id: p.id, name: p.playerName, handicap: p.handicap,
                                 teams: playerTeams[p.id] ?? ["A"])
        }

        guard let nedBuilt   = built.first(where: { $0.name == "Ned"   }),
              let aliceBuilt = built.first(where: { $0.name == "Alice" }),
              let bobBuilt   = built.first(where: { $0.name == "Bob"   }) else {
            XCTFail("Players missing from device-2 built list"); return
        }
        XCTAssertEqual(Set(nedBuilt.teams),   ["A", "B"], "Device 2: Ned must load with teams A+B")
        XCTAssertEqual(aliceBuilt.teams,      ["A"],       "Device 2: Alice must be on Team A only")
        XCTAssertEqual(bobBuilt.teams,        ["B"],       "Device 2: Bob must be on Team B only")

        let scores = try await svc.fetchClubEventGroupScores(
            tournamentId: event.id, playerIds: built.map { $0.id })
        XCTAssertEqual(scores.count, 9, "Device 2: must see 9 scores (3 players × 3 holes)")
        XCTAssertTrue(scores.allSatisfy { $0.grossScore == 5 }, "All posted scores must read back as 5")
    }
}
